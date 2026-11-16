"""Renders the waveforms of the final report from the per-cycle traces of final_tb.v.

    python3 waves.py table <design> <program> [c0 c1] [signal ...]   # readable table (analysis)
    python3 waves.py render <outdir>                                 # build every figure in FIGS

<design> is B (dual-issue) or C (dual-issue + BTB); <program> is a path under tb/programs
without .mem (e.g. opt/pred_slot0). render compiles both designs with final_tb.v, runs the
programs and draws figs/waveform-<name>.png. Needs iverilog/vvp and matplotlib
(e.g. `uv run --with matplotlib python3 waves.py render ../figs`).
Cycle 1 is the first cycle after reset, the same numbering as the cycle counts of perf_tb.
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
HERE = os.path.dirname(os.path.abspath(__file__))
DESIGN = {"B": ("dualissue", ["-DDUAL"]), "C": ("dualissue-btb", ["-DDUAL", "-DOPT"])}

# ================= DISASSEMBLER (subset supported by the processor) =================
R_OPS = {(0, 0): "add", (0, 32): "sub", (7, 0): "and", (6, 0): "or", (4, 0): "xor", (2, 0): "slt"}
I_OPS = {0: "addi", 7: "andi", 6: "ori", 4: "xori", 2: "slti"}


def sext(v, bits):
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def dis(h):
    w = int(h, 16) if isinstance(h, str) else h
    if w == 0:
        return None  # bubble
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
def simulate(design, prog, tmp):
    exe = os.path.join(tmp, design + ".out")
    if not os.path.exists(exe):
        d, flags = DESIGN[design]
        src = sorted(os.path.join(ROOT, "designs", d, f) for f in os.listdir(os.path.join(ROOT, "designs", d)))
        subprocess.run(["iverilog", "-g2012", *flags, "-o", exe, *src, os.path.join(HERE, "final_tb.v")], check=True)
    out = subprocess.run(["vvp", "-n", exe, f"+prog={ROOT}/tb/programs/{prog}.mem", "+trace"],
                         check=True, capture_output=True, text=True).stdout
    lines = [l.split() for l in out.splitlines() if l.startswith("cycle") or l[:1].isdigit()]
    hdr = lines[0]
    rows = [dict(zip(hdr, l)) for l in lines[1:] if len(l) == len(hdr)]
    return [r for r in rows if r["reset"] == "0"]


FWD = {"0": "RF", "1": "WB0", "2": "WB1", "3": "MEM0", "4": "MEM1"}
HEX = ("PCF", "PCNextF", "PCD_0", "PCD_1", "PCTargetE", "TargetF_0", "TargetF_1", "PCBrE", "PredTargetE", "PCCorrectE")
STAGE = {"0": "", "1": "A", "2": "B", "3": "C", "4": "D"}


def fmt(sig, v):
    if v is None:
        return ""
    if v == "x" or "x" in v and not sig.startswith(("x", "Instr")):
        return "x"
    if sig.startswith("Instr"):
        return dis(v) or "bubble"
    if sig.startswith("Forward"):
        return FWD[v]
    if sig in HEX:
        return str(int(v, 16))  # decimal addresses, as in the program listings
    if sig.startswith(("Rd", "Rs")):
        return "x" + v
    if sig == "chk":
        return STAGE[v]
    return v


def table(design, prog, args):
    rows = simulate(design, prog, tempfile.mkdtemp())
    c0, c1 = 1, len(rows)
    if len(args) >= 2 and args[0].isdigit():
        c0, c1, args = int(args[0]), int(args[1]), args[2:]
    sigs = args or ["PCF", "InstrD_0", "InstrD_1", "InstrE_0", "InstrE_1", "RegroupD", "StallD",
                    "PredF_0", "PredF_1", "AnnulF_1", "MispredictE", "CtrE"]
    print("cyc " + " | ".join(f"{s[:13]:>13}" for s in sigs))
    for r in rows:
        if c0 <= int(r["cycle"]) <= c1:
            print(f"{r['cycle']:>3} " + " | ".join(f"{fmt(s, r[s])[:13]:>13}" for s in sigs))


# ================= FIGURES =================
# Each figure: design, program, cycle window, rows. Highlights and notes are in notes.py.
# Row = (signal, label, kind) with kind "clk", "bit", "bus" or "instr<stage>"; None = separator.
BLUE, GREEN, ORANGE, RED, PURPLE, BROWN = "#4a86d8", "#4f9d69", "#e09a3e", "#d0505a", "#8a63c7", "#9a6a3a"
INSTR_COL = {"F": "#4a6fa5", "D": "#3f8f5a", "E": "#c8962c", "M": "#c0464f", "W": "#7a5ba8"}

FIGS = {}


def fig(name, **kw):
    FIGS[name] = kw


def R(sig, label=None, kind="bus"):
    return (sig, label or sig, kind)


def B(sig, label=None):
    return (sig, label or sig, "bit")


def instr_rows(stages, lanes=(0, 1)):
    return [(f"Instr{s}_{l}", f"Instr{s}_{l}", "instr" + s) for s in stages for l in lanes]


CLK = [("clk", "clk", "clk")]
FETCH = [R("PCF"), R("PCNextF")]
PRED_F = [B("PredF_0"), R("TargetF_0"), B("PredF_1"), R("TargetF_1"), B("AnnulF_1")]
BU = [B("CtrlE"), R("PCBrE", "PC salto (E)"), B("BtbHitE"), R("CtrE", "Ctr (BTB)"), B("PredTakenE"), B("PCSrcE"),
      B("MispredictE"), R("PCCorrectE"), B("FlushLane1E")]
HZ = [B("RegroupD"), B("StallD"), B("FlushD"), B("FlushM_1")]

# ---- optimization (design C) ----
fig("opt-slot0", design="C", prog="opt/pred_slot0", win=(1, 19),
    title="Optimización 1 — beq en el slot 0: fallo inicial, predicción tomada con anulación del slot 1",
    rows=CLK + FETCH + [R("InstrF_0", kind="instrF"), R("InstrF_1", kind="instrF")] + instr_rows("DE") + [None]
         + PRED_F + [None] + BU + [None] + HZ)

fig("opt-slot0-exit", design="C", prog="opt/pred_slot0", win=(32, 42),
    title="Optimización 1 (cont.) — salida del bucle: predicho tomado, no tomado → PCCorrectE = PC+4",
    rows=CLK + FETCH + instr_rows("DEM") + [None] + PRED_F + [None] + BU + [None] + HZ
         + [None, R("x5", "x5 (RF)"), B("MemWrite"), R("DataAdr"), R("WriteData")])

fig("opt-slot0-B", design="B", prog="opt/pred_slot0", win=(1, 19),
    title="Referencia — el mismo bucle en el Dual-Issue sin predicción (arquitectura B)",
    rows=CLK + FETCH + instr_rows("DE") + [None, B("PCSrcE"), R("PCTargetE"), B("FlushD"), B("FlushM_1")])

fig("opt-slot1", design="C", prog="opt/pred_slot1", win=(1, 18),
    title="Optimización 2 — beq en el slot 1: el slot 0 se conserva y el bucle avanza 2 instrucciones por ciclo",
    rows=CLK + FETCH + instr_rows("DEW") + [None] + PRED_F + [None] + BU + [None] + HZ)

fig("opt-regroup", design="C", prog="opt/pred_regroup", win=(8, 19),
    title="Optimización 3 — salto predicho reagrupado con la primera instrucción de su destino",
    rows=CLK + FETCH + [R("PCD_0"), R("PCD_1")] + instr_rows("DE") + [None, B("IssueOneD"), B("RegroupD"), None,
         B("PredF_0"), B("PredF_1"), R("TargetF_1"), B("AnnulF_1"), B("PredD_0"), B("PredD_1"), None] + BU)

fig("opt-jal", design="C", prog="opt/pred_jal", win=(4, 25),
    title="Optimización 4 — jal en el BTB: contador 11 desde la primera ejecución",
    rows=CLK + FETCH + instr_rows("DE") + [None] + PRED_F + [None] + BU + [None, B("FlushD"), B("FlushM_1"), None,
         B("RegWriteW_0"), R("RdW_0"), R("ResultW_0"), B("RegWriteW_1"), R("RdW_1"), R("ResultW_1")])

fig("opt-loaduse", design="C", prog="opt/pred_loaduse", win=(13, 26),
    title="Optimización 5 — stall por load-use detrás de un salto bien predicho",
    rows=CLK + FETCH + instr_rows("DEM") + [None, B("PredF_0"), B("PredF_1"), B("AnnulF_1"), None,
         B("LoadUseD_0"), B("StallF"), B("StallD"), B("FlushE_0"), B("FlushE_1"), None]
         + [B("CtrlE"), R("CtrE", "Ctr (BTB)"), B("PredTakenE"), B("PCSrcE"), B("MispredictE"), None,
            R("ForwardAE_0"), R("ForwardBE_0"), R("ALUResultE_0"), R("ReadDataM")])

# ---- professor's program (design C) ----
REGS_A = [R(f"x{i}", f"x{i}") for i in (5, 6, 7, 9, 10)]
MEM = lambda ws: [R(f"M{4 * w}", f"M[x1+{4 * w}]") for w in ws]
CHECK = [R("chk", "chk (etapa)"), B("ok", "ok (estado = ref.)")]
WB = instr_rows("W")

fig("prog-A", design="C", prog="final/programa", win=(1, 13),
    title="Programa del profesor — cierre de la etapa A (doble emisión, RAW y forwarding)",
    rows=CLK + [R("PCF")] + instr_rows("DEW") + [None, B("IssueOneD"), B("RegroupD"), None,
         R("ForwardAE_0"), R("ForwardBE_0"), R("ALUResultE_0"), R("ForwardAE_1"), R("ForwardBE_1"),
         R("ALUResultE_1"), None] + CHECK + REGS_A + MEM(range(3)))

fig("prog-B", design="C", prog="final/programa", win=(10, 26),
    title="Programa del profesor — etapa B: load-use, un solo puerto de memoria y cierre de la etapa",
    rows=CLK + [R("PCF")] + instr_rows("DEMW") + [None, B("IssueOneD"), B("LoadUseD_0"), B("StallD"), B("RegroupD"),
         None, B("MemLaneM"), B("MemWrite"), R("DataAdr"), R("WriteData"), R("ReadDataM"), None] + CHECK
         + [R(f"x{i}") for i in (12, 15, 16, 17, 18)] + MEM(range(3, 6)))

fig("prog-C1", design="C", prog="final/programa", win=(25, 45),
    title="Programa del profesor — bucle C1: el BTB aprende el beq y lo predice tomado",
    rows=CLK + FETCH + instr_rows("DE") + [None, B("PredF_0"), B("PredF_1"), R("TargetF_1"), B("AnnulF_1"), None]
         + BU + [None, B("RegroupD"), B("FlushD"), None, R("x19"), R("x21")])

fig("prog-C2", design="C", prog="final/programa", win=(61, 88),
    title="Programa del profesor — bucle C2: un salto que alterna T/N y el contador de 2 bits",
    rows=CLK + FETCH + instr_rows("DE") + [None, B("PredF_0"), B("PredF_1"), None] + BU
         + [None, B("FlushD"), B("FlushM_1"), None, R("x22"), R("x23")])

fig("prog-C", design="C", prog="final/programa", win=(212, 221),
    title="Programa del profesor — cierre de la etapa C",
    rows=CLK + [R("PCF")] + instr_rows("EMW") + [None, B("CtrlE"), B("PredTakenE"), B("PCSrcE"), B("MispredictE"),
         None, B("MemWrite"), R("DataAdr"), R("WriteData"), None] + CHECK
         + [R(f"x{i}") for i in (19, 20, 21, 22, 24, 25)] + MEM(range(6, 9)))

fig("prog-D", design="C", prog="final/programa", win=(274, 292),
    title="Programa del profesor — final de la etapa D: saltos hacia adelante y cierre",
    rows=CLK + [R("PCF")] + instr_rows("EW") + [None, B("CtrlE"), B("PCSrcE"), B("PredTakenE"), B("MispredictE"),
         R("PCCorrectE"), None, B("MemWrite"), R("DataAdr"), R("WriteData"), None] + CHECK
         + [R(f"x{i}") for i in (25, 26, 27, 28, 29, 31)] + MEM(range(9, 14)))


def render_fig(name, spec, rows, out, highlights=(), notes=()):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.patches import Polygon, Rectangle

    c0, c1 = spec["win"]
    rows = [r for r in rows if c0 <= int(r["cycle"]) <= c1]
    n = len(rows)
    cyc = [int(r["cycle"]) for r in rows]
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
    figw = max(12, 2.4 + n * 0.82)
    # wrap the notes to the figure width; each note keeps one colour square
    import textwrap
    width = int((figw - 0.5) * 72 / (8.4 * 0.56))
    lines = []
    for col, txt in notes:
        for j, part in enumerate(textwrap.wrap(txt, width)):
            lines.append((col if j == 0 else None, part))
    notes = lines
    figh = 1.0 + total * 0.33 + 0.28 * len(notes) + 0.3
    fig_, ax = plt.subplots(figsize=(figw, figh), dpi=110)
    ax.set_xlim(-2.9, n * W + 0.05)
    ax.set_ylim(total + 0.2, -1.6)
    ax.axis("off")
    fig_.subplots_adjust(left=0.01, right=0.995, top=1 - 0.55 / figh, bottom=(0.28 * len(notes) + 0.25) / figh)
    ax.set_title(spec["title"], loc="left", fontsize=12, fontweight="bold", color="#222", pad=4)

    for h0, h1, col, lab in highlights:  # highlight columns are given as cycle numbers
        x0 = cyc.index(h0)
        x1 = cyc.index(h1)
        ax.add_patch(Rectangle((x0 * W, -0.7), (x1 - x0 + 1) * W, total + 0.7, color=col, alpha=0.18, lw=0, zorder=0))
        if lab:
            ax.text((x0 + x1 + 1) / 2 * W, -1.1, lab, ha="center", va="center", fontsize=7.5, fontweight="bold", color=col)
    for c in range(n + 1):
        ax.plot([c * W, c * W], [-0.3, total], color="#e6e6e6", lw=0.6, zorder=0.5)
    for c in range(n):
        ax.text((c + 0.5) * W, -0.45, str(cyc[c]), ha="center", va="center", fontsize=7, color="#777", family="monospace")
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
                lv = top if row[sig] == "1" else bot
                xs += [c * W, (c + 1) * W]
                yy += [lv, lv]
            col = "#1f9d55" if sig == "ok" else "#2f6fc9"
            ax.plot(xs, yy, color=col, lw=1.6 if sig == "ok" else 1.3)
            continue
        # bus / instruction: merge consecutive equal values into one segment
        vals = [fmt(sig, row[sig]) for row in rows]
        segs, s = [], 0
        for c in range(1, n + 1):
            if c == n or vals[c] != vals[s]:
                segs.append((s, c, vals[s]))
                s = c
        for s0, s1, v in segs:
            x0, x1, k = s0 * W, s1 * W, 0.12
            pts = [(x0, mid), (x0 + k, top), (x1 - k, top), (x1, mid), (x1 - k, bot), (x0 + k, bot)]
            empty = v in ("bubble", "x", "")
            if kind.startswith("instr"):
                ec = INSTR_COL[kind[5]]
                fc = "#ffffff" if empty else matplotlib.colors.to_rgba(ec, 0.13)
            elif sig == "chk" and v:
                ec, fc = "#1f9d55", matplotlib.colors.to_rgba("#1f9d55", 0.22)
            else:
                ec, fc = "#9aa3ad", "#f4f6f8" if not empty else "#fafafa"
            ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec if not empty else "#c9ced3", lw=0.8, zorder=2))
            fs = 7 if len(v) <= 9 else 6.2 if len(v) <= 13 else 5.6
            if (x1 - x0) * 8 < len(v) * fs * 0.62 and (x1 - x0) < 1.5:  # does not fit: smaller
                fs = max(4.6, fs - 1.2)
            ax.text((x0 + x1) / 2, mid, v, ha="center", va="center", fontsize=fs, family="monospace", zorder=3,
                    color="#888" if empty else "#222", style="italic" if empty else "normal",
                    fontweight="bold" if sig == "chk" else "normal")

    for i, (col, txt) in enumerate(notes):
        yy = 0.28 * (len(notes) - i) / figh - 0.04 / figh
        if col:
            fig_.patches.append(Rectangle((0.012, yy + 0.02 / figh), 0.09 / figw, 0.09 / figh,
                                          transform=fig_.transFigure, color=col, figure=fig_))
        fig_.text(0.03, yy, txt, fontsize=8.4, va="bottom", color="#222")
    fig_.savefig(out)
    plt.close(fig_)


def render(outdir, only=()):
    from notes import NOTES  # highlights and notes written after reading each trace
    tmp = tempfile.mkdtemp()
    cache = {}
    for name, spec in FIGS.items():
        if only and name not in only:
            continue
        key = (spec["design"], spec["prog"])
        if key not in cache:
            cache[key] = simulate(*key, tmp)
        hl, nt = NOTES.get(name, ((), ()))
        render_fig(name, spec, cache[key], os.path.join(outdir, f"waveform-{name}.png"), hl, nt)
        print("ok", f"waveform-{name}.png")


if __name__ == "__main__":
    sys.path.insert(0, HERE)
    if sys.argv[1] == "table":
        table(sys.argv[2], sys.argv[3], sys.argv[4:])
    else:
        render(sys.argv[2], sys.argv[3:])
