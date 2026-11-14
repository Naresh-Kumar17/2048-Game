# 2048 – Slide & Merge Puzzle (x86 MASM, Irvine32) – complete project

EL-2003 COAL Lab, Fall 2026 · Group BDS-3A
Syed Burhan Hussain Shah (25K-2518) · Naresh Kumar (25K-2501) · Aryaan Taimur (25K-2540)

All nine modules of the proposal are implemented. **Nothing here has been assembled yet**:
build it, fix any first-build typos module by module, and run the tests.

## 1. Files of the game (one Visual Studio project)

| File | Owner | Contains | Item Type |
|---|---|---|---|
| `data.asm` | Burhan | all shared variables, flags | Microsoft Macro Assembler |
| `game_macros.inc` | Burhan | constants, key/menu codes, `mGoto` | Does not participate in build |
| `module.inc` | everyone | PROTOs of all procedures | Does not participate in build |
| `logic.asm` | Burhan | M2 board setup, M5 `SlideLine`, M6 `MoveBoard` | Microsoft Macro Assembler |
| `spawn.asm` | Naresh | M7 random tile spawner | Microsoft Macro Assembler |
| `state.asm` | Naresh | M8 score, win, game over; M9 undo, restart; best-score file | Microsoft Macro Assembler |
| `ui.asm` | Aryaan | M1 menu and help, M3 renderer, win and game-over messages | Microsoft Macro Assembler |
| `input.asm` | Aryaan | M4 key handling | Microsoft Macro Assembler |
| `main.asm` | Aryaan | entry point and the whole game loop | Microsoft Macro Assembler |

Only `main.asm` ends with `END main`; every other `.asm` ends with a plain `END`.
Project setup: Visual Studio 2026, 32-bit MASM, Irvine32 configured as in the lab,
`game_macros.inc` and `module.inc` in the project folder.

## 2. How the game works

- **Menu:** New Game, Help, Exit. New Game asks for N (3 to 8). Target tile: 512 for 3x3, 2048 otherwise.
- **Keys:** arrows or WASD move, U undo (one level), R restart with the same N, Q back to the menu.
- **One move:** `ApplyMove` takes a snapshot, `MoveBoard` calls `SlideLine` once per line, and if the board changed it commits the undo backup, adds the score and spawns one tile (2 at 90%, 4 at 10%). A move that changes nothing does nothing at all.
- **After each move:** `IsGameOver` tries all four directions on the board and restores it. Then `CheckWin` shows the win message once per game and play continues.
- **Game over:** shows the final score. Only U, R and Q work then.
- **Best score:** kept for the session and saved to `best2048.dat` (4 bytes) in the working folder when you quit or exit. If the file cannot be opened the game just carries on.

## 3. Week 3 and 4 tasks (what is new since week 2)

| Who | Week | Branch | Phase | Commit message |
|---|---|---|---|---|
| Naresh | 3 | `feature/m8-win` | M8-P3 `CheckWin` | `M8-P3: win detection` |
| Naresh | 3 | `feature/m8-gameover` | M8-P4 `IsGameOver`, `CopyCells` (needs M5-P4 merged) | `M8-P4: game over via scratch copy` |
| Naresh | 3 | `feature/m9-undo-restart` | M9-P1 snapshot and `UndoMove` | `M9-P1: one-level undo` |
| Naresh | 3 | | M9-P2 `RestartGame` | `M9-P2: restart with same N` |
| Naresh | 3 | `feature/best-file` | optional best-score file | `Optional: best score file` |
| Aryaan | 3 | `feature/status-messages` | `ClearStatus`, `ShowWin`, `ShowGameOver` in `ui.asm` | `Week3: status row messages` |
| Aryaan | 3 | `feature/final-loop` | final `main.asm` (win, game over, undo, restart) | `Week3: complete game loop` |
| Aryaan | 3 to 4 | `docs/report` | colour and help polish, IEEE report draft then final | `Report: draft` / `Report: final` |
| Burhan | 3 | `feature/edge-cases` | N = 3 to 8 edge cases in `SlideLine` and `MoveBoard`, comments, refactoring | `Week3: edge cases and comments` |
| Naresh | 4 | `test/results` | run all test cases on every board size, fill the Result column | `Week4: test results` |
| Burhan | 4 | `release` | bug fixes, final build, merge `dev` into `main`, tag `final` | `Release: final build` |
| All | 4 | | rehearse demo and viva | |

Dates: week 3 is 9 to 18 Nov, week 4 is 19 to 22 Nov. Merge order in `dev`:
status messages and M8-P3/M9 first, M8-P4 after M5-P4, then the final `main.asm`.

## 4. Test projects (separate from the game, never add `data.asm` to them)

| Test file | Add these files | Expected |
|---|---|---|
| `tests/test_board.asm` | itself + `logic.asm` | 7 PASS + interactive size input |
| `tests/test_slideline.asm` | itself + `logic.asm` | `Passed: 15 of 15` |
| `tests/test_moveboard.asm` | itself + `logic.asm` | 14 PASS |
| `tests/test_spawn.asm` | itself + `spawn.asm` | 13 PASS |
| `tests/test_state.asm` | itself + `logic.asm` + `spawn.asm` + `state.asm` | 24 PASS |
| `tests/test_ui.asm` | itself + `ui.asm` + `input.asm` | manual: menu, colours, key codes |

`game_macros.inc` and `module.inc` must be in each test project's include path.

## 5. Final run of the 20 cases (`docs/test_cases.md`)

Play the finished game and fill the Result column. Shortcuts for the cases that are hard to reach by hand:

- **Set up a board:** break after New Game, Debug, Windows, Memory, address `board`, edit DWORDs (row-major), press F5.
- **Win (TC18):** set `target` to 8 in the memory window, then merge two 4s. The message appears once and play continues.
- **Game over (TC19):** game over is checked only after a move that changes the board. Start a 3x3 game and put these 9 values in `board`: `8 16 8 16 8 16 32 64 0`. Press Right (or D): row 2 becomes `0 32 64`, the spawned 2 or 4 fills the last cell, no pair exists, and "GAME OVER" appears with the final score. Then check that arrows do nothing, and that U, R and Q work. For the "not game over" case use `8 16 8 16 8 16 32 64 0` but with the last row `2 2 0`, press Right, and play continues.
- **Undo / restart (TC20):** play two moves, press U (board and score return), press U again (nothing), press R (fresh board, score 0, best score kept).

## 6. Known assumptions

- `ReadInt` may print its own error text for non-numbers in addition to ours; harmless.
- The best-score file is created in the folder Visual Studio runs from (the project folder, or `Debug` for some setups).
- The console must be at least 80 columns wide and about 25 rows tall; the default 120x30 is fine.

## 7. Still to do (not code)

The IEEE-format report and the viva preparation (every member must be able to explain every line, and AI-assisted code must be disclosed to the instructor, as the proposal states).
