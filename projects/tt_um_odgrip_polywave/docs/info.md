# PolyWave

PolyWave is a four-channel mixed-signal waveform source. A compact digital
engine generates four 16-bit sample streams, and the custom GF180 layout converts
those streams to analog voltages with four R-2R DAC ladders.

The design is intended as a small multi-output waveform lab for synchronized
signals, modulation experiments, DAC characterization and mixed-signal Tiny
Tapeout demonstrations.

## How it works

The digital engine contains four 20-bit phase accumulators, a shared 16-bit
LFSR/noise source, a 4-bit sequencer and four 16-bit DAC sample registers. It can
run autonomously in generated-waveform mode, or it can accept direct byte writes
to any DAC channel.

The four DAC sample registers drive inverted 16-bit layout buses named
`R2R_Bn_0`, `R2R_Bn_1`, `R2R_Bn_2` and `R2R_Bn_3`. These buses feed the four
physical R-2R ladders in the custom GDS. The analog DAC outputs are exposed on
`ua[0]` to `ua[3]`.

This repository uses the Tiny Tapeout custom GDS path. The prebuilt `gds/` and
`lef/` files are the physical source for the submitted layout. `src/project.v`
documents and syntax-checks the mixed-signal partition used by the layout; it is
not synthesized by the submission action into a new layout. The public
`tt_um_odgrip_polywave` module keeps the standard Tiny Tapeout analog port list,
instantiates `polywave_top_digital` for the digital waveform engine, and
instantiates `polywave_top_analog_stub` as the analog boundary that represents
the custom GDS. The R-2R buses are internal signals between those two blocks,
not top-level ports.

The submitted analog frame uses the GF180 pgvaa Tiny Tapeout interface, so
`VAPWR` remains part of the project interface even though the current digital
engine does not consume the analog supply internally.

## Digital controls

### Generated mode

Set `ui_in[7]` low to use the autonomous waveform generator.

| Signal | Function |
| --- | --- |
| `ui_in[2:0]` | Extra live modulation bits and low-cost phase nudges |
| `ui_in[3]` | Fast internal tempo select |
| `ui_in[5:4]` | Scene selection for the waveform formulas |
| `ui_in[6]` | Freeze phase accumulator updates while held high |
| `uio_in[7:0]` | Live modulation/control bus used by the waveform engine |

In this mode the four phase accumulators, cross-modulation paths, sequencer,
noise source, saw/triangle/PWM/stepped waveforms and live controls generate the
four DAC values.

### Direct DAC mode

Set `ui_in[7]` high to stop generated DAC updates and write DAC codes directly.

| Signal | Function |
| --- | --- |
| `ui_in[5:4]` | DAC channel select: 0 to 3 |
| `ui_in[3]` | Byte select: 0 for low byte, 1 for high byte |
| `uio_in[7:0]` | Byte value to load |
| `ui_in[6]` | Rising-edge load strobe |

To write a full 16-bit DAC code, load the low byte and high byte separately with
two pulses on `ui_in[6]`.

## Outputs

| Signal | Function |
| --- | --- |
| `ua[0]` | DAC A analog output |
| `ua[1]` | DAC B analog output |
| `ua[2]` | DAC C analog output |
| `ua[3]` | DAC D analog output |
| `uo_out[2:0]` | Mirror of `ui_in[2:0]` live modulation bits |
| `uo_out[6:3]` | Current 4-bit sequencer step |
| `uo_out[7]` | Tempo tick |
| `uio_out[7:0]` | Always zero |
| `uio_oe[7:0]` | Always zero, so the bidirectional pins are input-only controls |

## How to test

1. Apply power to the design.
2. Provide the system clock and release reset.
3. Hold `ui_in[7]` low for generated-waveform mode.
4. Observe `ua[0]` to `ua[3]` with an oscilloscope or data acquisition system.
5. Change `ui_in[5:4]`, `ui_in[3]`, `ui_in[2:0]` and `uio_in[7:0]` to exercise the live waveform controls.
6. Set `ui_in[7]` high and use direct DAC mode to write known 16-bit codes to each channel.
7. Check `uo_out[7]` and `uo_out[6:3]` for the tempo tick and sequencer state.

## External hardware

Use a clock/reset source, digital control source for `ui_in` and `uio_in`, and an
oscilloscope, logic analyzer or data acquisition system to observe the analog and
status outputs.
