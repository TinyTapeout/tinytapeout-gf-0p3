/*
 * Copyright (c) 2026 Riccardo Pellegrini
 * SPDX-License-Identifier: Apache-2.0
 *
 * Quad 16-bit R2R performance engine for a 328.72um x 206um TT GF180 pgvaa slot.
 *
 * The engine is intentionally area-aware: four phase accumulators, shared noise,
 * cross-modulated timing, sequencer offsets, PWM and stepped/noisy outputs. It
 * avoids large multipliers/ROMs so the block has a realistic chance of fitting
 * in the available standard-cell area.
 *
 * ui_in[2:0] extra live modulation bits
 * ui_in[3]  fast internal tempo; direct byte select when ui_in[7]=1
 * ui_in[5:4] live scene select; direct channel select when ui_in[7]=1
 * ui_in[6]  freeze phase; direct load strobe when ui_in[7]=1
 * ui_in[7]  direct DAC mode
 * uio_in    8-bit live modulation/control input bus
 *           direct byte data when ui_in[7]=1
 * uio_out   unused
 * ua        Tiny Tapeout analog pins; driven by the custom GDS R-2R ladders
 * VAPWR     present for the Tiny Tapeout pgvaa analog frame; unused internally
 *
 * R2R_Bn_0..3 are internal mixed-signal layout buses. They drive the four
 * physical R-2R ladders in the custom GDS and are not Tiny Tapeout user pins.
 *
 * Direct DAC mode:
 *   ui_in[7]   = 1 freezes generated DAC updates and enables direct loading.
 *   ui_in[5:4] = channel select: 0..3.
 *   ui_in[3]   = byte select: 0 loads low byte, 1 loads high byte.
 *   uio_in     = byte value.
 *   Pulse ui_in[6] high for at least one clk to load the selected byte.
 */

