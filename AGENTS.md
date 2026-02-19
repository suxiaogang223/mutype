# Repository Guidelines

## Project Structure & Module Organization

MuType is currently a small Emacs Lisp project with an MVP layout:

- `mutype.el`: main package entry and core logic (session state, input handling, HUD, zone scoring, reporting).
- `test/mutype-test.el`: ERT test suite for core behavior.
- `README.md`: user-facing setup and usage guide.

Keep feature code in `mutype.el` until a clear module split is introduced. If you split modules later, keep file names aligned with responsibilities (for example `mutype-zone.el`, `mutype-render.el`).

## Build, Test, and Development Commands

- `emacs --batch -Q -L . --eval "(progn (load \"mutype.el\") (message \"ok\"))"`: sanity-load check.
- `emacs --batch -Q --eval "(byte-compile-file \"mutype.el\")"`: byte-compile check for syntax/warnings.
- `emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit`: run all tests.

Run load and test commands before opening a PR.

## Coding Style & Naming Conventions

- Language: Emacs Lisp (target Emacs 27+), `lexical-binding` enabled.
- Indentation: follow standard Emacs Lisp style (2-space indentation, aligned forms).
- Naming:
  - Public symbols: `mutype-*`
  - Internal helpers: `mutype--*`
- Keep comments and documentation in English.
- Prefer small, focused functions and avoid adding external dependencies.

## Testing Guidelines

- Framework: ERT.
- Test files should live under `test/` and use `*-test.el` suffix.
- Test names should describe behavior, e.g. `mutype-flow-advances-on-error`.
- Add or update tests for any change in input logic, zone scoring, session state, or reporting output.

## Commit & Pull Request Guidelines

- Use imperative commit messages, consistent with existing history (example: `Initialize MuType MVP`).
- Keep one logical change per commit.
- PRs should include:
  - What changed and why.
  - How it was tested (exact commands).
  - Any user-visible behavior change (HUD, commands, workflow).
- Link related issues when available.
