# PROJECT BLACK RAIN

Prototipe survival horror first-person 3D untuk Godot 4.5.1, memakai renderer Compatibility agar sesuai sasaran desktop, web, dan Android.

## Menjalankan

1. Buka folder proyek ini di Godot 4.5.1.
2. Tekan **Run Project**.
3. Pilih **New Game** di menu.

Kontrol desktop: WASD, Shift untuk lari, Ctrl untuk jongkok, mouse untuk melihat, F untuk senter, E untuk interaksi/keluar dari tempat persembunyian, I untuk inventaris, M untuk peta, dan Esc untuk jeda.

Kontrol layar sentuh dibuat saat game berjalan pada Android: joystick gerak virtual, lari, jongkok, interaksi, dan senter. Geser layar untuk melihat.

## Alur prototipe

Ambil kartu akses di area masuk, buka pintu layanan, cari terminal dan catatan penelitian, aktifkan generator di ruang servis, lalu buka pintu keluar. Monster berpatroli, mendengar suara langkah/lari, menyelidiki, mengejar, menyerang, dan mencari kembali setelah kehilangan jejak.

Progres disimpan pada checkpoint yang dapat digunakan kembali dan saat perubahan objektif penting ke `user://game_state.json`. Pengaturan kontrol, audio, grafis, dan hujan disimpan terpisah ke `user://player_settings.json`.

Status implementasi dan pekerjaan tersisa tercatat di [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md).

## Ekspor

Preset Web, Windows Desktop, dan Android APK tersedia di `export_presets.cfg`. Ekspor Android memerlukan export templates Godot, Android SDK, JDK, dan pengaturan signing untuk rilis.

Workflow `.github/workflows/export.yml` hanya berjalan lewat **Actions → Validate and export → Run workflow**. Workflow tidak berjalan otomatis ketika commit atau push. Web dan Windows dapat dipilih; Android tetap diekspor dari mesin yang sudah dikonfigurasi dengan Android SDK.

Folder `build/` hanya menjadi lokasi keluaran ekspor dan tidak berisi build yang dibuat dalam perubahan ini.
