import Atk from 'gi://Atk';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Pango from 'gi://Pango';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as ModalDialog from 'resource:///org/gnome/shell/ui/modalDialog.js';
import {LOCALES} from './locale/labels.js';
import * as Format from './format.js';

const BUS = 'com.aw.huda.PrayerTray';
const PATH = '/com/aw/huda/PrayerExperience';
const IFACE = 'com.aw.huda.PrayerExperience1';
// An unlocked desktop session. Distributions run their own session mode on
// top of 'user' (Ubuntu runs 'ubuntu'), so its parent counts too.
function userSession() {
    const mode = Main.sessionMode;
    return !mode.isLocked && !mode.isGreeter &&
        (mode.currentMode === 'user' || mode.parentMode === 'user');
}
function call(owner, member, args, signature = 's', cancel = null) {
    return new Promise((resolve, reject) => {
        Gio.DBus.session.call(owner, PATH, IFACE, member,
            args === null ? null : new GLib.Variant(`(${signature})`, args),
            new GLib.VariantType('(s)'), Gio.DBusCallFlags.NO_AUTO_START, 30000, cancel,
            (bus, result) => {
                try { resolve(JSON.parse(bus.call_finish(result).deep_unpack()[0])); }
                catch (error) { reject(error); }
            });
    });
}
function vertical(options = {}) {
    const box = new St.BoxLayout(options);
    box.layout_manager.orientation = Clutter.Orientation.VERTICAL;
    return box;
}
function css(hex) {
    const match = /^#(..)(..)(..)(..)$/.exec(hex ?? '');
    return match ? `rgba(${parseInt(match[1], 16)},${parseInt(match[2], 16)},${parseInt(match[3], 16)},${parseInt(match[4], 16) / 255})` : 'transparent';
}

