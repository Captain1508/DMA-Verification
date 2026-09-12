module dma_top (
    input logic clk,
    input logic rst_n,
    output dma_pkg::dma_fsm_e dbg_state_o,
    // AXI4-Lite slave port — CPU-facing, drives dma_regs
    input  logic [dma_pkg::csr_addr_width-1:0] s_axil_awaddr_i,
    input  logic                                s_axil_awvalid_i,
    output logic                                s_axil_awready_o,
    input  logic [dma_pkg::csr_data_width-1:0] s_axil_wdata_i,
    input  logic [(dma_pkg::csr_data_width/8)-1:0] s_axil_wstrb_i,
    input  logic                                s_axil_wvalid_i,
    output logic                                s_axil_wready_o,
    output logic [1:0]                          s_axil_bresp_o,
    output logic                                s_axil_bvalid_o,
    input  logic                                s_axil_bready_i,
    input  logic [dma_pkg::csr_addr_width-1:0] s_axil_araddr_i,
    input  logic                                s_axil_arvalid_i,
    output logic                                s_axil_arready_o,
    output logic [dma_pkg::csr_data_width-1:0] s_axil_rdata_o,
    output logic [1:0]                          s_axil_rresp_o,
    output logic                                s_axil_rvalid_o,
    input  logic                                s_axil_rready_i,

    // AXI4 master port — memory-facing, driven by dma_axi_master
    output logic [63:0] m_axi_araddr_o,
    output logic [7:0]  m_axi_arlen_o,
    output logic [2:0]  m_axi_arsize_o,
    output logic [1:0]  m_axi_arburst_o,
    output logic        m_axi_arvalid_o,
    input  logic        m_axi_arready_i,
    input  logic [63:0] m_axi_rdata_i,
    input  logic         m_axi_rvalid_i,
    output logic        m_axi_rready_o,

    output logic [63:0] m_axi_awaddr_o,
    output logic         m_axi_awvalid_o,
    output logic [7:0]  m_axi_awlen_o,
    output logic [2:0]  m_axi_awsize_o,
    output logic [1:0]  m_axi_awburst_o,
    input  logic        m_axi_awready_i,
    output logic [63:0] m_axi_wdata_o,
    output logic [7:0]  m_axi_wstrb_o,
    output logic         m_axi_wvalid_o,
    output logic        m_axi_wlast_o,
    input  logic        m_axi_wready_i,
    input  logic        m_axi_bvalid_i,
    output logic        m_axi_bready_o 
);
import dma_pkg::*;
// internal wires — regs <-> fsm
logic start, soft_reset, busy, error;

// internal wires — fsm <-> descriptor_fetch
logic fetch_req, desc_valid;
logic [63:0] nxt_desc_addr;

// internal wires — regs <-> descriptor_fetch
logic [csr_data_width-1:0] desc_ptr_l, desc_ptr_h;

// internal wires — descriptor_fetch <-> axi_master (its outputs feeding the AXI master's data-move inputs)
logic [63:0] src_addr, dst_addr, xfer_length;

// internal wires — fsm <-> axi_master
logic read_req, write_req, read_done, write_done;

// internal wires — descriptor_fetch <-> axi_master (single-beat descriptor read path)
// note: descriptor_fetch's ports use "mem_*" naming, axi_master's use "df_*" — different
// base names on each side, same mismatch situation as nxt_desc_addr earlier. Picking "df_*"
// as the canonical wire name here since it matches the axi_master side.
logic [63:0] df_addr;
logic        df_read_req;
logic [63:0] df_rdata;
logic        df_valid;

dma_regs u_regs (
    .clk(clk), .rst_n(rst_n),
    .awaddr_i(s_axil_awaddr_i), .awvalid_i(s_axil_awvalid_i), .awready_o(s_axil_awready_o),
    .wdata_i(s_axil_wdata_i), .wstrb_i(s_axil_wstrb_i), .wvalid_i(s_axil_wvalid_i), .wready_o(s_axil_wready_o),
    .bresp_o(s_axil_bresp_o), .bvalid_o(s_axil_bvalid_o), .bready_i(s_axil_bready_i),
    .araddr_i(s_axil_araddr_i), .arvalid_i(s_axil_arvalid_i), .arready_o(s_axil_arready_o),
    .rdata_o(s_axil_rdata_o), .rresp_o(s_axil_rresp_o), .rvalid_o(s_axil_rvalid_o), .rready_i(s_axil_rready_i),
    .busy_i(busy), .error_i(error), 
    .desc_ptr_l_o(desc_ptr_l), .desc_ptr_h_o(desc_ptr_h),
    .start_o(start), .soft_reset_o(soft_reset)
);

dma_fsm u_fsm (
    .clk(clk), .rst_n(rst_n),
    .start_i(start), .soft_reset_i(soft_reset),
    .error_i(1'b0), .busy_o(busy),
    .desc_valid_i(desc_valid), .nxt_desc_addr_i(nxt_desc_addr),
    .fetch_req_o(fetch_req),
    .read_req_o(read_req), .write_req_o(write_req),
    .read_done_i(read_done), .write_done_i(write_done),
    .state(dbg_state_o),
    .error_o(error)
);

dma_descriptor_fetch u_desc_fetch (
    .clk(clk), .rst_n(rst_n),
    .fetch_req_i(fetch_req),
    .desc_ptr_l_i(desc_ptr_l), .desc_ptr_h_i(desc_ptr_h),
    .mem_addr_o(df_addr), .mem_read_req_o(df_read_req),
    .mem_rdata_i(df_rdata), .mem_rvalid_i(df_valid),
    .desc_valid_o(desc_valid),
    .src_addr_o(src_addr), .dst_addr_o(dst_addr),
    .xfer_length_o(xfer_length), .nxt_desc_addr_o(nxt_desc_addr)
);

dma_axi_master u_axi_master (
    .clk(clk), .rst_n(rst_n),
    .df_addr_i(df_addr), .df_read_req_i(df_read_req),
    .df_rdata_o(df_rdata), .df_valid_o(df_valid),
    .read_req_i(read_req), .write_req_i(write_req),
    .src_addr_i(src_addr), .dst_addr_i(dst_addr), .xfer_length_i(xfer_length),
    .read_done_o(read_done), .write_done_o(write_done),
    .araddr_o(m_axi_araddr_o), .arlen_o(m_axi_arlen_o), .arsize_o(m_axi_arsize_o),
    .arburst_o(m_axi_arburst_o), .arvalid_o(m_axi_arvalid_o), .arready_i(m_axi_arready_i),
    .rdata_i(m_axi_rdata_i), .rvalid_i(m_axi_rvalid_i), .rready_o(m_axi_rready_o),
    .awaddr_o(m_axi_awaddr_o), .awvalid_o(m_axi_awvalid_o), .awlen_o(m_axi_awlen_o),
    .awsize_o(m_axi_awsize_o), .awburst_o(m_axi_awburst_o), .awready_i(m_axi_awready_i),
    .wdata_o(m_axi_wdata_o), .wstrb_o(m_axi_wstrb_o), .wvalid_o(m_axi_wvalid_o),
    .wlast_o(m_axi_wlast_o), .wready_i(m_axi_wready_i),
    .bvalid_i(m_axi_bvalid_i), .bready_o(m_axi_bready_o)
);
endmodule
