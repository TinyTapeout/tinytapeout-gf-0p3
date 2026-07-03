`default_nettype none

module tt_um_tnt_gf_vco (
    input  wire       VGND,
    input  wire       VDPWR,
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    inout  wire [7:0] ua,       // analog pins
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

	// DUT
	vco dut_I (
		.GND       (VGND),
		.VDD       (VDPWR),
		.ctrl      (ua[2]),
		.out_0     (uo_out[0]),
		.out_90    (ua[1]),
		.out_180   (ua[0]),
		.out_270   (uo_out[1])
	);

	// Tie-offs
	assign uo_out[7:2] = {6{VGND}};
	assign uio_out = {8{VGND}};
	assign uio_oe  = {8{VGND}};

endmodule
