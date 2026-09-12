module dma_regs (
    input logic clk,
    input logic rst_n,
    input logic [dma_pkg::csr_addr_width-1:0] awaddr_i,
    input logic awvalid_i,
    input logic [dma_pkg::csr_data_width-1:0] wdata_i,
    input logic [(dma_pkg::csr_data_width/8)-1:0] wstrb_i,
    input logic wvalid_i,
    input logic bready_i,
    input logic [dma_pkg::csr_addr_width-1:0]araddr_i,
    input logic arvalid_i,
    input logic rready_i,
    input logic busy_i,
    input logic error_i,
    output logic awready_o,
    output logic wready_o,
    output logic [1:0]bresp_o,
    output logic bvalid_o,
    output logic arready_o,
    output  logic [dma_pkg::csr_data_width-1:0] rdata_o,
    output logic [1:0]rresp_o,
    output logic rvalid_o,
    output logic start_o,
    output logic soft_reset_o,
    output logic [dma_pkg::csr_data_width-1:0] desc_ptr_l_o,
    output logic [dma_pkg::csr_data_width-1:0] desc_ptr_h_o
);
import dma_pkg::*;
//stored register
logic [csr_data_width-1:0] desc_ptr_l_q, desc_ptr_h_q;
// write handshake- accept AW+W
logic write_fire;
assign awready_o = !bvalid_o;
assign desc_ptr_l_o = desc_ptr_l_q;
assign desc_ptr_h_o = desc_ptr_h_q;
assign wready_o = !bvalid_o;
assign write_fire = awready_o && wready_o && awvalid_i && wvalid_i;
//write response channel 
always_ff @( posedge clk or negedge rst_n ) begin 
    if(!rst_n) begin
        bvalid_o <= 1'b0;
        bresp_o <= 2'b0;
    end else if(write_fire) begin
        bvalid_o <= 1'b1;
        bresp_o <= 2'b0;
    end else if(bvalid_o && bready_i) begin
        bvalid_o <= 1'b0;
    end
    end
//register write + start/reset pulses
always_ff @( posedge clk or negedge rst_n ) begin 
    if(!rst_n) begin
        desc_ptr_l_q <= 1'b0;
        desc_ptr_h_q <= 1'b0;
        start_o <= 1'b0;
        soft_reset_o <= 1'b0;
    end else begin
        start_o <= 1'b0;
        soft_reset_o <= 1'b0;
    if(write_fire) begin
        case(awaddr_i) 
            reg_dma_control: begin
                start_o <= wdata_i[ctrl_start_bit];
                soft_reset_o <= wdata_i[ctrl_reset_bit];
            end
            reg_desc_ptr_l: desc_ptr_l_q <= wdata_i;
            reg_desc_ptr_h:desc_ptr_h_q <= wdata_i;
            default: ;
        endcase
    end
end
end 
//read handshake 
assign arready_o = !rvalid_o;
logic read_fire;
assign read_fire = (arready_o && arvalid_i);
always_ff @( posedge clk or negedge rst_n ) begin 
    if(!rst_n) begin 
        rvalid_o <= 1'b0;
        rresp_o <= 2'b0;
    end else if(read_fire) begin
        rvalid_o <= 1'b1;
        rdata_o <= '0;
        rresp_o <= 2'b0;
        case(araddr_i)
        reg_dma_status: begin
            rdata_o <= '0;
            rdata_o[stat_busy_bit] <= busy_i;
            rdata_o[stat_err_bit] <= error_i;
        end
        reg_desc_ptr_l: rdata_o <= desc_ptr_l_q;
        reg_desc_ptr_h: rdata_o <= desc_ptr_h_q;
        default: rdata_o <= '0; 
        endcase
    end else if(rvalid_o && rready_i) begin
        rvalid_o <= 1'b0;
    end 
end 
endmodule
