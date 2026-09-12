class dma_csr_agent extends uvm_agent;
`uvm_component_utils(dma_csr_agent)
function new (string name, uvm_component parent);
    super.new(name,parent);
endfunction
dma_csr_driver drv;
dma_csr_monitor mon;
uvm_sequencer #(dma_csr_txn) sqr;

virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(get_is_active() == UVM_ACTIVE) begin 
        drv = dma_csr_driver::type_id::create("drv",this);
        sqr = uvm_sequencer #(dma_csr_txn)::type_id::create("sqr", this);
    end 
    mon = dma_csr_monitor::type_id::create("mon",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE)
        drv.seq_item_port.connect(sqr.seq_item_export);
endfunction
endclass
