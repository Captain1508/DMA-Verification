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

axil_if axil_if_inst(
    .clk(clk),
    .rst_n(rst_n)
    );

axim_if axim_if_inst(
    .clk(clk),
    .rst_n(rst_n)
    );

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
    .dbg_state_o(),
    .m_axi_araddr_o (axim_if_inst.m_axi_araddr_o),
    .m_axi_arlen_o  (axim_if_inst.m_axi_arlen_o),
    .m_axi_arsize_o (axim_if_inst.m_axi_arsize_o),
    .m_axi_arburst_o(axim_if_inst.m_axi_arburst_o),
    .m_axi_arvalid_o(axim_if_inst.m_axi_arvalid_o),
    .m_axi_arready_i(axim_if_inst.m_axi_arready_i),
    .m_axi_rdata_i  (axim_if_inst.m_axi_rdata_i),
    .m_axi_rvalid_i (axim_if_inst.m_axi_rvalid_i),
    .m_axi_rready_o (axim_if_inst.m_axi_rready_o),
    .m_axi_awaddr_o (axim_if_inst.m_axi_awaddr_o),
    .m_axi_awvalid_o(axim_if_inst.m_axi_awvalid_o),
    .m_axi_awlen_o  (axim_if_inst.m_axi_awlen_o),
    .m_axi_awsize_o (axim_if_inst.m_axi_awsize_o),
    .m_axi_awburst_o(axim_if_inst.m_axi_awburst_o),
    .m_axi_awready_i(axim_if_inst.m_axi_awready_i),
    .m_axi_wdata_o  (axim_if_inst.m_axi_wdata_o),
    .m_axi_wstrb_o  (axim_if_inst.m_axi_wstrb_o),
    .m_axi_wvalid_o (axim_if_inst.m_axi_wvalid_o),
    .m_axi_wlast_o  (axim_if_inst.m_axi_wlast_o),
    .m_axi_wready_i (axim_if_inst.m_axi_wready_i),
    .m_axi_bvalid_i (axim_if_inst.m_axi_bvalid_i),
    .m_axi_bready_o (axim_if_inst.m_axi_bready_o)
);

fake_memory mem_model(
    .clk(clk), .rst_n(rst_n),
    .awaddr_i (axim_if_inst.m_axi_awaddr_o),
    .awvalid_i(axim_if_inst.m_axi_awvalid_o),
    .awready_o(axim_if_inst.m_axi_awready_i),
    .wdata_i  (axim_if_inst.m_axi_wdata_o),
    .wvalid_i (axim_if_inst.m_axi_wvalid_o),
    .wready_o (axim_if_inst.m_axi_wready_i),
    .bvalid_o (axim_if_inst.m_axi_bvalid_i),
    .bready_i (axim_if_inst.m_axi_bready_o),
    .araddr_i (axim_if_inst.m_axi_araddr_o),
    .arvalid_i(axim_if_inst.m_axi_arvalid_o),
    .arready_o(axim_if_inst.m_axi_arready_i),
    .rdata_o  (axim_if_inst.m_axi_rdata_i),
    .rvalid_o (axim_if_inst.m_axi_rvalid_i),
    .rready_i (axim_if_inst.m_axi_rready_o)
);

localparam logic [63:0] DESC_BASE = 64'h0000_0000_0000_0040;
localparam logic [63:0] SRC_ADDR  = 64'h0000_0000_0000_0100;
localparam logic [63:0] DST_ADDR  = 64'h0000_0000_0000_0200;
localparam logic [63:0] TEST_DATA = 64'hDEAD_BEEF_CAFE_1234;

initial begin
    @(posedge rst_n);
    mem_model.mem[SRC_ADDR[12:3]]      = TEST_DATA;
    mem_model.mem[DESC_BASE[12:3] + 0] = 64'h0;
    mem_model.mem[DESC_BASE[12:3] + 1] = SRC_ADDR;
    mem_model.mem[DESC_BASE[12:3] + 2] = DST_ADDR;
    mem_model.mem[DESC_BASE[12:3] + 3] = {32'h0000_0001, 32'd8};
end

initial begin
    uvm_config_db #(virtual axil_if)::set(null, "*", "vif", axil_if_inst);
    uvm_config_db #(virtual axim_if)::set(null, "*", "vif", axim_if_inst);
    run_test("dma_csr_test");
end
endmodule
