`default_nettype none

module tt_um_tnt_gf_555 (
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

	// On-Chip oscillator
	wire osc;

	onchip_osc osc_I (
		.GND     (VGND),
		.VDD     (VDPWR),
		.reset_n (rst_n),
		.out     (osc)
	);

	assign uo_out[0] = osc;
	assign uio_oe[0] = osc;

	// DUT
	tnt555 dut_I (
		.GND       (VGND),
		.VDD       (VAPWR),
		.trigger   (ua[1]),
		.threshold (ua[0]),
		.control   (ua[3]),
		.reset_n   (ua[2]),
		.discharge (ua[5]),
		.out       (ua[4])
	);

	// Tie-offs
	assign uo_out[7:1]  = {7{VGND}};
	assign uio_out      = {8{VGND}};
	assign uio_oe[7:1]  = {7{VGND}};

endmodule
