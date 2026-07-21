#ifndef FLUTTER_PLUGIN_DESKTOP_SCREENSHOT_CAPTURE_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_DESKTOP_SCREENSHOT_CAPTURE_WINDOWS_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace desktop_screenshot_capture_windows {

class CaptureEventStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override;

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* arguments) override;

 private:
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
};

class DesktopScreenshotCaptureWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  DesktopScreenshotCaptureWindowsPlugin();

  virtual ~DesktopScreenshotCaptureWindowsPlugin();

  DesktopScreenshotCaptureWindowsPlugin(
      const DesktopScreenshotCaptureWindowsPlugin&) = delete;
  DesktopScreenshotCaptureWindowsPlugin& operator=(
      const DesktopScreenshotCaptureWindowsPlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace desktop_screenshot_capture_windows

#endif  // FLUTTER_PLUGIN_DESKTOP_SCREENSHOT_CAPTURE_WINDOWS_PLUGIN_H_
