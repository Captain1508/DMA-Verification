class dma_csr_monitor extends uvm_monitor;
    `uvm_component_utils(dma_csr_monitor)
    dma_csr_txn cov_tr;
    covergroup csr_cg;
    option.per_instance = 1;
    cp_is_write: coverpoint cov_tr.is_write;
    cp_addr: coverpoint cov_tr.addr {
    bins ctrl   = {reg_dma_control};
    bins status = {reg_dma_status};
    bins descl  = {reg_desc_ptr_l};
    bins desch  = {reg_desc_ptr_h};
    }
    addr_x_write: cross cp_is_write, cp_addr;
    endgroup
    
    function new(string name, uvm_component parent);
        super.new(name,parent);
        csr_cg = new();
    endfunction //new()

    virtual axil_if vif;
    uvm_analysis_port #(dma_csr_txn) mon_analysis_port;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_analysis_port = new("mon_analysis_port",this);
        if(!uvm_config_db #(virtual axil_if)::get(this,"","vif",vif))
        `uvm_error("NOVIF","virtual interface must be set for: dma_csr_monitor");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
    dma_csr_txn tr;
    forever begin 
        @(vif.mon_cb);
        if(vif.mon_cb.bvalid && vif.mon_cb.bready) begin
            tr = dma_csr_txn::type_id::create("tr");
            tr.addr = vif.mon_cb.awaddr;
            tr.is_write = 1'b1;
            tr.wdata = vif.mon_cb.wdata;
            cov_tr = tr;
            csr_cg.sample();
            mon_analysis_port.write(tr);
        end else if(vif.mon_cb.rvalid && vif.mn_cb.rready) begin
            tr = dma_csr_txn::type_id::create("tr");
            tr.is_write = 1'b0;
            tr.addr = vif.mon_cb.araddr;
            tr.rdata = vif.mon_cb.rdata;
            cov_tr = tr;
            csr_cg.sample();
            mon_analysis_port.write(tr);
        end 
    end
    endtask

     virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("COVERAGE",
            $sformatf("CSR Coverage = %0.2f%%",
                      csr_cg.get_inst_coverage()),
            UVM_NONE)
    endfunction
endclass //dma_csr_monitor extends uvm_monitor
