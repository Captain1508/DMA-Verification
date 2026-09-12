class write_desc_ptr_l_seq extends uvm_sequence #(dma_csr_txn) ;
    `uvm_object_utils(write_desc_ptr_l_seq)    
    logic [63:0] desc_addr; //set by test before start
    function new(string name = "write_desc_ptr_l_seq");
        super.new(name);
    endfunction //new()

task body();
    req = dma_csr_txn::type_id::create("req");
    start_item(txn);
    req.is_write = 1'b1;
    req.addr = reg_desc_ptr_l;
    req.wdata = desc_addr[31:0];
    finish_item(txn);
endtask
endclass //write_desc_ptr_l_seq extends uvm_sequence 

class write_desc_ptr_h_seq extends uvm_sequence #(dma_csr_txn);
    `uvm_object_utils(write_desc_ptr_h_seq)
    logic [63:0] desc_addr;
    function new(string name = "write_desc_ptr_h_seq");
        super.new(name);
    endfunction //new()

task body();
    req = dma_csr_txn::type_id::create("req");
    start_item(req);
    req.is_write = 1'b1;
    req.addr = reg_desc_ptr_h;
    req.wdata = desc_addr[63:32];
    finish_item(req);
endtask
endclass //write_desc_ptr_h extends uvm_sequence 

class write_control_seq extends uvm_sequence #(dma_csr_txn);
    `uvm_object_utils(write_control_seq) 
    function new(string name = "write_control_seq");
        super.new(name);
    endfunction //new()

task body();
    req = dma_csr_txn::type_id::create("req");
    start_item(req);
    req.is_write = 1'b1;
    req.addr = reg_dma_control;
    req.wdata = 32'h1 << ctrl_start_bit;
    finish_item(req);
endtask
endclass //write_control_seq extends uvm_sequence 

class read_status_seq extends uvm_sequence #(dma_csr_txn);
    `uvm_object_utils(read_status_seq)
    function new(string name = "read_status_seq");
        super.new(name);
    endfunction //new()

task body();
    req = dma_csr_txn::type_id::create("req");
    start_item(req);
    req.is_write = 1'b0;
    req.addr = reg_dma_status;
    finish_item(req);
endtask
endclass //read_status_seq extends uvm_sequence

//Composing sequence :instantiated 3 sequence and read_status_seq will get called from(test) 
class dma_basic_seq extends uvm_sequence #(dma_csr_txn);
    `uvm_object_utils(dma_basic_seq)
    logic [63:0] desc_addr;
    write_desc_ptr_l_seq desc_l_seq;
    write_desc_ptr_h_seq desc_h_seq;
    write_control_seq    control_seq;
    function new(string name = "dma_basic_seq");
        super.new(name);
    endfunction //new()

task body();
    desc_l_seq = write_desc_ptr_l_seq::type_id::create("desc_l_seq");
    desc_h_seq = write_desc_ptr_h_seq::type_id::create("desc_h_seq");
    control_seq = write_control_seq::type_id::create("control_seq");
    desc_l_seq.desc_addr = desc_addr;
    desc_h_seq.desc_addr = desc_addr;
    desc_l_seq.start(m_sequencer);
    desc_h_seq.start(m_sequencer);   // another approach we can use p_sequencer macro so we can direct access parent sequencer rather than 
    control_seq.start(m_sequencer);
endtask
endclass //dma_basic extends uvm_sequence
