#include "prayer_taskbar_bridge.h"

#include <flutter/standard_method_codec.h>
#include <sddl.h>
#include <shlobj.h>
#include <shellapi.h>

#include <algorithm>
#include <regex>
#include <vector>

#include "utils.h"

namespace {
constexpr UINT kReplyMessage = WM_APP + 0x61;
constexpr UINT kNavigationMessage = WM_APP + 0x62;
constexpr DWORD kMaximumFrame = 1024 * 1024;
using Value = flutter::EncodableValue;
using Map = flutter::EncodableMap;

struct Handle {
  HANDLE value = INVALID_HANDLE_VALUE;
  explicit Handle(HANDLE handle = INVALID_HANDLE_VALUE) : value(handle) {}
  ~Handle() { if (value != INVALID_HANDLE_VALUE && value != nullptr) CloseHandle(value); }
  Handle(const Handle&) = delete;
  Handle& operator=(const Handle&) = delete;
};

struct UserSecurity {
  PSECURITY_DESCRIPTOR descriptor = nullptr;
  SECURITY_ATTRIBUTES attributes{};
  UserSecurity() {
    const auto sid = PrayerTaskbarBridge::UserSid();
    const auto sddl = L"O:" + sid + L"D:P(A;;GA;;;" + sid + L")";
    if (!sid.empty() && ConvertStringSecurityDescriptorToSecurityDescriptorW(
            sddl.c_str(), SDDL_REVISION_1, &descriptor, nullptr)) {
      attributes.nLength = sizeof(attributes);
      attributes.lpSecurityDescriptor = descriptor;
    }
  }
  ~UserSecurity() { if (descriptor) LocalFree(descriptor); }
};

std::wstring CompanionPipe() {
  return L"\\\\.\\pipe\\Huda.PrayerTaskbar." + PrayerTaskbarBridge::UserSid();
}

bool CompanionRunning() {
  const auto name = L"Local\\Huda.PrayerTaskbar." + PrayerTaskbarBridge::UserSid();
  Handle guard(OpenMutexW(SYNCHRONIZE | MUTEX_MODIFY_STATE, FALSE, name.c_str()));
  if (!guard.value) return GetLastError() != ERROR_FILE_NOT_FOUND;
  const auto state = WaitForSingleObject(guard.value, 0);
  if (state == WAIT_OBJECT_0 || state == WAIT_ABANDONED) {
    ReleaseMutex(guard.value);
    return false;
  }
  return true;
}

// Overlapped I/O gives every frame an upper bound; a crashed or malicious peer
// cannot block Flutter's UI or hold an installer indefinitely.
bool Transfer(HANDLE pipe, void* data, DWORD size, bool write, ULONGLONG deadline) {
  auto* cursor = static_cast<char*>(data);
  while (size > 0) {
    if (GetTickCount64() >= deadline) return false;
    Handle event(CreateEventW(nullptr, TRUE, FALSE, nullptr));
    if (!event.value) return false;
    OVERLAPPED overlapped{};
    overlapped.hEvent = event.value;
    DWORD transferred = 0;
    const BOOL complete = write ? WriteFile(pipe, cursor, size, &transferred, &overlapped)
                                : ReadFile(pipe, cursor, size, &transferred, &overlapped);
    if (!complete) {
      if (GetLastError() != ERROR_IO_PENDING) return false;
      const auto now = GetTickCount64();
      const auto remaining = now < deadline
          ? static_cast<DWORD>(deadline - now) : 0;
      if (WaitForSingleObject(event.value, remaining) != WAIT_OBJECT_0) {
        CancelIoEx(pipe, &overlapped);
        GetOverlappedResult(pipe, &overlapped, &transferred, TRUE);
        return false;
      }
      if (!GetOverlappedResult(pipe, &overlapped, &transferred, FALSE)) return false;
    }
    if (transferred == 0 || transferred > size) return false;
    cursor += transferred;
    size -= transferred;
  }
  return true;
}

bool Frame(HANDLE pipe, std::string& text, bool write) {
  const auto deadline = GetTickCount64() + 2500;
  DWORD length = write ? static_cast<DWORD>(text.size()) : 0;
  if (!Transfer(pipe, &length, sizeof(length), write, deadline)) return false;
  if (length == 0 || length > kMaximumFrame) return false;
  if (!write) text.resize(length);
  return Transfer(pipe, text.data(), length, write, deadline);
}

bool SameUser(DWORD process_id) {
  Handle process(OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, process_id));
  HANDLE raw_token = nullptr;
  if (!process.value || process.value == INVALID_HANDLE_VALUE ||
      !OpenProcessToken(process.value, TOKEN_QUERY, &raw_token)) return false;
  Handle token(raw_token);
  DWORD size = 0;
  GetTokenInformation(token.value, TokenUser, nullptr, 0, &size);
  std::vector<char> bytes(size);
  if (!GetTokenInformation(token.value, TokenUser, bytes.data(), size, &size)) return false;
  LPWSTR sid = nullptr;
  if (!ConvertSidToStringSidW(reinterpret_cast<TOKEN_USER*>(bytes.data())->User.Sid, &sid)) return false;
  const bool same = PrayerTaskbarBridge::UserSid() == sid;
  LocalFree(sid);
  return same;
}

