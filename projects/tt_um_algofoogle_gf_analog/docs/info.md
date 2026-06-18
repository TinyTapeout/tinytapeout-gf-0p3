## How it works

This is a simple VCO experiment using a current-starved ring oscillator. It consists of 5 current-starved inverter stages in a ring, followed by a buffer pair. This is output via `ua[1]` and also fed to a digital test block where it is divided using a 5-bit synchronous counter and presented on `uio_out[5:1]`, beside a buffered (but non-divided) copy of the VCO output on `uio_out[0]` (aka `osc_out`).

For a given input voltage (`vin`, i.e. `ua[0]`) in the range 0.55V to 3.3V, the oscillator output (`vco_out`, i.e. `ua[1]`) is expected to be a square wave roughly in the range of 2MHz to 400MHz.


## How to test

*   Apply power with `vin` held at 0V and `rst_n` high. No TT `clk` is required. Expect to see no oscillation on `vco_out` or `uio_out[5:1]`.
*   Raise `vin` to 0.55V, and you _might_ see `vco_out` oscillating at about 2MHz, 3.3Vpp, about 50% duty cycle.
*   Raise `vin` slowly and if `vco_out` wasn't already oscillating then you should see it start at least by the time `vin` reaches 0.65V (if not sooner), and as you raise `vin` further the frequency at `vco_out` should rapidly increase.
*   Observe digital-buffered (and TT-digital-mux-shaped) output of the VCO on `uio_out[0]`, and then halving of the frequency up through each of `uio_out[1]` to `uio_out[5]`.


## External hardware

*   Precision variable voltage source for `vin`.
*   Oscilloscope to monitor `vco_out`.
