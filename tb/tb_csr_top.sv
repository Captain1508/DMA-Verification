module tb_csr_top;
import uvm_pkg::*;
`include "uvm_macros.svh"
logic clk;
logic rst_n;

initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

initial begin
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
    end

initial begin
  #2000;
  $display("[TIMEOUT] simulation did not finish in time");
  $finish;
end

always @(posedge clk) begin
  $display("t=%0t awvalid=%b wvalid=%b awready=%b wready=%b bvalid=%b arvalid=%b arready=%b rvalid=%b",
             $time, axil_if_inst.awvalid, axil_if_inst.wvalid, axil_if_inst.awready, axil_if_inst.wready,
             axil_if_inst.bvalid, axil_if_inst.arvalid, axil_if_inst.arready, axil_if_inst.rvalid);
end
// --- end new blocks ---

axil_if axil_if_inst(
    .clk(clk),
    .rst_n(rst_n)
    );
logic [63:0] m_araddr, m_awaddr, m_rdata, m_wdata;
logic [7:0]  m_arlen, m_awlen, m_wstrb;
logic [2:0]  m_arsize, m_awsize;
logic [1:0]  m_arburst, m_awburst;
logic m_arvalid, m_arready, m_rvalid, m_rready;
logic m_awvalid, m_awready, m_wvalid, m_wready, m_wlast;
logic m_bvalid, m_bready;

dma_top dut(
    .clk(clk), .rst_n(rst_n),
    .s_axil_awaddr_i  (axil_if_inst.awaddr),
    .s_axil_awvalid_i (axil_if_inst.awvalid),
    .s_axil_awready_o (axil_if_inst.awready),
    .s_axil_wdata_i   (axil_if_inst.wdata),
    .s_axil_wstrb_i   (axil_if_inst.wstrb),
    .s_axil_wvalid_i  (axil_if_inst.wvalid),
    .s_axil_wready_o  (axil_if_inst.wready),
    .s_axil_bresp_o   (axil_if_inst.bresp),
    .s_axil_bvalid_o  (axil_if_inst.bvalid),
    .s_axil_bready_i  (axil_if_inst.bready),
    .s_axil_araddr_i  (axil_if_inst.araddr),
    .s_axil_arvalid_i (axil_if_inst.arvalid),
    .s_axil_arready_o (axil_if_inst.arready),
    .s_axil_rdata_o   (axil_if_inst.rdata),
    .s_axil_rresp_o   (axil_if_inst.rresp),
    .s_axil_rvalid_o  (axil_if_inst.rvalid),
    .s_axil_rready_i  (axil_if_inst.rready),
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

localparam logic [63:0] DESC_BASE = 64'h0000_0000_0000_0040;
localparam logic [63:0] SRC_ADDR  = 64'h0000_0000_0000_0100;
localparam logic [63:0] DST_ADDR  = 64'h0000_0000_0000_0200;
localparam logic [63:0] TEST_DATA = 64'hDEAD_BEEF_CAFE_1234;

initial begin
    @(posedge rst_n);   // wait for reset to actually finish first
    mem_model.mem[SRC_ADDR[12:3]]      = TEST_DATA;
    mem_model.mem[DESC_BASE[12:3] + 0] = 64'h0;              // nxt_desc_addr = null
    mem_model.mem[DESC_BASE[12:3] + 1] = SRC_ADDR;
    mem_model.mem[DESC_BASE[12:3] + 2] = DST_ADDR;
    mem_model.mem[DESC_BASE[12:3] + 3] = {32'h0000_0001, 32'd8};
end

initial begin
    uvm_config_db #(virtual axil_if)::set(null,"uvm_test_top.m_top_env.m_agent.*","vif",axil_if_inst);
    run_test("dma_csr_test");
end
endmodule
