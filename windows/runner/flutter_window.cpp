#include "flutter_window.h"

#include <optional>

#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "windows_notification_activator.h"

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  notification_bridge_ = std::make_unique<WindowsNotificationBridge>(
      flutter_controller_->engine()->messenger(), GetHandle());
  notification_taps_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.aw.huda/windows_notification_taps",
          &flutter::StandardMethodCodec::GetInstance());
  notification_taps_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "takeTap") {
          result->NotImplemented();
          return;
        }
        const auto payload = WindowsNotificationActivator::TakePayload();
        result->Success(payload ? flutter::EncodableValue(*payload)
                                : flutter::EncodableValue());
      });
  WindowsNotificationActivator::SetWindow(GetHandle());
  prayer_system_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.aw.huda/prayer_system",
          &flutter::StandardMethodCodec::GetInstance());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  WindowsNotificationActivator::SetWindow(nullptr);
  notification_taps_.reset();
  notification_bridge_.reset();
  prayer_system_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (notification_bridge_ && notification_bridge_->HandleMessage(message)) {
    return 0;
  }
  if (message == WindowsNotificationActivator::kMessage) {
    // A toast was clicked: bring Huda forward, then Flutter takes the payload.
    ShowWindow(hwnd, SW_RESTORE);
    SetForegroundWindow(hwnd);
    if (notification_taps_) notification_taps_->InvokeMethod("tapped", nullptr);
    return 0;
  }
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
  case WM_TIMECHANGE:
    if (prayer_system_channel_) {
      prayer_system_channel_->InvokeMethod(
          "systemChanged", std::make_unique<flutter::EncodableValue>("time"));
    }
    break;
  case WM_POWERBROADCAST:
    if (wparam == PBT_APMRESUMEAUTOMATIC && prayer_system_channel_) {
      prayer_system_channel_->InvokeMethod(
          "systemChanged", std::make_unique<flutter::EncodableValue>("resume"));
    }
    break;
  case WM_ACTIVATE:
    if (LOWORD(wparam) != WA_INACTIVE && prayer_system_channel_) {
      prayer_system_channel_->InvokeMethod(
          "systemChanged",
          std::make_unique<flutter::EncodableValue>("activation"));
    }
    break;
  case WM_FONTCHANGE:
    flutter_controller_->engine()->ReloadSystemFonts();
    break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
