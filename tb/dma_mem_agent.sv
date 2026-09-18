class dma_mem_agent extends uvm_agent;
  `uvm_component_utils(dma_mem_agent)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  dma_mem_monitor mon;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = dma_mem_monitor::type_id::create("mon", this);
  endfunction
endclass
