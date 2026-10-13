#include <windows.h>
#include <appmodel.h>
#include <shlobj.h>
#include <propkey.h>
#include <propvarutil.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.UI.Notifications.h>

#include "windows_notification_worker.h"

#include <algorithm>
#include <chrono>
#include <stdexcept>
#include <unordered_map>
#include <sddl.h>

using winrt::Windows::Data::Xml::Dom::XmlDocument;
using winrt::Windows::UI::Notifications::ScheduledToastNotification;
using winrt::Windows::UI::Notifications::ToastNotificationManager;
using winrt::Windows::UI::Notifications::ToastNotifier;

namespace {
constexpr int kPendingBudget = 4000;
constexpr int64_t kReplacementGuardSeconds = 30;

class QueueLease {
 public:
  explicit QueueLease(const std::string& app_id) {
    HANDLE token = nullptr;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) throw std::runtime_error("queue-owner-unavailable");
    DWORD length = 0;
    GetTokenInformation(token, TokenUser, nullptr, 0, &length);
    std::vector<char> bytes(length);
    const bool read = GetTokenInformation(token, TokenUser, bytes.data(), length, &length) != FALSE;
    CloseHandle(token);
    LPWSTR sid = nullptr;
    if (!read || !ConvertSidToStringSidW(reinterpret_cast<TOKEN_USER*>(bytes.data())->User.Sid, &sid))
      throw std::runtime_error("queue-owner-unavailable");
    const auto name = std::wstring(L"Local\\Huda.PrayerToastQueue.") + sid + L"." + winrt::to_hstring(app_id).c_str();
    LocalFree(sid);
    handle_ = CreateMutexW(nullptr, FALSE, name.c_str());
    if (!handle_) throw std::runtime_error("queue-lock-unavailable");
    const auto acquired = WaitForSingleObject(handle_, 25000);
    if (acquired != WAIT_OBJECT_0 && acquired != WAIT_ABANDONED) {
      CloseHandle(handle_); handle_ = nullptr;
      throw std::runtime_error("queue-lock-timeout");
    }
  }
  ~QueueLease() { if (handle_) { ReleaseMutex(handle_); CloseHandle(handle_); } }
 private:
  HANDLE handle_ = nullptr;
};

bool HasPackageIdentity() {
  UINT32 length = 0;
  return GetCurrentPackageFullName(&length, nullptr) != APPMODEL_ERROR_NO_PACKAGE;
}

struct RegistryKey {
  HKEY value = nullptr;
  ~RegistryKey() { if (value) RegCloseKey(value); }
};

void WriteRegistryString(const std::wstring& path, const wchar_t* name,
                         const std::wstring& value) {
  RegistryKey key;
  winrt::check_win32(RegCreateKeyExW(HKEY_CURRENT_USER, path.c_str(), 0,
      nullptr, 0, KEY_SET_VALUE, nullptr, &key.value, nullptr));
  winrt::check_win32(RegSetValueExW(key.value, name, 0, REG_SZ,
      reinterpret_cast<const BYTE*>(value.c_str()),
      static_cast<DWORD>((value.size() + 1) * sizeof(wchar_t))));
}

bool RegistryDwordEquals(HKEY root, const std::wstring& path,
                         const wchar_t* name, DWORD expected) {
  DWORD value = 0, size = sizeof(value);
  return RegGetValueW(root, path.c_str(), name, RRF_RT_REG_DWORD, nullptr,
      &value, &size) == ERROR_SUCCESS && value == expected;
}

int InitialNotificationSetting(const std::string& app_id) {
  using winrt::Windows::UI::Notifications::NotificationSetting;
  const std::wstring policy = L"Software\\Policies\\Microsoft\\Windows\\CurrentVersion\\PushNotifications";
  if (RegistryDwordEquals(HKEY_CURRENT_USER, policy, L"NoToastApplicationNotification", 1) ||
      RegistryDwordEquals(HKEY_LOCAL_MACHINE, policy, L"NoToastApplicationNotification", 1))
    return static_cast<int>(NotificationSetting::DisabledByGroupPolicy);
  if (RegistryDwordEquals(HKEY_CURRENT_USER,
      L"Software\\Microsoft\\Windows\\CurrentVersion\\PushNotifications", L"ToastEnabled", 0))
    return static_cast<int>(NotificationSetting::DisabledForUser);
  if (RegistryDwordEquals(HKEY_CURRENT_USER,
      L"Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings\\" +
          std::wstring(winrt::to_hstring(app_id)), L"Enabled", 0))
    return static_cast<int>(NotificationSetting::DisabledForApplication);
  return static_cast<int>(NotificationSetting::Enabled);
}

