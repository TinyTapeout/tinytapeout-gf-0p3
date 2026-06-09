`default_nettype none

module tt_um_analog_factory_test (
    input  wire       VGND,
    input  wire       VDPWR,
    input  wire       VAPWR,
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

	// Loads
	mirror_load ld_vdpwr_I (
		.VGND      (VGND),
		.VDPWR     (VDPWR),
		.VAPWR     (VAPWR),
		.ena       (ui_in[0]),
		.iref      (ua[0]),
		.rail      (VDPWR)
	);

	mirror_load ld_vapwr_I (
		.VGND      (VGND),
		.VDPWR     (VDPWR),
		.VAPWR     (VAPWR),
		.ena       (ui_in[1]),
		.iref      (ua[0]),
		.rail      (VAPWR)
	);

	// Power sense
	assign ua[1] = VGND;
	assign ua[2] = VDPWR;
	assign ua[3] = VAPWR;

	// Loopback
	assign ua[5] = ua[4];

	// Tie-offs
	assign uo_out  = {8{VGND}};
	assign uio_out = {8{VGND}};
	assign uio_oe  = {8{VGND}};

endmodule