// One ModalDialog owns the grab. Extra displays render synchronized cards in its
// actor group; they never push competing modal grabs or ordinary Wayland windows.
export class PrayerFocus {
    constructor(onStatus = null) {
        this._alive = true;
        this._onStatus = onStatus;
        this._appearance = new Gio.Settings({schema_id: 'org.gnome.desktop.interface'});
        this._appearanceSignal = this._appearance.connect('changed::color-scheme', () => this._restyle());
        this._sessionSignal = Main.sessionMode.connect('updated', () => {
            if (!userSession()) this._close();
            this._report().catch(console.error);
        });
        this._monitorsSignal = Main.layoutManager.connect('monitors-changed', () => {
            if (this._session) this.command('emergencyExit', this._session).catch(console.error);
            this._close(); // No stale coordinates after hotplug; the session is interrupted.
            this._report().catch(console.error);
        });
        this._environmentTick = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 10, () => {
            this._report().catch(console.error);
            return GLib.SOURCE_CONTINUE;
        });
        this._watch = Gio.bus_watch_name(Gio.BusType.SESSION, BUS, Gio.BusNameWatcherFlags.NONE,
            (_bus, _name, owner) => {
                this._cancel?.cancel(); this._close();
                this._owner = owner; this._cancel = new Gio.Cancellable();
                this._listen(owner, this._cancel).catch(console.error);
            }, () => { this._owner = null; this._cancel?.cancel(); this._close(); });
    }
    async _report() {
        if (!this._alive || !this._owner) return;
        await call(this._owner, 'ReportEnvironment', [JSON.stringify({
            available: true, unlocked: userSession(),
            displays: Main.layoutManager.monitors.map(monitor => ({
                id: `monitor-${monitor.index}`, name: `${monitor.index + 1} · ${monitor.width} × ${monitor.height}`,
            })),
        })]);
    }
    async _listen(owner, cancel) {
        try { await this._report(); }
        catch (error) {
            if (Gio.DBusError.get_remote_error(error)?.endsWith('UnknownMethod')) return;
        }
        let serial = 0;
        while (this._alive && this._owner === owner && !cancel.is_cancelled()) {
            try {
                const snapshot = await call(owner, 'WaitForExperience', [serial], 't', cancel);
                if (!this._alive || this._owner !== owner) return;
                if (snapshot.version !== 1) throw new Error('Unsupported prayer experience version');
                serial = snapshot.changeSerial;
                this._snapshot = snapshot;
                this._onStatus?.(snapshot);
                await this._update(snapshot);
            } catch (error) {
                if (cancel.is_cancelled() || !this._alive) return;
                this._close();
                if (Gio.DBusError.get_remote_error(error)?.includes('Unknown')) return;
                if (Gio.DBusError.get_remote_error(error)?.endsWith('.Unavailable')) return;
                if (Gio.DBusError.get_remote_error(error)?.endsWith('.Rejected')) continue;
                throw error;
            }
        }
    }
    async command(action, session) {
        if (!this._owner || !session) return;
        await call(this._owner, 'Command', [JSON.stringify({action, sessionId: session})]);
    }
    async _update(snapshot) {
        const focus = snapshot.focus;
        if (!focus || !snapshot.focusAvailable || Main.sessionMode.isLocked) { this._close(); return; }
        if (this._session === focus.sessionId) {
            this._deadline = GLib.get_monotonic_time() + focus.remainingSeconds * 1000000;
            this._restyle(); return;
        }
        this._close();
        if (focus.state !== 'pending') return; // Never resurrect an acknowledged session after owner loss/re-enable.
        let presented = false, error = null;
        try {
            this._show(snapshot);
            presented = this._dialog.open(global.get_current_time(), false);
            if (!presented) throw new Error('GNOME could not acquire Focus input');
            const requested = focus.settings.focusDisplay;
            if (requested.startsWith('monitor-')) {
                const index = Number(requested.slice(8));
                if (!Main.layoutManager.monitors[index]) throw new Error('Selected display unavailable');
                this._dialog._monitorConstraint.index = index;
            }
        } catch (failure) { error = failure.message; this._close(); }
        if (this._session !== focus.sessionId && presented) return;
        await call(this._owner, 'AcknowledgeFocus', [JSON.stringify({
            sessionId: focus.sessionId, revision: focus.revision, presented, error,
        })]);
    }
    _label(text, size = 1) {
        const label = new St.Label({text, x_expand: true});
        label.clutter_text.line_wrap = true;
        label.clutter_text.line_wrap_mode = Pango.WrapMode.WORD_CHAR;
        label.clutter_text.ellipsize = Pango.EllipsizeMode.NONE;
        label.clutter_text.line_alignment = this._snapshot?.presentation?.rtl ? Pango.Alignment.RIGHT : Pango.Alignment.LEFT;
        label.set_style(`font-size: ${size}em;`);
        return label;
    }
    _content(snapshot, monitor, primary) {
        const focus = snapshot.focus, presentation = snapshot.presentation;
        const labels = {...LOCALES[presentation.locale], ...presentation.strings};
        const scale = presentation.textScale ?? 1;
        const immersive = focus.settings.focusStyle === 'immersive';
        const width = Math.min(immersive ? monitor.width - 64 : 520 * scale, monitor.width - 48);
        const height = Math.min(immersive ? monitor.height - 96 : 640 * scale, monitor.height - 64);
        const card = vertical({style_class: 'huda-prayer-focus-card', width, height, x_expand: true,
            accessible_role: Atk.Role.DIALOG, accessible_name: labels[focus.prayerKey]});
        card.set_text_direction(presentation.rtl ? Clutter.TextDirection.RTL : Clutter.TextDirection.LTR);
        const text = vertical({style: 'spacing: 16px;', x_expand: true});
        const labelNodes = {};
        for (const [key, value, size] of [
            ['title', labels[focus.prayerKey], 2],
            ['clock', Format.clock(focus.prayerUtcMs, snapshot.timeZoneId, presentation), 1.1],
            ['focusMessage', labels.focusMessage, 1], ['verse', labels.verse, 1.3],
            ['verseReference', labels.verseReference, .85],
        ]) { labelNodes[key] = this._label(value, size); text.add_child(labelNodes[key]); }
        if (focus.settings.focusCommitment && !focus.preview) {
            labelNodes.lockedHint = this._label(labels.lockedHint, .85); text.add_child(labelNodes.lockedHint);
        }
        const scroll = new St.ScrollView({overlay_scrollbars: false, x_expand: true, y_expand: true,
            style: `max-height: ${Math.max(100, height - 170)}px;`});
        scroll.set_child(text); card.add_child(scroll);
        const timer = this._label('', 1.2); card.add_child(timer);
        const progress = new St.Widget({style_class: 'huda-prayer-focus-progress', height: 5, x_expand: true});
        const fill = new St.Widget({height: 5}); progress.add_child(fill); card.add_child(progress);
        const buttons = vertical({style: 'spacing: 8px;', x_expand: true});
        const buttonNodes = {};
        function button(key, action) {
            const label = labels[key];
            const result = new St.Button({label, can_focus: true, reactive: true,
                style_class: 'button', x_expand: true, accessible_name: label});
            result.connect('clicked', action); buttons.add_child(result); buttonNodes[key] = result; return result;
        }
        // One action at a time: Dismiss also stops the sound.
        if (!focus.settings.focusCommitment || focus.preview)
            button('dismiss', () => this.command('dismissFocus', focus.sessionId).catch(console.error));
        else if (focus.settings.focusAudio)
            button('stop', () => this.command('stopAudio', focus.sessionId).catch(console.error));
        const emergency = button('emergencyExit', () => {
            this.command('emergencyExit', focus.sessionId).catch(console.error); this._close();
        });
        card.add_child(buttons);
        if (primary) this._dialog.setInitialKeyFocus(emergency);
        this._cards.push({card, timer, fill, progress, labelNodes, buttonNodes, monitor});
        return card;
    }
    _show(snapshot) {
        const focus = snapshot.focus;
        this._session = focus.sessionId;
        this._deadline = GLib.get_monotonic_time() + focus.remainingSeconds * 1000000;
        this._cards = [];
        const requested = focus.settings.focusDisplay;
        const index = requested.startsWith('monitor-') ? Number(requested.slice(8)) : global.display.get_current_monitor();
        const monitor = Main.layoutManager.monitors[index];
        if (!monitor) throw new Error('Selected display unavailable');
        this._dialog = new ModalDialog.ModalDialog({styleClass: 'huda-prayer-focus-dialog',
            shouldFadeIn: false, shouldFadeOut: false, destroyOnClose: false});
        this._dialog.contentLayout.add_child(this._content(snapshot, monitor, true));
        this._dialog.setButtons([{label: '', key: Clutter.KEY_Escape, action: () => {
            this.command('emergencyExit', focus.sessionId).catch(console.error); this._close();
        }}]);
        this._dialog.buttonLayout.hide();
        if (requested === 'all') {
            // Keep every display above the dialog's one input-blocking lightbox.
            // Adding independent children beside the highlighted background can
            // put cards below it and retain disposed siblings during teardown.
            const group = new St.Widget({x_expand: true, y_expand: true});
            group.add_constraint(new Clutter.BindConstraint({source: this._dialog, coordinate: Clutter.BindCoordinate.ALL}));
            this._dialog._lightbox?.highlight(null);
            this._dialog.remove_child(this._dialog._backgroundBin);
            this._dialog.add_child(group);
            group.add_child(this._dialog._backgroundBin);
            for (const other of Main.layoutManager.monitors.filter(item => item.index !== index)) {
                const bin = new St.Bin({x: other.x, y: other.y, width: other.width, height: other.height,
                    child: this._content(snapshot, other, false)});
                group.add_child(bin);
            }
            this._dialog._lightbox?.highlight(group);
        }
        this._restyle();
        this._timer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
            this._updateTimer(); return GLib.SOURCE_CONTINUE;
        });
        this._updateTimer();
    }
    _updateTimer() {
        if (!this._dialog || !this._snapshot?.focus) return;
        const remaining = Math.max(0, Math.ceil((this._deadline - GLib.get_monotonic_time()) / 1000000));
        const presentation = this._snapshot.presentation;
        const label = {...LOCALES[presentation.locale], ...presentation.strings}.remaining;
        for (const item of this._cards) {
            item.timer.text = `${label} ${Format.isolate(Format.digits(`${Math.floor(remaining / 60)}:${String(remaining % 60).padStart(2, '0')}`, presentation))}`;
            item.fill.width = Math.max(0, item.progress.width * remaining / this._snapshot.focus.durationSeconds);
        }
        if (remaining === 0) this._close();
    }
    _restyle() {
        if (!this._cards?.length || !this._snapshot?.presentation) return;
        const p = this._snapshot.presentation;
        const direction = p.rtl ? Clutter.TextDirection.RTL : Clutter.TextDirection.LTR;
        this._dialog.set_text_direction(direction);
        this._dialog.dialogLayout.set_text_direction(direction);
        this._dialog.contentLayout.set_text_direction(direction);
        const dark = p.themeMode === 'dark' || p.themeMode === 'system' && this._appearance.get_string('color-scheme') === 'prefer-dark';
        const tokens = p.tokens[dark ? 'dark' : 'light'];
        const labels = {...LOCALES[p.locale], ...p.strings};
        const focus = this._snapshot.focus;
        this._dialog.dialogLayout.set_style(`padding: 0; spacing: 0; border-radius: 20px; background-color: ${css(tokens.card)};`);
        for (const item of this._cards) {
            item.card.set_text_direction(direction);
            item.card.accessible_name = labels[focus.prayerKey];
            const immersive = focus.settings.focusStyle === 'immersive';
            item.card.width = Math.min(immersive ? item.monitor.width - 64 : 520 * p.textScale, item.monitor.width - 48);
            item.card.height = Math.min(immersive ? item.monitor.height - 96 : 640 * p.textScale, item.monitor.height - 64);
            for (const [key, label] of Object.entries(item.labelNodes)) {
                label.text = key === 'title' ? labels[focus.prayerKey] : key === 'clock'
                    ? Format.clock(focus.prayerUtcMs, this._snapshot.timeZoneId, p) : labels[key];
                label.clutter_text.line_alignment = p.rtl ? Pango.Alignment.RIGHT : Pango.Alignment.LEFT;
            }
            for (const [key, button] of Object.entries(item.buttonNodes)) {
                button.label = labels[key]; button.accessible_name = labels[key];
                button.set_style(`background-color: ${css(tokens.highlight)}; color: ${css(tokens.ink)}; border-color: ${css(tokens.primary)};`);
            }
            item.card.set_style(`padding: 24px; spacing: 16px; border-radius: 20px; background-color: ${css(tokens.card)}; color: ${css(tokens.ink)}; border: 1px solid ${css(tokens.border)}; font-family: ${p.fontFamily === 'Amiri' ? 'Amiri, Noto Sans, Sans' : 'Sans'}; font-size: ${16 * p.textScale}px;`);
            item.progress.set_style(`background-color: ${css(tokens.highlight)};`);
            item.fill.set_style(`background-color: ${css(tokens.primary)};`);
        }
    }
    _close() {
        if (this._timer) GLib.Source.remove(this._timer);
        this._timer = 0;
        this._dialog?._lightbox?.highlight(null);
        this._dialog?.close(global.get_current_time());
        this._dialog?.destroy(); this._dialog = null;
        this._cards = []; this._session = null;
    }
    destroy() {
        if (!this._alive) return;
        if (this._owner) call(this._owner, 'ReportEnvironment', [JSON.stringify({available: false, unlocked: userSession(), displays: []})]).catch(console.error);
        this._alive = false; this._cancel?.cancel(); this._close();
        if (this._watch) Gio.bus_unwatch_name(this._watch);
        GLib.Source.remove(this._environmentTick);
        Main.sessionMode.disconnect(this._sessionSignal);
        Main.layoutManager.disconnect(this._monitorsSignal);
        this._appearance.disconnect(this._appearanceSignal);
    }
}
