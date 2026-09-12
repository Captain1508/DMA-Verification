class dma_csr_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dma_csr_scoreboard)
function new(string name, uvm_component parent);
    super.new(name,parent);
endfunction //new()

uvm_analysis_imp #(dma_csr_txn,dma_csr_scoreboard) ap_imp;
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_imp = new("ap_imp",this);
endfunction

logic [31:0] exp_desc_ptr_l;
logic [31:0] exp_desc_ptr_h;

function void write(dma_csr_txn tr);
if(tr.is_write) begin
    case(tr.addr)
    reg_desc_ptr_l: exp_desc_ptr_l = tr.wdata;
    reg_desc_ptr_h: exp_desc_ptr_h = tr.wdata;
    default: ; 
    endcase
end else begin 
    case(tr.addr)
    reg_desc_ptr_l: begin 
        if(tr.rdata !== exp_desc_ptr_l) 
            `uvm_error("MISMATCH", $sformatf("DESC_PTR_L read %0h, expected %0h",tr.rdata,exp_desc_ptr_l))
        else 
            `uvm_info("MATCH", $sformatf("DESC_PTR_L read matched: %0h",tr.rdata),UVM_LOW)
        end
    reg_desc_ptr_h: begin
        if(tr.rdata !== exp_desc_ptr_h)
            `uvm_error("MISMATCH", $sformatf("DESC_PTR_H read %0h, expected %0h",tr.rdata,exp_desc_ptr_h))
        else 
            `uvm_info("MATCH", $sformatf("DESC_PTR_H read matched: %0h",tr.rdata),UVM_LOW)
        end
        default: ;
    endcase
end
endfunction
endclass //dma_csr_scoreboard extends uvm_scoreboard
