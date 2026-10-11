# Neko Nightfall — audit dan rencana eksekusi

Target Godot 4.5.1; Compatibility renderer; build hanya melalui GitHub Actions. Plan sumber lengkap tetap `NEKO_NIGHTFALL_FULL_IMPLEMENTATION_PLAN.md`.

## Audit awal

- Entry scene tunggal: `scenes/main.tscn`; perilaku game/distrik berada di `scripts/game.gd`.
- Player `CharacterBody3D`, kamera SpringArm, pistol raycast, health/ammo signals, pickup Area3D, model visual, dan input sentuh sudah ada; pertahankan dan perluas, jangan membuat controller atau pistol kedua.
- AI zombie saat audit hanya mengejar target tanpa LOS/state; pickup dikumpulkan otomatis; reload langsung; belum ada interaksi, inventaris, teka-teki, checkpoint/save, atau pause.
- Dunia memanggil generator distrik besar pada startup dan banyak objek dibuat per sesi; belum ada quality toggle.
- `anime-model.glb` adalah geometri berwarna statis tanpa UV, skeleton, skinning, atau klip. Workflow rigging sudah disiapkan pada perubahan sebelumnya, tetapi belum pernah dijalankan; karakter akhir belum terverifikasi.
- Input Map punya gerak/tembak/reload/interact tetapi belum `pause`, `inventory`, atau `heal`. Teks HUD masih Inggris. Belum ada aset audio.
- Preset Web, Android, Windows tersedia. `pages.yml` deploy Pages, `web.yml` hanya artifact; workflow validasi dan generator terpisah. Belum ada hasil run/preview yang bisa diverifikasi dalam sesi ini.
- Plan merujuk `reference/neko_reference.png`, tetapi file itu tidak ada di repository; preview konsep bukan aset runtime.

## Rencana berurutan

1. **Vertical slice:** pertahankan player/pistol/HUD; kecilkan area aktif menjadi gang dan minimarket, satu infected, fuse, panel, pintu keluar, checkpoint; seluruh target memakai interface interaksi yang sama.
2. **Karakter/combat:** pakai hanya `anime-model.glb`; guard reload/fire, jeda reload, invulnerability singkat, dan notifikasi suara tembakan telah diimplementasikan. Animasi rig tetap bergantung pada Actions dan belum diuji.
3. **AI:** status idle, investigasi suara, pengejaran dengan LOS, serang, dan mati telah ditambahkan tanpa navigasi berat. Patroli waypoint dan stagger khusus masih belum dibuat.
4. **Inventaris/puzzle/save:** slot item sederhana, medkit/amunisi/fuse, fuse-panel, pintu terkunci, save checkpoint serializable di `user://` dengan versi dan validasi.
5. **Atmosfer/UI:** HUD/prompt Indonesia, inventaris, pause, dan kontrol sentuh interaksi/heal/menu telah ditambahkan. Hujan, ambience/audio, pengaturan kualitas grafis, tutorial singkat, dan pengujian UI perangkat masih belum tersedia.
6. **Optimasi/CI:** slice kecil menggantikan distrik besar pada startup; tes gameplay headless ditambahkan ke workflow validate dan Pages. Import/startup/export Web dan artifact tetap menunggu Actions; Android/Windows dan profiling perangkat belum dilakukan.

## Kriteria verifikasi

- Pemeriksaan statis di workspace: rujukan path, struktur model, YAML/Python, `git diff --check`.
- GitHub Actions: Godot 4.5.1 import, tes gameplay headless, startup, ekspor Web, artifact log; rigging memiliki workflow terpisah.
- Pemeriksaan visual belum bisa dilakukan di runner headless. Jangan sebut preview berhasil sampai Pages deployment aktual diverifikasi.

## Status

- [x] Audit struktur dan spesifikasi lengkap.
- [x] Implementasi kode vertical slice dan sistem dasar (belum diuji di Godot).
- [ ] Tes headless/ekspor oleh GitHub Actions.
- [ ] Pemeriksaan visual Web Preview.
- [ ] Audit performa pada perangkat target.

Dokumen ini mencatat status implementasi, bukan klaim bahwa checklist penerimaan penuh sudah lulus.