struct PropertyValue {
  PROPVARIANT value{};
  ~PropertyValue() { PropVariantClear(&value); }
};

std::wstring KnownFolder(REFKNOWNFOLDERID folder) {
  PWSTR path = nullptr;
  winrt::check_hresult(SHGetKnownFolderPath(folder, KF_FLAG_CREATE, nullptr, &path));
  std::wstring result(path);
  CoTaskMemFree(path);
  return result;
}

bool ShortcutMatches(const std::wstring& path, const std::wstring& executable,
                     const std::wstring& app_id, const GUID& activator) {
  winrt::com_ptr<IShellLinkW> link;
  winrt::check_hresult(CoCreateInstance(CLSID_ShellLink, nullptr,
      CLSCTX_INPROC_SERVER, IID_PPV_ARGS(link.put())));
  if (FAILED(link.as<IPersistFile>()->Load(path.c_str(), STGM_READ))) return false;
  wchar_t target[32768]{};
  if (FAILED(link->GetPath(target, 32768, nullptr, SLGP_RAWPATH)) ||
      _wcsicmp(target, executable.c_str()) != 0) return false;
  auto store = link.as<IPropertyStore>();
  PropertyValue id, clsid;
  if (FAILED(store->GetValue(PKEY_AppUserModel_ID, &id.value)) ||
      FAILED(store->GetValue(PKEY_AppUserModel_ToastActivatorCLSID, &clsid.value))) return false;
  return id.value.vt == VT_LPWSTR && id.value.pwszVal &&
      app_id == id.value.pwszVal && clsid.value.vt == VT_CLSID &&
      clsid.value.puuid && IsEqualGUID(*clsid.value.puuid, activator);
}

void RegisterDesktopApp(const std::string& app_id, const std::string& app_name,
                        const std::string& activator_guid) {
  // MSIX supplies the identity, shortcut and COM server through its manifest.
  if (HasPackageIdentity()) return;
  const auto id = std::wstring(winrt::to_hstring(app_id));
  if (id.empty() || id.size() > 128 ||
      id.find_first_of(L"\\/:*?\"<>| ") != std::wstring::npos || app_name.empty())
    throw std::invalid_argument("invalid Windows notification identity");
  const auto clsid = L"{" + std::wstring(winrt::to_hstring(activator_guid)) + L"}";
  GUID activator{};
  winrt::check_hresult(CLSIDFromString(clsid.c_str(), &activator));
  wchar_t filename[32768]{};
  const auto length = GetModuleFileNameW(nullptr, filename, 32768);
  if (!length || length >= 32768) throw std::runtime_error("notification executable unavailable");
  const std::wstring executable(filename, length);
  const auto directory = executable.substr(0, executable.find_last_of(L"\\/"));
  winrt::check_hresult(SetCurrentProcessExplicitAppUserModelID(id.c_str()));
  const auto app_key = L"Software\\Classes\\AppUserModelId\\" + id;
  WriteRegistryString(app_key, L"DisplayName", std::wstring(winrt::to_hstring(app_name)));
  WriteRegistryString(app_key, L"CustomActivator", clsid);
  const auto icon = directory + L"\\data\\flutter_assets\\assets\\images\\huda.png";
  if (GetFileAttributesW(icon.c_str()) != INVALID_FILE_ATTRIBUTES)
    WriteRegistryString(app_key, L"IconUri", icon);
  const auto server_key = L"Software\\Classes\\CLSID\\" + clsid + L"\\LocalServer32";
  WriteRegistryString(server_key, nullptr, L"\"" + executable + L"\" --notification-activated");
  WriteRegistryString(server_key, L"ServerExecutable", executable);

  const auto name = id == L"awr.Huda-IslamicCompanionApp" ? L"Huda.lnk" : id + L".lnk";
  const auto shortcut = KnownFolder(FOLDERID_Programs) + L"\\" + name;
  const auto common = KnownFolder(FOLDERID_CommonPrograms) + L"\\" + name;
  if (ShortcutMatches(shortcut, executable, id, activator) ||
      ShortcutMatches(common, executable, id, activator)) return;
  winrt::com_ptr<IShellLinkW> link;
  winrt::check_hresult(CoCreateInstance(CLSID_ShellLink, nullptr,
      CLSCTX_INPROC_SERVER, IID_PPV_ARGS(link.put())));
  winrt::check_hresult(link->SetPath(executable.c_str()));
  winrt::check_hresult(link->SetWorkingDirectory(directory.c_str()));
  winrt::check_hresult(link->SetDescription(winrt::to_hstring(app_name).c_str()));
  auto store = link.as<IPropertyStore>();
  PropertyValue identity, callback;
  winrt::check_hresult(InitPropVariantFromString(id.c_str(), &identity.value));
  winrt::check_hresult(InitPropVariantFromCLSID(activator, &callback.value));
  winrt::check_hresult(store->SetValue(PKEY_AppUserModel_ID, identity.value));
  winrt::check_hresult(store->SetValue(PKEY_AppUserModel_ToastActivatorCLSID, callback.value));
  winrt::check_hresult(store->Commit());
  winrt::check_hresult(link.as<IPersistFile>()->Save(shortcut.c_str(), TRUE));
  SHChangeNotify(SHCNE_CREATE, SHCNF_PATHW, shortcut.c_str(), nullptr);
}

