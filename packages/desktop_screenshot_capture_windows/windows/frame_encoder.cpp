#include "frame_encoder.h"

#include "capture_error_codes.h"

#include <wincodec.h>
#include <windows.h>
#include <wrl/client.h>

#include <algorithm>
#include <filesystem>
#include <sstream>
#include <stdexcept>

namespace desktop_screenshot_capture_windows {

namespace {

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return L"";
  }

  const int length =
      MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                          nullptr, 0);
  if (length <= 0) {
    throw std::runtime_error("Invalid UTF-8 path.");
  }

  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                      wide.data(), length);
  return wide;
}

GUID EncoderClsidForFormat(const std::string& format) {
  if (format == "png") {
    return {0x557cf406, 0x1a04, 0x11d3, {0x9a, 0x73, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e}};
  }
  return {0x557cf401, 0x1a04, 0x11d3, {0x9a, 0x73, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e}};
}

std::string HResultMessage(HRESULT hr) {
  std::ostringstream stream;
  stream << "HRESULT 0x" << std::hex << hr;
  return stream.str();
}

}  // namespace

int FrameEncoder::Encode(const std::vector<uint8_t>& bgra_pixels,
                         int width,
                         int height,
                         const std::string& format,
                         int quality,
                         const std::string& output_path) {
  if (width <= 0 || height <= 0) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Invalid image dimensions."));
  }

  const std::filesystem::path output = std::filesystem::u8path(output_path);
  const auto parent = output.parent_path();
  std::error_code ec;
  std::filesystem::create_directories(parent, ec);
  if (ec) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kDirectoryCreationFailed));
  }

  Microsoft::WRL::ComPtr<IWICImagingFactory> factory;
  HRESULT hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not create WIC factory."));
  }

  const std::wstring wide_path = Utf8ToWide(output_path);
  Microsoft::WRL::ComPtr<IWICStream> stream;
  hr = factory->CreateStream(&stream);
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not create WIC stream."));
  }

  hr = stream->InitializeFromFilename(wide_path.c_str(), GENERIC_WRITE);
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kDiskWriteFailed));
  }

  Microsoft::WRL::ComPtr<IWICBitmapEncoder> encoder;
  hr = factory->CreateEncoder(EncoderClsidForFormat(format), nullptr, &encoder);
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not create WIC encoder."));
  }

  hr = encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache);
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not initialize WIC encoder."));
  }

  Microsoft::WRL::ComPtr<IWICBitmapFrameEncode> frame;
  Microsoft::WRL::ComPtr<IPropertyBag2> properties;
  hr = encoder->CreateNewFrame(&frame, &properties);
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not create WIC frame."));
  }

  hr = frame->Initialize(properties.Get());
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not initialize WIC frame."));
  }

  hr = frame->SetSize(static_cast<UINT>(width), static_cast<UINT>(height));
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not set WIC frame size."));
  }

  WICPixelFormatGUID pixel_format = GUID_WICPixelFormat32bppBGRA;
  hr = frame->SetPixelFormat(&pixel_format);
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not set WIC pixel format."));
  }

  if (format != "png" && properties) {
    PROPBAG2 option = {};
    option.pstrName = const_cast<LPOLESTR>(L"ImageQuality");
    const float normalized_quality =
        static_cast<float>(std::max(0, std::min(quality, 100))) / 100.0f;
    VARIANT variant;
    VariantInit(&variant);
    variant.vt = VT_R4;
    variant.fltVal = normalized_quality;
    hr = properties->Write(1, &option, &variant);
    VariantClear(&variant);
    if (FAILED(hr)) {
      throw std::runtime_error(CapturePluginErrorMessage(
          CapturePluginError::kEncodingFailed, "Could not set JPEG quality."));
    }
  }

  const UINT stride = static_cast<UINT>(width * 4);
  const UINT buffer_size = stride * static_cast<UINT>(height);
  if (bgra_pixels.size() < buffer_size) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Pixel buffer too small."));
  }

  hr = frame->WritePixels(static_cast<UINT>(height), stride, buffer_size,
                          const_cast<BYTE*>(bgra_pixels.data()));
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not write WIC pixels."));
  }

  hr = frame->Commit();
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not commit WIC frame."));
  }

  hr = encoder->Commit();
  if (FAILED(hr)) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kEncodingFailed, "Could not commit WIC encoder."));
  }

  const auto file_size = std::filesystem::file_size(output, ec);
  if (ec) {
    throw std::runtime_error(CapturePluginErrorMessage(
        CapturePluginError::kDiskWriteFailed));
  }
  return static_cast<int>(file_size);
}

}  // namespace desktop_screenshot_capture_windows
