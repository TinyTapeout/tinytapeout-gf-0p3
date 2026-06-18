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

    wire vco_out;

    wire vin = ua[0];
    assign ua[1] = vco_out;

    digital digital_0 (
        .VDD        (VDPWR),
        .VSS        (VGND),
        .clk        (clk),
        .rst_n      (rst_n),
        .vco_in     (vco_out),
        .ui_in      (ui_in),
        .uio_in     (uio_in),
        .uio_oe     (uio_oe),
        .uio_out    (uio_out),
        .uo_out     (uo_out)
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
