# Neko Godot AI — Development Plan

## 1. Tujuan Proyek

Membangun IDE Godot berbasis browser untuk membuat game 3D dengan bantuan AI, dengan prinsip:

- PC pengguna tidak perlu menginstal Godot.
- Godot hanya berjalan di GitHub Actions Runner.
- Coding dilakukan melalui browser.
- AI dapat membaca, membuat, dan mengubah kode project.
- Project disimpan di GitHub.
- Godot Headless digunakan untuk validasi, testing, dan export.
- Game dapat di-preview melalui hasil Godot Web.
- Game dapat dibuild menjadi Web, Android APK, dan Windows.
- Kecepatan build bukan prioritas utama; kestabilan dan penggunaan PC yang ringan lebih penting.

Nama kerja proyek: **Neko Godot AI**.

---

# 2. Visi Arsitektur

```text
                         USER PC
                            |
                            | Browser
                            v
                 +-----------------------+
                 |    Neko Godot AI      |
                 |-----------------------|
                 | File Explorer         |
                 | Monaco Code Editor    |
                 | AI Chat / Agent       |
                 | Run / Build           |
                 | Build Logs            |
                 +-----------+-----------+
                             |
                             | HTTPS
                             v
                 +-----------------------+
                 |        GitHub         |
                 |-----------------------|
                 | Repository            |
                 | Git history           |
                 | Actions               |
                 +-----------+-----------+
                             |
                             v
                 +-----------------------+
                 | GitHub Actions Runner |
                 |-----------------------|
                 | Godot Headless        |
                 | Validate              |
                 | Test                  |
                 | Export                |
                 +-----------+-----------+
                             |
              +--------------+---------------+
              |              |               |
              v              v               v
          Godot Web       Android         Windows
           Export           APK             EXE
              |
              v
        Browser Preview
```

---

# 3. Prinsip Desain

## 3.1 Godot non-local

Godot tidak menjadi dependency pada komputer pengguna.

Yang dijalankan pada runner:

```text
Godot Headless
Export Templates
Project Validation
Automated Tests
Web Export
Android Export
Windows Export
```

## 3.2 Browser sebagai client

PC pengguna hanya membutuhkan browser modern.

Tidak perlu:

- Godot Editor
- Android Studio
- Java/JDK lokal
- Android SDK lokal
- compiler lokal
- GPU kuat

## 3.3 GitHub sebagai pusat project

GitHub menjadi sumber utama:

```text
Source Code
Scenes
Assets
Project Settings
Workflow
Build History
Version History
```

## 3.4 AI sebagai coding agent

AI tidak hanya memberikan potongan kode.

AI harus dapat melakukan operasi:

```text
read_file
write_file
create_file
delete_file
list_files
search_code
get_project_structure
run_validation
read_build_log
```

AI tetap harus bekerja dengan batasan keamanan dan meminta persetujuan untuk operasi berisiko.

---

# 4. Teknologi yang Disarankan

## Frontend

- React
- TypeScript
- Monaco Editor
- React-based file explorer
- HTML/CSS
- Browser Fetch API

## Backend / API Layer

Tahap awal dapat menggunakan server ringan.

Tugas backend:

- autentikasi GitHub
- membaca repository
- membuat commit
- trigger GitHub Actions
- membaca status workflow
- mengambil build logs
- mengatur AI tool calls
- mengontrol akses project

## AI

Gunakan model coding/agent yang memiliki kemampuan tool calling.

AI harus diberi context:

```text
project structure
relevant files
Godot version
build errors
user request
```

Jangan mengirim seluruh repository pada setiap request jika tidak diperlukan.

## Source Control

- GitHub Repository
- GitHub API
- GitHub Actions

## Game Engine

- Godot 4.x
- GDScript
- Compatibility renderer untuk target PC/game ringan

Versi Godot harus dipin agar build reproducible.

Contoh:

```text
GODOT_VERSION=4.x.x
```

Jangan menggunakan versi `latest` untuk production workflow.

---

# 5. Struktur Repository Game

Contoh repository game:

