-- Window action menu (GNOME Alt+Space): a chooser with the window actions.
--
-- `choices` and `run` are pure. `show` opens the chooser through `hs`.

local window_menu = {}

-- Order is the order shown. `hint` is the chord that does the same thing.
local ENTRIES = {
  {
    id = "toggle_maximize",
    text = "Maximize or restore",
    hint = "Opt+F10",
    run = function(manager, win)
      return manager:toggle_maximize(win)
    end,
  },
  {
    id = "tile_left",
    text = "Tile left",
    hint = "Cmd+Left",
    run = function(manager, win)
      return manager:tile(win, "left")
    end,
  },
  {
    id = "tile_right",
    text = "Tile right",
    hint = "Cmd+Right",
    run = function(manager, win)
      return manager:tile(win, "right")
    end,
  },
  {
<<<<<<< HEAD
    id = "tile_top_left",
    text = "Tile top left",
    hint = "Cmd+Left, then Cmd+Up",
    run = function(manager, win)
      return manager:tile_to(win, "top_left")
    end,
  },
  {
    id = "tile_top_right",
    text = "Tile top right",
    hint = "Cmd+Right, then Cmd+Up",
    run = function(manager, win)
      return manager:tile_to(win, "top_right")
    end,
  },
  {
    id = "tile_bottom_left",
    text = "Tile bottom left",
    hint = "Cmd+Left, then Cmd+Down",
    run = function(manager, win)
      return manager:tile_to(win, "bottom_left")
    end,
  },
  {
    id = "tile_bottom_right",
    text = "Tile bottom right",
    hint = "Cmd+Right, then Cmd+Down",
    run = function(manager, win)
      return manager:tile_to(win, "bottom_right")
    end,
  },
  {
=======
>>>>>>> 669e447 (feat: text navigation module complete)
    id = "minimize",
    text = "Minimize",
    hint = "Cmd+H",
    run = function(manager, win)
      return manager:minimize(win)
    end,
  },
  {
    id = "move",
    text = "Move",
    hint = "Opt+F7",
    run = function(_, win, modal)
      modal.start(win, "move")
      return "done"
    end,
  },
  {
    id = "resize",
    text = "Resize",
    hint = "Opt+F8",
    run = function(_, win, modal)
      modal.start(win, "resize")
      return "done"
    end,
  },
  {
    id = "display_left",
    text = "Move to display on the left",
    hint = "Cmd+Shift+Left",
    run = function(manager, win)
      return manager:move_to_display(win, "left")
    end,
  },
  {
    id = "display_right",
    text = "Move to display on the right",
    hint = "Cmd+Shift+Right",
    run = function(manager, win)
      return manager:move_to_display(win, "right")
    end,
  },
  {
    id = "close",
    text = "Close",
    hint = "Opt+F4",
    run = function(manager, win)
      return manager:close(win)
    end,
  },
}

local SHOW_DELAY_SECONDS = 0.15

--- Chooser rows: { text, subText, id }.
function window_menu.choices()
  local rows = {}
  for _, entry in ipairs(ENTRIES) do
    table.insert(rows, { text = entry.text, subText = entry.hint, id = entry.id })
  end
  return rows
end

--- Run the entry with `id` on `win`. Returns the action status, or "unchanged" for an unknown id.
function window_menu.run(id, win, manager, modal)
  for _, entry in ipairs(ENTRIES) do
    if entry.id == id then
      return entry.run(manager, win, modal)
    end
  end
  return "unchanged"
end

-- Kept at module level so the chooser is not garbage collected while open.
local open_chooser = nil

--- Open the chooser for `win`. After a pick, focus returns to `win` before the action runs.
function window_menu.show(win, manager, modal)
  open_chooser = hs.chooser.new(function(choice)
    if choice == nil then
      return
    end

    win:focus()
    hs.timer.doAfter(SHOW_DELAY_SECONDS, function()
      local succeeded = pcall(window_menu.run, choice.id, win, manager, modal)
      if not succeeded then
        hs.alert.show("Rakuen: window action failed")
      end
    end)
  end)

  open_chooser:choices(window_menu.choices())
  open_chooser:show()
end

return window_menu
