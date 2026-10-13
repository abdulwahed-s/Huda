#ifndef RUNNER_PRAYER_TASKBAR_BRIDGE_H_
#define RUNNER_PRAYER_TASKBAR_BRIDGE_H_

#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <windows.h>

#include <atomic>
#include <condition_variable>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

// The bridge is owned by FlutterWindow. Destroying it never quits the companion.
class PrayerTaskbarBridge {
 public:
  PrayerTaskbarBridge(flutter::BinaryMessenger* messenger, HWND window);
  ~PrayerTaskbarBridge();
  bool HandleMessage(UINT message);
  static std::wstring UserSid();
  static bool ActivateExisting(const std::string& action);
  static std::string ActivationAction(const std::vector<std::string>& arguments);

 private:
  using Value = flutter::EncodableValue;
  using Result = flutter::MethodResult<Value>;
  struct Job {
    uint64_t id;
    std::string method;
    std::string json;
    int64_t revision = 0;
    bool enabled = false;
    bool startup = false;
    bool update_startup = false;
  };
  struct Reply { uint64_t id; std::string json; std::string error; };
  void Worker();
  void ActivationServer();
  void Navigate(const std::string& action);
  std::string Status();
  Reply Execute(const Job& job);
  std::string HelperCommand(const std::wstring& arguments);
  bool LaunchHelper();
  bool SaveConfiguration(const Job& job);

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<Value>> channel_;
  std::wstring directory_;
  std::wstring helper_;
  std::wstring app_pipe_;
  HANDLE activation_pipe_ = INVALID_HANDLE_VALUE;
  std::atomic<bool> stopping_{false};
  std::thread worker_;
  std::thread activation_worker_;
  std::mutex mutex_;
  std::condition_variable wake_;
  std::deque<Job> jobs_;
  std::deque<Reply> replies_;
  std::deque<std::string> navigations_;
  std::map<uint64_t, std::unique_ptr<Result>> results_;
  uint64_t next_id_ = 0;
  int64_t revision_ = 0;
  bool dart_ready_ = false;
  std::string pending_action_;
};

#endif
