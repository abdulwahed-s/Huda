#ifndef RUNNER_WINDOWS_NOTIFICATION_WORKER_H_
#define RUNNER_WINDOWS_NOTIFICATION_WORKER_H_

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

struct WindowsPendingToast {
  std::string tag;
  std::string group;
  std::string payload;
  std::string title;
  std::string body;
  int64_t delivery_seconds;
  bool silent = false;
};

struct WindowsToastSnapshot {
  int64_t token;
  std::vector<WindowsPendingToast> items;
};

struct WindowsToastMutation {
  int added = 0;
  int removed = 0;
};

// Construct, use and destroy on the bridge's single MTA thread. No WinRT
// object or native notification handle crosses that thread boundary.
class WindowsNotificationWorker {
 public:
  WindowsNotificationWorker();
  ~WindowsNotificationWorker();
  WindowsNotificationWorker(const WindowsNotificationWorker&) = delete;
  WindowsNotificationWorker& operator=(const WindowsNotificationWorker&) = delete;

  bool Initialize(const std::string& app_id);
  // The Flutter plugin owns the live COM callback. Complete its persistent
  // desktop registration without changing Windows notification preferences.
  void RegisterApp(const std::string& app_id, const std::string& app_name,
                   const std::string& activator_guid);
  int NotificationSetting(const std::string& app_id);
  std::string PackageFullName() const;
  WindowsToastSnapshot Pending(const std::string& app_id, int64_t previous_token);
  WindowsToastMutation Schedule(const std::string& app_id, int64_t token,
                                int id, int64_t delivery_seconds,
                                const std::string& title,
                                const std::string& body,
                                const std::string& payload,
                                bool protect_near_due,
                                bool silent_audio = false,
                                bool short_duration = false);
  WindowsToastMutation Cancel(const std::string& app_id, int64_t token, int id,
                              bool protect_near_due);
  void Release(const std::string& app_id, int64_t token);

 private:
  struct State;
  std::unique_ptr<State> state_;
};

#endif
