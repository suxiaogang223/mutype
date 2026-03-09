<div align="center">

# 🌿 MuType

**Type into stillness. Calm rhythm. Low distraction. Steady flow.**

[![中文说明](https://img.shields.io/badge/README-中文-blue)](README.zh-CN.md) [![MELPA](https://melpa.org/packages/mutype-badge.svg)](https://melpa.org/packages/mutype) ![Requires: Emacs 25.1+](https://img.shields.io/badge/Requires-Emacs%2025.1%2B-7F5AB6) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

</div>

---

## 📖 What is MuType?

> *菩提本无树，明镜亦非台；*  
> *本来无一物，何处惹尘埃？*  
> 
> — Huineng  
> “Originally there is not a single thing—where could dust alight?”

The name **“MuType”** can be read as “type into stillness”. “Mu” comes from the Chinese character “無” (simplified: “无”), literally “not / without”.

In Chan/Zen, “mu” points to letting go of rigid judgments and returning to a clear, unforced mind. MuType uses this as a reminder: **focus on the current character, keep a calm rhythm, and let mistakes pass.**

MuType is a minimal typing practice loop for Emacs. It aims to keep you in a calm, steady rhythm: focus on the current character and keep moving.

MuType provides two practice modes:
- `flow`: mistakes do not block progress.
- `precision`: you must type the correct character to advance.

## 📸 Demo

<div align="center">
  <img src="docs/screenshots/mutype-session.png" alt="MuType session" />
</div>

## ✨ Features

- 🧘 **Zen Philosophy**: Minimalist design, focused on the present moment with `flow` and `precision` modes.
- 📊 **HUD in the Mode Line**: Real-time timer, progress, accuracy, and zone indicators (`·`, `:`, `*`, `●`).
- 📚 **Diverse Practice Sources**:
  - **Classic Literature**: Famous works by Dickens, Austen, Shakespeare, etc.
  - **Chinese Treasures**: *Tao Te Ching*, Tang poems, and modern prose.
  - **Programming Snippets**: Idiomatic Elisp, Python, and more.
- 🚀 **Instant Reports**: Automatic detailed performance analysis at session end.

## 🚀 Install

### MELPA (recommended)

MuType is available on MELPA. Install it with:

```elisp
M-x package-install RET mutype RET
```

<details>
<summary>If you don't have MELPA enabled</summary>

```elisp
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
```
</details>

### Manual (load-path)

```elisp
(add-to-list 'load-path "/path/to/mutype")
(require 'mutype)
```

### straight.el (optional)

```elisp
(use-package mutype
  :straight (mutype :type git :host github :repo "suxiaogang223/mutype")
  :commands (mutype-mode mutype-mode-custom))
```

## 🎮 Start

- `M-x mutype-mode` starts quickly with defaults.
- `C-u M-x mutype-mode` or `M-x mutype-mode-custom` lets you pick mode/duration/source.

## ⌨️ During a Session

The MuType HUD lives in the mode line and shows:
- **Zone symbol** (`·`, `:`, `*`, `●`)
- **Timer and state** (`running`/`paused`)
- **Progress, accuracy, and current source label** (clickable)

### Common Keys & Commands

| Key / Command | Action |
| :--- | :--- |
| `C-c C-p` | Pause / Resume |
| `C-c C-q` | Stop session |
| `C-c C-n` | Next source (restart) |
| `C-c C-b` | Previous source (restart) |
| `M-x mutype-select-source` | Pick a source (restart) |
| `M-x mutype-report-last-session` | Open the last report |

> **Note**: Typing always follows MuType's sequential index. If point is moved, input snaps back to the current training position.

## 📝 Text Sources

MuType intentionally reads plain text from the bundled `sources/*.txt` directory inside the package.

To add or tweak training text, edit or add `.txt` files under `sources/`. Since this directory is part of the installed package, upgrades may overwrite local changes—**keep a copy of your custom texts.**

## ⚙️ Customization

Put something like this in your init file:

```elisp
(setq mutype-default-mode 'flow
      mutype-default-duration-minutes 15
      mutype-enable-guidance-text t
      mutype-prompt-on-start nil)
```

## 📈 Report

MuType shows a report buffer when you stop a session or when the time limit is reached. Reopen the last report with `M-x mutype-report-last-session`.

## 🛠️ Development (optional)

Useful commands:
- **Load check**: `emacs --batch -Q -L . --eval "(progn (load \"mutype.el\") (message \"ok\"))"`
- **Byte compile**: `emacs --batch -Q --eval "(byte-compile-file \"mutype.el\")"`
- **Tests**: `emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit`

## 📜 License

MuType is licensed under the MIT License. See [LICENSE](LICENSE) for details.
