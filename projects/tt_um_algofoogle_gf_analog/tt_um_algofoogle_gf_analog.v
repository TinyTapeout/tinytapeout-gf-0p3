/*
 * Copyright (c) 2026 Anton Maurovic
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_algofoogle_gf_analog (
    input  wire       VGND,
    input  wire       VDPWR,    // 3.3v core power supply
//    input  wire       VAPWR,    // second analog power supply (VAA)
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    inout  wire [7:0] ua,       // Analog pins, only ua[5:0] can be used
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire vco_out; // Weakly buffered output from main VCO block.
    wire vco_in; // Buffered VCO output, going into the digital block.

    wire vin = ua[0]; // VCO control voltage.

    digital digital_0 (
        .VDD        (VDPWR),
        .VSS        (VGND),
        .clk        (clk),
        .rst_n      (rst_n),
        .vco_in     (vco_in),
        .ui_in      (ui_in),
        .uio_in     (uio_in),
        .uio_oe     (uio_oe),
        .uio_out    (uio_out),
        .uo_out     (uo_out)
    );

    // Buffer vco_out and send it out ua[1]:
    wire ua1buf_mid;
    bufinv_2 ua1buf0 (
        .VCC        (VDPWR),
        .VSS        (VGND),
        .A          (vco_out),
        .Y          (ua1buf_mid)
    );
    bufinv_2 ua1buf1 (
        .VCC        (VDPWR),
        .VSS        (VGND),
        .A          (ua1buf_mid),
        .Y          (ua[1])
    );

    // Also buffer vco_out and send it all the way across the tile
    // to another buffer that drives the signal into the digital block:
    wire txdigbuf_mid;
    wire vco_tx;
    wire rxdigbuf_mid;
    bufinv_2 txdigbuf0 (
        .VCC        (VDPWR),
        .VSS        (VGND),
        .A          (vco_out),
        .Y          (txdigbuf_mid)
    );
    bufinv_2 txua1buf1 (
        .VCC        (VDPWR),
        .VSS        (VGND),
        .A          (txdigbuf_mid),
        .Y          (vco_tx)
    );
    bufinv_2 rxdigbuf0 (
        .VCC        (VDPWR),
        .VSS        (VGND),
        .A          (vco_tx),
        .Y          (rxdigbuf_mid)
    );
    bufinv_2 rxua1buf1 (
        .VCC        (VDPWR),
        .VSS        (VGND),
        .A          (rxdigbuf_mid),
        .Y          (vco_in)
    );

    csringosc csringosc_0 (
        .VCC    (VDPWR),
        .VSS    (VGND),
        .vin    (vin),
        .osc_out(vco_out)
        // .vbiasp(),
        // .vbiasn(),
        // .osc_raw(),
    );

endmodule
