#ifndef FRAME_ENCODER_H_
#define FRAME_ENCODER_H_

#include <cstdint>
#include <string>
#include <vector>

namespace desktop_screenshot_capture_windows {

class FrameEncoder {
 public:
  static int Encode(const std::vector<uint8_t>& bgra_pixels,
                    int width,
                    int height,
                    const std::string& format,
                    int quality,
                    const std::string& output_path);
};

}  // namespace desktop_screenshot_capture_windows

#endif  // FRAME_ENCODER_H_
