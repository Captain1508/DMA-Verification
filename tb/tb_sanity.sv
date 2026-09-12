module tb_sanity;
 import dma_pkg::*;
 //1. Signals
 logic clk , rst_n;
 logic [csr_addr_width-1:0] s_awaddr, s_araddr;
 logic s_awvalid, s_awready, s_wvalid, s_wready, s_arvalid, s_arready;
 logic [csr_data_width-1:0] s_wdata, s_rdata;
 logic [3:0] s_wstrb;
 logic [1:0] s_bresp, s_rresp;
 logic s_bvalid, s_bready, s_rvalid, s_rready;
 dma_fsm_e dbg_state;
 logic [63:0] m_araddr, m_awaddr, m_rdata, m_wdata;
  logic [7:0] m_arlen, m_awlen;
 logic [2:0] m_arsize, m_awsize;
 logic [1:0] m_arburst, m_awburst;
 logic m_arvalid, m_arready, m_rvalid, m_rready;
 logic m_awvalid,  m_awready, m_wvalid, m_wready, m_wlast;
 logic [7:0] m_wstrb;
 logic m_bvalid, m_bready;
 //count
 int pass_count = 0;
 int fail_count = 0;
//dut-instantiation 
 dma_top dut ( 
   .clk(clk), .rst_n(rst_n), .dbg_state_o(dbg_state), .s_axil_wready_o(s_wready),
    .s_axil_awaddr_i(s_awaddr), .s_axil_awvalid_i(s_awvalid), .s_axil_awready_o(s_awready),
    .s_axil_wdata_i(s_wdata), .s_axil_wstrb_i(s_wstrb), .s_axil_wvalid_i(s_wvalid),
    .s_axil_bresp_o(s_bresp), .s_axil_bvalid_o(s_bvalid), .s_axil_bready_i(s_bready),
    .s_axil_araddr_i(s_araddr), .s_axil_arvalid_i(s_arvalid), .s_axil_arready_o(s_arready),
    .s_axil_rdata_o(s_rdata), .s_axil_rresp_o(s_rresp), .s_axil_rvalid_o(s_rvalid), .s_axil_rready_i(s_rready),
    .m_axi_araddr_o(m_araddr), .m_axi_arlen_o(m_arlen), .m_axi_arsize_o(m_arsize), .m_axi_arburst_o(m_arburst),
    .m_axi_arvalid_o(m_arvalid), .m_axi_arready_i(m_arready),
    .m_axi_rdata_i(m_rdata), .m_axi_rvalid_i(m_rvalid), .m_axi_rready_o(m_rready),
    .m_axi_awaddr_o(m_awaddr), .m_axi_awvalid_o(m_awvalid), .m_axi_awlen_o(m_awlen),
    .m_axi_awsize_o(m_awsize), .m_axi_awburst_o(m_awburst), .m_axi_awready_i(m_awready),
    .m_axi_wdata_o(m_wdata), .m_axi_wstrb_o(m_wstrb), .m_axi_wvalid_o(m_wvalid), .m_axi_wlast_o(m_wlast), .m_axi_wready_i(m_wready),
    .m_axi_bvalid_i(m_bvalid), .m_axi_bready_o(m_bready)
 );
 fake_memory mem_model(
    .clk(clk), .rst_n(rst_n),
    .awaddr_i(m_awaddr), .awvalid_i(m_awvalid), .awready_o(m_awready),
    .wdata_i(m_wdata), .wvalid_i(m_wvalid), .wready_o(m_wready),
    .bvalid_o(m_bvalid), .bready_i(m_bready),
    .araddr_i(m_araddr), .arvalid_i(m_arvalid), .arready_o(m_arready),
    .rdata_o(m_rdata), .rvalid_o(m_rvalid), .rready_i(m_rready)
 );
 //clock+reset
 initial clk = 0;
 always #5 clk = ~clk;
 always @(posedge clk) begin
  $display("t=%0t fsm=%s | df_state=%s df_beat=%0d desc_valid=%b | m_state=%s is_df=%b araddr=%h arvalid=%b rvalid=%b",
             $time, dbg_state.name(),
             dut.u_desc_fetch.df_state.name(), dut.u_desc_fetch.beat_cnt_q, dut.u_desc_fetch.desc_valid_o,
             dut.u_axi_master.m_state.name(), dut.u_axi_master.is_df_q,
             dut.m_axi_araddr_o, dut.m_axi_arvalid_o, dut.m_axi_rvalid_i);
   $display("t=%0t | nxt_addr=%h desc_q=%h",
           $time, dut.u_fsm.nxt_desc_addr_i, dut.u_desc_fetch.desc_q);