std::string Request(const std::wstring& name, const std::string& request,
                    bool allow_foreground = false, bool require_ack = true) {
  Handle pipe(CreateFileW(name.c_str(), GENERIC_READ | GENERIC_WRITE, 0, nullptr,
                         OPEN_EXISTING, FILE_FLAG_OVERLAPPED, nullptr));
  if (pipe.value == INVALID_HANDLE_VALUE) return {};
  ULONG process_id = 0;
  if (!GetNamedPipeServerProcessId(pipe.value, &process_id) || !SameUser(process_id)) return {};
  if (allow_foreground) AllowSetForegroundWindow(process_id);
  std::string frame = request;
  if (!Frame(pipe.value, frame, true) || !Frame(pipe.value, frame, false)) return {};
  if (allow_foreground && require_ack) {
    std::string acknowledgement = "ack";
    if (!Frame(pipe.value, acknowledgement, true)) return {};
  }
  return frame;
}

std::string ReadConfiguration(const std::wstring& directory) {
  const auto path = directory + L"\\configuration.json";
  Handle file(CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                         nullptr, OPEN_EXISTING, 0, nullptr));
  if (file.value == INVALID_HANDLE_VALUE) return {};
  LARGE_INTEGER size{};
  if (!GetFileSizeEx(file.value, &size) || size.QuadPart <= 0 || size.QuadPart > kMaximumFrame) return {};
  std::string json(static_cast<size_t>(size.QuadPart), '\0');
  DWORD read = 0;
  return ReadFile(file.value, json.data(), static_cast<DWORD>(json.size()), &read, nullptr) &&
                 read == json.size() ? json : std::string();
}

bool Exists(const std::wstring& path) {
  const auto flags = GetFileAttributesW(path.c_str());
  return flags != INVALID_FILE_ATTRIBUTES && (flags & FILE_ATTRIBUTE_DIRECTORY) == 0;
}

const Value* Field(const Map* map, const char* key) {
  if (!map) return nullptr;
  const auto found = map->find(Value(key));
  return found == map->end() ? nullptr : &found->second;
}
bool Boolean(const Map* map, const char* key) {
  const auto* value = Field(map, key);
  const auto* flag = value ? std::get_if<bool>(value) : nullptr;
  return flag && *flag;
}
int64_t Integer(const Map* map, const char* key) {
  const auto* value = Field(map, key);
  if (!value) return 0;
  if (const auto* number = std::get_if<int64_t>(value)) return *number;
  if (const auto* number = std::get_if<int32_t>(value)) return *number;
  return 0;
}
}  // namespace

