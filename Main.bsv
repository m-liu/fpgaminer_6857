
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


//last 64 bit of hash indicates num of BITS. 
function Bit#(9) getMessageLen(Bit#(512) msg);
	return truncate(msg);
endfunction


interface MineRequest;
	method Action reqMine(Struct512 r, Struct256 diffMask);
	method Action setLatencyInitNonce(Bit#(32) lat, Bit#(64) initNonce);
	method Action reqDebug(Bit#(32) dummy);
endinterface

interface MineIndication;
	method Action getGoldResults(Struct256 h, Bit#(64) goldNonce);
	method Action getDebug(Struct512 req, Struct512 currRxIn0, Struct512 currRxInMax, Bit#(64) nonce, Bit#(64) nonceMax);
endinterface

typedef 8 NUM_HASHERS;

module mkMain#(MineIndication indication)(MineRequest);


	Reg#(Bit#(512)) currReq <- mkReg(0);
	Reg#(Bit#(256)) currDiffMask <- mkReg(0); //111..000
	Reg#(Bit#(64)) initNonceR <- mkReg(0); //(nodeid)*2^62 for 4 nodes 
	Reg#(Bit#(64)) cyc <- mkReg(0);
	Reg#(Bit#(32)) latR <- mkReg(0);
	FIFO#(Tuple2#(Bit#(512), Bit#(256))) reqQ <- mkFIFO();
	
	rule cycleCnt;
		cyc <= cyc + 1;
	endrule



`ifdef BSIM
	Vector#(NUM_HASHERS, VSha) sha <- replicateM(vMkShaModel());
`else
	Vector#(NUM_HASHERS, VSha) sha <- replicateM(vMkSha());
`endif
	Vector#(NUM_HASHERS, Reg#(Bit#(512))) rxIn <- replicateM(mkReg(0));
	Vector#(NUM_HASHERS, Reg#(Bit#(64))) nonce <- replicateM(mkReg(0));
	Vector#(NUM_HASHERS, FIFO#(Tuple2#(Bit#(256), Bit#(64)))) resultsQ <- replicateM(mkFIFO());
	


	//this rule takes priority
	//if there's a new request, then we should forget the old one 
	rule handlReq;// if (st==CMD || st==PROCESS);
		match{.req, .diffmask} = reqQ.first;
		reqQ.deq;
		currReq <= req;
		currDiffMask <= diffmask;
		for (Integer i=0; i<valueOf(NUM_HASHERS); i=i+1) begin
			nonce[i] <= initNonceR + fromInteger(i); //INITIAL VALUE IS VERY IMPORTANT!
		end
		$display("@%d: Main.bsv: handle request; req=%x, diffmask=%x", cyc, req, diffmask);
	endrule

	//for each hasher..
	for (Integer i=0; i<valueOf(NUM_HASHERS); i=i+1) begin
		rule setInput;
			sha[i].setRxInput(rxIn[i]);
		endrule
	

		rule doProcess;
			let txHash = sha[i].getTxHash();
			$display("@%d:[%d] hash=%x", cyc, i, txHash);
			if ( (txHash!=0) && (txHash & currDiffMask) == 0 ) begin
				//FIXME hacky.. what's the correct latency here?
				Bit#(64) goldNonce = nonce[i] - zeroExtend(latR); 
				$display("@%d: [%d] Gold nonce found! nonce=%d", cyc, i, goldNonce);
				//indication.getGoldResults(unpack(txHash), goldNonce);
				resultsQ[i].enq(tuple2(txHash, goldNonce));
			end
		endrule
		
		
		rule doSend; // if (st==PROCESS);
				Bit#(9) msgLen = getMessageLen(currReq);
				Bit#(10) padLen = 512 - zeroExtend(msgLen);

				Bit#(64) tmpMask = -1;
				Bit#(512) tmpMaskExt = zeroExtend(tmpMask); 
				Bit#(512) nonceMask = ~ (tmpMaskExt << (padLen+32)); //11..100011..11
				Bit#(512) nonceExt = zeroExtend(nonce[i]);
				Bit#(512) newBlk = (currReq & nonceMask) | (nonceExt << (padLen+32));

				nonce[i] <= nonce[i] + fromInteger(valueOf(NUM_HASHERS)); //INCREMENT BY NUM HASHERS
				rxIn[i] <= newBlk;
				$display("@%d: [%d] Main.bsv: msgLen=%d, padLen=%d, nonceMask=%x, nonce=%d, newBlk=%x", 
							cyc, i, msgLen, padLen, nonceMask, nonce[i], newBlk);
			
		endrule

		rule gatherResults;
			resultsQ[i].deq;
			match{.hash, .goldnonce} = resultsQ[i].first;
			indication.getGoldResults(unpack(hash), goldnonce);
		endrule

	end //num hashers


	method Action reqMine(Struct512 r, Struct256 diffMask);
		reqQ.enq(tuple2(pack(r), pack(diffMask)));
	endmethod

	method Action setLatencyInitNonce(Bit#(32) lat, Bit#(64) initNonce);
		latR <= lat;
		initNonceR <= initNonce;
	endmethod

	method Action reqDebug(Bit#(32) dummy);
		indication.getDebug(unpack(currReq), unpack(rxIn[0]), unpack(rxIn[valueOf(NUM_HASHERS)-1]), nonce[0], nonce[valueOf(NUM_HASHERS)-1]);
	endmethod

endmodule