end
 initial begin
    rst_n = 0;
    s_awvalid = 0;
    s_wvalid = 0;
    s_bready = 1;
    s_arvalid = 0;
    s_rready = 1;
    repeat (3) @(posedge clk);
    rst_n = 1;
 end
//AXI4 lite driver task - reusable drive+wait
  task automatic axil_write(input logic [csr_addr_width-1:0] addr, input logic [31:0] data);
        $display("Entering axil_write for addr %h", addr);
        @(negedge clk);
        s_awaddr = addr; 
        s_awvalid = 1;
        s_wdata  = data; 
        s_wvalid  = 1;
        do @(posedge clk); 
        while (!(s_awready && s_wready && s_awvalid && s_wvalid));
        $display("write handshake done");
        @(negedge clk);
        s_awvalid = 0; 
        s_wvalid = 0;
        do @(posedge clk); while (!s_bvalid);
        $display("BVALID RECEIVED");
    endtask

 task automatic axil_read(
    input logic [csr_addr_width-1:0] addr,
    output logic [31:0] data
);

    $display("Entering axil_read addr=%h", addr);

    // Drive before DUT sampling edge
    @(negedge clk);
    s_araddr  = addr;
    s_arvalid = 1'b1;

    // Wait for address handshake
    do @(posedge clk);
    while (!(s_arvalid && s_arready));

    $display("AR handshake done");

    // Remove VALID away from sampling edge
    @(negedge clk);
    s_arvalid = 1'b0;

    $display("Waiting for RVALID");

    // Wait for read data
    do @(posedge clk);
    while (!s_rvalid);

    data = s_rdata;

    $display("RVALID received data=%h", data);

endtask
 //Stimulus 
 localparam logic [63:0] DESC_BASE = 64'h0000_0000_0000_0040; //memory index 8
  localparam logic [63:0] SRC_ADDR = 64'h0000_0000_0000_0100; // memory index 32
 localparam logic [63:0] DST_ADDR = 64'h0000_0000_0000_0200; // memory index 64 
 localparam logic [63:0] TEST_DATA = 64'hDEAD_BEEF_CAFE_1234;
 logic [31:0] status_rd;

 initial begin 
    wait (rst_n == 1);
    @(posedge clk);
    // (a) preload: real data at the source, and the descriptor itself, direct array pokes
    mem_model.mem[SRC_ADDR[12:3]] = TEST_DATA;
    mem_model.mem[DESC_BASE[12:3] + 0] = 64'h0;                                   // beat0: nxt_desc_addr = null (chain ends)
    mem_model.mem[DESC_BASE[12:3] + 1] = SRC_ADDR;                                // beat1: src_addr
    mem_model.mem[DESC_BASE[12:3] + 2] = DST_ADDR;                                // beat2: dst_addr
    mem_model.mem[DESC_BASE[12:3] + 3] = {32'h0000_0001, 32'd8};
    $display("Preload done");
    //(b) drive: configure via axi4 lite 
    axil_write(reg_desc_ptr_l, DESC_BASE[31:0]);
    axil_write(reg_desc_ptr_h, DESC_BASE[63:32]);
    axil_write(reg_dma_control, 32'h0000_0001); // start bit
      $display("Drive done");
    //(c) wait for completion-poll DMA_STATUS busy bit, with a timeout safety net
    fork
        begin
            do begin 
                axil_read(reg_dma_status, status_rd);
              $display("STATUS READ: time=%0t status=%h busy_bit=%b", $time,
             status_rd,
             status_rd[stat_busy_bit]);
		end while(status_rd[stat_busy_bit] == 1'b1);
        end 
        begin 
          repeat (50) @(posedge clk);
            $display("[TIMEOUT] DMA never completed");
            $finish;
        end
    join_any
    disable fork;  
    $display("Status done");
    // (d) check — golden model is simple: dest should equal what we preloaded at source
    if(mem_model.mem[DST_ADDR[12:3]] === TEST_DATA) begin
        pass_count++;
        $display("[PASS] single_descriptor_transfer: dest=%h",mem_model.mem[DST_ADDR[12:3]]);
    end else begin
        fail_count++;
        $display("[FAIL] signle_descriptor_transfer: got %h, expected %h", mem_model.mem[DST_ADDR[12:3]],TEST_DATA);
    end
    $display("check done");
  
    $display("==============================================");
    $display("Total: Pass=%0d Fail=%0d", pass_count,fail_count);
    $display("==============================================");
    $finish;
end
endmodule