std::string EscapeXml(const std::string& value) {
  std::string escaped;
  for (char c : value) {
    switch (c) {
      case '&': escaped += "&amp;"; break;
      case '<': escaped += "&lt;"; break;
      case '>': escaped += "&gt;"; break;
      case '"': escaped += "&quot;"; break;
      case '\'': escaped += "&apos;"; break;
      default: escaped += c;
    }
  }
  return escaped;
}

WindowsPendingToast Describe(const ScheduledToastNotification& toast) {
  const auto document = toast.Content();
  const auto texts = document.GetElementsByTagName(L"text");
  const auto audio = document.GetElementsByTagName(L"audio");
  return {winrt::to_string(toast.Tag()), winrt::to_string(toast.Group()),
          winrt::to_string(document.DocumentElement().GetAttribute(L"launch")),
          texts.Length() > 0 ? winrt::to_string(texts.Item(0).InnerText()) : "",
          texts.Length() > 1 ? winrt::to_string(texts.Item(1).InnerText()) : "",
          static_cast<int64_t>(winrt::clock::to_time_t(toast.DeliveryTime())),
          audio.Length() > 0 && audio.Item(0).as<winrt::Windows::Data::Xml::Dom::XmlElement>().GetAttribute(L"silent") == L"true"};
}

void CheckDeadline(const ScheduledToastNotification& toast, bool protect) {
  if (protect && toast.DeliveryTime() <=
                     winrt::clock::now() +
                         std::chrono::seconds(kReplacementGuardSeconds)) {
    throw std::runtime_error("prayer-deadline-near: existing toast retained");
  }
}
}  // namespace

struct WindowsNotificationWorker::State {
  struct Snapshot {
    std::unique_ptr<QueueLease> lease;
    std::string app_id;
    size_t count = 0;
    std::unordered_map<std::wstring, std::vector<ScheduledToastNotification>> by_tag;
  };
  std::unordered_map<std::string, ToastNotifier> notifiers;
  std::unordered_map<std::string, bool> registered_apps;
  // Snapshots retain handles, but capacity is shared by every gateway using
  // this queue (including reminders arriving during a prayer reconciliation).
  std::unordered_map<std::string, size_t> queue_counts;
  std::unordered_map<int64_t, Snapshot> snapshots;
  int64_t next_token = 0;

