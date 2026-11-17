"""
gui.py - Neo-brutalist front end for the 2048 assembly engine.

The GAME (slide, merge, score, spawn, undo, win, game over, best-score
file) runs entirely in assembly inside game2048.dll. This file only
draws what the DLL reports and turns keys and clicks into DLL calls.
Needs 32-bit Python 3 (Tkinter is included with Python).
"""
import ctypes
import os
import sys
import tkinter as tk
from tkinter import messagebox

# ---------------- style: flat colours, thick ink borders, hard shadows ----------------
INK, BG, WHITE = "#111111", "#FFF1D6", "#FFFFFF"
YELLOW, PINK, BLUE, MINT = "#FFD23F", "#FF6B9E", "#5CC8FF", "#7DF0B5"
ORANGE, RED, PURPLE = "#FF9F68", "#FF6B6B", "#C77DFF"
FONT, BORDER, SHADOW = "Arial Black", 4, 8
TILE = {0: "#E9DCBF", 2: WHITE, 4: "#FFE66D", 8: ORANGE, 16: RED, 32: PINK, 64: PURPLE,
        128: BLUE, 256: "#4DD4AC", 512: "#B8F28B", 1024: YELLOW, 2048: "#FF3D77"}
KEYS = {"Left": 0, "a": 0, "Right": 1, "d": 1, "Up": 2, "w": 2, "Down": 3, "s": 3}

# ---------------- layout (pixels) ----------------
W, H = 960, 700
BOARD_X, BOARD_Y, BOARD_S = 40, 130, 520
PX, PW = 610, 310                      # right-hand panel: left edge, width


class Engine:
    """Thin ctypes wrapper: every call goes into the assembly DLL (stdcall)."""

    def __init__(self, path):
        if ctypes.sizeof(ctypes.c_void_p) != 4:
            raise RuntimeError("32-bit Python is required (the DLL is 32-bit).")
        self.dll = ctypes.WinDLL(path)
        self.dll.Game_Init()

    def get(self, name, *args):
        return getattr(self.dll, name)(*args) & 0xFFFFFFFF

    def new(self, n):    return self.get("Game_New", n)
    def move(self, d):   return self.get("Game_Move", d)
    def undo(self):      return self.get("Game_Undo")
    def restart(self):   return self.get("Game_Restart")
    def save(self):      return self.get("Game_Save")
    def cell(self, i):   return self.get("Game_Cell", i)
    def size(self):      return self.get("Game_Size")
    def score(self):     return self.get("Game_Score")
    def best(self):      return self.get("Game_Best")
    def target(self):    return self.get("Game_Target")
    def is_over(self):   return self.get("Game_IsOver")
    def won(self):       return self.get("Game_CheckWin")


