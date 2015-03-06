`timescale 1ns/1ps


module tb_wrap();

reg clk=0;

always
	#5 clk = ~clk;


wire [511:0] rx_input = 512'hdeadbeefcafe00000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000170;
wire [255:0] tx_hash;

sha256_wrap dut (
	.clk(clk),
	.rx_input(rx_input),
	.tx_hash(tx_hash)
);


always @ (posedge clk) 
begin
	$display("rx_in=%x", rx_input);
	$display("tx_hash=%x", tx_hash);
end

endmodule
