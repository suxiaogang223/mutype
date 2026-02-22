# MuType

MuType is a minimal typing practice loop for Emacs. It is designed for calm rhythm,
low-distraction focus, and steady flow (not a speed competition).

![MuType session](docs/screenshots/mutype-session.png)

Requirements: Emacs 25.1+ (no external runtime dependencies).

## Install

### MELPA (recommended)

Once the MuType recipe is available on MELPA, install it with:

- `M-x package-install RET mutype RET`

If you don't have MELPA enabled:

```elisp
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
```

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

## Start

Run `M-x mutype-mode` to jump into `*MuType*` and start typing.

To choose mode, duration, and text source, use `C-u M-x mutype-mode` or
`M-x mutype-mode-custom`.

Modes:

- `flow`: mistakes do not block progress.
- `precision`: you must type the correct character to advance.

## During a Session

The MuType HUD lives in the mode line and shows:

- zone symbol (`·`, `:`, `*`, `●`)
- timer and state (`running`/`paused`)
- progress, accuracy, and current source label (clickable)

Common keys and commands:

| Key / Command | Action |
| --- | --- |
| `C-c C-p` | Pause/resume |
| `C-c C-q` | Stop session |
| `C-c C-n` | Next source (restart) |
| `C-c C-b` | Previous source (restart) |
| `M-x mutype-select-source` | Pick a source (restart) |
| `M-x mutype-report-last-session` | Open the last report |

Typing always follows MuType's sequential index. If point is moved, input snaps
back to the current training position.

## Text Sources

MuType intentionally reads plain text from the bundled `sources/*.txt` directory
inside the package.

To add or tweak training text, edit or add `.txt` files under `sources/`. Since
this directory is part of the installed package, upgrades may overwrite local
changes. Keep a copy of your custom texts if you maintain your own set.

## Customization

Put something like this in your init file:

```elisp
(setq mutype-default-mode 'flow
      mutype-default-duration-minutes 15
      mutype-enable-guidance-text t
      mutype-prompt-on-start nil)
```

## Report

MuType shows a report buffer when you stop a session or when the time limit is
reached. Reopen the last report with `M-x mutype-report-last-session`.

## Development

Implementation notes live in `docs/IMPLEMENTATION.md`.

Useful commands:

- Load check: `emacs --batch -Q -L . --eval "(progn (load \"mutype.el\") (message \"ok\"))"`
- Byte compile: `emacs --batch -Q --eval "(byte-compile-file \"mutype.el\")"`
- Tests: `emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit`

## Name

MuType means "type into stillness". The name emphasizes attention to the current
character, not speed competition.

## License

MuType is licensed under the MIT License. See [LICENSE](LICENSE) for details.
