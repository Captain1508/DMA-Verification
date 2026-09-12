interface axil_if (input bit clk, input bit rst_n);
  import dma_pkg::*;

  logic [csr_addr_width-1:0] awaddr;
  logic awvalid;
  logic awready;
  logic [csr_data_width-1:0] wdata;
  logic [(csr_data_width/8)-1:0] wstrb;
  logic wvalid;
  logic wready;
  logic [1:0] bresp;
  logic bvalid;
  logic bready;
  logic [csr_addr_width-1:0] araddr;
  logic arvalid;
  logic arready;
  logic [csr_data_width-1:0] rdata;
  logic [1:0] rresp;
  logic rvalid;
  logic rready;

  clocking drv_cb @(posedge clk);
    output awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr, arvalid, rready;
    input  awready, arready, wready, bresp, bvalid, rdata, rresp, rvalid;
  endclocking

  clocking mon_cb @(posedge clk);
    input awaddr, awvalid, awready, wdata, wvalid, wready, bvalid, bready,
          araddr, arvalid, arready, rdata, rvalid, rready;
  endclocking
endinterface
