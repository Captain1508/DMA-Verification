class dma_mem_monitor extends uvm_monitor;
    `uvm_component_utils(dma_mem_monitor)
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    virtual axim_if vif;
    uvm_analysis_port #(dma_mem_txn) mon_analysis_port;

    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_analysis_port = new("mon_analysis_port",this);
    if(!uvm_config_db #(virtual axim_if)::get(this,"","vif",vif))
    `uvm_error(get_type_name(),"Didn't get handle to virtual interface axim_if");
    endfunction

    virtual task run_phase(uvm_phase phase);
        dma_mem_txn tr;
        forever begin 
            @(vif.mon_cb);
            if(vif.mon_cb.m_axi_bvalid_i) begin           //bready
                tr = dma_mem_txn::type_id::create("tr");
                tr.addr = vif.mon_cb.m_axi_awaddr_o;
                tr.is_write = 1; 
                tr.data = vif.mon_cb.m_axi_wdata_o;
                mon_analysis_port.write(tr);
            end else if(vif.mon_cb.m_axi_rvalid_i) begin  //rready
                tr = dma_mem_txn::type_id::create("tr");
                tr.addr = vif.mon_cb.m_axi_araddr_o;
                tr.is_write = 0;
                tr.data = vif.mon_cb.m_axi_rdata_i;
                mon_analysis_port.write(tr);
            end
        end
    endtask
endclass //dma_mem_monitor extends uvm_monitor
