module dma_axi_master (
    input logic clk ,
    input logic rst_n,
    
    input logic [63:0]df_addr_i,
    input logic df_read_req_i,
    output logic [63:0]df_rdata_o,
    
    output logic df_valid_o,
    input logic read_req_i,
    input logic write_req_i,
    input logic [63:0]src_addr_i,
    input logic [63:0]dst_addr_i,
    input logic [63:0]xfer_length_i,
    output logic read_done_o,
    output logic write_done_o,

    output logic [63:0]araddr_o,
    output logic [7:0]arlen_o,
    output logic [2:0]arsize_o,
    output logic [1:0]arburst_o,
    output logic arvalid_o,
    input logic arready_i,
    input logic [63:0]rdata_i,
    input logic rvalid_i,
    output logic rready_o,
 
    output logic [63:0]awaddr_o,
    output logic awvalid_o,
    output logic [7:0]awlen_o,
    output logic [2:0]awsize_o,
    output logic [1:0]awburst_o,
    input logic awready_i,
    output logic [63:0]wdata_o,
    output logic [7:0]wstrb_o,
    output logic wvalid_o,
    output logic wlast_o,
    input logic wready_i,
    input logic bvalid_i,
    output logic bready_o
 );
import dma_pkg::*;
typedef enum logic [2:0] { m_idle,m_ar,m_rwait,m_aw,m_wwait,m_bwait } m_state_e;
m_state_e m_state,m_next;
logic [63:0] cur_addr_q;
logic [5:0] beat_cnt_q,total_beats_q;
logic is_df_q;
logic [63:0] xfer_buf [0:dma_pkg::max_xfer_beats-1];
assign arlen_o = 8'h00; 
assign arsize_o = 3'b011; 
assign arburst_o = 2'b01;
assign awlen_o = 8'h00; 
assign awsize_o = 3'b011; 
assign awburst_o = 2'b01;
assign wstrb_o = 8'hFF; 
assign wlast_o = 1'b1;

always_ff @( posedge clk or negedge rst_n ) begin
    if(!rst_n) m_state <= m_idle;
    else m_state <= m_next;
    end
always_comb begin
    m_next = m_state;
    case(m_state)
    m_idle: begin
        if(df_read_req_i) m_next = m_ar;
        else if(read_req_i) m_next = m_ar;
        else if(write_req_i) m_next = m_aw;
        end
    m_ar: if(arready_i) m_next = m_rwait;
    m_rwait: if(rvalid_i) m_next = (beat_cnt_q==total_beats_q)? m_idle:m_ar;
    m_aw: if(awready_i) m_next = m_wwait;
    m_wwait: if(wready_i) m_next = m_bwait;
    m_bwait: if(bvalid_i) m_next = (beat_cnt_q==total_beats_q)? m_idle:m_aw;
    endcase
end
always_ff @( posedge clk or negedge rst_n ) begin
    if(!rst_n) begin
        cur_addr_q <= '0;
        beat_cnt_q <= '0;
        total_beats_q <= '0;
        is_df_q <= 1'b0;
    end else if (m_state == m_idle) begin
    if (df_read_req_i) begin
      cur_addr_q <= df_addr_i; total_beats_q <= 6'd0; beat_cnt_q <= '0; is_df_q <= 1'b1;
    end else if (read_req_i) begin
      cur_addr_q <= src_addr_i; total_beats_q <= xfer_length_i[8:3] - 1'b1; beat_cnt_q <= '0; is_df_q <= 1'b0;
    end else if (write_req_i) begin
      cur_addr_q <= dst_addr_i; total_beats_q <= xfer_length_i[8:3] - 1'b1; beat_cnt_q <= '0; is_df_q <= 1'b0;
    end 
    end else if((m_state == m_rwait && rvalid_i) || (m_state == m_bwait && bvalid_i)) begin
        if(beat_cnt_q != total_beats_q) begin
            cur_addr_q <= cur_addr_q + 64'd8;
            beat_cnt_q <= beat_cnt_q + 1'b1;
        end 
    end 
end 
always_ff @( posedge clk ) begin 
    if(m_state == m_rwait && rvalid_i && !is_df_q) begin
        xfer_buf[beat_cnt_q] <= rdata_i;
    end
end
assign araddr_o  = cur_addr_q;
assign arvalid_o = (m_state == m_ar);
assign rready_o  = (m_state == m_rwait);
assign df_rdata_o  = rdata_i;
assign df_valid_o  = (m_state == m_rwait) && rvalid_i && is_df_q;
assign read_done_o = (m_state == m_rwait) && rvalid_i && !is_df_q && (beat_cnt_q == total_beats_q);
assign awaddr_o = cur_addr_q; 
assign awvalid_o = (m_state == m_aw);
assign wdata_o = xfer_buf[beat_cnt_q];
assign wvalid_o = (m_state == m_wwait);
assign bready_o = (m_state == m_bwait);
assign write_done_o = (m_state == m_bwait) && bvalid_i && (beat_cnt_q == total_beats_q);
endmodule
