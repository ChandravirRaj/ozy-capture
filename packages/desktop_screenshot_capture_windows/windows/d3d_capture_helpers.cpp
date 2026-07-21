#include "d3d_capture_helpers.h"

#include <dxgi.h>
#include <winrt/Windows.Graphics.Capture.h>
#include <winrt/Windows.Graphics.DirectX.Direct3D11.h>

#include <cstring>
#include <sstream>
#include <stdexcept>

namespace desktop_screenshot_capture_windows {

namespace {

std::string HResultMessage(HRESULT hr) {
  std::ostringstream stream;
  stream << "HRESULT 0x" << std::hex << hr;
  return stream.str();
}

}  // namespace

Microsoft::WRL::ComPtr<ID3D11Device> CreateD3D11Device() {
  Microsoft::WRL::ComPtr<ID3D11Device> device;
  D3D_FEATURE_LEVEL feature_levels[] = {D3D_FEATURE_LEVEL_11_0};
  D3D_FEATURE_LEVEL chosen_level = D3D_FEATURE_LEVEL_11_0;
  const HRESULT hr = D3D11CreateDevice(
      nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, D3D11_CREATE_DEVICE_BGRA_SUPPORT,
      feature_levels, 1, D3D11_SDK_VERSION, &device, &chosen_level, nullptr);
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create D3D11 device: " + HResultMessage(hr));
  }
  return device;
}

winrt::Windows::Graphics::DirectX::Direct3D11::IDirect3DDevice
CreateDirect3DDevice(ID3D11Device* device) {
  Microsoft::WRL::ComPtr<IDXGIDevice> dxgi_device;
  const HRESULT hr = device->QueryInterface(IID_PPV_ARGS(&dxgi_device));
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to query DXGI device: " + HResultMessage(hr));
  }

  winrt::com_ptr<IInspectable> inspectable;
  const HRESULT create_hr =
      CreateDirect3D11DeviceFromDXGIDevice(dxgi_device.Get(), inspectable.put());
  if (FAILED(create_hr)) {
    throw std::runtime_error("Failed to create WinRT D3D device: " +
                             HResultMessage(create_hr));
  }
  return inspectable.as<winrt::Windows::Graphics::DirectX::Direct3D11::IDirect3DDevice>();
}

CapturedFrame CopyFrameSurfaceToBgra(
    const winrt::Windows::Graphics::Capture::Direct3D11CaptureFrame& frame,
    ID3D11Device* device,
    ID3D11DeviceContext* context) {
  const auto surface = frame.Surface();
  const auto access = surface.as<
      winrt::Windows::Graphics::DirectX::Direct3D11::IDirect3DDxgiInterfaceAccess>();

  Microsoft::WRL::ComPtr<ID3D11Texture2D> texture;
  const HRESULT query_hr =
      access->GetInterface(IID_PPV_ARGS(texture.GetAddressOf()));
  if (FAILED(query_hr)) {
    throw std::runtime_error("Failed to access capture texture: " +
                             HResultMessage(query_hr));
  }

  D3D11_TEXTURE2D_DESC desc = {};
  texture->GetDesc(&desc);

  D3D11_TEXTURE2D_DESC staging_desc = desc;
  staging_desc.BindFlags = 0;
  staging_desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  staging_desc.Usage = D3D11_USAGE_STAGING;
  staging_desc.MiscFlags = 0;

  Microsoft::WRL::ComPtr<ID3D11Texture2D> staging;
  const HRESULT create_hr =
      device->CreateTexture2D(&staging_desc, nullptr, staging.GetAddressOf());
  if (FAILED(create_hr)) {
    throw std::runtime_error("Failed to create staging texture: " +
                             HResultMessage(create_hr));
  }

  context->CopyResource(staging.Get(), texture.Get());

  D3D11_MAPPED_SUBRESOURCE mapped = {};
  const HRESULT map_hr = context->Map(staging.Get(), 0, D3D11_MAP_READ, 0, &mapped);
  if (FAILED(map_hr)) {
    throw std::runtime_error("Failed to map staging texture: " +
                             HResultMessage(map_hr));
  }

  CapturedFrame captured;
  captured.width = static_cast<int>(desc.Width);
  captured.height = static_cast<int>(desc.Height);
  const size_t row_bytes = static_cast<size_t>(captured.width) * 4;
  captured.bgra_pixels.resize(row_bytes * static_cast<size_t>(captured.height));

  auto* destination = captured.bgra_pixels.data();
  const auto* source = static_cast<const uint8_t*>(mapped.pData);
  for (int row = 0; row < captured.height; ++row) {
    memcpy(destination + row * row_bytes, source + row * mapped.RowPitch, row_bytes);
  }

  context->Unmap(staging.Get(), 0);
  return captured;
}

bool ProbeMonitorCapture(HMONITOR monitor, std::string* error_message) {
  try {
    if (!winrt::Windows::Graphics::Capture::GraphicsCaptureSession::IsSupported()) {
      if (error_message != nullptr) {
        *error_message = "Windows Graphics Capture is not supported on this system.";
      }
      return false;
    }

    auto activation_factory =
        winrt::get_activation_factory<winrt::Windows::Graphics::Capture::GraphicsCaptureItem>();
    auto interop = activation_factory.as<IGraphicsCaptureItemInterop>();
    winrt::Windows::Graphics::Capture::GraphicsCaptureItem item{nullptr};
    const HRESULT hr =
        interop->CreateForMonitor(monitor, winrt::guid_of<ABI::Windows::Graphics::Capture::IGraphicsCaptureItem>(),
                                  winrt::put_abi(item));
    if (FAILED(hr) || !item) {
      if (error_message != nullptr) {
        *error_message = "CreateForMonitor failed: " + HResultMessage(hr);
      }
      return false;
    }

    auto d3d_device = CreateD3D11Device();
    auto direct3d_device = CreateDirect3DDevice(d3d_device.Get());
    const auto size = item.Size();
    auto frame_pool = winrt::Windows::Graphics::Capture::Direct3D11CaptureFramePool::Create(
        direct3d_device, winrt::Windows::Graphics::DirectX::DirectXPixelFormat::B8G8R8A8UIntNormalized,
        1, size);
    auto session = frame_pool.CreateCaptureSession(item);
    session.StartCapture();
    session.Close();
    frame_pool.Close();
    return true;
  } catch (const winrt::hresult_error& error) {
    if (error_message != nullptr) {
      *error_message = winrt::to_string(error.message());
    }
    return false;
  } catch (const std::exception& error) {
    if (error_message != nullptr) {
      *error_message = error.what();
    }
    return false;
  }
}

}  // namespace desktop_screenshot_capture_windows
