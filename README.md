# Budoux.lua

Budoux is the line break organizer tool originally developed by Google Inc and licensed under Apache 2.0 LICENSE.

This is a Lua implementation of Budoux.

## Requirements

- [lpeg](https://www.inf.puc-rio.br/~roberto/lpeg/) or [Neovim](https://github.com/neovim/neovim)

## Getting Started

```lua
local budoux = require("budoux")
local parser = budoux.load_japanese_model()
local segments = parser.parse('今日は天気です。')
for _, segment in ipairs(segments) do
  print(segment)
end
```

```
今日は
天気です。
```
