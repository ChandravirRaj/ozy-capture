#ifndef D3D_CAPTURE_HELPERS_H_
#define D3D_CAPTURE_HELPERS_H_

#include <d3d11.h>
#include <windows.graphics.capture.interop.h>
#include <windows.graphics.directx.direct3d11.interop.h>
#include <winrt/base.h>
#include <winrt/Windows.Graphics.Capture.h>
#include <winrt/Windows.Graphics.DirectX.Direct3D11.h>

#include <cstdint>
#include <string>
#include <vector>
#include <wrl/client.h>

namespace desktop_screenshot_capture_windows {

struct CapturedFrame {
  int width = 0;
  int height = 0;
  std::vector<uint8_t> bgra_pixels;
};

Microsoft::WRL::ComPtr<ID3D11Device> CreateD3D11Device();
winrt::Windows::Graphics::DirectX::Direct3D11::IDirect3DDevice
CreateDirect3DDevice(ID3D11Device* device);

bool ProbeMonitorCapture(HMONITOR monitor, std::string* error_message);

CapturedFrame CopyFrameSurfaceToBgra(
    const winrt::Windows::Graphics::Capture::Direct3D11CaptureFrame& frame,
    ID3D11Device* device,
    ID3D11DeviceContext* context);

}  // namespace desktop_screenshot_capture_windows

#endif  // D3D_CAPTURE_HELPERS_H_
