
// Copyright (c) 2013 Nokia, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import FIFO::*;
import Vector::*;

import Sha256::*;


typedef struct{
   Bit#(32) v0;
   Bit#(32) v1;
   Bit#(32) v2;
   Bit#(32) v3;
   Bit#(32) v4;
   Bit#(32) v5;
   Bit#(32) v6;
   Bit#(32) v7;
} Struct256 deriving (Bits, Eq);


typedef struct{
   Bit#(32) v0;
   Bit#(32) v1;
   Bit#(32) v2;
   Bit#(32) v3;
   Bit#(32) v4;
   Bit#(32) v5;
   Bit#(32) v6;
   Bit#(32) v7;
   Bit#(32) v8;
   Bit#(32) v9;
   Bit#(32) v10;
   Bit#(32) v11;
   Bit#(32) v12;
   Bit#(32) v13;
   Bit#(32) v14;
   Bit#(32) v15;
} Struct512 deriving (Bits, Eq);



interface MineRequest;
	method Action setTxIn(Struct512 d);
endinterface

interface MineIndication;
	method Action getHash(Struct256 h);
endinterface


module mkMain#(MineIndication indication)(MineRequest);


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


	rule doIndicate;
		indication.getHash(unpack(txHash));
		$display("getHash: %x", txHash);
	endrule

	method Action setTxIn(Struct512 d);
		rxIn <= pack(d);
		$display("setTxIn: %x", pack(d));
	endmethod
endmodule