```text
neko-game/
├── project.godot
│
├── scenes/
│   ├── main.tscn
│   ├── player.tscn
│   └── enemy.tscn
│
├── scripts/
│   ├── player.gd
│   ├── enemy.gd
│   └── game.gd
│
├── assets/
│   ├── models/
│   ├── textures/
│   ├── materials/
│   └── audio/
│
├── shaders/
│
├── tests/
│
└── .github/
    └── workflows/
        ├── validate.yml
        ├── web.yml
        ├── android.yml
        └── windows.yml
```

---

# 6. Struktur Repository IDE

Aplikasi IDE dapat dipisahkan dari repository game:

```text
neko-godot-ai/
├── frontend/
│   ├── components/
│   ├── editor/
│   ├── file-tree/
│   ├── ai/
│   ├── preview/
│   └── logs/
│
├── backend/
│   ├── github/
│   ├── ai/
│   ├── projects/
│   ├── builds/
│   └── security/
│
├── shared/
│
└── docs/
```

---

# 7. MVP 1 — Godot Headless di GitHub

Tujuan:

> Membuktikan bahwa project Godot dapat dibuild tanpa Godot lokal.

Buat project 3D sederhana:

```text
Main
├── WorldEnvironment
├── DirectionalLight3D
├── Camera3D
├── Ground
└── Player
```

Runner melakukan:

```text
checkout
    |
install/download Godot
    |
validate project
    |
export Web
    |
upload artifact
```

Acceptance criteria:

- Workflow berhasil.
- Godot berjalan headless.
- Project dapat divalidasi.
- Web build berhasil.
- Artifact tersedia.

---

# 8. MVP 2 — Godot Web Preview

Tujuan:

> Menjalankan hasil game 3D langsung di browser.

Alur:

```text
GitHub Actions
      |
      v
Godot Headless
      |
      v
Web Export
      |
      v
HTML + WASM + PCK
      |
      v
Preview Hosting
      |
      v
Browser
```

Preview harus dipisahkan dari IDE utama menggunakan iframe atau halaman preview.

Acceptance criteria:

- Game 3D terbuka di browser.
- Keyboard/mouse input berfungsi.
- Reload preview mudah dilakukan.
- Build yang sedang dipreview memiliki commit/build ID yang jelas.

---

# 9. MVP 3 — Browser Code Editor

Gunakan Monaco Editor.

Fitur:

```text
Open file
Edit file
Save
Undo/Redo
Search
Find/Replace
Syntax highlighting
GDScript support
```

Layout awal:

```text
+------------------------------------------------------+
| Neko Godot AI                       Run | Build       |
+------------+-------------------------+---------------+
| FILES      | EDITOR                  | PREVIEW       |
|            |                         |               |
| scenes/    | player.gd               |               |
| scripts/   |                         |   Godot Web   |
| assets/    | extends CharacterBody3D |   Game 3D     |
|            |                         |               |
+------------+-------------------------+---------------+
| AI CHAT                                              |
|                                                     |
+------------------------------------------------------+
```

Acceptance criteria:

- File dapat dibuka dari GitHub.
- File dapat diedit.
- Perubahan dapat disimpan.
- Perubahan dapat di-commit.

---

# 10. MVP 4 — AI Coding Agent

AI diberi tools:

```text
list_files()
read_file(path)
search_code(query)
write_file(path, content)
create_file(path, content)
delete_file(path)
```

Contoh prompt:

> Buat player dapat berjalan, sprint, dan melompat.

Workflow:

```text
User request
    |
    v
AI Agent
    |
    +-- list files
    |
    +-- read player.gd
    |
    +-- read project.godot
    |
    +-- modify player.gd
    |
    +-- modify input configuration
    |
    v
Show Diff
    |
    v
User Approve
    |
    v
Commit
```

Penting:

**Jangan langsung overwrite file tanpa diff/approval pada MVP awal.**

---

# 11. MVP 5 — AI + Godot Validation

Setelah AI membuat perubahan:

