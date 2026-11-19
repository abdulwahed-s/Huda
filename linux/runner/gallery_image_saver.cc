#include "gallery_image_saver.h"

#include <errno.h>
#include <fcntl.h>
#include <glib/gstdio.h>
#include <string.h>
#include <unistd.h>

namespace {

// Downloads, else ~/Downloads (created) when XDG has no such folder.
gchar* downloads_folder() {
  const char* xdg = g_get_user_special_dir(G_USER_DIRECTORY_DOWNLOAD);
  gchar* folder = xdg ? g_strdup(xdg) : g_build_filename(g_get_home_dir(), "Downloads", nullptr);
  g_mkdir_with_parents(folder, 0755);
  return folder;
}

// Path separators and control characters become underscores.
gchar* sanitize(const char* name) {
  gchar* clean = g_strndup(name, 120);
  for (char* c = clean; *c; c++) {
    if (*c == '/' || static_cast<unsigned char>(*c) < 32) *c = '_';
  }
  g_strstrip(clean);
  return clean;
}

// Writes [bytes] to a new file: O_EXCL never replaces one, so a taken name
// moves on to the next "(n)". Returns an error message, or nullptr.
gchar* save(const uint8_t* bytes, size_t length, const char* name) {
  g_autofree gchar* folder = downloads_folder();
  for (int index = 1; index < 1000; index++) {
    g_autofree gchar* file_name = index == 1 ? g_strdup_printf("%s.png", name)
                                             : g_strdup_printf("%s (%d).png", name, index);
    g_autofree gchar* path = g_build_filename(folder, file_name, nullptr);
    const int fd = g_open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644);
    if (fd < 0) {
      if (errno == EEXIST) continue;
      return g_strdup_printf("Could not create %s: %s", path, g_strerror(errno));
    }
    size_t written = 0;
    while (written < length) {
      const ssize_t count = write(fd, bytes + written, length - written);
      if (count < 0 && errno == EINTR) continue;
      if (count <= 0) break;
      written += static_cast<size_t>(count);
    }
    const bool closed = close(fd) == 0;
    if (written != length || !closed) {
      g_unlink(path);
      return g_strdup_printf("Could not write %s", path);
    }
    return nullptr;
  }
  return g_strdup("Too many files with this name in Downloads.");
}

void method_call(FlMethodChannel*, FlMethodCall* call, gpointer) {
  if (!g_str_equal(fl_method_call_get_name(call), "saveImage")) {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  FlValue* args = fl_method_call_get_args(call);
  FlValue* bytes = args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP
                       ? fl_value_lookup_string(args, "bytes") : nullptr;
  FlValue* name = args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP
                      ? fl_value_lookup_string(args, "name") : nullptr;
  if (!bytes || fl_value_get_type(bytes) != FL_VALUE_TYPE_UINT8_LIST ||
      fl_value_get_length(bytes) == 0 || !name || fl_value_get_type(name) != FL_VALUE_TYPE_STRING) {
    fl_method_call_respond_error(call, "invalid_arguments", "saveImage needs bytes and a name.",
                                 nullptr, nullptr);
    return;
  }
  g_autofree gchar* file_name = sanitize(fl_value_get_string(name));
  if (!*file_name) {
    fl_method_call_respond_error(call, "invalid_arguments", "saveImage needs a name.", nullptr,
                                 nullptr);
    return;
  }
  g_autofree gchar* error =
      save(fl_value_get_uint8_list(bytes), fl_value_get_length(bytes), file_name);
  if (error) {
    fl_method_call_respond_error(call, "save_failed", error, nullptr, nullptr);
    return;
  }
  g_autoptr(FlValue) saved = fl_value_new_bool(TRUE);
  fl_method_call_respond_success(call, saved, nullptr);
}

}  // namespace

FlMethodChannel* gallery_image_saver_new(FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), "com.aw.huda/gallery",
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call, nullptr, nullptr);
  return channel;
}
