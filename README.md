# MuType

```text
M u T y p e
     .
   .   .
     .
```

MuType is a minimal typing practice plugin for Emacs.  
It is designed for calm rhythm, low-distraction focus, and steady flow.

## Name Meaning

`MuType` means "type into stillness."

- `Mu` references quietness and emptiness in a Zen context.
- `Type` is the physical practice of keystrokes.
- Together, the name emphasizes attention to the current character, not speed competition.

## Features

- Two modes:
  - `flow`: mistakes do not block progress.
  - `precision`: correct input is required to move forward.
- Real-time HUD:
  - zone symbol (`·`, `:`, `*`, `●`)
  - timer
  - guidance text
- Zone scoring from recent error rate and key-interval stability.
- Session report with accuracy, CPM, interval, and zone metrics.
- Text sources:
  - built-in text
  - current buffer
  - file

## Requirements

- Emacs 27+
- No external runtime dependencies

## Installation

```elisp
(add-to-list 'load-path "/path/to/mutype")
(require 'mutype)
```

## Usage

1. Run `M-x mutype-mode`.
2. Choose:
  - mode (`flow` or `precision`)
  - duration in minutes (`0` means unlimited)
  - text source (`builtin`, `current-buffer`, or `file`)
3. Start typing in the `*MuType*` buffer.

### Session Commands

- `M-x mutype-mode`: start a session
- `M-x mutype-stop`: stop current session
- `M-x mutype-pause`: pause session
- `M-x mutype-resume`: resume session
- `M-x mutype-toggle-pause`: toggle pause/resume
- `M-x mutype-report-last-session`: open last report

### Training Buffer Keys

- `C-c C-p`: pause/resume
- `C-c C-q`: stop
- `C-g`: stop

## Development Guide

### Project Layout

- `mutype.el`: package implementation (state, input, HUD, zone, report)
- `test/mutype-test.el`: ERT test suite
- `docs/IMPLEMENTATION.md`: implementation notes and design mapping
- `AGENTS.md`: contributor workflow guidelines

### Build and Test Commands

- Load check:
  - `emacs --batch -Q -L . --eval "(progn (load \"mutype.el\") (message \"ok\"))"`
- Byte compile:
  - `emacs --batch -Q --eval "(byte-compile-file \"mutype.el\")"`
- Run tests:
  - `emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit`

### Coding Rules

- Keep public symbols under `mutype-*`.
- Keep internal helpers under `mutype--*`.
- Keep comments and docs in English.
- Add ERT tests for behavior changes.

## Acceptance Matrix

- Mode behavior works:
  - `mutype-mode-starts-with-selected-mode`
- HUD updates in session:
  - `mutype-hud-shows-zone-and-paused-status`
- Error feedback is non-blocking in flow mode:
  - `mutype-flow-advances-on-error`
- Text source switching works:
  - `mutype-source-switching`
