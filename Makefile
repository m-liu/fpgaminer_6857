CONNECTALDIR=/home/mingliu/bluedbm/tools/connectal/

INTERFACES = MineRequest MineIndication

NUMBER_OF_MASTERS=0

BSVFILES = Main.bsv Top.bsv

CPPFILES=main.cpp

ifeq ($(BOARD), vc707)
CONNECTALFLAGS += \
	--verilog ./ \
	--verilog ./src_verilog/
endif 

include $(CONNECTALDIR)/Makefile.connectal
