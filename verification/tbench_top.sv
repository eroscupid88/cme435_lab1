`timescale 1ns/1ns
module tbench_top;
	logic [7:0] data_in;
	logic [7:0] data_out;
	logic [1:0] s_in;
	bit clk_in,reset_in;

	initial 
		begin
		// dut.student_no = 11100292;
		// dut.bug_mode = 1;
		// dut.enable_dut_bugs;
		end

	

	initial begin
		reset_in = 1'b1;
		#50 reset_in =1'b0;
	end

	clock_generator clock_generator(.clk_in);

	always #100 clk_in = ~clk_in;
	testbench testbench(
						.for_up_down_counter(data_in),
						.s_in,
						.reset_in,
						.clk_in,
						.data_output_from_counter(data_out)
						);
	up_down_counter dut(.data_out,
						.data_in,
						.s_in,
						.clk_in,
						.reset_in);

	
	
	endmodule