`default_nettype none

module tt_um_odgrip_polywave (
    input  wire       VGND,
    input  wire       VDPWR,
    input  wire       VAPWR,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    inout  wire [7:0] ua,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [15:0] R2R_Bn_0;
    wire [15:0] R2R_Bn_1;
    wire [15:0] R2R_Bn_2;
    wire [15:0] R2R_Bn_3;

    polywave_top_digital top_digital (
        .VGND(VGND),
        .VDPWR(VDPWR),
        .VAPWR(VAPWR),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .R2R_Bn_0(R2R_Bn_0),
        .R2R_Bn_1(R2R_Bn_1),
        .R2R_Bn_2(R2R_Bn_2),
        .R2R_Bn_3(R2R_Bn_3),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    polywave_top_analog_stub top_analog (
        .VGND(VGND),
        .VDPWR(VDPWR),
        .VAPWR(VAPWR),
        .R2R_Bn_0(R2R_Bn_0),
        .R2R_Bn_1(R2R_Bn_1),
        .R2R_Bn_2(R2R_Bn_2),
        .R2R_Bn_3(R2R_Bn_3),
        .ua(ua)
    );

endmodule

module polywave_top_digital (
    input  wire       VGND,
    input  wire       VDPWR,
    input  wire       VAPWR,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    output wire [15:0] R2R_Bn_0,
    output wire [15:0] R2R_Bn_1,
    output wire [15:0] R2R_Bn_2,
    output wire [15:0] R2R_Bn_3,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire _unused = VGND ^ VDPWR ^ VAPWR ^ ena;

    reg [19:0] phase_0, phase_1, phase_2, phase_3;
    reg [15:0] lfsr;
    reg [3:0] seq_step;
    reg [15:0] dac_0, dac_1, dac_2, dac_3;
    reg direct_load_d;

    localparam [19:0] INC_0 = 20'h05555;
    localparam [19:0] INC_1 = 20'h07333;
    localparam [19:0] INC_2 = 20'h0a199;
    localparam [19:0] INC_3 = 20'h0f111;

    reg [19:0] tempo_div;
    wire [19:0] tempo_limit = ui_in[3] ? 20'd8191 : 20'd65535;
    wire tempo_tick = tempo_div == tempo_limit;
    wire direct_mode = ui_in[7];
    wire direct_load_rise = direct_mode & ui_in[6] & ~direct_load_d;

    wire [16:0] phase_0_seq_hi = phase_0[19:3] + {seq_step, 13'd0};
    wire [16:0] phase_2_live_hi = phase_2[19:3] + {uio_in[3:0], 13'd0};
    wire signed [15:0] saw_0 = saw16(phase_0[19:4]);
    wire signed [15:0] saw_1 = saw16(phase_1[19:4]);
    wire signed [15:0] saw_2 = saw16(phase_2[19:4]);
    wire signed [15:0] saw_3 = saw16(phase_3[19:4]);
    wire signed [15:0] tri_0 = tri17(phase_0_seq_hi);
    wire signed [15:0] tri_1 = tri17({phase_1[19], phase_1[18:3]});
    wire signed [15:0] tri_2 = tri17(phase_2_live_hi);
    wire signed [15:0] tri_3 = tri17({phase_3[19], phase_3[18:3]});
    wire signed [15:0] noise = $signed(lfsr);
    wire signed [15:0] pwm_1 = phase_1[19:4] < {1'b0, uio_in, 7'd0} ? 16'sd32767 : -16'sd32767;
    wire signed [15:0] step_2 = {phase_2[19], phase_2[18:16], lfsr[11:0]};

    wire signed [15:0] wave_0 = ui_in[4] ? tri_0 : (saw_0 + (tri_3 >>> 2));
    wire signed [15:0] wave_1 = ui_in[4] ? pwm_1 : (tri_1 + (saw_1 >>> 3));
    wire signed [15:0] wave_2 = ui_in[5] ? noise : (step_2 ^ tri_2);
    wire signed [15:0] wave_3 = ui_in[5] ? (saw_3 ^ noise) : ((tri_3 >>> 1) + (saw_2 >>> 1));

    wire signed [19:0] cm_0 = {{12{wave_3[15]}}, wave_3[15:8]};
    wire signed [19:0] cm_1 = {{12{wave_0[15]}}, wave_0[15:8]};
    wire signed [19:0] cm_2 = {{12{wave_1[15]}}, wave_1[15:8]};
    wire signed [19:0] cm_3 = {{12{wave_2[15]}}, wave_2[15:8]};
    wire [19:0] live_nudge = {8'd0, uio_in, 4'd0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_0 <= 20'd0;
            phase_1 <= 20'd0;
            phase_2 <= 20'd0;
            phase_3 <= 20'd0;
            lfsr <= 16'hace1;
            seq_step <= 4'd0;
            dac_0 <= 16'h8000;
            dac_1 <= 16'h8000;
            dac_2 <= 16'h8000;
            dac_3 <= 16'h8000;
            direct_load_d <= 1'b0;
            tempo_div <= 20'd0;
        end else begin
            direct_load_d <= ui_in[6];

            if (direct_load_rise) begin
                case ({ui_in[5:4], ui_in[3]})
                    3'b000: dac_0[7:0] <= uio_in;
                    3'b001: dac_0[15:8] <= uio_in;
                    3'b010: dac_1[7:0] <= uio_in;
                    3'b011: dac_1[15:8] <= uio_in;
                    3'b100: dac_2[7:0] <= uio_in;
                    3'b101: dac_2[15:8] <= uio_in;
                    3'b110: dac_3[7:0] <= uio_in;
                    default: dac_3[15:8] <= uio_in;
                endcase
            end

            if (tempo_tick) begin
                tempo_div <= 20'd0;
                seq_step <= seq_step + 4'd1;
            end else begin
                tempo_div <= tempo_div + 20'd1;
            end

            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            if (!ui_in[6] && !direct_mode) begin
                phase_0 <= phase_0 + INC_0 + cm_0[19:0] + live_nudge + {17'd0, ui_in[2:0]};
                phase_1 <= phase_1 + INC_1 + cm_1[19:0] + {live_nudge[18:0], 1'b0};
                phase_2 <= phase_2 + INC_2 + cm_2[19:0] + {1'b0, live_nudge[19:1]};
                phase_3 <= phase_3 + INC_3 + cm_3[19:0] + {15'd0, ui_in[2:0], 2'd0};
            end

            if (!direct_mode) begin
                dac_0 <= wave_0 ^ 16'h8000;
                dac_1 <= wave_1 ^ 16'h8000;
                dac_2 <= wave_2 ^ 16'h8000;
                dac_3 <= wave_3 ^ 16'h8000;
            end
        end
    end

    assign R2R_Bn_0 = ~dac_0;
    assign R2R_Bn_1 = ~dac_1;
    assign R2R_Bn_2 = ~dac_2;
    assign R2R_Bn_3 = ~dac_3;

    assign uo_out = {tempo_tick, seq_step, ui_in[2:0]};
    assign uio_out = 8'h00;
    assign uio_oe = 8'h00;

    function signed [15:0] saw16;
        input [15:0] ph;
        begin
            saw16 = ph ^ 16'h8000;
        end
    endfunction

    function signed [15:0] tri17;
        input [16:0] ph;
        reg [15:0] mag;
        begin
            mag = ph[16] ? ~ph[15:0] : ph[15:0];
            tri17 = mag ^ 16'h8000;
        end
    endfunction

endmodule

module polywave_top_analog_stub (
    input  wire        VGND,
    input  wire        VDPWR,
    input  wire        VAPWR,
    input  wire [15:0] R2R_Bn_0,
    input  wire [15:0] R2R_Bn_1,
    input  wire [15:0] R2R_Bn_2,
    input  wire [15:0] R2R_Bn_3,
    inout  wire [7:0]  ua
);

    wire _unused = VGND ^ VDPWR ^ VAPWR ^ (^R2R_Bn_0) ^ (^R2R_Bn_1) ^
                   (^R2R_Bn_2) ^ (^R2R_Bn_3) ^ (^ua);

endmodule

`default_nettype wire
