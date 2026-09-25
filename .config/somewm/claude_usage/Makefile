LUA ?= lua5.4
LUAJIT ?= luajit

.PHONY: all test test-lua test-jit lint check

all: check

test: test-lua test-jit

test-lua:
	TZ=UTC $(LUA) spec/run.lua
	TZ=Europe/Vienna $(LUA) spec/run.lua

test-jit:
	@command -v $(LUAJIT) >/dev/null 2>&1 && TZ=Europe/Vienna $(LUAJIT) spec/run.lua || echo "skip: $(LUAJIT) not installed"

lint:
	luacheck .

check: lint test
