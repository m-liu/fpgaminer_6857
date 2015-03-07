/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <assert.h>
#include <string.h>

#include "MineRequest.h"
#include "MineIndication.h"


void print256 (Struct256 s) {
			printf("%08x", s.v0);
			printf("%08x", s.v1);
			printf("%08x", s.v2);
			printf("%08x", s.v3);
			printf("%08x", s.v4);
			printf("%08x", s.v5);
			printf("%08x", s.v6);
			printf("%08x", s.v7);
			printf("\n");
			fflush(stdout);
}

void print512 (Struct512 s) {
			printf("%08x", s.v0);
			printf("%08x", s.v1);
			printf("%08x", s.v2);
			printf("%08x", s.v3);
			printf("%08x", s.v4);
			printf("%08x", s.v5);
			printf("%08x", s.v6);
			printf("%08x", s.v7);
			printf("%08x", s.v8);
			printf("%08x", s.v9);
			printf("%08x", s.v10);
			printf("%08x", s.v11);
			printf("%08x", s.v12);
			printf("%08x", s.v13);
			printf("%08x", s.v14);
			printf("%08x", s.v15);
			printf("\n");
			fflush(stdout);
}

class MineIndication : public MineIndicationWrapper
{  
public:
		MineIndication(unsigned int id) : MineIndicationWrapper(id){}
		virtual void getGoldResults(Struct256 h, uint64_t nonce) {
			printf("Gold results:"); 
			print256(h);
			printf("gold nonce:%lu\n", nonce);
			fflush(stdout);
		}

		virtual void getDebug(Struct512 req, Struct512 currRxIn0, Struct512 currRxInMax, uint64_t nonce, uint64_t nonceMax) {
			printf("---------------\nDebug\n");
			printf("req="); print512(req);
			printf("currRxIn[hasher=0]="); print512(currRxIn0);
			printf("currRxInMax[hasher=last] ="); print512(currRxInMax);
			printf("nonce[hasher=0] = %lu\n", nonce);
			printf("nonce[hasher=last] = %lu\n", nonceMax);
		}
};


#define NUM_NODES 2
#define MY_NODE_ID 1

int main(int argc, const char **argv)
{
	MineIndication *indication = new MineIndication(IfcNames_MineIndication);
	MineRequestProxy *device = new MineRequestProxy(IfcNames_MineRequest);
	device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */
	
	portalExec_start();
	
	uint64_t maxNonce = -1;
	uint64_t noncePiece = maxNonce/NUM_NODES;
	uint64_t initNonce = MY_NODE_ID * noncePiece;
	fprintf(stderr, "maxNonce=%lx, noncePiece=%lx, initNonce=%lx\n", maxNonce, noncePiece, initNonce);
	device->setLatencyInitNonce(66, initNonce);
	
	//deadbeefcafe00000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000170
	//group chain
	//0000008e859f76b34c4ffe2b32e5f912a2f5dffaed2aa84cfaac61dcabdd74e33239000000000000000000000003800000000000000000000000000000000170
	//                       "000000000029bc81be12df0f047234932dd61d5c996359d584f4df68c94d771d32390000000000000000000006e5"
	
	//char reqHeader[256] = "00000000002fa56340caf894bf0c34b785c6b762d87a3e706998f337f36c013b32390000000000000000000006e6";
	char reqHeader[256] = "00000000003fba3ceb3b372a61470aed0b4db3262d43fddaf09367e92d40bded32390000000000000000000006e7";
	char pad[256] = "800000000000000000000000000000000170";
	char reqChar[512];
	
	strcpy(reqChar, reqHeader);
	strcat(reqChar, pad);
	
	printf("reqChar=%s\n", reqChar); fflush(stdout);
	//printf("reqHeader=%x\n", reqHeader); fflush(stdout);
	
	//unsigned long ul[16];
	unsigned long ul[16];
	char tmpStr[512];
	
	for (int i=0; i<128; i+=8) {
		strncpy(tmpStr, &(reqChar[i]), 8);
		tmpStr[8] = '\0';
		ul[i/8] = strtoul(tmpStr,NULL,16);
		printf("[%d] tmpStr=%s, ul=%lx\n", i/8, tmpStr, ul[i/8]); 
	}
	fflush(stdout);
	
	Struct512 req = { ul[0], ul[1], ul[2], ul[3], ul[4], ul[5], ul[6], ul[7],
		ul[8], ul[9], ul[10], ul[11], ul[12], ul[13], ul[14], ul[15]};
	
	
	//TODO
	Struct256 diffmask = {
		0xFFFFFFFF,
		0xFF800000,
		0x00000000,
		0x00000000,
		0x00000000,
		0x00000000,
		0x00000000,
		0x00000000
	};
	
	printf("req: ");
	print512(req);
	printf("diffMask: ");
	print256(diffmask);
	
	device->reqMine(req, diffmask);
	
	
	fprintf(stderr, "Main::mining starts\n");
	while(true){
		device->reqDebug(0);
		sleep(60);
	}
	
}




//
/*
	Struct512 req = {
							0x0000008e,
						   0x859f76b3,
							0x4c4ffe2b,
							0x32e5f912,
							0xa2f5dffa,
							0xed2aa84c,
							0xfaac61dc,
							0xabdd74e3,
							0x32390000,
							0x00000000,
							0x00000000,
							0x00038000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000170};
*/
	/*
	Struct512 req = {
							0xdeadbeef,
						   0xcafe0000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00008000,
							0x00000000,
							0x00000000,
							0x00000000,
							0x00000170
	};
	*/