std::wstring PrayerTaskbarBridge::UserSid() {
  HANDLE raw_token = nullptr;
  if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &raw_token)) return {};
  Handle token(raw_token);
  DWORD size = 0;
  GetTokenInformation(token.value, TokenUser, nullptr, 0, &size);
  std::vector<char> bytes(size);
  if (!GetTokenInformation(token.value, TokenUser, bytes.data(), size, &size)) return {};
  LPWSTR sid = nullptr;
  if (!ConvertSidToStringSidW(reinterpret_cast<TOKEN_USER*>(bytes.data())->User.Sid, &sid)) return {};
  std::wstring result(sid);
  LocalFree(sid);
  return result;
}

bool PrayerTaskbarBridge::ActivateExisting(const std::string& action) {
  const auto pipe = L"\\\\.\\pipe\\Huda.App." + UserSid();
  const auto deadline = GetTickCount64() + 5000;
  for (int attempt = 0; attempt < 50 && GetTickCount64() < deadline; ++attempt) {
    if (Request(pipe, action, true) == "ok") return true;
    Sleep(100);
  }
  return false;
}

std::string PrayerTaskbarBridge::ActivationAction(const std::vector<std::string>& arguments) {
  std::string action;
  for (const auto& argument : arguments) {
    if (argument == "--prayer-settings") action = "settings";
    else if (argument == "--prayer-times") action = "prayers";
    else if (argument == "--quran") action = "quran";
    else if (argument == "--athkar") action = "athkar";
    else if (argument == "--open-huda") action = "home";
  }
  return action;
}

