# 2048 – Python GUI on top of the assembly engine

The game itself (slide, merge, score, tile spawning, undo, win, game over, best-score
file) stays in x86 assembly and is built as `game2048.dll`. Python (Tkinter) only draws
the board and sends key presses and clicks to the DLL.

Not built or run yet: follow the steps below and report the first error you see.

## Code split

| Part | Files | Code lines |
|---|---|---|
| Assembly engine and console game | `src/*.asm`, `include/*.inc` | 1036 |
| Python GUI | `gui/gui.py` | 167 |
| Scripts and export list | `*.bat`, `gui/game2048.def` | 136 |

Assembly is 77% of all code even if the scripts are counted as "other", and 86% if only
the Python is counted. Every rule of the game is decided in assembly.

## How the two sides talk

Python calls these stdcall functions of `game2048.dll` (all written in `src/api.asm`,
which calls the same procedures the console game uses):

| Function | Does |
|---|---|
| `Game_Init` | seed random numbers, load `best2048.dat` |
| `Game_New(n)` | new game of size n (3 to 8) |
| `Game_Move(dir)` | slide and merge; 0 Left, 1 Right, 2 Up, 3 Down; returns 1 if the board changed |
| `Game_Undo`, `Game_Restart`, `Game_Save` | undo one move, same-size restart, save best score |
| `Game_Cell(i)` | tile value at cell i = row × N + col |
| `Game_Size`, `Game_Score`, `Game_Best`, `Game_Target` | numbers for the panel |
| `Game_IsOver`, `Game_CheckWin` | game-over and win checks (win reports once per game) |

## 1. Install 32-bit Python (once)

The DLL is 32-bit, so Python must be 32-bit too. A 64-bit Python cannot load it.

1. Download **Windows installer (32-bit)** from python.org (Python 3.10 or newer).
2. Tick "Add python.exe to PATH" and keep **tcl/tk and IDLE** and **py launcher** ticked.
3. Check in a new Command Prompt:
   ```
   py -3-32 -c "import struct; print(struct.calcsize('P')*8)"
   ```
   It must print `32`. Then `py -3-32 -m tkinter` should open a small test window.

## 2. Build the DLL

In the repo root (`F:\2048-Game`):

```
build_dll.bat
```

It must end with `BUILD OK -> build_dll\game2048.dll` and list 14 `Game_...` exports.
`build_dll.bat` loads Visual Studio's tools itself. If your path or Irvine folder differs,
change `VCVARS` and `IRVINE` at the top of the file.

## 3. Run the GUI

```
run_gui.bat
```

or directly: `py -3-32 gui\gui.py build_dll\game2048.dll`

| Input | Action |
|---|---|
| Arrow keys or W A S D | slide tiles |
| U | undo one move |
| R | restart (same size) |
| Size buttons 3 to 8 | new game of that size |
| UNDO / RESTART buttons | same as U and R |

The best score is saved to `best2048.dat` in the folder you start the GUI from, when you
close the window.

## The look (neo-brutalism)

Flat, saturated colours on a cream background, 4 px black borders, hard black offset
shadows with no blur, heavy "Arial Black" type, and buttons that press down onto their
shadow. The style is set by the constants at the top of `gui/gui.py` (`INK`, `BG`, `TILE`,
`FONT`, `BORDER`, `SHADOW`), so colours can be changed in one place.

## If something fails

| Message | Cause and fix |
|---|---|
| `32-bit Python is required` or `not a valid Win32 application` | The 64-bit Python ran. Use `py -3-32` |
| `Cannot load the assembly engine ... not found` | Run `build_dll.bat` first, or pass the DLL path as an argument |
| `LNK2001 unresolved external symbol` while building the DLL | A file is missing from the `ml` line in `build_dll.bat`, or a name differs in `gui/game2048.def` |
| `LNK1561 entry point must be defined` | `END DllMain` is missing at the end of `src/api.asm` |
| Window opens but the board is empty or wrong | The DLL is old: delete `build_dll` and rebuild |

The console game still builds with `build.bat`; `api.asm` is not part of that build.
