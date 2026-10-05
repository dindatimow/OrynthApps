#!/usr/bin/env bash
# Setup otomatis (macOS/Linux/Git Bash). Jalankan dari folder proyek: bash setup.sh
set -euo pipefail
cd "$(dirname "$0")"
flutter create . --platforms=android --org com.orynth --project-name orynth_apps
rm -f test/widget_test.dart
cp -r android_overlay/. android/
for f in android/app/build.gradle.kts android/app/build.gradle; do
  if [ -f "$f" ]; then
    sed -i.bak -E 's/minSdk(Version)? *(=)? *flutter\.minSdkVersion/minSdk\1\2 23/' "$f"
    rm -f "$f.bak"
  fi
done
flutter pub get
echo "SELESAI. Lanjut: isi .vscode/launch.json lalu tekan F5."
