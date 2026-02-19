# WuType

```text
__        __  _   _  _____ __   _______  ______
\ \      / / | | | ||_   _|\ \ / /  __ \|  ____|
 \ \ /\ / /  | | | |  | |   \ V /| |__) | |__
  \ V  V /   | |_| |  | |    | | |  ___/|  __|
   \_/\_/     \___/   |_|    |_| |_|    |_____|
```

WuType is a minimal typing practice experience for Emacs, focused on rhythm, attention, and flow.  
Current package/command namespace in code is `mutype-*`.

## Features

- Two practice modes:
  - `flow`: mistakes do not block progress
  - `precision`: correct input is required to advance
- Real-time HUD with zone symbol, timer, and guidance text
- Zone scoring based on recent error rate and interval stability
- Session report with accuracy, CPM, interval, and zone summary
- Text sources: built-in text, current buffer, or a file

## Requirements

- Emacs 27+
- No external runtime dependencies

## How To Use

1. Add this repository to your Emacs load path and require the package:

```elisp
(add-to-list 'load-path "/path/to/mutype")
(require 'mutype)
```

2. Start a session:

- `M-x mutype-mode`

3. During training:

- `C-c C-p`: pause/resume
- `C-c C-q`: stop
- `C-g`: stop

4. Useful commands:

- `M-x mutype-stop`
- `M-x mutype-pause`
- `M-x mutype-resume`
- `M-x mutype-toggle-pause`
- `M-x mutype-report-last-session`

## Development Guide

### Project Layout

- `mutype.el`: core implementation (session, input, HUD, zone, report)
- `test/mutype-test.el`: ERT tests
- `AGENTS.md`: contributor guide and collaboration rules

### Development Commands

- Load check:
  - `emacs --batch -Q -L . --eval "(progn (load \"mutype.el\") (message \"ok\"))"`
- Byte-compile check:
  - `emacs --batch -Q --eval "(byte-compile-file \"mutype.el\")"`
- Test:
  - `emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit`

### Coding Conventions

- Keep documentation and code comments in English.
- Use `mutype-*` for public symbols and `mutype--*` for internal helpers.
- Keep functions focused and add tests for behavior changes.
- Target Emacs Lisp style with lexical binding and standard indentation.

## Status

MVP is implemented and testable. Further iterations can split modules (`mutype-zone.el`, `mutype-render.el`, etc.) as complexity grows.