```text
AI edit
   |
   v
Temporary commit / branch
   |
   v
GitHub Actions
   |
   v
Godot validation
   |
   +---- ERROR ----> AI
   |                  |
   |                  v
   |               Fix code
   |                  |
   |                  v
   |                Retry
   |
   +---- OK -------> Preview
```

Batasi jumlah auto-fix, misalnya:

```text
MAX_AUTO_FIX_ATTEMPTS=3
```

Tujuannya mencegah infinite loop.

---

# 12. MVP 6 — Build Manager

Tambahkan tombol:

```text
[ RUN WEB ]
[ BUILD WEB ]
[ BUILD APK ]
[ BUILD WINDOWS ]
```

Build manager menyimpan:

```text
build_id
commit_sha
target
status
started_at
finished_at
artifact
logs
```

Status:

```text
QUEUED
RUNNING
SUCCESS
FAILED
CANCELLED
```

---

# 13. GitHub Actions Workflow

## Validate

```text
Push / Pull Request
       |
       v
GitHub Actions
       |
       v
Godot Headless
       |
       v
Validate + Tests
```

## Web

```text
Manual / Run
    |
    v
Godot Headless
    |
    v
Export Web
    |
    v
Upload Artifact / Preview
```

## Android

```text
Manual Build
    |
    v
Godot Headless
    |
    v
Android Export
    |
    v
APK Artifact
```

## Windows

```text
Manual Build
    |
    v
Godot Headless
    |
    v
Windows Export
    |
    v
EXE/ZIP Artifact
```

---

# 14. Preview Strategy

Karena Godot hanya berada di GitHub Runner, preview bersifat build-based.

Alur:

```text
EDIT
 |
 v
SAVE
 |
 v
RUN
 |
 v
GitHub Actions
 |
 v
Godot Web Export
 |
 v
Publish Preview
 |
 v
Open Browser
```

Tidak perlu real-time editor pada tahap awal.

Target waktu awal yang realistis:

```text
Edit → Build → Preview
```

boleh memakan waktu beberapa menit.

Prioritas:

1. Stabil
2. Hemat resource PC
3. Reproducible
4. Baru kemudian optimasi kecepatan

---

# 15. Branch Strategy

Jangan langsung AI bekerja pada branch utama.

Gunakan:

```text
main
 |
 +-- ai/player-movement
 |
 +-- ai/inventory
 |
 +-- ai/zombie-system
```

Alur:

```text
User request
    |
    v
AI branch
    |
    v
Build/Test
    |
    v
Preview
    |
    v
User approval
    |
    v
Merge main
```

Ini memungkinkan perubahan AI dibatalkan dengan mudah.

---

# 16. AI Diff System

Setiap perubahan AI harus ditampilkan:

```diff
- var speed = 5
+ var speed = 7

+ @export var sprint_speed := 10.0
+ @export var jump_velocity := 5.0
```

Tombol:

```text
[Accept]
[Reject]
[Edit]
```

Acceptance criteria:

- User mengetahui file yang berubah.
- User mengetahui baris yang berubah.
- Perubahan dapat ditolak.
- Perubahan dapat diterapkan sebagian jika memungkinkan.

---

# 17. Error Recovery

AI harus mampu membaca:

```text
Godot stdout
Godot stderr
Exit code
Build status
```

Contoh:

```text
BUILD FAILED

scripts/player.gd:32
Invalid access to property...
```

AI mendapat:

```text
Error
Relevant source file
Relevant surrounding code
Recent diff
Godot version
```

AI kemudian memberikan patch.

---

# 18. Asset Management

Tahap awal:

```text
assets/
├── models/
├── textures/
├── audio/
└── fonts/
```

Upload dari browser:

```text
Browser
  |
  v
Backend
  |
  v
GitHub
```

Jangan mengirim asset besar melalui AI.

AI hanya perlu mengetahui:

```text
filename
type
size
path
optional metadata
```

---

# 19. Security

Ini bagian wajib karena sistem memberikan kemampuan AI untuk mengubah dan menjalankan project.

## Jangan lakukan

```text
AI → arbitrary shell → production server
```

## Gunakan pembatasan

