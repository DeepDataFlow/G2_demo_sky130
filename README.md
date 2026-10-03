# G2_demo_sky130

A ready-made [G2](https://github.com/DeepDataFlow/G2) project on the
**SkyWater 130nm (sky130)** PDK. Clone it into your G2 workspace and you
can start working on real designs right away. You don't need to set up a
project, scenarios or libraries yourself.

![G2 Impl Status view of G2_demo_sky130](snapshot/snapshot1.png)

*The Impl Status view at the Place stage of the `v01` run. For each block,
it shows the floorplan, the RUDY congestion map, errors, runtime,
instance count, reg2reg timing, and the flows used.*

## What's Inside

| | |
|---|---|
| **Blocks** | `gcd` and `spm`, each with implementation version `v01`; `ibex_top` (lowRISC Ibex RISC-V core with 4 SRAM macros) with `v01` and `v02` |
| **Design data (DDM)** | RTL, SDC (syn / APR / signoff × `func`, `shift`), UPF and floorplan |
| **Signoff scenarios** | 2 modes (`func`, `shift`) × 4 PVT corners |
| **Libraries (LIM)** | `sky130_fd_sc_hd`, `sky130_fd_sc_hdll` stdcells; `fakeram45_*` memory macros from the G2 package; `fakeram_256x22` / `fakeram_256x64` memory macros shipped in this project (`ldata/`) |
| **Flows in gcd / spm `v01`** | Yosys, OpenDFT, OpenROAD, OpenRCX, OpenSTA, OpenPV, OpenIR, OpenPower, OpenEC and OpenLP, already checked out and configured |
| **Flows in ibex_top `v01` / `v02`** | Yosys and OpenSTA, set up for a synthesis comparison (see [ibex_top: Basic vs Advanced Synthesis](#ibex_top-basic-vs-advanced-synthesis)) |
| **Reference results** | QoR from a previous gcd / spm `v01` run (per-stage OpenROAD timing, floorplan and congestion images) |

The reference results let you compare your own runs against a known
baseline right away.

Large generated files aren't in Git: netlists, the `syn` / `apr_*` DDM
data, logs and databases. You regenerate them when you run the flows.

## Requirements

- A working G2 workspace. See the
  [G2 Quick Start](https://github.com/DeepDataFlow/G2#quick-start).
- The G2 release package, which provides the sky130 PDK in
  `$G2_ROOT/../pdk/sky130`.

## Quick Start

```bash
# 1. Load your G2 environment
cd <your G2 workspace>
source g2.rc

# 2. Clone the project into the workspace's projs/ directory
cd $G2_SYS/projs
git clone https://github.com/DeepDataFlow/G2_demo_sky130

# 3. Link the sky130 PDK and install the libraries from your G2 package
cd G2_demo_sky130
make setup
```

Refresh the G2 web UI. **G2_demo_sky130** now appears in your project list.

`make setup` must be run **inside the project directory** with `g2.rc`
already sourced. It runs two scripts:

| Script | What it does |
|---|---|
| `.scripts/setup_pdk.tcl` | Points `spec/pdk` at the sky130 tech LEF, RC, RCX and KLayout files in your G2 package, and sets the synthesis corner. These paths are machine-specific, so it also tells Git to ignore your local copy of `spec/pdk/.vars.tcl` (`--skip-worktree`) |
| `.scripts/install_library.tcl` | Installs the stdcell and memory libraries into LIM (from your G2 package, and the ibex_top SRAM macros from `ldata/`) and parses every liberty file |

## Try It

New to G2? The [Getting Started video series](https://www.youtube.com/playlist?list=PLZvKK6r2180A) shows this workflow
step by step. The videos use the Nangate45 demo, so the library names and
numbers differ from this project, but the pages and steps are the same.

1. Open **Impl → gcd → v01** to see the reference results.
2. Run the flows in order: **yosys** → **openroad** → **openrcx** →
   **opensta** → **openpv**. Every flow uses the same steps: go to the
   **Exec** view, click **Gen**, then **Run**, then **QoR**.
   [Tutorial #3](https://www.youtube.com/watch?v=saEB3l4aPWk) runs the first four of these flows.
3. Compare your QoR against the reference numbers.
4. Experiment with a new version, such as `v02`: change the clock
   target, utilization or scripts, then compare `v01` and `v02` side by
   side in the **Status** view. [Tutorial #5](https://www.youtube.com/watch?v=99AJz-IdMXw) does this
   with a new clock constraint.

A good first challenge: the `v01` baseline for gcd at 1 GHz does not meet
setup timing at the slow corner. See how close you can get.
[Tutorial #6](https://www.youtube.com/watch?v=8SoFOXsoSHk) shows how to find out why a path fails.

## ibex_top: Basic vs Advanced Synthesis

`ibex_top` is the [lowRISC Ibex](https://github.com/lowRISC/ibex) RISC-V
core (commit `654ac71f`, Apache-2.0) configured with its instruction
cache on, so it has 4 SRAM macros: 2 ways × (tag RAM 256×22 + data RAM
256×64). Same RTL and constraints, two synthesis scripts, judged with
OpenSTA:

| Version | Yosys script | What it does |
|---|---|---|
| `v01` | `yosys.tcl` (Basic) | Generic synthesis, then area-oriented mapping (`abc -liberty`). No timing information. |
| `v02` | `yosys_adv.tcl` (Advanced) | Timing-driven mapping: `abc -D <ps> -constr`, plus `synth -booth`. The delay target, driving cell and load are read from `sdc_syn`, so the SDC stays the single source of the constraint values. |

Yosys can't optimize to an SDC. Its only timing controls are ABC's `-D`
(one delay target) and `-constr` (driving cell and output load). `-D`
alone leaves this design unchanged: ABC only buffers and resizes gates
when `-constr` is also given.

### How the design data is set up

- **RTL** (`ddm/ibex_top/rtl/v01`): only the files this configuration
  needs. The first line of `rtl.f`, `-GICache=1`, sets the configuration
  without editing the vendor RTL.
- **Technology layer** (`lowrisc_ip/ip/prim_sky130/rtl/`): a
  `prim_ram_1p` that maps each RAM shape onto a FakeRAM macro, and a
  `prim_clock_gating` that uses the sky130 `sdlclkp` clock-gating cell.
  Every other RTL file is identical to upstream.
- **Constraints**: `sdc_syn/v01` (40 ns clock at ss/100°C/1.60V, I/O
  delays at 25% of the period, false paths on static configuration
  inputs and resets) and `sdc_signoff_func/v01`, which has the same
  constraints for pre-layout STA.
- **SRAM macros** (`ldata/mem/`): FakeRAM-generated LEF, Verilog model
  and 4 corner libs. They are abstract views (no GDS).

### Run it

For each of `v01` and `v02` (Impl → ibex_top → `<version>`):

1. **yosys** → Exec view: **Gen** → **Run** (about 25 s) → **QoR**.
2. **yosys** → Chkin view: check the netlist into DDM as `syn/<version>`.
3. **opensta** → `func.max_ss1p600v100c_cworst` → Exec view: **Gen** →
   **Run** (about 1 min). Use **Gen inside the scenario**, not **Gen all**
   at the opensta level: Gen all also checks out the shift-mode
   scenarios, which have no SDC for this block.

Each version's opensta reads its own netlist: `v01` → `syn:v01`,
`v02` → `syn:v02` (DDM view → Block Data).

Then open **Impl → ibex_top → Status view → STA stage**. Turn on
**Column → IO** to see the in2reg, reg2out and in2out groups next to
reg2reg.

### Expected results

`func.max_ss1p600v100c_cworst`, before layout (ideal clock, no wire
parasitics):

| | `v01` Basic | `v02` Advanced |
|---|---|---|
| reg2reg WNS (ns) | −16.25 | met (+6.65) |
| in2reg / reg2out WNS (ns) | −12.17 / −12.32 | met |
| in2out | met | met |
| Instances | 16,678 | 17,477 (+4.8%) |
| Buffers | 0 | 1,494 |
| Registers / SRAM macros | 2,395 / 4 | 2,395 / 4 |

The Basic netlist fails mainly because of unbuffered high-fanout nets:
its worst path has one flip-flop driving 259 pins. Things that look
wrong but are expected:

- opensta reports about 17–18k SPEF errors and one `read_spef` error:
  there's no layout yet, so there are no parasitics.
- `v02` still has max-transition violations: ABC buffers for delay, not
  slew. Place and route repairs them.

To look inside a netlist, check out **netins** in a version, then
**Gen** → **Run** → **QoR**. It also writes a starting SDC to
`out/sdc.tcl`.

## Project Layout

```
G2_demo_sky130/
├── spec/        project settings, block specs, signoff scenarios, PDK paths
├── lim/         libraries (stdcell, mem, hip, io)
├── ddm/         versioned design data (rtl, sdc, upf, syn, apr_*)
├── impl/        implementation runs: impl/<block>/<version>/<flow>
├── scm/         flow scripts
├── ldata/       library data shipped with the project (ibex_top SRAM macros)
├── checklist/   QA checklists
├── docs/        project documents
└── .scripts/    setup scripts called by `make setup`
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `sd: command not found` during `make setup` | Run `source g2.rc` in your workspace first. |
| `make setup` can't find PDK files | Check that `$G2_ROOT/../pdk/sky130` exists. It ships in the G2 release package. |
| The project doesn't appear in the UI | Make sure you cloned it into `$G2_SYS/projs/`, then refresh the page. |
| Flows fail with missing netlist or `syn` data | Expected on a fresh clone. Run yosys first and check its netlist into DDM. |
| `git pull` refuses to overwrite `spec/pdk/.vars.tcl` | Run `git update-index --no-skip-worktree spec/pdk/.vars.tcl`, then `git checkout spec/pdk/.vars.tcl`, pull, and run `make setup` again. |
| netins counts thousands of "Macro" cells for ibex_top | Your G2 package's `$G2_USER/netins/mapping.cfg` doesn't know sky130 cell names. Add `__a4 : Compound`, `__o4 : Compound`, `__df : Seq-FF`, `__sdlclkp : ICG` and `^fakeram : Memory`, then click **QoR** again. |
