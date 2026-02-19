# AGENTS.md

This file defines the default collaboration conventions for the MuType repository.

## Goals

- Keep implementation aligned with the product design specification.
- Prioritize readability, maintainability, and testability.
- Implement features in Emacs Lisp with minimal dependencies.

## Code Conventions

- Target version: Emacs 27+
- Prefer `cl-defstruct`, `defcustom`, and `define-minor-mode`
- Use the `mutype-` prefix for public functions
- Add ERT tests for new behavior whenever practical

## Commit Conventions

- Use imperative commit messages focused on one logical change
- Do not mix unrelated refactors with feature changes in one commit
- Run at least one basic load or test check before committing

## Documentation Conventions

- Keep README content user-facing
- Keep design/implementation docs developer-facing
- Record key design decisions in documentation
