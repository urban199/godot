# PRD — SHINOBI ARENA 2D
## Rencana Produk Lengkap: Home → Pemilihan Karakter → Pemilihan Arena → Battle

**Versi dokumen:** 1.0  
**Engine:** Godot 4.5.1  
**Bahasa:** GDScript  
**Target:** Web (GitHub Pages), Windows, Android  
**Gaya:** 2D side-scrolling anime fighter dengan sprite HD orisinal atau berlisensi  
**Metode build:** GitHub Actions; pengembangan tidak mensyaratkan editor Godot berjalan di PC lokal

---

## 1. Ringkasan Produk

Shinobi Arena 2D adalah game pertarungan anime 2D yang terinspirasi dari struktur permainan side-scrolling team fighter seperti Naruto Senki. Pemain melewati alur menu utama, memilih mode permainan, memilih karakter, memilih arena, kemudian bertarung melawan AI atau pemain kedua lokal jika fitur tersebut sudah diaktifkan.

Dokumen ini menetapkan pengalaman produk dari layar Home sampai Battle, sistem pendukung, arsitektur scene, data, input, alur build, dan kriteria penerimaan. Game harus menggunakan aset game yang benar-benar dirender oleh Godot. Gambar konsep hanya untuk referensi; karakter, arena, efek, dan animasi saat bermain harus berupa node, sprite, tilemap, partikel, shader, audio, dan kode gameplay.

### Sasaran utama
- Alur navigasi jelas dari Home sampai pertandingan.
- Pemain bisa memilih karakter dan arena sebelum battle.
- Pertarungan responsif dengan gerak, serangan, skill, pertahanan, HP, energi, dan kondisi menang/kalah.
- UI beradaptasi untuk desktop, browser, dan layar sentuh.
- Proyek dapat divalidasi dan dibuild melalui GitHub Actions.
- Arsitektur modular agar penambahan karakter, arena, mode, dan skill tidak memerlukan penulisan ulang game inti.

### Bukan sasaran versi pertama
- Multiplayer online, matchmaking, akun cloud, dan server kompetitif.
- Game 3D.
- Monetisasi, loot box, atau toko daring.
- Penggunaan sprite, musik, logo, atau karakter berhak cipta tanpa izin.
- Menjanjikan frame rate atau kompatibilitas semua perangkat sebelum pengujian.

---

## 2. Target Pengguna dan Platform

### Pengguna
- Pemain kasual yang menyukai pertarungan anime 2D.
- Pengguna Android yang membutuhkan kontrol sentuh.
- Pengguna PC yang lebih nyaman menggunakan keyboard.
- Pengguna browser yang ingin mencoba game tanpa instalasi.

### Platform dan input
| Platform | Input utama | Catatan |
|---|---|---|
| Web desktop | Keyboard dan mouse | Build Godot Web; uji browser Chromium/Firefox yang didukung |
| Web mobile | Kontrol sentuh | Kinerja tergantung browser dan perangkat |
| Windows | Keyboard; gamepad opsional | Build desktop |
| Android | Joystick/tombol sentuh | APK; uji orientasi landscape dan safe area |

**Orientasi:** landscape.  
**Resolusi desain UI:** 1280×720 dengan scaling berbasis container/anchor.  
**Renderer:** Godot Compatibility / GL Compatibility untuk cakupan perangkat yang lebih luas.  
**Target performa:** 60 FPS sebagai sasaran desktop, dengan fallback kualitas/efek pada perangkat lemah; angka akhir ditentukan lewat profiling nyata.

---

## 3. Alur Utama Pengguna

