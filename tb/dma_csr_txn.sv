import uvm_pkg::*;
`include "uvm_macros.svh"
import dma_pkg::*;
class dma_csr_txn extends uvm_sequence_item;
rand bit is_write;
rand bit [csr_addr_width-1:0] addr;
rand bit [csr_data_width-1:0] wdata;
bit [csr_data_width-1:0] rdata;
  `uvm_object_utils_begin(dma_csr_txn)
  `uvm_field_int(is_write,UVM_ALL_ON)
  `uvm_field_int(addr,UVM_ALL_ON) 
  `uvm_field_int(wdata,UVM_ALL_ON)
  `uvm_field_int(rdata,UVM_ALL_ON)
`uvm_object_utils_end
function new(string name = "dma_txn");
    super.new(name);
endfunction 
endclass 
