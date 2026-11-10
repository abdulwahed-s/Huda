#ifndef HUDA_PRAYER_TRAY_BRIDGE_H_
#define HUDA_PRAYER_TRAY_BRIDGE_H_
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

struct PrayerTrayBridge;
PrayerTrayBridge* prayer_tray_bridge_new(FlView* view, GApplication* application);
void prayer_tray_bridge_request_settings(PrayerTrayBridge* bridge);
// Opens the page of a clicked companion notification (its payload).
void prayer_tray_bridge_notification_tap(PrayerTrayBridge* bridge, const char* payload);
void prayer_tray_bridge_free(PrayerTrayBridge* bridge);
#endif
