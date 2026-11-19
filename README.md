# Procesador RISC-V Dual-Issue con predicción de saltos

Proyecto de Arquitectura de Computadores: un procesador RISC-V (subconjunto de RV32I) en Verilog que
evoluciona en cuatro diseños, desde un single-cycle hasta un Dual-Issue In-Order con un
predictor dinámico de saltos.

## Diseños (`designs/`)

| Carpeta         | Descripción |
|-----------------|-------------|
| `singlecycle`   | Procesador single-cycle base (Harris & Harris). |
| `pipeline`      | **A**: pipeline de 5 etapas con forwarding, stalls y flush. |
| `dualissue`     | **B**: Dual-Issue In-Order: dos vías, Register File de 4 lecturas y 2 escrituras, Issue Unit que emite 2, 1 o 0 instrucciones por ciclo. |
| `dualissue-btb` | **C**: B + Branch Target Buffer de 16 entradas con contador saturado de 2 bits. |

Instrucciones soportadas: `add sub and or xor slt addi andi ori xori slti lw sw beq jal`.

## Pruebas (`tb/`)

- `perf_tb.v`: testbench común a A, B y C. Mide ciclos, IPC, stalls, flushes y errores de
  predicción, e imprime los registros y la memoria de datos al final.
- `run_all.sh`: corre todos los programas en las tres arquitecturas, comprueba que terminen en el
  mismo estado y muestra ciclos, IPC y speedups.
- `asm.py`: ensamblador mínimo que convierte un `.s` en `.mem`.
- `programs/`: programas de prueba (`pipeline/`, `dualissue/`, `opt/`), benchmarks (`bench/`) y
  el programa del proyecto final (`final/`).

Requiere [Icarus Verilog](https://steveicarus.github.io/iverilog/).

```bash
./tb/run_all.sh              # todos los programas
./tb/run_all.sh bench/       # solo una carpeta
./tb/run_all.sh -v bench/    # con el reporte completo
python3 tb/asm.py prog.s     # genera prog.mem
```

Resultados de los benchmarks:

| Programa        | IPC A | IPC B | IPC C | Speedup A→C |
|-----------------|:-----:|:-----:|:-----:|:-----------:|
| `bubble_sort`   | 0.769 | 0.939 | 1.148 | 1.49 |
| `random_branch` | 0.744 | 0.861 | 1.139 | 1.53 |
| `sieve`         | 0.637 | 0.752 | 1.219 | 1.91 |

## Documentación (`docs/`)

- `informes/`: informes de las entregas E1, E2 y el informe final.
- `guias/`: guías de cada paso (single-cycle → pipeline → dual-issue → BTB).
- `diapositivas/`: presentación final.
- `imgs/`: diagramas de los procesadores en SVG.

Cada documento se compila con su `build.sh` (necesita `pdflatex` y `rsvg-convert`; las waveforms
se regeneran con `./build.sh waves`, que usa `uv` y `matplotlib`).
