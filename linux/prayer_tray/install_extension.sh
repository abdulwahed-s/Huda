#!/usr/bin/env bash
set -euo pipefail
task_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ $# -gt 0 ]]; then
  task_zip=$1
else
  shopt -s nullglob
  task_archives=("$task_directory"/huda-prayer-tray-*.zip)
  if [[ ${#task_archives[@]} -eq 0 ]]; then
    task_archives=("$task_directory"/../../build/linux/prayer-tray/huda-prayer-tray-*.zip)
  fi
  if [[ ${#task_archives[@]} -ne 1 ]]; then
    printf '%s\n' 'Choose the Huda prayer panel ZIP and pass its path to this installer.' >&2
    exit 1
  fi
  task_zip=${task_archives[0]}
fi
printf '%s\n' 'Installing Huda Prayer Panel…'
gnome-extensions install --force "$task_zip"
task_font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/huda"
mkdir -p "$task_font_dir"
unzip -jo "$task_zip" 'fonts/*.ttf' -d "$task_font_dir"
fc-cache "$task_font_dir"
if gnome-extensions enable prayer-tray@huda &&
  LC_ALL=C gnome-extensions info prayer-tray@huda 2>/dev/null |
    grep -Eq '^[[:space:]]*State: (ACTIVE|ENABLED)[[:space:]]*$'; then
  printf '%s\n' 'Installed and enabled. Return to Huda and select “Check setup”.'
else
  printf '%s\n' 'Installed. Log out of your desktop and log back in.' \
    'Then open Extensions and turn on “Huda Prayer Panel”.' \
    'Return to Huda and select “Check setup”.'
fi