PrayerTaskbarBridge::PrayerTaskbarBridge(flutter::BinaryMessenger* messenger, HWND window)
    : window_(window) {
  PWSTR local = nullptr;
  if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, KF_FLAG_NO_PACKAGE_REDIRECTION, nullptr, &local))) {
    directory_ = std::wstring(local) + L"\\Huda\\PrayerTaskbar";
    CoTaskMemFree(local);
  }
  std::vector<wchar_t> executable(32768);
  const auto length = GetModuleFileNameW(nullptr, executable.data(), static_cast<DWORD>(executable.size()));
  std::wstring folder(executable.data(), length);
  folder.resize(folder.find_last_of(L"\\/"));
  helper_ = folder + L"\\prayer_taskbar\\Huda.PrayerTaskbar.exe";
  app_pipe_ = L"\\\\.\\pipe\\Huda.App." + UserSid();
  const auto json = ReadConfiguration(directory_);
  std::smatch match;
  if (std::regex_search(json, match, std::regex("\"revision\"\\s*:\\s*([0-9]+)"))) {
    const auto revision = _strtoi64(match[1].str().c_str(), nullptr, 10);
    if (revision > 0 && revision <= 9007199254740991LL) revision_ = revision;
  }
  pending_action_ = ActivationAction(GetCommandLineArguments());
  UserSecurity security;
  if (security.descriptor) {
    activation_pipe_ = CreateNamedPipeW(app_pipe_.c_str(), PIPE_ACCESS_DUPLEX | FILE_FLAG_OVERLAPPED |
        FILE_FLAG_FIRST_PIPE_INSTANCE, PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT | PIPE_REJECT_REMOTE_CLIENTS,
        1, 4096, 4096, 0, &security.attributes);
  }
  channel_ = std::make_unique<flutter::MethodChannel<Value>>(messenger,
      "com.aw.huda/windows_prayer_taskbar", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const flutter::MethodCall<Value>& call,
                                      std::unique_ptr<Result> result) {
    if (call.method_name() == "initialize") {
      result->Success(Value(Map{{Value("configuration"), Value(ReadConfiguration(directory_))},
          {Value("storagePath"), Value(Utf8FromUtf16(directory_.c_str()))},
          {Value("helperAvailable"), Value(Exists(helper_))}}));
      return;
    }
    if (call.method_name() == "ready") {
      dart_ready_ = true;
      if (!pending_action_.empty()) { const auto action = pending_action_; pending_action_.clear(); Navigate(action); }
      result->Success();
      return;
    }
    if (call.method_name() == "audioPaths") {
      const auto parent = directory_.substr(0, directory_.find_last_of(L'\\'));
      const auto bundled = helper_.substr(0, helper_.find_last_of(L'\\')) + L"\\Assets\\Adhan";
      result->Success(Value(Map{{Value("cache"), Value(Utf8FromUtf16((parent + L"\\PrayerAudio").c_str()))},
          {Value("bundled"), Value(Utf8FromUtf16(bundled.c_str()))}}));
      return;
    }
    if (call.method_name() == "openStartupSettings") {
      ShellExecuteW(window_, L"open", L"ms-settings:startupapps", nullptr, nullptr, SW_SHOWNORMAL);
      result->Success();
      return;
    }
    if (call.method_name() != "getStatus" && call.method_name() != "publishConfiguration" &&
        call.method_name() != "experienceCommand") {
      result->NotImplemented(); return;
    }
    const auto* args = call.arguments() ? std::get_if<Map>(call.arguments()) : nullptr;
    Job job{};
    job.id = ++next_id_;
    job.method = call.method_name();
    if (job.method == "experienceCommand") {
      const auto* raw = Field(args, "json");
      const auto* value = raw ? std::get_if<std::string>(raw) : nullptr;
      if (!value || value->empty() || value->size() > kMaximumFrame) {
        result->Error("invalid_command", "Invalid prayer reminder command."); return;
      }
      job.json = *value;
    }
    if (job.method == "publishConfiguration") {
      const auto* raw = Field(args, "json");
      const auto* value = raw ? std::get_if<std::string>(raw) : nullptr;
      job.revision = Integer(args, "revision");
      if (!value || value->empty() || value->size() > kMaximumFrame ||
          job.revision <= 0 || job.revision > 9007199254740991LL) {
        result->Error("invalid_configuration", "Invalid countdown configuration."); return;
      }
      job.json = *value;
      job.enabled = Boolean(args, "enabled");
      job.startup = Boolean(args, "startWithWindows");
      job.update_startup = Boolean(args, "updateStartup");
    }
    results_[job.id] = std::move(result);
    { std::lock_guard<std::mutex> lock(mutex_); jobs_.push_back(std::move(job)); }
    wake_.notify_one();
  });
  worker_ = std::thread(&PrayerTaskbarBridge::Worker, this);
  if (activation_pipe_ != INVALID_HANDLE_VALUE)
    activation_worker_ = std::thread(&PrayerTaskbarBridge::ActivationServer, this);
}

PrayerTaskbarBridge::~PrayerTaskbarBridge() {
  stopping_ = true;
  if (activation_pipe_ != INVALID_HANDLE_VALUE) CancelIoEx(activation_pipe_, nullptr);
  wake_.notify_all();
  if (activation_worker_.joinable()) activation_worker_.join();
  if (worker_.joinable()) worker_.join();
  if (activation_pipe_ != INVALID_HANDLE_VALUE) CloseHandle(activation_pipe_);
  channel_->SetMethodCallHandler(nullptr);
}

void PrayerTaskbarBridge::Worker() {
  while (!stopping_) {
    Job job{};
    { std::unique_lock<std::mutex> lock(mutex_);
      wake_.wait(lock, [this] { return stopping_ || !jobs_.empty(); });
      if (stopping_) return;
      job = std::move(jobs_.front()); jobs_.pop_front();
    }
    auto reply = Execute(job);
    { std::lock_guard<std::mutex> lock(mutex_); replies_.push_back(std::move(reply)); }
    if (!stopping_) PostMessageW(window_, kReplyMessage, 0, 0);
  }
}