1. **Boot / Splash:** memuat konfigurasi, audio, data karakter, dan data arena.
2. **Home:** pemain memilih Play, Practice, Settings, Collection, atau Quit/Back.
3. **Mode Select:** memilih Quick Battle, Practice, atau Versus Local (jika sudah tersedia).
4. **Character Select:** memilih karakter Player 1 dan lawan/slot AI, melihat preview, statistik, dan skill.
5. **Arena Select:** memilih arena yang terbuka, melihat preview, dan menetapkan arena.
6. **Battle Intro:** menampilkan nama karakter, nama arena, transisi kamera, dan announcer opsional.
7. **Battle:** pemain bertarung sampai kondisi menang/kalah, timeout, atau draw.
8. **Result:** menampilkan pemenang, statistik ringkas, Rematch, Character Select, Arena Select, atau Home.
9. **Save:** pengaturan dan unlock lokal disimpan secara aman melalui sistem file `user://`; web memakai persistensi yang didukung export/browser.

### Navigasi ringkas
```text
Boot
 └─ Home
     ├─ Play
     │   └─ Mode Select
     │       └─ Character Select
     │           └─ Arena Select
     │               └─ Battle Intro
     │                   └─ Battle
     │                       └─ Result
     │                           ├─ Rematch → Battle
     │                           ├─ Character Select
     │                           ├─ Arena Select
     │                           └─ Home
     ├─ Practice → Character Select → Arena Select → Battle
     ├─ Collection (future / unlock viewer)
     ├─ Settings
     └─ Quit (desktop) / Back (web)
```

---

## 4. Requirements Fungsional

### 4.1 Boot dan Home

**Tujuan:** menyediakan titik masuk yang jelas, memulihkan pengaturan, dan menavigasi ke fitur game.

**UI Home**
- Logo/title game.
- Tombol Play.
- Tombol Practice.
- Tombol Collection (boleh diberi label Coming Soon sampai implementasi selesai).
- Tombol Settings.
- Tombol Credits.
- Tombol Exit pada Windows; di web tombol menjadi Back to title/confirmation atau disembunyikan karena browser tidak mengizinkan tab ditutup sesuka hati.
- Background animasi ringan dengan parallax, partikel daun/kelopak, dan karakter idle dekoratif bila aset tersedia.

**Aturan**
- Tombol Play mengarah ke Mode Select.
- Practice langsung mengarah ke pemilihan karakter dengan AI pasif/target dummy.
- Settings bisa dibuka dari Home dan Pause.
- Menu harus bisa digunakan keyboard, mouse, gamepad bila tersedia, dan sentuh.
- Tombol memiliki state normal, hover/focus, pressed, disabled.
- Transisi layar menggunakan fade/slide pendek dan bisa dimatikan melalui pengaturan reduced effects.

**Kriteria penerimaan**
- Tidak ada tombol utama tanpa aksi.
- Back/Escape kembali ke layar sebelumnya, bukan keluar dari game secara tidak sengaja.
- UI tidak terpotong pada rasio 16:9 dan layar ponsel landscape yang diuji.
- Jika aset gagal dimuat, menu tetap tampil menggunakan fallback sederhana.

### 4.2 Mode Select

**Mode MVP**
1. **Quick Battle:** satu pemain melawan AI.
2. **Practice:** AI diam atau target dummy, tanpa timer atau dengan reset cepat.
3. **Versus Local (tahap lanjutan):** dua pemain pada satu perangkat; tidak termasuk online multiplayer.

**Aturan**
- Mode yang belum diimplementasikan ditandai Coming Soon dan tidak dapat dimulai.
- Pemilihan mode disimpan ke `GameSession`.
- Mode menentukan konfigurasi AI, timer, dan kondisi menang.

**Kriteria penerimaan**
- Quick Battle dapat dilanjutkan ke Character Select.
- Practice mengaktifkan konfigurasi practice yang sesuai.
- Mode yang belum tersedia tidak membuat crash.

### 4.3 Character Select

**Layout**
- Panel kiri: Player 1.
- Panel tengah: grid kartu karakter.
- Panel kanan: lawan/AI.
- Panel bawah: nama, role, statistik, skill, tombol Confirm dan Back.
- Preview karakter besar dengan animasi idle.
- Ikon status Locked/Unlocked.
- Pada Android, kartu dan tombol memiliki area sentuh memadai.

