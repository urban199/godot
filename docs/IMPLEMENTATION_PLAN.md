# PROJECT BLACK RAIN — plan pelaksanaan dan status

Rencana ini mencatat pekerjaan kode yang sudah disiapkan dalam proyek. Permintaan kerja membatasi verifikasi pada pemeriksaan statis dan mengecualikan build serta push.

## 1. Fondasi dan lingkungan — prototipe selesai

- Versi Web Three.js memakai `web/index.html`, `web/game.js`, dan `web/style.css`; distrik kota mempunyai 36 bangunan bernama, persimpangan, kendaraan, lampu jalan, landmark, serta jalan ke hutan dan fasilitas.
- Posisi kota ditulis eksplisit. Web merender geometri 3D first-person, fasad dan jendela, material, fog, pencahayaan, senter, hujan, dan kilat. Tidak ada tata letak kota acak saat permainan berjalan.
- Versi native Windows/Android tetap proyek Godot 4.5.1 yang memakai `scripts/world/world_builder.gd`.

## 2. Gerak dan interaksi — kode selesai

- Kontrol sudut pandang pertama, berjalan, berlari, jongkok dengan pemeriksaan ruang kepala, senter dan baterai.
- Raycast interaksi kontekstual, keyboard/mouse, joystick gerak, swipe horizontal untuk melihat, serta tombol sentuh. Saat permainan dimulai, browser diminta masuk fullscreen dan landscape jika mendukung.
- Tempat bersembunyi yang mematikan gerak, senter, deteksi, serta serangan sampai pemain keluar dengan tombol interaksi.

## 3. Skenario dan AI — kode selesai

- Kartu akses, catatan penelitian, terminal, generator, pintu layanan dan pintu keluar, medkit, baterai, serta alur objektif.
- AI Stalker dengan patroli, deteksi kerucut pandang dan garis pandang, pendengaran langkah, investigasi, kejar, serang, dan pencarian.
- Graf rute A* berisi waypoint untuk koridor dan cabang ruangan; AI menggunakannya untuk memilih titik gerak berikut.
- Pemicu kejadian horor laboratorium, lampu berkedip, dan audio stinger prosedural.

## 4. UI dan penyimpanan — kode selesai

- Menu awal/jeda, pengaturan, HUD, inventaris dengan kapasitas, peta progresif, status kesehatan, dan pesan interaksi.
- Penyimpanan JSON untuk posisi, kesehatan, baterai, inventaris, objektif, area peta, pickup, pintu, dan kejadian dunia.
- Checkpoint yang dapat digunakan kembali di ruang servis dan laboratorium; tombol coba lagi memuat penyimpanan terbaru.
- Pengaturan sensitivitas, audio, kualitas grafis, intensitas efek, jarak pandang, dan kepadatan hujan.

## 5. Audio dan presentasi — kode prototipe

- Web memakai ambience audio sintetis melalui Web Audio dan efek guntur; tidak memakai rekaman eksternal.
- Geometri dibuat dari mesh Three.js tanpa model, tekstur, decal, atau animasi karakter produksi. Tampilan adalah level blockout 3D yang ditata eksplisit, belum aset semi-realistis final.

## 6. Ekspor — konfigurasi disiapkan

- Workflow CI mengemas folder Three.js `web/` sebagai situs statis, mengekspor Windows dan Android dari Godot, lalu mengunggah artifact saat push atau pemicu manual.
- Workflow menerbitkan artifact Web ke GitHub Pages dari branch default; repository perlu memilih GitHub Actions sebagai Pages source.
- Tidak menjalankan build, ekspor, atau workflow.

## Pekerjaan yang tersisa di luar perubahan kode ini

1. Impor model, tekstur, decal, animasi, dan audio final untuk mengganti geometri placeholder.
2. Uji pengalaman browser dan kompatibilitas touch pada desktop/mobile setelah artifact di-host.
3. Samakan kelengkapan gameplay antara Web Three.js dengan build native Godot jika keduanya menjadi target rilis.
4. Signing Android rilis dan distribusi APK perlu kunci rilis yang dikonfigurasi.

## Pemeriksaan dalam sesi ini

- Verifikasi hanya statis; engine, build, ekspor, workflow CI, dan permainan tidak dijalankan.
