
`timescale 1ns/1ns
module reset_driver(output bit reset_in);
    bit local_reset = 1'b1;
    assign reset_in =local_reset;
    initial 
    begin
    # 50  local_reset =1'b0;
    // #240 local_reset =1'b0;
    // #1200 local_reset = 1'b0;
    end
endmodule