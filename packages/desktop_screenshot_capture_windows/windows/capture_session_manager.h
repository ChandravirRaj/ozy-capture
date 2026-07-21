#ifndef CAPTURE_SESSION_MANAGER_H_
#define CAPTURE_SESSION_MANAGER_H_

#include <flutter/encodable_value.h>
#include <flutter/event_sink.h>

#include "display_enumerator.h"

#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>

namespace desktop_screenshot_capture_windows {

class CaptureSessionManager {
 public:
  static CaptureSessionManager& Instance();

  void SetEventSink(flutter::EventSink<flutter::EncodableValue>* event_sink);

  flutter::EncodableMap PrepareCapture(const std::string& session_id,
                                       const std::string& display_id);

  flutter::EncodableMap TakeScreenshot(const std::string& session_id,
                                       const std::string& output_path,
                                       const std::string& format,
                                       int quality);

  void StopCapture(const std::string& session_id);
  void DisposeAll();

 private:
  CaptureSessionManager() = default;

  struct ActiveSession;

  void EmitEvent(const std::string& type,
                 const std::string& session_id,
                 const flutter::EncodableMap& extra);

  std::mutex mutex_;
  flutter::EventSink<flutter::EncodableValue>* event_sink_ = nullptr;
  std::unordered_map<std::string, std::unique_ptr<ActiveSession>> sessions_;
};

}  // namespace desktop_screenshot_capture_windows

#endif  // CAPTURE_SESSION_MANAGER_H_
