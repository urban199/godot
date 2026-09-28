# Neko Nightfall — Game Development Plan

## Tujuan dokumen

Dokumen ini menjadi roadmap kerja untuk game yang ada sekarang; roadmap IDE lama tetap disimpan sebagai catatan dan tidak menjadi target saat ini. Alur kerjanya sederhana: saya membantu merencanakan dan mengubah project, perubahan ditinjau di repository, lalu pemilik project melakukan push manual. GitHub Pages tetap menjadi preview game.

Targetnya adalah survival horror 3D yang lebih luas dan menarik, dengan eksplorasi, suasana tegang, pengelolaan amunisi, teka-teki, dan progres area. Game boleh mengambil inspirasi dari genre survival horror seperti Resident Evil, tetapi karakter, cerita, lokasi, desain, logo, dan aset harus orisinal.

## Kondisi project sekarang

- Project Godot 4.5.1 dengan GDScript dan renderer Compatibility.
- Game 3D Neko Nightfall, berlatar distrik kota malam hari.
- Ada gerak, sprint, lompat, menembak, reload, flashlight, beberapa zombie, pickup, dan pintu keluar.
- Web export dan GitHub Pages sudah digunakan sebagai preview.
- Kota dibangun dari kombinasi geometri prosedural dan aset Kenney City Kit Suburban.
- Script visual karakter saat ini membentuk manusia secara prosedural. Model survivor dan beberapa model/animasi zombie yang sudah ada di `assets/` belum menjadi karakter aktif.
- Workflow Web, Android, Windows, dan validasi tersedia; keberadaan workflow tidak berarti setiap target sudah teruji pada setiap perubahan.

## Arah desain

Bangun pengalaman melalui area yang saling terhubung, bukan memperbesar peta kosong. Pemain menjelajahi distrik karantina, menemukan jalur masuk ke bangunan penting, mengumpulkan perlengkapan, membuka jalan pintas, dan memutuskan kapan harus menghadapi atau menghindari musuh.

Prinsip permainan:

1. Eksplorasi memberi alasan untuk kembali ke area yang sudah dikenal.
2. Amunisi dan pemulihan terbatas, tetapi pemain selalu punya pilihan selain bertarung.
3. Petunjuk lingkungan dan dokumen memberi konteks cerita serta arah teka-teki.
4. Setiap area memiliki siluet, pencahayaan, landmark, dan ancaman yang mudah dibedakan.
5. Fitur baru dibuat sebagai potongan kecil yang dapat dimainkan dan dipreview sebelum area berikutnya ditambahkan.

## Prioritas aset

Gunakan aset yang sudah ada sebelum menambah unduhan baru. Aset yang masuk ke game perlu dipilih dan diintegrasikan; menyimpan satu paket lengkap dalam repository tidak otomatis membuatnya tampil di game.

| Kebutuhan | Aset yang tersedia / arah | Tujuan |
|---|---|---|
| Kota dan jalan | Kenney City Kit Suburban yang sudah ada | Pertahankan blok kota, tambah variasi dan landmark yang mendukung navigasi |
| Penyintas | Kenney Blocky `character-a.glb` di paket yang sudah ada | Ganti placeholder prosedural setelah skala dan animasinya diperiksa; lisensi CC0 tercatat |
| Zombie | Kenney Blocky `character-b.glb` atau model Kenney Retro yang ada di `assets/characters/retro/` | Buat siluet musuh yang berbeda; pakai animasi idle/run yang sesuai rig; hindari salinan duplikat `creature.glb` |
| Props survival | Paket props yang sudah ada; tambahkan item seperti kotak P3K, amunisi, kunci, sekering, dokumen, dan generator | Memberi fungsi gameplay pada ruang dan eksplorasi |
| Area indoor | Prioritaskan aset modular interior yang satu gaya dengan kota | Bangun klinik atau pos evakuasi kecil sebagai area eksplorasi pertama |
| Audio | Tambahkan ambience malam, langkah kaki, pintu, senjata, dan suara ancaman secara bertahap | Membentuk suasana dan memberi informasi gameplay |

