PYTHON 		 := python
GEN_SCRIPT := autotest.py
NUM_OPS	   ?= 100
VCS 	 		 := vcs -sverilog -q
SRCDIR 		 := ../src/
SRC		 		 := $(wildcard $(SRCDIR)*.sv)

.PHONY: clean

randtest:
	$(PYTHON) $(GEN_SCRIPT) --nums=$(NUM_OPS);
	$(VCS) -o randtest +incdir+$(SRCDIR) randtest.sv $(SRC)

test-%:
	$(VCS) -o $*_test +incdir+$(SRCDIR) $*_test.sv $(SRC) -debug;

clean:
	rm -rf csrc *.daidir *_test randtest ucli.key simv*
