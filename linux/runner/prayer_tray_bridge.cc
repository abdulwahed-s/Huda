#include "prayer_tray_bridge.h"

#include <errno.h>
#include <glib/gstdio.h>
#include <unistd.h>
#include <limits.h>
#include <string>
#include <vector>
#include <chrono>
#include <condition_variable>
#include <map>
#include <mutex>
#include <signal.h>

struct PrayerTrayBridge {
  FlMethodChannel* channel;
  GDBusConnection* bus = nullptr;
  guint control_object = 0;
  bool ready = false;
  bool settings_pending = false;
  std::string tap_pending;
};

namespace {
constexpr const char* kBus = "com.aw.huda.PrayerTray";
constexpr const char* kPath = "/com/aw/huda/PrayerTray";
constexpr const char* kInterface = "com.aw.huda.PrayerTray1";
constexpr const char* kExperiencePath = "/com/aw/huda/PrayerExperience";
constexpr const char* kExperienceInterface = "com.aw.huda.PrayerExperience1";
constexpr const char* kUnit = "huda-prayer-tray.service";
constexpr const char* kControlPath = "/com/aw/huda/PrayerTrayControl";
struct ControlAck {
  bool received = false, startup = false;
  std::string owner, error;
  bool apply = false, enabled = false, requested_startup = false, update = false, delivered = false;
  bool migration = false;
};
std::mutex control_mutex;
std::condition_variable control_ready;
std::map<guint64, ControlAck> control_requests;
GDBusMethodInvocation* control_waiter = nullptr;
GDBusMethodInvocation* migration_waiter = nullptr;
guint control_wait_timeout = 0;
guint migration_wait_timeout = 0;
gint64 control_seen = 0;  // When the extension last long-polled (monotonic µs).

void finish_wait(guint64 token, bool apply = false, bool enabled = false,
                 bool startup = false, bool update = false) {
  // Called with control_mutex held. Returning a D-Bus invocation is thread safe.
  if (!control_waiter) return;
  g_dbus_method_invocation_return_value(control_waiter,
      g_variant_new("(tbbbb)", token, apply, enabled, startup, update));
  g_clear_object(&control_waiter);
  if (control_wait_timeout) g_source_remove(control_wait_timeout);
  control_wait_timeout = 0;
}

void deliver_control_request() {
  for (auto& [token, request] : control_requests) {
    auto* waiter = request.migration ? migration_waiter : control_waiter;
    if (!waiter) continue;
    const gchar* sender = g_dbus_method_invocation_get_sender(waiter);
    if (!request.delivered && request.owner == sender) {
      request.delivered = true;
      if (request.migration) {
        g_dbus_method_invocation_return_value(migration_waiter, g_variant_new("(t)", token));
        g_clear_object(&migration_waiter);
        if (migration_wait_timeout) g_source_remove(migration_wait_timeout);
        migration_wait_timeout = 0;
      } else finish_wait(token, request.apply, request.enabled, request.requested_startup, request.update);
      return;
    }
  }
}

void control_method(GDBusConnection* bus, const gchar* sender, const gchar*, const gchar*,
                    const gchar* member, GVariant* parameters, GDBusMethodInvocation* invocation, gpointer) {
  if (g_str_equal(member, "WaitForControlRequest") || g_str_equal(member, "WaitForMigrationRequest")) {
    g_autoptr(GVariant) owner = g_dbus_connection_call_sync(bus, "org.freedesktop.DBus",
        "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner",
        g_variant_new("(s)", "org.gnome.Shell"), G_VARIANT_TYPE("(s)"),
        G_DBUS_CALL_FLAGS_NO_AUTO_START, 1000, nullptr, nullptr);
    const gchar* name = nullptr;
    if (owner) g_variant_get(owner, "(&s)", &name);
    if (!name || !g_str_equal(sender, name)) {
      g_dbus_method_invocation_return_dbus_error(invocation, "org.freedesktop.DBus.Error.AccessDenied",
          "Only the current GNOME Shell can receive prayer display requests.");
      return;
    }
    std::lock_guard<std::mutex> guard(control_mutex);
    if (g_str_equal(member, "WaitForMigrationRequest")) {
      if (migration_waiter) {
        g_dbus_method_invocation_return_value(migration_waiter, g_variant_new("(t)", guint64(0)));
        g_clear_object(&migration_waiter);
      }
      if (migration_wait_timeout) g_source_remove(migration_wait_timeout);
      migration_waiter = G_DBUS_METHOD_INVOCATION(g_object_ref(invocation));
      migration_wait_timeout = g_timeout_add_seconds(20, [](gpointer) -> gboolean {
        std::lock_guard<std::mutex> lock(control_mutex);
        migration_wait_timeout = 0;
        if (migration_waiter) {
          g_dbus_method_invocation_return_value(migration_waiter, g_variant_new("(t)", guint64(0)));
          g_clear_object(&migration_waiter);
        }
        return G_SOURCE_REMOVE;
      }, nullptr);
      deliver_control_request();
      return;
    }
    finish_wait(0); // A re-enabled extension replaces its cancelled long poll.
    control_seen = g_get_monotonic_time();
    control_waiter = G_DBUS_METHOD_INVOCATION(g_object_ref(invocation));
    control_wait_timeout = g_timeout_add_seconds(20, [](gpointer) -> gboolean {
      std::lock_guard<std::mutex> lock(control_mutex);
      control_wait_timeout = 0;
      finish_wait(0);
      return G_SOURCE_REMOVE;
    }, nullptr);
    deliver_control_request();
    return;
  }
  guint64 token; gboolean startup; const gchar* error;
  g_variant_get(parameters, "(tb&s)", &token, &startup, &error);
  {
    std::lock_guard<std::mutex> guard(control_mutex);
    auto found = control_requests.find(token);
    if (found != control_requests.end() && found->second.owner == sender) {
      found->second.received = true; found->second.startup = startup;
      found->second.error = error; control_ready.notify_all();
    }
  }
  g_dbus_method_invocation_return_value(invocation, nullptr);
}

// The enabled extension long-polls Huda while it runs; its last poll shows it is there.
bool extension_connected() {
  std::lock_guard<std::mutex> guard(control_mutex);
  return control_waiter || (control_seen && g_get_monotonic_time() - control_seen < 30 * G_USEC_PER_SEC);
}

std::string data_directory() {
  const char* snap_common = g_getenv("SNAP_USER_COMMON");
  return std::string(snap_common ? snap_common : g_get_user_data_dir()) +
      (snap_common ? "/prayer-tray" : "/huda/prayer-tray");
}

std::string bundle_directory() {
  char path[PATH_MAX];
  const ssize_t size = readlink("/proc/self/exe", path, sizeof(path) - 1);
  if (size < 0) return "";
  path[size] = 0;
  g_autofree char* directory = g_path_get_dirname(path);
  return directory;
}

// The Snap's "Start at login": snapd runs huda.prayer-tray-login at login while
// this file is in the Snap's own ~/.config/autostart (snapcraft.yaml, autostart).
std::string snap_autostart() {
  const char* data = g_getenv("SNAP_USER_DATA");
  return std::string(data ? data : g_get_home_dir()) + "/.config/autostart/huda-prayer-tray.desktop";
}

bool snap_startup() { return g_file_test(snap_autostart().c_str(), G_FILE_TEST_EXISTS); }

void set_snap_startup(bool startup, std::string* error) {
  const std::string path = snap_autostart();
  if (!startup) {
    if (g_unlink(path.c_str()) != 0 && errno != ENOENT) *error = "Start at login could not be turned off";
    return;
  }
  g_autofree char* directory = g_path_get_dirname(path.c_str());
  g_mkdir_with_parents(directory, 0700);
  g_autoptr(GError) failure = nullptr;
  if (!g_file_set_contents(path.c_str(), "[Desktop Entry]\nType=Application\nName=Huda prayer service\n"
      "Exec=huda.prayer-tray-login\nNoDisplay=true\nX-GNOME-Autostart-enabled=true\n", -1, &failure))
    *error = failure ? failure->message : "Start at login could not be turned on";
}

// A call to the companion's name makes the session bus start the Snap's
// service (snapcraft.yaml, activates-on); a Snap can't start a daemon itself.
void activate_service(GDBusConnection* bus, std::string* error) {
  // A just-started companion owns its name a moment before its objects exist.
  for (int attempt = 0; bus && attempt < 30; attempt++) {
    g_autoptr(GError) failure = nullptr;
    g_autoptr(GVariant) reply = g_dbus_connection_call_sync(bus, kBus, kPath, kInterface,
        "GetSnapshot", nullptr, G_VARIANT_TYPE("(s)"), G_DBUS_CALL_FLAGS_NONE, 25000, nullptr, &failure);
    if (reply) return;
    if (!g_error_matches(failure, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_METHOD) &&
        !g_error_matches(failure, G_DBUS_ERROR, G_DBUS_ERROR_UNKNOWN_OBJECT)) {
      *error = failure ? failure->message : "Prayer companion unavailable";
      return;
    }
    g_usleep(100000);
  }
  *error = "Prayer companion unavailable";
}

bool run(const std::vector<std::string>& args, std::string* error = nullptr,
         std::string* output = nullptr) {
  std::vector<const gchar*> argv;
  for (const auto& arg : args) argv.push_back(arg.c_str());
  argv.push_back(nullptr);
  g_autoptr(GError) failure = nullptr;
  g_autoptr(GSubprocess) child = g_subprocess_newv(argv.data(),
      static_cast<GSubprocessFlags>((output ? G_SUBPROCESS_FLAGS_STDOUT_PIPE : G_SUBPROCESS_FLAGS_STDOUT_SILENCE) |
                                   G_SUBPROCESS_FLAGS_STDERR_PIPE), &failure);
  g_autofree char* stderr_text = nullptr;
  g_autofree char* stdout_text = nullptr;
  bool ok = child && g_subprocess_communicate_utf8(child, nullptr, nullptr,
      output ? &stdout_text : nullptr, &stderr_text, &failure) && g_subprocess_get_successful(child);
  if (output) *output = stdout_text ? stdout_text : "";
  if (!ok && error) *error = failure ? failure->message : stderr_text ? stderr_text : "Service command failed";
  return ok;
}

void set_string(FlValue* result, const char* key, const std::string& value) {
  fl_value_set_string_take(result, key, fl_value_new_string(value.c_str()));
}

void set_bool(FlValue* result, const char* key, bool value) {
  fl_value_set_string_take(result, key, fl_value_new_bool(value));
}

gboolean boolean(FlValue* args, const char* key) {
  FlValue* value = args ? fl_value_lookup_string(args, key) : nullptr;
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL && fl_value_get_bool(value);
}

std::string read_configuration(const char* suffix = "") {
  g_autofree char* contents = nullptr;
  g_file_get_contents((data_directory() + "/configuration.json" + suffix).c_str(), &contents, nullptr, nullptr);
  return contents ? contents : "";
}

std::string experience_call(GDBusConnection* bus, const char* member, const char* json,
                            std::string* error) {
  g_autoptr(GError) failure = nullptr;
  g_autoptr(GVariant) reply = bus ? g_dbus_connection_call_sync(bus, kBus, kExperiencePath,
      kExperienceInterface, member, json ? g_variant_new("(s)", json) : nullptr,
      G_VARIANT_TYPE("(s)"), G_DBUS_CALL_FLAGS_NO_AUTO_START, 10000, nullptr, &failure) : nullptr;
  if (!reply) { *error = failure ? failure->message : "Prayer companion unavailable"; return ""; }
  const gchar* result; g_variant_get(reply, "(&s)", &result);
  return result;
}

bool stop_legacy() {
  // The Snap can't stop its own daemon. The companion takes over under the
  // helper's dispatch lock instead, and the helper then exits by itself.
  if (g_getenv("SNAP")) return true;
  // The fixed service and fixed autostart entry only. Native activation verifies
  // helper.lock independently, so a failed stop cannot activate dual delivery.
  run({"systemctl", "--user", "disable", "--now", "huda-prayer-notifications.service"});
  g_unlink((std::string(g_get_user_config_dir()) + "/autostart/huda-prayers.desktop").c_str());
  const std::string helper = std::string(g_get_user_data_dir()) + "/huda/prayer-notifications/notify-prayers.sh";
  g_autoptr(GDir) processes = g_dir_open("/proc", 0, nullptr);
  if (processes) while (const char* entry = g_dir_read_name(processes)) {
    char* tail; const long pid = strtol(entry, &tail, 10);
    if (*tail || pid <= 1 || pid == getpid()) continue;
    const std::string path = std::string("/proc/") + entry;
    GStatBuf info;
    if (g_stat(path.c_str(), &info) != 0 || info.st_uid != getuid()) continue;
    g_autofree gchar* cmd = nullptr; gsize size = 0;
    if (!g_file_get_contents((path + "/cmdline").c_str(), &cmd, &size, nullptr)) continue;
    for (gsize offset = 0; offset < size; offset += strlen(cmd + offset) + 1) {
      if (helper == cmd + offset) { kill(static_cast<pid_t>(pid), SIGTERM); break; }
    }
  }
  return true;
}

void initialize_files() {
  const std::string bundle = bundle_directory();
  const std::string helper = bundle + "/prayer-tray/huda-prayer-tray";
  if (!g_getenv("SNAP") && g_file_test(helper.c_str(), G_FILE_TEST_IS_EXECUTABLE)) {
    const std::string units = std::string(g_get_user_config_dir()) + "/systemd/user";
    g_mkdir_with_parents(units.c_str(), 0700);
    // Quote systemd's executable syntax, including percent specifiers in arbitrary bundle paths.
    auto quote = [](const std::string& value) {
      std::string result = "\"";
      for (char ch : value) {
        if (ch == '\\' || ch == '"') result += '\\';
        if (ch == '%') result += '%';
        result += ch;
      }
      return result + '"';
    };
    const std::string unit = "[Unit]\nDescription=Huda prayer display\nAfter=graphical-session.target\n"
        "PartOf=graphical-session.target\n[Service]\nType=simple\nExecStart=" + quote(helper) +
        // Stop only the companion: a Huda window it opened from a notification keeps running.
        "\nKillMode=process" +
        "\nEnvironment=" + quote(std::string("XDG_DATA_HOME=") + g_get_user_data_dir()) +
        "\nRestart=on-failure\nRestartSec=2\n[Install]\nWantedBy=graphical-session.target\n";
    g_file_set_contents((units + "/" + kUnit).c_str(), unit.c_str(), -1, nullptr);
    run({"systemctl", "--user", "daemon-reload"});
    // Fixed development desktop entry also lets Shell recover when the service is unavailable.
    const std::string desktop_dir = std::string(g_get_user_data_dir()) + "/applications";
    g_mkdir_with_parents(desktop_dir.c_str(), 0700);
    const std::string desktop = "[Desktop Entry]\nType=Application\nName=Huda\nExec=" +
        quote(bundle + "/huda") + "\nIcon=" + bundle + "/data/flutter_assets/assets/images/huda.png\n"
        "Categories=Utility;\nStartupWMClass=com.aw.huda\nActions=prayer-settings;\n"
        "[Desktop Action prayer-settings]\nName=Prayer Settings\nExec=" + quote(bundle + "/huda") + " --prayer-settings\n";
    g_file_set_contents((desktop_dir + "/com.aw.huda.desktop").c_str(), desktop.c_str(), -1, nullptr);
  }
}

void service_preferences(GDBusConnection* bus, bool enabled, bool startup,
                         bool update_startup, std::string* error) {
  const std::string marker = std::string(g_get_user_runtime_dir()) + "/huda-prayer-tray-session-stopped";
  if (enabled) g_unlink(marker.c_str());
  if (!update_startup && bus) {
    g_autoptr(GVariant) running = g_dbus_connection_call_sync(bus, kBus, kPath,
        kInterface, "GetSnapshot", nullptr, G_VARIANT_TYPE("(s)"),
        G_DBUS_CALL_FLAGS_NO_AUTO_START, 1000, nullptr, nullptr);
    if (running) return;
  }
  if (g_getenv("SNAP")) {
    if (update_startup) set_snap_startup(startup, error);
    if (error->empty()) activate_service(bus, error);
  } else {
    if (update_startup) run({"systemctl", "--user", startup ? "enable" : "disable", kUnit}, error);
    // Keep the disabled snapshot available; visibility and login registration
    // are preferences, while an explicit session Quit stops the companion.
    run({"systemctl", "--user", "start", kUnit}, error);
  }
}

FlValue* status(GDBusConnection* bus) {
  FlValue* result = fl_value_new_map();
  g_autoptr(GVariant) snapshot = bus ? g_dbus_connection_call_sync(bus, kBus, kPath,
      kInterface, "GetSnapshot", nullptr, G_VARIANT_TYPE("(s)"),
      G_DBUS_CALL_FLAGS_NO_AUTO_START, 3000, nullptr, nullptr) : nullptr;
  set_bool(result, "serviceAvailable", snapshot != nullptr);
  set_string(result, "state", snapshot ? "ready" : "unavailable");
  if (snapshot) {
    const gchar* json;
    g_variant_get(snapshot, "(&s)", &json);
    // The Dart bridge decodes the coherent service readback instead of re-parsing JSON natively.
    set_string(result, "snapshot", json);
  }
  set_string(result, "extensionState", "missing");
  g_autoptr(GVariant) info = bus && !g_getenv("SNAP") ? g_dbus_connection_call_sync(bus, "org.gnome.Shell",
      "/org/gnome/Shell", "org.gnome.Shell.Extensions", "GetExtensionInfo",
      g_variant_new("(s)", "prayer-tray@huda"), G_VARIANT_TYPE("(a{sv})"),
      G_DBUS_CALL_FLAGS_NO_AUTO_START, 3000, nullptr, nullptr) : nullptr;
  if (info) {
    g_autoptr(GVariant) dictionary = g_variant_get_child_value(info, 0);
    double state = 0, version = 0;
    g_variant_lookup(dictionary, "state", "d", &state);
    g_variant_lookup(dictionary, "version", "d", &version);
    if (g_variant_n_children(dictionary) > 0)
      // extensions.gnome.org numbers each upload, so any version from 1 on is compatible.
      set_string(result, "extensionState", version < 1 || state == 3 || state == 4 ?
          "incompatible" : state == 1 ? "enabled" : "disabled");
  }
  bool startup, startup_known = true;
  if (g_getenv("SNAP")) {
    startup = snap_startup();
    if (extension_connected()) set_string(result, "extensionState", "enabled");
    else if (!info) set_string(result, "extensionState", "unknown");
  } else startup = run({"systemctl", "--user", "is-enabled", "--quiet", kUnit});
  set_bool(result, "startupEnabled", startup);
  set_bool(result, "startupKnown", startup_known);
  return result;
}

struct Work { FlMethodCall* call; GDBusConnection* bus; };
void worker(GTask* task, gpointer, gpointer task_data, GCancellable*) {
  Work* work = static_cast<Work*>(task_data);
  const char* method = fl_method_call_get_name(work->call);
  FlValue* args = fl_method_call_get_args(work->call);
  if (g_str_equal(method, "getSetupInfo")) {
    FlValue* result = fl_value_new_map();
    const std::string installer = bundle_directory() + "/data/install-huda-prayer-panel.sh";
    if (g_file_test(installer.c_str(), G_FILE_TEST_IS_REGULAR)) {
      g_autofree char* quoted = g_shell_quote(installer.c_str());
      set_string(result, "installCommand", std::string("bash ") + quoted);
    }
    g_task_return_pointer(task, result, reinterpret_cast<GDestroyNotify>(fl_value_unref));
    return;
  }
  if (g_str_equal(method, "audioPaths")) {
    FlValue* result = fl_value_new_map();
    const std::string root = g_getenv("SNAP_USER_COMMON") ? g_getenv("SNAP_USER_COMMON") :
        std::string(g_get_user_data_dir()) + "/huda";
    set_string(result, "cache", root + "/prayer-audio");
    set_string(result, "bundled", bundle_directory() + "/data/prayer-audio");
    g_task_return_pointer(task, result, reinterpret_cast<GDestroyNotify>(fl_value_unref));
    return;
  }
  std::string error;
  if (g_str_equal(method, "initialize")) {
    initialize_files();
    g_unlink((std::string(g_get_user_runtime_dir()) + "/huda-prayer-tray-session-stopped").c_str());
  }
  if (g_str_equal(method, "experienceStatus") || g_str_equal(method, "experienceCommand") ||
      g_str_equal(method, "applyExperience")) {
    FlValue* result = fl_value_new_map();
    FlValue* json = args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP ? fl_value_lookup_string(args, "json") : nullptr;
    std::string receipt;
    if (g_str_equal(method, "experienceStatus")) receipt = experience_call(work->bus, "GetStatus", nullptr, &error);
    else if (!json || fl_value_get_type(json) != FL_VALUE_TYPE_STRING) error = "Missing reminder request";
    else if (g_str_equal(method, "experienceCommand"))
      receipt = experience_call(work->bus, "Command", fl_value_get_string(json), &error);
    else {
      // Starting the standby process does not apply a draft's login registration.
      service_preferences(work->bus, boolean(args, "enabled"), false, false, &error);
      if (error.empty()) {
        for (int attempt = 0; attempt < 30; attempt++) {
          receipt = experience_call(work->bus, "Prepare", fl_value_get_string(json), &error);
          if (!receipt.empty() || error.find("ServiceUnknown") == std::string::npos) break;
          error.clear(); g_usleep(100000);
        }
      }
      bool previous_startup = false;
      const bool already_native = receipt.find("\"deliveryOwner\":\"native\"") != std::string::npos;
      if (error.empty() && (already_native || stop_legacy())) {
        previous_startup = g_getenv("SNAP") ? snap_startup() :
            run({"systemctl", "--user", "is-enabled", "--quiet", kUnit});
        service_preferences(work->bus, boolean(args, "enabled"), boolean(args, "startAtLogin"),
            boolean(args, "updateStartup"), &error);
        // A stopped shell may take a moment to release its lifetime flock.
        for (int attempt = 0; error.empty() && attempt < 20; attempt++) {
          receipt = experience_call(work->bus, "Activate", fl_value_get_string(json), &error);
          if (error.find("Legacy prayer dispatch is still running") == std::string::npos) break;
          error.clear(); g_usleep(100000);
        }
        if (!error.empty()) {
          std::string rollback_error;
          service_preferences(work->bus, boolean(args, "enabled"), previous_startup, true, &rollback_error);
        }
      }
    }
    if (g_str_equal(method, "applyExperience")) {
      fl_value_unref(result);
      result = status(work->bus);
    }
    if (!receipt.empty()) set_string(result, "experienceStatus", receipt);
    if (!error.empty()) set_string(result, "error", error);
    g_task_return_pointer(task, result, reinterpret_cast<GDestroyNotify>(fl_value_unref));
    return;
  }
  if (g_str_equal(method, "ensureService")) service_preferences(work->bus, true, false, false, &error);
  if (g_str_equal(method, "publishConfiguration")) {
    FlValue* json = fl_value_lookup_string(args, "json");
    if (!json || fl_value_get_type(json) != FL_VALUE_TYPE_STRING) error = "Missing configuration";
    else {
      const std::string directory = data_directory();
      g_mkdir_with_parents(directory.c_str(), 0700);
      const std::string temporary = directory + "/configuration.json.tmp";
      g_autoptr(GError) failure = nullptr;
      if (!g_file_set_contents(temporary.c_str(), fl_value_get_string(json), -1, &failure) ||
          g_rename(temporary.c_str(), (directory + "/configuration.json").c_str()) != 0)
        error = failure ? failure->message : "Atomic configuration publication failed";
      if (error.empty()) service_preferences(work->bus, boolean(args, "enabled"), boolean(args, "startAtLogin"),
          boolean(args, "updateStartup"), &error);
    }
  }
  FlValue* result = status(work->bus);
  if (g_str_equal(method, "publishConfiguration") && boolean(args, "enabled") && error.empty()) {
    for (int attempt = 0; !fl_value_lookup_string(result, "snapshot") && attempt < 25; attempt++) {
      fl_value_unref(result);
      g_usleep(100000);
      result = status(work->bus);
    }
  }
  if (g_str_equal(method, "initialize")) {
    set_string(result, "configuration", read_configuration());
    set_string(result, "configurationBackup", read_configuration(".accepted"));
  }
  if (!error.empty()) set_string(result, "error", error);
  g_task_return_pointer(task, result, reinterpret_cast<GDestroyNotify>(fl_value_unref));
}

// The page of a clicked notification goes to Flutter once it is ready.
void send_tap(PrayerTrayBridge* bridge) {
  if (bridge->tap_pending.empty()) return;
  g_autoptr(FlValue) payload = fl_value_new_string(bridge->tap_pending.c_str());
  bridge->tap_pending.clear();
  fl_method_channel_invoke_method(bridge->channel, "notificationTapped", payload, nullptr, nullptr, nullptr);
}

void completed(GObject*, GAsyncResult* result, gpointer) {
  GTask* task = G_TASK(result);
  Work* work = static_cast<Work*>(g_task_get_task_data(task));
  g_autoptr(FlValue) value = static_cast<FlValue*>(g_task_propagate_pointer(task, nullptr));
  fl_method_call_respond_success(work->call, value, nullptr);
}

void method_call(FlMethodChannel*, FlMethodCall* call, gpointer user_data) {
  PrayerTrayBridge* bridge = static_cast<PrayerTrayBridge*>(user_data);
  const char* name = fl_method_call_get_name(call);
  if (g_str_equal(name, "ready")) {
    g_debug("Huda prayer display: Flutter ready");
    bridge->ready = true;
    if (bridge->settings_pending) prayer_tray_bridge_request_settings(bridge);
    send_tap(bridge);
    fl_method_call_respond_success(call, nullptr, nullptr);
    return;
  }
  if (!g_str_equal(name, "initialize") && !g_str_equal(name, "getStatus") &&
      !g_str_equal(name, "publishConfiguration") && !g_str_equal(name, "getSetupInfo") &&
      !g_str_equal(name, "ensureService")) {
    if (!g_str_equal(name, "audioPaths") && !g_str_equal(name, "experienceStatus") &&
        !g_str_equal(name, "experienceCommand") && !g_str_equal(name, "applyExperience")) {
    fl_method_call_respond_not_implemented(call, nullptr); return;
    }
  }
  g_autoptr(GTask) task = g_task_new(nullptr, nullptr, completed, nullptr);
  auto* work = new Work{FL_METHOD_CALL(g_object_ref(call)),
      bridge->bus ? G_DBUS_CONNECTION(g_object_ref(bridge->bus)) : nullptr};
  g_task_set_task_data(task, work, [](gpointer ptr) {
    Work* value = static_cast<Work*>(ptr);
    g_object_unref(value->call); g_clear_object(&value->bus); delete value;
  });
  g_task_run_in_thread(task, worker);
}
}  // namespace

