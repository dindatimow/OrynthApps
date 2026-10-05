# Dokumen Keamanan — OrynthApps
Disusun berdasarkan prinsip *Mobile Application Security Testing* (OWASP MASTG/MASVS) dan SDLC aman.

## 1. Klasifikasi data sensitif (wajib didefinisikan sebelum pentest)
| Data | Tingkat | At rest | In use | In transit |
|---|---|---|---|---|
| Email, password | Sensitif | Password tidak pernah disimpan; email di Keystore (encrypted prefs) | Controller dibuang saat `dispose` | TLS 1.2+ ke Google |
| Refresh token / ID token | Sangat sensitif | Keystore/Keychain; ID token hanya di memori | Auto-refresh, dihapus saat logout | HTTPS, query `auth` ke RTDB |
| Isi catatan | Sensitif (privat user) | Firebase RTDB (terenkripsi at-rest oleh Google), tidak di-cache lokal | Hanya di state widget | HTTPS |
| Warna latar | Tidak sensitif | RTDB `settings` | — | HTTPS |

## 2. Threat model ringkas (STRIDE)
| Ancaman | Mitigasi |
|---|---|
| Spoofing: tebak/ambil alih akun | Email terverifikasi, password policy, lockout, pesan error generik |
| Tampering: ubah data user lain (IDOR) | Rules: `auth.uid === $uid` + `email_verified` |
| Tampering: payload aneh/field liar | Rules `.validate` + `$other: false`, sanitasi klien |
| Repudiation | Log audit Firebase Auth (console) |
| Information disclosure: sadap jaringan / backup / screenshot | HTTPS-only, `allowBackup=false`, `FLAG_SECURE` (release), secure storage |
| DoS / spam | Rate-limit Firebase Auth; disarankan Firebase App Check |
| Elevation: perangkat root/debugger | Deteksi root & debugger (release) memblokir app |
| Sesi tertinggal | Auto-logout setelah 5 menit di background; logout menghapus semua secure storage |

## 3. Pemetaan MASVS
| Area | Status |
|---|---|
| STORAGE | Secure storage; tanpa data sensitif di log; backup dimatikan; FLAG_SECURE |
| CRYPTO | Tidak ada kripto buatan sendiri (memakai Keystore & TLS platform) |
| AUTH | Verifikasi email, password policy, lockout, auto-lock, refresh token |
| NETWORK | HTTPS-only (kode + network security config). Certificate pinning: *belum* (risiko rotasi sertifikat Google) |
| PLATFORM | Activity tunggal exported hanya untuk launcher; tanpa WebView/JS bridge |
| CODE | Input validation, defensive parsing, dependency lockfile, CI SAST + secret scan + dependency scan |
| RESILIENCE | Deteksi root/debugger, obfuscation rilis. Belum: anti-tampering/integrity check (Play Integrity / App Check) |

## 4. Persiapan untuk pentester
- **Scope:** app Android (APK), Firebase Auth REST, Realtime Database Rules. Di luar scope: infrastruktur Google.
- **Dua build** (sesuai praktik terbaik): *release* (kontrol aktif) dan *debug* (screenshot boleh; root check hanya peringatan):
  ```bash
  flutter build apk --release --obfuscate --split-debug-info=build/symbols --dart-define=...
  flutter build apk --debug --dart-define=...
  ```
  Untuk menguji di perangkat root: tambahkan `--dart-define=ALLOW_ROOTED=true`.
- **Berikan** source code (white-box lebih efisien), `database.rules.json`, dan 2 akun uji terverifikasi (untuk uji IDOR antar-user).
- **Prioritas temuan:** gunakan DREAD (Damage, Reproducibility, Exploitability, Affected users, Discoverability).
- **Wajib izin tertulis** sebelum pengujian pada project Firebase milik orang lain.

## 5. Pengujian otomatis (CI)
`.github/workflows/security.yml`: `flutter analyze` (SAST), `flutter test` (security unit test), Gitleaks (secret scan), OSV-Scanner (dependency).
Uji manual disarankan: coba baca `users/<uid-lain>` dengan token user A → harus `Permission denied`.
