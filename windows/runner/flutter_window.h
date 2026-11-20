#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>

#include <memory>

#include "gallery_image_saver.h"
#include "win32_window.h"
#include "prayer_taskbar_bridge.h"
#include "windows_notification_bridge.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject &project);
  virtual ~FlutterWindow();

protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      prayer_system_channel_;
  // Toast clicks: "tapped" to Flutter, "takeTap" from it.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      notification_taps_;
  std::unique_ptr<PrayerTaskbarBridge> prayer_taskbar_bridge_;
  std::unique_ptr<WindowsNotificationBridge> notification_bridge_;
  std::unique_ptr<GalleryImageSaver> gallery_image_saver_;
};

#endif // RUNNER_FLUTTER_WINDOW_H_
