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
- Real-time mode line status:
  - zone symbol (`·`, `:`, `*`, `●`)
  - timer
  - running/paused state
  - progress and accuracy
  - current source label (clickable for source selection)
- Completed text uses high contrast (light theme: black foreground).
- Zone scoring from recent error rate and key-interval stability.
- Session report with accuracy, CPM, interval, and zone metrics.
- Training buffer is text-mode based with soft wrapping.
- Text sources:
  - source directory (`sources/*.txt`) only

## Requirements

- Emacs 27+
- No external runtime dependencies

## Installation

```elisp
(add-to-list 'load-path "/path/to/mutype")
(require 'mutype)
```

## Usage

### Quick Start (Recommended)

1. Run `M-x mutype-mode`.
2. Start typing immediately in the `*MuType*` buffer.

By default, MuType uses:

- `mutype-default-mode`
- `mutype-default-duration-minutes`
- internal source directory (`sources/`)

### Custom Start

Use `M-x mutype-mode-custom` (or `C-u M-x mutype-mode`) to choose:

  - mode (`flow` or `precision`)
  - duration in minutes (`0` means unlimited)
  - source text file from internal `sources/`
Then start typing in the `*MuType*` buffer.

### Session Commands

- `M-x mutype-mode`: start a session
- `M-x mutype-mode-custom`: start with interactive prompts
- `M-x mutype-select-source`: choose source text and restart session
- `M-x mutype-stop`: stop current session
- `M-x mutype-pause`: pause session
- `M-x mutype-resume`: resume session
- `M-x mutype-toggle-pause`: toggle pause/resume
- `M-x mutype-next-source`: switch to next source text and restart session
- `M-x mutype-prev-source`: switch to previous source text and restart session
- `M-x mutype-report-last-session`: open last report

### Training Buffer Keys

- `C-c C-p`: pause/resume
- `C-c C-q`: stop
- `C-c C-n`: switch to next source text
- `C-c C-b`: switch to previous source text
- `SPC` / normal character keys: typing input
- `RET`: typing newline input
- `DEL` / `<backspace>`: move one position back to retype
- Arrow keys and standard navigation commands remain available
- Click the `src:<name>` segment in mode line to pick another source chapter

Typing always follows MuType's sequential training index. If point is moved,
the next input snaps back to the current training position.

## Development Guide

### Project Layout

- `mutype.el`: package implementation (state, input, HUD, zone, report)
- `sources/`: editable training text files (`*.txt`)
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

### Useful Customization

Set defaults in your Emacs config:

```elisp
(setq mutype-default-mode 'flow)
(setq mutype-default-duration-minutes 15)
```

### Source Directory

MuType always reads source files from its internal `sources/` directory.

- File pattern: `*.txt`
- Selection rule for quick start: first valid file by filename sort
- Label rule: filename without extension

Example:

- `sources/001-dickens-tale-of-two-cities-opening.txt`
- `sources/002-austen-pride-and-prejudice-opening.txt`

To add training content, create or edit `.txt` files in the internal source directory.

## Acceptance Matrix

- Mode behavior works:
  - `mutype-mode-starts-with-selected-mode`
- Mode line status updates in session:
  - `mutype-hud-shows-mode-line-status`
- Error feedback is non-blocking in flow mode:
  - `mutype-flow-advances-on-error`
- Text source switching works:
  - `mutype-source-switching`
