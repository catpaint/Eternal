local LoadStart = tick()

getgenv().it = true
getgenv().mstudio45 = getgenv().mstudio45 or {}
getgenv().mstudio45.Legit = false
getgenv().mstudio45.Paid = true

if not mstudio45.Environment then
    local gethuiFunc = gethui or function() return Services and Services.CoreGui or game:GetService("CoreGui") end
    mstudio45.Environment = setmetatable({
        cloneref = function(obj) return obj end,
        gethui = gethuiFunc,
        GenerateRandomString = function(len)
            local str = ""
            for i = 1, (len or 10) do str = str .. string.char(math.random(97, 122)) end
            return str
        end
    }, {
        __index = function(_, k)
            if getgenv()[k] then return getgenv()[k] end
            return nil
        end
    })
end

if not mstudio45.Interface or type(mstudio45.Interface) ~= "table" or not mstudio45.Interface.Library then
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
    local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    mstudio45.Interface = { Library = Library, SaveManager = SaveManager, ThemeManager = ThemeManager }
end

mstudio45.SavePath = "Doors/Lobby"

local Library = mstudio45.Interface.Library
local SaveManager = mstudio45.Interface.SaveManager
local ThemeManager = mstudio45.Interface.ThemeManager

local Toggles = Library.Toggles
local Options = Library.Options

local function CloneReference(Object)
    if mstudio45 and mstudio45.Environment and mstudio45.Environment.cloneref then
        return mstudio45.Environment.cloneref(Object)
    else
        return Object
    end
end

local Services = setmetatable({}, {
    __index = function(self, Name)
        return CloneReference(game:GetService(Name))
    end
})

local Globals = {}
local Con = {}
local Functions = {}

local LocalPlayer = Services.Players.LocalPlayer
local RemotesFolder = Services.ReplicatedStorage:WaitForChild("RemotesFolder")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Window = Library:CreateWindow({
    Title = "mstudio45 V4",
    Footer = "Game: DOORS LOBBY | dsc.gg/mstudio45",
    Icon = 77196040991392,
    NotifySide = "Right",
    ShowCustomCursor = false,
    AutoShow = true,
    Center = true,
	TabPadding = 3,
	MenuFadeTime = 0,
    CornerRadius = 2,
})

if mstudio45.Interface and type(mstudio45.Interface.ApplyInfoTab) == "function" then
    pcall(function() mstudio45.Interface.ApplyInfoTab(Window) end)
end

local Tabs = {
    General  = Window:AddTab("General", "house"),
    Settings = Window:AddTab("Settings", "settings"),
}

Functions.CheckCompatability = function(Array)
    local Valid = true
    for Index, Name in pairs(Array) do
        if not mstudio45.Environment[Name] then
            Valid = false
        end
    end
    return Valid
end

local function GetHiddenContainer()
	if Functions.CheckCompatability({"gethui"}) then
		return mstudio45.Environment.gethui()
	else
		return Services.CoreGui
	end
end

local Container = Instance.new("ScreenGui")
Container.Name = (mstudio45.ESPLibrary and type(mstudio45.ESPLibrary.GenerateRandomString) == "function" and mstudio45.ESPLibrary:GenerateRandomString()) or "mstudio45_Lobby_UI"
Container.Parent = GetHiddenContainer()
Container.DisplayOrder = 32767
Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local General_CreateElevator = Tabs.General:AddLeftGroupbox("Create Elevator")
General_CreateElevator:AddSlider("AmountOfPlayers", { Text = "Amount Of Players", Min = 1, Max = 12, Default = 1, Rounding = 0 })

General_CreateElevator:AddButton({
	Text = "Super Hard Mode",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {
            "PlayerHealthLess",
            "PlayerLeastSlots",
            "RoomsA90",
            "EntitiesMost",
            "DupeMost",
            "BackdoorVacuum",
            "BackdoorLookman",
            "NoKeySound",
            "Dread",
            "GoldSpawnNone",
            "FigureFaster",
            "RushQuiet",
            "RushMore",
            "FiredampMost"
			},
        	Settings = {},
        	Destination = "Hotel",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

Library:OnUnload(function()
    if Con.MainConnection then Con.MainConnection:Disconnect() end
	getgenv().mstudio45 = nil
end)

if Options.MenuKeybind then
	Options.MenuKeybind:OnClick(function()
		Library:Toggle()
	end)
end

Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.RightShift then
		Library:Toggle()
	end
end)

if mstudio45.Interface and type(mstudio45.Interface.ApplySettingsTab) == "function" then
    pcall(function() mstudio45.Interface.ApplySettingsTab(Window) end)
end

Functions.Notify({ Title = "Successfully loaded", Body = "Press RightControl to Close/Open the menu"})
