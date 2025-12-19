import sys
import random
import time
from collections import deque

WIDTH = 80
HEIGHT = 25

program = [[' ' for _ in range(WIDTH)] for _ in range(HEIGHT)]

lines = sys.stdin.read().splitlines()
for y, line in enumerate(lines[:HEIGHT]):
    for x, ch in enumerate(line[:WIDTH]):
        program[y][x] = ch

x, y = 0, 0
dx, dy = 1, 0
stack = []
string_mode = False
output_buffer = ""

def pop():
    return stack.pop() if stack else 0

step = 0

# --- simple log area (keeps prints off the terminal scroll) ---
LOG_LINES = 6
log = deque(maxlen=LOG_LINES)

def render():
    """Render everything in-place without scrolling."""
    buf = []
    buf.append("\033[H")  # home (top-left)

    # Header
    buf.append(f"--- Step {step} ---\n")

    # Befunge grid
    for yy in range(HEIGHT):
        row = []
        for xx in range(WIDTH):
            ch = program[yy][xx]
            if xx == x and yy == y:
                row.append(f"\033[7m{ch}\033[0m")
            else:
                row.append(ch)
        buf.append("".join(row) + "\n")

    # Status
    buf.append(f"IP:({x:2},{y:2}) Dir:({dx:+2},{dy:+2}) Cmd:{repr(program[y][x]):^2}  ")
    buf.append("(string mode)  " if string_mode else "               ")
    buf.append("\n")

    # Log area (fixed number of lines)
    buf.append("-" * WIDTH + "\n")
    for i in range(LOG_LINES):
        line = log[i] if i < len(log) else ""
        # pad / trim to WIDTH
        if len(line) > WIDTH:
            line = line[:WIDTH]
        buf.append(line.ljust(WIDTH) + "\n")

    # clear anything left from previous frame (if terminal is taller)
    buf.append("\033[J")

    sys.stdout.write("".join(buf))
    sys.stdout.flush()

def term_enter():
    # alternate screen + clear + hide cursor
    sys.stdout.write("\033[?1049h\033[2J\033[H\033[?25l")
    sys.stdout.flush()

def term_exit():
    # show cursor + leave alternate screen
    sys.stdout.write("\033[?25h\033[?1049l")
    sys.stdout.flush()

term_enter()

try:
    while True:
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
                log.append(f"Output(int): {pop()}")
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
                program[b % HEIGHT][a % WIDTH] = chr(v % 256)
            elif cmd == '&':
                # input without breaking the screen too much:
                # show cursor, jump to bottom prompt line, read, then hide cursor again
                sys.stdout.write("\033[?25h")
                sys.stdout.write(f"\033[{1 + 1 + HEIGHT + 1 + 1 + LOG_LINES + 1};1H")  # move below UI
                sys.stdout.write("\033[KInput(int): ")
                sys.stdout.flush()
                s = sys.stdin.readline().strip()
                sys.stdout.write("\033[?25l")
                try:
                    stack.append(int(s))
                except:
                    stack.append(0)
            elif cmd == '~':
                sys.stdout.write("\033[?25h")
                sys.stdout.write(f"\033[{1 + 1 + HEIGHT + 1 + 1 + LOG_LINES + 1};1H")
                sys.stdout.write("\033[KInput(char): ")
                sys.stdout.flush()
                s = sys.stdin.readline()
                sys.stdout.write("\033[?25l")
                stack.append(ord(s[0]) if s else 0)
            elif cmd == '@':
                log.append("Final Output: " + output_buffer)
                render()
                time.sleep(0.8)
                break

        x = (x + dx) % WIDTH
        y = (y + dy) % HEIGHT
        step += 1

finally:
    term_exit()
