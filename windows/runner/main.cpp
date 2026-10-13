#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"
#include "prayer_taskbar_bridge.h"
#include "windows_notification_activator.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  const auto mutex_name = L"Local\\Huda.App." + PrayerTaskbarBridge::UserSid();
  HANDLE app_guard = CreateMutexW(nullptr, TRUE, mutex_name.c_str());
  if (!app_guard) return EXIT_FAILURE;
  const auto acquisition = GetLastError() == ERROR_ALREADY_EXISTS
      ? WaitForSingleObject(app_guard, 0) : WAIT_OBJECT_0;
  if (acquisition != WAIT_OBJECT_0 && acquisition != WAIT_ABANDONED) {
    const auto action = PrayerTaskbarBridge::ActivationAction(GetCommandLineArguments());
    const bool activated = PrayerTaskbarBridge::ActivateExisting(action.empty() ? "home" : action);
    CloseHandle(app_guard);
    ::CoUninitialize();
    return activated ? EXIT_SUCCESS : EXIT_FAILURE;
  }

  // Before the window, so a toast click that started Huda is received.
  WindowsNotificationActivator::Register();

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments({"--enable-notifications"});

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"huda", origin, size)) {
    WindowsNotificationActivator::Unregister();
    ReleaseMutex(app_guard);
    CloseHandle(app_guard);
    ::CoUninitialize();
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  WindowsNotificationActivator::Unregister();
  ::CoUninitialize();
  ReleaseMutex(app_guard);
  CloseHandle(app_guard);
  return EXIT_SUCCESS;
}
