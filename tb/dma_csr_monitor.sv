class dma_csr_monitor extends uvm_monitor;
    `uvm_component_utils(dma_csr_monitor)
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    virtual axil_if vif;
    uvm_analysis_port #(dma_csr_txn) mon_analysis_port;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_analysis_port = new("mon_analysis_port",this);
        if(!uvm_config_db #(virtual axil_if)::get(this,"","vif",vif))
        `uvm_error("NOVIF","virtual interface must be set for: dma_csr_monitor")
    endfunction

    virtual task run_phase(uvm_phase phase);
    dma_csr_txn tr;
    forever begin 
        @(vif.mon_cb);
        if(vif.mon_cb.bvalid) begin
            tr = dma_csr_txn::type_id::create("tr",this);
            tr.addr = vif.mon_cb.awaddr;
            tr.is_write = 1'b1;
            tr.wdata = vif.mon_cb.wdata;
            mon_analysis_port.write(tr);
        end else if(vif.mon_cb.rvalid) begin
            tr = dma_csr_txn::type_id::create("tr",this);
            tr.is_write = 1'b0;
            tr.addr = vif.mon_cb.araddr;
            tr.rdata = vif.mon_cb.rdata;
            mon_analysis_port.write(tr);
        end 
    end
    endtask
endclass //dma_csr_monitor extends uvm_monitor
