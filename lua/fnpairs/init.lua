local api = vim.api
local F = {}

-- Core FP utilities
F.curry = function(fn)
  local function curry_n(n, fn)
    if n <= 1 then
      return fn
    end
    return function(x)
      return curry_n(n - 1, function(...)
        return fn(x, ...)
      end)
    end
  end
  return curry_n(debug.getinfo(fn).nparams, fn)
end

F.compose = function(...)
  local fns = { ... }
  return function(...)
    local result = ...
    for i = #fns, 1, -1 do
      result = fns[i](result)
    end
    return result
  end
end

F.pipe = function(x, ...)
  local fns = { ... }
  local result = x
  for i = 1, #fns do
    result = fns[i](result)
  end
  return result
end

-- Maybe Monad
F.Maybe = {
  of = function(x)
    return { kind = 'Maybe', value = x }
  end,
  nothing = { kind = 'Maybe', value = nil },
  isNothing = function(maybe)
    return maybe.value == nil
  end,
  fromNullable = function(x)
    return x == nil and F.Maybe.nothing or F.Maybe.of(x)
  end,
  map = function(maybe, f)
    if F.Maybe.isNothing(maybe) then
      return F.Maybe.nothing
    end
    return F.Maybe.of(f(maybe.value))
  end,
  chain = function(maybe, f)
    if F.Maybe.isNothing(maybe) then
      return F.Maybe.nothing
    end
    return f(maybe.value)
  end,
  getOrElse = function(maybe, default)
    return maybe.value or default
  end,
}

-- Pure state management
local StateManager = {}
StateManager.get = function()
  return {
    get_line = function()
      return api.nvim_get_current_line()
    end,
    get_cursor = function()
      return api.nvim_win_get_cursor(0)
    end,
    get_mode = function()
      return api.nvim_get_mode().mode
    end,
  }
end

-- State ADT
local State = {}
State.new = function()
  local state = StateManager.get()
  return {
    line = state.get_line(),
    cursor = state.get_cursor(),
    mode = state.get_mode(),
  }
end

-- BracketPair ADT with configuration support
local BracketPair = {
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  ['"'] = '"',
  ["'"] = "'",
  ['`'] = '`',
}

BracketPair = vim.tbl_extend('keep', BracketPair, vim.g.fnpairs or {})

-- Action ADT with smart constructors
local Action = {
  Skip = { type = 'skip' },
  Insert = function(opening, closing)
    return { type = 'insert', opening = opening, closing = closing }
  end,
  Move = { type = 'move' },
  Delete = { type = 'delete' },
  Nothing = { type = 'nothing' },
}

-- Pure functions for character handling
local get_char_at = F.curry(function(pos, state)
  return F.Maybe.fromNullable(state.line:sub(pos(state), pos(state)))
end)

local get_char_before = get_char_at(function(state)
  return state.cursor[2]
end)

local get_char_after = get_char_at(function(state)
  return state.cursor[2] + 1
end)

-- Action determination functions
local should_skip_completion = function(char)
  local state = State.new()
  local prev_char = get_char_before(state).value
  if char == "'" and prev_char and string.match(prev_char, '[%w]') then
    return Action.Insert(char, BracketPair[char])
  end
  return Action.Insert(char, BracketPair[char])
end

local determine_char_action = function(char)
  return F.compose(should_skip_completion, function(action)
    return action or Action.Insert(char, BracketPair[char])
  end)
end

local determine_action = F.curry(function(char, state)
  if state.mode == 'v' or state.mode == 'V' then
    return Action.Insert(char, BracketPair[char])
  end

  local function check_bracket_balance(str, opening_char)
    local stack = {}
    for i = 1, #str do
      local c = str:sub(i, i)
      if BracketPair[c] then
        table.insert(stack, c)
      elseif c == BracketPair[opening_char] then
        if #stack == 0 or stack[#stack] ~= opening_char then
          return false
        end
        table.remove(stack)
      end
    end
    return true
  end

  local next_char = get_char_after(state)
  if not F.Maybe.isNothing(next_char) and next_char.value == BracketPair[char] then
    local substr = state.line:sub(state.cursor[2] + 1, state.cursor[2] + 1)
    if check_bracket_balance(substr, char) then
      return Action.Skip
    end
  end

  return determine_char_action(char)(char)
end)

-- Action handlers
local handle_skip = function()
  return '<Right>'
end

local handle_insert = function(action)
  return action.opening .. action.closing .. '<Left>'
end

local handle_delete = function()
  local state = State.new()
  return F.pipe(state, function(s)
    return {
      before = get_char_before(s).value,
      after = get_char_after(s).value,
    }
  end, function(chars)
    return BracketPair[chars.before] == chars.after and '<BS><Del>' or '<BS>'
  end)
end

local handle_action = function(action)
  local handlers = {
    skip = handle_skip,
    insert = handle_insert,
    delete = handle_delete,
    nothing = function()
      return ''
    end,
  }
  return handlers[action.type](action)
end

return {
  setup = function()
    -- Setup bracket pairs
    for opening, _ in pairs(BracketPair) do
      vim.keymap.set('i', opening, function()
        return F.pipe(State.new(), determine_action(opening), handle_action)
      end, { expr = true })
    end

    -- Setup backspace handling
    vim.keymap.set('i', '<BS>', function()
      return handle_action(Action.Delete)
    end, { expr = true })
  end,
}
