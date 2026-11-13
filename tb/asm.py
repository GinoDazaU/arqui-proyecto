#!/usr/bin/env python3
"""Minimal RV32I assembler for the subset supported by the three processors.

    python3 tb/asm.py prog.s            # writes prog.mem next to it
    python3 tb/asm.py prog.s -o out.mem

Instructions: add sub and or xor slt | addi andi ori xori slti | lw sw | beq | jal
Source: "label:" before an instruction, comments after ';', header lines starting with "//"
(copied to the top of the .mem). Branch/jump targets are labels or byte offsets.
Output lines use the format of tb/programs: "<hex>  // <addr>: <instr>  ; <label>: <comment>".
"""
import re
import sys

R = {"add": (0, 0), "sub": (0, 32), "and": (7, 0), "or": (6, 0), "xor": (4, 0), "slt": (2, 0)}
I = {"addi": 0, "andi": 7, "ori": 6, "xori": 4, "slti": 2}


def reg(t):
    m = re.fullmatch(r"x(\d+)", t)
    if not m or int(m.group(1)) > 31:
        raise ValueError(f"bad register '{t}'")
    return int(m.group(1))


def imm(t, labels, pc, bits, pcrel=False):
    if t in labels:
        v = labels[t] - pc if pcrel else labels[t]
    else:
        v = int(t, 0)
    if not -(1 << (bits - 1)) <= v < (1 << (bits - 1)):
        raise ValueError(f"immediate {v} out of range ({bits} bits)")
    return v & ((1 << bits) - 1)


def encode(op, a, labels, pc):
    if op in R:
        f3, f7 = R[op]
        rd, rs1, rs2 = map(reg, a)
        return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x33
    if op in I:
        rd, rs1 = reg(a[0]), reg(a[1])
        return (imm(a[2], labels, pc, 12) << 20) | (rs1 << 15) | (I[op] << 12) | (rd << 7) | 0x13
    if op in ("lw", "sw"):
        m = re.fullmatch(r"(.+)\((x\d+)\)", a[1])
        if not m:
            raise ValueError("expected offset(reg)")
        off, base = imm(m.group(1), labels, pc, 12), reg(m.group(2))
        if op == "lw":
            return (off << 20) | (base << 15) | (2 << 12) | (reg(a[0]) << 7) | 0x03
        return ((off >> 5) << 25) | (reg(a[0]) << 20) | (base << 15) | (2 << 12) | ((off & 31) << 7) | 0x23
    if op == "beq":
        rs1, rs2 = reg(a[0]), reg(a[1])
        v = imm(a[2], labels, pc, 13, pcrel=True)
        return (((v >> 12) & 1) << 31) | (((v >> 5) & 63) << 25) | (rs2 << 20) | (rs1 << 15) | \
               (((v >> 1) & 15) << 8) | (((v >> 11) & 1) << 7) | 0x63
    if op == "jal":
        rd = reg(a[0])
        v = imm(a[1], labels, pc, 21, pcrel=True)
        return (((v >> 20) & 1) << 31) | (((v >> 1) & 1023) << 21) | (((v >> 11) & 1) << 20) | \
               (((v >> 12) & 255) << 12) | (rd << 7) | 0x6F
    raise ValueError(f"unsupported instruction '{op}'")


def assemble(src):
    header, items, labels, pending = [], [], {}, []
    for n, line in enumerate(src.splitlines(), 1):
        if line.startswith("//"):
            header.append(line.rstrip())
            continue
        code, _, comment = line.partition(";")
        code = code.strip()
        m = re.match(r"([A-Za-z_]\w*):\s*(.*)", code)
        if m:
            labels[m.group(1)] = 4 * len(items)
            pending.append(m.group(1))
            code = m.group(2)
        if code:
            items.append((n, code, pending, comment.strip()))
            pending = []
    if len(items) > 256:
        sys.exit(f"program has {len(items)} words, the instruction memory holds 256")
    out = header[:]
    for i, (n, code, labs, comment) in enumerate(items):
        op, *rest = code.split(None, 1)
        args = [t.strip() for t in rest[0].split(",")] if rest else []
        try:
            w = encode(op.lower(), args, labels, 4 * i)
        except (ValueError, IndexError) as e:
            sys.exit(f"line {n}: {e}: {code}")
        text = f"{op:<4} {', '.join(args)}"
        note = "; ".join(x for x in [", ".join(l + ":" for l in labs), comment] if x)
        note = note.replace(":; ", ": ")
        out.append(f"{w:08X}  // {4 * i:3d}: {text:<22} ; {note}".rstrip(" ;"))
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    src = sys.argv[1]
    dst = sys.argv[sys.argv.index("-o") + 1] if "-o" in sys.argv else re.sub(r"\.s$", "", src) + ".mem"
    with open(src) as f:
        text = assemble(f.read())
    with open(dst, "w") as f:
        f.write(text)
    print("ok", dst)