**Data karakter**
Setiap karakter mempunyai:
- `id`, `display_name`, `description`, `portrait`, `sprite_scene`.
- `max_hp`, `move_speed`, `jump_strength`, `attack_power`, `defense`.
- `skills[]` berisi ID skill.
- `unlock_condition` opsional.
- `animations` dengan nama state yang konsisten.
- `team_color` atau palet UI opsional.

**MVP roster**
- Minimal 3 karakter orisinal dengan peran berbeda: balanced, fast, heavy.
- Untuk starter prototype boleh dimulai dari 2 karakter placeholder, namun PRD target fase ini adalah minimal 3 karakter.
- Tidak memakai aset Naruto resmi tanpa izin; karakter dan nama dibuat orisinal atau memakai aset yang lisensinya mengizinkan distribusi.

**Aturan**
- Pilihan default ditandai jelas.
- Player 1 tidak boleh memilih karakter yang terkunci.
- AI opponent dapat dipilih secara manual atau acak.
- Tombol Confirm baru aktif jika pilihan valid.
- Pilihan diteruskan melalui `GameSession`, bukan variabel global ad hoc.
- Preview tidak boleh menjalankan gameplay penuh; gunakan scene preview yang ringan.

**Kriteria penerimaan**
- Memilih kartu memperbarui nama, statistik, skill, dan preview.
- Confirm menyimpan ID karakter ke sesi.
- Kembali ke Character Select dari Arena Select mempertahankan pilihan sebelumnya.
- Data karakter yang hilang menghasilkan fallback dan log yang mudah ditemukan.

### 4.4 Arena Select

**Layout**
- Kartu arena dengan screenshot/preview.
- Nama, deskripsi, tema, dan status unlock.
- Panel ringkasan karakter yang dipilih.
- Tombol Random Arena opsional.
- Confirm dan Back.

**MVP arena**
- Forest Shrine: arena hutan dengan kuil.
- Training Dojo: arena latihan.
- Ruined Outpost: pos terbengkalai.
Semua arena dibuat dengan background layers/parallax, ground collision, batas kiri/kanan, dan titik spawn pemain yang terdefinisi.

**Aturan**
- Arena data mempunyai ID, `PackedScene` path, preview, batas arena, spawn point, musik, dan daftar layer.
- Random Arena hanya memilih arena yang terbuka.
- Pilihan arena disimpan di `GameSession`.
- Tidak menggunakan gambar preview sebagai latar arena aktif; arena battle harus scene game yang sebenarnya.

**Kriteria penerimaan**
- Preview arena berubah sesuai kartu.
- Confirm memuat scene arena terpilih pada saat Battle dimulai.
- Player dan AI spawn pada posisi yang benar dan tidak jatuh menembus lantai.
- Back mempertahankan pilihan karakter.

### 4.5 Battle

**Kamera dan arena**
- Side-view 2D.
- Kamera mengikuti kedua petarung dengan batas arena.
- Latar parallax dengan ground/collision yang nyata.
- Batas arena mencegah pemain berjalan keluar layar.
- Efek visual dipisahkan dari gameplay collision.

**Pergerakan**
- Jalan/berlari kiri dan kanan.
- Melompat dan jatuh dengan gravitasi.
- Dash atau dodge dengan cooldown.
- Facing otomatis mengarah ke lawan.
- Collision konsisten di semua arena.

**Combat**
- Light attack dengan cooldown.
- Combo chain berdasarkan input window.
- Heavy attack opsional.
- Skill 1/2 dengan konsumsi energi dan cooldown.
- Block/guard dengan pengurangan damage.
- Hitbox/hurtbox aktif pada frame serangan yang tepat.
- Knockback, hit-stun, invulnerability window singkat setelah menerima serangan (bila desain memerlukannya).
- Proyektil mempunyai team ownership, kecepatan, durasi hidup, collision, dan efek hit.
- Tidak ada damage berulang setiap frame untuk satu serangan yang sama kecuali skill memang multi-hit.

**Status**
- HP.
- Energi/chakra.
- Cooldown skill.
- Timer ronde.
- Status menang/kalah/draw.
- Pause/resume.