bool PrayerTaskbarBridge::HandleMessage(UINT message) {
  if (message == kReplyMessage) {
    std::deque<Reply> replies;
    { std::lock_guard<std::mutex> lock(mutex_); replies.swap(replies_); }
    for (const auto& reply : replies) {
      const auto found = results_.find(reply.id);
      if (found == results_.end()) continue;
      if (reply.error.empty()) found->second->Success(Value(reply.json));
      else found->second->Error("countdown_failed", reply.error);
      results_.erase(found);
    }
    return true;
  }
  if (message == kNavigationMessage) {
    std::deque<std::string> actions;
    { std::lock_guard<std::mutex> lock(mutex_); actions.swap(navigations_); }
    for (const auto& action : actions) Navigate(action);
    return true;
  }
  return false;
}

void PrayerTaskbarBridge::Navigate(const std::string& action) {
  if (action == "prayer-audio") {
    if (dart_ready_) channel_->InvokeMethod("prayerAudioStarted", nullptr);
    return;
  }
  if (action == "quit") {
    stopping_ = true;
    wake_.notify_all();
    PostMessageW(window_, WM_CLOSE, 0, 0);
    return;
  }
  ShowWindow(window_, SW_RESTORE);
  SetForegroundWindow(window_);
  if (!dart_ready_) { pending_action_ = action; return; }
  const char* method = action == "settings" ? "openPrayerSettings"
      : action == "quran" ? "openQuran" : action == "athkar" ? "openAthkar"
      : action == "home" ? "openHuda" : "openPrayerPage";
  channel_->InvokeMethod(method, nullptr);
}

void PrayerTaskbarBridge::ActivationServer() {
  while (!stopping_) {
    Handle event(CreateEventW(nullptr, TRUE, FALSE, nullptr));
    OVERLAPPED overlapped{}; overlapped.hEvent = event.value;
    bool connected = ConnectNamedPipe(activation_pipe_, &overlapped) != FALSE;
    const auto error = GetLastError();
    if (!connected && error == ERROR_PIPE_CONNECTED) connected = true;
    else if (!connected && error == ERROR_IO_PENDING) {
      while (!stopping_ && WaitForSingleObject(event.value, 100) == WAIT_TIMEOUT) {}
      DWORD count = 0;
      if (stopping_) CancelIoEx(activation_pipe_, &overlapped);
      connected = GetOverlappedResult(activation_pipe_, &overlapped, &count, TRUE) != FALSE;
    }
    if (connected && !stopping_) {
      std::string action;
      if (Frame(activation_pipe_, action, false) &&
          (action == "settings" || action == "prayers" || action == "quran" ||
           action == "athkar" || action == "home" || action == "quit" || action == "prayer-audio")) {
        { std::lock_guard<std::mutex> lock(mutex_); navigations_.push_back(action); }
        std::string response = "ok";
        if (Frame(activation_pipe_, response, true)) {
          // DisconnectNamedPipe discards unread replies. Wait for the client
          // to consume this acknowledgement, using the bounded frame reader.
          std::string acknowledgement;
          Frame(activation_pipe_, acknowledgement, false);
        }
        PostMessageW(window_, kNavigationMessage, 0, 0);
      }
    }
    DisconnectNamedPipe(activation_pipe_);
  }
}