AI hanya boleh:

```text
read/write project directory
```

Untuk command:

```text
Godot validation
Build
Test
```

gunakan workflow yang telah ditentukan.

Jangan memberikan GitHub token dengan permission penuh.

Gunakan prinsip:

```text
least privilege
```

Secrets seperti AI API key dan GitHub credentials tidak boleh masuk source code atau prompt.

---

# 20. GitHub Authentication

User login menggunakan GitHub OAuth.

Konsep:

```text
Browser
   |
   v
GitHub OAuth
   |
   v
Backend
   |
   v
GitHub API
```

Backend harus menyimpan credential dengan aman.

MVP dapat dimulai dengan satu repository yang dikonfigurasi manual sebelum membuat multi-project/multi-user system.

---

# 21. Build Queue

Karena GitHub Runner dapat memiliki antrean:

```text
Build #101
Build #102
Build #103
```

UI harus menunjukkan:

```text
Build #103
Status: QUEUED
Commit: abc123
Target: Web
```

Jangan membuat user mengira browser error ketika runner sedang antre.

---

# 22. Cost Control

GitHub Actions memiliki batas penggunaan tergantung akun/plan.

Optimasi:

- Jangan trigger build pada setiap karakter yang diketik.
- Save tidak otomatis berarti Build.
- Preview hanya ketika user menekan Run.
- Gunakan cache dependency bila memungkinkan.
- Gunakan artifact retention yang wajar.
- Jangan melakukan infinite AI retry.
- Gunakan workflow manual untuk APK/Windows.

Mode:

```text
SAVE
  ↓
GitHub

RUN
  ↓
Web build

BUILD APK
  ↓
Android build
```

---

# 23. Tahap Development Lengkap

## Phase 0 — Proof of Concept

Target:

```text
GitHub
  ↓
Actions
  ↓
Godot Headless
  ↓
Web build
```

Tidak ada AI dan IDE dahulu.

## Phase 1 — Browser IDE

Target:

```text
Browser
  ↓
Monaco
  ↓
GitHub
```

## Phase 2 — Preview

Target:

```text
Browser
  ↓
Run
  ↓
Actions
  ↓
Godot Web
  ↓
Preview
```

## Phase 3 — AI

Target:

```text
AI
  ↓
Read project
  ↓
Generate patch
  ↓
Diff
  ↓
Apply
```

## Phase 4 — AI Agent

Target:

```text
AI
  ↓
Edit
  ↓
Validate
  ↓
Read errors
  ↓
Fix
```

## Phase 5 — Build System

Target:

```text
Web
Android
Windows
```

## Phase 6 — Polish

Tambahkan:

- project dashboard
- build history
- commit history
- diff viewer
- log viewer
- asset browser
- settings
- AI context management
- templates
- project cloning
- rollback
- branch management

---

# 24. Fitur Akhir

Target akhir:

```text
NEKO GODOT AI
│
├── Dashboard
│
├── Projects
│
├── Code Editor
│   ├── GDScript
│   ├── Search
│   └── Diff
│
├── AI Agent
│   ├── Code
│   ├── Explain
│   ├── Fix
│   └── Refactor
│
├── Preview
│   └── Godot Web
│
├── Git
│   ├── Branch
│   ├── Commit
│   └── History
│
├── Build
│   ├── Web
│   ├── Android
│   └── Windows
│
└── Logs
    ├── Godot
    ├── Actions
    └── AI
```

---

# 25. Contoh User Journey

User membuka browser.

```text
1. Login GitHub
2. Create Project
3. Pilih Godot 3D
4. Project dibuat
5. Editor terbuka
```

User berkata:

> Buat game third-person sederhana.

AI:

```text
Create:
scenes/player.tscn
scripts/player.gd
scripts/camera.gd

Modify:
scenes/main.tscn
project.godot
```

User menekan:

```text
[Accept]
```

Lalu:

```text
[RUN]
```

GitHub Actions:

```text
checkout
download Godot
validate
export Web
publish preview
```

Browser:

```text
GAME 3D PREVIEW
```