PrayerTrayBridge* prayer_tray_bridge_new(FlView* view, GApplication* application) {
  auto* bridge = new PrayerTrayBridge;
  // GApplication owns its identity on its own connection. A separately cached
  // connection can emit from another unique name and fail the Shell's sender filter.
  GDBusConnection* app_bus = g_application_get_dbus_connection(application);
  bridge->bus = app_bus ? G_DBUS_CONNECTION(g_object_ref(app_bus)) : nullptr;
  if (bridge->bus) {
    g_autoptr(GDBusNodeInfo) schema = g_dbus_node_info_new_for_xml(
        "<node><interface name='com.aw.huda.PrayerTrayControl1'>"
        "<method name='WaitForControlRequest'><arg type='t' direction='out'/>"
        "<arg type='b' direction='out'/><arg type='b' direction='out'/>"
        "<arg type='b' direction='out'/><arg type='b' direction='out'/></method>"
        "<method name='AcknowledgeControl'><arg type='t' direction='in'/>"
        "<arg type='b' direction='in'/><arg type='s' direction='in'/></method>"
        "<method name='WaitForMigrationRequest'><arg type='t' direction='out'/></method>"
        "</interface></node>", nullptr);
    static const GDBusInterfaceVTable handler = {control_method, nullptr, nullptr, {nullptr}};
    bridge->control_object = g_dbus_connection_register_object(bridge->bus, kControlPath,
        schema->interfaces[0], &handler, nullptr, nullptr, nullptr);
  }
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  bridge->channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "com.aw.huda/linux_prayer_tray", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(bridge->channel, method_call, bridge, nullptr);
  return bridge;
}

