#include "desktop_screenshot_capture_windows_plugin.h"

#include "capture_error_codes.h"
#include "capture_session_manager.h"
#include "display_enumerator.h"
#include "screen_capture_permission_checker.h"

#include <flutter/encodable_value.h>
#include <flutter/method_result_functions.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <winrt/base.h>

#include <memory>
#include <optional>
#include <string>

namespace desktop_screenshot_capture_windows {

namespace {

constexpr char kMethodChannel[] =
    "dev.oxy.screen_capture/desktop_screenshot_capture";
constexpr char kEventChannel[] = "dev.oxy.screen_capture/events";

const flutter::EncodableMap* GetMapArgument(
    const flutter::MethodCall<flutter::EncodableValue>& method_call) {
  return std::get_if<flutter::EncodableMap>(method_call.arguments());
}

std::optional<std::string> GetString(const flutter::EncodableMap& map,
                                     const char* key) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return std::nullopt;
  }
  if (const auto* value = std::get_if<std::string>(&it->second)) {
    return *value;
  }
  return std::nullopt;
}

std::optional<int> GetInt(const flutter::EncodableMap& map, const char* key) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return std::nullopt;
  }
  if (const auto* value = std::get_if<int32_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  return std::nullopt;
}

}  // namespace

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
CaptureEventStreamHandler::OnListenInternal(
    const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
  event_sink_ = std::move(events);
  CaptureSessionManager::Instance().SetEventSink(event_sink_.get());
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
CaptureEventStreamHandler::OnCancelInternal(
    const flutter::EncodableValue* arguments) {
  CaptureSessionManager::Instance().SetEventSink(nullptr);
  event_sink_.reset();
  return nullptr;
}

void DesktopScreenshotCaptureWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<DesktopScreenshotCaptureWindowsPlugin>();

  auto method_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kMethodChannel,
          &flutter::StandardMethodCodec::GetInstance());

  method_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  auto event_channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), kEventChannel,
          &flutter::StandardMethodCodec::GetInstance());

  auto event_handler = std::make_unique<CaptureEventStreamHandler>();
  event_channel->SetStreamHandler(std::move(event_handler));

  registrar->AddPlugin(std::move(plugin));
}

DesktopScreenshotCaptureWindowsPlugin::DesktopScreenshotCaptureWindowsPlugin() {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
}

DesktopScreenshotCaptureWindowsPlugin::~DesktopScreenshotCaptureWindowsPlugin() {
  CaptureSessionManager::Instance().DisposeAll();
}

void DesktopScreenshotCaptureWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  try {
    if (method == "getPermissionStatus") {
      result->Success(flutter::EncodableValue(
          ScreenCapturePermissionChecker::PermissionStatusMap()));
      return;
    }

    if (method == "listMonitors") {
      flutter::EncodableList monitors;
      for (const auto& monitor : DisplayEnumerator::ListMonitors()) {
        monitors.push_back(flutter::EncodableValue(monitor.ToMap()));
      }
      result->Success(flutter::EncodableValue(monitors));
      return;
    }

    if (method == "selectMonitor") {
      const flutter::EncodableMap* args = GetMapArgument(method_call);
      if (args == nullptr) {
        result->Success();
        return;
      }

      const auto id = GetString(*args, "id");
      if (!id.has_value()) {
        result->Success();
        return;
      }

      const MonitorInfo monitor = DisplayEnumerator::MonitorForId(*id);
      result->Success(flutter::EncodableValue(monitor.ToMap()));
      return;
    }

    if (method == "prepareCapture") {
      const flutter::EncodableMap* args = GetMapArgument(method_call);
      if (args == nullptr) {
        ResultError(result.get(), CapturePluginError::kCaptureFailed,
                    "Invalid prepareCapture arguments");
        return;
      }

      const auto session_id = GetString(*args, "sessionId");
      std::optional<std::string> source_id = GetString(*args, "sourceId");
      if (!source_id.has_value()) {
        if (const auto source_it = args->find(flutter::EncodableValue("source"));
            source_it != args->end()) {
          if (const auto* source_map =
                  std::get_if<flutter::EncodableMap>(&source_it->second)) {
            source_id = GetString(*source_map, "id");
          }
        }
      }

      if (!session_id.has_value() || !source_id.has_value()) {
        ResultError(result.get(), CapturePluginError::kCaptureFailed,
                    "Invalid prepareCapture arguments");
        return;
      }

      result->Success(flutter::EncodableValue(CaptureSessionManager::Instance().PrepareCapture(
          *session_id, *source_id)));
      return;
    }

    if (method == "takeScreenshot") {
      const flutter::EncodableMap* args = GetMapArgument(method_call);
      if (args == nullptr) {
        ResultError(result.get(), CapturePluginError::kCaptureFailed,
                    "Invalid takeScreenshot arguments");
        return;
      }

      const auto session_id = GetString(*args, "sessionId");
      const auto output_path = GetString(*args, "outputPath");
      const auto format = GetString(*args, "format");
      const int quality = GetInt(*args, "quality").value_or(80);
      if (!session_id.has_value() || !output_path.has_value() ||
          !format.has_value()) {
        ResultError(result.get(), CapturePluginError::kCaptureFailed,
                    "Invalid takeScreenshot arguments");
        return;
      }

      result->Success(flutter::EncodableValue(CaptureSessionManager::Instance().TakeScreenshot(
          *session_id, *output_path, *format, quality)));
      return;
    }

    if (method == "stopCapture") {
      const flutter::EncodableMap* args = GetMapArgument(method_call);
      if (args == nullptr) {
        ResultError(result.get(), CapturePluginError::kCaptureFailed,
                    "Invalid stopCapture arguments");
        return;
      }

      const auto session_id = GetString(*args, "sessionId");
      if (!session_id.has_value()) {
        ResultError(result.get(), CapturePluginError::kCaptureFailed,
                    "Invalid stopCapture arguments");
        return;
      }

      CaptureSessionManager::Instance().StopCapture(*session_id);
      result->Success();
      return;
    }

    if (method == "dispose") {
      CaptureSessionManager::Instance().DisposeAll();
      result->Success();
      return;
    }

    result->NotImplemented();
  } catch (const std::exception& error) {
    ResultError(result.get(), CapturePluginError::kCaptureFailed, error.what());
  }
}

}  // namespace desktop_screenshot_capture_windows
