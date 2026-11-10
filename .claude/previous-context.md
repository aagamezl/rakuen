Create a detailed plan with different phases to implement the rakuen project.

Create a checkbox list with all the tasks to implement; this list will represent the implementation goals and status.
Use the taskmd, gnome-keybindings.txt and gnome_hammerspoon_keymap_initial_plan.md to create a plan to implement the solution.
gnome_hammerspoon_keymap_initial_plan.md is my own plan, but use it only as extra context, use, modify or ignore anything you need for your plan
I wrote the plan to IMPLEMENTATION_PLAN.md in your Rakuen folder. It has 16 phases (0–15) and checkbox tasks you can tick as you go, and the phase 1 spikes are the ones most likely to change the plan.

Where I changed your draft:

Spikes first: phase 1 tests which chords the system consumes before Hammerspoon sees them, such as Ctrl+Arrow and Ctrl+Tab. Whether text navigation works at all depends on those results.
Generated docs: docs/keybindings.md and the cheatsheet are generated from the same rule tables, so they can’t drift apart.
Safety: your draft didn’t cover marking Rakuen’s own synthetic keys so they aren’t remapped again, a watchdog that restarts the keyboard hook, or a panic hotkey that disables Rakuen. I added all three.
Stretch items: clipboard history is in phase 15 as optional, since task.md doesn’t ask for it.
Questions for you:

Should native Cmd+<key> shortcuts (like Cmd+C) keep working after the remap? I assumed yes, with a config option to block them later.
Is it OK for the installer to move the macOS Spaces shortcuts off Ctrl+Left/Right? I assumed yes, so those chords can be word-motion keys and Space switching moves to another chord.
I’ll proceed on those defaults unless you say otherwise.


Implementation plan
Document·MD
brew install lua@5.4 luarocks stylua
luarocks --lua-version 5.4 --lua-dir "$(brew --prefix lua@5.4)" install luacheck
luarocks --lua-version 5.4 --lua-dir "$(brew --prefix lua@5.4)" install busted
make check
                                                                                                                                                                                                             ✔
luacheck rakuen spec
make: luacheck: No such file or directory
make: *** [lint] Error 1

The install worked, but the 5.4 wrappers went to a directory that isn’t on your PATH. Find it:

sh
luarocks --lua-version 5.4 path --lr-bin
That prints the directory, probably /opt/homebrew/lib/luarocks/rocks-5.4/... or ~/.luarocks/bin. Check that luacheck and busted are in it, then add it to PATH for this shell and permanently:

sh
export PATH="$(luarocks --lua-version 5.4 path --lr-bin):$PATH"
echo 'export PATH="$(luarocks --lua-version 5.4 path --lr-bin):$PATH"' >> ~/.zshrc
hash -r
which luacheck busted
make check
If which finds nothing, send me the output of the first command and ls on that directory.

export PATH="$(luarocks --lua-version 5.4 path --lr-bin):$PATH"                     ✔

Error: Could not find Lua 5.4 in PATH.
Please set your Lua interpreter with:

   luarocks --lua-version=5.4 --local config variables.LUA </path/lua>

My command was missing --lua-dir, and that’s also why the line I had you append to ~/.zshrc is wrong. Use this form:

sh
BIN_DIR="$(luarocks --lua-version 5.4 --lua-dir "$(brew --prefix lua@5.4)" path --lr-bin)"
echo "$BIN_DIR"
ls "$BIN_DIR"
If luacheck and busted are listed, add that directory to your path. This writes a fixed path, so .zshrc doesn’t call luarocks on every shell start:

sh
export PATH="$BIN_DIR:$PATH"
echo "export PATH=\"$BIN_DIR:\$PATH\"" >> ~/.zshrc
hash -r
make check
If you already ran my earlier echo ... >> ~/.zshrc, open ~/.zshrc and delete that line first. It calls luarocks without --lua-dir and prints an error on every new shell.

make check                                                                                                                                                                                                                    ✔
luacheck rakuen spec
Checking spec/helpers/hs_mock.lua                 OK
Checking spec/hs_mock_spec.lua                    OK

Total: 0 warnings / 0 errors in 2 files
stylua --check rakuen spec
busted
●●
2 successes / 0 failures / 0 errors / 0 pending : 0.002388 seconds

Edited a file IMPLEMENTATION_PLAN.md
make check is green locally, so Phase 0 is done apart from the first GitHub CI run, which I noted in the plan.

Phase 1 is next: building the keybinding catalog and the feasibility spikes. The spikes can’t run in my sandbox, so I’ll write a small Hammerspoon script that logs what each key does on your Mac and you paste the results back. Should I start?

starts Phase 1

Phase 1 has two parts. The catalog is written and ticked off (1.1–1.3). The spikes (1.4–1.9) are ready to run but need your Mac.

Catalog: docs/keybindings.md has all the sections with GNOME, configured, macOS original, possible, and notes columns. Reconciling your draft against the dump turned up chords the draft missed, listed in its “Reconciliation” section. The main ones:

Rename: F2, Finder only.
Input source: Super+Space.
Apps: Switch to application N and open a new window of application N.
Tabs: Ctrl+1 to Ctrl+9.
Selection: select by paragraph.
Cmd+F1 conflict: it is both macOS display mirroring and GNOME Help, so Help takes it and Cmd+P sends the native mirroring toggle.
Spikes: scripts/spikes/spikes.lua has five spikes that run for 30 seconds each and then stop on their own. They are log_keys, swallow_test, synthetic_marker, inspect_focus, and stop_all. docs/feasibility.md has the steps and result tables for you to fill in.

To run them:

lua
spikes = dofile("/Users/aagamezl/workspace/personal/git-repos/rakuen/scripts/spikes/spikes.lua")
spikes.help()
I couldn’t run the script myself, so run make format and then make check first. Then run the spikes and send me the contents of ~/rakuen-spike-log.txt. I’ll fill in the results and settle D5 and D7, and the Space-switching and Super+Space decisions, to close out Phase 1.