**AI**
- State machine: Idle, Approach, Retreat, Attack, Skill, Guard, Hurt, KO.
- AI memilih aksi berdasarkan jarak, HP, energi, dan cooldown.
- Tingkat kesulitan: Easy/Normal/Hard (tahap lanjutan).
- AI tidak boleh terus menembakkan skill tanpa energi atau menyerang saat KO.

**HUD Battle**
- Bar HP dua pemain.
- Bar energi.
- Timer ronde.
- Nama karakter.
- Indikator cooldown/skill.
- Pause.
- Touch controls untuk mobile: kiri/kanan, lompat, guard, attack, skill, dash.
- Tombol sentuh harus mendukung menekan dan melepas; input tidak boleh tertahan setelah jari keluar dari tombol atau aplikasi kehilangan fokus.

**Kondisi akhir**
- HP salah satu petarung mencapai nol → lawan menang.
- Timer mencapai nol → petarung dengan HP lebih tinggi menang.
- HP sama pada timeout → draw.
- Setelah kondisi akhir, input combat dinonaktifkan dan transisi menuju Result dilakukan sekali saja.

**Kriteria penerimaan**
- Hitbox hanya aktif pada window serangan.
- Damage, knockback, dan animasi tidak dipicu ganda oleh satu hit.
- Pause benar-benar menghentikan gameplay dan timer.
- Battle berakhir tepat satu kali.
- Restart menghasilkan state bersih tanpa projectile atau timer dari pertandingan sebelumnya.

### 4.6 Result Screen

**Informasi**
- Victory/Defeat/Draw.
- Karakter pemenang.
- Arena.
- Durasi pertandingan.
- Jumlah serangan/hit (opsional).
- Tombol Rematch.
- Tombol Character Select.
- Tombol Arena Select.
- Tombol Home.

**Aturan**
- Rematch mempertahankan karakter, mode, dan arena.
- Character Select kembali ke pemilihan karakter.
- Arena Select mempertahankan karakter yang dipilih.
- Home menghapus state pertandingan sementara, tetapi tidak menghapus pengaturan atau unlock.
- Statistik hasil baru dicatat sekali setiap pertandingan.

### 4.7 Settings

- Master volume, musik, efek suara.
- Sensitivitas kontrol.
- Layout tombol mobile (opsional).
- Kualitas efek: Low/Medium/High.
- Screen shake on/off.
- Flash intensity / reduced effects.
- Bahasa UI (Bahasa Indonesia dan English sebagai opsi fase lanjutan).
- Tombol Reset Settings.
- Pengaturan otomatis tersimpan dan dipulihkan saat game dibuka kembali.

### 4.8 Collection / Progression

**MVP:** halaman koleksi dapat menampilkan roster dan status karakter tanpa progression kompleks.

**Fase lanjutan:**
- Statistik total kemenangan dan kekalahan.
- Karakter yang terbuka melalui tantangan offline.
- Skin orisinal.
- Tantangan latihan.
- Tidak menggunakan gacha atau transaksi online di MVP.

---

## 5. Non-Functional Requirements

### Performa
- Menghindari aset tekstur berlebihan dan ukuran file yang tidak perlu.
- Sprite atlas digunakan untuk mengurangi pergantian tekstur jika sesuai.
- Efek partikel dibatasi dan dapat diturunkan.
- Gunakan object pooling untuk proyektil/efek jika jumlahnya tinggi.
- Hindari alokasi node berulang pada setiap frame.
- Target awal 60 FPS, lalu ukur pada browser desktop, PC target, dan Android target.

### Stabilitas
- Tidak boleh ada error script saat membuka Home, memilih karakter, memilih arena, bertarung, pause, result, dan rematch.
- Scene harus dapat dimuat ulang tanpa node tertinggal.
- Data tidak valid ditangani dengan fallback.

