# fnpairs.nvim

A simple pairs plugin written in FP style using Lua.

# Install

install with any plugin manager or built-in package.

no setup function is used, fnpairs will work after loaded.

using `vim.g.fnpairs` add new pairs list. below is default
paris list.

```lua
{
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
}
```

## License MIT
