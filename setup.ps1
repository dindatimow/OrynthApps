# Setup otomatis untuk Windows PowerShell. Jalankan dari folder proyek: .\setup.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
flutter create . --platforms=android --org com.orynth --project-name orynth_apps
Remove-Item -Force -ErrorAction SilentlyContinue "test\widget_test.dart"
Copy-Item -Path "android_overlay\*" -Destination "android" -Recurse -Force
foreach ($f in @("android\app\build.gradle.kts", "android\app\build.gradle")) {
  if (Test-Path $f) {
    $full = (Resolve-Path $f).Path
    $c = [System.IO.File]::ReadAllText($full)
    $c = $c -replace 'minSdk(Version)?(\s*=\s*|\s+)flutter\.minSdkVersion', 'minSdk$1$2 23'
    [System.IO.File]::WriteAllText($full, $c)
  }
}
flutter pub get
Write-Host "SELESAI. Lanjut: isi .vscode/launch.json lalu tekan F5."
