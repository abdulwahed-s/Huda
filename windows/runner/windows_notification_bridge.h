#ifndef RUNNER_WINDOWS_NOTIFICATION_BRIDGE_H_
#define RUNNER_WINDOWS_NOTIFICATION_BRIDGE_H_

#include <windows.h>
#include <flutter/binary_messenger.h>

#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>
#include <vector>

class WindowsNotificationBridge {
 public:
  WindowsNotificationBridge(flutter::BinaryMessenger* messenger, HWND window);
  ~WindowsNotificationBridge();
  bool HandleMessage(UINT message);

 private:
  struct Message {
    std::vector<uint8_t> bytes;
    flutter::BinaryReply reply;
  };
  void Run();
  flutter::BinaryMessenger* messenger_;
  HWND window_;
  std::mutex mutex_;
  std::condition_variable ready_;
  std::deque<Message> jobs_;
  std::deque<Message> replies_;
  bool stopping_ = false;
  std::thread thread_;
};

#endif
