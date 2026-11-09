<div align="center">

# ✳ GG Developer Studio

**A workspace for creating Lua projects inside GameGuardian.**  
Build menus, use templates and assemble scripts without leaving the studio.

[![Version](https://img.shields.io/badge/version-0.23-7c5cff?style=for-the-badge)](manifest.json)
[![Lua](https://img.shields.io/badge/Lua-100%25-2C2D72?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org)
[![Platform](https://img.shields.io/badge/Android-GameGuardian-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://gameguardian.net)
[![License](https://img.shields.io/badge/license-MPL--2.0-e0407a?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/nearzvx/GGDevStudio?style=for-the-badge&color=ffcc33)](https://github.com/nearzvx/GGDevStudio/stargazers)

[**Русский**](README.md) · [**Website**](https://ggstudio.freedev.app) · [**Download**](https://github.com/nearzvx/GGDevStudio/blob/main/GG_Developer_Studio.lua) · [**Report an issue**](https://github.com/nearzvx/GGDevStudio/issues/new)

</div>

---

```text
  ✳  GG DEVELOPER STUDIO  ·  workspace                    v0.23
  ──────────────────────────────────────────────────────────────
  project    my_next_idea.ggds        Lua · UTF-8 · GameGuardian
  blocks     interface templates
             string templates
             custom Lua code          ← yours
  check      syntax validation
  build      → Download/my_next_idea_generated.lua
  ──────────────────────────────────────────────────────────────
  ● READY TO CREATE
```

<div align="center"><sub>One idea can change everything. Developer: BinaryMoon.</sub></div>

---

## ✨ What is it?

**GG Developer Studio** is a Lua project-building tool that runs inside **GameGuardian** on Android. It helps you organise projects, create menus and assemble Lua scripts on your device.

> Complex tasks. Simple tools.

## ✦ Features

| | Module | What it does |
|---|---|---|
| ⌘ | **Projects** | Create and manage `.ggds` projects |
| ▦ | **Library** | Explore **350 templates** for menus, strings, files, debugging and the GameGuardian API |
| ⚡ | **Build** | Assemble project items and Lua blocks into a script with a menu |
| ⌁ | **Tools** | Check syntax, compare files, search, and manage notes and tasks |
| ◈ | **Project radar** | Review the project's saved state, tasks, placeholders and TODO markers |
| ✳ | **Custom code** | Add Lua blocks alongside templates |
| ⛨ | **Backups** | Save a separate copy of a project |

Syntax checks, where available, do **not** guarantee that custom code is safe or behaves correctly. Review code before running it.

## 🚀 Getting started

### 01 · Download

Open [the studio file on GitHub](https://github.com/nearzvx/GGDevStudio/blob/main/GG_Developer_Studio.lua), select **Download raw file**, and save it on your Android device.

### 02 · Run in GameGuardian

```text
Download/
└── GG_Developer_Studio.lua   →  open with GameGuardian
```

An internet connection to the public GitHub repository is required for the startup update check. The Lua file can be run on its own; no separate access file is required.

### 03 · Create

```text
New project  →  add templates  →  edit your code  →  build  →  Lua script
```

Projects, notes, tasks and generated files are stored in **`Download`**. Keep backups of any files you want to preserve.

## 📚 Template library

The studio contains **350 examples**, covering:

- **Interfaces:** choices, menus, dialogs and notifications
- **Strings and tables:** formatting, parsing and common operations
- **Files:** reading, writing and paths
- **GameGuardian API:** common calls and read-only examples
- **Debugging:** checks, formatting and action stubs

Templates are starting points. Review and adapt them for your project.

## ⚙️ Requirements

| Requirement | Details |
|---|---|
| Device | Android |
| Environment | [GameGuardian](https://gameguardian.net) |
| Internet | Required to check `manifest.json` on GitHub at startup |
| Storage | Permission to read and write in `Download` |
| Version | `0.23` (see `manifest.json`) |

Compatibility depends on the device and GameGuardian version. If GitHub is unreachable, startup stops with a message. The release and the minimise/restore feature have been tested in a simulated Lua environment, but still need testing on actual devices.

## 🌐 Languages

At startup, choose Russian, English (US), English (UK), Simplified Chinese or Arabic. The two English options currently use the same translation.

**Translation is incomplete:** the main screen and core commands are translated, but some messages and template names remain in Russian. User code and project data are not translated. The language is selected again on each launch.

## 📁 Repository structure

```text
GGDevStudio/
├── GG_Developer_Studio.lua   # Lua studio script
├── manifest.json             # release version
├── README.md                 # Russian documentation
├── README_EN.md              # English documentation
├── modules/                  # module list and Lua modules
├── examples/                 # example data
└── LICENSE                   # MPL-2.0
```


## 🆕 Release notes

### 0.23

- Quick Lab now has **150 small operations**, and 50 matching examples bring the library to **350 templates**.
- Ten new modules bring the total to **15**: Code Search, Title Check, Duplicate Blocks, API Inventory, Marker Board, Syntax Batch, Line Review, Project Outline, Config Builder and Menu Builder. The latter two turn text data into Lua blocks after confirmation. Use generated local tables inside the inserted block.
- Analyses are heuristic and are not complete security reviews. New labels and messages are mostly in Russian; byte/ASCII operations are not full Unicode handling.

### 0.22 · Module Hub

Extract the **`modules`** folder from the release archive into `Download`, so `Download/modules/modules.txt` and the 15 Lua files are together. Optional CSV/TSV examples are in `examples`. Approve trusted modules at startup, then open **Tools → Module Hub**. The studio can run without modules; use the hub to inspect errors or reload them.

The original five modules provide project metrics, text-based code auditing, a literal `require` dependency map, CSV-to-Lua conversion and TSV translation-table generation. Analysis is heuristic and does not guarantee security or completeness. CSV and TSV are data, not executable code; adding generated Lua requires confirmation. Generated tables are local to the added block. CSV fields are strings.

**Trust:** modules are unsandboxed Lua with the studio's full privileges and are not checked against GitHub. Load only files you trust. The automatic updater updates **only the main studio file**; install or update modules separately from the release archive. Publish the `modules` folder and `modules.txt` with the repository files.

GameGuardian cannot normally start an external Python interpreter and blocks `os.execute`; direct Python modules are not supported. Instead, prepare CSV or TSV in Python and import those data files with the supplied Lua modules.

To add a module, put its ID (letters, digits, `_` or `-`) in `modules.txt` and provide `<ID>.lua` in the same folder, then reload. Up to 32 entries are loaded. Return a table: `return {name = 'Name', run = function(ctx) ... end}`. Context offers `project` (a snapshot or `nil`), `root`, `read_file(path, limit)`, `alert(text)`, `report(text)` and `offer_code(title, code, info)`. Modules still have access to globals and are not sandboxed.

### 0.21

- If GameGuardian returns an unreadable path containing `?`, select the studio file manually. The selected file is checked; in this situation the app cannot verify it is the file actually running.

### 0.20

- Added **Quick Lab**: 100 small tools for text, numbers, encoding, lists and paths. Results can be copied without modifying the input.
- Added 100 templates demonstrating those same transformations in Lua, bringing the library to 350 templates.
- Refreshed the main screen. Some new labels remain in Russian when another language is selected.
- Case conversion, lengths and reversal use ASCII/bytes rather than full Unicode characters.

### 0.19

- With user consent, the studio downloads a new release to `Download`. Run the new file in GameGuardian and delete the old one manually **after the new version starts successfully**.
- At startup, the current file is compared byte-for-byte with the official GitHub file. This checks content equality, **not the file’s download origin**. GitHub caching can cause temporary mismatches after a release.
- External text Lua files can be syntax-checked and, if `string.dump` is supported, compiled to `.luac` bytecode without executing the source. Bytecode may not be compatible with other Lua or GameGuardian versions.

### 0.18

- Added a language selector at startup and initial interface translations.
- Translation coverage is still incomplete; see **Languages** above.

### 0.17

- Added a GitHub download-link option. In 0.19 this is offered when file integrity does not match.
- Startup stops when the installed version is outdated or the update check cannot be completed.

### 0.16

- Added the BinaryMoon developer credit, minimise/restore, studio search and project radar.
- Expanded the template library.

### Publishing an update

Upload the new `GG_Developer_Studio.lua` to the root of the `main` branch, then update `manifest.json` to the same version. The studio file and manifest must have matching version numbers. GitHub may temporarily serve cached files after publishing.

## 🗺️ Roadmap

- [x] Projects, templates and in-studio builds
- [x] Syntax checks, file comparison, tasks and notes
- [x] 350 templates
- [ ] Improve the build engine and module management
- [ ] Add more debugging tools

Have an idea? [Open an issue](https://github.com/nearzvx/GGDevStudio/issues/new).

## ❓ FAQ

<details><summary><b>Do I need an internet connection?</b></summary>

Yes. The studio checks the GitHub manifest at startup and stops if it cannot complete the check.
</details>

<details><summary><b>Where are my projects stored?</b></summary>

In `Download`, along with notes, tasks and generated scripts. Keep your own backups.
</details>

<details><summary><b>Can I switch back to GameGuardian?</b></summary>

Use the minimise option, then tap the GameGuardian icon to return to the studio. Behaviour may depend on your GG version.
</details>

## 🤝 Contributing

1. Fork the repository and create a feature branch.
2. Keep commits focused and describe your changes in the pull request.
3. For bugs, include reproduction steps, the studio version and your device model.

Templates, translations, documentation and ideas are welcome.

## ⚠️ Disclaimer

This project is a development tool. Use it in accordance with GameGuardian's rules and applicable laws. You are responsible for the content and behaviour of scripts you create.

## 📄 License

Distributed under the **Mozilla Public License 2.0**; see [LICENSE](LICENSE).

<div align="center">

**YOUR NEXT IDEA STARTS HERE ↗**

[ggstudio.freedev.app](https://ggstudio.freedev.app) · [@nearzvx](https://github.com/nearzvx)

<sub>Made with Lua, pain and inspiration ✳</sub>

</div>