class App:
    def __init__(self, root, engine):
        self.root, self.e = root, engine
        self.over = self.win = False          # display flags only; rules live in the DLL
        root.title("2048 - x86 Assembly Engine")
        root.resizable(False, False)
        self.cv = tk.Canvas(root, width=W, height=H, bg=BG, highlightthickness=0)
        self.cv.pack()
        self.e.new(4)
        self.build_static()
        self.render()
        root.bind("<Key>", self.on_key)
        root.protocol("WM_DELETE_WINDOW", self.close)

    # ---------------- drawing primitives ----------------
    def card(self, x, y, w, h, fill, tag="dyn", shadow=SHADOW, border=BORDER):
        self.cv.create_rectangle(x + shadow, y + shadow, x + w + shadow, y + h + shadow,
                                 fill=INK, outline=INK, tags=tag)
        self.cv.create_rectangle(x, y, x + w, y + h, fill=fill, outline=INK,
                                 width=border, tags=tag)

    def text(self, x, y, s, size, fill=INK, anchor="w", tag="dyn"):
        self.cv.create_text(x, y, text=s, font=(FONT, size), fill=fill, anchor=anchor, tags=tag)

    def button(self, x, y, w, h, label, fill, cmd, size=14):
        tag = f"btn{x}_{y}"
        self.cv.create_rectangle(x + 6, y + 6, x + w + 6, y + h + 6, fill=INK, outline=INK)
        self.cv.create_rectangle(x, y, x + w, y + h, fill=fill, outline=INK,
                                 width=BORDER, tags=tag)
        self.cv.create_text(x + w / 2, y + h / 2, text=label, font=(FONT, size),
                            fill=INK, tags=tag)
        self.cv.tag_bind(tag, "<ButtonPress-1>", lambda ev: self.cv.move(tag, 5, 5))
        self.cv.tag_bind(tag, "<ButtonRelease-1>",
                         lambda ev: (self.cv.move(tag, -5, -5), cmd()))

    # ---------------- parts that never change ----------------
    def build_static(self):
        self.card(40, 24, 330, 86, YELLOW, "static")
        self.text(60, 66, "2048", 40, tag="static")
        self.text(210, 50, "SLIDE & MERGE", 11, tag="static")
        self.text(210, 76, "x86 ASM ENGINE", 11, tag="static")
        self.card(PX, 236, PW, 140, WHITE, "static")
        self.text(PX + 16, 256, "BOARD SIZE", 11, tag="static")
        for i, n in enumerate(range(3, 9)):
            self.button(PX + 16 + i * 46, 282, 38, 38, str(n), MINT,
                        lambda n=n: self.new_game(n), 12)
        self.button(PX, 404, 146, 56, "UNDO", BLUE, self.undo)
        self.button(PX + 164, 404, 146, 56, "RESTART", PINK, self.restart)
        self.text(PX, 626, "ARROWS / WASD  MOVE", 10, tag="static")
        self.text(PX, 648, "U  UNDO     R  RESTART", 10, tag="static")

    # ---------------- parts redrawn after every change ----------------
    def tile(self, x, y, s, v):
        fill = TILE.get(v, INK)
        if v:
            self.cv.create_rectangle(x + 3, y + 3, x + s + 3, y + s + 3,
                                     fill=INK, outline=INK, tags="dyn")
        self.cv.create_rectangle(x, y, x + s, y + s, fill=fill, outline=INK,
                                 width=3 if v else 2, tags="dyn")
        if v:
            digits = len(str(v))
            size = max(8, int(s * {1: 0.32, 2: 0.30, 3: 0.24, 4: 0.19}.get(digits, 0.15)))
            color = WHITE if v >= 2048 else INK
            self.text(x + s / 2, y + s / 2, str(v), size, color, "center")

    def stat_card(self, y, label, value, fill):
        self.card(PX, y, PW, 88, fill)
        self.text(PX + 16, y + 24, label, 11)
        self.text(PX + 16, y + 58, str(value), 28)

    def render(self):
        e, n = self.e, self.e.size()
        self.cv.delete("dyn")
        self.card(BOARD_X, BOARD_Y, BOARD_S, BOARD_S, "#FFFBF0")
        pad, gap = 14, 8
        cell = (BOARD_S - 2 * pad - (n - 1) * gap) / n
        for r in range(n):
            for c in range(n):
                self.tile(BOARD_X + pad + c * (cell + gap), BOARD_Y + pad + r * (cell + gap),
                          cell, e.cell(r * n + c))
        self.stat_card(24, "SCORE", e.score(), BLUE)
        self.stat_card(130, "BEST", e.best(), PINK)
        self.text(PX + 16, 346, f"SIZE {n}x{n}    TARGET {e.target()}", 11)
        title, fill, sub = ("GAME OVER", RED, "U UNDO  /  R RESTART") if self.over else \
                           ("YOU WIN!", MINT, "KEEP GOING OR RESTART") if self.win else \
                           ("YOUR MOVE", WHITE, f"BUILD THE {e.target()} TILE")
        self.card(PX, 486, PW, 110, fill)
        self.text(PX + PW / 2, 524, title, 24, anchor="center")
        self.text(PX + PW / 2, 566, sub, 10, anchor="center")

    # ---------------- actions: all rules are decided by the DLL ----------------
    def new_game(self, n):
        self.e.new(n)
        self.over = self.win = False
        self.render()

    def restart(self):
        self.e.restart()
        self.over = self.win = False
        self.render()

    def undo(self):
        if self.e.undo():
            self.over = False
            self.render()

    def move(self, d):
        if self.over or not self.e.move(d):
            return
        if self.e.is_over():
            self.over = True
        elif self.e.won():
            self.win = True
        self.render()

    def on_key(self, ev):
        k = ev.keysym if ev.keysym in KEYS else ev.char.lower()
        if k in KEYS:
            self.move(KEYS[k])
        elif k == "u":
            self.undo()
        elif k == "r":
            self.restart()

    def close(self):
        self.e.save()
        self.root.destroy()


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    dll = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "..", "build_dll", "game2048.dll")
    root = tk.Tk()
    try:
        engine = Engine(dll)
    except (OSError, RuntimeError) as err:
        root.withdraw()
        size = os.path.getsize(dll) if os.path.exists(dll) else "missing"
        messagebox.showerror("2048", f"Cannot load the assembly engine:\n{err}\n\n"
                                     f"File: {os.path.abspath(dll)}\nSize: {size} bytes")
        return
    App(root, engine)
    root.mainloop()


if __name__ == "__main__":
    main()
