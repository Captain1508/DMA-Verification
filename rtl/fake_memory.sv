module fake_memory (
    input logic clk,
    input logic rst_n,
    input logic [63:0] awaddr_i,
    input logic awvalid_i,
    output logic awready_o,
    input logic [63:0] wdata_i,
    input logic wvalid_i,
    output logic wready_o,
    output logic bvalid_o,
    input logic bready_i,
    input logic [63:0] araddr_i,
    input logic arvalid_i,
    output logic arready_o,
    output logic [63:0] rdata_o,
    output logic rvalid_o,
    input logic rready_i
);
logic [63:0] mem [0:1023];
assign awready_o = 1'b1;
assign wready_o = 1'b1;
assign arready_o = 1'b1;
logic [63:0] awaddr_q;

// latch the write address when it arrives
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) awaddr_q <= '0;
  else if (awvalid_i) awaddr_q <= awaddr_i;
end

// writes — trigger on data arrival, using the latched address
always_ff @(posedge clk) begin
  if (wvalid_i)
    mem[awaddr_q[12:3]] <= wdata_i;
end

// write response — one cycle after data arrives
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) bvalid_o <= 1'b0;
  else        bvalid_o <= wvalid_i;
end
//reads-one cycle latency 
always_ff @( posedge clk or negedge rst_n ) begin 
    if(!rst_n) begin 
        rvalid_o <= 1'b0;
        rdata_o <= '0;
    end else if(arvalid_i) begin
        rdata_o <= mem[araddr_i[12:3]];
        rvalid_o <= 1'b1;
    end else begin
        rvalid_o <= 1'b0;
    end 
end
endmodule
