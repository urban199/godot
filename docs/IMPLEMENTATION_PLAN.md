# PROJECT BLACK RAIN — plan pelaksanaan dan status

Rencana ini mencatat pekerjaan kode yang sudah disiapkan dalam proyek. Permintaan kerja membatasi verifikasi pada pemeriksaan statis dan mengecualikan build serta push.

## 1. Fondasi proyek — kode selesai

- Proyek Godot 4.5, renderer Compatibility, scene utama, input desktop, dan konfigurasi ekspor Web, Windows, serta Android.
- Lingkungan 3D prosedural berisi hutan, area masuk, administrasi, koridor, ruang servis, laboratorium, hujan, kabut, kilat, material, dan properti.
- Batang dan kanopi pohon memakai `MultiMesh`; collider tetap tersedia per pohon.

## 2. Gerak dan interaksi — kode selesai

- Kontrol sudut pandang pertama, berjalan, berlari, jongkok dengan pemeriksaan ruang kepala, senter dan baterai.
- Raycast interaksi kontekstual, input keyboard/mouse, joystick gerak dan kontrol aksi sentuh, serta sensitivitas tersimpan.
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

## 5. Audio dan presentasi — kode selesai pada tingkat prototipe

- Hujan, langkah, guntur, dan stinger ancaman dibangkitkan dari kode; lampu ruang dan efek cuaca dibuat saat runtime.
- Geometri, material, dan properti masih berupa aset prosedural/blockout. Audio rekaman, model, tekstur, decal, animasi produksi, serta set modular final belum diimpor.

## 6. Ekspor — konfigurasi kode selesai

- Preset Web, Windows, dan Android tersedia. Workflow CI ekspor hanya manual dan bukan bagian yang dijalankan untuk tugas ini.
- Tidak ada artefak build yang dihasilkan.

## Pekerjaan yang tersisa di luar perubahan kode ini

1. Impor atau ganti aset prosedural dengan model, tekstur, decal, animasi, dan audio final.
2. Jalankan impor/validasi engine dan build ekspor pada mesin dengan Godot serta export templates yang sesuai.
3. Uji kontrol, renderer, penyimpanan browser, performa, dan perangkat desktop/Android secara langsung; atur signing Android jika merilis APK.
4. Push repository dilakukan oleh pemilik proyek.

## Pemeriksaan dalam sesi ini

- Pemeriksaan statis referensi `res://`, deklarasi input, autoload, serta konfigurasi workflow dan preset.
- Tidak menjalankan engine, build, ekspor, workflow CI, atau pengujian runtime.
