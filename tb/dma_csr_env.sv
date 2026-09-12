class dma_csr_env extends uvm_env;
    `uvm_component_utils(dma_csr_env)
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    dma_csr_agent m_agent;
    dma_csr_scoreboard m_scoreboard;
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_agent = dma_csr_agent::type_id::create("m_agent",this);
        m_scoreboard = dma_csr_scoreboard::type_id::create("m_scoreboard",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_agent.mon.mon_analysis_port.connect(m_scoreboard.ap_imp);
endfunction
endclass //dma_csr_env extends uvm_environment
