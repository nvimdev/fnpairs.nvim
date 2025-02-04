# fnpairs.nvim

A simple pairs plugin written in FP style using Lua.

# Install

install with any plugin manager or built-in package.

no setup function is used, fnpairs will work after loaded.
below are default pairs list.

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