### Aksesibilitas
- Navigasi keyboard.
- Fokus UI yang terlihat.
- Ukuran tombol mobile memadai.
- Opsi mengurangi screen shake/flash.
- Informasi tidak hanya dibedakan dengan warna.

### Keamanan dan privasi
- Tidak membutuhkan akun atau backend pada MVP.
- Data lokal hanya menyimpan preferensi dan progres.
- Jangan menyimpan token rahasia dalam repository.
- Aset pihak ketiga harus dicatat lisensi dan atribusinya.

---

## 6. Architecture

### Pola arsitektur
Gunakan scene modular dan Autoload terbatas:
- `GameSession.gd`: mode, ID karakter, ID arena, hasil pertandingan sementara.
- `SaveManager.gd`: load/save settings dan progression.
- `AudioManager.gd`: musik dan efek suara.
- `SceneRouter.gd`: perpindahan scene dengan transisi.
- `CharacterDatabase.gd`: registrasi karakter.
- `ArenaDatabase.gd`: registrasi arena.

### Struktur direktori yang disarankan
```text
SHINOBI_ARENA_2D/
├── project.godot
├── export_presets.cfg
├── scenes/
│   ├── boot/boot.tscn
│   ├── menus/home.tscn
│   ├── menus/mode_select.tscn
│   ├── menus/character_select.tscn
│   ├── menus/arena_select.tscn
│   ├── battle/battle.tscn
│   ├── battle/battle_hud.tscn
│   ├── results/result.tscn
│   ├── settings/settings.tscn
│   ├── characters/
│   │   ├── fighter_base.tscn
│   │   └── previews/
│   └── arenas/
│       ├── forest_shrine.tscn
│       ├── training_dojo.tscn
│       └── ruined_outpost.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_session.gd
│   │   ├── save_manager.gd
│   │   ├── scene_router.gd
│   │   └── audio_manager.gd
│   ├── menus/
│   ├── combat/
│   │   ├── fighter_controller.gd
│   │   ├── combat_component.gd
│   │   ├── hitbox.gd
│   │   ├── hurtbox.gd
│   │   ├── projectile.gd
│   │   └── fighter_state_machine.gd
│   ├── ai/
│   ├── data/
│   └── ui/
├── data/
│   ├── characters/
│   ├── arenas/
│   └── skills/
├── assets/
│   ├── sprites/
│   ├── portraits/
│   ├── backgrounds/
│   ├── effects/
│   ├── audio/
│   ├── fonts/
│   └── ui/
├── tests/
├── docs/
└── .github/workflows/
```

### Pembagian tanggung jawab
- **Menu scenes:** mengumpulkan pilihan dan memvalidasi input.
- **GameSession:** sumber kebenaran untuk pilihan mode/karakter/arena pertandingan aktif.
- **Battle scene:** membuat instance arena dan petarung berdasarkan ID yang sudah dikonfirmasi.
- **Fighter controller:** pergerakan dan state karakter.
- **Combat component:** damage, cooldown, energy, hit confirmation.
- **AI controller:** keputusan lawan, bukan pengganti combat system.
- **SaveManager:** penyimpanan persisten, terpisah dari state pertandingan aktif.

### Scene transitions
Gunakan satu metode transisi terpusat yang:
1. Memvalidasi data sesi.
2. Menampilkan fade.
3. Memuat scene tujuan.
4. Mengirim parameter melalui `GameSession`.
5. Menghapus overlay transisi setelah scene siap.
6. Menampilkan pesan error yang bisa dipahami jika scene gagal dimuat.

---

## 7. Data Model

### GameSession
```gdscript
var selected_mode: String = "quick_battle"
var player_character_id: String = "shinobi_balanced"
var opponent_character_id: String = "rival_fast"
var selected_arena_id: String = "forest_shrine"
var match_result: Dictionary = {}
var is_practice: bool = false
```

### Character Definition
```json
{
  "id": "shinobi_balanced",
  "display_name": "Kairo",
  "role": "balanced",
  "max_hp": 100,
  "move_speed": 280,
  "attack_power": 12,
  "defense": 1.0,
  "skills": ["energy_bolt", "rising_strike"],
  "unlocked_by_default": true
}
```

