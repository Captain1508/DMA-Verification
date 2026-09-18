interface axim_if(input bit clk , input bit rst_n);
import dma_pkg::*;

logic [63:0] m_axi_araddr_o;
logic [7:0] m_axi_arlen_o;
logic [2:0] m_axi_arsize_o;
logic [1:0] m_axi_arburst_o;
logic m_axi_arvalid_o;
logic m_axi_arready_i;
logic [63:0] m_axi_rdata_i;
logic m_axi_rvalid_i;
logic m_axi_rready_o;
logic [63:0] m_axi_awaddr_o;
logic [7:0] m_axi_awlen_o;
logic [2:0] m_axi_awsize_o;
logic [1:0] m_axi_awburst_o;
logic m_axi_awvalid_o;
logic m_axi_awready_i;
logic [63:0] m_axi_wdata_o;
logic [7:0] m_axi_wstrb_o;
logic m_axi_wlast_o;
logic m_axi_wvalid_o;
logic m_axi_wready_i;
logic m_axi_bready_o;
logic m_axi_bvalid_i;


clocking mon_cb @(posedge clk);
    input m_axi_araddr_o,m_axi_arlen_o,m_axi_arsize_o,m_axi_arburst_o,m_axi_arvalid_o,m_axi_arready_i,m_axi_rdata_i,
    m_axi_rvalid_i,m_axi_rready_o,m_axi_awaddr_o,m_axi_awlen_o,m_axi_awsize_o,m_axi_awburst_o,m_axi_awvalid_o, 
    m_axi_awready_i,m_axi_wdata_o,m_axi_wstrb_o,m_axi_wlast_o,m_axi_wvalid_o,m_axi_wready_i,m_axi_bready_o,m_axi_bvalid_i;
endclocking
endinterface
