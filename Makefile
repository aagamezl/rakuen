LUA_SOURCES = init.lua rakuen spec scripts

.PHONY: test lint format format-check docs docs-check check

test:
	busted

lint:
	luacheck $(LUA_SOURCES)
	shellcheck -x bin/install.sh

format:
	stylua $(LUA_SOURCES)

format-check:
	stylua --check $(LUA_SOURCES)

docs:
	lua scripts/generate_docs.lua

docs-check:
	lua scripts/generate_docs.lua --check

check: lint format-check docs-check test