Kemudian user:

> Tambahkan zombie yang mengejar player.

AI membuat perubahan.

Jika build gagal:

```text
Godot error
    ↓
AI diagnosis
    ↓
patch
    ↓
validation
    ↓
preview
```

Ketika game selesai:

```text
[BUILD APK]
```

Runner menghasilkan:

```text
NekoGame.apk
```

---

# 26. Target MVP Pertama

Jangan membuat AI dahulu.

Milestone pertama harus sesederhana ini:

```text
GitHub Repository
        |
        v
GitHub Actions
        |
        v
Godot Headless
        |
        v
Godot 3D Project
        |
        v
Web Export
        |
        v
Browser
```

Jika ini berhasil, fondasi proyek sudah benar.

Setelah itu baru:

```text
Monaco
   ↓
GitHub
   ↓
Actions
   ↓
Godot
```

dan terakhir:

```text
AI
 ↓
Monaco
 ↓
GitHub
 ↓
Actions
 ↓
Godot
```

---

# 27. Definition of Done

MVP dianggap berhasil jika:

- [ ] Tidak ada Godot yang terinstall di PC pengguna.
- [ ] Project Godot berada di GitHub.
- [ ] GitHub Actions dapat menjalankan Godot Headless.
- [ ] Project 3D berhasil divalidasi.
- [ ] Project berhasil diexport ke Web.
- [ ] Hasil Web dapat dibuka di browser.
- [ ] Monaco dapat mengedit GDScript.
- [ ] Perubahan dapat disimpan ke GitHub.
- [ ] AI dapat membaca file.
- [ ] AI dapat menghasilkan diff.
- [ ] User dapat menerima/menolak diff.
- [ ] AI dapat membuat commit.
- [ ] Build dapat dipicu dari browser.
- [ ] Log build dapat ditampilkan.
- [ ] Build error dapat dikirim kembali ke AI.
- [ ] APK dapat dibuat melalui GitHub Actions.
- [ ] Windows build dapat dibuat melalui GitHub Actions.

---

# 28. Urutan Implementasi yang Direkomendasikan

```text
STEP 01
Godot project 3D minimal
        ↓
STEP 02
GitHub repository
        ↓
STEP 03
GitHub Actions + Godot Headless
        ↓
STEP 04
Godot Web export
        ↓
STEP 05
Browser preview
        ↓
STEP 06
Monaco Editor
        ↓
STEP 07
GitHub file API
        ↓
STEP 08
Save + Commit
        ↓
STEP 09
AI read/write tools
        ↓
STEP 10
AI Diff
        ↓
STEP 11
AI validation loop
        ↓
STEP 12
Build Web
        ↓
STEP 13
Build Android
        ↓
STEP 14
Build Windows
        ↓
STEP 15
Polish + security + optimization
```

---

# 29. Keputusan Teknis Awal

Untuk menghindari perubahan arsitektur terlalu dini:

| Bagian | Pilihan |
|---|---|
| Engine | Godot 4.x |
| Language | GDScript |
| Renderer | Compatibility |
| Editor | Monaco |
| Frontend | React + TypeScript |
| Source Control | GitHub |
| Build | GitHub Actions |
| Engine execution | Godot Headless |
| Preview | Godot Web |
| AI | Coding/agent model dengan tool calling |
| PC requirement | Browser saja |
| Local Godot | Tidak digunakan |
| Local Android SDK | Tidak digunakan |
| Local Windows build tools | Tidak digunakan |

---

# 30. Prinsip Utama Proyek

**"PC kentang hanya menjadi terminal browser. GitHub menjadi workspace. GitHub Runner menjadi mesin Godot. AI menjadi programmer."**

Prioritas:

```text
Stabilitas
   >
Kemudahan penggunaan
   >
Keamanan
   >
Reproducibility
   >
Kecepatan
```

Build yang lambat masih dapat diterima selama:

1. project tetap tersimpan dengan aman,
2. build dapat diulang,
3. error dapat didiagnosis,
4. hasil dapat dipreview,
5. AI dapat membantu memperbaikinya.

