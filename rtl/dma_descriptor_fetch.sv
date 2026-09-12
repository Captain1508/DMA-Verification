module dma_descriptor_fetch(
    input logic clk,
    input logic rst_n,
    input logic fetch_req_i,
    input logic [dma_pkg::csr_data_width-1:0]desc_ptr_l_i,
    input logic [dma_pkg::csr_data_width-1:0]desc_ptr_h_i,
    input logic [63:0]mem_rdata_i,
    input logic mem_rvalid_i,
    output logic [63:0]mem_addr_o,
    output logic mem_read_req_o,
    output logic desc_valid_o,
    output logic [63:0]src_addr_o,
    output logic [63:0]dst_addr_o,
    output logic [63:0]xfer_length_o,
    output logic [63:0]nxt_desc_addr_o
);
import dma_pkg::*;
typedef enum logic [1:0] { df_idle,df_req,df_wait } df_state_e;
df_state_e df_state,df_next;
logic [3:0] beat_cnt_q;
logic [255:0] desc_q;
logic [63:0] base_addr_q;
dma_pkg::dma_desc_t desc_view;

//state register 
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin 
        df_state <= df_idle;
    end
    else begin 
        df_state <= df_next;
    end 
end
// next-state logic 
always_comb begin 
    df_next = df_state; // silliest mistake of my life costed 4hrs minimum
    case(df_state)
    df_idle: if(fetch_req_i) df_next = df_req;
    df_req: df_next = df_wait;
    df_wait: if(mem_rvalid_i)
    df_next = (beat_cnt_q == 4'd3) ? df_idle : df_req;
    endcase
end
//beat-counter 
always_ff @( posedge clk or negedge rst_n ) begin 
    if(!rst_n) begin 
        beat_cnt_q <= 0;
        desc_q <= 0;
        base_addr_q <= 0;
    end
    else if (df_state == df_idle && fetch_req_i) begin
        base_addr_q <= {desc_ptr_h_i,desc_ptr_l_i};
        beat_cnt_q <= 0;
    end else if (df_state == df_wait && mem_rvalid_i) begin 
        desc_q[beat_cnt_q*64 +: 64] <= mem_rdata_i;
        beat_cnt_q <= beat_cnt_q + 1'b1;
    end
end
//output 
assign mem_addr_o = base_addr_q +(beat_cnt_q*8);
assign mem_read_req_o = (df_state == df_req);
assign desc_valid_o = (df_state == df_wait) && mem_rvalid_i && (beat_cnt_q == 4'd3);
//unpack 
assign desc_view = dma_pkg::dma_desc_t'(desc_q);
assign nxt_desc_addr_o = {desc_view.nxt_desc_addr_h,desc_view.nxt_desc_addr_l}; /// this _o costed lots of hours of debugging  
assign src_addr_o = {desc_view.src_addr_h,desc_view.src_addr_l};
assign dst_addr_o = {desc_view.dst_addr_h,desc_view.dst_addr_l};
assign xfer_length_o = {32'b0, desc_view.xfer_length}; 

endmodule
