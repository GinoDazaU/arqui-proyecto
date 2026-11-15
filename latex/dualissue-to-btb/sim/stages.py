#!/usr/bin/env python3
"""Reads the output of trace_tb.v and prints, per cycle, the PC held by each stage and lane
(F = fetched pair, D/E/M/W = slot or lane 0 | 1; '-' = empty / bubble) and the events.
   vvp -n t.out +prog=... | python3 latex/dualissue-to-btb/sim/stages.py
"""
import sys

rows = [l.split() for l in sys.stdin if l[:1].isdigit()]
prevE = ["-", "-"]
prevM = ["-", "-"]
print(f"{'cyc':>3} | {'F':>7} | {'D':>7} | {'E':>7} | {'M':>7} | {'W':>7} | events")
for r in rows:
    cyc, pcf, d0, d1, iD0, iD1, e0, e1, iE0, iE1, iM0, iM1, iW0, iW1 = r[:14]
    pF0, pF1, an, rg, st, misp, fl1, pcn = r[14:22]
    nz = lambda h: int(h, 16) != 0
    D = [d0 if nz(iD0) else "-", d1 if nz(iD1) else "-"]
    E = [e0 if nz(iE0) else "-", e1 if nz(iE1) else "-"]
    M = [prevE[k] if nz((iM0, iM1)[k]) else "-" for k in range(2)]
    W = [prevM[k] if nz((iW0, iW1)[k]) else "-" for k in range(2)]
    ev = []
    if pF0 == "1": ev.append("PredF0")
    if pF1 == "1": ev.append("PredF1")
    if an == "1": ev.append("AnnulF1")
    if rg == "1": ev.append("Regroup")
    if st == "1": ev.append("Stall")
    if misp == "1": ev.append("MISPREDICT")
    if fl1 == "1": ev.append("FlushLane1")
    f = lambda p: f"{p[0]:>3}|{p[1]:<3}"
    print(f"{cyc:>3} | {pcf:>3}+4  | {f(D)} | {f(E)} | {f(M)} | {f(W)} | next={pcn} {' '.join(ev)}")
    prevE, prevM = E, M
