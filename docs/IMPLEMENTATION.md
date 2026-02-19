# MuType Implementation Notes

## Goal

MuType provides a low-distraction typing practice loop in Emacs with two modes:

- `flow`: continue on mistakes
- `precision`: block on mistakes

The package is implemented in pure Emacs Lisp for Emacs 27+.

## Core Data Model

`mutype-session` (`cl-defstruct`) stores:

- session lifecycle state (`running`, `paused`, `finished`, `aborted`)
- source metadata (`source-type`, `source-label`, `text`)
- typing progress (`index`, `total-count`, `correct-count`, `error-count`)
- timing (`start-time`, `end-time`, `duration-limit`, `last-input-time`)
- zone metrics (`recent-intervals`, `recent-errors`, `zone-score`, `zone-level`)
- runtime resources (`timer`, `buffer`)

## Session Lifecycle

1. `mutype-mode` creates a session and opens `*MuType*`.
2. `mutype--dispatch-input` routes keypresses to `mutype--handle-input`.
3. `mutype--tick` refreshes HUD and enforces time-limit/buffer-close termination.
4. `mutype--finish-session` finalizes, cancels timer, builds report, and shows report buffer.

Pause/resume is implemented by moving `start-time` forward during resume so paused duration is excluded from elapsed time.

## Source Handling

Sources are normalized into a plist of `:type`, `:label`, `:text`:

- `mutype--source-from-builtin`
- `mutype--source-from-buffer`
- `mutype--source-from-file`

All source text runs through `mutype--normalize-text` to standardize newlines and enforce minimum length.

## Zone Algorithm

Inputs for a sliding window (`mutype-zone-window-size`):

- recent error bits (0 or 1)
- recent key intervals

Computation:

- error component: `1 - error-rate`
- stability component: `1 - (cv / 0.6)` clamped to `[0, 1]`
- weighted score: `0.55 * error + 0.45 * stability`
- smoothing: `smoothed = 0.3 * raw + 0.7 * previous`
- level mapping:
  - `< 0.45` => 0 (`·`)
  - `< 0.65` => 1 (`:`)
  - `< 0.82` => 2 (`*`)
  - otherwise => 3 (`●`)

## Acceptance Mapping

- Mode switching: `mutype-mode-starts-with-selected-mode`
- Real-time HUD update: `mutype-hud-shows-zone-and-paused-status`
- Non-blocking error feedback in flow mode: `mutype-flow-advances-on-error`
- Source switching: `mutype-source-switching`

## Test Command

```bash
emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit
```
