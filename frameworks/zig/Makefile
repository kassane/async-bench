# Makefile for building and running a Zig project using `zig build`

# Location of the `zig` executable
ZIG = zig

# Target for building the project
all: build

# Build the project using `zig build`
build:
	$(ZIG) build -Doptimize=ReleaseFast --summary all

# Clean the project
clean:
	rm -rf zig-cache
	rm -rf zig-out

# Run the project
run: build
	$(ZIG) build run -Doptimize=ReleaseFast

.PHONY: all build clean run
