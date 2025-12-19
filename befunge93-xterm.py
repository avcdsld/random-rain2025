#!/usr/bin/env python3
import sys
import random
import time
import signal
import shutil
from collections import deque

WIDTH = 80
HEIGHT = 25

# -------------------------
# Load program (from stdin)
# -------------------------
program = [[' ' for _ in range(WIDTH)] for _ in range(HEIGHT)]
lines = sys.stdin.read().splitlines()
for yy, line in enumerate(lines[:HEIGHT]):
    for xx, ch in enumerate(line[:WIDTH]):
        program[yy][xx] = ch

# Befunge state
x, y = 0, 0
dx, dy = 1, 0
stack = []
string_mode = False
output_buffer = ""
step = 0

def pop():
    return stack.pop() if stack else 0

# For interactive input even when stdin is redirected
try:
    TTY = open("/dev/tty", "r", buffering=1)
except Exception:
    TTY = None  # may be unavailable in some environments

# -------------------------
# Terminal control helpers
# -------------------------
STOP = False

def on_sigint(_sig, _frame):
    global STOP
    STOP = True

signal.signal(signal.SIGINT, on_sigint)

def term_enter():
    # alternate screen + clear + home + hide cursor
    sys.stdout.write("\033[?1049h\033[2J\033[H\033[?25l")
    sys.stdout.flush()

def term_exit():
    # show cursor + leave alternate screen
    sys.stdout.write("\033[?25h\033[?1049l")
    sys.stdout.flush()

def term_size():
    # Returns (cols, rows)
    sz = shutil.get_terminal_size(fallback=(80, 24))
    return sz.columns, sz.lines

# -------------------------
# UI rendering (no scrolling)
# -------------------------
LOG = deque(maxlen=9999)  # we will slice per-frame based on terminal height

def push_log(s: str):
    # keep log lines reasonably short for WIDTH
    if s is None:
        s = ""
    LOG.append(str(s))

def render():
    cols, rows = term_size()

    # We must never output more than `rows` lines, or xterm may scroll/jitter.
    # Compose fixed parts first:
    # 1: header
    # HEIGHT: grid
    # 1: status
    # 1: separator
    base_lines = 1 + HEIGHT + 1 + 1

    # Ensure we fit within screen height.
    # If terminal is too small, reduce what we show.
    # Prefer keeping the grid; if even that doesn't fit, crop grid.
    usable_rows = max(1, rows)  # safety

    # Determine how many grid rows can fit
    if usable_rows < 3:
        grid_rows = max(0, usable_rows - 2)  # almost nothing fits
    else:
        # try to keep full HEIGHT, but may need to crop
        grid_rows = min(HEIGHT, max(0, usable_rows - (1 + 1 + 1)))  # header+status+sep

    # With possibly cropped grid, recompute base
    base_lines = 1 + grid_rows + 1 + 1
    log_lines = max(0, usable_rows - base_lines)

    # Width handling: keep logical WIDTH chars, but if terminal narrower, hard-trim.
    w = min(WIDTH, max(1, cols))

    lines_out = []

    # Header (no trailing newline at the very end; we join later)
    lines_out.append(f"--- Step {step} ---"[:w].ljust(w))

    # Grid (possibly cropped vertically)
    for yy in range(grid_rows):
        row = []
        for xx in range(WIDTH):
            ch = program[yy][xx]
            if xx == x and yy == y:
                row.append(f"\033[7m{ch}\033[0m")
            else:
                row.append(ch)
        # This row may contain ANSI sequences; trimming naively can cut sequences.
        # For safety, we keep logical WIDTH content and then trim raw string only if needed
        # when terminal is narrower than WIDTH. Most of the time cols >= 80 in fullscreen.
        s = "".join(row)
        if w < WIDTH:
            # fallback: drop highlighting when narrow to avoid broken ANSI truncation
            plain = "".join(program[yy][:WIDTH])
            s = plain[:w].ljust(w)
        lines_out.append(s)

    # Status
    cmd_repr = repr(program[y][x]) if 0 <= y < HEIGHT and 0 <= x < WIDTH else repr(' ')
    status = f"IP:({x:2},{y:2}) Dir:({dx:+2},{dy:+2}) Cmd:{cmd_repr:^2}"
    if string_mode:
        status += "  (string mode)"
    lines_out.append(status[:w].ljust(w))

    # Separator
    lines_out.append(("-" * WIDTH)[:w].ljust(w))

    # Log area (show last `log_lines` lines)
    if log_lines > 0:
        recent = list(LOG)[-log_lines:]
        # pad if fewer
        while len(recent) < log_lines:
            recent.insert(0, "")
        for s in recent:
            lines_out.append(str(s)[:w].ljust(w))

    # Now draw in-place: HOME + join WITHOUT trailing newline + clear-to-end
    sys.stdout.write("\033[H" + "\n".join(lines_out) + "\033[J")
    sys.stdout.flush()