bool PrayerTaskbarBridge::SaveConfiguration(const Job& job) {
  if (directory_.empty() || job.revision <= revision_) return false;
  UserSecurity security;
  if (!security.descriptor) return false;
  auto parent = directory_.substr(0, directory_.find_last_of(L'\\'));
  CreateDirectoryW(parent.c_str(), &security.attributes);
  CreateDirectoryW(directory_.c_str(), &security.attributes);
  const auto destination = directory_ + L"\\configuration.json";
  const auto temporary = directory_ + L"\\configuration.tmp";
  {
    Handle file(CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, &security.attributes,
                           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr));
    DWORD written = 0;
    if (file.value == INVALID_HANDLE_VALUE ||
        !WriteFile(file.value, job.json.data(), static_cast<DWORD>(job.json.size()), &written, nullptr) ||
        written != job.json.size() || !FlushFileBuffers(file.value)) return false;
  }
  const auto backup = directory_ + L"\\configuration.backup.json";
  const bool replaced = Exists(destination)
      ? ReplaceFileW(destination.c_str(), temporary.c_str(), backup.c_str(), REPLACEFILE_IGNORE_MERGE_ERRORS, nullptr, nullptr) != FALSE
      : MoveFileExW(temporary.c_str(), destination.c_str(), MOVEFILE_WRITE_THROUGH) != FALSE;
  if (!replaced) { DeleteFileW(temporary.c_str()); return false; }
  revision_ = job.revision;
  return true;
}

bool PrayerTaskbarBridge::LaunchHelper() {
  if (stopping_ || !Exists(helper_)) return false;
  auto command = L"\"" + helper_ + L"\"";
  STARTUPINFOW startup{}; startup.cb = sizeof(startup);
  PROCESS_INFORMATION process{};
  auto working = helper_.substr(0, helper_.find_last_of(L'\\'));
  if (!CreateProcessW(helper_.c_str(), command.data(), nullptr, nullptr, FALSE, CREATE_NO_WINDOW,
                      nullptr, working.c_str(), &startup, &process)) return false;
  CloseHandle(process.hThread); CloseHandle(process.hProcess);
  return true;
}

std::string PrayerTaskbarBridge::HelperCommand(const std::wstring& arguments) {
  if (!Exists(helper_)) return {};
  SECURITY_ATTRIBUTES security{sizeof(SECURITY_ATTRIBUTES), nullptr, TRUE};
  HANDLE read = nullptr, write = nullptr;
  if (!CreatePipe(&read, &write, &security, 0)) return {};
  Handle reader(read), writer(write);
  SetHandleInformation(read, HANDLE_FLAG_INHERIT, 0);
  STARTUPINFOW startup{}; startup.cb = sizeof(startup);
  startup.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
  startup.hStdOutput = write; startup.hStdError = write; startup.wShowWindow = SW_HIDE;
  PROCESS_INFORMATION process{};
  auto command = L"\"" + helper_ + L"\" " + arguments;
  auto working = helper_.substr(0, helper_.find_last_of(L'\\'));
  if (!CreateProcessW(helper_.c_str(), command.data(), nullptr, nullptr, TRUE, CREATE_NO_WINDOW,
                      nullptr, working.c_str(), &startup, &process)) return {};
  Handle instance(process.hProcess), thread(process.hThread);
  CloseHandle(writer.value); writer.value = nullptr;
  if (WaitForSingleObject(instance.value, 10000) != WAIT_OBJECT_0) {
    // These short-lived startup utilities must not alter registration later
    // after Flutter has reported that the operation failed.
    TerminateProcess(instance.value, 1);
    return {};
  }
  std::string output;
  char buffer[4096]; DWORD count = 0;
  while (ReadFile(read, buffer, sizeof(buffer), &count, nullptr) && count > 0) {
    output.append(buffer, count);
    if (output.size() > kMaximumFrame) return {};
  }
  return output;
}

std::string PrayerTaskbarBridge::Status() {
  const auto running = Request(CompanionPipe(), "{\"command\":\"status\"}");
  if (!running.empty()) return running;
  auto startup = HelperCommand(L"--startup-state");
  if (startup.empty() || startup.front() != '{') startup = "{\"startupState\":\"unavailable\"}";
  return std::string("{\"helperAvailable\":") + (Exists(helper_) ? "true" : "false") +
      ",\"running\":false,\"appliedRevision\":" + std::to_string(revision_) +
      ",\"taskbarPlacement\":\"hidden\"," + startup.substr(1);
}

