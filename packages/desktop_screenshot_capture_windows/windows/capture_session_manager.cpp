#include "capture_session_manager.h"

#include "capture_error_codes.h"
#include "d3d_capture_helpers.h"
#include "frame_encoder.h"
#include "screen_capture_permission_checker.h"

#include <windows.graphics.capture.interop.h>
#include <winrt/base.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Graphics.Capture.h>
#include <winrt/Windows.Graphics.DirectX.Direct3D11.h>

#include <chrono>
#include <condition_variable>
#include <ctime>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <thread>

namespace desktop_screenshot_capture_windows {

namespace {

std::string CurrentIso8601Utc() {
  const auto now = std::chrono::system_clock::now();
  const auto time = std::chrono::system_clock::to_time_t(now);
  std::tm tm = {};
  gmtime_s(&tm, &time);
  std::ostringstream stream;
  stream << std::put_time(&tm, "%Y-%m-%dT%H:%M:%SZ");
  return stream.str();
}

winrt::Windows::Graphics::Capture::GraphicsCaptureItem CreateCaptureItemForMonitor(
    HMONITOR monitor) {
  auto activation_factory =
      winrt::get_activation_factory<winrt::Windows::Graphics::Capture::GraphicsCaptureItem>();
  auto interop = activation_factory.as<IGraphicsCaptureItemInterop>();
  winrt::Windows::Graphics::Capture::GraphicsCaptureItem item{nullptr};
  const HRESULT hr = interop->CreateForMonitor(
      monitor,
      winrt::guid_of<ABI::Windows::Graphics::Capture::IGraphicsCaptureItem>(),
      winrt::put_abi(item));
  if (FAILED(hr) || !item) {
    throw std::runtime_error("CreateForMonitor failed.");
  }
  return item;
}

}  // namespace

struct CaptureSessionManager::ActiveSession {
  MonitorInfo monitor;
  winrt::Windows::Graphics::Capture::GraphicsCaptureItem item{nullptr};
  winrt::Windows::Graphics::Capture::Direct3D11CaptureFramePool frame_pool{nullptr};
  winrt::Windows::Graphics::Capture::GraphicsCaptureSession session{nullptr};
  Microsoft::WRL::ComPtr<ID3D11Device> d3d_device;
  Microsoft::WRL::ComPtr<ID3D11DeviceContext> d3d_context;
  winrt::Windows::Graphics::Capture::Direct3D11CaptureFramePool::FrameArrived_revoker
      frame_arrived_revoker;
  std::mutex frame_mutex;
  CapturedFrame latest_frame;
  bool has_frame = false;
  std::condition_variable frame_cv;
};

CaptureSessionManager& CaptureSessionManager::Instance() {
  static CaptureSessionManager instance;
  return instance;
}

void CaptureSessionManager::SetEventSink(
    flutter::EventSink<flutter::EncodableValue>* event_sink) {
  std::lock_guard<std::mutex> lock(mutex_);
  event_sink_ = event_sink;
}

void CaptureSessionManager::EmitEvent(const std::string& type,
                                      const std::string& session_id,
                                      const flutter::EncodableMap& extra) {
  flutter::EventSink<flutter::EncodableValue>* sink = nullptr;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    sink = event_sink_;
  }
  if (sink == nullptr) {
    return;
  }

  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("type")] = flutter::EncodableValue(type);
  payload[flutter::EncodableValue("sessionId")] = flutter::EncodableValue(session_id);
  for (const auto& entry : extra) {
    payload[entry.first] = entry.second;
  }
  sink->Success(flutter::EncodableValue(payload));
}

