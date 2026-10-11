# Neko Nightfall — GitHub Actions Character Studio

## Tujuan
Project ini disiapkan untuk PC spesifikasi rendah: GitHub Actions menyediakan runner build, lalu GitHub Pages menampilkan model karakter 3D di browser.

## Cara deploy
1. Ekstrak ZIP.
2. Buka folder `godot-projectV0`.
3. Upload **isi folder tersebut** ke root repository GitHub (jangan menaruh `.github` satu tingkat terlalu dalam).
4. Pastikan workflow `.github/workflows/character-studio-pages.yml` ikut ter-upload.
5. Di repository, buka **Settings → Pages → Build and deployment → Source → GitHub Actions**.
6. Push ke branch `main` atau buka **Actions → Neko Character Studio Pages → Run workflow**.
7. Setelah workflow sukses, buka URL Pages yang diberikan GitHub. Halaman ini menampilkan browser character studio.

## Kontrol di Pages
- Drag mouse untuk memutar model; scroll untuk zoom.
- Pilih klip animasi jika model berisi klip.
- Atur tint, roughness, metalness, lighting, exposure, dan skala.
- `Simpan preset JSON` menyimpan pengaturan tampilan yang bisa dipakai sebagai referensi.

## Batasan yang penting
- Pages viewer adalah **preview/poles tampilan material dan lighting**, bukan editor sculpting 3D dan tidak mengubah file GLB secara permanen.
- Tombol simpan mengekspor preset JSON, bukan model GLB yang sudah dimodifikasi.
- Viewer memakai Three.js dari jsDelivr CDN, sehingga browser perlu koneksi internet.
- Workflow ini menerbitkan Character Studio di root Pages. Workflow Pages Godot lama dinonaktifkan sebagai `pages-game-export.disabled` supaya tidak bersaing dengan Character Studio. `web.yml` masih bisa menghasilkan artifact game web terpisah melalui Actions.
- Model karakter yang disertakan adalah model dasar dari project. Preview tidak menjamin kualitas karakter setara produksi AAA; geometri, rig, dan animasi harus diverifikasi dalam Godot/browser.

## Project Godot
File Godot, scene, gameplay, aset, dan preset ekspor tetap disertakan. Workflow ini fokus pada halaman Character Studio. Untuk deploy game web Godot di URL terpisah, buat workflow terpisah dan atur base path Pages dengan benar.
