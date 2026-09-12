class dma_csr_driver extends uvm_driver #(dma_csr_txn);
    `uvm_component_utils(dma_csr_driver)
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    virtual axil_if vif;
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual axil_if)::get(this,"","vif",vif))
    `uvm_fatal("NOVIF","virtual interface must be set for: dma_csr_driver")
endfunction

task run_phase(uvm_phase phase);
forever begin
    seq_item_port.get_next_item(req);

    if(req.is_write) begin 
        vif.drv_cb.awaddr <= req.addr;
        vif.drv_cb.awvalid <= 1;
        vif.drv_cb.wdata <= req.wdata;
        vif.drv_cb.wvalid <= 1;
        @(vif.drv_cb iff (vif.drv_cb.awready && vif.drv_cb.wready));        
        vif.drv_cb.awvalid <= 0;
        vif.drv_cb.wvalid <= 0;
        @(vif.drv_cb iff (vif.drv_cb.bvalid == 1'b1));
    end else begin
        vif.drv_cb.araddr <= req.addr;
        vif.drv_cb.arvalid <= 1;
        @(vif.drv_cb iff (vif.drv_cb.arready == 1'b1));
        vif.drv_cb.arvalid <= 0;
        @(vif.drv_cb iff (vif.drv_cb.rvalid == 1'b1));
        req.rdata = vif.drv_cb.rdata;
    end
    seq_item_port.item_done();
end
endtask
endclass //dma_csr_driver extends uvm_driver 
