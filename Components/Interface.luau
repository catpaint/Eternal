local Library = (mstudio45.UILibrary == "Linoria" and "LinoriaLib" or "Obsidian")
-- local BaseUrl = "https://raw.githubusercontent.com/mstudio45/" .. Library .. "/refs/heads/main/"
local BaseUrl = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local mstudio45Url = "https://raw.githubusercontent.com/mstudio45/mstudio45.xyz/refs/heads/main/"

local Interface = {
  Library = loadstring(game:HttpGet(BaseUrl .. "Library.lua"))(),
  SaveManager = loadstring(game:HttpGet(BaseUrl .. "addons/SaveManager.lua"))(),
  ThemeManager = loadstring(game:HttpGet(BaseUrl .. "addons/ThemeManager.lua"))(),

  ApplyInfoTab = loadstring(game:HttpGet(mstudio45Url .. "Components/InfoTab.luau"))(),
  ApplySettingsTab = loadstring(game:HttpGet(mstudio45Url .. "Components/SettingsTab.luau"))()
}

Interface.ThemeManager.BuiltInThemes = {
	["Default"]   = { 1,  { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "0078ff", BackgroundColor = "1a1a1a", OutlineColor = "1a1b1d" } },
	["Fatality"]  = { 2,  { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
	["Jester"]    = { 3,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
	["Mint"]      = { 4,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
	["Quartz"]    = { 5,  { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
	["Nord"]      = { 6,  { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" } },
	["Dracula"]   = { 7,  { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" } },
	["Monokai"]   = { 8,  { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e" } },
	["Gruvbox"]   = { 9,  { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945" } },
	["SirMeme"]   = { 10, { FontColor = "ffffff", MainColor = "140d17", AccentColor = "00ff21", BackgroundColor = "000000", OutlineColor = "1a1b1d" } },
	["Anoled"]    = { 11, { FontColor = "ffffff", MainColor = "000000", AccentColor = "ff3131", BackgroundColor = "000000", OutlineColor = "000000" } },
	["Cyber"]     = { 12, { FontColor = "e6f1ff", MainColor = "10151f", AccentColor = "00e5ff", BackgroundColor = "0a0d14", OutlineColor = "1e2735" } },
	["Synthwave"] = { 13, { FontColor = "f0e6ff", MainColor = "2b1a4d", AccentColor = "ff6ec7", BackgroundColor = "1a0f2e", OutlineColor = "4d3d8f" } },
	["Cipher"] = { 14, { FontColor = "d0ffd0", MainColor = "0b120b", AccentColor = "00ff66", BackgroundColor = "050805", OutlineColor = "1c2e1c" } },
}
return Interface
