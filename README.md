# OrynthApps (orynth_apps) — Flutter + Firebase (REST), aplikasi Android native

> Flutter mengompilasi Dart menjadi **kode mesin native (ARM)** dan menghasilkan **APK yang terpasang di HP**
> (bukan web/PWA). Proyek ini juga memuat lapisan **native Kotlin** (`MainActivity.kt`) untuk fitur keamanan.

## Fitur
- Register/login email asli (**wajib verifikasi email**), lupa password, hapus akun
- CRUD catatan (POST, GET, PUT, PATCH, DELETE ke Firebase Realtime Database via REST)
- **Pin catatan** (fitur baru): sematkan catatan penting, otomatis tampil di atas dengan bingkai & ikon pin
- Warna latar pastel pilihan user (tersimpan per akun), tampilan responsif
- Stateless/Stateful, Extract Widget, dekorasi TextField

## LANGKAH MENJALANKAN DI HP ANDROID

### A. Siapkan komputer (sekali saja)
1. Install **Flutter SDK** (docs.flutter.dev/get-started/install) dan **Android Studio** (untuk Android SDK).
2. Install **VS Code** + ekstensi **Flutter** (otomatis memasang Dart).
3. Terminal: `flutter doctor --android-licenses` (terima semua), lalu `flutter doctor` → pastikan bagian Android ✔.

### B. Siapkan HP
1. Settings → About phone → ketuk **Build number** 7×  → aktif *Developer options*.
2. Developer options → aktifkan **USB debugging**.
3. Colok USB ke PC, izinkan "Allow USB debugging" di HP. Cek: `flutter devices` (HP harus muncul).

### C. Siapkan Firebase (sekali saja)
1. console.firebase.google.com → **Add project**.
2. **Authentication → Sign-in method** → aktifkan **Email/Password** (jangan aktifkan Anonymous).
   *Settings → Password policy*: min 10 karakter.
3. **Realtime Database → Create database** → pilih **locked mode**.
4. Tab **Rules** → hapus isi lama → tempel seluruh isi `database.rules.json` → **Publish**.
5. ⚙ Project settings → General → salin **Web API Key**.
6. Salin **URL database** dari tab Data (mis. `https://xxx-default-rtdb.asia-southeast1.firebasedatabase.app`), **tanpa `/` di akhir**.

### D. Siapkan proyek (sekali saja)
Buka folder `OrynthApps` di VS Code, buka terminal, lalu:
- **Windows (PowerShell):** `.\setup.ps1`  (jika diblokir: `Set-ExecutionPolicy -Scope Process Bypass` dulu)
- **macOS/Linux/Git Bash:** `bash setup.sh`

Script ini otomatis: membuat folder `android/`, menerapkan hardening native (Manifest + INTERNET, network security
config, Kotlin MainActivity), menaikkan minSdk ke 23, dan menjalankan `flutter pub get`.

### E. Jalankan
1. Edit `.vscode/launch.json`: ganti `ISI_API_KEY_KAMU` dan `PROJECT_ID-default-rtdb.firebaseio.com` dengan milikmu.
2. Pilih HP-mu di pojok kanan bawah VS Code, tekan **F5** (Run → "orynth_apps (debug)").
   Atau via terminal:
   ```bash
   flutter run --dart-define=FIREBASE_API_KEY=KEY_KAMU --dart-define=FIREBASE_DB_URL=https://URL_KAMU
   ```
3. Di app: **Daftar** → cek inbox/**spam** → klik tautan verifikasi → **Masuk** → buat, ubah, sematkan, hapus catatan.

### F. Pasang versi release (APK mandiri, kontrol keamanan penuh aktif)
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=FIREBASE_API_KEY=KEY_KAMU --dart-define=FIREBASE_DB_URL=https://URL_KAMU
flutter install
```
APK ada di `build/app/outputs/flutter-apk/app-release.apk`. Di build release: screenshot diblokir, HP root diblokir.
Jika HP-mu root dan ingin tetap mencoba: tambahkan `--dart-define=ALLOW_ROOTED=true`.

### Troubleshooting
| Masalah | Solusi |
|---|---|
| Layar "Konfigurasi belum diisi" | `--dart-define` belum diisi / URL berakhiran `/` |
| "Akses ditolak" | Email belum diverifikasi, atau Rules belum di-Publish |
| Email verifikasi tidak datang | Cek folder spam; coba login lagi (app mengirim ulang) |
| Error `minSdkVersion` | Jalankan ulang setup script, atau set `minSdk = 23` di `android/app/build.gradle(.kts)` |
| HP tidak terdeteksi | Ganti kabel USB (harus data), pilih mode *File transfer*, cek `adb devices` |
| Build gagal soal Gradle/Kotlin | `flutter upgrade`, lalu `flutter clean && flutter pub get` |

## Keamanan
Detail lengkap: `docs/SECURITY_CHECKLIST.md` (klasifikasi data, threat model STRIDE, pemetaan MASVS, persiapan pentest).

**Aplikasi:** HTTPS-only • token di Keystore/Keychain • verifikasi email • password policy • lockout • pesan error generik •
validasi & sanitasi input • parsing defensif • tanpa secret di source • obfuscation rilis • `allowBackup=false` •
**baru:** FLAG_SECURE (anti screenshot, release) • deteksi root & debugger (native Kotlin) • auto-logout 5 menit di background •
lockfile dependency di-commit • unit test keamanan (`flutter test`) • CI: analyze + Gitleaks + OSV-Scanner.

**Database:** default deny • hanya pemilik terverifikasi (`auth.uid === $uid` + `email_verified`) • skema & tipe divalidasi,
field asing ditolak • NoSQL (tanpa SQL injection).

**Batasan jujur:** tidak ada app yang 100% bebas celah. Belum ada certificate pinning, Play Integrity/App Check, dan deteksi
root bisa dilewati oleh penyerang berpengalaman. Aktifkan **Firebase App Check** & batasi API key di Google Cloud Console.
Proyek ini belum pernah saya jalankan di perangkat (tidak ada Flutter SDK di lingkungan saya) — jalankan `flutter test`
dan `flutter analyze` sebagai verifikasi pertama.
