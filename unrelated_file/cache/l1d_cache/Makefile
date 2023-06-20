FLIST = ./flist.f
sim_log = "./logs"
dump_on = 1

default:
	vcs +vcs+lic+wait -sverilog -kdb +vc +error+3  -F "$(FLIST)"  +lint=TFIPC-L -full64 -timescale=1ns/1ps -debug_access -l bld.log


run:
	-mkdir $(sim_log)
	time ./simv +dumpon=$(dump_on) +sim_log=$(sim_log)  2>&1 | tee run_2_$(debug_print_on).log

clean:
	-rm bld.log simv ucli.key waves.*
	-rm -r csrc simv.daidir logs Verdi-SXLog
	-rm *.log
	-rm novas* .nfs* 