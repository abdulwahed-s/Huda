#include "windows_notification_bridge.h"

#include <flutter/standard_method_codec.h>
#include <winrt/base.h>

#include <limits>
#include <stdexcept>

#include "windows_notification_worker.h"

namespace {
constexpr char kChannel[] = "com.aw.huda/windows_notifications";
constexpr UINT kReplyMessage = WM_APP + 0x63;
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;
using List = flutter::EncodableList;

const Value& Field(const Map& arguments, const char* key) {
  const auto found = arguments.find(Value(key));
  if (found == arguments.end()) throw std::invalid_argument(key);
  return found->second;
}

int64_t Integer(const Value& value) {
  if (const auto number = std::get_if<int32_t>(&value)) return *number;
  return std::get<int64_t>(value);
}

int Id(const Map& arguments) {
  const auto id = Integer(Field(arguments, "id"));
  if (id < 0 || id > std::numeric_limits<int32_t>::max()) {
    throw std::invalid_argument("invalid notification id");
  }
  return static_cast<int>(id);
}

Value Execute(WindowsNotificationWorker& worker, const std::string& method,
              const Map& args) {
  if (method == "identity") return Value(worker.PackageFullName());
  const auto app_id = std::get<std::string>(Field(args, "appId"));
  if (method == "register") {
    worker.RegisterApp(app_id, std::get<std::string>(Field(args, "appName")),
                       std::get<std::string>(Field(args, "activatorGuid")));
    return Value();
  }
  if (method == "settings") return Value(worker.NotificationSetting(app_id));
  if (method == "initialize") return Value(worker.Initialize(app_id));
  const auto token = Integer(Field(args, "snapshot"));
  if (method == "pending") {
    const auto snapshot = worker.Pending(app_id, token);
    List items;
    for (const auto& item : snapshot.items) {
      items.emplace_back(Map{
          {Value("tag"), Value(item.tag)}, {Value("group"), Value(item.group)},
          {Value("payload"), Value(item.payload)},
          {Value("title"), Value(item.title)}, {Value("body"), Value(item.body)},
          {Value("seconds"), Value(item.delivery_seconds)}});
      std::get<Map>(items.back())[Value("silent")] = Value(item.silent);
    }
    return Value(Map{{Value("snapshot"), Value(snapshot.token)},
                     {Value("items"), Value(std::move(items))}});
  }
  if (method == "release") {
    worker.Release(app_id, token);
    return Value();
  }
  const bool protect = std::get<bool>(Field(args, "protectNearDue"));
  WindowsToastMutation mutation;
  if (method == "schedule") {
    mutation = worker.Schedule(
        app_id, token, Id(args), Integer(Field(args, "seconds")),
        std::get<std::string>(Field(args, "title")),
        std::get<std::string>(Field(args, "body")),
        std::get<std::string>(Field(args, "payload")), protect,
        args.find(Value("silent")) != args.end() && std::get<bool>(Field(args, "silent")),
        args.find(Value("shortDuration")) != args.end() &&
            std::get<bool>(Field(args, "shortDuration")));
  } else if (method == "cancel") {
    mutation = worker.Cancel(app_id, token, Id(args), protect);
  } else {
    throw std::invalid_argument("unknown notification command");
  }
  return Value(Map{{Value("added"), Value(mutation.added)},
                   {Value("removed"), Value(mutation.removed)}});
}
}  // namespace

WindowsNotificationBridge::WindowsNotificationBridge(
    flutter::BinaryMessenger* messenger, HWND window)
    : messenger_(messenger), window_(window) {
  messenger_->SetMessageHandler(kChannel, [this](const uint8_t* data, size_t size,
                                                flutter::BinaryReply reply) {
    {
      std::lock_guard<std::mutex> lock(mutex_);
      jobs_.push_back({std::vector<uint8_t>(data, data + size), std::move(reply)});
    }
    ready_.notify_one();
  });
  thread_ = std::thread([this]() { Run(); });
}

WindowsNotificationBridge::~WindowsNotificationBridge() {
  messenger_->SetMessageHandler(kChannel, nullptr);
  {
    std::lock_guard<std::mutex> lock(mutex_);
    stopping_ = true;
  }
  ready_.notify_one();
  thread_.join();
  // Replies own engine response handles; release them before engine teardown.
  for (const auto& reply : replies_) reply.reply(nullptr, 0);
  for (const auto& job : jobs_) job.reply(nullptr, 0);
}

void WindowsNotificationBridge::Run() {
  std::unique_ptr<WindowsNotificationWorker> worker;
  const auto& codec = flutter::StandardMethodCodec::GetInstance();
  while (true) {
    Message job;
    {
      std::unique_lock<std::mutex> lock(mutex_);
      ready_.wait(lock, [this]() { return stopping_ || !jobs_.empty(); });
      if (stopping_) break;
      job = std::move(jobs_.front());
      jobs_.pop_front();
    }
    std::unique_ptr<std::vector<uint8_t>> envelope;
    try {
      if (!worker) worker = std::make_unique<WindowsNotificationWorker>();
      const auto call = codec.DecodeMethodCall(job.bytes);
      if (!call || !call->arguments()) throw std::invalid_argument("invalid command");
      const auto result = Execute(*worker, call->method_name(),
                                 std::get<Map>(*call->arguments()));
      envelope = codec.EncodeSuccessEnvelope(&result);
    } catch (const winrt::hresult_error& error) {
      const Value details(Map{{Value("hresult"), Value(static_cast<int64_t>(error.code().value))},
                              {Value("uncertain"), Value(true)}});
      envelope = codec.EncodeErrorEnvelope("windows-notification-error",
                                           winrt::to_string(error.message()), &details);
    } catch (const std::exception& error) {
      envelope = codec.EncodeErrorEnvelope("windows-notification-error", error.what());
    } catch (...) {
      envelope = codec.EncodeErrorEnvelope("windows-notification-error", "unknown native error");
    }
    {
      std::lock_guard<std::mutex> lock(mutex_);
      replies_.push_back({std::move(*envelope), std::move(job.reply)});
    }
    PostMessageW(window_, kReplyMessage, 0, 0);
  }
  // The apartment and all retained handles are destroyed on this thread.
}

bool WindowsNotificationBridge::HandleMessage(UINT message) {
  if (message != kReplyMessage) return false;
  std::deque<Message> replies;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    replies.swap(replies_);
  }
  for (const auto& reply : replies) {
    reply.reply(reply.bytes.data(), reply.bytes.size());
  }
  return true;
}
