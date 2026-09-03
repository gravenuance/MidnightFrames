-- luacheck config for MidnightFrames (a World of Warcraft addon).
--
-- The WoW API is huge and reached here almost entirely through the pcall
-- wrappers in Modules/SecureUtil.lua, so cataloguing every global would be
-- more upkeep than signal. Global reads and writes are allowed to pass
-- (codes 111-113, 143); every other check stays strict. luacheck still
-- catches syntax errors, unused and shadowed locals, unreachable code, and
-- redefinitions - the payoff for running it without a game client.

std = "lua51"
max_line_length = false
codes = true

-- WoW widget script handlers (OnEvent, OnUpdate, OnDragStart, ...) have
-- fixed positional signatures; not every callback uses every argument.
unused_args = false

exclude_files = {
  ".luacheckrc",
}

ignore = {
  "111", -- setting an undefined global (addon namespace, SLASH_* handlers)
  "112", -- mutating an undefined global
  "113", -- accessing an undefined global (WoW API surface)
  "143", -- accessing an undefined field of a global
}