### Arena Definition
```json
{
  "id": "forest_shrine",
  "display_name": "Forest Shrine",
  "scene_path": "res://scenes/arenas/forest_shrine.tscn",
  "preview_path": "res://assets/backgrounds/forest_shrine_preview.png",
  "left_bound": 40,
  "right_bound": 2100,
  "music_id": "battle_theme_01",
  "unlocked_by_default": true
}
```

### Settings Save
Simpan di `user://settings.json`:
```json
{
  "version": 1,
  "master_volume": 1.0,
  "music_volume": 0.8,
  "sfx_volume": 1.0,
  "effects_quality": "medium",
  "screen_shake": true,
  "reduced_flashes": false,
  "control_sensitivity": 1.0
}
```

### Progress Save
Simpan di `user://progress.json`:
```json
{
  "version": 1,
  "wins": 0,
  "losses": 0,
  "draws": 0,
  "unlocked_characters": ["shinobi_balanced", "rival_fast"],
  "unlocked_arenas": ["forest_shrine", "training_dojo"]
}
```

Jangan menyimpan state runtime seperti node reference, object instance, atau timer aktif langsung ke JSON. Simpan ID dan nilai primitif yang dapat divalidasi.

---

## 8. Tech Stack dan Build

- **Engine:** Godot 4.5.1.
- **Bahasa:** GDScript.
- **Grafik:** Sprite2D/AnimatedSprite2D atau AnimationPlayer; TileMapLayer jika diperlukan.
- **UI:** Control nodes, Containers, Theme, anchors.
- **Audio:** AudioStreamPlayer dan AudioStreamPlayer2D.
- **Data:** Resource `.tres` atau JSON terverifikasi.
- **Save:** `FileAccess` dengan folder `user://`.
- **CI:** GitHub Actions.
- **Web:** Godot Web export; host hasil ekspor di GitHub Pages.
- **Windows:** Windows Desktop export.
- **Android:** Android export dengan Java/JDK, Android SDK, dan template Godot yang sesuai.

### Workflow CI yang direkomendasikan
1. Checkout repository.
2. Unduh Godot 4.5.1.
3. Pasang export templates dengan versi yang sama.
4. Jalankan import/headless parse check.
5. Jalankan smoke test untuk scene utama.
6. Ekspor Web, Windows, dan Android pada workflow masing-masing.
7. Unggah output sebagai GitHub Actions artifacts.
8. Publikasikan Web ke GitHub Pages setelah build valid.
9. Simpan log build untuk diagnosis.

**Penting:** validasi script tidak menjamin semua ekspor platform berhasil. Web, Windows, dan Android harus diuji sebagai job terpisah; Android memerlukan konfigurasi SDK/JDK dan signing sesuai kebutuhan distribusi.

---

## 9. Prioritas dan Tahapan Implementasi

### Tahap 0 — Fondasi teknis
- [ ] Project Godot 4.5.1 bersih dan dapat dibuka headless.
- [ ] Autoload GameSession, SaveManager, SceneRouter.
- [ ] CI validation berjalan.
- [ ] Input actions terpusat.

### Tahap 1 — Home dan navigasi
- [ ] Home dengan Play, Practice, Collection, Settings, Credits.
- [ ] Mode Select.
- [ ] Back/Escape dan transisi scene.
- [ ] UI scalable desktop/mobile.

### Tahap 2 — Character Select
- [ ] Character database dan 3 karakter orisinal.
- [ ] Kartu karakter, preview animasi, statistik, skill.
- [ ] Confirm/back dan validasi pilihan.
- [ ] Penyimpanan pilihan dalam GameSession.

### Tahap 3 — Arena Select
- [ ] Arena database dan 3 arena.
- [ ] Preview, deskripsi, unlock state.
- [ ] Spawn point dan batas arena.
- [ ] Confirm melanjutkan ke Battle.

