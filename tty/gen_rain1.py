import random

WIDTH = 80
HEIGHT = 25

# 1行目：固定
header = 'v' * 80
lines = [header]

# 2～22行目：ランダムに ? を配置
for _ in range(1, 22):
    row = [' '] * WIDTH
    num_q = random.randint(60, 80)
    q_positions = random.sample(range(WIDTH), num_q)
    for pos in q_positions:
        row[pos] = '?'
    lines.append(''.join(row))

# 23行目：固定+ランダム文字列

row1 = [' '] * 36
num_q = random.randint(27, 36)
q_positions = random.sample(range(36), num_q)
for pos in q_positions:
    row1[pos] = '?'

row2 = [' '] * 35
num_q = random.randint(25, 34)
q_positions = random.sample(range(34), num_q)
for pos in q_positions:
    row2[pos] = '?'

line = ''.join(row1) + '^' * 9 + ''.join(row2)
lines.append(line)

# 24〜25行目：固定文字列
footer_24 = '^' * 36 + 'v"Rain."0<' + '^' * (WIDTH - 46)
footer_25 = ' ' * 36 + '<,_@#:' + ' ' * (WIDTH - 42)
lines.append(footer_24)
lines.append(footer_25)

# ファイル保存
with open('wandering_rain.bf', 'w') as f:
    for line in lines:
        f.write(line + '\n')

print("wandering_rain.bf generated.")
