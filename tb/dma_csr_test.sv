class dma_csr_test extends uvm_test;
    `uvm_component_utils(dma_csr_test)
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

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
        read_status_seq status_seq;
        localparam logic [63:0] DESC_BASE = 64'h0000_0000_0000_0040;

        `uvm_info("TEST", "starting run_phase", UVM_LOW);
        phase.raise_objection(this);

        seq = dma_basic_seq::type_id::create("seq");
        seq.desc_addr = DESC_BASE;
        seq.start(m_top_env.m_agent.sqr);

        // wait for the actual transfer to complete before ending the test
        do begin
            status_seq = read_status_seq::type_id::create("status_seq");
            status_seq.start(m_top_env.m_agent.sqr);
        end while (status_seq.req.rdata[stat_busy_bit] == 1'b1);

        `uvm_info("TEST", "DMA transfer completed, busy bit cleared", UVM_LOW);
        phase.drop_objection(this);
    endtask
endclass