  ToastNotifier Notifier(const std::string& app_id) {
    if (HasPackageIdentity() && app_id != "awr.Huda-IslamicCompanionApp") {
      throw std::invalid_argument(
          "A private notification identity requires an unpackaged test process");
    }
    auto found = notifiers.find(app_id);
    if (found != notifiers.end()) return found->second;
    // Follow the original plugin's identity strategy. Registration and
    // activation still belong to that plugin on the root isolate.
    auto notifier = HasPackageIdentity()
                        ? ToastNotificationManager::CreateToastNotifier()
                        : ToastNotificationManager::CreateToastNotifier(
                              winrt::to_hstring(app_id));
    notifiers.emplace(app_id, notifier);
    return notifier;
  }

  Snapshot& Find(const std::string& app_id, int64_t token) {
    auto found = snapshots.find(token);
    if (found == snapshots.end() || found->second.app_id != app_id) {
      throw std::runtime_error("notification-snapshot-expired");
    }
    return found->second;
  }
};

WindowsNotificationWorker::WindowsNotificationWorker() {
  winrt::init_apartment(winrt::apartment_type::multi_threaded);
  state_ = std::make_unique<State>();
}

WindowsNotificationWorker::~WindowsNotificationWorker() {
  state_.reset();
  winrt::uninit_apartment();
}

bool WindowsNotificationWorker::Initialize(const std::string& app_id) {
  state_->Notifier(app_id);
  return HasPackageIdentity();
}

void WindowsNotificationWorker::RegisterApp(const std::string& app_id,
    const std::string& app_name, const std::string& activator_guid) {
  RegisterDesktopApp(app_id, app_name, activator_guid);
  state_->registered_apps[app_id] = true;
}

int WindowsNotificationWorker::NotificationSetting(const std::string& app_id) {
  try {
    return static_cast<int>(state_->Notifier(app_id).Setting());
  } catch (const winrt::hresult_error& error) {
    // Windows may not create its notification handler until the first toast
    // is delivered. A freshly registered desktop app must still be able to
    // schedule that first toast. Only this case uses Windows' stored settings;
    // all other failures propagate and packaged apps always use the OS API.
    if (error.code() != HRESULT_FROM_WIN32(ERROR_NOT_FOUND) ||
        HasPackageIdentity() || !state_->registered_apps.count(app_id)) throw;
    return InitialNotificationSetting(app_id);
  }
}

std::string WindowsNotificationWorker::PackageFullName() const {
  UINT32 length = 0;
  const auto status = GetCurrentPackageFullName(&length, nullptr);
  if (status == APPMODEL_ERROR_NO_PACKAGE) return {};
  if (status != ERROR_INSUFFICIENT_BUFFER) {
    throw winrt::hresult_error(HRESULT_FROM_WIN32(status));
  }
  std::wstring name(length, L'\0');
  const auto result = GetCurrentPackageFullName(&length, name.data());
  if (result != ERROR_SUCCESS) {
    throw winrt::hresult_error(HRESULT_FROM_WIN32(result));
  }
  name.resize(length - 1);
  return winrt::to_string(name);
}

WindowsToastSnapshot WindowsNotificationWorker::Pending(
    const std::string& app_id, int64_t previous_token) {
  State::Snapshot snapshot;
  snapshot.lease = std::make_unique<QueueLease>(app_id);
  snapshot.app_id = app_id;
  WindowsToastSnapshot result{++state_->next_token, {}};
  for (auto toast : state_->Notifier(app_id).GetScheduledToastNotifications()) {
    result.items.push_back(Describe(toast));
    snapshot.by_tag[std::wstring(toast.Tag())].push_back(toast);
    ++snapshot.count;
  }
  state_->queue_counts[app_id] = snapshot.count;
  Release(app_id, previous_token);
  state_->snapshots.emplace(result.token, std::move(snapshot));
  return result;
}