void prayer_tray_bridge_request_settings(PrayerTrayBridge* bridge) {
  if (!bridge) return;
  g_debug("Huda prayer display: settings request (ready=%d)", bridge->ready);
  if (!bridge->ready) { bridge->settings_pending = true; return; }
  bridge->settings_pending = false;
  fl_method_channel_invoke_method(bridge->channel, "openPrayerSettings", nullptr, nullptr, nullptr, nullptr);
}

void prayer_tray_bridge_notification_tap(PrayerTrayBridge* bridge, const char* payload) {
  if (!bridge || !payload || !*payload) return;
  g_debug("Huda prayer display: notification tap (ready=%d)", bridge->ready);
  bridge->tap_pending = payload;
  if (bridge->ready) send_tap(bridge);
}

void prayer_tray_bridge_free(PrayerTrayBridge* bridge) {
  if (!bridge) return;
  {
    std::lock_guard<std::mutex> guard(control_mutex);
    finish_wait(0);
    if (migration_waiter) {
      g_dbus_method_invocation_return_value(migration_waiter, g_variant_new("(t)", guint64(0)));
      g_clear_object(&migration_waiter);
    }
    if (migration_wait_timeout) g_source_remove(migration_wait_timeout);
    migration_wait_timeout = 0;
  }
  if (bridge->control_object) g_dbus_connection_unregister_object(bridge->bus, bridge->control_object);
  g_clear_object(&bridge->bus);
  fl_method_channel_set_method_call_handler(bridge->channel, nullptr, nullptr, nullptr);
  g_object_unref(bridge->channel);
  delete bridge;
}
