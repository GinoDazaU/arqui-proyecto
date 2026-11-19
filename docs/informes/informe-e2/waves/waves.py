"""Renders the E2 waveforms (dual-issue) from the per-cycle traces of trace_tb.v.

    python3 waves.py table <trace.txt> [signal ...]    # print a readable table (analysis)
    python3 waves.py render <outdir>                   # build every figure in FIGS

render compiles the dual-issue design with trace_tb.v, runs each program and
draws figs/waveform-<name>.png. Needs iverilog/vvp and matplotlib
(e.g. `uv run --with matplotlib python3 waves.py render ../figs`).
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
HERE = os.path.dirname(os.path.abspath(__file__))

# ================= DISASSEMBLER (subset supported by the processor) =================
R_OPS = {(0, 0): "add", (0, 32): "sub", (7, 0): "and", (6, 0): "or", (4, 0): "xor", (2, 0): "slt"}
I_OPS = {0: "addi", 7: "andi", 6: "ori", 4: "xori", 2: "slti"}


def sext(v, bits):
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def dis(h):
    w = int(h, 16) if isinstance(h, str) else h
    if w == 0:
        return None  # bubble
    if w == 0x13:
        return "nop"
    op, rd, f3 = w & 0x7F, (w >> 7) & 31, (w >> 12) & 7
    rs1, rs2, f7 = (w >> 15) & 31, (w >> 20) & 31, w >> 25
    if op == 0x33:
        return f"{R_OPS.get((f3, f7), '?')} x{rd},x{rs1},x{rs2}"
    if op == 0x13:
        return f"{I_OPS.get(f3, '?')} x{rd},x{rs1},{sext(w >> 20, 12)}"
    if op == 0x03:
        return f"lw x{rd},{sext(w >> 20, 12)}(x{rs1})"
    if op == 0x23:
        imm = sext(((w >> 25) << 5) | ((w >> 7) & 31), 12)
        return f"sw x{rs2},{imm}(x{rs1})"
    if op == 0x63:
        imm = (((w >> 31) & 1) << 12) | (((w >> 7) & 1) << 11) | (((w >> 25) & 63) << 5) | (((w >> 8) & 15) << 1)
        return f"beq x{rs1},x{rs2},{sext(imm, 13)}"
    if op == 0x6F:
        imm = (((w >> 31) & 1) << 20) | (((w >> 12) & 255) << 12) | (((w >> 20) & 1) << 11) | (((w >> 21) & 1023) << 1)
        return f"jal x{rd},{sext(imm, 21)}"
    return f"{w:08x}"


# ================= TRACE =================
def load(path):
    with open(path) as f:
        lines = [l.split() for l in f if l.strip()]
    hdr = lines[0]
    return [dict(zip(hdr, l)) for l in lines[1:] if len(l) == len(hdr)]


FWD = {"0": "RF", "1": "WB0", "2": "WB1", "3": "MEM0", "4": "MEM1"}


def fmt(sig, v):
    if v is None:
        return ""
    if "x" in v or "z" in v:
        return "x"
    if sig.startswith("Instr"):
        return dis(v) or "bubble"
    if sig.startswith("Forward"):
        return FWD[v]
    if sig in ("PCF", "PCD_0", "PCD_1", "PCTargetE"):
        return hex(int(v, 16))
    if sig.startswith(("Rd", "Rs")):
        return "x" + v
    return v


def table(path, sigs):
    rows = load(path)
    sigs = sigs or ["PCF", "InstrD_0", "InstrD_1", "InstrE_0", "InstrE_1", "IssueOneD", "RegroupD", "StallD", "FlushD"]
    print("cyc " + " | ".join(f"{s:>14}" for s in sigs))
    for r in rows:
        print(f"{r['cycle']:>3} " + " | ".join(f"{fmt(s, r[s])[:14]:>14}" for s in sigs))


# ================= FIGURES =================
# Each figure: program, cycles shown, rows, highlighted columns and notes.
# Row = (signal, label, kind) with kind "bit", "bus" or "instr<n>" (n = colour group).
BLUE, GREEN, ORANGE, RED, PURPLE = "#4a86d8", "#4f9d69", "#e09a3e", "#d0505a", "#8a63c7"
INSTR_COL = {"F": "#4a6fa5", "D": "#3f8f5a", "E": "#c8962c", "M": "#c0464f", "W": "#7a5ba8"}

FIGS = {}


def fig(name, **kw):
    FIGS[name] = kw


def instr_rows(stages, lanes=(0, 1)):
    return [(f"Instr{s}_{l}", f"Instr{s}_{l}", "instr" + s) for s in stages for l in lanes]


fig("alu-pair", prog="dualissue/alu_pair", title="Programa 1 — Dos operaciones ALU independientes emitidas juntas",
    rows=[("clk", "clk", "clk"), ("PCF", "PCF", "bus")] + instr_rows("DEW") + [None,
          ("IssueOneD", "IssueOneD", "bit"), ("RegroupD", "RegroupD", "bit"), None,
          ("ForwardAE_0", "ForwardAE_0", "bus"), ("ForwardBE_0", "ForwardBE_0", "bus"),
          ("SrcAE_0", "SrcAE_0", "bus"), ("SrcBE_0", "SrcBE_0", "bus"), ("ALUResultE_0", "ALUResultE_0", "bus"),
          ("ForwardAE_1", "ForwardAE_1", "bus"), ("ForwardBE_1", "ForwardBE_1", "bus"),
          ("SrcAE_1", "SrcAE_1", "bus"), ("SrcBE_1", "SrcBE_1", "bus"), ("ALUResultE_1", "ALUResultE_1", "bus"), None,
          ("RegWriteW_0", "RegWriteW_0", "bit"), ("RdW_0", "RdW_0", "bus"), ("ResultW_0", "ResultW_0", "bus"),
          ("RegWriteW_1", "RegWriteW_1", "bit"), ("RdW_1", "RdW_1", "bus"), ("ResultW_1", "ResultW_1", "bus"), None,
          ("MemLaneM", "MemLaneM", "bit"), ("MemWrite", "MemWrite", "bit"), ("DataAdr", "DataAdr", "bus"),
          ("WriteData", "WriteData", "bus")])

fig("raw-forward", prog="dualissue/raw_forward", title="Programa 2 — RAW dentro del par y forwarding entre vías",
    rows=[("clk", "clk", "clk"), ("PCF", "PCF", "bus")] + instr_rows("DE") + [None,
          ("IssueOneD", "IssueOneD", "bit"), ("RegroupD", "RegroupD", "bit"), None,
          ("ForwardAE_0", "ForwardAE_0", "bus"), ("ForwardBE_0", "ForwardBE_0", "bus"),
          ("SrcAE_0", "SrcAE_0", "bus"), ("SrcBE_0", "SrcBE_0", "bus"), ("ALUResultE_0", "ALUResultE_0", "bus"), None,
          ("ForwardAE_1", "ForwardAE_1", "bus"), ("ForwardBE_1", "ForwardBE_1", "bus"),
          ("SrcAE_1", "SrcAE_1", "bus"), ("SrcBE_1", "SrcBE_1", "bus"), ("ALUResultE_1", "ALUResultE_1", "bus"), None,
          ("MemWrite", "MemWrite", "bit"), ("DataAdr", "DataAdr", "bus"), ("WriteData", "WriteData", "bus")])

fig("memory", prog="dualissue/memory", title="Programa 3 — Load-use y conflictos del puerto de memoria",
    rows=[("clk", "clk", "clk"), ("PCF", "PCF", "bus")] + instr_rows("DEM") + [None,
          ("IssueOneD", "IssueOneD", "bit"), ("LoadUseD_0", "LoadUseD_0", "bit"), ("StallF", "StallF", "bit"),
          ("StallD", "StallD", "bit"), ("FlushE_0", "FlushE_0", "bit"), ("FlushE_1", "FlushE_1", "bit"), None,
          ("ForwardAE_0", "ForwardAE_0", "bus"), ("ForwardBE_0", "ForwardBE_0", "bus"),
          ("ALUResultE_0", "ALUResultE_0", "bus"), ("ALUResultE_1", "ALUResultE_1", "bus"), None,
          ("MemLaneM", "MemLaneM", "bit"), ("MemWrite", "MemWrite", "bit"), ("DataAdr", "DataAdr", "bus"),
          ("WriteData", "WriteData", "bus"), ("ReadDataM", "ReadDataM", "bus")])

fig("branch", prog="dualissue/branch", title="Programa 4 — Branches en ambas posiciones del par y flushing",
    rows=[("clk", "clk", "clk"), ("PCF", "PCF", "bus")] + instr_rows("DEM") + [None,
          ("IssueOneD", "IssueOneD", "bit"), ("RegroupD", "RegroupD", "bit"), None,
          ("BrLaneE", "BrLaneE", "bit"), ("PCSrcE", "PCSrcE", "bit"), ("TakenE_0", "TakenE_0", "bit"),
          ("PCTargetE", "PCTargetE", "bus"), None,
          ("FlushD", "FlushD", "bit"), ("FlushE_0", "FlushE_0", "bit"), ("FlushE_1", "FlushE_1", "bit"),
          ("FlushM_1", "FlushM_1", "bit"), None,
          ("x3", "x3 (RF)", "bus"), ("MemWrite", "MemWrite", "bit"), ("DataAdr", "DataAdr", "bus"),
          ("WriteData", "WriteData", "bus")])

fig("branch-conflict", prog="dualissue/branch_conflict",
    title="Programa 7 — Una sola Branch Unit: dos saltos en el par y jal en la segunda posición",
    rows=[("clk", "clk", "clk"), ("PCF", "PCF", "bus")] + instr_rows("DEM") + [None,
          ("IssueOneD", "IssueOneD", "bit"), ("RegroupD", "RegroupD", "bit"), None,
          ("BrLaneE", "BrLaneE", "bit"), ("PCSrcE", "PCSrcE", "bit"), ("TakenE_0", "TakenE_0", "bit"),
          ("PCTargetE", "PCTargetE", "bus"), None,
          ("FlushD", "FlushD", "bit"), ("FlushE_1", "FlushE_1", "bit"), ("FlushM_1", "FlushM_1", "bit"), None,
          ("RegWriteW_1", "RegWriteW_1", "bit"), ("RdW_1", "RdW_1", "bus"), ("ResultW_1", "ResultW_1", "bus"),
          ("x3", "x3 (RF)", "bus")])

fig("two-writes", prog="dualissue/two_writes", title="Programa 5 — Dos escrituras en el Register File en el mismo ciclo",
    rows=[("clk", "clk", "clk")] + instr_rows("DEMW") + [None,
          ("RegWriteW_0", "RegWriteW_0", "bit"), ("RdW_0", "RdW_0", "bus"), ("ResultW_0", "ResultW_0", "bus"),
          ("RegWriteW_1", "RegWriteW_1", "bit"), ("RdW_1", "RdW_1", "bus"), ("ResultW_1", "ResultW_1", "bus"),
          ("x3", "x3 (RF)", "bus"), None,
          ("ForwardAE_0", "ForwardAE_0", "bus"), ("ALUResultE_0", "ALUResultE_0", "bus"),
          ("ForwardAE_1", "ForwardAE_1", "bus"), ("ALUResultE_1", "ALUResultE_1", "bus"), None,
          ("MemWrite", "MemWrite", "bit"), ("DataAdr", "DataAdr", "bus"), ("WriteData", "WriteData", "bus")])

fig("regroup", prog="dualissue/regroup", title="Programa 6 — Reagrupamiento tras emisión parcial",
    rows=[("clk", "clk", "clk"), ("PCF", "PCF", "bus"), ("InstrF_0", "InstrF_0", "instrF"),
          ("InstrF_1", "InstrF_1", "instrF"), ("PCD_0", "PCD_0", "bus"), ("PCD_1", "PCD_1", "bus")]
         + instr_rows("DE") + [None,
          ("IssueOneD", "IssueOneD", "bit"), ("RegroupD", "RegroupD", "bit"), ("FlushE_1", "FlushE_1", "bit"), None,
          ("MemLaneM", "MemLaneM", "bit"), ("MemWrite", "MemWrite", "bit"), ("DataAdr", "DataAdr", "bus"),
          ("WriteData", "WriteData", "bus")])


def render_fig(name, spec, trace, out, highlights=(), notes=()):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon, Rectangle

    rows = load(trace)
    # show up to the cycle where the halt (jal x0,0) reaches WB (end criterion of perf_tb)
    end = next(i for i, r in enumerate(rows) if "0000006f" in (r["InstrW_0"], r["InstrW_1"]))
    rows = rows[:end + 1]
    n = len(rows)
    spec_rows = spec["rows"]
    H, GAP = 1.0, 0.45  # row height and extra space for a separator (None)
    ys, y = [], 0.0
    for r in spec_rows:
        if r is None:
            y += GAP
            ys.append(None)
        else:
            ys.append(y)
            y += H
    total = y
    W = 1.0
    figw = max(12, 2.2 + n * 0.82)
    figh = 1.0 + total * 0.33 + 0.28 * len(notes) + 0.3
    fig_, ax = plt.subplots(figsize=(figw, figh), dpi=110)
    ax.set_xlim(-2.6, n * W + 0.05)
    ax.set_ylim(total + 0.2, -1.6)
    ax.axis("off")
    fig_.subplots_adjust(left=0.01, right=0.995, top=1 - 0.55 / figh, bottom=(0.28 * len(notes) + 0.25) / figh)
    ax.set_title(spec["title"], loc="left", fontsize=12, fontweight="bold", color="#222", pad=4)

    for c0, c1, col, lab in highlights:
        ax.add_patch(Rectangle((c0 * W, -0.7), (c1 - c0 + 1) * W, total + 0.7, color=col, alpha=0.18, lw=0, zorder=0))
        if lab:
            ax.text((c0 + c1 + 1) / 2 * W, -1.1, lab, ha="center", va="center", fontsize=7.5, fontweight="bold", color=col)
    for c in range(n + 1):
        ax.plot([c * W, c * W], [-0.3, total], color="#e6e6e6", lw=0.6, zorder=0.5)
    for c in range(n):
        ax.text((c + 0.5) * W, -0.45, str(c), ha="center", va="center", fontsize=7, color="#777", family="monospace")
    ax.text(-0.15, -0.45, "ciclo", ha="right", va="center", fontsize=7, color="#777", family="monospace")

    for r, y0 in zip(spec_rows, ys):
        if r is None:
            continue
        sig, label, kind = r
        lc = INSTR_COL[kind[5]] if kind.startswith("instr") else "#222"
        ax.text(-0.15, y0 + H / 2, label, ha="right", va="center", fontsize=8, family="monospace",
                color=lc, fontweight="bold" if kind.startswith("instr") else "normal")
        top, bot, mid = y0 + 0.2, y0 + 0.8, y0 + 0.5
        if kind == "clk":
            xs, yy = [], []
            for c in range(n):
                xs += [c, c, c + 0.5, c + 0.5]
                yy += [bot, top, top, bot]
            ax.plot([x * W for x in xs] + [n * W], yy + [bot], color="#333", lw=1.1)
            continue
        if kind == "bit":
            xs, yy = [], []
            for c, row in enumerate(rows):
                v = row[sig]
                lv = top if v == "1" else bot
                xs += [c * W, (c + 1) * W]
                yy += [lv, lv]
            ax.plot(xs, yy, color="#2f6fc9", lw=1.3)
            continue
        # bus / instruction: merge consecutive equal values into one segment
        vals = [fmt(sig, row[sig]) for row in rows]
        segs, s = [], 0
        for c in range(1, n + 1):
            if c == n or vals[c] != vals[s]:
                segs.append((s, c, vals[s]))
                s = c
        for c0, c1, v in segs:
            x0, x1, k = c0 * W, c1 * W, 0.12
            pts = [(x0, mid), (x0 + k, top), (x1 - k, top), (x1, mid), (x1 - k, bot), (x0 + k, bot)]
            bubble = v in ("bubble", "x")
            if kind.startswith("instr"):
                ec = INSTR_COL[kind[5]]
                fc = "#ffffff" if bubble else matplotlib.colors.to_rgba(ec, 0.13)
            else:
                ec, fc = "#9aa3ad", "#f4f6f8" if not bubble else "#fafafa"
            ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec if not bubble else "#c9ced3", lw=0.8, zorder=2))
            fs = 7 if len(v) <= 9 else 6.2 if len(v) <= 13 else 5.6
            ax.text((x0 + x1) / 2, mid, v, ha="center", va="center", fontsize=fs, family="monospace", zorder=3,
                    color="#888" if bubble else "#222", style="italic" if bubble else "normal")

    for i, (col, txt) in enumerate(notes):
        yy = 0.28 * (len(notes) - i) / figh - 0.04 / figh
        fig_.patches.append(Rectangle((0.012, yy + 0.02 / figh), 0.09 / figw, 0.09 / figh,
                                      transform=fig_.transFigure, color=col, figure=fig_))
        fig_.text(0.03, yy, txt, fontsize=8.4, va="bottom", color="#222")
    fig_.savefig(out)
    plt.close(fig_)


def render(outdir):
    from notes import NOTES  # highlights and notes written after reading each trace
    tmp = tempfile.mkdtemp()
    exe = os.path.join(tmp, "t.out")
    src = sorted(os.path.join(ROOT, "designs", "dualissue", f) for f in os.listdir(os.path.join(ROOT, "designs", "dualissue")))
    subprocess.run(["iverilog", "-g2012", "-o", exe, *src, os.path.join(HERE, "trace_tb.v")], check=True)
    for name, spec in FIGS.items():
        trace = os.path.join(tmp, name + ".txt")
        out = subprocess.run(["vvp", "-n", exe, f"+prog={ROOT}/tb/programs/{spec['prog']}.mem"],
                             check=True, capture_output=True, text=True).stdout
        with open(trace, "w") as f:
            f.write("\n".join(l for l in out.splitlines() if l.startswith("cycle") or l[:1].isdigit()))
        hl, nt = NOTES.get(name, ((), ()))
        render_fig(name, spec, trace, os.path.join(outdir, f"waveform-{name}.png"), hl, nt)
        print("ok", f"waveform-{name}.png")


if __name__ == "__main__":
    if sys.argv[1] == "table":
        table(sys.argv[2], sys.argv[3:])
    else:
        sys.path.insert(0, HERE)
        render(sys.argv[2])
