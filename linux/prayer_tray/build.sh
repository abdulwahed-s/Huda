#!/usr/bin/env bash
set -euo pipefail
task_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
task_dotnet=${HUDA_DOTNET:-dotnet}
task_output=${HUDA_TRAY_OUTPUT:-"$task_root/build/linux/prayer-tray"}
cd "$task_root"
mkdir -p "$task_output"
cd "$task_root/linux/prayer_tray" # apply this project's SDK pin, even with other SDKs installed
"$task_dotnet" restore Huda.PrayerTray/Huda.PrayerTray.csproj --locked-mode
"$task_dotnet" publish Huda.PrayerTray/Huda.PrayerTray.csproj -c Release \
  -r linux-x64 --self-contained true --no-restore -o "$task_output/companion"
cd "$task_root"
python3 - "$task_root" "$task_output" <<'PY'
from pathlib import Path
import json, shutil, sys, zipfile
root, output = map(Path, sys.argv[1:])
staging = output / 'extension'
if staging.exists():
    shutil.rmtree(staging)
extension = staging / 'prayer-tray@huda'
extension.mkdir(parents=True, exist_ok=True)
source = root / 'linux/gnome_extension'
for name in ['metadata.json', 'extension.js', 'stylesheet.css', 'format.js', 'service-control.js', 'focus.js', 'locale/labels.js']:
    destination = extension / name
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / name, destination)
shutil.copy2(root / 'macos/Runner/Assets.xcassets/HudaMenuIcon.imageset/huda-logo-60.png', extension / 'huda-logo.png')
(extension / 'fonts').mkdir(exist_ok=True)
for name in ['Amiri-Regular.ttf', 'Amiri-Bold.ttf']:
    shutil.copy2(root / 'assets/fonts' / name, extension / 'fonts' / name)
version = json.loads((extension / 'metadata.json').read_text())['version-name']
archive = output / f'huda-prayer-tray-{version}.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
    for path in sorted(extension.rglob('*')):
        if path.is_file() and not path.name.startswith('._'):
            info = zipfile.ZipInfo(path.relative_to(extension).as_posix(), (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            package.writestr(info, path.read_bytes())
print(archive)
# extensions.gnome.org package: the panel without the fonts, which only the
# bundled installer copies into ~/.local/share/fonts.
store = output / 'prayer-tray@huda.shell-extension.zip'
with zipfile.ZipFile(store, 'w', zipfile.ZIP_DEFLATED) as package:
    for path in sorted(extension.rglob('*')):
        relative = path.relative_to(extension).as_posix()
        if path.is_file() and not path.name.startswith('._') and not relative.startswith('fonts/'):
            info = zipfile.ZipInfo(relative, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            package.writestr(info, path.read_bytes())
print(store)
shutil.copy2(root / 'linux/prayer_tray/install_extension.sh', output / 'install-huda-prayer-panel.sh')
audio = output / 'audio/v1/huda-default'
audio.mkdir(parents=True, exist_ok=True)
shutil.copy2(root / 'windows/prayer_taskbar/Huda.PrayerTaskbar/Assets/Adhan/v1/huda-default/full.mp3', audio / 'full.mp3')
shutil.copy2(root / 'assets/json/athan_catalog.json', output / 'audio/catalog.json')
PY
if [[ ${1:-} != --native-only ]]; then
  "${HUDA_FLUTTER:-flutter}" build linux --release
fi
