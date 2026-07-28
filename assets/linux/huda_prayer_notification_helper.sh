#!/bin/sh

# Huda's Linux scheduling adapter. It is deliberately dependency-light: the
# app writes a local TSV plan and this user service sleeps until the next due
# prayer. No location or prayer settings leave the device.

set -u

if [ -n "${SNAP_USER_COMMON:-}" ]; then
  data_root="$SNAP_USER_COMMON/prayer-notifications"
elif [ -n "${SNAP_USER_DATA:-}" ]; then
  data_root="$SNAP_USER_DATA/prayer-notifications"
else
  data_root="${XDG_DATA_HOME:-$HOME/.local/share}/huda/prayer-notifications"
fi

schedule_file="${HUDA_PRAYER_SCHEDULE:-$data_root/schedule.tsv}"
state_file="$data_root/last-delivered"
mkdir -p "$data_root"

# The autostart fallback and an already-running user service may overlap when
# Huda is upgraded. Hold a per-user lock so only one helper can deliver.
if command -v flock >/dev/null 2>&1; then
  exec 9>"$data_root/helper.lock"
  flock -n 9 || exit 0
else
  lock_dir="$data_root/helper.lock.d"
  mkdir "$lock_dir" 2>/dev/null || exit 0
  trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT INT TERM
fi

decode_base64() {
  decoded=$(printf '%s' "$1" | base64 --decode 2>/dev/null) || \
    decoded=$(printf '%s' "$1" | base64 -D 2>/dev/null) || decoded=''
  printf '%s' "$decoded"
}

while :; do
  if [ ! -r "$schedule_file" ]; then
    sleep 60
    continue
  fi

  now=$(date +%s)
  last_id=''
  [ -r "$state_file" ] && last_id=$(sed -n '1p' "$state_file")
  next_epoch=''
  next_id=''
  next_title=''
  next_body=''

  tab=$(printf '\t')
  while IFS="$tab" read -r epoch notification_id title body; do
    case "$epoch" in
      ''|*[!0-9]*) continue ;;
    esac
    [ "$notification_id" = "$last_id" ] && continue
    # Do not display notifications more than 15 minutes after resume.
    [ "$epoch" -lt $((now - 900)) ] && continue
    if [ -z "$next_epoch" ] || [ "$epoch" -lt "$next_epoch" ]; then
      next_epoch="$epoch"
      next_id="$notification_id"
      next_title="$title"
      next_body="$body"
    fi
  done < "$schedule_file"

  if [ -z "$next_epoch" ]; then
    sleep 300
    continue
  fi

  delay=$((next_epoch - now))
  if [ "$delay" -gt 60 ]; then
    sleep 60
    continue
  fi
  if [ "$delay" -gt 0 ]; then
    sleep "$delay"
  fi

  title=$(decode_base64 "$next_title")
  body=$(decode_base64 "$next_body")
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name='Huda' --urgency=critical "$title" "$body" || true
  fi
  printf '%s\n' "$next_id" > "$state_file"
  sleep 1
done
