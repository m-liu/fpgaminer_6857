`timescale 1ns/1ps


module tb_top();


reg clk=0;

always
	#5 clk = ~clk;

mkMine dut (.CLK(clk),
			    .RST_N(1)
			 );

endmodule
