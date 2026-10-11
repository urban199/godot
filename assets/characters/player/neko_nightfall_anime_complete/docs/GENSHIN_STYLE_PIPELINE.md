# Pipeline Karakter Anime Stylized Neko Nightfall

## Otomatisasi yang tersedia

Workflow `.github/workflows/generate-character.yml` menjalankan Blender di GitHub Actions ketika workflow/generator berubah atau saat dijalankan manual. Workflow akan:

1. Menghasilkan mesh karakter, armature, skinning, material PBR, dan delapan action animasi.
2. Menyalin GLB hasil sementara ke `assets/characters/player/neko_nightfall_anime_complete/models/neko_nightfall_genshin_style.glb` pada runner.
3. Mengimpor project dengan Godot 4.5.1 dan menjalankan `scripts/ci/validate_character.gd` terhadap model hasil tersebut.
4. Setelah validasi lulus, membuat commit GLB baru pada branch yang memicu workflow.
5. Mengunggah GLB dan log sebagai artifact `neko-nightfall-genshin-style-<commit>`.

GLB akan otomatis tersimpan pada path model di repository melalui commit bot setelah workflow sukses. Workflow diberi izin `contents: write`; pengaturan repository harus mengizinkan GitHub Actions menulis ke repository. `scripts/humanoid_visual.gd` otomatis memilih model baru; jika belum ada, game tetap memakai model aktif yang lama. Artifact tetap tersedia untuk pemeriksaan atau pemulihan manual.

`assets/characters/neko/neko_nightfall_baseline.glb` dari pack adalah duplikat byte-identik dari sumber lama `neko_nightfall_character_full`; file itu bukan model baru dan tidak perlu disimpan lagi. Generator Blender menghasilkan model berbeda. Outputnya prototipe anime stylized, bukan model produksi yang identik dengan Genshin.

## Integrasi dan pemeriksaan

1. Sistem `project.godot`, player scene/controller, camera, weapon logic, dan Input Map yang sudah ada tetap digunakan.
2. Workflow menguji GLB melalui `GLTFDocument`, lalu memeriksa skeleton, skinning, UV, material, delapan klip, serta pemasangan pada player dan socket senjata.
3. Rig generator menamai tangan kanan `hand.R`; kode socket menerima variasi nama itu maupun `Hand_R` dari model lama.
4. Skala, orientasi hadap, posisi kaki, deformasi, dan pose reload tetap perlu diperiksa pada Web Preview karena runner headless tidak memvalidasi kualitas visual.
5. Jangan menyatakan integrasi visual selesai sebelum artifact dimasukkan ke project, workflow lulus, dan preview diperiksa.
