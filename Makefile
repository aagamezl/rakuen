LUA_SOURCES = init.lua rakuen spec scripts

.PHONY: test lint format format-check check

test:
	busted

lint:
	luacheck $(LUA_SOURCES)

format:
	stylua $(LUA_SOURCES)

format-check:
	stylua --check $(LUA_SOURCES)

check: lint format-check test
