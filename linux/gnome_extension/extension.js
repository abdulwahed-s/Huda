import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Pango from 'gi://Pango';
import St from 'gi://St';
import Shell from 'gi://Shell';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {LOCALES} from './locale/labels.js';
import * as Format from './format.js';
import {ServiceControl} from './service-control.js';
import {PrayerFocus} from './focus.js';

const BUS = 'com.aw.huda.PrayerTray';
const PATH = '/com/aw/huda/PrayerTray';
const IFACE = 'com.aw.huda.PrayerTray1';
const ICONS = ['weather-clear-night-symbolic', 'weather-clear-symbolic', 'weather-clear-symbolic',
    'weather-few-clouds-symbolic', 'weather-clear-night-symbolic', 'weather-clear-night-symbolic'];
// Secondary text, row icons and passed prayers use the muted color of Huda's
// palette; without a palette they are dimmed and keep the Shell's text color.
function muted(tokens) {
    return tokens ? {style: `color: ${tokens.muted};`} : {opacity: 170};
}
function verticalBox(options) {
    const box = new St.BoxLayout(options);
    box.layout_manager.orientation = Clutter.Orientation.VERTICAL;
    return box;
}

const PrayerIndicator = GObject.registerClass({GTypeName: 'HudaPrayerTrayIndicatorV1'}, class PrayerIndicator extends PanelMenu.Button {
    _init(extension) {
        super._init(0.5, 'Huda');
        this._extension = extension;
        this._alive = true;
        this.connect('destroy', () => this._cleanup());
        this._snapshot = null;
        this._owner = null;
        this._snapshotOwner = null;
        this._stopped = GLib.file_test(`${GLib.get_user_runtime_dir()}/huda-prayer-tray-session-stopped`, GLib.FileTest.EXISTS);
        this._enabledCache = Gio.File.new_for_path(`${GLib.get_user_cache_dir()}/huda-prayer-tray/display-visibility.json`);
        this._cachedEnabled = true;
        try {
            const value = JSON.parse(new TextDecoder().decode(this._enabledCache.load_contents(null)[1]));
            if (value.schemaVersion === 1 && typeof value.enabled === 'boolean') this._cachedEnabled = value.enabled;
        } catch (_) { /* A new extension has no confirmed display preference yet. */ }
        this._cancel = new Gio.Cancellable();
        this._panelBox = new St.BoxLayout({style_class: 'huda-prayer-panel-box'});
        // The text first, then the logo (mirrored for right-to-left languages).
        this._panelLabel = new St.Label({y_align: Clutter.ActorAlign.CENTER, style_class: 'huda-prayer-panel-label'});
        this._panelLabel.clutter_text.ellipsize = Pango.EllipsizeMode.END;
        this._panelBox.add_child(this._panelLabel);
        const logo = extension.dir.get_child('huda-logo.png').get_uri();
        this._panelBox.add_child(new St.Widget({style_class: 'huda-prayer-panel-logo',
            style: `background-image: url("${logo}");`, y_align: Clutter.ActorAlign.CENTER}));
        this.add_child(this._panelBox);
        this.menu.actor.add_style_class_name('huda-prayer-popup');
        this._appearance = new Gio.Settings({schema_id: 'org.gnome.desktop.interface'});
        this._appearanceSignal = this._appearance.connect('changed::color-scheme', () => this._render());
        this._signal = Gio.DBus.session.signal_subscribe(BUS, IFACE, 'SnapshotChanged', PATH, null,
            Gio.DBusSignalFlags.NONE, (_bus, sender, _path, _iface, _member, params) => {
                if (sender === this._owner) this._accept(params.deep_unpack()[0]);
            });
        this._watch = Gio.bus_watch_name(Gio.BusType.SESSION, BUS, Gio.BusNameWatcherFlags.NONE,
            (_bus, _name, owner) => {
                this._observeCancel?.cancel();
                this._observeCancel = new Gio.Cancellable();
                this._owner = owner; this._request('GetSnapshot');
            },
            () => { this._observeCancel?.cancel(); this._owner = null; this._render(); });
        this._tick = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            if (!this._alive) return GLib.SOURCE_REMOVE;
            // Countdown text is local; only clock jumps, prayer boundaries and expiry request refresh.
            const now = Date.now();
            if (this._owner && (!this._lastNow || Math.abs(now - this._lastNow - 1000) > 5000 ||
                (this._snapshot?.validUntilUtcMs <= now && !this._requesting))) this._request('Refresh');
            this._lastNow = now;
            this._updateTimes(now);
            return GLib.SOURCE_CONTINUE;
        });
        this._render();
    }

    _accept(json) {
        if (!this._alive) return;
        try {
            const next = JSON.parse(json);
            if (!Format.validateSnapshot(next)) throw new Error('Incompatible prayer display');
            if (this._snapshot && next.appliedRevision < this._snapshot.appliedRevision) return;
            this._snapshot = next;
            this._snapshotOwner = this._owner;
            this._rememberEnabled(next.preferences?.enabled ?? true);
            this._stopped = next.state === 'stopped';
            const identity = JSON.stringify([next.appliedRevision, next.state, next.civilDate, next.next, next.rows, next.error]);
            if (identity !== this._renderIdentity) {
                this._renderIdentity = identity;
                this._render();
            }
            this._updateTimes(Date.now());
        } catch (error) { console.error(`Huda prayer display: ${error.message}`); this._render(); }
    }

    _rememberEnabled(enabled) {
        if (this._cachedEnabled === enabled) return;
        this._cachedEnabled = enabled;
        // Cache only the confirmed visibility bit, never a schedule or location.
        // It preserves hiding while the disabled companion has no bus owner.
        try {
            GLib.mkdir_with_parents(this._enabledCache.get_parent().get_path(), 0o700);
            this._enabledCache.replace_contents(JSON.stringify({schemaVersion: 1, enabled}),
                null, false, Gio.FileCreateFlags.PRIVATE | Gio.FileCreateFlags.REPLACE_DESTINATION, null);
        } catch (error) { console.error(`Huda display preference cache: ${error.message}`); }
    }

    _request(method) {
        if (!this._owner || this._requesting || !this._alive) return;
        this._requesting = true;
        const owner = this._owner;
        Gio.DBus.session.call(owner, PATH, IFACE, method, null, new GLib.VariantType('(s)'),
            Gio.DBusCallFlags.NO_AUTO_START, 5000, this._cancel, (bus, result) => {
                this._requesting = false;
                try {
                    const [json] = bus.call_finish(result).deep_unpack();
                    if (this._owner === owner) {
                        this._accept(json);
                        if (this._observingOwner !== owner) {
                            this._observingOwner = owner;
                            this._observe(owner, this._observeCancel);
                        }
                    }
                } catch (error) { if (this._alive) { console.error(error.message); this._render(); } }
            });
    }

    async _observe(owner, cancellable) {
        // Host-initiated replies also work under strict Snap's D-Bus profile.
        // The companion holds this call until a change or its 30-second heartbeat.
        while (this._alive && this._owner === owner && !cancellable.is_cancelled()) {
            try {
                const json = await new Promise((resolve, reject) => {
                    Gio.DBus.session.call(owner, PATH, IFACE, 'WaitForSnapshot',
                        new GLib.Variant('(t)', [this._snapshot?.changeSerial ?? 0]),
                        new GLib.VariantType('(s)'), Gio.DBusCallFlags.NO_AUTO_START,
                        40000, cancellable, (bus, result) => {
                            try { resolve(bus.call_finish(result).deep_unpack()[0]); }
                            catch (error) { reject(error); }
                        });
                });
                if (this._owner === owner && !cancellable.is_cancelled()) this._accept(json);
            } catch (error) {
                const remote = Gio.DBusError.get_remote_error(error);
                if (this._alive && this._owner === owner && !cancellable.is_cancelled() && !this._stopped &&
                    !['org.freedesktop.DBus.Error.NoReply', 'org.freedesktop.DBus.Error.ServiceUnknown', `${IFACE}.Stopping`].includes(remote))
                    console.error(`Huda prayer display observation: ${error.message}`);
                return;
            }
        }
    }

    _command(action) {
        this.menu.close();
        if (action !== 'quit') {
            // Fixed desktop identities; never execute a string supplied by a snapshot.
            const app = Shell.AppSystem.get_default().lookup_app('huda_huda.desktop') ??
                Shell.AppSystem.get_default().lookup_app('com.aw.huda.desktop');
            if (app) {
                const info = app.get_app_info();
                const context = global.create_app_launch_context(0, -1);
                if (action === 'prayerSettings' && info.list_actions().includes('prayer-settings'))
                    info.launch_action('prayer-settings', context);
                else app.activate();
                return;
            }
        }
        if (!this._owner) return;
        Gio.DBus.session.call(this._owner, PATH, IFACE, 'Command', new GLib.Variant('(s)', [action]),
            new GLib.VariantType('(b)'), Gio.DBusCallFlags.NO_AUTO_START, 10000, this._cancel,
            (bus, result) => {
                try {
                    const [accepted] = bus.call_finish(result).deep_unpack();
                    if (action === 'quit' && accepted) { this._stopped = true; this._render(); }
                }
                catch (error) { if (this._alive) console.error(`Huda activation: ${error.message}`); }
            });
    }

    _label(text, options = {}) {
        const label = new St.Label({text, x_expand: true, ...options});
        label.clutter_text.line_wrap = true;
        label.clutter_text.line_wrap_mode = Pango.WrapMode.WORD_CHAR;
        label.clutter_text.ellipsize = Pango.EllipsizeMode.NONE;
        return label;
    }

    _render() {
        if (!this._alive) return;
        const snapshot = this._snapshot;
        this.visible = !this._stopped && this._cachedEnabled;
        const presentation = snapshot?.presentation ?? {locale: 'en', rtl: false, textScale: 1, fontFamily: 'system', themeMode: 'system'};
        this._labels = {...LOCALES[presentation.locale] ?? LOCALES.en, ...presentation.strings};
        const labels = this._labels;
        if (this._experience?.deliveryOwner === 'native') labels.quitExplanation = labels.nativeQuitExplanation;
        this._presentation = presentation;
        const direction = presentation.rtl ? Clutter.TextDirection.RTL : Clutter.TextDirection.LTR;
        this.set_text_direction(direction);
        this.menu.actor.set_text_direction(direction);
        const dark = presentation.themeMode === 'dark' ||
            (presentation.themeMode === 'system' && this._appearance.get_string('color-scheme') === 'prefer-dark');
        const publishedTokens = presentation.tokens?.[dark ? 'dark' : 'light'];
        // St's CSS parser supports rgba(), while eight-digit web hex colors vary by Shell version.
        const tokens = publishedTokens ? Object.fromEntries(Object.entries(publishedTokens).map(([key, value]) => {
            const match = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(value);
            return [key, match ? `rgba(${parseInt(match[1], 16)},${parseInt(match[2], 16)},${parseInt(match[3], 16)},${parseInt(match[4], 16) / 255})` : 'transparent'];
        })) : null;
        const monitor = Main.layoutManager.primaryMonitor;
        const scale = Math.max(0.5, Math.min(2, presentation.textScale ?? 1));
        const width = Math.min(Math.max(322, 322 * scale), (monitor?.width ?? 1280) - 32);
        const height = Math.max(200, (monitor?.height ?? 720) - 100);
        // Amiri suits Arabic script; other languages keep the Shell's interface font.
        const font = presentation.fontFamily === 'Amiri' && presentation.rtl ? 'font-family: Amiri, Noto Naskh Arabic, Sans;' : '';
        this.menu.box.set_style(`width: ${width}px; ${font}${scale === 1 ? '' : ` font-size: ${scale}em;`}` +
            (tokens ? ` background-color: ${tokens.surface}; color: ${tokens.ink}; border-radius: 14px; border: 1px solid ${tokens.border};` : ''));
        this.menu.actor.set_style(tokens ? `-arrow-background-color: ${tokens.surface}; -arrow-border-color: ${tokens.border};` : '');
        const open = this.menu.isOpen;
        this._section?.destroy();
        this._scroll?.destroy();
        this.menu.removeAll();
        const section = new PopupMenu.PopupMenuSection();
        this._section = section;
        this.menu.addMenuItem(section);
        const scroll = new St.ScrollView({style: `max-height: ${height}px;`,
            hscrollbar_policy: St.PolicyType.NEVER, vscrollbar_policy: St.PolicyType.AUTOMATIC});
        this.menu.box.remove_child(section.actor);
        if (scroll.set_child) scroll.set_child(section.actor);
        else scroll.add_child(section.actor);
        this._scroll = scroll;
        this.menu.box.add_child(scroll);
        const body = new PopupMenu.PopupBaseMenuItem({reactive: false, can_focus: false});
        this._content = verticalBox({x_expand: true,
            style_class: 'huda-prayer-content'});
        body.add_child(this._content);
        section.addMenuItem(body);
        this._date = this._label('', {style_class: 'huda-prayer-date', ...muted(tokens)});
        this._content.add_child(this._date);
        this._hero = new St.BoxLayout({style_class: 'huda-prayer-hero',
            style: tokens ? `background-color: ${tokens.highlight};` : ''});
        const heroText = verticalBox({x_expand: true, y_align: Clutter.ActorAlign.CENTER});
        this._eyebrow = this._label('', {style_class: 'huda-prayer-note', ...muted(tokens)});
        heroText.add_child(this._eyebrow);
        this._nextName = this._label('', {style_class: 'huda-prayer-title'});
        this._remaining = this._label('', {style_class: 'huda-prayer-countdown', ...muted(tokens)});
        heroText.add_child(this._nextName); heroText.add_child(this._remaining);
        this._hero.add_child(heroText);
        this._nextClock = new St.Label({style_class: 'huda-prayer-hero-clock', y_align: Clutter.ActorAlign.CENTER,
            style: tokens ? `color: ${tokens.primary};` : ''});
        this._hero.add_child(this._nextClock); this._content.add_child(this._hero);
        this._message = this._label('', {style_class: 'huda-prayer-message', style: tokens ? `color: ${tokens.warning};` : ''});
        this._content.add_child(this._message);
        this._rows = [];
        for (let index = 0; index < Format.PRAYERS.length; index++) {
            const key = Format.PRAYERS[index];
            const row = new St.BoxLayout({style_class: 'huda-prayer-row'});
            row.add_child(new St.Icon({icon_name: ICONS[index], style_class: 'huda-prayer-row-icon',
                ...muted(tokens), y_align: Clutter.ActorAlign.CENTER}));
            row.add_child(this._label(labels[key], {y_align: Clutter.ActorAlign.CENTER}));
            const clock = new St.Label({style_class: 'huda-prayer-clock', y_align: Clutter.ActorAlign.CENTER});
            row.add_child(clock); this._content.add_child(row);
            this._rows.push({key, row, clock});
        }
        const location = snapshot?.locationLabel || snapshot?.timeZoneId || '';
        const meta = [location, presentation.methodLabel].filter(Boolean).join(' · ');
        if (meta) this._content.add_child(this._label(meta, {style_class: 'huda-prayer-meta', ...muted(tokens)}));
        if (snapshot?.provisional) this._content.add_child(this._label(labels.verifyLocation,
            {style: tokens ? `color: ${tokens.warning};` : ''}));
        for (const [session, action, key] of [
            // Dismiss also stops the sound, so offer one of the two.
            [this._experience?.focusSession && this._experience?.focusCanDismiss ? null
                : this._experience?.audioSession, 'stopAudio', 'stop'],
            [this._experience?.focusSession, this._experience?.focusCanDismiss ? 'dismissFocus' : 'emergencyExit',
                this._experience?.focusCanDismiss ? 'dismiss' : 'emergencyExit'],
        ]) {
            if (!session) continue;
            const item = new PopupMenu.PopupMenuItem(labels[key]);
            item.connect('activate', () => this._extension._focus.command(action, session).catch(console.error));
            section.addMenuItem(item);
        }
        const separator = new PopupMenu.PopupSeparatorMenuItem();
        if (tokens) separator._separator?.set_style(`background-color: ${tokens.border};`);
        section.addMenuItem(separator);
        for (const [action, key] of [['openHuda', 'openHuda'], ['prayerSettings', 'prayerSettings'], ['quit', 'quitHuda']]) {
            const item = new PopupMenu.PopupMenuItem(labels[key]);
            if (tokens) {
                // Hover and keyboard focus in Huda's palette, not the Shell's.
                const paint = () => item.set_style(`color: ${tokens.ink};` +
                    (item.active ? ` background-color: ${tokens.highlight};` : ''));
                item.connect('notify::active', paint);
                paint();
            }
            item.label.clutter_text.line_wrap = true;
            item.label.clutter_text.ellipsize = Pango.EllipsizeMode.NONE;
            item.accessible_name = labels[key];
            item.connect('activate', () => this._command(action));
            if (action === 'quit') item.setSensitive(Boolean(this._owner));
            section.addMenuItem(item);
        }
        const explanation = new PopupMenu.PopupBaseMenuItem({reactive: false, can_focus: false});
        explanation.add_child(this._label(labels.quitExplanation,
            {style_class: 'huda-prayer-note', ...muted(tokens)}));
        section.addMenuItem(explanation);
        this._tokens = tokens;
        this._updateTimes(Date.now());
        if (open) this.menu.open();
    }

    _updateTimes(now) {
        if (!this._labels || !this._alive) return;
        const snapshot = this._snapshot;
        const labels = this._labels;
        const valid = Boolean(this._owner && this._snapshotOwner === this._owner && snapshot?.validUntilUtcMs > now);
        const usable = valid && !['needsSetup', 'disabled', 'stopped'].includes(snapshot.state);
        const errorKey = !valid ? 'serviceUnavailable' : snapshot.state === 'needsSetup' ? 'needsSetup'
            : snapshot.state === 'calculationUnavailable' ? 'calculationUnavailable' : snapshot.error ? 'serviceUnavailable' : null;
        this._panelLabel.text = Format.indicator(valid ? snapshot : null, now, labels);
        this._panelLabel.visible = snapshot?.preferences?.style !== 'iconOnly';
        const prayer = usable ? Format.moment(snapshot, now) : null;
        const current = Boolean(prayer && prayer === snapshot.current);
        const counter = prayer ? (current ? Format.elapsed : Format.countdown)(prayer.utcMs, now, this._presentation, labels) : '';
        this.accessible_name = `Huda · ${labels.prayerTimes}${prayer ? ` · ${labels[prayer.key]} ${counter}` : ''}`;
        this._date.text = Format.date(now, snapshot?.timeZoneId, this._presentation);
        this._hero.visible = Boolean(prayer);
        this._eyebrow.text = current ? labels.current : labels.nextPrayer;
        this._nextName.text = prayer ? labels[prayer.key] : '';
        this._remaining.text = counter;
        this._nextClock.text = prayer ? Format.clock(prayer.utcMs, snapshot.timeZoneId, this._presentation) : '';
        this._message.visible = Boolean(errorKey);
        this._message.text = errorKey ? labels[errorKey] : '';
        for (const {key, row, clock} of this._rows) {
            // After Isha the next prayer is tomorrow's Fajr: its row shows that time.
            const next = prayer?.key === key;
            const time = !usable ? null : next ? prayer.utcMs : snapshot.rows.find(item => item.key === key)?.utcMs;
            clock.text = Format.clock(time, snapshot?.timeZoneId, this._presentation);
            const passed = !next && Number.isFinite(time) && time <= now;
            row.opacity = passed && !this._tokens ? 140 : 255;
            row.set_style(next ? `font-weight: bold;${this._tokens ? ` background-color: ${this._tokens.highlight}; color: ${this._tokens.primary};` : ''}`
                : passed && this._tokens ? `color: ${this._tokens.muted};` : '');
            row.accessible_name = `${labels[key]} ${clock.text}`;
        }
    }

    _cleanup() {
        if (!this._alive) return;
        this._alive = false;
        this._cancel.cancel();
        this._observeCancel?.cancel();
        if (this._tick) GLib.Source.remove(this._tick);
        if (this._watch) Gio.bus_unwatch_name(this._watch);
        if (this._signal) Gio.DBus.session.signal_unsubscribe(this._signal);
        if (this._appearanceSignal) this._appearance.disconnect(this._appearanceSignal);
    }

    destroy() {
        this._cleanup();
        super.destroy();
    }
});

export default class HudaPrayerExtension extends Extension {
    enable() {
        this._control = new ServiceControl();
        this._indicator = new PrayerIndicator(this);
        Main.panel.addToStatusArea('huda-prayer-tray', this._indicator);
        this._focus = new PrayerFocus(snapshot => {
            const prior = this._indicator?._experience;
            if (!this._indicator) return;
            this._indicator._experience = snapshot;
            if (prior?.audioSession !== snapshot.audioSession || prior?.focusSession !== snapshot.focusSession ||
                prior?.deliveryOwner !== snapshot.deliveryOwner) this._indicator._render();
        });
    }
    disable() {
        this._focus?.destroy();
        this._focus = null;
        this._control?.destroy();
        this._control = null;
        this._indicator?.destroy();
        this._indicator = null;
    }
}
