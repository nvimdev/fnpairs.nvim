# fnpairs.nvim

A simple pairs plugin written in FP style using Lua.

```lua
-- BracketPair ADT
local BracketPair = {
  match = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
  },
}
```

## License MIT