Sebelum menggunakan aset baru, catat nama paket, URL sumber, format, lisensi, dan atribusi yang diminta di `ASSET_SOURCES.md`. Kenney City Kit Suburban dan paket City Kit Industrial/Roads serta Survival Kit menyatakan lisensi CC0 di halaman resminya: [Suburban](https://kenney.nl/assets/city-kit-suburban), [Industrial](https://kenney.nl/assets/city-kit-industrial), [Roads](https://kenney.nl/assets/city-kit-roads), [Survival Kit](https://kenney.nl/assets/survival-kit). Tetap simpan berkas lisensi yang menyertai unduhan. Audit hash menunjukkan `survivor.glb` dan `creature.glb` adalah salinan byte-identik `character-a.glb` dan `character-b.glb` dari paket Kenney Blocky Characters; gunakan berkas sumber dalam paket berlisensi CC0 tersebut, bukan salinan duplikatnya.

### Aturan penambahan aset ke GitHub

- Masukkan aset runtime yang benar-benar dipakai game; jangan menambahkan duplikat FBX, OBJ, dan GLB bila hanya satu format yang diperlukan.
- Utamakan GLB untuk model Godot dan tekstur yang sudah dikemas/dioptimalkan. Simpan file sumber besar hanya bila memang diperlukan untuk proses impor atau pengeditan ulang.
- Hindari file preview, arsip paket, executable, cache import, dan file sementara dalam folder runtime.
- Pertahankan struktur aset yang jelas, misalnya `assets/environment/`, `assets/characters/`, `assets/props/`, `assets/audio/`, dan `assets/ui/`.
- Untuk setiap impor baru, cek skala, orientasi, material, collision, animasi, ukuran file, dan tampilan pada renderer Compatibility.
- Jangan menghapus atau mengganti aset yang sudah ada sebelum referensi scene/script dan lisensinya diperiksa.

## Roadmap implementasi

### Tahap 1 — Art pass karakter dan kontrol

- Integrasikan model penyintas ke scene karakter, dengan prosedural visual sebagai fallback selama migrasi.
- Integrasikan satu model zombie dan animasi dasar yang tersedia.
- Rapikan ukuran collision capsule agar sesuai dengan kaki model.
- Tentukan kamera over-the-shoulder yang konsisten, termasuk kontrol sentuh dan desktop.
- Tambahkan animasi dasar untuk diam, jalan/lari, serangan, terkena damage, dan mati sesuai ketersediaan rig.
- Pastikan HUD, tombol, dan kamera tidak menutupi area penting pada layar ponsel.

**Selesai jika:** penyintas dan zombie terlihat sebagai model final sementara, bergerak tanpa menembus lantai, dan kontrol tetap dapat dipakai di Web serta layar sentuh.

### Tahap 2 — Vertical slice area pertama

Buat satu segmen pendek yang utuh:

`jalan kota → pos evakuasi/klinik → ruang utilitas → pintu keluar yang terkunci → jalur pintas terbuka`

- Ubah sebagian bangunan menjadi interior yang dapat dimasuki, bukan hanya dekorasi luar.
- Tambahkan pintu, kunci, sekering/generator, pickup, dokumen, serta landmark visual.
- Susun pencahayaan dan blocking agar rute terbaca tanpa membuat semua ruang terang.
- Ganti kondisi menang saat menyentuh pintu dengan tujuan yang memerlukan eksplorasi dan satu teka-teki sederhana.

**Selesai jika:** pemain bisa menyelesaikan segmen, menemukan item kunci, memahami petunjuk, membuka jalur, dan mencapai tujuan tanpa terjebak.

### Tahap 3 — Sistem survival horror inti

- Buat inventory terbatas dengan pemilihan item dan penggunaan item.
- Bedakan amunisi yang dibawa, amunisi cadangan, dan item pemulihan.
- Tambahkan interaksi kontekstual untuk pintu, item, dokumen, dan objek teka-teki.
- Buat pickup hanya bisa dikumpulkan jika kondisi pemain memungkinkan; tampilkan pesan saat inventory penuh.
- Tambahkan save point/checkpoint sederhana setelah alur dasar stabil.
- Pastikan kematian, restart, dan checkpoint tidak menggandakan musuh atau item.

**Selesai jika:** pemain harus memilih penggunaan resource dan progres utama tetap tersimpan sesuai aturan checkpoint.

### Tahap 4 — Perluasan distrik dan variasi ancaman

- Tambahkan area kedua yang berbeda secara visual dan mekanis, misalnya gang servis atau stasiun bawah tanah.
- Gunakan jalur pintas untuk menghubungkan area baru dengan area lama.
- Tambahkan satu varian musuh dengan pola yang berbeda sebelum memperbanyak jumlah musuh.
- Rencanakan encounter dengan ruang untuk menghindar, berlindung, atau mundur.
- Tambahkan puzzle kedua yang menggunakan petunjuk lingkungan, bukan sekadar mencari tombol.

**Selesai jika:** area baru memberi pilihan rute dan tekanan baru, bukan hanya memperbesar jarak tempuh.

### Tahap 5 — Audio, UI, dan penyelesaian

- Tambahkan ambience per area, langkah kaki, suara pintu, reload, tembakan, damage, dan cue ancaman.
- Buat menu awal, pause, pengaturan volume, objective, inventory, dan layar akhir.
- Tambahkan opsi sensitivitas kamera dan ukuran kontrol sentuh.
- Optimalkan jumlah lampu, bayangan, geometri, tekstur, dan ukuran unduhan untuk Web/mobile.
- Periksa lisensi dan ukuran seluruh aset/audio sebelum masuk ke branch utama.

**Selesai jika:** pemain mendapat umpan balik yang jelas dan game tetap berjalan lancar pada perangkat sasaran.

## Cara kerja per perubahan

1. Kerjakan satu tujuan kecil pada satu waktu, seperti “integrasikan model penyintas” atau “buat pintu berkunci”.
2. Saya akan memeriksa file dan dependensi yang relevan, lalu mengubah project sesuai tujuan itu.
3. Tinjau perubahan dan jalankan validasi/preview yang tersedia sebelum menggabungkan pekerjaan.
4. Kelompokkan perubahan dalam commit yang menjelaskan fitur atau aset yang ditambahkan.
5. Kamu melakukan push manual; Pages menjadi preview setelah workflow deploy selesai.
6. Jika preview gagal, gunakan log Actions dan commit terkait untuk mencari regresi sebelum menambah fitur baru.

Jangan menumpuk banyak paket aset dan fitur gameplay dalam satu perubahan. Perubahan kecil memudahkan pemeriksaan ukuran, lisensi, kompatibilitas renderer, dan sumber error.

## Kriteria rilis vertical slice

- Game bisa dijalankan dari awal sampai akhir segmen pertama.
- Ada setidaknya satu area outdoor dan satu interior yang dapat dijelajahi.
- Pemain, zombie, pintu, pickup, objective, dan teka-teki memakai scene/script yang dapat digunakan ulang.
- Progres tidak bisa dilewati hanya dengan berjalan ke pintu keluar.
- Kontrol desktop dan sentuh bekerja; HUD tetap terbaca pada orientasi landscape.
- Web export tampil melalui GitHub Pages.
- Tidak ada referensi aset yang hilang atau error runtime yang menghalangi progres.
- Semua aset tambahan tercatat sumber dan lisensinya.
- Cerita, nama, karakter, desain musuh, peta, dan UI tetap orisinal.

## Di luar cakupan untuk sekarang

- IDE browser, Monaco, backend, OAuth, dan GitHub API.
- AI agent otomatis yang mengedit repository atau membuat commit.
- Multiplayer, dunia terbuka besar, banyak karakter playable, dan boss campaign panjang.
- Membeli atau memasukkan banyak aset sebelum vertical slice pertama terbukti menarik.

---

# Masterplan produksi: survival horror sinematik

Bagian ini memperluas roadmap ringkas di atas. Urutan ini mengutamakan game yang bisa dimainkan dan dipreview pada setiap milestone. Skala visual yang realistis untuk project ini adalah **survival horror sinematik dengan aset yang konsisten dan pencahayaan kuat**. Rasa seperti remake modern dicapai lewat kamera, tempo, ruang, animasi, audio, dan encounter. Photorealism setara produksi AAA memerlukan banyak aset khusus, animasi, audio, dan waktu produksi; itu bukan syarat untuk membuat game ini terasa tegang dan menarik.

## 1. Pilar pengalaman

### Kamera dan kontrol

- Kamera third-person over-the-shoulder menjadi target utama agar karakter dan animasinya terlihat.
- Gerak karakter memiliki bobot: akselerasi, berhenti, berputar, membidik, menembak, stagger, dan pulih.
- Saat membidik, kamera mendekat dan memberi ruang untuk membaca sasaran; saat eksplorasi, kamera menunjukkan ruang dan ancaman.
- Aim assist ringan dapat disediakan untuk sentuh; sensitivitas kamera dapat diatur.
- Kontrol desktop dan sentuh menjalankan aksi gameplay yang sama.

### Ketegangan dan resource

- Encounter dibuat agar pemain menilai jarak, jumlah peluru, jalur mundur, dan risiko sebelum menembak.
- Amunisi, healing, dan item kunci ditempatkan untuk mengatur ritme, bukan diberikan secara acak tanpa tujuan.
- Musuh perlu memberi tanda sebelum menyerang agar pemain bisa membaca ancaman dan merespons.
- Beberapa musuh dapat dihindari; tidak setiap ruang harus menjadi arena tembak.

### Eksplorasi dan progres

- Area saling terhubung dengan landmark dan jalan pintas yang terbuka dari sisi lain.
- Kunci, sekering, kode, dan petunjuk memiliki hubungan yang dapat dipahami pemain.
- Catatan dan objek lingkungan menceritakan apa yang terjadi tanpa memaksa semua cerita melalui dialog panjang.
- Tujuan utama terlihat jelas di HUD/map, sedangkan rahasia tetap opsional.

## 2. Gaya visual dan identitas

Pilih satu arah visual sebelum menambah banyak aset. Paket Kenney yang sekarang cenderung low-poly; memadukannya langsung dengan model photorealistic dapat membuat game terlihat tidak konsisten. Rencana dasar:

- Bentuk dan siluet aset tetap bergaya sederhana agar sesuai dengan paket yang sudah ada.
- Material, warna, decal, kabut, kontras cahaya, framing kamera, animasi, dan audio memberi kesan grounded dan sinematik.
- Tiap area mempunyai palet warna sendiri: biru dingin untuk jalan malam, hijau pucat untuk klinik, amber untuk ruang utilitas, dan merah sebagai tanda bahaya.
- Hindari menaruh lampu berwarna terang di semua tempat; simpan kontras tertinggi untuk petunjuk dan ancaman.
- Gunakan tekstur trim, material kotor, noda, retak, bekas terbakar, genangan, dan papan petunjuk untuk menyatukan aset modular.
- Desain logo, judul, UI, karakter, musuh, peta, cerita, dan puzzle secara orisinal. Referensi genre tidak berarti menyalin elemen khas Resident Evil.

Jika kemudian dipilih arah realistis penuh, lakukan sebagai keputusan terpisah: ganti set environment dan karakter secara menyeluruh, audit performa, ukuran unduhan, dan lisensi sebelum mulai membangun banyak level.

## 3. Peta campaign yang disarankan

Campaign awal dibuat sebagai beberapa area kompak yang terhubung, bukan satu kota luas tanpa isi.

1. **Jalan distrik karantina** — tutorial gerak, kamera, interaksi, dan satu ancaman; pemain melihat landmark klinik dan gerbang keluar.
2. **Klinik darurat** — ruang tunggu, ruang periksa, farmasi terkunci, dan ruang generator; memperkenalkan healing, dokumen, kunci, dan puzzle daya.
3. **Gang servis dan toko kecil** — jalan pintas ke jalan utama, encounter yang dapat dihindari, dan item opsional.
4. **Terowongan utilitas/stasiun bawah tanah** — navigasi lebih gelap, audio sebagai petunjuk, serta musuh dengan pola berbeda.
5. **Pos evakuasi** — payoff cerita dan encounter klimaks untuk versi pertama.

Mulai dari area 1 dan sebagian kecil area 2 sebagai vertical slice. Area lain baru dibangun setelah alur, interaksi, kamera, dan combat dasar terbukti menyenangkan.

## 4. Inventaris aset yang perlu disiapkan

### Karakter dan animasi

- Penyintas utama: model, rig humanoid, idle, walk, run, aim, shoot, reload, hit reaction, death, dan interaksi.
- Zombie standar: idle, walk/shamble, attack wind-up, attack, stagger, knockdown, dan death.
- Satu varian musuh dengan bentuk dan perilaku berbeda; jangan hanya mengganti warna material.
- Senjata utama beserta model tampak dekat, animasi reload, muzzle flash, casing, dan suara mekanis.
- Periksa apakah `survivor.glb`, model Retro, dan `creature.glb` memakai rig serta skala yang cocok sebelum memilihnya sebagai aset final.

### Environment dan props

- Modular dinding, lantai, pintu, kusen, tangga, koridor, sudut, dan variasi rusak untuk interior.
- Klinik: ranjang, meja pemeriksaan, lemari obat, tirai, lampu darurat, troli, signage, dan props medis.
- Utilitas: panel listrik, generator, kabel, valve, pipa, fuse box, serta pintu servis.
- Jalan kota: pembatas, kendaraan rusak, lampu jalan, pagar, sampah, signage, dan landmark unik.
- Gameplay props: kunci, sekering, catatan, peta, item pemulihan, amunisi, peti penyimpanan, save point, dan objek puzzle.
- Variant kondisi: bersih, rusak, kotor, mati listrik, dan terkena dampak peristiwa. Gunakan material/decal ulang sebelum menambah mesh baru.

### Material dan permukaan

- Material tileable untuk beton, aspal, bata, plester, ubin klinik, logam, kayu, kain, dan kaca.
- Map yang benar-benar dibutuhkan saja: albedo, normal, roughness, dan metallic bila sesuai.
- Trim sheet dan atlas membantu menjaga ukuran tekstur serta konsistensi.
- Pilih resolusi tekstur berdasarkan jarak kamera dan uji Web/mobile; hindari membawa texture 4K untuk objek kecil.
- Poly Haven menyatakan aset model, tekstur, dan HDRI mereka CC0; tekstur/HDRI resolusi tinggi perlu diturunkan sebelum dipakai di build ringan. [Lisensi Poly Haven](https://polyhaven.com/license)

### Efek visual

- Senjata: muzzle flash singkat, asap tipis, casing opsional, recoil kamera, dan impact yang cocok dengan permukaan.
- Musuh: darah/splatter secukupnya, debu saat jatuh, efek hit yang terbaca, dan perubahan pose saat stagger.
- Lingkungan: debu di sorot flashlight, asap dari pipa, percikan listrik, lampu berkedip, hujan/genangan bila area membutuhkannya.
- Feedback: crosshair saat membidik, hit confirmation yang tidak mengganggu, interaksi yang disorot, dan cue saat item penting ditemukan.
- Prioritaskan efek pendek, transparan seperlunya, particle count rendah, dan versi sederhana untuk Web/mobile.
- Bangun efek dari `GPUParticles3D`, mesh sederhana, material emissive, animasi, dan audio; jangan menjadikan post-processing mahal sebagai syarat visual utama.

### Audio dan musik

- Ambience loop per area: angin, dengung listrik, hujan jauh, pipa, ruang kosong, dan suara kota samar.
- Foley karakter: langkah berbeda untuk beton/ubin/genangan, pakaian, napas, senjata, reload, item, dan interaksi pintu.
- Suara musuh: idle jarak jauh, gerak, wind-up, serangan, kena hit, dan mati; variasi pitch/clip mengurangi repetisi.
- Audio positional untuk ancaman dan petunjuk; ambience stereo untuk rasa ruang.
- Musik digunakan pada momen tertentu, bukan terus-menerus. Sisakan ruang hening agar suara lingkungan bekerja.
- Kenney Digital Audio dan RPG Audio tercatat CC0 pada halaman resminya dan dapat menjadi placeholder; gunakan rekaman/kreasi yang lebih sesuai untuk suara senjata, horror, dan ambience final. [Digital Audio](https://kenney.nl/assets/digital-audio), [RPG Audio](https://kenney.nl/assets/rpg-audio)

### UI dan presentasi cerita

- Main menu, continue/new game, pause, settings, objective, inventory, map, document viewer, item examine, death, dan ending.
- HUD menampilkan hanya informasi yang dibutuhkan saat bermain; detail inventory berada di layar terpisah.
- Interaksi harus terbaca di ponsel: tombol besar, label singkat, kontras yang memadai, dan area aman dari tepi layar.
- Dokumen memakai layout orisinal dan teks pendek yang memberi petunjuk atau konteks.
- Tambahkan subtitle untuk dialog/voice bila dialog digunakan; jangan menaruh informasi penting hanya dalam audio.

## 5. Struktur folder konten yang dituju

Pertahankan folder sumber yang sudah ada. Folder baru dibuat saat konten tersebut mulai dipakai:

```text
assets/
  characters/
    player/
    enemies/
  environment/
    city/
    clinic/
    underground/
  props/
    gameplay/
    set_dressing/
  materials/
  audio/
    ambience/
    characters/
    weapons/
    ui/
  vfx/
scenes/
  levels/
  actors/
  interactables/
  ui/
scripts/
```

Jangan memindahkan paket aset lama secara massal. Scene Godot dan script harus merujuk ke satu salinan runtime yang jelas, sementara berkas lisensi dan catatan sumber tetap ikut tersimpan.

## 6. Roadmap milestone produksi

### M0 — Audit dan keputusan visual

- Inventaris semua model/animasi/audio yang sudah ada dan cek lisensinya.
- Buka model survivor, zombie, dan creature untuk memeriksa rig, skala, material, jumlah mesh, dan ukuran.
- Buat satu halaman art direction: palet, pencahayaan, bentuk UI, gaya material, dan contoh target tiap area.
- Ambil screenshot baseline game dan catat performa/ukuran export yang ada.

**Keluar dari milestone:** aset karakter utama yang dipilih, gaya visual yang konsisten, dan daftar kebutuhan yang benar-benar belum tersedia.

### M1 — Karakter, kamera, dan combat feel

- Ganti karakter prosedural secara bertahap dengan model rigged yang dipilih.
- Implementasikan camera follow dan aim mode, collision kamera, sensitivitas, serta kontrol layar sentuh.
- Sambungkan animasi gerak, bidik, tembak, reload, hit, dan death.
- Rapikan collision karakter; hapus workaround gerak yang menembus collision setelah gerakan fisika benar.
- Buat satu zombie yang mengejar, telegraph serangan, memberi damage, stagger, dan mati.

**Keluar dari milestone:** satu encounter terasa bisa dibaca dan dikendalikan, bukan hanya berfungsi secara teknis.

### M2 — Interaksi, item, dan ruang kecil

- Buat sistem interaksi umum berbasis raycast/jarak dan prompt.
- Buat scene dasar untuk pickup, pintu terkunci, item key, panel daya, dokumen, dan save point.
- Buat satu interior modular kecil dari aset yang tersedia.
- Tambahkan objective yang berubah berdasarkan tindakan pemain.

**Keluar dari milestone:** semua objek penting dapat digunakan tanpa kode khusus yang tersebar di level.

### M3 — Vertical slice klinik

- Hubungkan jalan, klinik, ruang utilitas, dan satu jalan pintas.
- Susun kunci/sekring/petunjuk agar pemain memahami urutannya tanpa waypoint berlebihan.
- Tempatkan musuh, amunisi, healing, dan save point untuk membentuk ritme tegang.
- Tambahkan ambience, langkah kaki, pintu, senjata, dan efek impact dasar.
- Buat awal dan akhir segmen yang jelas.

**Keluar dari milestone:** pemain baru dapat menyelesaikan segmen pertama tanpa bantuan developer.

### M4 — Inventory, resource, dan save

- Inventory terbatas dengan slot/item count yang jelas.
- Gunakan item, gabungkan item hanya jika benar-benar mendukung puzzle, dan beri preview sebelum mengonsumsi.
- Simpan status pintu, item yang diambil, musuh yang dikalahkan, objective, dan checkpoint.
- Pastikan load tidak menggandakan atau menghilangkan item.
- Buat setting sensitivitas, volume, dan kontrol sentuh tersimpan.

**Keluar dari milestone:** progres bertahan setelah restart dan keputusan resource punya konsekuensi.

### M5 — Area kedua dan variasi gameplay

- Tambahkan area underground/servis yang memakai set dressing dan palet berbeda.
- Tambahkan satu varian musuh dengan pola serangan yang berbeda.
- Tambahkan puzzle lingkungan kedua dan jalur pintas yang kembali ke kota.
- Tambahkan satu encounter besar atau mini-boss hanya setelah AI musuh normal stabil.

**Keluar dari milestone:** area kedua menambah pilihan dan ancaman baru; bukan sekadar lebih banyak musuh.

### M6 — Presentasi sinematik

- Buat title/menu, transisi area, objective/map, inventory, examine, pause, death, dan ending.
- Tambahkan efek lighting, fog, lamp flicker, particle, impact, animasi kamera, dan audio cues secara terukur.
- Tambahkan cutscene pendek berbasis kamera/animasi hanya bila memperkuat cerita.
- Pastikan cutscene dapat dilewati dan kontrol kembali dengan benar.

**Keluar dari milestone:** game memiliki identitas visual/audio dan alur yang terasa selesai untuk campaign pendek.

### M7 — Optimasi dan kandidat rilis

- Uji Web melalui Pages dan perangkat Android nyata dengan renderer Compatibility.
- Kurangi ukuran model, material, tekstur, audio, lampu bayangan, transparansi, dan particle yang terbukti berat.
- Periksa rasio layar, orientasi landscape, pause/resume, kehilangan fokus, dan sentuhan multi-finger.
- Uji campaign dari fresh start, checkpoint, mati/restart, dan kondisi semua item penting.
- Pastikan semua aset mempunyai sumber/lisensi yang tercatat dan tidak ada asset import yang hilang.

**Keluar dari milestone:** build Web dapat dimainkan sampai akhir vertical slice; Android diuji terpisah dan masalah perangkat dicatat.

## 7. Prioritas teknis untuk Godot project ini

- Pisahkan logic karakter, senjata, inventory, interaksi, musuh, level, dan UI agar fitur baru tidak menumpuk di satu script besar.
- Gunakan scene reusable untuk actor, pickup, pintu, item, lampu, dan props gameplay.
- Simpan data item/senjata/musuh sebagai resource/data yang mudah disetel, bukan angka tersebar di banyak script.
- Satu sistem interaction menangani prompt dan target terdekat; tombol keyboard dan layar sentuh memanggil aksi yang sama.
- Gunakan NavigationAgent3D untuk AI navigasi bila level sudah menyediakan NavigationRegion3D; jangan menggeser CharacterBody langsung menembus collision sebagai fallback permanen.
- Gunakan save format dengan versi agar perubahan struktur data tidak merusak save lama selama iterasi.
- Setelah setiap milestone, jalankan validasi Godot dan ekspor Web yang tersedia; manual push dilakukan setelah hasil ditinjau.

## 8. Checklist aset sebelum commit/push

- Apakah aset benar-benar dipakai di scene/game, bukan hanya diletakkan di folder?
- Apakah lisensi mengizinkan penggunaan dan distribusi di repository/build?
- Apakah sumber, nama kreator, lisensi, dan atribusi sudah dicatat?
- Apakah hanya format runtime yang diperlukan yang ikut masuk?
- Apakah ukuran file sesuai target Web/mobile?
- Apakah model punya skala, origin, rig, collision, dan material yang benar?
- Apakah audio memiliki loop, volume, channel, dan panjang yang sesuai?
- Apakah efek tetap terbaca tanpa menutupi UI atau menghabiskan performa?
- Apakah preview Pages setelah push tetap berjalan?

## 9. Definisi selesai untuk versi pertama yang layak dibagikan

- Satu campaign pendek dengan beberapa ruang luar/dalam yang terhubung dan tujuan akhir yang jelas.
- Penyintas beranimasi, satu musuh dasar, satu varian ancaman, dan senjata yang punya feedback audio/visual.
- Inventory, item kunci, puzzle, pintu terkunci, healing, ammo scarcity, dan checkpoint bekerja.
- Ada ambience dan cue audio yang membantu pemain membaca ruang/ancaman.
- UI dan kontrol mendukung desktop serta landscape touch.
- Web preview melalui Pages dapat dimainkan dari awal sampai ending vertical slice.
- Android build menjadi target uji terpisah; performa dan layout tidak diasumsikan otomatis sama dengan Web.
- Aset yang dipakai konsisten secara visual dan mempunyai catatan lisensi/sumber.
- Seluruh karakter, lokasi, cerita, UI, dan desain musuh tetap milik Neko Nightfall dan tidak menyalin elemen terlindungi dari franchise lain.
