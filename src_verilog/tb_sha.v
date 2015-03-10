`timescale 1ns/1ps

module tb_sha256();
	parameter LOOP = 1;

	reg clk =0;
	wire [511:0] data =   512'hdeadbeefcafe00000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000170;

	wire [511:0] data_end_rev;
	wire [255:0] hash_out;

	//Reverse the endianness
	genvar i;
	generate
		for (i=0; i<16; i=i+1) begin: ENDIAN_REV
			assign data_end_rev[32*i +: 32] = data[32*(15-i) +: 32];
		end
	endgenerate
	
	always 
	begin
		#5 clk = ~clk;
	end

	sha256_transform #(.LOOP(LOOP)) uut (
		.clk(clk),
		.feedback(1'b0),
		.cnt(6'd0),
		.rx_state(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667), //Prime constants
		.rx_input(data_end_rev),
		.tx_hash(hash_out)
	);

	wire [255:0] hash_out_rev;
	generate
		for (i=0; i<8; i=i+1) begin: HASH_OUT_REV
			assign hash_out_rev[32*i +: 32] = hash_out[32*(7-i) +: 32];
		end
	endgenerate

	always@(posedge clk)
	begin
		$display("hashinp=%x", data);
		$display("hashirev=%x", data_end_rev);
		$display("hashout=%x", hash_out);
		$display("hashorev=%x", hash_out_rev);
	end
endmodule
