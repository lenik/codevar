PREFIX ?= /usr
DESTDIR ?=
BINDIR = $(DESTDIR)$(PREFIX)/bin
MANDIR = $(DESTDIR)$(PREFIX)/share/man/man1
COMPLETIONDIR = $(DESTDIR)$(PREFIX)/share/bash-completion/completions

CC = gcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -lm

BASE91_TARGET = base91
BASE91_SOURCES = base91.c
BASE91_OBJECTS = $(BASE91_SOURCES:.c=.o)

CODEVAR_SCRIPT = codevar

.PHONY: all clean install install-symlinks uninstall uninstall-symlinks

all: $(BASE91_TARGET)

$(BASE91_TARGET): $(BASE91_OBJECTS)
	$(CC) $(BASE91_OBJECTS) -o $@ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(BASE91_TARGET) $(BASE91_OBJECTS)

install: $(BASE91_TARGET) $(CODEVAR_SCRIPT)
	install -d $(BINDIR)
	install -m 755 $(BASE91_TARGET) $(BINDIR)/
	install -m 755 $(CODEVAR_SCRIPT) $(BINDIR)/
	ln -sf $(BASE91_TARGET) $(BINDIR)/base85
	ln -sf $(BASE91_TARGET) $(BINDIR)/base122
	install -d $(MANDIR)
	install -m 644 base91.1 $(MANDIR)/
	install -m 644 codevar.1 $(MANDIR)/
	ln -sf base91.1 $(MANDIR)/base85.1
	ln -sf base91.1 $(MANDIR)/base122.1
	install -d $(COMPLETIONDIR)
	install -m 644 base91.bash-completion $(COMPLETIONDIR)/base91
	install -m 644 codevar.bash-completion $(COMPLETIONDIR)/codevar
	ln -sf base91 $(COMPLETIONDIR)/base85
	ln -sf base91 $(COMPLETIONDIR)/base122

uninstall:
	rm -f $(BINDIR)/$(BASE91_TARGET)
	rm -f $(BINDIR)/$(CODEVAR_SCRIPT)
	rm -f $(BINDIR)/base85
	rm -f $(BINDIR)/base91
	rm -f $(BINDIR)/base122
	rm -f $(MANDIR)/base91.1
	rm -f $(MANDIR)/base85.1
	rm -f $(MANDIR)/base122.1
	rm -f $(MANDIR)/codevar.1
	rm -f $(COMPLETIONDIR)/base91
	rm -f $(COMPLETIONDIR)/base85
	rm -f $(COMPLETIONDIR)/base122
	rm -f $(COMPLETIONDIR)/codevar

install-symlinks:
	@echo "Installing symlinks to /usr (hardcoded)"
	@if [ -f $(BASE91_TARGET) ]; then \
		sudo ln -sf $(abspath $(BASE91_TARGET)) /usr/bin/base85; \
		sudo ln -sf $(abspath $(BASE91_TARGET)) /usr/bin/base91; \
		sudo ln -sf $(abspath $(BASE91_TARGET)) /usr/bin/base122; \
		echo "Binary symlinks installed: base85, base91, base122 -> $(abspath $(BASE91_TARGET))"; \
	else \
		echo "Error: $(BASE91_TARGET) not found. Run 'make' first."; \
		exit 1; \
	fi
	@if [ -f base91.1 ]; then \
		sudo ln -sf $(abspath base91.1) /usr/share/man/man1/base85.1; \
		sudo ln -sf $(abspath base91.1) /usr/share/man/man1/base122.1; \
		echo "Man page symlinks installed: base85.1, base122.1 -> $(abspath base91.1)"; \
	else \
		echo "Warning: base91.1 not found. Skipping man page symlinks."; \
	fi
	@if [ -f base91.bash-completion ]; then \
		sudo ln -sf $(abspath base91.bash-completion) /usr/share/bash-completion/completions/base85; \
		sudo ln -sf $(abspath base91.bash-completion) /usr/share/bash-completion/completions/base122; \
		echo "Bash completion symlinks installed: base85, base122 -> $(abspath base91.bash-completion)"; \
	else \
		echo "Warning: base91.bash-completion not found. Skipping bash completion symlinks."; \
	fi

uninstall-symlinks:
	@echo "Removing symlinks from /usr (hardcoded)"
	@sudo rm -f /usr/bin/base85
	@sudo rm -f /usr/bin/base91
	@sudo rm -f /usr/bin/base122
	@sudo rm -f /usr/share/man/man1/base85.1
	@sudo rm -f /usr/share/man/man1/base122.1
	@sudo rm -f /usr/share/bash-completion/completions/base85
	@sudo rm -f /usr/share/bash-completion/completions/base122
	@echo "Symlinks removed from /usr"
