"""Per-branch statistics of a program on B and C (from the final_tb traces).

    python3 branches.py final/programa

For every static branch/jump (PC in Execute): executions, taken, mispredictions in B
(every taken branch) and in C (BTB + 2-bit counter).
"""
import sys
import tempfile
from collections import OrderedDict

from waves import dis, simulate

prog = sys.argv[1]
tmp = tempfile.mkdtemp()
stats = OrderedDict()
for d in ("B", "C"):
    for r in simulate(d, prog, tmp):
        if r["CtrlE"] != "1":
            continue
        pc = int(r["PCBrE"], 16)
        lane = "InstrE_1" if r["BrLaneE"] == "1" else "InstrE_0"
        s = stats.setdefault(pc, {"ins": dis(r[lane]), "B": [0, 0, 0], "C": [0, 0, 0]})
        s[d][0] += 1
        s[d][1] += r["PCSrcE"] == "1"
        s[d][2] += r["MispredictE"] == "1"
print(f"{'PC':>4}  {'instr':<18} {'exec':>4} {'taken':>5} {'misB':>4} {'misC':>4}")
tot = [0, 0, 0, 0]
for pc in sorted(stats):
    s = stats[pc]
    assert s["B"][:2] == s["C"][:2], pc
    print(f"{pc:>4}  {s['ins']:<18} {s['C'][0]:>4} {s['C'][1]:>5} {s['B'][2]:>4} {s['C'][2]:>4}")
    tot = [tot[0] + s["C"][0], tot[1] + s["C"][1], tot[2] + s["B"][2], tot[3] + s["C"][2]]
print(f"{'':>4}  {'total':<18} {tot[0]:>4} {tot[1]:>5} {tot[2]:>4} {tot[3]:>4}")
