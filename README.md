# MuType

MuType is a minimal typing practice plugin for Emacs, designed to help users enter focus and flow through a steady rhythm.

## Project Status

- Current phase: MVP implemented
- Target platform: Emacs 27+
- Tech stack: Emacs Lisp (pure implementation)

## Implemented Features

- `Flow` mode: mistakes do not block progress
- `Precision` mode: correct input is required to advance
- Real-time HUD with zone symbol, timer, and guidance text
- Zone scoring based on recent error rate and rhythm stability
- Session lifecycle: start, pause/resume, stop, auto-finish
- Session report with accuracy, CPM, average interval, and zone stats
- Multiple text sources: built-in text / current buffer / file

## Quick Start

Add MuType to your Emacs load path and require it:

```elisp
(add-to-list 'load-path "/path/to/mutype")
(require 'mutype)
```

Start a session:

- `M-x mutype-mode`

You will be prompted for:

- Mode (`flow` or `precision`)
- Duration (minutes, `0` for unlimited)
- Text source (`builtin`, `current-buffer`, or `file`)

## Commands

- `M-x mutype-mode`: start a session
- `M-x mutype-stop`: stop the current session
- `M-x mutype-pause`: pause the current session
- `M-x mutype-resume`: resume a paused session
- `M-x mutype-toggle-pause`: toggle pause state
- `M-x mutype-report-last-session`: show the latest report

## Training Buffer Keys

- `C-c C-p`: pause/resume
- `C-c C-q`: stop session
- `C-g`: stop session

## Tests

Run ERT tests in batch mode:

```bash
emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit
```

## Project Layout

- `mutype.el`: core implementation (MVP)
- `test/mutype-test.el`: ERT tests
