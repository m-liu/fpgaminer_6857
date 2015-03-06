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

#include "MineRequest.h"
#include "MineIndication.h"


class MineIndication : public MineIndicationWrapper
{  
public:
		MineIndication(unsigned int id) : MineIndicationWrapper(id){}
		virtual void getHash(Struct256 h) {
			printf("%08x", h.v0);
			printf("%08x", h.v1);
			printf("%08x", h.v2);
			printf("%08x", h.v3);
			printf("%08x", h.v4);
			printf("%08x", h.v5);
			printf("%08x", h.v6);
			printf("%08x", h.v7);
			printf("\n");
		}
		
};



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
}


int main(int argc, const char **argv)
{
  MineIndication *indication = new MineIndication(IfcNames_MineIndication);
  MineRequestProxy *device = new MineRequestProxy(IfcNames_MineRequest);
  //device->pint.busyType = BUSY_SPIN;   /* spin until request portal 'notFull' */

  portalExec_start();


//deadbeefcafe00000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000170

	Struct512 inp = {
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
	print512(inp);

  device->setTxIn(inp);

  fprintf(stderr, "Main::about to go to sleep\n");
  while(true){sleep(10000000);}
}
