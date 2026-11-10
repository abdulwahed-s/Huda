import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

// Huda's prayer service starts by itself (D-Bus activation, and snapd's login
// autostart for "Start at login"), so the panel never manages services. While
// Huda runs, the panel holds one long-poll call on Huda's control object: that
// is how Huda sees that the panel is installed and enabled.
const APP = 'com.aw.huda';
const PATH = '/com/aw/huda/PrayerTrayControl';
const IFACE = 'com.aw.huda.PrayerTrayControl1';

function call(destination, member, parameters, replyType, timeout, cancellable) {
    return new Promise((resolve, reject) => {
        Gio.DBus.session.call(destination, PATH, IFACE, member, parameters,
            new GLib.VariantType(replyType), Gio.DBusCallFlags.NO_AUTO_START,
            timeout, cancellable, (bus, result) => {
                try { resolve(bus.call_finish(result).deep_unpack()); }
                catch (error) { reject(error); }
            });
    });
}

export class ServiceControl {
    constructor() {
        this._alive = true;
        this._owner = null;
        this._delays = new Map();
        this._watch = Gio.bus_watch_name(Gio.BusType.SESSION, APP, Gio.BusNameWatcherFlags.NONE,
            (_bus, _name, owner) => {
                this._cancel?.cancel();
                this._owner = owner;
                this._cancel = new Gio.Cancellable();
                this._listen(owner, this._cancel).catch(console.error);
            }, () => {
                this._owner = null;
                this._cancel?.cancel();
            });
    }
    _delay(milliseconds) {
        return new Promise(resolve => {
            const source = GLib.timeout_add(GLib.PRIORITY_DEFAULT, milliseconds, () => {
                this._delays.delete(source);
                resolve();
                return GLib.SOURCE_REMOVE;
            });
            this._delays.set(source, resolve);
        });
    }
    async _listen(owner, cancellable) {
        // A strict Snap's dbus slot allows host clients to call it and receive
        // replies, but not unsolicited sends to Shell, so the call is held open.
        let startupRetries = 0;
        while (this._alive && this._owner === owner && !cancellable.is_cancelled()) {
            try {
                const [token] = await call(owner, 'WaitForControlRequest', null, '(tbbbb)', 25000, cancellable);
                // Development builds from before 2026-10-17 asked the panel to manage
                // the service; this panel version declines.
                if (token !== 0) {
                    await call(owner, 'AcknowledgeControl',
                        new GLib.Variant('(tbs)', [token, false, 'The prayer panel no longer manages services.']),
                        '()', 10000, cancellable);
                }
            } catch (error) {
                if (cancellable.is_cancelled() || !this._alive || this._owner !== owner) return;
                const remote = Gio.DBusError.get_remote_error(error);
                if (['org.freedesktop.DBus.Error.UnknownMethod', 'org.freedesktop.DBus.Error.UnknownObject'].includes(remote)
                    && startupRetries++ < 120) {
                    // GApplication acquires its name before GTK/Flutter exports
                    // the bridge. Wait for that object during cold startup.
                    await this._delay(500);
                    continue;
                }
                throw error;
            }
        }
    }
    destroy() {
        this._alive = false;
        this._cancel?.cancel();
        Gio.bus_unwatch_name(this._watch);
        for (const [source, resolve] of this._delays) {
            GLib.source_remove(source);
            resolve();
        }
        this._delays.clear();
    }
}
