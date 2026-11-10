LUA_SOURCES = init.lua rakuen spec scripts

.PHONY: test lint format format-check check

test:
	busted

lint:
	luacheck $(LUA_SOURCES)
	shellcheck -x bin/install.sh

format:
	stylua $(LUA_SOURCES)

format-check:
	stylua --check $(LUA_SOURCES)

check: lint format-check test
