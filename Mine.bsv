import Connectable       ::*;
import Clocks            ::*;
import FIFO              ::*;
import FIFOF             ::*;
import Vector            ::*;

import Sha256 ::*;

module mkMine();
	VSha sha <- vMkSha();
	Reg#(Bit#(512)) rxIn <- mkReg(0);
	Reg#(Bit#(256)) txHash <- mkReg(0);

	rule setInput;
		sha.setRxInput(rxIn);
	endrule

	rule getOut;
		txHash <= sha.getTxHash();
		$display("@%t: hash=%x", $time, txHash);
	endrule

	rule doTest;
		rxIn <= 512'hdeadbeefcafe00000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000170;
	endrule
endmodule