def prompt_on_bottom(prompt: str) -> str:
    """Read from /dev/tty to avoid interfering with stdin-redirected program input."""
    cols, rows = term_size()
    w = min(WIDTH, max(1, cols))
    r = max(1, rows)

    # show cursor, move to bottom-left, clear line, print prompt
    sys.stdout.write("\033[?25h")
    sys.stdout.write(f"\033[{r};1H\033[K")
    sys.stdout.write(prompt[:w])
    sys.stdout.flush()

    if TTY is None:
        # can't read; return empty
        s = ""
    else:
        s = TTY.readline()
        if s is None:
            s = ""
        s = s.rstrip("\n")

    # hide cursor again, clear prompt line
    sys.stdout.write(f"\033[{r};1H\033[K\033[?25l")
    sys.stdout.flush()
    return s

# -------------------------
# Main loop
# -------------------------
term_enter()
try:
    while True:
        if STOP:
            push_log("Interrupted (Ctrl+C).")
            render()
            break

        render()
        time.sleep(0.05)

        cmd = program[y][x]

        if string_mode:
            if cmd == '"':
                string_mode = False
            else:
                stack.append(ord(cmd))
        else:
            if cmd == '>':
                dx, dy = 1, 0
            elif cmd == '<':
                dx, dy = -1, 0
            elif cmd == '^':
                dx, dy = 0, -1
            elif cmd == 'v':
                dx, dy = 0, 1
            elif cmd == '?':
                dx, dy = random.choices(
                    [(1,0), (-1,0), (0,1), (0,-1)],
                    weights=[0.3, 0.2, 0.3, 0.2],
                    k=1
                )[0]
            elif cmd == '_':
                dx, dy = (1,0) if pop() == 0 else (-1,0)
            elif cmd == '|':
                dx, dy = (0,1) if pop() == 0 else (0,-1)
            elif cmd == '"':
                string_mode = True
            elif cmd in '0123456789':
                stack.append(int(cmd))
            elif cmd == '+':
                stack.append(pop() + pop())
            elif cmd == '-':
                a, b = pop(), pop()
                stack.append(b - a)
            elif cmd == '*':
                stack.append(pop() * pop())
            elif cmd == '/':
                a, b = pop(), pop()
                stack.append(0 if a == 0 else b // a)
            elif cmd == '%':
                a, b = pop(), pop()
                stack.append(0 if a == 0 else b % a)
            elif cmd == '!':
                stack.append(0 if pop() else 1)
            elif cmd == '`':
                a, b = pop(), pop()
                stack.append(1 if b > a else 0)
            elif cmd == ':':
                stack.append(stack[-1] if stack else 0)
            elif cmd == '\\':
                a = pop()
                b = pop()
                stack.append(a)
                stack.append(b)
            elif cmd == '$':
                pop()
            elif cmd == '.':
                push_log(f"Output(int): {pop()}")
            elif cmd == ',':
                output_buffer += chr(pop())
                # optionally mirror into log for visibility
                if len(output_buffer) <= 200:
                    push_log("Output(str): " + output_buffer)
            elif cmd == '#':
                x = (x + dx) % WIDTH
                y = (y + dy) % HEIGHT
            elif cmd == 'g':
                a = pop()
                b = pop()
                stack.append(ord(program[b % HEIGHT][a % WIDTH]))
            elif cmd == 'p':
                a = pop()
                b = pop()
                v = pop()
                program[b % HEIGHT][a % WIDTH] = chr(v % 256)
            elif cmd == '&':
                s = prompt_on_bottom("Input(int): ")
                try:
                    stack.append(int(s.strip()))
                except Exception:
                    stack.append(0)
            elif cmd == '~':
                s = prompt_on_bottom("Input(char): ")
                stack.append(ord(s[0]) if s else 0)
            elif cmd == '@':
                push_log("Final Output: " + output_buffer)
                render()
                time.sleep(0.8)
                break

        x = (x + dx) % WIDTH
        y = (y + dy) % HEIGHT
        step += 1

finally:
    try:
        if TTY is not None:
            TTY.close()
    except Exception:
        pass
    term_exit()
