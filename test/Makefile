PYTHON 		 := python
GEN_SCRIPT := autotest.py
NUM_OPS	   ?= 100
VCS 	 		 := vcs -sverilog -q -debug
SRCDIR 		 := ../src/
SRC		 		 := $(SRCDIR)*.sv

.PHONY: clean

rand:
	$(VCS) -o randtest +incdir+$(SRCDIR) randtest.sv $(SRC)

test-%:
	$(VCS) -o $*_test +incdir+$(SRCDIR) $*_test.sv $(SRC)

clean:
	rm -rf csrc *.daidir *_test randtest ucli.key simv*
