# 2048 (x86 MASM) – Test Case List  (T-P1 draft)

Owner: Naresh Kumar (25K-2501) · Branch: `docs/test-cases`
20 cases (the proposal requires at least 15). Board sizes covered: N = 3, 4, 5, 6, 7, 8.

**How to set up a board:** in Visual Studio, break after the new game starts, open
*Debug → Windows → Memory*, type `board` as the address and edit the DWORDs (row-major,
cell = row × N + col; each cell is 4 bytes). Row r, col c is at `board + 4 × (r × N + c)`.
Press F5 and make the move.

**Result column:** `P` = pass, `F` = fail (add a note and the commit hash), `-` = not run yet.

| ID | N | Module | Setup | Action | Expected result | Result |
|----|---|--------|-------|--------|-----------------|--------|
| TC01 | – | M1 menu | Start program | Enter 4, x, Enter at the menu; then 1, 2, 3 | Invalid keys show an error and re-ask; 1 = new game, 2 = help, 3 = exit | - |
| TC02 | – | M2 board config | New Game | Enter size 2, 9, 0, a letter, then 3 and 8 | 2, 9, 0 and letters rejected with a message; 3 and 8 accepted | - |
| TC03 | 3 | M2, M7 | New Game, N = 3 | Look at the screen | Exactly 2 tiles (each 2 or 4); TARGET shows 512 | - |
| TC04 | 4 | M2, M7 | New Game, N = 4 | Look at the screen | Exactly 2 tiles (each 2 or 4); TARGET shows 2048 | - |
| TC05 | 4 | M5 SlideLine | Row 0 = 2 2 0 0 | Left | Row 0 = 4 0 0 0; score +4 | - |
| TC06 | 4 | M5 SlideLine | Row 0 = 2 2 0 0 | Right | Row 0 = 0 0 0 4; score +4 | - |
| TC07 | 4 | M5 merge-once | Row 0 = 2 2 2 2 | Left | Row 0 = 4 4 0 0 (not 8 0 0 0); score +8 | - |
| TC08 | 4 | M5 no chaining | Row 0 = 4 2 2 0 | Left | Row 0 = 4 4 0 0 (new 4 does not merge with first 4); score +4 | - |
| TC09 | 4 | M6 Up | Column 0 (top to bottom) = 0 2 0 2 | Up | Column 0 = 4 0 0 0; score +4 | - |
| TC10 | 4 | M6 Down | Column 0 (top to bottom) = 2 0 2 4 | Down | Column 0 = 0 0 4 4; score +4 | - |
| TC11 | 4 | M6 / M8 no-op | Board where Left changes nothing (e.g. row 0 = 2 4 8 16 packed left, rest empty or packed) | Left | Board, score unchanged; **no** new tile spawns | - |
| TC12 | 4 | M7 / M8 spawn | Board with several empty cells | Any valid move | Exactly one new tile appears, in a cell that was empty, value 2 or 4 | - |
| TC13 | 4 | M7 distribution | Run `test_spawn.asm` | Run the harness | All PASS; "4s seen in 1000" is between 60 and 140 | - |
| TC14 | 5 | smoke | New Game N = 5 | 30 mixed moves | No crash; every tile is a power of two; score never decreases | - |
| TC15 | 6 | smoke | New Game N = 6 | 30 mixed moves | Same as TC14 | - |
| TC16 | 7 | smoke | New Game N = 7 | 30 mixed moves | Same as TC14 | - |
| TC17 | 8 | M5 / M6 full width | N = 8, row 0 = 2 0 0 0 0 0 0 2 | Left, then restore and Right | Left: 4 0 0 0 0 0 0 0. Right: 0 0 0 0 0 0 0 4. Layout and panel still fit the console | - |
| TC18 | 3, 4 | M8 win | N = 3: two 256 tiles adjacent. N = 4: two 1024 tiles adjacent | Move so they merge | N = 3 shows win at 512; N = 4 shows win at 2048 | - |
| TC19 | 3 | M8 game over | N = 3 full, no equal neighbours (e.g. 2 4 2 / 4 2 4 / 2 4 2). Second run: same board with one equal pair | Press any arrow | First run: "Game Over" with final score. Second run: game continues | - |
| TC20 | 4 | M9 undo / restart | Play 2 moves, note score and board | U, then R | U restores the board and score from before the last move. R gives a fresh 4x4 board, score 0, 2 tiles; best score is kept | - |

## Notes for the viva

- TC05–TC10 and TC17 prove one procedure (`SlideLine`) handles all four directions.
- TC14–TC17 together with TC03/TC04 cover every N from 3 to 8.
- Log failures as GitHub issues named `TC## – short description`.
