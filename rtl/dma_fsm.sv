module dma_fsm 
(
    input logic clk,
    input logic rst_n,
    input logic start_i,
    input logic error_i,
    input logic desc_valid_i,
    input logic read_done_i,
    input logic write_done_i,
    input logic [63:0] nxt_desc_addr_i,
    input logic soft_reset_i,
    output dma_pkg::dma_fsm_e state,
    output logic fetch_req_o,
    output logic read_req_o,
    output logic write_req_o,
    output logic busy_o,
    output logic error_o
);
import dma_pkg::* ;
dma_pkg::dma_fsm_e next_state;
//state register
always_ff @( posedge clk or negedge rst_n ) begin
    if(!rst_n)
    state <= dma_idle;
    else 
        state <= next_state;
    end
//next_state logic 
always_comb begin 
    next_state = state;
    case(state)
    dma_idle: begin
        if(start_i) next_state = dma_fetch_desc; 
    end 
    dma_fetch_desc: begin 
        if(error_i) next_state = dma_error_halt;
        else if (desc_valid_i) next_state = dma_read;
    end 
    dma_read: begin
        if(error_i) next_state = dma_error_halt;
        else if(read_done_i) next_state = dma_write;    
    end
    dma_write: begin 
        if(error_i) next_state = dma_error_halt;
        else if(write_done_i) next_state = dma_check_next;
    end
    dma_check_next: begin 
        if(nxt_desc_addr_i == dma_pkg::dma_null_ptr) 
        next_state = dma_idle;
        else 
            next_state = dma_fetch_desc;
    end
    dma_error_halt: begin 
        if(soft_reset_i) next_state = dma_idle;
    end 
    endcase
end
//output logic block
always_comb begin
  fetch_req_o = (state == dma_fetch_desc);
  read_req_o  = (state == dma_read);
  write_req_o = (state == dma_write);
  busy_o      = (state != dma_idle);
  error_o     = (state == dma_error_halt);
end
endmodule 
