#include "display_enumerator.h"

#include "capture_error_codes.h"

#include <sstream>
#include <stdexcept>

namespace desktop_screenshot_capture_windows {

namespace {

std::string MonitorIdFromHandle(HMONITOR monitor) {
  std::ostringstream stream;
  stream << reinterpret_cast<uintptr_t>(monitor);
  return stream.str();
}

BOOL CALLBACK MonitorEnumCallback(HMONITOR monitor, HDC, LPRECT rect, LPARAM param) {
  auto* monitors = reinterpret_cast<std::vector<MonitorInfo>*>(param);

  MONITORINFOEXW info = {};
  info.cbSize = sizeof(info);
  if (!GetMonitorInfoW(monitor, &info)) {
    return TRUE;
  }

  MonitorInfo entry;
  entry.handle = monitor;
  entry.id = MonitorIdFromHandle(monitor);
  entry.width = rect->right - rect->left;
  entry.height = rect->bottom - rect->top;
  entry.is_primary = (info.dwFlags & MONITORINFOF_PRIMARY) != 0;
  entry.label = "Display " + entry.id + " (" + std::to_string(entry.width) + "x" +
                std::to_string(entry.height) + ")";
  monitors->push_back(std::move(entry));
  return TRUE;
}

}  // namespace

flutter::EncodableMap MonitorInfo::ToMap() const {
  flutter::EncodableMap map;
  map[flutter::EncodableValue("id")] = flutter::EncodableValue(id);
  map[flutter::EncodableValue("label")] = flutter::EncodableValue(label);
  map[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
  map[flutter::EncodableValue("height")] = flutter::EncodableValue(height);
  map[flutter::EncodableValue("isPrimary")] = flutter::EncodableValue(is_primary);
  return map;
}

std::vector<MonitorInfo> DisplayEnumerator::ListMonitors() {
  std::vector<MonitorInfo> monitors;
  EnumDisplayMonitors(nullptr, nullptr, MonitorEnumCallback,
                      reinterpret_cast<LPARAM>(&monitors));
  return monitors;
}

MonitorInfo DisplayEnumerator::MonitorForId(const std::string& id) {
  const auto monitors = ListMonitors();
  for (const auto& monitor : monitors) {
    if (monitor.id == id) {
      return monitor;
    }
  }
  throw std::runtime_error(CapturePluginErrorMessage(
      CapturePluginError::kSourceDisconnected));
}

MonitorInfo DisplayEnumerator::PrimaryMonitor() {
  const auto monitors = ListMonitors();
  for (const auto& monitor : monitors) {
    if (monitor.is_primary) {
      return monitor;
    }
  }
  if (monitors.empty()) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kCaptureApiUnavailable));
  }
  return monitors.front();
}

}  // namespace desktop_screenshot_capture_windows
