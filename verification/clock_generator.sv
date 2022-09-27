
`timescale 1ns/1ns

module clock_generator(output bit clk_in);
    bit local_clock = 1'b0;
    assign clk_in =local_clock;
    always #100 local_clock = ~local_clock;
endmodule