WindowsToastMutation WindowsNotificationWorker::Schedule(
    const std::string& app_id, int64_t token, int id, int64_t delivery_seconds,
    const std::string& title, const std::string& body, const std::string& payload,
    bool protect_near_due, bool silent_audio, bool short_duration) {
  auto& snapshot = state_->Find(app_id, token);
  auto notifier = state_->Notifier(app_id);
  const auto tag = std::to_wstring(id);
  auto& existing = snapshot.by_tag[tag];
  // Copy handles: snapshot changes only after operations are acknowledged.
  auto previous = existing;
  ScheduledToastNotification matching{nullptr};
  for (auto toast : previous) {
    if (!toast.Group().empty()) continue;
    const auto metadata = Describe(toast);
    if (!matching && metadata.payload == payload && metadata.title == title &&
        metadata.body == body && metadata.delivery_seconds == delivery_seconds && metadata.silent == silent_audio) {
      matching = toast;
    }
  }
  for (auto toast : previous) {
    if (toast.Group().empty() && toast != matching) {
      CheckDeadline(toast, protect_near_due);
    }
  }
  WindowsToastMutation result;
  if (!matching) {
    if (winrt::clock::from_time_t(static_cast<time_t>(delivery_seconds)) <=
        winrt::clock::now()) {
      throw std::runtime_error("prayer-deadline-passed: no replay scheduled");
    }
    if (state_->queue_counts.at(app_id) >= kPendingBudget) {
      throw std::runtime_error("insufficient-safe-capacity: existing toast retained");
    }
    XmlDocument document;
    // Equivalent to Huda's existing WindowsNotificationDetails: long duration
    // for prayers, Windows' default for reminders, ToastGeneric title/body,
    // launch payload, default audio and empty actions.
    document.LoadXml(winrt::to_hstring(
        std::string(short_duration ? "<toast" : "<toast duration=\"long\"") +
        " launch=\"" + EscapeXml(payload) +
        "\" useButtonStyle=\"true\"><visual><binding template=\"ToastGeneric\">"
        "<text>" + EscapeXml(title) + "</text><text>" + EscapeXml(body) +
        "</text></binding></visual>" + (silent_audio ? "<audio silent=\"true\"/>" : "") + "<actions/></toast>"));
    matching = ScheduledToastNotification(
        document, winrt::clock::from_time_t(static_cast<time_t>(delivery_seconds)));
    matching.Tag(tag);
    // Accept the replacement before removing the old event. A failed addition
    // or a full queue therefore never creates an empty replacement window.
    notifier.AddToSchedule(matching);
    existing.push_back(matching);
    ++snapshot.count;
    ++state_->queue_counts.at(app_id);
    ++result.added;
  }
  for (auto toast : previous) {
    if (toast.Group().empty() && toast != matching) {
      notifier.RemoveFromSchedule(toast);
      existing.erase(std::remove(existing.begin(), existing.end(), toast),
                     existing.end());
      --snapshot.count;
      if (state_->queue_counts.at(app_id) > 0) --state_->queue_counts.at(app_id);
      ++result.removed;
    }
  }
  return result;
}

WindowsToastMutation WindowsNotificationWorker::Cancel(
    const std::string& app_id, int64_t token, int id, bool protect_near_due) {
  auto& snapshot = state_->Find(app_id, token);
  auto notifier = state_->Notifier(app_id);
  const auto tag = std::to_wstring(id);
  const auto found = snapshot.by_tag.find(tag);
  if (found == snapshot.by_tag.end()) {
    if (HasPackageIdentity()) ToastNotificationManager::History().Remove(tag);
    return {};
  }
  const auto previous = found->second;
  for (auto toast : previous) {
    if (toast.Group().empty()) CheckDeadline(toast, protect_near_due);
  }
  if (HasPackageIdentity()) ToastNotificationManager::History().Remove(tag);
  WindowsToastMutation result;
  for (auto toast : previous) {
    if (!toast.Group().empty()) continue;
    notifier.RemoveFromSchedule(toast);
    auto& items = snapshot.by_tag[tag];
    items.erase(std::remove(items.begin(), items.end(), toast), items.end());
    --snapshot.count;
    if (state_->queue_counts.at(app_id) > 0) --state_->queue_counts.at(app_id);
    ++result.removed;
  }
  return result;
}

void WindowsNotificationWorker::Release(const std::string& app_id, int64_t token) {
  auto found = state_->snapshots.find(token);
  if (found != state_->snapshots.end() && found->second.app_id == app_id) {
    state_->snapshots.erase(found);
  }
}
