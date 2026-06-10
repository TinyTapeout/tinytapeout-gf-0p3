## How it works

Implements a simple interdigitated metal-oxide-metal capacitor:

![momcap layout illustration](momcap.png)

The repo contains both a script to generate a custom size capacitor
and a fixed instance filling a Tiny Tapeout analog slot (1x2 tiles).

## How to test

Measure the capacitance between terminals A and B.

You can use the dummy terminals to control for parasitic capacitance on the path
between your probes and the project pins.

For comparison, magic's circuit extraction estimates the capacitance at around 85 pF.

## External hardware

Test equipment (function generator + oscilloscope, or VNA).
