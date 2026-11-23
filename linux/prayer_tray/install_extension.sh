#!/usr/bin/env bash
# Installs the Huda Prayer Panel (GNOME Shell extension) for the current user.
#
# The Snap ships this script next to the panel ZIP, and Huda shows the command
# that runs it. It also works on its own, downloading the panel from Huda's
# latest GitHub release:
#   curl -fsSL https://github.com/abdulwahed-s/Huda/releases/latest/download/install-huda-prayer-panel.sh | bash
set -euo pipefail
task_uuid=prayer-tray@huda
task_release=https://github.com/abdulwahed-s/Huda/releases/latest/download/huda-gnome-prayer-panel.zip

if ! command -v gnome-extensions >/dev/null 2>&1; then
  printf '%s\n' 'The Huda prayer panel needs the GNOME desktop.' \
    'Prayer notifications still work without it.' >&2
  exit 1
fi

task_zip=
if [[ $# -gt 0 ]]; then
  task_zip=$1
else
  # Piped into bash there is no script file: then only the download applies.
  task_directory=
  if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
    task_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  fi
  shopt -s nullglob
  task_archives=()
  if [[ -n $task_directory ]]; then
    task_archives=("$task_directory"/huda-prayer-tray-*.zip)
    if [[ ${#task_archives[@]} -eq 0 ]]; then
      task_archives=("$task_directory"/../../build/linux/prayer-tray/huda-prayer-tray-*.zip)
    fi
  fi
  if [[ ${#task_archives[@]} -eq 1 ]]; then
    task_zip=${task_archives[0]}
  elif [[ ${#task_archives[@]} -gt 1 ]]; then
    printf '%s\n' 'Several panel ZIP files were found. Pass the one to install.' >&2
    exit 1
  fi
fi

if [[ -z $task_zip ]]; then
  task_download=$(mktemp -d)
  trap 'rm -rf "$task_download"' EXIT
  task_zip="$task_download/huda-gnome-prayer-panel.zip"
  printf '%s\n' 'Downloading the Huda prayer panel from GitHub…'
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$task_release" -o "$task_zip"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$task_zip" "$task_release"
  else
    printf '%s\n' 'Install curl or wget, or download the panel from:' "$task_release" >&2
    exit 1
  fi
fi

printf '%s\n' 'Installing the Huda prayer panel…'
gnome-extensions install --force "$task_zip"

task_font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/huda"
if command -v unzip >/dev/null 2>&1 &&
  unzip -Z1 "$task_zip" 2>/dev/null | grep -q '^fonts/.*\.ttf$'; then
  mkdir -p "$task_font_dir"
  unzip -jo "$task_zip" 'fonts/*.ttf' -d "$task_font_dir" >/dev/null
  command -v fc-cache >/dev/null 2>&1 && fc-cache "$task_font_dir" || true
fi

# GNOME on Wayland only sees a newly installed extension after the next login,
# so "gnome-extensions enable" can fail now. Marking it enabled in GNOME's own
# settings turns it on at that login, with no trip to the Extensions app.
task_enable_at_login() {
  command -v gsettings >/dev/null 2>&1 || return 1
  gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true
  local current
  current=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null) || return 1
  [[ $current == *"'$task_uuid'"* ]] && return 0
  if [[ $current == "@as []" || $current == "[]" ]]; then
    current="['$task_uuid']"
  else
    current="${current%]}, '$task_uuid']"
  fi
  gsettings set org.gnome.shell enabled-extensions "$current"
}

if gnome-extensions enable "$task_uuid" 2>/dev/null &&
  LC_ALL=C gnome-extensions info "$task_uuid" 2>/dev/null |
    grep -Eq '^[[:space:]]*State: (ACTIVE|ENABLED)[[:space:]]*$'; then
  printf '\n%s\n' '✓ Done. The prayer panel is in your top bar. You can close this window.'
elif task_enable_at_login; then
  printf '\n%s\n%s\n' '✓ Installed. Log out and log back in to see the prayer panel in your top bar.' \
    '  It turns on by itself; you can close this window.'
else
  printf '\n%s\n%s\n' '✓ Installed. Log out and log back in,' \
    '  then open the Extensions app and turn on "Huda Prayer Panel".'
fi
