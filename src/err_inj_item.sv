class err_inj_item extends axi_base_item;
    `uvm_object_utils(err_inj_item)
    
    rand axi_err_e err_type;

    function new(string name = "err_inj_item");
        super.new(name);
    endfunction

    
    
        constraint c_burst_len {
            if(err_type == ERR_BURST_LEN){
                if(burst == FIXED) {
                    len > 15;
                }
                else if (burst == INCR) {
                    ((addr[11:0]>>size)<<size)+(1<<size)*(len+1) > (1<<12);
                }
                else if (burst == WRAP) {
                    len inside {[0:15]};
                    ~(len inside {1,3,7,15});
                }
            }
        }
    


endclass



    