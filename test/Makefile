VCS 	 := vcs -sverilog -q
SRCDIR := ../src/
SRC		 := $(wildcard $(SRCDIR)*.sv)

.PHONY: clean

test-%:
	$(VCS) -o $*_test +incdir+$(SRCDIR) $*_test.sv $(SRC) -debug;

clean:
	rm -rf csrc *.daidir *_test ucli.key simv*
