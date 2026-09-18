class dma_mem_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dma_mem_scoreboard)
    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction //new()

    uvm_analysis_imp #(dma_mem_txn,dma_mem_scoreboard) ap_imp;
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp",this);
    endfunction

    logic [63:0] last_read_data;
    function void write(dma_mem_txn tr);
        if(!tr.is_write) begin
            last_read_data = tr.data;
        end else begin
            if(tr.data !== last_read_data)
                `uvm_error("MISMATCH", $sformatf("write data %0h did not match last read data %0h",tr.data,last_read_data));
            else
                `uvm_info("MATCH", $sformatf("write data matched last read: %0h",tr.data), UVM_LOW);
        end
    endfunction
endclass //dma_mem_scoreboard extends uvm_scoreboard 
