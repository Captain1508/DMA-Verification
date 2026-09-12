class dma_csr_test extends uvm_test;
    `uvm_component_utils(dma_csr_test)
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction //new()
    
    dma_csr_env m_top_env;
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_top_env = dma_csr_env::type_id::create("m_top_env",this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        dma_basic_seq seq;
        localparam logic [63:0] DESC_BASE = 64'h0000_0000_0000_0040 ;
        seq = dma_basic_seq::type_id::create("seq");
        seq.desc_addr = DESC_BASE;
        phase.raise_objection(this);
        seq.start(m_top_env.m_agent.sqr);
        phase.drop_objection(this);
    endtask
endclass //dma_csr_test extends uvm_test 
