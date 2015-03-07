import Clocks            ::*;
import FIFO::*;
import Vector::*;

(* always_ready, always_enabled *)
interface VSha;
	method Action setRxInput (Bit#(512) i);
	method Bit#(256) getTxHash();
endinterface

import "BVI" sha256_wrap = 
module vMkSha(VSha ifc);
	default_clock clk;
	default_reset rst;
	
	input_clock clk (clk) <- exposeCurrentClock;
	input_reset rst (rst) <- exposeCurrentReset;

	method setRxInput(rx_input) enable((*inhigh*)en0);
	method tx_hash getTxHash();

schedule (setRxInput, getTxHash) CF (setRxInput, getTxHash);

endmodule

typedef 66 NUM_PIPE_STAGES;
Integer num_pipe_stages = valueOf(NUM_PIPE_STAGES);

module vMkShaModel(VSha ifc);
	
	Vector#(NUM_PIPE_STAGES, Reg#(Bit#(512))) pipeReg <- replicateM(mkReg(0));

	for (Integer i=1; i<num_pipe_stages; i=i+1) begin
	rule doRegPipe;
			pipeReg[i] <= pipeReg[i-1];
	endrule
	end


	method Action setRxInput (Bit#(512) in);
		pipeReg[0] <= in;
	endmethod
	method Bit#(256) getTxHash();
		return truncateLSB(pipeReg[num_pipe_stages-1]); //just mirror the input
	endmethod

endmodule


