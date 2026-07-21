#ifndef DISPLAY_ENUMERATOR_H_
#define DISPLAY_ENUMERATOR_H_

#include <flutter/encodable_value.h>
#include <windows.h>

#include <string>
#include <vector>

namespace desktop_screenshot_capture_windows {

struct MonitorInfo {
  std::string id;
  std::string label;
  int width = 0;
  int height = 0;
  bool is_primary = false;
  HMONITOR handle = nullptr;

  flutter::EncodableMap ToMap() const;
};

class DisplayEnumerator {
 public:
  static std::vector<MonitorInfo> ListMonitors();
  static MonitorInfo MonitorForId(const std::string& id);
  static MonitorInfo PrimaryMonitor();
};

}  // namespace desktop_screenshot_capture_windows

#endif  // DISPLAY_ENUMERATOR_H_
