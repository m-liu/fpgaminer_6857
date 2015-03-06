`timescale 1ns/1ps

module sha256_wrap(
	input clk,
	input rst, //unused
	input [511:0] rx_input,
	output [255:0] tx_hash
);
	parameter LOOP = 1;

	wire [255:0] hash_out;
	//wire [511:0] data =   512'hdeadbeefcafe00000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000170;

	wire [511:0] rx_input_rev;

	genvar i;
	generate
		for (i=0; i<16; i=i+1) begin: ENDIAN_REV
			assign rx_input_rev[32*i +: 32] = rx_input[32*(15-i) +: 32];
		end
	endgenerate
	
	sha256_transform #(.LOOP(LOOP)) uut (
		.clk(clk),
		.feedback(1'b0),
		.cnt(6'd0),
		.rx_state(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
		.rx_input(rx_input_rev),
		.tx_hash(hash_out)
	);

	wire [255:0] hash_out_rev;
	generate
		for (i=0; i<8; i=i+1) begin: HASH_OUT_REV
			assign hash_out_rev[32*i +: 32] = hash_out[32*(7-i) +: 32];
		end
	endgenerate


	//outputs
	assign tx_hash = hash_out_rev;

/*
	always@(posedge clk)
	begin
		$display("hashinp=%x", rx_input);
		$display("hashirev=%x", rx_input_rev);
		$display("hashout=%x", hash_out);
		$display("hashorev=%x", tx_hash);
	end
*/
endmodule
