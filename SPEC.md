# MuType Specification

## Overview
MuType is a minimalist typing practice tool for Emacs, designed to help users enter a "flow" state through calm, low-distraction practice. It draws inspiration from Zen philosophy, emphasizing presence and steady rhythm.

## Core Philosophies
- **Type into Stillness**: The interface should be as clean as possible.
- **Steady Flow**: Progress is measured not just by speed, but by the stability of the typing rhythm.
- **Zero Distraction**: No intrusive popups or complex UI during the session; status is confined to the mode-line.

## Functional Requirements

### 1. Practice Modes
- **Flow Mode**: Keystrokes advance the cursor even on errors. Mistakes are visually marked but do not block the user.
- **Precision Mode**: The user must type the correct character to advance the cursor.

### 2. Session Lifecycle
- **Initialization**: Users start a session via `mutype-mode` or `mutype-mode-custom`.
- **Input Handling**: Intercepts `self-insert-command`, `RET`, and `DEL`.
- **Termination**: Sessions end when the timer expires or the text is completed. A report is automatically generated.
- **Pause/Resume**: Users can toggle the session state, freezing the timer and input.

### 3. Source Management
- **Bundled Sources**: Built-in texts located in the `sources/` directory.
- **Extensibility**: Support for user-defined source directories (via `mutype-user-source-directory`).
- **Diversity**: Support for classic literature, Chinese poetry, and programming code snippets.

### 4. Metrics & Zone Algorithm
- **Accuracy**: (Correct Characters / Total Keystrokes) * 100.
- **Speed**: Characters Per Minute (CPM) and Words Per Minute (WPM).
- **Zone Level**: A dynamic indicator (·, :, *, ●) derived from:
  - **Stability**: Coefficient of variation of recent typing intervals.
  - **Accuracy**: Recent error rate.
- **Report**: A summary buffer showing WPM, Accuracy, Session Duration, and Zone distribution.

## Technical Architecture

### Data Structures
- `mutype-session` (cl-defstruct): Tracks the state of the active training loop, including timing, index, and event logs.

### UI Components
- **Training Buffer**: A dedicated buffer with custom faces for "done", "pending", "current", and "error" characters.
- **HUD (Mode-line)**: A compact display showing zone, timer, progress, and source label.

### Key Commands
- `C-c C-p`: Pause/Resume.
- `C-c C-q`: Stop session.
- `C-c C-n` / `C-c C-b`: Switch to the next/previous source text.

## Development Standards
- **Language**: Emacs Lisp (lexical-binding: t).
- **Compatibility**: Emacs 25.1+.
- **Testing**: Regression testing via `ERT`.
