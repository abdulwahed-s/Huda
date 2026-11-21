#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <string.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "gallery_image_saver.h"
#include "prayer_tray_bridge.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  PrayerTrayBridge* tray_bridge;
  FlMethodChannel* gallery_channel;
  gboolean settings_pending;
  // The payload of a clicked companion notification, until a window exists.
  char* tap_pending;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* existing = gtk_application_get_active_window(GTK_APPLICATION(application));
  if (existing) {
    gtk_window_present(existing);
    if (self->settings_pending) prayer_tray_bridge_request_settings(self->tray_bridge);
    self->settings_pending = FALSE;
    prayer_tray_bridge_notification_tap(self->tray_bridge, self->tap_pending);
    g_clear_pointer(&self->tap_pending, g_free);
    return;
  }
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "huda");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "huda");
  }

  gtk_window_set_default_size(window, 1280, 720);

  // Window icon: installed next to the binary by CMake (assets/linux), so
  // resolve it from the executable, not the working directory (the snap and
  // desktop launchers start elsewhere). `flutter run` falls back to the repo.
  g_autofree gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
  g_autofree gchar* exe_dir = exe != nullptr ? g_path_get_dirname(exe) : nullptr;
  g_autofree gchar* icon = exe_dir != nullptr
      ? g_build_filename(exe_dir, "data", "flutter_assets", "assets", "linux",
                         "huda_icon.png", nullptr)
      : nullptr;
  if (icon != nullptr && g_file_test(icon, G_FILE_TEST_EXISTS)) {
    gtk_window_set_icon_from_file(window, icon, nullptr);
  } else {
    gtk_window_set_icon_from_file(window, "assets/linux/huda_icon.png", nullptr);
  }

  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  prayer_tray_bridge_free(self->tray_bridge);
  self->tray_bridge = prayer_tray_bridge_new(view, application);
  g_clear_object(&self->gallery_channel);
  self->gallery_channel = gallery_image_saver_new(view);
  if (self->settings_pending) prayer_tray_bridge_request_settings(self->tray_bridge);
  self->settings_pending = FALSE;
  prayer_tray_bridge_notification_tap(self->tray_bridge, self->tap_pending);
  g_clear_pointer(&self->tap_pending, g_free);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static int my_application_command_line(GApplication* application, GApplicationCommandLine* command) {
  MyApplication* self = MY_APPLICATION(application);
  int count = 0;
  g_auto(GStrv) arguments = g_application_command_line_get_arguments(command, &count);
  for (int index = 1; index < count; index++) {
    if (g_str_equal(arguments[index], "--quit-huda")) {
      g_debug("Huda received Quit Huda");
      GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
      while (windows) {
        gtk_widget_destroy(GTK_WIDGET(windows->data));
        windows = gtk_application_get_windows(GTK_APPLICATION(application));
      }
      g_application_quit(application);
      return 0;
    }
    if (g_str_equal(arguments[index], "--prayer-settings")) {
      g_debug("Huda received Prayer Settings");
      self->settings_pending = TRUE;
    }
    if (g_str_has_prefix(arguments[index], "--notification-payload=")) {
      g_free(self->tap_pending);
      self->tap_pending = g_strdup(arguments[index] + strlen("--notification-payload="));
    }
  }
  if (!self->dart_entrypoint_arguments) self->dart_entrypoint_arguments = g_strdupv(arguments + 1);
  g_application_activate(application);
  return 0;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_pointer(&self->tap_pending, g_free);
  prayer_tray_bridge_free(self->tray_bridge);
  self->tray_bridge = nullptr;
  g_clear_object(&self->gallery_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->command_line = my_application_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static int my_application_command_line_signal(GApplication* application,
    GApplicationCommandLine* command, gpointer) {
  return my_application_command_line(application, command);
}

static void my_application_init(MyApplication* self) {
  // gtk.dart registers a generic command-line signal handler during plugin setup.
  // GApplication uses the first handler's result, so install our route first.
  // The class virtual alone is preempted after the first Flutter window is created.
  g_signal_connect(self, "command-line", G_CALLBACK(my_application_command_line_signal), nullptr);
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_HANDLES_COMMAND_LINE,
                                     nullptr));
}