flutter::EncodableMap CaptureSessionManager::PrepareCapture(
    const std::string& session_id,
    const std::string& display_id) {
  const PermissionEvaluation permission = ScreenCapturePermissionChecker::Evaluate();
  if (permission.result != PermissionResult::kGranted) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kPermissionDenied));
  }

  const MonitorInfo monitor = DisplayEnumerator::MonitorForId(display_id);
  auto session = std::make_unique<ActiveSession>();
  session->monitor = monitor;
  session->d3d_device = CreateD3D11Device();
  session->d3d_device->GetImmediateContext(session->d3d_context.GetAddressOf());
  session->item = CreateCaptureItemForMonitor(monitor.handle);

  const auto direct3d_device = CreateDirect3DDevice(session->d3d_device.Get());
  const auto size = session->item.Size();
  session->frame_pool =
      winrt::Windows::Graphics::Capture::Direct3D11CaptureFramePool::Create(
          direct3d_device,
          winrt::Windows::Graphics::DirectX::DirectXPixelFormat::B8G8R8A8UIntNormalized,
          2, size);
  session->session = session->frame_pool.CreateCaptureSession(session->item);

  ActiveSession* session_ptr = session.get();
  session->frame_arrived_revoker = session->frame_pool.FrameArrived(
      winrt::auto_revoke,
      [session_ptr](const winrt::Windows::Graphics::Capture::Direct3D11CaptureFramePool& sender,
                    const winrt::Windows::Foundation::IInspectable&) {
        const auto frame = sender.TryGetNextFrame();
        if (!frame) {
          return;
        }

        try {
          CapturedFrame captured = CopyFrameSurfaceToBgra(
              frame, session_ptr->d3d_device.Get(), session_ptr->d3d_context.Get());
          {
            std::lock_guard<std::mutex> lock(session_ptr->frame_mutex);
            session_ptr->latest_frame = std::move(captured);
            session_ptr->has_frame = true;
          }
          session_ptr->frame_cv.notify_all();
        } catch (...) {
        }
      });

  session->session.StartCapture();

  {
    std::lock_guard<std::mutex> lock(mutex_);
    sessions_[session_id] = std::move(session);
  }

  flutter::EncodableMap phase_extra;
  phase_extra[flutter::EncodableValue("phase")] = flutter::EncodableValue("ready");
  EmitEvent("phaseChanged", session_id, phase_extra);

  flutter::EncodableMap response;
  response[flutter::EncodableValue("sessionId")] = flutter::EncodableValue(session_id);
  response[flutter::EncodableValue("source")] =
      flutter::EncodableValue(monitor.ToMap());
  response[flutter::EncodableValue("phase")] = flutter::EncodableValue("ready");
  return response;
}

flutter::EncodableMap CaptureSessionManager::TakeScreenshot(
    const std::string& session_id,
    const std::string& output_path,
    const std::string& format,
    int quality) {
  ActiveSession* session = nullptr;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = sessions_.find(session_id);
    if (it == sessions_.end()) {
      throw std::runtime_error(CapturePluginErrorMessage(
          CapturePluginError::kSessionClosed));
    }
    session = it->second.get();
  }

  CapturedFrame captured;
  {
    std::unique_lock<std::mutex> lock(session->frame_mutex);
    if (!session->frame_cv.wait_for(lock, std::chrono::seconds(3),
                                    [session] { return session->has_frame; })) {
      throw std::runtime_error(CapturePluginErrorMessage(
          CapturePluginError::kCaptureFailed, "No frame available from capture stream"));
    }
    captured = session->latest_frame;
  }

  const int bytes_written =
      FrameEncoder::Encode(captured.bgra_pixels, captured.width, captured.height, format,
                           quality, output_path);

  flutter::EncodableMap response;
  response[flutter::EncodableValue("filePath")] = flutter::EncodableValue(output_path);
  response[flutter::EncodableValue("width")] =
      flutter::EncodableValue(session->monitor.width);
  response[flutter::EncodableValue("height")] =
      flutter::EncodableValue(session->monitor.height);
  response[flutter::EncodableValue("bytesWritten")] =
      flutter::EncodableValue(bytes_written);
  response[flutter::EncodableValue("capturedAt")] =
      flutter::EncodableValue(CurrentIso8601Utc());
  return response;
}

void CaptureSessionManager::StopCapture(const std::string& session_id) {
  std::unique_ptr<ActiveSession> session;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    const auto it = sessions_.find(session_id);
    if (it == sessions_.end()) {
      return;
    }
    session = std::move(it->second);
    sessions_.erase(it);
  }

  if (session->frame_pool) {
    session->frame_arrived_revoker.revoke();
  }
  if (session->session) {
    session->session.Close();
  }
  if (session->frame_pool) {
    session->frame_pool.Close();
  }

  flutter::EncodableMap completed_extra;
  completed_extra[flutter::EncodableValue("phase")] =
      flutter::EncodableValue("completed");
  EmitEvent("phaseChanged", session_id, completed_extra);
  EmitEvent("sessionClosed", session_id, {});
}

void CaptureSessionManager::DisposeAll() {
  std::vector<std::string> session_ids;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    session_ids.reserve(sessions_.size());
    for (const auto& entry : sessions_) {
      session_ids.push_back(entry.first);
    }
  }

  for (const auto& session_id : session_ids) {
    StopCapture(session_id);
  }
}

}  // namespace desktop_screenshot_capture_windows
