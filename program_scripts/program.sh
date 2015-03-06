
#rm -rf build ; tar xzf c.tgz ; cd build ;
#cd hw;
#vivado -mode batch -source program-a7-clear.tcl
#vivado -mode batch -source program-v7-clear.tcl
#vivado -mode batch -source program-a7.tcl
#vivado -mode batch -source program-v7.tcl
vivado -mode batch -source program-vc.tcl
#cd ;

#rm -rf vc707/ ; tar xzf m.tgz ; cd vc707/ ;
# fpgajtag hw/mkPcieTop.bin
#../fpgajtag_stable hw/mkPcieTop.bin

#cd hw ;
#vivado -mode batch -source program-vc707.tcl
pciescanportal
sleep 0.5
sudo chmod agu+rw /dev/fpga*
sudo chmod agu+rw /dev/portalmem
#cd;
#sudo ./portaldriver.sh
