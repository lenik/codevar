.PHONY: test test-base91 test-codevar clean

test: test-base91 test-codevar

test-base91:
	@echo "Running base91 tests..."
	@chmod +x test_base91.sh
	@./test_base91.sh

test-codevar:
	@echo "Running codevar tests..."
	@chmod +x test_codevar.sh
	@./test_codevar.sh

clean:
	@rm -rf /tmp/tmp.*
	@echo "Cleaned test temporary files"

