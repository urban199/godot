# PROJECT BLACK RAIN

PROJECT BLACK RAIN adalah survival horror orang pertama. Versi Web memakai Three.js dan sebuah level 3D yang ditata secara eksplisit; versi native Windows dan Android tetap memakai prototipe Godot 4.5.1.

## Menjalankan

**Web:** sajikan isi folder `web/` melalui static web server lalu buka `index.html`. Three.js dimuat dari jsDelivr, jadi koneksi internet diperlukan.

**Windows/Android:** buka folder proyek ini di Godot 4.5.1, tekan **Run Project**, lalu pilih **New Game**.

Kontrol desktop: WASD, Shift untuk lari, Ctrl untuk jongkok, mouse untuk melihat, F untuk senter, E untuk interaksi/keluar dari tempat persembunyian, I untuk inventaris, M untuk peta, dan Esc untuk jeda.

Kontrol layar sentuh dibuat saat game berjalan pada Android: joystick gerak virtual, lari, jongkok, interaksi, dan senter. Geser layar untuk melihat.

## Alur permainan Web

Level Three.js mencakup distrik kota dengan 36 bangunan bernama, jalan ber-grid, landmark, lampu jalan, dan kendaraan, lalu jalan hutan dan fasilitas penelitian. Posisi blok dan landmark ditetapkan di kode. Ikuti sinyal ke fasilitas, ambil kartu akses, periksa terminal dan catatan, pulihkan daya, lalu capai pintu servis keluar. Stalker berpatroli, menyelidiki suara gerak, mengejar, menyerang, dan mencari posisi terakhir pemain. Senter, baterai, medkit, tempat bersembunyi, hujan, kilat, menu pengaturan, kontrol sentuh, dan save browser tersedia.

Progress Web disimpan ke browser `localStorage` pada checkpoint dan perubahan penting. Pengaturan grafis, hujan, sensitivitas, dan volume juga disimpan di browser.

Kontrol Web: WASD, mouse, Shift, Ctrl, F, E, I, M, Esc. Pada layar sentuh gunakan joystick kiri, swipe kanan/kiri untuk memutar kamera, dan tombol aksi. Game meminta fullscreen dan landscape saat dimulai jika browser mendukungnya; layar portrait menampilkan petunjuk untuk memutar perangkat.

## Ekspor

Preset Windows Desktop dan Android APK tersedia di `export_presets.cfg`. Runner CI menyiapkan Godot, Android SDK, dan JDK secara terpisah. APK otomatis mengikuti preset unsigned; signing perlu dikonfigurasi sebelum distribusi rilis.

Workflow `.github/workflows/export.yml` menyiapkan situs Three.js dan menerbitkannya ke GitHub Pages otomatis saat ada push ke branch default. Windows serta Android diekspor paralel dan tersedia sebagai artifact di tab **Actions**. Untuk publikasi pertama, aktifkan **Settings → Pages → Source: GitHub Actions** pada repository.

