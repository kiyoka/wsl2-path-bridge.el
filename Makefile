.PHONY: test clean

EMACS ?= emacs

test:
	$(EMACS) -batch \
		-l ert \
		-l test/wsl2-path-bridge-test.el \
		-f ert-run-tests-batch-and-exit

clean:
	rm -f *.elc test/*.elc
