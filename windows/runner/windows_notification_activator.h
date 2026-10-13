#ifndef RUNNER_WINDOWS_NOTIFICATION_ACTIVATOR_H_
#define RUNNER_WINDOWS_NOTIFICATION_ACTIVATOR_H_

#include <windows.h>

#include <optional>
#include <string>

// Opens Huda when one of its toasts is clicked. Windows calls this COM class,
// the toast activator registered for Huda's AppUserModelID: in the running
// process, or after starting Huda with --notification-activated. Toasts from
// Huda, from its prayer companion and from older releases (which used
// flutter_local_notifications) all use the same class ID, so they all land
// here. The ID matches the shortcut, the installer, the MSIX manifest
// (pubspec `toast_activator`) and WindowsNotificationRegistration.
namespace WindowsNotificationActivator {

// Posted to the window when a toast was clicked.
constexpr UINT kMessage = WM_APP + 0x64;

// Registers the class object for this process. Call once on the main thread
// before the message loop, so an activation that started Huda arrives.
bool Register();
void Unregister();

// Where clicks are posted; a click before the window exists is kept.
void SetWindow(HWND window);

// The clicked toast's launch arguments (its payload), once.
std::optional<std::string> TakePayload();

}  // namespace WindowsNotificationActivator

#endif
