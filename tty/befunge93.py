#!/usr/bin/env python3
import sys
import random
import time
import signal
import shutil
from collections import deque

WIDTH = 80
HEIGHT = 25

program = [[' ' for _ in range(WIDTH)] for _ in range(HEIGHT)]
lines = sys.stdin.read().splitlines()
for yy, line in enumerate(lines[:HEIGHT]):
    for xx, ch in enumerate(line[:WIDTH]):
        program[yy][xx] = ch

x, y = 0, 0
dx, dy = 1, 0
stack = []
string_mode = False
output_buffer = ""
step = 0

def pop():
    return stack.pop() if stack else 0

try:
    TTY = open("/dev/tty", "r", buffering=1)
except Exception:
    TTY = None

STOP = False

def on_sigint(_sig, _frame):
    global STOP
    STOP = True

signal.signal(signal.SIGINT, on_sigint)

def term_enter():
    sys.stdout.write("\033[?1049h\033[2J\033[H\033[?25l")
    sys.stdout.flush()

def term_exit():
    sys.stdout.write("\033[?25h\033[?1049l")
    sys.stdout.flush()

def term_size():
    sz = shutil.get_terminal_size(fallback=(80, 24))
    return sz.columns, sz.lines

def move(row_1based: int, col_1based: int):
    sys.stdout.write(f"\033[{row_1based};{col_1based}H")

def clear_eol():
    sys.stdout.write("\033[K")

HEADER_ROW = 1
GRID_ROW0 = 2
STATUS_ROW = GRID_ROW0 + HEIGHT
SEP_ROW = STATUS_ROW + 1
LOG_ROW0 = STATUS_ROW + 1

LOG = deque(maxlen=2000)

def ensure_terminal_large_enough():
    cols, rows = term_size()
    min_rows = 1 + HEIGHT + 1 + 1 + 1
    if cols < WIDTH or rows < min_rows:
        term_exit()
        msg = (
            f"Terminal too small. Need at least {WIDTH}x{min_rows}. "
            f"Current: {cols}x{rows}\n"
            f"Try: xterm -fullscreen -fa 'DejaVu Sans Mono' -fs 18 -geometry 80x45\n"
        )
        sys.stderr.write(msg)
        sys.exit(1)

def log_capacity():
    _, rows = term_size()
    cap = rows - (LOG_ROW0 - 1)
    return max(1, cap)

def push_log(s: str, update_last: bool = False):
    s_str = str(s)
    if update_last and LOG and LOG[-1].startswith("Output(str): "):
        LOG[-1] = s_str
    else:
        LOG.append(s_str)
    redraw_log_area()

def redraw_log_area():
    cap = log_capacity()
    recent = list(LOG)[-cap:]
    for i in range(cap):
        move(LOG_ROW0 + i, 1)
        clear_eol()
        if i < len(recent):
            line = recent[i]
            sys.stdout.write(line[:WIDTH].ljust(WIDTH))
    sys.stdout.flush()

def draw_header():
    move(HEADER_ROW, 1)
    clear_eol()
    sys.stdout.write(f"--- Step {step} ---".ljust(WIDTH))

def cell_char(xx: int, yy: int) -> str:
    return program[yy][xx]

def draw_cell(xx: int, yy: int, inverse: bool):
    row = GRID_ROW0 + yy
    col = 1 + xx
    move(row, col)
    ch = cell_char(xx, yy)
    if inverse:
        sys.stdout.write(f"\033[7m{ch}\033[0m")
    else:
        sys.stdout.write(ch)

def draw_grid_full(initial_ip=True):
    for yy in range(HEIGHT):
        move(GRID_ROW0 + yy, 1)
        sys.stdout.write("".join(program[yy]))
    if initial_ip:
        draw_cell(x, y, True)

def draw_status():
    move(STATUS_ROW, 1)
    clear_eol()
    cmd_repr = repr(program[y][x])
    s = f"IP:({x:2},{y:2}) Dir:({dx:+2},{dy:+2}) Cmd:{cmd_repr:^2}"
    if output_buffer:
        s += f" Output: {output_buffer[-40:]}"
    if string_mode:
        s += " (string mode)"
    sys.stdout.write(s[:WIDTH].ljust(WIDTH))

def draw_separator():
    move(SEP_ROW, 1)
    clear_eol()
    sys.stdout.write(("-" * WIDTH))

def prompt_on_bottom(prompt: str) -> str:
    cols, rows = term_size()
    row = rows
    move(row, 1)
    clear_eol()
    sys.stdout.write("\033[?25h")
    sys.stdout.write(prompt[:cols])
    sys.stdout.flush()

    if TTY is None:
        s = ""
    else:
        s = TTY.readline()
        s = "" if s is None else s.rstrip("\n")

    move(row, 1)
    clear_eol()
    sys.stdout.write("\033[?25l")
    sys.stdout.flush()
    return s

term_enter()
try:
    ensure_terminal_large_enough()

    draw_header()
    draw_grid_full(initial_ip=True)
    draw_status()
    # draw_separator()
    redraw_log_area()
    sys.stdout.flush()

    prev_x, prev_y = x, y

    while True:
        if STOP:
            push_log("Interrupted (Ctrl+C).")
            break

        time.sleep(0.03)

        cmd = program[y][x]

        wrote_cell = None

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
                xx = a % WIDTH
                yy = b % HEIGHT
                program[yy][xx] = chr(v % 256)
                wrote_cell = (xx, yy)
            elif cmd == '&':
                s = prompt_on_bottom("Input(int): ")
                try:
                    stack.append(int(s.strip()))
                except Exception:
                    stack.append(0)
                push_log(f"Input(int) = {stack[-1]}")
            elif cmd == '~':
                s = prompt_on_bottom("Input(char): ")
                stack.append(ord(s[0]) if s else 0)
                push_log(f"Input(char) = {stack[-1]}")
            elif cmd == '@':
                # push_log("Final Output: " + output_buffer)
                break

        prev_x, prev_y = x, y
        x = (x + dx) % WIDTH
        y = (y + dy) % HEIGHT
        step += 1

        draw_header()

        if wrote_cell is not None:
            wx, wy = wrote_cell
            draw_cell(wx, wy, False)

        if not (prev_x == x and prev_y == y):
            draw_cell(prev_x, prev_y, False)

        draw_cell(x, y, True)

        draw_status()

        if wrote_cell is not None:
            wx, wy = wrote_cell
            if wx == x and wy == y:
                draw_cell(x, y, True)

        sys.stdout.flush()

finally:
    try:
        if TTY is not None:
            TTY.close()
    except Exception:
        pass
    term_exit()
