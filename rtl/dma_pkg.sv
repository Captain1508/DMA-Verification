//package is about data definations, container for sharing constants!
package dma_pkg;
//Constants
localparam bit [63:0] dma_null_ptr = 64'h0000_0000_0000_0000;
localparam int max_xfer_beats = 32;
localparam int unsigned desc_size_bytes = 32;
localparam int csr_addr_width = 6;
localparam int csr_data_width = 32;
//Register file
typedef enum logic [5:0] { 
    reg_dma_control = 6'h00,
    reg_dma_status = 6'h04,
    reg_desc_ptr_l = 6'h08,
    reg_desc_ptr_h = 6'h0C
 } csr_offset_e;
 //FSM states
 typedef enum logic [2:0] { 
    dma_idle = 3'b000,
    dma_fetch_desc = 3'b001,
    dma_read = 3'b010,
    dma_write = 3'b011,
    dma_check_next = 3'b100,
    dma_error_halt = 3'b101
  } dma_fsm_e;
//Scatter-gather descriptor structure(32-byte)
  typedef struct packed {
    logic [31:0] ctrl_stat;
    logic [31:0] xfer_length;
    logic [31:0] dst_addr_h;
    logic [31:0] dst_addr_l;
    logic [31:0] src_addr_h;
    logic [31:0] src_addr_l;
    logic [31:0] nxt_desc_addr_h;
    logic [31:0] nxt_desc_addr_l; 
  } dma_desc_t;
// ctrl_stat bit positions
localparam int ctrl_start_bit = 0; // dma control bits
localparam int ctrl_reset_bit = 1;
// descriptor ctrl_stat bit positions (per-descriptor, in memory)
localparam int desc_valid_bit = 0;
localparam int desc_done_bit  = 16;
localparam int desc_error_bit = 17;

// DMA_STATUS register bit positions (register bank, CPU-visible)
localparam int stat_busy_bit  = 0;
localparam int stat_err_bit   = 1;
endpackage : dma_pkg
