#include "my_application.h"

#include <dlfcn.h>

// An editor launched from Snap can export old GNOME schemas to host apps.
// GTK's Wayland backend then falls back to removed xsettings font keys and
// aborts. Inspect sources directly: the default source is cached, so it must
// not be initialized until after correcting the inherited override.
static void configure_gsettings_schema_directory() {
  const char* inherited_directory = g_getenv("GSETTINGS_SCHEMA_DIR");
  if (!inherited_directory || !*inherited_directory) return;

  g_autoptr(GSettingsSchemaSource) inherited_source =
      g_settings_schema_source_new_from_directory(
          inherited_directory, nullptr, FALSE, nullptr);
  if (!inherited_source) return;
  g_autoptr(GSettingsSchema) inherited_interface =
      g_settings_schema_source_lookup(
          inherited_source, "org.gnome.desktop.interface", FALSE);
  if (!inherited_interface ||
      g_settings_schema_has_key(inherited_interface, "font-antialiasing")) {
    return;
  }

  const char* system_directory = "/usr/share/glib-2.0/schemas";
  g_autoptr(GSettingsSchemaSource) system_source =
      g_settings_schema_source_new_from_directory(
          system_directory, nullptr, FALSE, nullptr);
  if (!system_source) return;
  g_autoptr(GSettingsSchema) system_interface =
      g_settings_schema_source_lookup(
          system_source, "org.gnome.desktop.interface", FALSE);
  if (!system_interface ||
      !g_settings_schema_has_key(system_interface, "font-antialiasing") ||
      !g_settings_schema_has_key(system_interface, "font-hinting") ||
      !g_settings_schema_has_key(system_interface, "font-rgba-order")) {
    return;
  }

  g_setenv("GSETTINGS_SCHEMA_DIR", system_directory, TRUE);
}

int main(int argc, char** argv) {
  configure_gsettings_schema_directory();
  dlopen("librsvg-2.so.2", RTLD_NOW | RTLD_GLOBAL);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
