// bsg_cgol_cell_tb.v
//
// This file contains the toplevel testbench for testing
// this design. 
//

module bsg_cgol_cell_tb;

  /* Dump Test Waveform To VPD File */
  initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars();
  end

  /* Non-synth clock generator */
  logic clk;
  bsg_nonsynth_clock_gen #(10000) clk_gen_1 (clk);

  /* Non-synth reset generator */
  logic reset;
  bsg_nonsynth_reset_gen #(.num_clocks_p(1),.reset_cycles_lo_p(5),. reset_cycles_hi_p(5))
    reset_gen
      (.clk_i        ( clk )
      ,.async_reset_o( reset )
      );

  logic dut_v_r;
  logic [9:0] dut_data_r;

  logic tr_v_lo;
  logic [9:0] tr_data_lo;
  logic tr_ready_lo;

  logic [31:0] rom_addr_li;
  logic [13:0] rom_data_lo;

  logic tr_yumi_li;

  logic [7:0] data_li;
  logic en_li, update_li, update_val_li;
  logic data_lo;


  bsg_fsb_node_trace_replay #(.ring_width_p(10)
                             ,.rom_addr_width_p(32) )
    trace_replay
      ( .clk_i ( ~clk )
      , .reset_i( reset )
      , .en_i( 1'b1 )

      , .v_i    ( dut_v_r )
      , .data_i ( dut_data_r )
      , .ready_o( tr_ready_lo )

      , .v_o   ( tr_v_lo )
      , .data_o( tr_data_lo )
      , .yumi_i( tr_yumi_li )

      , .rom_addr_o( rom_addr_li )
      , .rom_data_i( rom_data_lo )

      , .done_o()
      , .error_o()
      );

  assign tr_yumi_li = tr_v_lo;

  logic tr_yumi_li_r;
  always_ff @(negedge clk) begin
    tr_yumi_li_r <= tr_yumi_li;
    if (tr_v_lo) begin
      en_li <= tr_data_lo[9];
      update_li <= ~tr_data_lo[9];
      update_val_li <= tr_data_lo[8];
      data_li <= tr_data_lo[7:0];
    end
    else begin
      en_li <= 0;
      update_li <= 0;
    end
  end

  trace_rom #(.width_p(14),.addr_width_p(32))
    ROM
      (.addr_i( rom_addr_li )
      ,.data_o( rom_data_lo )
      );

  bsg_cgol_cell DUT
    (.clk_i        (           clk )

    ,.data_i       (       data_li )
    ,.en_i         (         en_li )
    ,.update_i     (     update_li )
    ,.update_val_i ( update_val_li )

    ,.data_o       (       data_lo )
    );

  always_ff @(negedge clk) begin
    if (reset) begin
      dut_v_r <= 0;
    end
    else if (tr_yumi_li_r) begin
      dut_data_r <= {9'b0, data_lo};
      dut_v_r <= 1;
    end
    else if (tr_ready_lo & dut_v_r) begin
      dut_v_r <= 0;
    end
  end

endmodule
