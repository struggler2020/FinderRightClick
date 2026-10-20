.PHONY: all build install uninstall clean

all: build

build:
	@./scripts/build.sh

install:
	@./scripts/install.sh

uninstall:
	@./scripts/uninstall.sh

clean:
	@rm -rf build/
	@echo "==> Cleaned build directory."