### Tahap 4 — Battle MVP
- [ ] Movement, jump, facing, collision.
- [ ] Attack, combo dasar, skill, guard, dash.
- [ ] Hitbox/hurtbox, damage, knockback.
- [ ] AI state machine.
- [ ] HP, energi, timer, pause, win/lose/draw.
- [ ] Kontrol sentuh dan fokus input.

### Tahap 5 — Result dan settings
- [ ] Result screen.
- [ ] Rematch dan jalur kembali ke menu.
- [ ] Settings audio/grafis/kontrol.
- [ ] SaveManager dan progression lokal.

### Tahap 6 — Art dan polish
- [ ] Sprite sheet HD orisinal/berlisensi.
- [ ] Animasi idle/run/jump/attack/hurt/skill/KO.
- [ ] Efek partikel dan hit-stop.
- [ ] Audio, kamera, parallax, transisi.
- [ ] Optimasi Web/mobile.

### Tahap 7 — Build dan rilis
- [ ] GitHub Actions validate.
- [ ] Web export dan GitHub Pages.
- [ ] Windows artifact.
- [ ] Android APK artifact.
- [ ] Uji di browser dan perangkat fisik.
- [ ] Dokumentasi build dan lisensi aset.

---

## 10. Definition of Done / Acceptance Test

Versi Home → Battle dianggap memenuhi fondasi lengkap jika:
1. Game dibuka dan masuk Home tanpa error.
2. Play membuka Mode Select.
3. Pemilihan mode tersimpan dengan benar.
4. Character Select menampilkan karakter, preview, statistik, dan skill.
5. Arena Select menampilkan arena yang benar.
6. Confirm memuat arena dan dua petarung berdasarkan pilihan.
7. Pemain dapat bergerak, melompat, menyerang, memakai skill, bertahan, dan dash.
8. AI dapat mengambil keputusan dan tidak menyerang ketika KO.
9. HP/energi/timer diperbarui dengan benar.
10. Pertandingan berakhir satu kali dan Result menampilkan hasil benar.
11. Rematch mengulang pertandingan tanpa state lama yang tertinggal.
12. Back/Home berfungsi pada seluruh layar.
13. Pengaturan tetap tersimpan setelah game dibuka ulang.
14. Kontrol sentuh diuji pada Android dan browser mobile.
15. Build Web, Windows, dan Android menghasilkan artefak melalui GitHub Actions.
16. Tidak ada aset tanpa izin distribusi dan tidak ada gambar konsep yang dipakai sebagai pengganti gameplay.

---

## 11. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Sprite HD membutuhkan banyak waktu | Gunakan karakter orisinal, pipeline sprite sheet, dan selesaikan satu karakter penuh lebih dahulu |
| Build Web tidak cocok pada sebagian ponsel | Gunakan efek ringan, batasi partikel, dan uji pada perangkat nyata |
| Ekspor Android gagal karena SDK/template | Kunci versi Godot, template, JDK, dan SDK dalam workflow |
| AI sulit diseimbangkan | Pisahkan AI decision dari combat system dan sediakan tingkat kesulitan |
| State rusak saat rematch | Buat Battle scene baru dan reset projectile, cooldown, timer, dan HP |
| Hak cipta karakter anime | Gunakan karakter orisinal atau aset berlisensi yang memperbolehkan distribusi |
| Build hijau tetapi gameplay rusak | Tambahkan smoke test, test checklist, dan uji manual hasil artefak |

---

## 12. Definisi Rilis

**MVP playable:** Home → Mode Select → Character Select → Arena Select → Battle → Result, satu mode Quick Battle, minimal tiga karakter orisinal, tiga arena, kontrol desktop dan mobile, serta AI yang berfungsi.

**Release candidate:** animasi sprite HD, audio, settings, save, rematch stabil, ekspor Web/Windows/Android tervalidasi, dan tidak ada bug blocker.

**Rilis publik:** seluruh aset memiliki izin distribusi, pengujian perangkat selesai, README dan petunjuk kontrol tersedia, dan GitHub Pages mengarah ke build Web yang benar.
