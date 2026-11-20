#include "gallery_image_saver.h"

#include <windows.h>

#include <flutter/standard_method_codec.h>
#include <knownfolders.h>
#include <shlobj.h>

#include <cstdint>
#include <cwchar>
#include <optional>
#include <string>
#include <vector>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) return std::wstring();
  const int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(),
                                       static_cast<int>(text.size()), nullptr, 0);
  if (size <= 0) return std::wstring();
  std::wstring wide(size, L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.data(),
                      static_cast<int>(text.size()), wide.data(), size);
  return wide;
}

std::string WideToUtf8(const std::wstring& text) {
  if (text.empty()) return std::string();
  const int size = WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                                       nullptr, 0, nullptr, nullptr);
  std::string utf8(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), utf8.data(), size,
                      nullptr, nullptr);
  return utf8;
}

// Characters Windows doesn't allow in file names become underscores; trailing
// dots and spaces, which Windows drops, are trimmed.
std::wstring Sanitize(std::wstring name) {
  for (auto& c : name) {
    if (c < 32 || wcschr(L"<>:\"/\\|?*", c) != nullptr) c = L'_';
  }
  while (!name.empty() && (name.back() == L'.' || name.back() == L' ')) name.pop_back();
  if (name.size() > 120) name.resize(120);
  return name;
}

std::optional<std::wstring> DownloadsFolder() {
  PWSTR path = nullptr;
  const HRESULT hr = SHGetKnownFolderPath(FOLDERID_Downloads, KF_FLAG_CREATE, nullptr, &path);
  std::optional<std::wstring> folder;
  if (SUCCEEDED(hr) && path != nullptr) folder = std::wstring(path);
  CoTaskMemFree(path);
  return folder;
}

// Writes [bytes] to a new file: CREATE_NEW never replaces one, so a taken
// name moves on to the next "(n)".
std::optional<std::string> Save(const std::vector<uint8_t>& bytes, const std::wstring& name) {
  const auto folder = DownloadsFolder();
  if (!folder) return "The Downloads folder is unavailable.";
  for (int index = 1; index < 1000; index++) {
    std::wstring path = *folder + L"\\" + name;
    if (index > 1) path += L" (" + std::to_wstring(index) + L")";
    path += L".png";
    HANDLE file = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW,
                              FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) {
      if (GetLastError() == ERROR_FILE_EXISTS) continue;
      return "Could not create " + WideToUtf8(path) + ".";
    }
    DWORD written = 0;
    const BOOL ok = WriteFile(file, bytes.data(), static_cast<DWORD>(bytes.size()), &written,
                              nullptr);
    CloseHandle(file);
    if (!ok || written != bytes.size()) {
      DeleteFileW(path.c_str());
      return "Could not write " + WideToUtf8(path) + ".";
    }
    return std::nullopt;
  }
  return "Too many files with this name in Downloads.";
}

}  // namespace

GalleryImageSaver::GalleryImageSaver(flutter::BinaryMessenger* messenger)
    : channel_(std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger, "com.aw.huda/gallery", &flutter::StandardMethodCodec::GetInstance())) {
  channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        if (call.method_name() != "saveImage") {
          result->NotImplemented();
          return;
        }
        const auto* arguments = std::get_if<EncodableMap>(call.arguments());
        const std::vector<uint8_t>* bytes = nullptr;
        const std::string* name = nullptr;
        if (arguments != nullptr) {
          auto found = arguments->find(EncodableValue("bytes"));
          if (found != arguments->end()) bytes = std::get_if<std::vector<uint8_t>>(&found->second);
          found = arguments->find(EncodableValue("name"));
          if (found != arguments->end()) name = std::get_if<std::string>(&found->second);
        }
        const std::wstring file_name = name ? Sanitize(Utf8ToWide(*name)) : std::wstring();
        if (bytes == nullptr || bytes->empty() || file_name.empty()) {
          result->Error("invalid_arguments", "saveImage needs bytes and a name.");
          return;
        }
        if (const auto error = Save(*bytes, file_name)) {
          result->Error("save_failed", *error);
          return;
        }
        result->Success(EncodableValue(true));
      });
}