PrayerTaskbarBridge::Reply PrayerTaskbarBridge::Execute(const Job& job) {
  Reply reply{job.id, {}, {}};
  if (job.method == "getStatus") { reply.json = Status(); return reply; }
  if (job.method == "experienceCommand") {
    reply.json = Request(CompanionPipe(), job.json, true, false);
    if (reply.json.empty() && !CompanionRunning() && LaunchHelper()) {
      const auto deadline = GetTickCount64() + 5000;
      while (reply.json.empty() && !stopping_ && GetTickCount64() < deadline) {
        Sleep(100);
        reply.json = Request(CompanionPipe(), job.json, true, false);
      }
    }
    if (reply.json.empty()) reply.error = "The Windows prayer companion is unavailable.";
    return reply;
  }
  if (!SaveConfiguration(job)) { reply.error = "Could not persist the countdown revision atomically."; return reply; }
  if (job.update_startup) {
    const auto state = HelperCommand(job.startup ? L"--set-startup true" : L"--set-startup false");
    if (Exists(helper_) && (state.empty() || state.front() != '{' ||
        state.find("\"error\"") != std::string::npos))
      reply.error = "Windows could not apply the saved startup preference.";
  }
  if (!job.enabled) {
    auto stopped = Request(CompanionPipe(), "{\"command\":\"shutdown\"}");
    for (int attempt = 0; stopped.empty() && CompanionRunning() && !stopping_ && attempt < 10; ++attempt) {
      Sleep(100);
      stopped = Request(CompanionPipe(), "{\"command\":\"shutdown\"}");
    }
    if ((stopped.empty() && CompanionRunning()) ||
        (!stopped.empty() && stopped.find("\"stopped\":true") == std::string::npos)) {
      reply.error = "The Windows countdown companion did not acknowledge shutdown.";
      return reply;
    }
    // Report saved preferences immediately; shutdown has acknowledged removal.
    auto startup = HelperCommand(L"--startup-state");
    if (startup.empty() || startup.front() != '{') startup = "{\"startupState\":\"unavailable\"}";
    reply.json = std::string("{\"helperAvailable\":") + (Exists(helper_) ? "true" : "false") +
        ",\"running\":false,\"appliedRevision\":" + std::to_string(job.revision) +
        ",\"taskbarPlacement\":\"hidden\"," + startup.substr(1);
    return reply;
  }
  auto applied = Request(CompanionPipe(), "{\"command\":\"reload\"}");
  // A companion from an earlier app launch may still be running after ordinary
  // window close. Replace that legacy process before exposing the new modes.
  if (!applied.empty() && applied.find("\"prayerExperienceVersion\":2") == std::string::npos) {
    const auto stopped = Request(CompanionPipe(), "{\"command\":\"shutdown\"}");
    if (stopped.find("\"stopped\":true") == std::string::npos) {
      reply.error = "The previous Windows prayer companion could not be stopped."; return reply;
    }
    const auto stop_deadline = GetTickCount64() + 5000;
    while (CompanionRunning() && !stopping_ && GetTickCount64() < stop_deadline) Sleep(100);
    if (CompanionRunning()) {
      reply.error = "The previous Windows prayer companion is still exiting."; return reply;
    }
    applied.clear();
  }
  if (applied.empty() && !LaunchHelper()) { reply.error = "The Windows countdown companion is unavailable."; return reply; }
  const auto deadline = GetTickCount64() + 5000;
  for (int attempt = 0; applied.empty() && !stopping_ && attempt < 50 && GetTickCount64() < deadline; ++attempt) {
    Sleep(100);
    applied = Request(CompanionPipe(), "{\"command\":\"reload\"}");
  }
  if (applied.empty()) reply.error = "The Windows countdown companion did not acknowledge this revision.";
  else reply.json = applied;
  return reply;
}
