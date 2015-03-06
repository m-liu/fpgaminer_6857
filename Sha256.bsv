import Clocks            ::*;

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




