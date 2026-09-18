import uvm_pkg::*;
`include "uvm_macros.svh"
import dma_pkg::*;
class dma_mem_txn extends uvm_sequence_item;

rand logic is_write;
rand logic [63:0] addr;
rand logic [7:0] len;
rand logic [2:0] size;
rand logic [1:0] burst;
rand logic [63:0] data;
rand logic [7:0] strb;
rand logic last;
logic [1:0] resp;

`uvm_object_utils_begin(dma_mem_txn)
    `uvm_field_int(is_write,UVM_ALL_ON)
    `uvm_field_int(addr,UVM_ALL_ON)
    `uvm_field_int(len,UVM_ALL_ON)
    `uvm_field_int(size,UVM_ALL_ON)
    `uvm_field_int(burst,UVM_ALL_ON)
    `uvm_field_int(data,UVM_ALL_ON)
    `uvm_field_int(strb,UVM_ALL_ON)
    `uvm_field_int(last,UVM_ALL_ON)
    `uvm_field_int(resp,UVM_ALL_ON)
`uvm_object_utils_end
function new(string name = "dma_mem_txn");
    super.new(name);
endfunction
endclass
