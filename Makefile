# Makefile for MuType

EMACS ?= emacs
BATCH = $(EMACS) -Q --batch -L .

ELS = mutype.el
ELCS = $(ELS:.el=.elc)
TEST_ELS = test/mutype-test.el

.PHONY: all compile test lint clean

all: compile test lint

compile: $(ELCS)

%.elc: %.el
	@echo "Compiling $<..."
	@$(BATCH) -f batch-byte-compile $<

test: compile
	@echo "Running tests..."
	@$(BATCH) -L test -l $(TEST_ELS) -f ert-run-tests-batch-and-exit

lint:
	@echo "Running checkdoc..."
	@$(BATCH) --eval "(checkdoc-file \"mutype.el\")"
	@echo "Running package-lint..."
	@$(BATCH) -l package-lint -f package-lint-batch-and-exit $(ELS) || echo "Note: package-lint requires the 'package-lint' package to be installed."

clean:
	@echo "Cleaning up..."
	@rm -f $(ELCS)
