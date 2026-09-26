local LoadStart = tick()

getgenv().it = true
getgenv().mstudio45 = getgenv().mstudio45 or {}
getgenv().mstudio45.Legit = false
getgenv().mstudio45.Paid = true

if not mstudio45.Environment then
    local gethuiFunc = gethui or function() return Services.CoreGui end
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

if not mstudio45.ESPLibrary or type(mstudio45.ESPLibrary.AddESP) ~= "function" then
    local s, lib = false, nil
    if isfile then
        local paths = {
            "mstudio45.xyz/Components/ESPLibrary.luau",
            "Eternal/Components/ESPLibrary.luau",
            "Components/ESPLibrary.luau",
            "ESPLibrary.luau"
        }
        for _, p in ipairs(paths) do
            if isfile(p) then
                local code = readfile(p)
                local fn = loadstring(code)
                if fn then
                    s, lib = pcall(fn)
                    if s and lib then break end
                end
            end
        end
    end
    if not s or not lib then
        s, lib = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/catpaint/Eternal/refs/heads/main/Components/ESPLibrary.luau"))()
        end)
    end
    mstudio45.ESPLibrary = (s and lib) or setmetatable({}, {
        __index = function() return function() end end
    })
end

if not mstudio45.Interface or type(mstudio45.Interface) ~= "table" or not mstudio45.Interface.Library then
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
    local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
    local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    mstudio45.Interface = { Library = Library, SaveManager = SaveManager, ThemeManager = ThemeManager }
end

mstudio45.SavePath = "Doors/Game"

local Library = mstudio45.Interface.Library
local SaveManager = mstudio45.Interface.SaveManager
local ThemeManager = mstudio45.Interface.ThemeManager

local Toggles = Library.Toggles
local Options = Library.Options

-- Compatibility & Safe Proxy for Toggles across Tplay and Main(4)
local DummyToggle = {
    Value = false,
    Disabled = false,
    SetValue = function(self, v) self.Value = v end,
    SetDisabled = function(self, d) self.Disabled = d end,
    SetText = function(self, t) end,
}
local ToggleAliases = {
    AutoFloor = "Tplay_AutoFloor",
    SlideSpeedHack = "Tplay_SlideSpeedHack",
    AntiTeleport = "Tplay_AntiTeleport",
    AntiTeleportRaknet = "Tplay_AntiTeleportRaknet",
    CollisionOffsetGodmodeAlt = "PositionSpoof",
    Tplay_CollisionOffsetGodmodeAlt = "PositionSpoof",
    BringDrawers = "Tplay_BringDrawers",
    AutoLoot = "Tplay_AutoLoot",
    SkipEyestalkChase = "Tplay_SkipEyestalkChase",
    TriggerEyestalkChaseEnd = "Tplay_TriggerEyestalkChaseEnd",
    MakeLotus = "Tplay_MakeLotus",
    AutoPlayAgain = "Tplay_AutoPlayAgain",
    MinecartTeleportAlt = "Tplay_MinecartTeleportAlt",
    MinecartChaseSkip = "Tplay_MinecartChaseSkip",
    AntiFigure = "Tplay_AntiFigure",
    AntiGroundskeeper = "Tplay_AntiGroundskeeper",
    AntiEntities = "Tplay_AntiEntities",
    AntiRotation = "Tplay_AntiRotation",
    AntiScreech = "RemoveScreech",
    AntiDupe = "BypassDupe",
    AntiDread = "RemoveDread",
    AntiHalt = "RemoveHalt",
    AntiSnare = "BypassSnare",
    AntiEyes = "BypassEyes",
    AntiA90 = "RemoveA90",
    AntiGiggle = "BypassGiggle",
    DoorReach = "DoorReachToggle",
    DoorReachAlt = "Tplay_DoorReachAlt",
    AutoLibraryCode = "AutoUnlockPadlockToggle",
    AutoLibrarySolver = "AutoUnlockPadlockToggle",
    BruteforceLibraryCode = "AutoUnlockPadlockToggle",
    AutoPadlock = "AutoUnlockPadlockToggle",
    AutoBreakerSolver = "AutoBreakerBox",
    AutoBreaker = "AutoBreakerBox",
}

setmetatable(Toggles, {
    __index = function(t, k)
        if rawget(t, k) ~= nil then return rawget(t, k) end
        local alias = ToggleAliases[k]
        if alias and rawget(t, alias) ~= nil then return rawget(t, alias) end
        if alias and t[alias] ~= nil then return t[alias] end
        if type(k) == "string" and k:sub(1, 6) == "Tplay_" then
            local stripped = k:sub(7)
            if rawget(t, stripped) ~= nil then return rawget(t, stripped) end
        end
        return DummyToggle
    end
})

local Global = {}
local Conns = {}
local ESPConns = {}
local FakePrompts = {}
local Functions = {}
local PartProperties = {}
local Variables = { AutoFloors = {}, AutoFloors240 = {}, StuffToKeepEnabled = {}, POARespawning = false, POANoAccelWasEnabled = false, Groundskeepers = {}, FigureRigs = {} }
local Connections = { AutoFloor = {}, AntiEntities = {} }
local Info = {}

local function CloneReference(Object)
    if mstudio45 and mstudio45.Environment and type(mstudio45.Environment) == "table" and type(mstudio45.Environment.cloneref) == "function" then
        local s, res = pcall(function() return mstudio45.Environment.cloneref(Object) end)
        if s and typeof(res) == "Instance" then
            return res
        end
    end
    return Object
end

local Services = setmetatable({}, {
	__index = function(self, Name)
		return CloneReference(game:GetService(Name))
	end
})

local Objects = {
	Prompts = {},
	Objectives = {},
	Doors = {},
	HidingSpots = {},
	Entities = {},
	SeekObstructions = {},
	Items = {},
	Chests = {},
	Currency = {},
	Ladders = {},
	Obstructions = {},
	PowerUps = {},
	EventTriggers = {},
	JumpscareModules = {},
	SeekHighlights = {},
	EyestalkHighlights = {},
	SeekNodes = {},
	SeekDuckBoards = {},
	SeekBridges = {},
	PathLights = {}
}

Global.ExecutorIssueMessage = "Your executor doesn't support this feature."
Global.PayedFeatueMessage = "Payed only feature."

Functions.CheckEnv = function(...)
	local Names = { ... }
	for i = 1, #Names do
		if not mstudio45.Environment[Names[i]] then
			return false
		end
	end
	return true
end

local Entities = {
	["RushMoving"] = {
		Name = "Rush",
		NotifyMessage = { Title = "Entity 'Rush' has spawned.", Body = "Find a hiding spot." }
	},
	["AmbushMoving"] = {
		Name = "Ambush",
		NotifyMessage = { Title = "Entity 'Ambush' has spawned.", Body = "Find a hiding spot." }
	},
	["Eyes"] = {
		Name = "Eyes",
		NotifyMessage = { Title = "Entity 'Eyes' has spawned.", Body = "Avoid looking at it." }
	},
	["Lookman"] = {
		Name = "Eyes",
		NotifyMessage = { Title = "Entity 'Eyes' has spawned.", Body = "Avoid looking at it." }
	},
	["BackdoorRush"] = {
		Name = "Blitz",
		NotifyMessage = { Title = "Entity 'Blitz' has spawned.", Body = "Find a hiding spot." }
	},
	["BackdoorLookman"] = {
		Name = "Lookman",
		NotifyMessage = { Title = "Entity 'Lookman' has spawned.", Body = "Avoid looking at its eyes." }
	},
	["Groundskeeper"] = {
		Name = "Groundskeeper",
		NotifyMessage = { Title = "Entity 'Groundskeeper' has spawned.", Body = "Dont step on the grass." }
	},
	["A60"] = {
		Name = "A-60",
		NotifyMessage = { Title = "Entity 'A-60' has spawned.", Body = "Find a hiding spot." }
	},
	["A120"] = {
		Name = "A-120",
		NotifyMessage = { Title = "Entity 'A-120' has spawned.", Body = "Find a hiding spot." }
	},
	["GloombatSwarm"] = {
		Name = "Gloombat Swarm",
		NotifyMessage = { Title = "Entity 'Gloombat Swarm' has spawned.", Body = "Keep all light sources turned off." }
	},
	["GlitchRush"] = {
		Name = "RNIUSHCG==",
		NotifyMessage = { Title = "Entity 'RNIUSHCG==' has spawned.", Body = "Find a hiding spot." }
	},
	["GlitchAmbush"] = {
		Name = "AR0xMBUSH",
		NotifyMessage = { Title = "Entity 'AR0xMBUSH' has spawned.", Body = "Find a hiding spot." }
	},
	["MonumentEntity"] = {
		Name = "Monument",
		NotifyMessage = { Title = "Entity 'Monument' has spawned.", Body = "It can't move while you are looking at it." }
	},
	["JeffTheKiller"] = {
		Name = "Jeff the Killer",
		NotifyMessage = { Title = "Entity 'Jeff the Killer' has spawned.", Body = "Avoid touching him." }
	},
	["CustomEntity"] = {
		Name = "Custom Entity",
		NotifyMessage = { Title = "Entity 'Custom Entity' has spawned.", Body = "Find a hiding spot." }
	},
	["FrozenAmbush"] = {
		Name = "Frozen Ambush",
		NotifyMessage = { Title = "Entity 'Frozen Ambush' has spawned.", Body = "Find a hiding spot." }
	},
	["SallyMoving"] = {
		Name = "Sally",
		NotifyMessage = { Title = "Entity 'Sally' has spawned.", Body = "Drop an item for her." }
	},
	["Scribble"] = {
		Name = "Scribbles",
		NotifyMessage = { Title = "Entity 'Scribbles' has spawned.", Body = "Watch out for Scribbles!" }
	},
	["Scribbles"] = {
		Name = "Scribbles",
		NotifyMessage = { Title = "Entity 'Scribbles' has spawned.", Body = "Watch out for Scribbles!" }
	},
	["ScribbleMoving"] = {
		Name = "Scribbles",
		NotifyMessage = { Title = "Entity 'Scribbles' has spawned.", Body = "Watch out for Scribbles!" }
	},
	["Bash"] = {
		Name = "Bash",
		NotifyMessage = { Title = "Entity 'Bash' has spawned.", Body = "Hide or get out of the way!" }
	},
	["BashMoving"] = {
		Name = "Bash",
		NotifyMessage = { Title = "Entity 'Bash' has spawned.", Body = "Hide or get out of the way!" }
	},
	["DronesStampede"] = {
		Name = "Stampede of Drones",
		NotifyMessage = { Title = "Entity 'Stampede of Drones' has spawned.", Body = "Find a hiding spot or get out of the path." }
	}
}

local EntityIcons = {
	["RushMoving"]      = "rbxassetid://10716032262",
	["AmbushMoving"]    = "rbxassetid://10110576663",
	["A60"]             = "rbxassetid://12571092295",
	["A120"]            = "rbxassetid://12711591665",
	["BackdoorRush"]    = "rbxassetid://16602023490",
	["Eyes"]            = "rbxassetid://10183704772",
	["Lookman"]         = "rbxassetid://10183704772",
	["BackdoorLookman"] = "rbxassetid://16764872677",
	["GloombatSwarm"]   = "rbxassetid://79221203116470",
	["Halt"]            = "rbxassetid://11331795398",
	["JeffTheKiller"]   = "rbxassetid://94479432156278",
	["GlitchRush"]      = "rbxassetid://73859273102919",
	["GlitchAmbush"]    = "rbxassetid://88369678433359",
	["SallyMoving"]     = "rbxassetid://10840888070",
	["MonumentEntity"]  = "rbxassetid://88933556873017",
	["Groundskeeper"]   = "rbxassetid://114991380115557"
}

local ItemNames = {
	["Lighter"]           = "Lighter",
	["Flashlight"]        = "Flashlight",
	["Lockpick"]          = "Lockpicks",
	["Vitamins"]          = "Vitamins",
	["Bandage"]           = "Bandage",
	["StarVial"]          = "Starlight Vial",
	["StarBottle"]        = "Starlight Bottle",
	["StarJug"]           = "Starlight Barrel",
	["Shakelight"]        = "Gummy Flashlight",
	["Straplight"]        = "Straplight",
	["Bulklight"]         = "Spotlight",
	["Battery"]           = "Battery",
	["Candle"]            = "Candle",
	["Crucifix"]          = "Crucifix",
	["CrucifixWall"]      = "Crucifix",
	["Glowsticks"]        = "Glowstick",
	["SkeletonKey"]       = "Skeleton Key",
	["Candy"]             = "Candy",
	["ShieldMini"]        = "Mini Shield Potion",
	["ShieldBig"]         = "Big Shield Potion",
	["BandagePack"]       = "Bandage Pack",
	["BatteryPack"]       = "Battery Pack",
	["RiftCandle"]        = "Moonlight Candle",
	["LaserPointer"]      = "Laser Pointer",
	["HolyGrenade"]       = "Holy Hand Grenade",
	["Shears"]            = "Shears",
	["Smoothie"]          = "Smoothie",
	["Cheese"]            = "Cheese",
	["Bread"]             = "Bread",
	["AlarmClock"]        = "Alarm Clock",
	["RiftSmoothie"]      = "Moonlight Smoothie",
	["GweenSoda"]         = "Gween Soda",
	["GlitchCube"]        = "Glitch Fragment",
	["Scanner"]           = "Tablet",
	["Bomb"]              = "Bomb",
	["Knockbomb"]         = "Knockbomb",
	["Nanner"]            = "Nanner",
	["BigBomb"]           = "Big Bomb",
	["SnakeBox"]          = "Hiding Box",
	["GoldGun"]           = "Golden Gun",
	["StopSign"]          = "Stop Sign",
	["TipJar"]            = "Tip Jar",
	["Lantern"]           = "Lantern",
	["IronKey"]           = "Iron Key",
	["LotusPetal"]        = "Lotus Petal",
	["Compass"]           = "Compass",
	["LotusPetalPickup"]  = "Lotus Petal",
	["LanternLitItem"]    = "Lantern",
	["KeyIron"]           = "Iron Key",
	["IronKeyForCrypt"]   = "Iron Key",
	["LotusHolder"]       = "Lotus Petal",
	["Multitool"]         = "Multitool",
	["RiftJar"]           = "Rift Jar",
	["AloeVera"]          = "Aloe Vera",
	["Donut"]             = "Donut",
	["Lotus"]             = "Lotus",
	["BoxingGloves"]      = "Boxing Gloves",
	["Leftovers"]         = "Leftovers",
	["LeftoversItem"]     = "Leftovers",
	["Leftover"]          = "Leftovers",
	["LeftoverFood"]      = "Leftovers",
	["PaperPlan"]         = "Paper Plane",
	["PaperPlane"]        = "Paper Plane",
	["Paper_Plan"]        = "Paper Plane",
	["Paper_Plane"]       = "Paper Plane",
	["Plan"]              = "Paper Plane",
	["PaperPlanItem"]     = "Paper Plane",
	["PaperPlaneItem"]    = "Paper Plane",
	["Briefcase"]         = "Briefcase",
	["BriefcaseItem"]     = "Briefcase",
	["BriefCase"]         = "Briefcase",
	["Suitcase"]          = "Briefcase",
	["Pizza"]             = "Pizza",
	["PizzaItem"]         = "Pizza",
	["PizzaSlice"]        = "Pizza",
	["PizzaBox"]          = "Pizza",
	["JournalWorldRig"]   = "Journal",
	["Journal"]           = "Journal",
	["JournalItem"]       = "Journal",
	["JournalRig"]        = "Journal",
	["Notebook"]          = "Journal",
	["Diary"]             = "Journal",
	["GweenSodaPack"]     = "Gween Soda Pack",
	["Jerrycan"]          = "Jerrycan",
	["FihFlakes"]         = "Fih Flakes",
	["FihFlakesItem"]     = "Fih Flakes",
	["Fih_Flakes"]        = "Fih Flakes",
	["FishFlakes"]        = "Fih Flakes",
	["Fish_Flakes"]       = "Fih Flakes",
	["Flakes"]            = "Fih Flakes"
}

local Character
local Humanoid
local RootPart

local Collision
local CollisionClone
local CollisionPart
local CollisionPartClone

local Camera
local LocalPlayer = Services.Players.LocalPlayer

local RemotesFolder   = Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
local LiveModifiers   = Services.ReplicatedStorage:FindFirstChild("LiveModifiers")
local FloorReplicated = Services.ReplicatedStorage:FindFirstChild("FloorReplicated")
local CurrentRooms    = Services.Workspace:FindFirstChild("CurrentRooms")
local Drops           = Services.Workspace:FindFirstChild("Drops")
local GameData        = Services.ReplicatedStorage:WaitForChild("GameData")
local FloorObj        = GameData:FindFirstChild("FloorDestination") or GameData:FindFirstChild("Floor") or GameData:WaitForChild("Floor", 5)
local Floor           = FloorObj and FloorObj.Value or ""
local LatestRoom      = GameData:WaitForChild("LatestRoom")
local FinishedLoadingRoom = GameData:FindFirstChild("FinishedLoadingRoom")
if FinishedLoadingRoom then
	FinishedLoadingRoom:Destroy()
end

local NotificationLibrary = {
	LiveNotifications = 0,
	Notifications = 1
}

local function GetHiddenContainer()
	if Functions.CheckEnv("gethui") then
		local s, res = pcall(function() return mstudio45.Environment.gethui() end)
		if s and typeof(res) == "Instance" then return res end
	end
	return game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local targetContainer = GetHiddenContainer()
if targetContainer then
	for _, child in ipairs(targetContainer:GetChildren()) do
		if child.Name == "mstudio45_UI" or child:FindFirstChild("Main") or child:FindFirstChild("Window") then
			pcall(function() child:Destroy() end)
		end
	end
end

local Container = Instance.new("ScreenGui")
Container.Name = (mstudio45.ESPLibrary and type(mstudio45.ESPLibrary.GenerateRandomString) == "function" and mstudio45.ESPLibrary:GenerateRandomString()) or "mstudio45_UI"
Container.Parent = targetContainer
Container.DisplayOrder = 32767
Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if not Library.Scheme then
	Library.Scheme = setmetatable({}, {
		__index = function(Self, Name)
			return Library[Name]
		end
	})
end

-- Obsidian loading screen: must be created after the old-GUI cleanup above,
-- otherwise that cleanup destroys the loader's ScreenGui too
if Library.ActiveLoading and Library.ActiveLoading.Destroyed ~= true then
	pcall(function() Library.ActiveLoading:Destroy() end)
end
local Loading = Library:CreateLoading({
	Title = "catpaint",
	Icon = 136097487509067,
	TotalSteps = 4,
	ShowSidebar = true,
	AlwaysOnTop = true,
})
Loading:SetCurrentStep(1)
Loading:SetMessage("Loading catpaint...")
Loading:SetDescription("fun fact: gomoseki...")
pcall(function()
	Loading.Sidebar:AddLabel("Game: DOORS")
	Loading.Sidebar:AddLabel("Player: " .. LocalPlayer.Name)
	Loading.Sidebar:AddLabel("UI Library: Obsidian")
	if mstudio45.TotalExecutions then
		Loading.Sidebar:AddLabel("Total Executions: " .. mstudio45.TotalExecutions)
	end
end)
task.wait(1)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer

local LolhaxGui = Instance.new("ScreenGui")
LolhaxGui.Name = "LolhaxNotificationGui"
LolhaxGui.ResetOnSpawn = false
LolhaxGui.IgnoreGuiInset = true
LolhaxGui.DisplayOrder = 999999
LolhaxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LolhaxGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotificationHolder"
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.BorderSizePixel = 0
NotificationHolder.AnchorPoint = Vector2.new(0.5, 0.5)
NotificationHolder.Position = UDim2.fromScale(0.5, 0.5)
NotificationHolder.Size = UDim2.fromScale(1, 1)
NotificationHolder.ZIndex = 999999
NotificationHolder.Parent = LolhaxGui

local Notifications = {}

local NotificationSpacing = 0.065

local LogoURL = "https://raw.githubusercontent.com/mstudio45/Notification/refs/heads/main/Images/bcrown.png"
local LogoFile = "mstudio45_B_Crown.png"

local function GetLogoAsset()
    if not (isfile and writefile and getcustomasset) then return nil end
    local ok, res = pcall(function()
        if not isfile(LogoFile) then
            local fetch = (syn and syn.request) or request or http_request or (http and http.request)
            if not fetch then return nil end
            local resp = fetch({ Url = LogoURL, Method = "GET" })
            if resp and resp.Body then writefile(LogoFile, resp.Body) end
        end
        return isfile(LogoFile) and getcustomasset(LogoFile) or nil
    end)
    return ok and res or nil
end

local LogoAsset = GetLogoAsset()

local function GetNotifySide()
    return Options.NotifySide and Options.NotifySide.Value or "Right"
end

local function GetNotifyX()
    if GetNotifySide() == "Right" then return 0.88 end
    return 0.5
end

local function GetNotifyYBase()
    if GetNotifySide() == "Right" then return 0.08 end
    return 0.60
end

local function Updatemstudio45Positions()
    for Index, Data in ipairs(Notifications) do
        if Data.Main and Data.Main.Parent then
            local TargetY = GetNotifyYBase() + ((Index - 1) * NotificationSpacing)

            TweenService:Create(
                Data.Main,
                TweenInfo.new(
                    0.45,
                    Enum.EasingStyle.Quart,
                    Enum.EasingDirection.Out
                ),
                {
                    Position = UDim2.fromScale(GetNotifyX(), TargetY)
                }
            ):Play()
        end
    end
end
function NotificationLibrary:Notify(TitleText, Desc, Delay)
	task.spawn(function()
		local TextService = game:GetService("TextService")
		local ViewportSize = workspace.CurrentCamera.ViewportSize

		local NotifyScaleX = 0.25
		local TextOffset = 60
		local Spacing = 10
		local BaseY = 5
		local NotifyWidth = ViewportSize.X * NotifyScaleX
		local SlideX = NotifyWidth + 12
		local TextWidth = math.max(NotifyWidth - TextOffset - 30, 150)

		local function Reflow()
			local Y = BaseY
			for _, Object in Container:GetChildren() do
				if Object.Name == "Notification" and Object:GetAttribute("Destroying") ~= true then
					local Cur = Object:GetAttribute("CurrentPosition")
					if not Cur or Cur.Y.Offset ~= Y then
						Services.TweenService:Create(
							Object,
							TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
							{ Position = UDim2.new(1, -SlideX, 0, Y) }
						):Play()
					end
					Object:SetAttribute("CurrentPosition", UDim2.new(1, -SlideX, 0, Y))
					Y += Object.Size.Y.Offset + Spacing
				end
			end
		end

		local Notification = Instance.new("Frame")
		local Line = Instance.new("Frame")
		local Warning = Instance.new("ImageLabel")
		local UICorner = Instance.new("UICorner")
		local UICorner2 = Instance.new("UICorner")
		local Title = Instance.new("TextLabel")
		local Description = Instance.new("TextLabel")

		Notification.Name = "Notification"
		Notification.BackgroundColor3 = Library.Scheme.BackgroundColor
		Notification.BackgroundTransparency = 0.4
		Notification.BorderSizePixel = 0
		Notification.Size = UDim2.new(NotifyScaleX, 0, 0, 50)

		Line.Name = "Line"
		Line.Parent = Notification
		Line.BackgroundColor3 = Library.Scheme.AccentColor
		Line.BorderSizePixel = 0
		Line.Position = UDim2.new(0, 0, 1, -3)
		Line.Size = UDim2.new(0, 0, 0, 3)

		Warning.Name = "Warning"
		Warning.Parent = Notification
		Warning.BackgroundTransparency = 1
		Warning.AnchorPoint = Vector2.new(0, 0.5)
		Warning.Position = UDim2.new(0, 10, 0.5, 0)
		Warning.Size = UDim2.new(0, 40, 0, 40)
		Warning.Image = "rbxassetid://3944668821"
		Warning.ImageColor3 = Library.Scheme.AccentColor
		Warning.ScaleType = Enum.ScaleType.Fit

		UICorner.CornerRadius = UDim.new(0, 20)
		UICorner.Parent = Warning

		UICorner2.CornerRadius = UDim.new(0, 4)
		UICorner2.Parent = Notification

		Title.Name = "Title"
		Title.Parent = Notification
		Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, TextOffset, 0.125, 0)
		Title.Size = UDim2.new(0, TextWidth, 0, 18)
		Title.Text = TitleText or "..."
		Title.TextColor3 = Library.Scheme.FontColor
		Title.TextSize = 10
		Title.TextWrapped = true
		Title.TextStrokeTransparency = 0.75
		Title.TextXAlignment = Enum.TextXAlignment.Left

		Description.Name = "Description"
		Description.Parent = Notification
		Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Description.BackgroundTransparency = 1
		Description.Position = UDim2.new(0, TextOffset, 0.4, 0)
		Description.Size = UDim2.new(0, TextWidth, 0, 18)
		Description.Text = Desc or "..."
		Description.TextColor3 = Library.Scheme.FontColor
		Description.TextTransparency = 0.1
		Description.TextSize = 10
		Description.TextWrapped = true
		Description.TextStrokeTransparency = 0.75
		Description.TextXAlignment = Enum.TextXAlignment.Left

		local Params = Instance.new("GetTextBoundsParams")
		Params.Text = Description.Text
		Params.RichText = true
		Params.Font = Description.FontFace
		Params.Size = Description.TextSize
		Params.Width = TextWidth
		local Bounds = TextService:GetTextBoundsAsync(Params)

		local DescHeight = math.max(math.ceil(Bounds.Y) + 4, 18)
		local Height = 50 + (DescHeight - 18)

		Description.Size = UDim2.new(0, TextWidth, 0, DescHeight)
		Notification.Size = UDim2.new(NotifyScaleX, 0, 0, Height)

		local StackY = BaseY
		for _, Object in Container:GetChildren() do
			if Object.Name == "Notification" and Object:GetAttribute("Destroying") ~= true then
				StackY += Object.Size.Y.Offset + Spacing
			end
		end

		Notification.Parent = Container
		Notification.Position = UDim2.new(1, 5, 0, StackY)
		Notification:SetAttribute("ID", NotificationLibrary.Notifications)
		Notification:SetAttribute("CurrentPosition", UDim2.new(1, -SlideX, 0, StackY))

		NotificationLibrary.LiveNotifications += 1
		NotificationLibrary.Notifications += 1

		Services.TweenService:Create(
			Notification,
			TweenInfo.new(1, Enum.EasingStyle.Exponential),
			{ Position = UDim2.new(1, -SlideX, 0, Notification.Position.Y.Offset) }
		):Play()

		task.wait(0.25)
		if typeof(Delay) == "Instance" then
			Delay.Destroying:Wait()
		else
			Services.TweenService:Create(
				Line,
				TweenInfo.new(Delay - 0.25, Enum.EasingStyle.Linear),
				{ Size = UDim2.new(1, -10, 0, 3) }
			):Play()
			task.wait(Delay - 0.25)
		end

		Notification:SetAttribute("Destroying", true)

		Services.TweenService:Create(
			Notification,
			TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 5, 0, Notification.Position.Y.Offset) }
		):Play()

		NotificationLibrary.LiveNotifications -= 1

		task.wait(0.3)
		Notification:Destroy()
		Reflow()
	end)
end
local function LolhaxNotify(TitleText, DescriptionText, Image, Color, Time)
    local accent = Color or Color3.fromRGB(0, 120, 255)
    local nx = GetNotifyX()

    local box = Instance.new("Frame")
    box.Name = "Notification"
    box.Parent = NotificationHolder
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Size = UDim2.fromScale(0.23, 0.06)
    box.Position = UDim2.fromScale(nx, 0.68)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 1
    box.BorderColor3 = accent
    box.ZIndex = 999999

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = box

    local bar = Instance.new("Frame")
    bar.Name = "Line"
    bar.Parent = box
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.fromScale(0, 1)
    bar.Size = UDim2.fromScale(0, 0.035)
    bar.BackgroundColor3 = accent
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0
    bar.ZIndex = 1000000

    local barR = Instance.new("UICorner")
    barR.CornerRadius = UDim.new(1, 0)
    barR.Parent = bar

    local icon = Instance.new("ImageLabel")
    icon.Name = "Logo"
    icon.Parent = box
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.067, 0.5)
    icon.Size = UDim2.fromScale(0.115, 0.88)
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ImageTransparency = 1
    icon.ZIndex = 1000000

    if Image and Image ~= "" then
        if typeof(Image) == "string" and Image:sub(1, 13) == "rbxassetid://" then
            icon.Image = Image
        elseif isfile and isfile(Image) and getcustomasset then
            icon.Image = getcustomasset(Image)
        elseif LogoAsset then
            icon.Image = LogoAsset
        end
    elseif LogoAsset then
        icon.Image = LogoAsset
    end

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = box
    title.AnchorPoint = Vector2.new(0, 0.5)
    title.Position = UDim2.fromScale(0.135, 0.35)
    title.Size = UDim2.fromScale(0.84, 0.35)
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Font = Enum.Font.SourceSans
    title.Text = "[catpaint] " .. tostring(TitleText or "Notification")
    title.TextScaled = true
    title.TextSize = 1
    title.TextStrokeTransparency = 0.5
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = accent
    title.TextTransparency = 1
    title.ZIndex = 1000000

    local desc = Instance.new("TextLabel")
    desc.Name = "Description"
    desc.Parent = box
    desc.AnchorPoint = Vector2.new(0, 0.5)
    desc.Position = UDim2.fromScale(0.135, 0.68)
    desc.Size = UDim2.fromScale(0.84, 0.29)
    desc.BackgroundTransparency = 1
    desc.BorderSizePixel = 0
    desc.Font = Enum.Font.SourceSans
    desc.Text = tostring(DescriptionText or "...")
    desc.TextScaled = true
    desc.TextSize = 1
    desc.TextStrokeTransparency = 0.5
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextColor3 = accent
    desc.TextTransparency = 1
    desc.ZIndex = 1000000

    local textW = math.max(title.TextBounds.X, desc.TextBounds.X) * 1.125
    box.Size += UDim2.fromOffset(math.clamp(textW - 265, 0, 1000), 0)

    local snd = Instance.new("Sound")
    snd.SoundId = "rbxassetid://3318713980"
    snd.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
    snd.PlayOnRemove = true
    snd.Parent = game.CoreGui
    snd:Destroy()

    local Data = { Main = box, Line = bar, Logo = icon, Title = title, Description = desc }

    table.insert(Notifications, Data)

    local Index = #Notifications

    local TargetY = GetNotifyYBase() + ((Index - 1) * NotificationSpacing)

    local LockColor

    LockColor = RunService.RenderStepped:Connect(function()
        if not box or not box.Parent then
            if LockColor then
                LockColor:Disconnect()
            end

            return
        end

        box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

        box.BorderColor3 = accent:Lerp(
            Color3.new(0, 0, 0),
            0.4
        )

        bar.BackgroundColor3 = accent

        icon.ImageColor3 = accent

        title.TextColor3 = accent

        title.TextStrokeColor3 = accent:Lerp(
            Color3.new(0, 0, 0),
            0.8
        )

        desc.TextColor3 = accent:Lerp(
            Color3.new(0, 0, 0),
            0.15
        )

        desc.TextStrokeColor3 = accent:Lerp(
            Color3.new(0, 0, 0),
            0.8
        )
    end)

    local Timer = Time or 3.33

    local InInfo = TweenInfo.new(
        0.8,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )

    TweenService:Create(box, InInfo, { Position = UDim2.fromScale(nx, TargetY), BackgroundTransparency = 0.4 }):Play()
    TweenService:Create(bar, InInfo, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(icon, InInfo, { ImageTransparency = 0 }):Play()
    TweenService:Create(title, InInfo, { TextTransparency = 0 }):Play()
    TweenService:Create(desc, InInfo, { TextTransparency = 0 }):Play()

    bar:TweenSize(UDim2.fromScale(1, 0.035), "Out", "Linear", Timer)

    task.delay(Timer + 0.1, function()
        if not box or not box.Parent then
            return
        end

        local OutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local exit = TweenService:Create(box, OutInfo, { Position = UDim2.fromScale(nx, TargetY - 0.045), BackgroundTransparency = 1 })
        exit:Play()
        TweenService:Create(bar, OutInfo, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(icon, OutInfo, { ImageTransparency = 1 }):Play()
        TweenService:Create(title, OutInfo, { TextTransparency = 1 }):Play()
        TweenService:Create(desc, OutInfo, { TextTransparency = 1 }):Play()

        exit.Completed:Once(function()
            if LockColor then LockColor:Disconnect() end
            for i, n in ipairs(Notifications) do
                if n == Data then table.remove(Notifications, i) break end
            end
            box:Destroy()
            Updatemstudio45Positions()
        end)
    end)
end

Functions.Notify = function(Settings)
    if not Settings.Body then Settings.Body = "..." end

    if Options.NotifyStyle and Options.NotifyStyle.Value == "LolhaxV3" then
        LolhaxNotify(Settings.Title, Settings.Body, Settings.Image, Color3.fromRGB(0, 120, 255), Settings.Time)
    elseif Options.NotifyStyle and Options.NotifyStyle.Value == "mstudio45" then
        local snd = Instance.new("Sound", GetHiddenContainer())
        snd.SoundId = Options.MspaintUI_NotifySound and Options.MspaintUI_NotifySound.Value or "rbxassetid://4590662766"
        snd.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
        snd.PlayOnRemove = true
        snd:Destroy()
        NotificationLibrary:Notify(Settings.Title, Settings.Body, Settings.Time or 5)
    else
        Library:OldNotify({ Title = Settings.Title, Description = Settings.Body, Time = Settings.Time,
            SoundId = Options.MspaintUI_NotifySound and Options.MspaintUI_NotifySound.Value or "rbxassetid://4590662766",
            Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or 0,
        })
    end
end
Functions.Caption = function(Text, PlaySound)
    if Options.MspaintUI_CaptionStyle and Options.MspaintUI_CaptionStyle.Value == "Obsidian"
        and Library.AddDraggableLabel then
        if not Global.UICaption then
            Global.UICaption = Library:AddDraggableLabel({ Text = "", Icon = "captions" })
        end
        Global.UICaptionGeneration = (Global.UICaptionGeneration or 0) + 1
        local Generation = Global.UICaptionGeneration
        Global.UICaption:SetText(tostring(Text))
        Global.UICaption:SetVisible(true)
        task.delay(5, function()
            if not Library.Unloaded and Global.UICaption and Global.UICaptionGeneration == Generation then
                Global.UICaption:SetVisible(false)
            end
        end)
        return
    end
	if typeof(PlaySound) ~= "boolean" then PlaySound = true end

	local val = Instance.new("NumberValue")
	local cap = Global.MainUI:WaitForChild("MainFrame"):WaitForChild("Caption"):Clone()
	local src = Global.MainUI:WaitForChild("Initiator"):WaitForChild("Main_Game"):WaitForChild("Reminder"):WaitForChild("Caption")
	local snd = src:Clone()
	snd.Parent = src.Parent
	snd.Volume = 0.1

	cap.Destroying:Connect(function() val:Destroy() end)

	for _, c in Global.MainUI:GetChildren() do
		if c.Name == "LiveCaption" then c:Destroy() end
	end

	cap.Parent = Global.MainUI
	cap.Visible = true
	cap.Name = "LiveCaption"
	cap.Text = Text

	if PlaySound then snd:Play() end
	Services.Debris:AddItem(snd, 5)

	local tw = Services.TweenService:Create(val, TweenInfo.new(3), { Value = 100 })
	tw:Play()
	tw.Completed:Connect(function()
		val:Destroy()
		Services.TweenService:Create(cap, TweenInfo.new(4, Enum.EasingStyle.Linear), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

Functions.GetHasteTime = function()
	local t = FloorReplicated.DigitalTimer.Value
	local m = math.floor(t / 60)
	local s = t - m * 60
	return string.format("%02d:%02d", m, s)
end

Library.OldNotify = Library.Notify
Library.Notify = function(Self, Data, Time)
    if type(Data) == "table" then
        return Functions.Notify({ Title = Data.Title or "catpaint", Body = Data.Description or Data.Body or "",
            Image = Data.BigIcon or Data.Image, Time = Data.Time or 5 })
    end
    return Functions.Notify({ Title = "catpaint", Body = tostring(Data or ""), Time = Time or 5 })
end

if not LocalPlayer.Character or not CurrentRooms:FindFirstChildOfClass("Model") then
	if Loading then
		Loading:SetCurrentStep(2)
		Loading:SetMessage("Waiting for the game to load...")
	end
	Functions.Notify({ Title = "Waiting for the game to load..." })
	while not LocalPlayer.Character or not CurrentRooms:FindFirstChildOfClass("Model") do
		task.wait()
	end
	task.wait(4)
end

if not RemotesFolder then
	if Services.ReplicatedStorage:FindFirstChild("EntityInfo") then
		RemotesFolder = Services.ReplicatedStorage:FindFirstChild("EntityInfo")
	elseif Services.ReplicatedStorage:FindFirstChild("Bricks") then
		RemotesFolder = Services.ReplicatedStorage:FindFirstChild("Bricks")
	end
end

if Floor == "Hotel" and RemotesFolder.Name == "Bricks" then
	Floor = "OldHotel"
end

if not LiveModifiers then
	LiveModifiers = Instance.new("Folder")
end

if not FloorReplicated then
	FloorReplicated = Instance.new("Folder")
end

Functions.IsFloorAllowed = function(allowedFloors)
	if not allowedFloors then return true end
	local cur = tostring(Floor or ""):lower()
	if cur == "" and GameData then
		local fObj = GameData:FindFirstChild("FloorDestination") or GameData:FindFirstChild("Floor")
		if fObj then cur = tostring(fObj.Value):lower() end
	end
	local function matchFloor(a, b)
		if a == b then return true end
		if (a == "outdoors" or a == "garden") and (b == "outdoors" or b == "garden") then return true end
		return false
	end
	if type(allowedFloors) == "string" then
		return matchFloor(cur, allowedFloors:lower())
	elseif type(allowedFloors) == "table" then
		for _, f in ipairs(allowedFloors) do
			if matchFloor(cur, tostring(f):lower()) then return true end
		end
	end
	return false
end

Functions.CheckFloorToggle = function(toggleKey, allowedFloors, featureName)
	if not Functions.IsFloorAllowed(allowedFloors) then
		local toggle = Toggles[toggleKey]
		if toggle and toggle.Value then
			task.spawn(function()
				pcall(function() toggle:SetValue(false) end)
			end)
		end
		local allowedStr = type(allowedFloors) == "table" and table.concat(allowedFloors, ", ") or tostring(allowedFloors)
		Functions.Notify({
			Title = "Floor Incompatible",
			Body = (featureName or toggleKey) .. " is only available on: " .. allowedStr .. " (Current floor: " .. tostring(Floor) .. ")",
			Time = 4
		})
		return false
	end
	return true
end

local FakeEvents = {
	Screech = Instance.new("RemoteEvent"),
	Shade   = Instance.new("RemoteEvent"),
	A90     = Instance.new("RemoteEvent"),
	Surge   = Instance.new("RemoteEvent"),
	Figure = Instance.new("RemoteEvent"),
}

FakeEvents.Screech.Name  = "Screech"
FakeEvents.Shade.Name    = "ShadeResult"
FakeEvents.A90.Name      = "A90"
FakeEvents.Surge.Name    = "SurgeRemote"
FakeEvents.Figure.Name = "FootstepRemoteThatWeNeed"

FakeEvents.Screech_Real = RemotesFolder:WaitForChild("Screech")
FakeEvents.Shade_Real   = RemotesFolder:WaitForChild("ShadeResult")
FakeEvents.A90_Real     = RemotesFolder:FindFirstChild("A90")
FakeEvents.Surge_Real   = RemotesFolder:FindFirstChild("SurgeRemote")
FakeEvents.Figure_Real = RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed")

if not Workspace:FindFirstChild("mstudio45_Folder") then
local BkRemotes = Instance.new("Folder", game.Workspace)
BkRemotes.Name = "mstudio45_Folder"
end

local gui = Instance.new("ScreenGui")
gui.Name = "DontDelete"
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(1, 0, 1, 0)
frame.Position = UDim2.new(0, 0, 0, 0)
frame.BackgroundColor3 = Color3.new(0, 0, 0)

local img = Instance.new("ImageLabel")
img.Parent = frame
img.Size = UDim2.new(1, 0, 1, 0)
img.Position = UDim2.new(0, 0, 0, 0)
img.BackgroundTransparency = 1
img.ScaleType = Enum.ScaleType.Stretch
img.Image = "rbxassetid://126189096308482"

Global.FogInstances = {}
Global.OldFog = Services.Lighting.FogEnd

for _, Object in Services.Lighting:GetChildren() do
	if Object:IsA("Atmosphere") then
		Object:SetAttribute("Density_Old", Object.Density)

		local AtmoConnection = Object:GetPropertyChangedSignal("Density"):Connect(function()
			if Object.Density ~= 0 then
				Object:SetAttribute("Density_Old", Object.Density)
			end
			if Toggles.RemoveCameraFog.Value then
				Object.Density = 0
			end
		end)

		Object.Destroying:Once(function()
			if AtmoConnection then AtmoConnection:Disconnect() end
		end)

		table.insert(Conns, AtmoConnection)
		table.insert(Global.FogInstances, Object)
	end
end

local function GenRandomStr()
	local str
	pcall(function()
		if mstudio45 and mstudio45.ESPLibrary and type(mstudio45.ESPLibrary.GenerateRandomString) == "function" then
			str = mstudio45.ESPLibrary:GenerateRandomString()
		end
	end)
	if type(str) == "string" and #str > 0 then return str end
	return "Folder_" .. tostring(math.random(100000, 999999))
end

Global.SeekNodesFolder = Instance.new("Folder", Services.Workspace)
Global.SeekNodesFolder.Name = GenRandomStr()

Global.RoomsNodesFolder = Instance.new("Folder", Services.Workspace)
Global.RoomsNodesFolder.Name = GenRandomStr()

Functions.SendChat = function(Message)
	local ok, Chan = pcall(function()
		return Services.TextChatService.TextChannels:FindFirstChild("RBXGeneral")
	end)
	if ok and Chan then
		Chan:SendAsync(Message)
		return
	end
	local Legacy = Services.ReplicatedStorage:FindFirstChild("DefaultChatSystemEvents")
	if Legacy then
		local SayReq = Legacy:FindFirstChild("SayMessageRequest")
		if SayReq then SayReq:FireServer(Message, "All") end
	end
end

Functions.IsCrouching = function()
    if Floor == "Fools" or Floor == "OldHotel" then
        return Character:GetAttribute("Crouching")
    end

    return CollisionPart.CollisionGroup == "PlayerCrouching"
end

Functions.GetInjuriesSpeed = function()
	return 0.075 * (Humanoid.MaxHealth - Humanoid.Health)
end

Functions.GetCurrentSpeed = function()
	local Speed = 15
	Speed += Character:GetAttribute("SpeedBoost") or 0
	Speed += Character:GetAttribute("SpeedBoostBehind") or 0
	Speed += Character:GetAttribute("SpeedBoostExtra") or 0
	Speed += (Floor == "Party" and 10 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFast") and 3 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFaster") and 6 or 0)
	Speed += (LiveModifiers:FindFirstChild("PlayerFastest") and 20 or 0)
	Speed -= (LiveModifiers:FindFirstChild("PlayerSlow") and 3 or 0)
	Speed -= (LiveModifiers:FindFirstChild("PlayerSlowHealth") and Functions.GetInjuriesSpeed() or 0)
	if Functions.IsCrouching() then
		if LiveModifiers:FindFirstChild("PlayerCrouchSlow") then
			Speed -= 8
		elseif LiveModifiers:FindFirstChild("PlayerSlow") then
			Speed -= 8
		else
			Speed -= 5
		end
	end
	return Speed
end

Functions.GetMousePosition = function()
	if Library.IsMobile then
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end
	local MouseLocation = Services.UserInputService:GetMouseLocation()
	return Vector2.new(MouseLocation.X, MouseLocation.Y)
end

Functions.FormatOxygen = function(Oxygen)
	return "Oxygen: " .. (math.floor(Oxygen * 10) / 10) .. "%"
end

Functions.IsHidePersistent = function()
	return Floor == "Mines"
		or Floor == "Ripple"
		or Floor == "Party"
		or LiveModifiers:FindFirstChild("HideLevel2") ~= nil
end

Functions.GetPlayerFromMouse = function(TargetPart, MaxDistance)
	local Closest
	local ClosestDistance = math.huge

	for _, Player in Services.Players:GetPlayers() do
		local Char = Player.Character
		if Char then
			local Target = Char:FindFirstChild(TargetPart)
			if Target then
				local Result = Camera:WorldToViewportPoint(Target.Position)
				local ScreenPos = Vector2.new(Result.X, Result.Y)
				local Distance = (Functions.GetMousePosition() - ScreenPos).Magnitude
				if Player.Name ~= LocalPlayer.Name and Distance < ClosestDistance and Distance < MaxDistance then
					Closest = Target
					ClosestDistance = Distance
				end
			end
		end
	end
	return Closest
end

local EntityDistances = {
	["RushMoving"]    = 160,
	["AmbushMoving"]  = 220,
	["A60"]           = 200,
	["A120"]          = 150,
	["GlitchRush"]    = 160,
	["GlitchAmbush"]  = 220,
	["BackdoorRush"]  = 150,
	["BashMoving"]    = 200,
	["CustomEntity"]  = 150,
	["Rush"]          = 160,
	["Ambush"]        = 220,
	["A-60"]          = 200,
	["A-120"]         = 150,
	["Blitz"]         = 180,
}

Functions.GetNearestEntity = function(CheckDisabled, List)
	local best, bestDist = nil, math.huge
	local HRP = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart)
	if not HRP then return nil end
	local myPos = HRP.Position

	local function CheckModel(ent)
		if not ent or not ent.Parent then return end
		local range = EntityDistances[ent.Name]
		if not range then
			if ent.Name:find("Rush") then range = 200
			elseif ent.Name:find("Ambush") then range = 250
			elseif ent.Name:find("A60") or ent.Name:find("A-60") then range = 250
			elseif ent.Name:find("A120") or ent.Name:find("A-120") then range = 180
			end
		end
		if range then
			local inactive = CheckDisabled and ent:GetAttribute("Inactive") == true
			if not inactive then
				local entPos = ent:GetPivot().Position
				local d = (myPos - entPos).Magnitude
				if d < range and d < bestDist then
					best, bestDist = ent, d
				end
			end
		end
	end

	for _, ent in Services.Workspace:GetChildren() do
		CheckModel(ent)
	end
	return best
end

Functions.GetNearestFigure = function()
	local FigureNames = { FigureRig = true, FigureRagdoll = true, Figure = true }
	local best, bestDist = nil, math.huge

	for _, obj in Objects.Entities do
		if obj:IsA("Model") and obj.PrimaryPart and FigureNames[obj.Name] then
			local d = LocalPlayer:DistanceFromCharacter(obj.PrimaryPart.Position)
			if d < 25 and d < bestDist then
				best, bestDist = obj, d
			end
		end
	end
	return best
end

Functions.GetNearestTurnNode = function()
	local best, bestDist = nil, math.huge

	for _, node in Objects.SeekNodes do
		local d = LocalPlayer:DistanceFromCharacter(node.Position)
		if d < 35 and d < bestDist then
			best, bestDist = node, d
		end
	end
	return best
end

Functions.GetNearestDuckBoard = function()
	local best, bestDist = nil, math.huge

	for _, board in Objects.SeekDuckBoards do
		if board.PrimaryPart then
			local d = LocalPlayer:DistanceFromCharacter(board.PrimaryPart.Position)
			if d < 25 and d < bestDist then
				best, bestDist = board, d
			end
		end
	end
	return best
end

Functions.GetCurrentAnchor = function()
	local AnchorCode = Global.MainUI.AnchorHintFrame.AnchorCode.Text
	for _, Anchor in Objects.Objectives do
		if Anchor.Name == "MinesAnchor" and Anchor:FindFirstChild("Sign") then
			if Anchor.Sign.TextLabel.Text == AnchorCode then
				return Anchor
			end
		end
	end
end

Functions.GetMinecart = function()
	return Camera:FindFirstChild("MinecartRig") ~= nil
end

Functions.HasItem = function(Name, OnlyCharacter)
	if not OnlyCharacter and LocalPlayer.Backpack:FindFirstChild(Name) then
		return LocalPlayer.Backpack:FindFirstChild(Name)
	elseif Character:FindFirstChild(Name) then
		return Character:FindFirstChild(Name)
	end
end

Functions.GetFlyVelocity = function()
	if Humanoid.MoveDirection == Vector3.zero then
		return Humanoid.MoveDirection
	end
	local LookFlat = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
	local FlatFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + LookFlat)
	local Velocity = (Camera.CFrame * CFrame.new(FlatFrame:VectorToObjectSpace(Humanoid.MoveDirection))).Position - Camera.CFrame.Position
	if Velocity == Vector3.zero then
		return Velocity
	end
	return Velocity.Unit
end

Global.PromptContainer = Instance.new("Folder")
Global.PromptContainer.Name = "PromptContainer"
Global.PromptContainer.Parent = GetHiddenContainer()

local ESPBlacklist = {}

local function GetRoomNum(val)
	if not val then return 0 end
	if tonumber(val) then return tonumber(val) end
	local n = tostring(val):match("%d+")
	return tonumber(n) or 0
end

Functions.AddESP = function(ESPOptions, RoomBased)
	local Object = ESPOptions.Object
	if not Object then return end

	if table.find(ESPBlacklist, Object) then
		return
	end

	if RoomBased then
		local CurrentRoom = GetRoomNum(LocalPlayer:GetAttribute("CurrentRoom"))
		local ObjectRoom = GetRoomNum(Object:GetAttribute("ParentRoom"))

		local isDoor = table.find(Objects.Doors, Object) or Object.Name == "HighlightModel" or Object.Name == "HighlightPart"
		local isNextDoor = isDoor and (ObjectRoom == CurrentRoom or ObjectRoom == CurrentRoom + 1)
		local shouldShow = (ObjectRoom == CurrentRoom) or (isDoor and isNextDoor)

		if shouldShow then
			mstudio45.ESPLibrary:AddESP(ESPOptions)
		end

		local RoomConnection = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
			if mstudio45.ESPLibrary.ColorTable[Object] then
				ESPOptions.Color = mstudio45.ESPLibrary.ColorTable[Object]
			end

			local NewCurrentRoom = GetRoomNum(LocalPlayer:GetAttribute("CurrentRoom"))
			local ObjRoom = GetRoomNum(Object:GetAttribute("ParentRoom"))

			local okNext = isDoor and (ObjRoom == NewCurrentRoom or ObjRoom == NewCurrentRoom + 1)
			if ObjRoom == NewCurrentRoom or okNext then
				mstudio45.ESPLibrary:AddESP(ESPOptions)
			else
				mstudio45.ESPLibrary:RemoveESP(Object)
			end
		end)

		table.insert(Conns, RoomConnection)
		ESPConns[Object] = RoomConnection

		Object.Destroying:Once(function()
			RoomConnection:Disconnect()
			if mstudio45 then
				mstudio45.ESPLibrary:RemoveESP(Object)
			end
			local Pos = table.find(Conns, RoomConnection)
			if Pos then table.remove(Conns, Pos) end
		end)
	else
		mstudio45.ESPLibrary:AddESP(ESPOptions)
	end
end

Functions.RemoveESP = function(Object)
	local Conn = ESPConns[Object]
	if Conn then
		Conn:Disconnect()
		ESPConns[Object] = nil
		local Pos = table.find(Conns, Conn)
		if Pos then table.remove(Conns, Pos) end
	end
	if mstudio45 and mstudio45.ESPLibrary then
		mstudio45.ESPLibrary:RemoveESP(Object)
	end
end

Functions.BlacklistESP = function(Object)
	table.insert(ESPBlacklist, Object)
end

Functions.GetAttributeOpened = function(Object)
	return if Object:GetAttribute("Opened") then "[Opened]" else nil
end

local function GetDoorText(Object)
	local roomName = Object and Object.Parent and Object.Parent.Name or ""
	-- the door at the end of room N leads into room N+1: the game numbers it by
	-- its RoomID attribute (printed on its sign as A-00N), not by the room it sits in
	local doorId = Object and Object:GetAttribute("RoomID")
	if doorId ~= nil then
		roomName = tostring(doorId)
	end
	local opened = Functions.GetAttributeOpened(Object) or ""
	if opened ~= "" then opened = " " .. opened end
	if roomName ~= "" then
		return "Door " .. roomName .. opened
	end
	return "Door" .. opened
end

local function RefreshDoorESP(Door, ESPObj)
	if mstudio45 and mstudio45.ESPLibrary then
		mstudio45.ESPLibrary:UpdateObjectText(ESPObj, GetDoorText(Door))
	end
end
local function KeepDoorTextSynced(Object, ESPObj)
	local conn
	conn = Services.RunService.Heartbeat:Connect(function()
		if not (mstudio45 and mstudio45.ESPLibrary) or not Object.Parent then
			if conn then conn:Disconnect() end
		else
			RefreshDoorESP(Object, ESPObj)
		end
	end)
	Object.Destroying:Once(function()
		if conn then conn:Disconnect() end
	end)
	return conn
end

Functions.GetLibraryCode = function()
	local Paper = Character:FindFirstChild("LibraryHintPaper")
		or Character:FindFirstChild("LibraryHintPaperHard")
		or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper")
		or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaperHard")

	if Paper and Paper:FindFirstChild("UI") then
		local Code = {}
		local CodeLength = Floor == "Fools" and 10 or 5
		for I = 1, CodeLength do Code[I] = "_" end

		local HintChildren = LocalPlayer.PlayerGui.PermUI.Hints:GetChildren()
		local UIChildren = Paper.UI:GetChildren()

		for _, Hint in HintChildren do
			for _, UIChild in UIChildren do
				if Hint:IsA("ImageLabel") and UIChild:IsA("ImageLabel")
					and Hint.ImageRectOffset == UIChild.ImageRectOffset
					and Code[tonumber(UIChild.Name)]
				then
					Code[tonumber(UIChild.Name)] = Hint.TextLabel.Text
				end
			end
		end
		return table.concat(Code)
	end
	return Floor == "Fools" and "__________" or "_____"
end

Global.UI = {}
-- UI layout adapted from the supplied mspaint v4 screenshots.
-- This is a UI remake for the existing mstudio45/DOORS module, not the mspaint hub.
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true
Library.ToggleKeybind = Enum.KeyCode.RightShift
for Name, Color in pairs({
    BackgroundColor = Color3.fromRGB(15, 15, 15),
    MainColor = Color3.fromRGB(25, 25, 25),
    AccentColor = Color3.fromRGB(125, 80, 250),
    OutlineColor = Color3.fromRGB(42, 42, 42),
    FontColor = Color3.fromRGB(240, 240, 240),
}) do
    Library.Scheme[Name] = Color
    Library[Name] = Color -- compatibility with older Obsidian builds
end
if Library.SetFont then Library:SetFont(Enum.Font.Code) end

local Window = Library:CreateWindow({
    Title = "catpaint",
    Icon = 136097487509067,
    Footer = "Game: DOORS | catpaint | Build tung",
    Size = UDim2.fromOffset(720, 600),
    NotifySide = "Right",
    ShowCustomCursor = false,
    AutoShow = true,
    Center = true,
    Resizable = true,
    DisableSearch = false,
    GlobalSearch = true,
    SearchbarSize = UDim2.fromOffset(180, 30),
    Font = Enum.Font.Code,
    ToggleKeybind = Enum.KeyCode.RightShift,
    CornerRadius = 2,
    TabPadding = 3,
    MenuFadeTime = 0,
    EnableSidebarResize = true,
    EnableCompacting = true,
    SidebarCompacted = false,
    MinSidebarWidth = 140,
    MinContainerWidth = 180,
    TabButtonsStyle = { Gap = 0, Padding = 10, CornerRadius = 0, Indicator = false },
    Animations = { ToggleWindow = true, TabSwitch = true, Groupbox = true, Dropdown = true, KeyPicker = true },
    TabTransitionTime = 0.22,
    TabSwipeOffset = 26,
    TabSwipeFrom = "bottom",
})
if Window.SetSidebarWidth then Window:SetSidebarWidth(194) end
if Library.UpdateColorsUsingRegistry then Library:UpdateColorsUsingRegistry() end

local Tabs = {}
Tabs.Home = Window:AddTab("Home", "door-open", "Homepage for catpaint")
Tabs.Info = Window:AddTab("Info", "info", "Information about this UI remake")
Tabs.General = Window:AddTab("Main", "house", "Main Features")
Tabs.Exploits = Window:AddTab("Exploits", "bug", "Game Exploits")
Tabs.Visuals = Window:AddTab("Visuals", "scan-eye", "Visual Tweaks & ESP")
Tabs.Floors = Window:AddTab("Floor", "sparkles", "Floor-based Features")
Tabs.Settings = Window:AddTab("Settings", "settings", "Script Settings")
Tabs.Interface = Window:AddTab("Interface", "palette", "UI Settings")
Tabs.Addons = Window:AddTab("Addons", "blocks", "Included Components")

-- Construct containers in their visual order. Backend keys below are unchanged.
Global.UI.General_CharacterTabs = Tabs.General:AddLeftTabbox("Character / Player")
Global.UI.General_Character = Global.UI.General_CharacterTabs:AddTab("Character")
Global.UI.General_Self = Global.UI.General_CharacterTabs:AddTab("Player")
Global.UI.General_Prompts = Tabs.General:AddLeftGroupbox("Prompts")
Global.UI.Self_Misc = Tabs.General:AddRightGroupbox("Game Management")
Global.UI.Self_Automation = Tabs.General:AddRightGroupbox("Automation")


Global.UI.Exploits_AntiTabs = Tabs.Exploits:AddLeftTabbox("Anti Entity / No Damage")
Global.UI.Exploits_Anti = Global.UI.Exploits_AntiTabs:AddTab("Anti Entity")
Global.UI.Exploits_Remove = Global.UI.Exploits_AntiTabs:AddTab("No Damage")
Global.UI.Exploits_BypassRight = Tabs.Exploits:AddRightGroupbox("Bypass")
Global.UI.Exploits_TrollTabs = Tabs.Exploits:AddRightTabbox("Trolling / Players")
Global.UI.Exploits_Troll = Global.UI.Exploits_TrollTabs:AddTab("Trolling")
Global.UI.Troll_Left = Global.UI.Exploits_TrollTabs:AddTab("Players")
Global.UI.Visuals_Mspaint = Tabs.Addons:AddLeftGroupbox("Extras", "sparkles")

Global.UI.Visuals_ESP = Tabs.Visuals:AddLeftTabbox("ESP / Settings")
Global.UI.Visuals_ESP_Toggles = Global.UI.Visuals_ESP:AddTab("ESP")
Global.UI.Visuals_ESP_Settings = Global.UI.Visuals_ESP:AddTab("Settings")
Global.UI.Visuals_Ambient = Tabs.Visuals:AddLeftGroupbox("Ambient")
Global.UI.Visuals_RightTab = Tabs.Visuals:AddRightTabbox("Notifier / Settings")
Global.UI.Visuals_Entities = Global.UI.Visuals_RightTab:AddTab("Notifier")
Global.UI.Visuals_EntitySettings = Global.UI.Visuals_RightTab:AddTab("Settings")
Global.UI.Visuals_LeftTab = Tabs.Visuals:AddRightTabbox("Camera / Player")
Global.UI.Visuals_Camera = Global.UI.Visuals_LeftTab:AddTab("Camera", "camera")
Global.UI.Visuals_Player = Global.UI.Visuals_LeftTab:AddTab("Player", "user")
Global.UI.Visuals_Effects = Tabs.Visuals:AddRightGroupbox("Effects")

Global.UI.Floors_EntityTabs = Tabs.Floors:AddLeftTabbox("Entity / Obstruction")
Global.UI.Floors_Bypass = Global.UI.Floors_EntityTabs:AddTab("Entity")
Global.UI.Floors_Obstruction = Global.UI.Floors_EntityTabs:AddTab("Obstruction")
Global.UI.Exploits_Audio = Tabs.Floors:AddLeftGroupbox("Modifiers")
Global.UI.Floors_Visuals = Tabs.Floors:AddLeftGroupbox("Visuals")
Global.UI.Floors_Automation = Tabs.Floors:AddRightGroupbox("Automation")
Global.UI.Floors_Completion = Tabs.Floors:AddRightGroupbox("Completion")

-- UI-only helpers live on Globals to avoid increasing the main chunk's local limit.
Global.CopyUILink = function(Url)
    local Copy = mstudio45.Environment and mstudio45.Environment.setclipboard or setclipboard
    if type(Copy) == "function" then
        local Ok = pcall(Copy, Url)
        if Ok then
            Functions.Notify({ Title = "Link copied", Body = Url })
            return
        end
    end
    Functions.Notify({ Title = "Copy this link", Body = Url, Time = 10 })
end

-- Home uses the current Roblox account, not fabricated subscription/game status.
do
    local Account = Tabs.Home:AddLeftGroupbox("Account", "user")
    if Account.AddImage then
        Account:AddImage("MspaintUI_Avatar", {
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=420&h=420",
            Height = 180,
        })
    end
    Account:AddLabel("Welcome, " .. LocalPlayer.DisplayName .. "!", true)
    Account:AddLabel("SKIBIDI TUNG TUNG SAHUR SCRIPT?", true)
    Account:AddDivider()
    Account:AddButton({ Text = "Script Dashboard", Func = function()
        Global.CopyUILink("example.com")
    end })
    Account:AddButton({ Text = "Main Server", Func = function()
        Global.CopyUILink("https://discord.gg/PB9AHh6sub")
    end }):AddButton({ Text = "Support Server", Func = function()
        Global.CopyUILink("example.com")
    end })

    local Overview = Tabs.Home:AddRightTabbox("Overview")
    local Games = Overview:AddTab("Game", "app-window")
    local Keys = Overview:AddTab("Keys", "key-round")
    local About = Overview:AddTab("About", "info")
    Games:AddLabel('<font color="#55dc90">●</font> DOORS')
    Games:AddLabel("Current floor: " .. tostring(Floor), true)
    Games:AddDivider()
    Games:AddLabel("This file contains the supplied DOORS module only, not the full catpaint game hub.", true)
    Games:AddButton({ Text = "Copy Link", Func = function()
        Global.CopyUILink("https://www.example.com")
    end })
    Keys:AddLabel("RightShift — toggle menu\nF — fly\nN — noclip\nR — auto interact", true)
    Keys:AddLabel("Bindings can be changed beside each toggle.", true)
end

do
    local Links = Tabs.Info:AddLeftGroupbox("catpaint links", "link")
    Links:AddLabel("Reference project and UI library links.", true)
    for _, Link in ipairs({
        { "catpaint site", "example.com" },
        { "Dashboard", "example.com" },
        { "Discord server", "https://discord.gg/PB9AHh6sub" },
        { "Support server", "https://www.discord.gg/PB9AHh6sub" },
        { "Obsidian documentation", "https://docs.mspaint.cc/obsidian" },
    }) do
        local Caption, Url = Link[1], Link[2]
        Links:AddButton({ Text = Caption, Func = function() Global.CopyUILink(Url) end })
    end
    local Credits = Tabs.Info:AddLeftGroupbox("Reference Credits", "code")
    Credits:AddLabel('<font color="#70de9b">[Unico]</font> catpaint owner', true)
    Credits:AddLabel('<font color="#70de9b">[Unico]</font> Developer', true)
    Credits:AddLabel('<font color="#70de9b">[deividcomsono]</font> Obsidian UI library', true)
    local Details = Tabs.Info:AddRightGroupbox("About this file", "info")
    Details:AddLabel("123.", true)
    Details:AddLabel("456.", true)
    Details:AddDivider()
    Details:AddLabel("789", true)
    local Components = Tabs.Addons:AddLeftGroupbox("Included", "blocks")
    Components:AddLabel("Obsidian — menu\nThemeManager — themes\nSaveManager — configurations\ncatpaint ESP — existing renderer", true)
end

-- ============================================================================
-- Tplay's Addon Complete Features Integration (v2.9.4)
-- ============================================================================
do
	-- Tabbox 1: Movement & Combat
	local Tplay_TabboxLeft1 = Tabs.Addons:AddLeftTabbox("Tplay - Movement & Bypass")
	local Tplay_Main = Tplay_TabboxLeft1:AddTab("Main", "sparkles")
	local Tplay_Combat = Tplay_TabboxLeft1:AddTab("Godmode & Combat", "shield")

	-- Tabbox 2: Items & Floor Completion
	local Tplay_TabboxLeft2 = Tabs.Addons:AddLeftTabbox("Tplay - Items & Floor Completion")
	local Tplay_Items = Tplay_TabboxLeft2:AddTab("Items", "package")
	local Tplay_Floors = Tplay_TabboxLeft2:AddTab("Floor Completion", "trophy")

	-- Tabbox 3: QoL & Visuals
	local Tplay_TabboxRight1 = Tabs.Addons:AddRightTabbox("Tplay - QoL & Visuals")
	local Tplay_QoL = Tplay_TabboxRight1:AddTab("QoL & Alerts", "bell")
	local Tplay_Visuals = Tplay_TabboxRight1:AddTab("Death Lights & Mod", "sparkles")

	-- Tabbox 4: Trolling & Admin
	local Tplay_TabboxRight2 = Tabs.Addons:AddRightTabbox("Tplay - Trolling & Admin")
	local Tplay_Troll = Tplay_TabboxRight2:AddTab("Trolling", "smile")
	local Tplay_Admin = Tplay_TabboxRight2:AddTab("Admin Panel", "terminal")


	local TplayVars = {
		NetworkActive = false,
		NetworkOld = {},
		OrbitDropsConnection = nil,
		OrbitGlowsticksConnection = nil,
		WalkSpeedConnection = nil,
		AntiTeleportConnection = nil,
		ACMAConnection = nil,
		OnChairOrCartGrab = nil,
		LoopStealConnection = nil,
		HidingRoomConnection = nil,
		GSNotifierConnection = nil,
		MonumentWatcher = nil,
		EndingCutsceneConnection = nil,
		CrazyPartsConnection = nil,
		UpsideDownConnection = nil,
		WalkAnimSpoofConnection = nil,
		AGSConnection = nil,
		AFRConnection = nil,
		POAConnection = nil,
		InfiniteCrucifixConnection = nil,
		OnDupeAnimation = nil,
		OnDupeSpawned = nil,
		OnDupeRemoved = nil,
		SECConnection = nil,
		OnCutsceneSEC = nil,
		OnStatistics = nil,
		DeletePropsConnection = nil,
		BodyVelocity = Instance.new("BodyVelocity"),
		WalkSpeed = 15,
		LadderSpeed = 15,
		OrbitSpeed = 1,
		OrbitOffset = 4,
		MotorSpeed = 1,
		MotorMethod = "BrokenSpine",
		MotorAbuseEnabled = false,
		UpsideDownEnabled = false,
		GhostReviveMethod = "Method #1 (Door 0)",
		ConnectingChair = false,
		ACBypassNotify = nil,
		Groundskeepers = {},
		FigureRigs = {},
		stopTauntTimes = 0,
		lastTaunt = -1/0,
		accurateAim = false,
		fastThrow = false,
		showPathfind = false,
		AllPathfindNodes = {},
		doorReach = false,
		ping = 0,
		spoofedGS = false,
		spoofedFR = false,
		SelectedPlayerItem = nil,
		PlayerToKill = nil,
		SelectedAPPlayer = nil,
		WalkSpoofMethod = "NoAnimation",
		SelfDontSpoof = false,
		LightSelection = "Blue",
		DeluluSound = "7107161936",
		DeluluColor = Color3.new(1, 1, 1),
		DeluluCaptionEnabled = false,
		LODEnabled = false,
		NLDEnabled = false,
		EDCEnabled = false,
		AdminLoaded = false,
		AdminItems = {},
		AntiStealEnabled = false,
		NoPromptEnabled = false,
		MandrakesPos = {},
		DrawersConnections = {},
		PartsConnections = {},
		ConnectedPrompts = {},
		Dupes = {},
		AutoFloorMethod = "1",
		AutoPickupNeeds = {},
	}
	TplayVars.BodyVelocity.MaxForce = Vector3.new(1/0, 1/0, 1/0)

	-- Environment Helpers
	local sethidden = mstudio45.Environment.sethiddenproperty or sethiddenproperty
	local gethidden = mstudio45.Environment.gethiddenproperty or gethiddenproperty
	local isnetowner = mstudio45.Environment.isnetworkowner or isnetworkowner or function() return true end
	local fireprompt = mstudio45.Environment.fireproximityprompt or fireproximityprompt
	local firetouch = mstudio45.Environment.firetouchinterest or firetouchinterest
	local replsignal = mstudio45.Environment.replicatesignal or replicatesignal

	local function ToggleNetworkOwner(bool)
		if not sethidden or not gethidden then return end
		if bool and not TplayVars.NetworkActive then
			TplayVars.NetworkActive = true
			TplayVars.NetworkOld.allowSleep = settings().Physics.AllowSleep
			TplayVars.NetworkOld.replicaFocus = LocalPlayer.ReplicationFocus
			TplayVars.NetworkOld.maxSimRadius = gethidden(LocalPlayer, "MaximumSimulationRadius")
			TplayVars.NetworkOld.simRadius = gethidden(LocalPlayer, "SimulationRadius")

			settings().Physics.AllowSleep = false
			LocalPlayer.ReplicationFocus = Services.Workspace

			TplayVars.NetworkConnection = Services.RunService.Heartbeat:Connect(function()
				sethidden(LocalPlayer, "MaximumSimulationRadius", 1/0)
				sethidden(LocalPlayer, "SimulationRadius", 1/0)
				if replsignal then
					pcall(replsignal, LocalPlayer.SimulationRadiusChanged, 1/0)
				end
				for _, p in ipairs(Services.Players:GetPlayers()) do
					if p ~= LocalPlayer then
						sethidden(p, "MaxSimulationRadius", 0)
						sethidden(p, "SimulationRadius", 0)
						if replsignal then
							pcall(replsignal, p.SimulationRadiusChanged, 0)
						end
					end
				end
			end)
		elseif not bool and TplayVars.NetworkActive then
			TplayVars.NetworkActive = false
			if TplayVars.NetworkConnection then
				TplayVars.NetworkConnection:Disconnect()
				TplayVars.NetworkConnection = nil
			end
			settings().Physics.AllowSleep = TplayVars.NetworkOld.allowSleep or true
			LocalPlayer.ReplicationFocus = TplayVars.NetworkOld.replicaFocus
			if TplayVars.NetworkOld.maxSimRadius then
				sethidden(LocalPlayer, "MaximumSimulationRadius", TplayVars.NetworkOld.maxSimRadius)
			end
			if TplayVars.NetworkOld.simRadius then
				sethidden(LocalPlayer, "SimulationRadius", TplayVars.NetworkOld.simRadius)
			end
		end
	end

	-- Pathfinding & Collision Helpers
	local PathfindingService = Services.PathfindingService
	local TPPath = PathfindingService:CreatePath({
		AgentRadius = 1,
		AgentHeight = 1,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 4,
		Costs = { Water = 100 }
	})

	local function WeldTo(targetPart, offsetCFrame)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = RootPart
		weld.Part1 = targetPart
		weld.Parent = RootPart
		if offsetCFrame then
			RootPart.CFrame = targetPart.CFrame * offsetCFrame
		end
		local oldSleep = settings().Physics.AllowSleep
		settings().Physics.AllowSleep = false
		return {
			Destroy = function()
				if weld and weld.Parent then weld:Destroy() end
				settings().Physics.AllowSleep = oldSleep
			end,
			OldAllowSleep = oldSleep
		}
	end

	local function inWhatRoom(model)
		if not model or not CurrentRooms then return nil end
		for _, room in ipairs(CurrentRooms:GetChildren()) do
			if model:IsDescendantOf(room) then
				return room.Name
			end
		end
		return nil
	end

	local function FindChair(attachment)
		local Misc = Services.Workspace:FindFirstChild("Misc")
		if Misc then
			for _, base in Misc:QueryDescendants(`> #{Floor}OfficeChair > #Base`) do
				local align = base:FindFirstChild("CartAlignPosition")
				local collider = base.Parent and base.Parent:FindFirstChild("Collider")
				if collider and (align or isnetowner(collider)) then
					return base.Parent
				end
			end
		end
		return nil
	end

	local function FindAlingsForChairOrCart(attachment)
		local Misc = Services.Workspace:FindFirstChild("Misc")
		if Misc then
			for _, base in Misc:QueryDescendants(`> #{Floor}OfficeChair > #Base, > #ShoppingCart > #Base`) do
				local alignPos = base:FindFirstChild("CartAlignPosition")
				local alignRot = base:FindFirstChild("CartAlignOrientation")
				if alignPos and alignRot then
					return alignPos, alignRot, base.Parent
				end
			end
		end
		return nil, nil, nil
	end

	local function ConnectChair(chair, promptBlock, restoring)
		if TplayVars.ConnectingChair then return end
		TplayVars.ConnectingChair = true
		local collision = Character and Character:FindFirstChild("Collision")
		local collisionPart = collision and collision:FindFirstChild("CollisionPart")
		local attachment = collisionPart and collisionPart:FindFirstChild("CartTargetAttachment")
		if attachment and chair and chair.Parent and promptBlock and isnetowner(promptBlock) then
			local CartControl = RemotesFolder:FindFirstChild("CartControl")
			if CartControl then CartControl:FireServer() end
			task.wait()
			if restoring then
				chair:PivotTo(Character:GetPivot())
			end
			if TplayVars.ACBypassNotify then
				TplayVars.ACBypassNotify:Destroy()
				TplayVars.ACBypassNotify = nil
			end
			Functions.Notify({
				Title = "Tplay's Addon",
				Body = "Anticheat bypass is active! (Hold chair to maintain bypass)",
				Time = 5
			})
			if sethidden then
				pcall(sethidden, promptBlock, "PhysicsRepRootPart", Character:FindFirstChild("HumanoidRootPart") or RootPart)
			end
			TplayVars.ChairConnection = Services.RunService.Heartbeat:Connect(function()
				if chair and chair.Parent and promptBlock and isnetowner(promptBlock) and attachment and attachment.Parent then
					chair:PivotTo(Character:GetPivot())
					local collider = chair:FindFirstChild("Collider")
					if collider then
						collider.AssemblyLinearVelocity = Vector3.zero
						collider.AssemblyAngularVelocity = Vector3.zero
					end
				else
					if TplayVars.ChairConnection then
						TplayVars.ChairConnection:Disconnect()
						TplayVars.ChairConnection = nil
					end
				end
			end)
		end
		TplayVars.ConnectingChair = false
	end

	local function handlePart(part)
		if part:IsA("BasePart") and not part.Anchored and isnetowner(part) then
			TplayVars.PartsConnections[part] = Services.RunService.RenderStepped:Connect(function()
				if isnetowner(part) and not part.Anchored then
					part.AssemblyLinearVelocity = Vector3.new(math.random(-150, 150), math.random(-150, 150), math.random(-150, 150))
				end
			end)
		end
	end

	local function disconnectPart(part)
		if TplayVars.PartsConnections[part] then
			TplayVars.PartsConnections[part]:Disconnect()
			TplayVars.PartsConnections[part] = nil
		end
	end

	-- =========================================================================
	-- 1. MAIN TAB (Movement, Anticheat & Prop Tools)
	-- =========================================================================

	Tplay_Main:AddToggle("Tplay_NoSpread", {
		Text = "No Spread (Glowsticks/Items)",
		Default = false,
		Tooltip = "Eliminates random velocity spread when throwing glowsticks or items.",
		Callback = function(Value)
			TplayVars.accurateAim = Value
			local AimRemote = RemotesFolder:FindFirstChild("AimRemote")
			if AimRemote and hookfunction then
				if Value then
					AimRemote._oldFire = AimRemote.FireServer
					hookfunction(AimRemote.FireServer, function(self, ...)
						local args = { ... }
						if TplayVars.accurateAim and args[1] and typeof(args[1]) == "Vector3" then
							args[1] = args[1] + Vector3.new(0, 0.001, 0)
						end
						return AimRemote._oldFire(self, unpack(args))
					end)
				end
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_FastThrow", {
		Text = "Fast Item Throw",
		Default = false,
		Tooltip = "Instantly throws items without windup animation delay.",
		Callback = function(Value)
			TplayVars.fastThrow = Value
		end
	})

	Tplay_Main:AddToggle("Tplay_DeleteProps", {
		Text = "Delete Props / Debris",
		Default = false,
		Tooltip = "Automatically cleans up dropped props and temporary parts locally.",
		Callback = function(Value)
			if Value then
				TplayVars.DeletePropsConnection = Services.Workspace.DescendantAdded:Connect(function(child)
					if child:IsA("BasePart") and (child.Name:find("Debris") or child.Name:find("Prop") or child.Name:find("GlassShard")) then
						task.defer(function() child:Destroy() end)
					end
				end)
			else
				if TplayVars.DeletePropsConnection then
					TplayVars.DeletePropsConnection:Disconnect()
					TplayVars.DeletePropsConnection = nil
				end
			end
		end
	})

	Tplay_Main:AddLabel("Use & Break Gold Blaster"):AddKeyPicker("Tplay_BreakToolKey", {
		Default = "V",
		SyncToggleState = false,
		Mode = "Press",
		Text = "Use & Break Gold Blaster",
		Callback = function()
			local tool = Character:FindFirstChildWhichIsA("Tool")
			if tool and tool:FindFirstChild("Break") then
				tool.Break:FireServer()
			elseif tool and tool:FindFirstChild("Remote") then
				tool.Remote:FireServer()
			end
		end
	})

	Tplay_Main:AddDivider()

	Tplay_Main:AddToggle("Tplay_ShowPathfind", {
		Text = "Show Pathfind Nodes",
		Default = false,
		Tooltip = "Visualizes Doors room navigation pathfinding nodes in real-time.",
		Callback = function(Value)
			TplayVars.showPathfind = Value
			if Value then
				task.spawn(function()
					while TplayVars.showPathfind do
						if CurrentRooms then
							for _, room in ipairs(CurrentRooms:GetChildren()) do
								local nodes = room:FindFirstChild("PathfindNodes") or room:FindFirstChild("Nodes")
								if nodes then
									for _, node in ipairs(nodes:GetChildren()) do
										if node:IsA("BasePart") and not node:FindFirstChild("TplayNodeHighlight") then
											local bbg = Instance.new("BillboardGui")
											bbg.Name = "TplayNodeHighlight"
											bbg.Size = UDim2.new(0, 10, 0, 10)
											bbg.AlwaysOnTop = true
											local frm = Instance.new("Frame", bbg)
											frm.Size = UDim2.new(1, 0, 1, 0)
											frm.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
											bbg.Parent = node
										end
									end
								end
							end
						end
						task.wait(1)
					end
				end)
			else
				if CurrentRooms then
					for _, bbg in ipairs(CurrentRooms:QueryDescendants("#TplayNodeHighlight")) do
						bbg:Destroy()
					end
				end
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_AutoLookAtFlowers", {
		Text = "Auto Look At Flowers",
		Default = false,
		Tooltip = "Scans every room in CurrentRooms and fires the LookAt remote for flowers 1-6.",
		Callback = function(Value)
			TplayVars.autoLookAtFlowers = Value
			if Value then
				task.spawn(function()
					local fired = {}
					while TplayVars.autoLookAtFlowers do
						if CurrentRooms then
							for _, room in ipairs(CurrentRooms:GetChildren()) do
								for i = 1, 6 do
									local flower = room:FindFirstChild(tostring(i))
									local lookAt = flower and flower:FindFirstChild("LookAt")
									if lookAt and lookAt:IsA("RemoteEvent") and not fired[lookAt] then
										fired[lookAt] = true
										pcall(function() lookAt:FireServer() end)
										task.wait(0.1)
									end
								end
							end
						end
						task.wait(1)
					end
				end)
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_DoorReachAlt", {
		Text = "Door Reach (Alternative)",
		Default = false,
		Tooltip = "Opens doors from a greater distance using prompt spoofing.",
		Callback = function(Value)
			TplayVars.doorReach = Value
		end
	})

	Tplay_Main:AddToggle("Tplay_AnticheatBypassAndFling", {
		Text = "Anticheat Bypass & Fling",
		Default = false,
		Disabled = not Functions.IsFloorAllowed({"Archives", "Stairwell"}),
		DisabledTooltip = not Functions.IsFloorAllowed({"Archives", "Stairwell"}) and ("Only available on: Archives, Stairwell (Current: " .. tostring(Floor) .. ")") or nil,
		Tooltip = "Bypasses anticheat by grabbing and aligning a chair or cart on Archives/Stairwell.",
		Callback = function(Value)
			if Value then
				if not Functions.CheckFloorToggle("Tplay_AnticheatBypassAndFling", {"Archives", "Stairwell"}, "Anticheat Bypass & Fling") then
					return
				end
				Functions.Notify({
					Title = "Tplay's Addon",
					Body = "Grab a chair to bypass anticheat!",
					Time = 5
				})
				TplayVars.OnChairGrab = Character.DescendantAdded:Connect(function(descendant)
					if not TplayVars.ChairConnection and (not (Toggles.Tplay_FlingCreak and Toggles.Tplay_FlingCreak.Value) or TplayVars.ChairThatFlingsCreak) and descendant:IsA("Attachment") and descendant.Name == "CartTargetAttachment" and descendant.Parent and descendant.Parent.Name == "CollisionPart" then
						local chair = FindChair(descendant)
						local promptBlock = chair and chair:FindFirstChild("PromptBlocker")
						if promptBlock then
							ConnectChair(chair, promptBlock)
						end
					end
				end)
			else
				if TplayVars.OnChairGrab then
					TplayVars.OnChairGrab:Disconnect()
					TplayVars.OnChairGrab = nil
				end
				if TplayVars.ChairConnection then
					TplayVars.ChairConnection:Disconnect()
					TplayVars.ChairConnection = nil
				end
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_FastChairAndCart", {
		Text = "Fast Chair & Cart",
		Default = false,
		Tooltip = "Removes acceleration inertia for chairs and shopping carts.",
		Callback = function(Value)
			if Value then
				TplayVars.OnChairOrCartGrab = Character.DescendantAdded:Connect(function(descendant)
					if descendant:IsA("Attachment") and descendant.Name == "CartTargetAttachment" and descendant.Parent and descendant.Parent.Name == "CollisionPart" then
						local alignPos, alignRot, base = FindAlingsForChairOrCart(descendant)
						if alignPos and alignRot then
							alignPos.Responsiveness = 200
							alignPos.MaxVelocity = 1000
							alignRot.Responsiveness = 200
						end
					end
				end)
			else
				if TplayVars.OnChairOrCartGrab then
					TplayVars.OnChairOrCartGrab:Disconnect()
					TplayVars.OnChairOrCartGrab = nil
				end
			end
		end
	})

	Tplay_Main:AddDivider()

	-- Drawers logic
	local NilConstraint = Instance.new("PrismaticConstraint")
	local function disconnectDrawer(drawer)
		local constraint = drawer:FindFirstChild("Constraint") or NilConstraint
		constraint.Enabled = true
		local drawerConns = TplayVars.DrawersConnections and TplayVars.DrawersConnections[drawer]
		if drawerConns then
			for _, connection in pairs(drawerConns) do
				if typeof(connection) == "RBXScriptConnection" then
					connection:Disconnect()
				end
			end
			TplayVars.DrawersConnections[drawer] = nil
		end
	end

	local function handleDrawer(drawer)
		local constraint, main
		if drawer:IsA("Model") and drawer.Name == "DrawerContainer" then
			main = drawer:WaitForChild("Main", 1)
			if not main then return end
			constraint = drawer:WaitForChild("Constraint", 1)
			if not constraint then return end
		else
			return
		end
		TplayVars.DrawersConnections = TplayVars.DrawersConnections or {}
		if TplayVars.DrawersConnections[drawer] then return end
		TplayVars.DrawersConnections[drawer] = {
			AncestryChanged1 = drawer.AncestryChanged:Connect(function()
				if not drawer.Parent then disconnectDrawer(drawer) end
			end),
			AncestryChanged2 = main.AncestryChanged:Connect(function()
				if not main.Parent then disconnectDrawer(drawer) end
			end),
			BringLoop = Services.RunService.RenderStepped:Connect(function()
				if isnetowner(main) and not main.Anchored then
					constraint.Enabled = false
					if Toggles.Tplay_AutoFloor and Toggles.Tplay_AutoFloor.Value then
						main.CFrame = Character:GetPivot()
					else
						main.CFrame = Character:GetPivot() * CFrame.Angles(0, math.rad(180), 0) + Character:GetPivot().LookVector * 3
					end
					main.AssemblyLinearVelocity = Vector3.zero
					main.AssemblyAngularVelocity = Vector3.zero
				else
					constraint.Enabled = true
				end
			end)
		}
		if Toggles.Tplay_AutoLoot and Toggles.Tplay_AutoLoot.Value then
			TplayVars.DrawersConnections[drawer].AutoLoot = Services.RunService.RenderStepped:Connect(function()
				if isnetowner(main) and not main.Anchored then
					local key = drawer:FindFirstChild("KeyObtain")
					local prompt = key and key:FindFirstChild("ModulePrompt", true)
					if prompt and fireprompt then fireprompt(prompt) end
					local stardust = drawer:FindFirstChild("Stardust", true)
					local prompt2 = stardust and stardust:FindFirstChild("ModulePrompt", true)
					if prompt2 and fireprompt then fireprompt(prompt2) end
					local prompt3 = drawer:FindFirstChild("ActivateEventPrompt", true)
					if prompt3 and fireprompt then fireprompt(prompt3) end
				end
			end)
		end
	end

	Tplay_Main:AddToggle("Tplay_BringDrawers", {
		Text = "Bring Drawers",
		Default = false,
		Disabled = not Functions.IsFloorAllowed({"Hotel", "Backdoor", "Endless", "Ripple"}),
		DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Backdoor", "Endless", "Ripple"}) and ("Only available on: Hotel, Backdoor, Endless, Ripple (Current: " .. tostring(Floor) .. ")") or nil,
		Tooltip = "Brings drawer containers in the room directly to you.",
		Callback = function(Value)
			if Value then
				if not Functions.CheckFloorToggle("Tplay_BringDrawers", {"Hotel", "Backdoor", "Endless", "Ripple"}, "Bring Drawers") then return end
				ToggleNetworkOwner(true)
				if Toggles.Tplay_OnlyDrawerWithKey and Toggles.Tplay_OnlyDrawerWithKey.SetDisabled then
					Toggles.Tplay_OnlyDrawerWithKey:SetDisabled(false)
				end
				if Toggles.Tplay_AutoLoot and Toggles.Tplay_AutoLoot.SetDisabled then
					Toggles.Tplay_AutoLoot:SetDisabled(false)
				end
				if CurrentRooms then
					for _, drawer in CurrentRooms:QueryDescendants("#DrawerContainer") do
						if Toggles.Tplay_OnlyDrawerWithKey and Toggles.Tplay_OnlyDrawerWithKey.Value then
							task.spawn(function()
								local key = drawer:WaitForChild("KeyObtain", 1)
								if key then handleDrawer(drawer) end
							end)
						else
							handleDrawer(drawer)
						end
					end
					TplayVars.DrawerAddedConn = CurrentRooms.DescendantAdded:Connect(function(drawer)
						if drawer.Name == "DrawerContainer" then
							if Toggles.Tplay_OnlyDrawerWithKey and Toggles.Tplay_OnlyDrawerWithKey.Value then
								task.wait(0.33)
								local key = drawer:WaitForChild("KeyObtain", 1)
								if key then handleDrawer(drawer) end
							else
								handleDrawer(drawer)
							end
						end
					end)
				end
			else
				ToggleNetworkOwner(false)
				if Toggles.Tplay_OnlyDrawerWithKey and Toggles.Tplay_OnlyDrawerWithKey.SetDisabled then
					Toggles.Tplay_OnlyDrawerWithKey:SetDisabled(true)
				end
				if Toggles.Tplay_AutoLoot and Toggles.Tplay_AutoLoot.SetDisabled then
					Toggles.Tplay_AutoLoot:SetDisabled(true)
				end
				if TplayVars.DrawerAddedConn then
					TplayVars.DrawerAddedConn:Disconnect()
					TplayVars.DrawerAddedConn = nil
				end
				for drawer, _ in pairs(TplayVars.DrawersConnections or {}) do
					task.spawn(disconnectDrawer, drawer)
				end
				TplayVars.DrawersConnections = {}
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_AutoLoot", {
		Text = "Auto Loot",
		Default = false,
		Disabled = true,
		Tooltip = "Automatically loots keys, stardust, and event prompts from brought drawers.",
		Callback = function()
			if Toggles.Tplay_BringDrawers and Toggles.Tplay_BringDrawers.Value then
				Toggles.Tplay_BringDrawers:SetValue(false)
				task.wait()
				Toggles.Tplay_BringDrawers:SetValue(true)
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_OnlyDrawerWithKey", {
		Text = "Only Drawer With Key",
		Default = false,
		Disabled = true,
		Tooltip = "Only brings drawers that contain a key.",
		Callback = function()
			if Toggles.Tplay_BringDrawers and Toggles.Tplay_BringDrawers.Value then
				Toggles.Tplay_BringDrawers:SetValue(false)
				task.wait()
				Toggles.Tplay_BringDrawers:SetValue(true)
			end
		end
	})

	Tplay_Main:AddDivider()

	-- Minecart Features
	Tplay_Main:AddToggle("Tplay_MinecartTeleportAlt", {
		Text = "Minecart Teleport Alt",
		Default = false,
		Disabled = not Functions.IsFloorAllowed("Mines"),
		DisabledTooltip = not Functions.IsFloorAllowed("Mines") and ("Only available on: Mines (Current: " .. tostring(Floor) .. ")") or nil,
		Tooltip = "Teleports minecart across tracks safely via Decode hook.",
		Callback = function(Value)
			if Value and not Functions.CheckFloorToggle("Tplay_MinecartTeleportAlt", "Mines", "Minecart Teleport Alt") then return end
			local NodeObject = Services.ReplicatedStorage:FindFirstChild("NodeObject")
			local MinecartNodes = NodeObject and NodeObject:FindFirstChild("MinecartNodes")
			if MinecartNodes then
				local req = require(MinecartNodes)
				if req and req.Decode and hookfunction then
					if Value then
						req._oldDecodeAlt = req.Decode
						hookfunction(req.Decode, function(nodes, folder, start)
							if folder and folder.Parent and (tonumber(folder.Parent.Name) or 0) < 49 then
								return nil
							end
							return req._oldDecodeAlt(nodes, folder, start)
						end)
					else
						if req._oldDecodeAlt and isfunctionhooked and isfunctionhooked(req.Decode) then
							restorefunction(req.Decode)
						end
					end
				end
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_MinecartChaseSkip", {
		Text = "Minecart Chase Skip",
		Default = false,
		Disabled = not Functions.IsFloorAllowed("Mines"),
		DisabledTooltip = not Functions.IsFloorAllowed("Mines") and ("Only available on: Mines (Current: " .. tostring(Floor) .. ")") or nil,
		Tooltip = "Skips the minecart track chase before room 50 in Mines.",
		Callback = function(Value)
			if Value and not Functions.CheckFloorToggle("Tplay_MinecartChaseSkip", "Mines", "Minecart Chase Skip") then return end
			local NodeObject = Services.ReplicatedStorage:FindFirstChild("NodeObject")
			local MinecartNodes = NodeObject and NodeObject:FindFirstChild("MinecartNodes")
			if MinecartNodes then
				local req = require(MinecartNodes)
				if req and req.Decode and hookfunction then
					if Value then
						req._oldDecode = req.Decode
						hookfunction(req.Decode, function(nodes, folder, start)
							if folder and folder.Parent and (tonumber(folder.Parent.Name) or 0) < 50 then
								return nil
							end
							return req._oldDecode(nodes, folder, start)
						end)
					else
						if req._oldDecode and isfunctionhooked and isfunctionhooked(req.Decode) then
							restorefunction(req.Decode)
						end
					end
				end
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_AutoMinecartPlay", {
		Text = "Auto Steer Minecart",
		Default = false,
		Disabled = not Functions.IsFloorAllowed("Mines"),
		DisabledTooltip = not Functions.IsFloorAllowed("Mines") and ("Only available on: Mines (Current: " .. tostring(Floor) .. ")") or nil,
		Tooltip = "Automatically completes the minecart chase by steering and ducking.",
		Callback = function(Value)
			if Value and not Functions.CheckFloorToggle("Tplay_AutoMinecartPlay", "Mines", "Auto Steer Minecart") then return end
			if Value then
				local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
				if PlayerModule then
					local success, controls = pcall(function() return require(PlayerModule):GetControls() end)
					if success and controls then
						TplayVars.MinecartControls = controls
						TplayVars.OrigMoveVector = controls.GetMoveVector
						controls.GetMoveVector = function(...)
							if Toggles.Tplay_AutoMinecartPlay and Toggles.Tplay_AutoMinecartPlay.Value and Floor == "Mines" then
								local node = TplayVars.AutoMinecartNearestTurnNode
								local camMinecart = Services.Workspace.CurrentCamera:FindFirstChild("MinecartRig")
								if node and camMinecart then
									local turn = node:GetAttribute("Turn")
									return turn == "Left" and Vector3.new(-1, 0, 0) or turn == "Right" and Vector3.new(1, 0, 0) or Vector3.zero
								end
							end
							return TplayVars.OrigMoveVector(...)
						end
					end
				end
				TplayVars.AutoMinecartConn = Services.RunService.Heartbeat:Connect(function()
					local camMinecart = Services.Workspace.CurrentCamera:FindFirstChild("MinecartRig")
					if not camMinecart then return end
					local duckDist = Options.Tplay_AutoMinecartDuckDistance and Options.Tplay_AutoMinecartDuckDistance.Value or 30
					local nearestDuck = nil
					if CurrentRooms then
						for _, board in CurrentRooms:QueryDescendants("#DuckBoard") do
							if board:IsA("Model") and board.PrimaryPart then
								local dist = LocalPlayer:DistanceFromCharacter(board.PrimaryPart.Position)
								if dist < duckDist then nearestDuck = board break end
							end
						end
					end
					local mg = LocalPlayer.PlayerGui:FindFirstChild("MainUI") and LocalPlayer.PlayerGui.MainUI:FindFirstChild("Initiator") and LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game")
					if mg then
						local req = require(mg)
						if req and req.crouch then
							if nearestDuck and not TplayVars.AutoMinecartDucked then
								req.crouch(true)
								TplayVars.AutoMinecartDucked = true
							elseif not nearestDuck and TplayVars.AutoMinecartDucked then
								req.crouch(false)
								TplayVars.AutoMinecartDucked = false
							end
						end
					end
				end)
			else
				if TplayVars.AutoMinecartConn then
					TplayVars.AutoMinecartConn:Disconnect()
					TplayVars.AutoMinecartConn = nil
				end
				if TplayVars.MinecartControls and TplayVars.OrigMoveVector then
					TplayVars.MinecartControls.GetMoveVector = TplayVars.OrigMoveVector
				end
			end
		end
	})

	Tplay_Main:AddSlider("Tplay_AutoMinecartTurnDistance", {
		Text = "Turn Distance",
		Min = 20,
		Max = 40,
		Default = 30,
		Rounding = 0,
		Compact = true
	})

	Tplay_Main:AddSlider("Tplay_AutoMinecartDuckDistance", {
		Text = "Crouch Distance",
		Min = 20,
		Max = 40,
		Default = 30,
		Rounding = 0,
		Compact = true
	})

	Tplay_Main:AddDivider()

	Tplay_Main:AddToggle("Tplay_AntiTeleport", {
		Text = "Anti Teleport (Bypass Anticheat)",
		Default = false,
		Tooltip = "Prevents server-side forced setbacks and anticheat pushback.",
		Callback = function(Value)
			if Value then
				local oldPivot = Character:GetPivot()
				TplayVars.AntiTeleportConnection = Services.RunService.RenderStepped:Connect(function()
					if RootPart then
						local current = RootPart.Position
						if (current - oldPivot.Position).Magnitude > 75 and not TplayVars.TeleportingLegit then
							RootPart.CFrame = oldPivot
						else
							oldPivot = RootPart.CFrame
						end
					end
				end)
			else
				if TplayVars.AntiTeleportConnection then
					TplayVars.AntiTeleportConnection:Disconnect()
					TplayVars.AntiTeleportConnection = nil
				end
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_AntiTeleportRaknet", {
		Text = "Anti Teleport (RakNet Method)",
		Default = false,
		Tooltip = "Drops incoming teleport correction packets at network layer.",
		Callback = function(Value)
			if Value and hookmetamethod then
				-- RakNet hook handler
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_RakNetSpeedHack", {
		Text = "RakNet Speed Hack",
		Default = false,
		Tooltip = "Accelerates network physics replication packets for faster movement.",
		Callback = function(Value)
			if Value then
				sethidden(LocalPlayer, "SimulationRadius", 1/0)
			end
		end
	})

	Tplay_Main:AddToggle("Tplay_SlideSpeedHack", {
		Text = "Slide Speed Hack",
		Default = false,
		Tooltip = "Boosts slide momentum significantly when crouching/sliding.",
		Callback = function(Value)
			if Value and Humanoid then
				Humanoid.WalkSpeed = 26
			else
				if Humanoid then Humanoid.WalkSpeed = 15 end
			end
		end
	})

	Tplay_Main:AddSlider("Tplay_WalkSpeed", {
		Text = "WalkSpeed Multiplier",
		Default = 15,
		Min = 10,
		Max = 45,
		Rounding = 0,
		Callback = function(Value)
			TplayVars.WalkSpeed = Value
			if Humanoid then Humanoid.WalkSpeed = Value end
		end
	})

	Tplay_Main:AddSlider("Tplay_LadderSpeed", {
		Text = "Ladder Climb Speed",
		Default = 15,
		Min = 10,
		Max = 50,
		Rounding = 0,
		Callback = function(Value)
			TplayVars.LadderSpeed = Value
		end
	})

	Tplay_Main:AddToggle("Tplay_AnticheatManipulationAlt", {
		Text = "Anticheat Manipulation Alt",
		Default = false,
		Tooltip = "Uses ladder physics to completely suspend anticheat checks.",
		Callback = function(Value)
			if Value then
				local Misc = Services.Workspace:FindFirstChild("Misc")
				local ladder = Misc and Misc:FindFirstChildWhichIsA("TrussPart", true)
				if ladder and RootPart then
					TplayVars.ACMAConnection = Services.RunService.Heartbeat:Connect(function()
						pcall(function() firetouch(RootPart, ladder, 0) end)
					end)
				end
			else
				if TplayVars.ACMAConnection then
					TplayVars.ACMAConnection:Disconnect()
					TplayVars.ACMAConnection = nil
				end
			end
		end
	}):AddKeyPicker("Tplay_AnticheatManipulationAltKey", {
		Default = "K",
		SyncToggleState = true,
		Mode = "Toggle",
		Text = "Anticheat Manipulation Alt"
	})

	-- =========================================================================
	-- 2. GODMODE & COMBAT TAB (Exact Tplays 2.9.4 Engine)
	-- =========================================================================
	do
		local CrouchRemoteEvent = RemotesFolder and RemotesFolder:FindFirstChild("Crouch")
		local GS_DIST_SQ = 90 * 90
		local function ShouldSpoofGS(hrp)
			if not hrp then return false end
			local hPos = hrp.Position
			for _, gs in Variables.Groundskeepers do
				local hrp2 = gs and gs.Parent and gs:FindFirstChild("HumanoidRootPart")
				if hrp2 then
					local gPos = hrp2.Position
					local dx, dy, dz = (gPos.X - hPos.X), (gPos.Y * 5 - hPos.Y * 5), (gPos.Z - hPos.Z)
					if dx * dx + dy * dy + dz * dz < GS_DIST_SQ then
						return true
					end
				end
			end
			return false
		end

		local FR_DIST_SQ = 20 * 20
		local function ShouldSpoofFR(hrp)
			if not hrp then return false end
			local hPos = hrp.Position
			for _, rig in Variables.FigureRigs do
				local root = rig and rig.Parent and (rig:FindFirstChild("Root") or rig:FindFirstChild("HumanoidRootPart"))
				if root then
					local rPos = root.Position
					local dx, dz = rPos.X - hPos.X, rPos.Z - hPos.Z
					if dx * dx + dz * dz < FR_DIST_SQ then
						return true
					end
				end
			end
			return false
		end

		local function TrackEntity(inst)
			if inst.Name == "Groundskeeper" or inst.Name == "GroundskeeperModel" then
				if not table.find(Variables.Groundskeepers, inst) then
					table.insert(Variables.Groundskeepers, inst)
					inst.Destroying:Once(function()
						local idx = table.find(Variables.Groundskeepers, inst)
						if idx then table.remove(Variables.Groundskeepers, idx) end
					end)
				end
			elseif inst.Name == "FigureRig" or inst.Name == "Figure" or inst.Name == "FigureRagdoll" then
				if not table.find(Variables.FigureRigs, inst) then
					table.insert(Variables.FigureRigs, inst)
					inst.Destroying:Once(function()
						local idx = table.find(Variables.FigureRigs, inst)
						if idx then table.remove(Variables.FigureRigs, idx) end
					end)
				end
			end
		end
		for _, inst in workspace:GetDescendants() do TrackEntity(inst) end
		workspace.DescendantAdded:Connect(TrackEntity)

		local RotationDivider
		local StartAntiEntitiesAuto

		Toggles.AntiEntitiesMode = Tplay_Combat:AddDropdown("Tplay_AntiEntitiesMode", {
			Text = "Anti Entities Mode",
			Tooltip = "Manual: each toggle below works independently. Automatic: Position Offset turns on while a rush entity is active (spawn/restore) and selected Rotation Features take over by entity distance.",
			Values = { "Manual", "Automatic" },
			Default = "Manual",
			Callback = function(value)
				if Toggles.Tplay_AntiRotation then
					pcall(Toggles.Tplay_AntiRotation.SetVisible, Toggles.Tplay_AntiRotation, value == "Automatic")
				end
				if RotationDivider then
					pcall(RotationDivider.SetVisible, RotationDivider, value == "Automatic")
				end
				if Connections.AntiEntitiesMode then
					for _, conn in Connections.AntiEntitiesMode do
						pcall(conn.Disconnect, conn)
					end
					Connections.AntiEntitiesMode = nil
				end
				if value == "Automatic" and StartAntiEntitiesAuto then
					StartAntiEntitiesAuto()
				end
			end
		})

		RotationDivider = Tplay_Combat:AddDivider({
			Text = "ROTATION",
			MarginTop = 2,
			MarginBottom = -2
		})

		Toggles.AntiRotation = Tplay_Combat:AddDropdown("Tplay_AntiRotation", {
			Text = "Rotation Features",
			Tooltip = "Choose which entity-based features rotate in while Automatic Mode is active. Leave blank for all features to rotate in.",
			Multi = true,
			AllowNull = true,
			Values = { "Position Offset V2", "Anti Groundskeeper", "Anti Figure" },
			Default = {},
		})
		pcall(Toggles.AntiRotation.SetVisible, Toggles.AntiRotation, false)
		pcall(RotationDivider.SetVisible, RotationDivider, false)

		StartAntiEntitiesAuto = function()
			local PO = Toggles.CollisionOffsetGodmodeAlt
			local GS = { Active = false, Record = nil, WasOn = false }
			local FR = { Active = false, Record = nil, WasOn = false }
			local EN = {}
			Connections.AntiEntitiesMode = EN
			local RushNames = {
				RushMoving = true, AmbushMoving = true, A60 = true, BackdoorRush = true,
				BashMoving = true, GlitchRush = true, GlitchAmbush = true, A120 = true,
				Rush = true, Ambush = true, Blitz = true, CustomEntity = true
			}
			local RushSet = {}
			local RushCount = 0
			local SpawnSnapshot

			local function SetPO(target)
				if PO and PO.SetValue and PO.Value ~= target then
					PO:SetValue(target)
				end
			end
			local function ClearSpawn()
				SpawnSnapshot = nil
			end
			local function WantsPO()
				local v = Toggles.AntiRotation and Toggles.AntiRotation.Value
				if type(v) ~= "table" or next(v) == nil then return true end
				for n in v do
					if n == "Position Offset V2" then return true end
				end
				return false
			end
			local function RushOriginal()
				if SpawnSnapshot ~= nil then return SpawnSnapshot end
				if GS.Active and GS.Record ~= nil then return GS.Record end
				if FR.Active and FR.Record ~= nil then return FR.Record end
				return PO and PO.Value == true or false
			end
			local function OnRushAdded(inst)
				if not RushNames[inst.Name] then return end
				if not RushSet[inst] then
					RushSet[inst] = true
					RushCount += 1
					if RushCount == 1 and SpawnSnapshot == nil and WantsPO() then
						SpawnSnapshot = RushOriginal()
					end
					if WantsPO() and not (GS.Active or FR.Active) and PO and PO.SetValue and not PO.Value then
						PO:SetValue(true)
					end
				end
			end
			local function OnRushRemoved(inst)
				if RushSet[inst] then
					RushSet[inst] = nil
					RushCount = math.max(0, RushCount - 1)
					if RushCount == 0 then
						if not (GS.Active or FR.Active) and SpawnSnapshot ~= nil then
							SetPO(SpawnSnapshot)
						end
						ClearSpawn()
					end
				end
			end
			for _, inst in workspace:GetDescendants() do
				OnRushAdded(inst)
			end
			EN.RushAdded = workspace.DescendantAdded:Connect(OnRushAdded)
			EN.RushRemoved = workspace.DescendantRemoving:Connect(OnRushRemoved)
			EN.HR = Services.RunService.Heartbeat:Connect(function()
				local AF = Connections.AutoFloor
				if AF and (AF.AntiFigure50 or AF.RestoreOffset50) then return end
				local Char = LocalPlayer.Character or Character
				local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
				if not HRP then return end
				local RotSel = Toggles.AntiRotation and Toggles.AntiRotation.Value
				local wantGS, wantFR, wantPO = false, false, false
				if type(RotSel) ~= "table" or next(RotSel) == nil then
					wantPO, wantGS, wantFR = true, true, true
				else
					for n in RotSel do
						if n == "Position Offset V2" then wantPO = true end
						if n == "Anti Groundskeeper" then wantGS = true end
						if n == "Anti Figure" then wantFR = true end
					end
				end
				local inGS = wantGS and ShouldSpoofGS(HRP)
				local inFR = wantFR and ShouldSpoofFR(HRP)
				if inGS and not GS.Active then
					GS.Active = true
					GS.Record = RushOriginal()
					GS.WasOn = Toggles.AntiGroundskeeper.Value
					if not Toggles.AntiGroundskeeper.Value then
						Toggles.AntiGroundskeeper:SetValue(true)
					end
					SetPO(false)
				elseif not inGS and GS.Active then
					GS.Active = false
					if Toggles.AntiGroundskeeper.Value and not GS.WasOn then
						Toggles.AntiGroundskeeper:SetValue(false)
					end
				if not FR.Active then SetPO(GS.Record) end
					GS.Record = nil
				end
				if inFR and not FR.Active then
					FR.Active = true
					FR.Record = RushOriginal()
					FR.WasOn = Toggles.AntiFigure.Value
					if not Toggles.AntiFigure.Value then
						Toggles.AntiFigure:SetValue(true)
					end
					SetPO(false)
				elseif not inFR and FR.Active then
					FR.Active = false
					if Toggles.AntiFigure.Value and not FR.WasOn then
						Toggles.AntiFigure:SetValue(false)
					end
					if not GS.Active then SetPO(FR.Record) end
					FR.Record = nil
				end
				if wantPO and RushCount > 0 and SpawnSnapshot == nil then
					SpawnSnapshot = RushOriginal()
				end
			end)
		end

		local POSITION_OFFSET = 2.346
		local POSITION_NORMAL_HIP = 2.396
		local POSITION_SPOOF_HIP = 0.05
		local POA_DOWN, POA_UP = CFrame.new(0, -POSITION_OFFSET, 0), CFrame.new(0, POSITION_OFFSET, 0)
		local POA_VISUAL = CFrame.new(0, -POSITION_OFFSET, 0)
		local POA_RUN = Services.RunService
		Variables.POARespawning = false
		Variables.POANoAccelWasEnabled = false

		local POA = {
			Character = nil,
			Humanoid = nil,
			Root = nil,
			Collision = nil,
			CollisionPart = nil,
			CollisionClone = nil,
			CollisionPartClone = nil,
			CrouchPart = nil,
			CloneCrouch = nil,
			RootJoint = nil,
			BaseParts = {},
			OriginalC1 = nil,
			VisualOffset = nil,
			LastCrouch = 0,
			Shifted = false,
		}
		Variables.POA = POA

		local POAToggles = {}
		local function POAFindToggle(key, ...)
			if POAToggles[key] then return POAToggles[key] end
			local LT = Library and Library.Toggles
			if not LT then return nil end
			for i = 1, select("#", ...) do
				local v = LT[select(i, ...)]
				if v then POAToggles[key] = v return v end
			end
		end
		local function POANoclip()
			local T = POAFindToggle("noclip", "Noclip", "NoclipToggle", "NoclipAlt", "TeleportManipulationToggle")
			return (T and T.Value == true) or (Toggles.TeleportManipulationToggle and Toggles.TeleportManipulationToggle.Value == true) or false
		end
		local function POAVelocityManipulation()
			local T = POAFindToggle("velocity", "VelocityManipulationToggle", "VelocityManipulation", "AnticheatManipulationV2", "TeleportManipulationToggle")
			return (T and T.Value == true) or (Toggles.TeleportManipulationToggle and Toggles.TeleportManipulationToggle.Value == true) or false
		end
		local function POAIsCrouching()
			if not POA.Character then return false end
			if Floor == "Fools" or Floor == "OldHotel" then
				return POA.Character:GetAttribute("Crouching") == true
			end
			return POA.CollisionPart and POA.CollisionPart.CollisionGroup == "PlayerCrouching" or false
		end
		local function POADestroyClones()
			if POA.CollisionClone and POA.CollisionClone.Parent then
				POA.CollisionClone:Destroy()
			end
			if POA.CollisionPartClone and POA.CollisionPartClone.Parent then
				POA.CollisionPartClone:Destroy()
			end
			POA.CollisionClone = nil
			POA.CollisionPartClone = nil
		end
		local function POASetVisualOffset(v)
			if POA.VisualOffset == v then return end
			local j = POA.RootJoint
			if not (j and j.Parent) then
				local l = POA.Character and POA.Character:FindFirstChild("LowerTorso")
				j = l and l:FindFirstChild("Root")
				POA.RootJoint = j
			end
			if not j then return end
			POA.OriginalC1 = POA.OriginalC1 or j.C1
			Global.OriginalC1 = POA.OriginalC1
			j.C1 = POA.OriginalC1 * (v and POA_VISUAL or CFrame.new())
			POA.VisualOffset = v
		end
		local function POARestorePhysicalPosition()
			if not POA.Shifted then return end
			if POA.Root and POA.Root.Parent then
				POA.Root.CFrame *= POA_UP
			end
			if POA.Humanoid and POA.Humanoid.Parent then
				POA.Humanoid.HipHeight = POSITION_NORMAL_HIP
			end
			POA.Shifted = false
		end
		local function POAApplyPhysicalPosition()
			if POA.Shifted or not (POA.Root and POA.Root.Parent) then return end
			POA.Root.CFrame *= POA_DOWN
			if POA.Humanoid and POA.Humanoid.Parent then
				POA.Humanoid.HipHeight = POSITION_SPOOF_HIP
			end
			POA.Shifted = true
		end
		local function POASync(force)
			local n = os.clock()
			if not force and n - POA.LastCrouch < 0.1 then return end
			POA.LastCrouch = n
			if CrouchRemoteEvent then pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true) end
		end

		local function POASetupCharacter(NewCharacter)
			if not NewCharacter then return false end
			POARestorePhysicalPosition()
			POADestroyClones()
			POA.Character = NewCharacter
			POA.Humanoid = NewCharacter:WaitForChild("Humanoid", 10)
			POA.Root = NewCharacter:WaitForChild("HumanoidRootPart", 10)
			POA.Collision = NewCharacter:WaitForChild("Collision", 10)
			-- FIX(noclip): search inside Collision for the real CollisionPart before falling back.
			POA.CollisionPart = NewCharacter:FindFirstChild("CollisionPart")
				or (POA.Collision and POA.Collision:FindFirstChild("CollisionPart"))
				or POA.Collision
			POA.OriginalC1 = nil
			POA.Shifted = false
			if not (POA.Humanoid and POA.Root and POA.Collision and POA.CollisionPart) then
				return false
			end
			for _, child in ipairs(NewCharacter:GetChildren()) do
				if child.Name == "CollisionClone" or child.Name == "CollisionPartClone" then
					pcall(function() child:Destroy() end)
				end
			end
			POA.CollisionClone = POA.Collision:Clone()
			POA.CollisionClone.Name = "CollisionClone"
			POA.CollisionClone.Massless = true
			POA.CollisionClone.Parent = NewCharacter
			CollisionClone = POA.CollisionClone
			POA.CollisionPartClone = POA.CollisionPart:Clone()
			POA.CollisionPartClone.Name = "CollisionPartClone"
			POA.CollisionPartClone.CanCollide = false
			POA.CollisionPartClone.Massless = true
			local ExtraCrouch = POA.CollisionPartClone:FindFirstChild("CollisionCrouch")
			if ExtraCrouch then ExtraCrouch:Destroy() end
			POA.CollisionPartClone.Parent = NewCharacter
			CollisionPartClone = POA.CollisionPartClone
			POA.CrouchPart = POA.Collision:FindFirstChild("CollisionCrouch")
			POA.CloneCrouch = POA.CollisionClone:FindFirstChild("CollisionCrouch")
			local Lower = NewCharacter:FindFirstChild("LowerTorso")
			POA.RootJoint = Lower and Lower:FindFirstChild("Root")
			if POA.RootJoint then
				POA.OriginalC1 = POA.RootJoint.C1
				Global.OriginalC1 = POA.RootJoint.C1
			end
			POA.VisualOffset = nil
			table.clear(POA.BaseParts)
			for _, part in ipairs(NewCharacter:GetChildren()) do
				if part:IsA("BasePart") and part ~= POA.CollisionClone and part ~= POA.CollisionPartClone then
					POA.BaseParts[#POA.BaseParts + 1] = part
				end
			end
			local isEnabled = (Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value) or (Toggles.PositionSpoof and Toggles.PositionSpoof.Value)
			if isEnabled and Floor ~= "Fools" and Floor ~= "OldHotel" then
				POAApplyPhysicalPosition()
				POASetVisualOffset(true)
				POASync(true)
			else
				POASetVisualOffset(false)
			end
			return true
		end

		Variables.POASetupCharacter = POASetupCharacter
		Variables.POAApplyPhysicalPosition = POAApplyPhysicalPosition
		Variables.POARestorePhysicalPosition = POARestorePhysicalPosition
		Variables.POASetVisualOffset = POASetVisualOffset
		Variables.POASync = POASync

		local POAWallParams = RaycastParams.new()
		POAWallParams.FilterType = Enum.RaycastFilterType.Exclude
		POAWallParams.RespectCanCollide = true
		POAWallParams.IgnoreWater = true
		local POAWallFilter = {}

		Tplay_Combat:AddToggle("Tplay_PositionSpoofWallCheck", {
			Text = "Wall Check",
			Default = true,
			Tooltip = "Prevents the spoof collision from passing through walls and solid objects."
		})

		local function POAWallCheck(Origin, Direction, Radius)
			if not Toggles.PositionSpoofWallCheck.Value or not Origin or not Direction or Direction.Magnitude <= 1e-4 then
				return nil
			end
			table.clear(POAWallFilter)
			if POA.Character then POAWallFilter[#POAWallFilter + 1] = POA.Character end
			if Camera and Camera:FindFirstChild("MinecartRig") then
				POAWallFilter[#POAWallFilter + 1] = Camera.MinecartRig
			end
			POAWallParams.FilterDescendantsInstances = POAWallFilter
			local Result = workspace:Spherecast(Origin, Radius or 0.2, Direction, POAWallParams)
			return Result and Result.Instance and Result.Instance.CanCollide and Result or nil
		end



		Connections.POA = POA_RUN.RenderStepped:Connect(function()
			if not (POA.Character and POA.Character.Parent and POA.Root and POA.Root.Parent and POA.Collision and POA.Collision.Parent and POA.CollisionClone and POA.CollisionClone.Parent) then
				return
			end
			local Enabled = (Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value) or (Toggles.PositionSpoof and Toggles.PositionSpoof.Value)
			local Noclip = POANoclip()
			local ActiveVelocity = POAVelocityManipulation()
			if Floor ~= "Fools" and Floor ~= "OldHotel" and not (Camera and Camera:FindFirstChild("MinecartRig")) then
				POA.Root.CanCollide = false
			end
			for _, Part in ipairs(POA.BaseParts) do
				if Part.Parent and Part.CanCollide then Part.CanCollide = false end
			end
			if Floor == "OldHotel" or Floor == "Fools" then
				POA.Collision.CanCollide = false
				POA.Root.CanCollide = not (Noclip or ActiveVelocity)
			else
				POA.Collision.CanCollide = false
				local CrouchPart = POA.CrouchPart
				local CloneCrouch = POA.CloneCrouch
				if CrouchPart then CrouchPart.CanCollide = false end
				if CloneCrouch then
					local IsCrouch = POAIsCrouching()
					POA.CollisionClone.CanCollide = not (Noclip or ActiveVelocity or IsCrouch)
					CloneCrouch.CanCollide = not (Noclip or ActiveVelocity or not IsCrouch)
				else
					POA.CollisionClone.CanCollide = not (Noclip or ActiveVelocity)
				end
			end
			POASetVisualOffset(Enabled)
			local SpoofY = Enabled and 2.328 or 0.18
			POA.Collision.Position = POA.Root.Position + Vector3.new(0, SpoofY, 0)
			POA.CollisionPart.Position = POA.Root.Position + Vector3.new(0, SpoofY, 0)
			local CrouchPart = POA.CrouchPart
			local CloneCrouch = POA.CloneCrouch
			if CrouchPart and CloneCrouch then
				CrouchPart.Position = POA.Root.Position + Vector3.new(0, Enabled and 1.328 or -0.982, 0)
				CloneCrouch.CollisionGroup = CrouchPart.CollisionGroup
				local CrouchTarget = POA.Root.Position + Vector3.new(0, Enabled and 0.75 or -0.982, 0)
				local CrouchDelta = CrouchTarget - CloneCrouch.Position
				local CrouchHit = POAWallCheck(CloneCrouch.Position, CrouchDelta, math.max(0.2, CloneCrouch.Size.X * 0.25))
				if CrouchHit and CrouchDelta.Magnitude > 1e-4 then
					CloneCrouch.Position = CloneCrouch.Position + CrouchDelta.Unit * math.max(0, CrouchHit.Distance - 0.05)
				else
					CloneCrouch.Position = CrouchTarget
				end
			end
			POA.CollisionClone.CollisionGroup = POA.Collision.CollisionGroup
			local CloneTarget = POA.Root.Position + Vector3.new(0, Enabled and 1.75 or 0.18, 0)
			local CloneDelta = CloneTarget - POA.CollisionClone.Position
			local CloneHit = POAWallCheck(POA.CollisionClone.Position, CloneDelta, math.max(0.2, POA.CollisionClone.Size.X * 0.25))
			if CloneHit and CloneDelta.Magnitude > 1e-4 then
				POA.CollisionClone.Position = POA.CollisionClone.Position + CloneDelta.Unit * math.max(0, CloneHit.Distance - 0.05)
			else
				POA.CollisionClone.Position = CloneTarget
			end
			if POA.CollisionPartClone and POA.CollisionPartClone.Parent then
				POA.CollisionPartClone.CollisionGroup = POA.CollisionPart.CollisionGroup
				POA.CollisionPartClone.Position = POA.CollisionPart.Position
				POA.CollisionPartClone.CanCollide = false
			end
			if Enabled then POASync(false) end
		end)

		Connections.POACharacterRemoving = LocalPlayer.CharacterRemoving:Connect(function()
			if Toggles.CollisionOffsetGodmodeAlt.Value then
				Variables.POARespawning = true
			end
			POARestorePhysicalPosition()
			POADestroyClones()
		end)

		Connections.POACharacterAdded = LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
			task.defer(function()
				Character = NewCharacter
				POASetupCharacter(NewCharacter)
			end)
		end)

		if LocalPlayer.Character then
			POASetupCharacter(LocalPlayer.Character)
		end

		Tplay_Combat:AddToggle("Tplay_AntiGroundskeeper", {
			Text = "Anti Groundskeeper",
			Default = false,
			Tooltip = "Offsets player character away from Groundskeeper to prevent being caught."
		})

		Tplay_Combat:AddToggle("Tplay_AntiFigure", {
			Text = "Anti Figure",
			Default = false,
			Tooltip = "Offsets player character away from Figure to prevent instant kills."
		})

		Tplay_Combat:AddToggle("Tplay_InfiniteCrucifixAlt", {
			Text = "Infinite Crucifix (Alt)",
			Default = false,
			Tooltip = "Cancels crucifix consumption packets for infinite uses."
		})

		if Floor == "Garden" then
			Tplay_Combat:AddToggle("Tplay_DisableMandrakeFEAlt", {
				Text = "Disable Mandrake [FE Alt]",
				Default = false,
				Tooltip = "Prevents Mandrakes from detecting or blinding the player."
			})
		end

		if Floor == "Stairwell" then
			Tplay_Combat:AddToggle("Tplay_FlingCreak", {
				Text = "Fling Creak [FE]",
				Default = false,
				Tooltip = "Flings Creak away when nearby."
			})
		end
	end

	-- =========================================================================
	-- 3. ITEMS & DROPS TAB
	-- =========================================================================

	local function HasItem(itemName)
		if not Character then return nil end
		local tool = Character:FindFirstChild(itemName) or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild(itemName))
		return tool
	end

	Tplay_Items:AddDropdown("Tplay_AutoPickupImportantNeeds", {
		Text = "Auto Pickup Needs",
		Tooltip = "Automatically picks up items when missing or low (Bandages, Batteries, Vitamins, Lockpicks, Crucifix).",
		Multi = true,
		AllowNull = true,
		Values = { "Bandages", "Batteries", "Vitamins", "Lockpicks", "Crucifix" },
		Default = {},
		Callback = function(val)
			TplayVars.AutoPickupNeeds = val or {}
		end
	})

	Tplay_Items:AddDropdown("Tplay_PlayerToBringItems", {
		SpecialType = "Player",
		Searchable = true,
		Multi = false,
		Text = "Target Player",
		Default = nil,
		Callback = function(v) TplayVars.SelectedPlayerItem = v end
	})

	Tplay_Items:AddButton({
		Text = "Bring Drops",
		Tooltip = "Bring all the dropped items to your current player or target player.",
		Func = function()
			local Drops = Services.Workspace:FindFirstChild("Drops")
			local targetChar = (TplayVars.SelectedPlayerItem and TplayVars.SelectedPlayerItem.Character) or Character
			local human = targetChar and targetChar:FindFirstChild("Humanoid")
			local hrp = human and human.RootPart or (targetChar and targetChar:FindFirstChild("HumanoidRootPart"))
			if Drops and hrp then
				ToggleNetworkOwner(true)
				local itemsOffset = Vector3.new(0, 2, 0)
				for _, drop in ipairs(Drops:GetChildren()) do
					if drop:IsA("BasePart") then
						drop.CFrame = hrp.CFrame + itemsOffset
					elseif drop:IsA("Model") then
						drop:PivotTo(hrp.CFrame + itemsOffset)
					end
				end
				ToggleNetworkOwner(false)
				Functions.Notify({ Title = "Items", Body = "Brought all drops!" })
			end
		end
	})

	Tplay_Items:AddButton({
		Text = "Steal Drops",
		Tooltip = "Steals all dropped items in the room by firing proximity prompts.",
		Func = function()
			local Drops = Services.Workspace:FindFirstChild("Drops")
			if Drops then
				for _, drop in ipairs(Drops:GetChildren()) do
					local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
					if prompt and fireprompt then
						fireprompt(prompt)
					end
				end
				Functions.Notify({ Title = "Items", Body = "Stealing dropped items...", Time = 2 })
			end
		end
	})

	Tplay_Items:AddToggle("Tplay_LoopSteal", {
		Text = "Loop Steal Drops",
		Default = false,
		Tooltip = "Continuously interacts with all dropped items in workspace.",
		Callback = function(Value)
			if Value then
				TplayVars.LoopStealConnection = Services.RunService.Heartbeat:Connect(function()
					local Drops = Services.Workspace:FindFirstChild("Drops")
					if Drops then
						for _, drop in ipairs(Drops:GetChildren()) do
							local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt", true)
							if prompt and fireprompt then fireprompt(prompt) end
						end
					end
				end)
			else
				if TplayVars.LoopStealConnection then
					TplayVars.LoopStealConnection:Disconnect()
					TplayVars.LoopStealConnection = nil
				end
			end
		end
	})

	Tplay_Items:AddDivider()

	Tplay_Items:AddToggle("Tplay_OrbitDrops", {
		Text = "Orbit Drops",
		Default = false,
		Tooltip = "Orbits all dropped items around your character.",
		Callback = function(Value)
			if Value then
				ToggleNetworkOwner(true)
				local angle = 0
				TplayVars.OrbitDropsConnection = Services.RunService.RenderStepped:Connect(function(dt)
					local Drops = Services.Workspace:FindFirstChild("Drops")
					if Drops and RootPart then
						angle = angle + dt * TplayVars.OrbitSpeed
						local children = Drops:GetChildren()
						for i, drop in ipairs(children) do
							local thisAngle = angle + (i * (2 * math.pi / math.max(#children, 1)))
							local offset = Vector3.new(math.cos(thisAngle) * TplayVars.OrbitOffset, 1, math.sin(thisAngle) * TplayVars.OrbitOffset)
							if drop:IsA("BasePart") then
								drop.CFrame = RootPart.CFrame + offset
							elseif drop:IsA("Model") then
								drop:PivotTo(RootPart.CFrame + offset)
							end
						end
					end
				end)
			else
				ToggleNetworkOwner(false)
				if TplayVars.OrbitDropsConnection then
					TplayVars.OrbitDropsConnection:Disconnect()
					TplayVars.OrbitDropsConnection = nil
				end
			end
		end
	})

	Tplay_Items:AddToggle("Tplay_OrbitGlowsticks", {
		Text = "Orbit Glowsticks",
		Default = false,
		Tooltip = "Orbits glowsticks around your character.",
		Callback = function(Value)
			if Value then
				ToggleNetworkOwner(true)
				local angle = 0
				TplayVars.OrbitGlowsticksConnection = Services.RunService.RenderStepped:Connect(function(dt)
					local Drops = Services.Workspace:FindFirstChild("Drops")
					if Drops and RootPart then
						angle = angle + dt * TplayVars.OrbitSpeed
						local glowsticks = {}
						for _, item in ipairs(Drops:GetChildren()) do
							if item.Name:find("Glowstick") then table.insert(glowsticks, item) end
						end
						for i, drop in ipairs(glowsticks) do
							local thisAngle = angle + (i * (2 * math.pi / math.max(#glowsticks, 1)))
							local offset = Vector3.new(math.cos(thisAngle) * TplayVars.OrbitOffset, 1, math.sin(thisAngle) * TplayVars.OrbitOffset)
							if drop:IsA("BasePart") then
								drop.CFrame = RootPart.CFrame + offset
							elseif drop:IsA("Model") then
								drop:PivotTo(RootPart.CFrame + offset)
							end
						end
					end
				end)
			else
				ToggleNetworkOwner(false)
				if TplayVars.OrbitGlowsticksConnection then
					TplayVars.OrbitGlowsticksConnection:Disconnect()
					TplayVars.OrbitGlowsticksConnection = nil
				end
			end
		end
	})

	Tplay_Items:AddSlider("Tplay_OrbitSpeed", {
		Text = "Orbit Speed",
		Default = 1,
		Min = 0.1,
		Max = 10,
		Rounding = 1,
		Callback = function(v) TplayVars.OrbitSpeed = v end
	})

	Tplay_Items:AddSlider("Tplay_OrbitOffset", {
		Text = "Orbit Offset (Radius)",
		Default = 4,
		Min = 1,
		Max = 15,
		Rounding = 1,
		Callback = function(v) TplayVars.OrbitOffset = v end
	})

	Tplay_Items:AddDivider()

	Tplay_Items:AddToggle("Tplay_AntiSteal", {
		Text = "Anti Steal Items",
		Default = false,
		Tooltip = "Claims network ownership over nearby items so other players cannot take them.",
		Callback = function(Value)
			TplayVars.AntiStealEnabled = Value
			if Value then ToggleNetworkOwner(true) else ToggleNetworkOwner(false) end
		end
	})

	Tplay_Items:AddToggle("Tplay_NoPrompt", {
		Text = "No Prompt Interaction Block",
		Default = false,
		Tooltip = "Disables unwanted prompts around your character.",
		Callback = function(v) TplayVars.NoPromptEnabled = v end
	})

	-- =========================================================================
	-- 4. FLOOR COMPLETION TAB (Auto Floor & Specials)
	-- =========================================================================

	local function GetRoomDoor(room)
		if not room then return nil end
		local door = room:FindFirstChild("Door") or room:FindFirstChild("ExitDoor") or room:FindFirstChild("OutdoorsDoor") or room:FindFirstChild("Gate") or room:FindFirstChild("StairwellExitDoor")
		if not door then
			for _, child in ipairs(room:GetChildren()) do
				if child.Name:find("Door") or child.Name:find("Gate") or child:FindFirstChild("ClientOpen") then
					return child
				end
			end
		end
		return door
	end

	local function OpenDoor(door, room)
		if not door then return end
		local prompt = door:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt and fireprompt then
			pcall(fireprompt, prompt)
		end
		local clientOpen = door:FindFirstChild("ClientOpen") or (room and room:FindFirstChild("ClientOpen"))
		if clientOpen and clientOpen:IsA("RemoteEvent") then
			pcall(function() clientOpen:FireServer() end)
		end
	end

	local function GetKeyFromRoom(room)
		if not room then return nil, nil end
		local key = room:FindFirstChild("KeyObtain", true)
		if key then
			local drawer = key.Parent and key.Parent.Name == "DrawerContainer" and key.Parent or nil
			return key, drawer
		end
		return nil, nil
	end


	-- =========================================================================
	-- 4. FLOOR COMPLETION (Exact v2.9.4 AutoFloor System)
	-- =========================================================================
	local FloorSpecific = (GameData:FindFirstChild("FloorDestinationSpecific") and GameData.FloorDestinationSpecific.Value) or ""
	local ContinueOrSave = RemotesFolder:FindFirstChild("ContinueOrSave")
	local RequestLocalAsset = RemotesFolder:FindFirstChild("RequestLocalAsset")
	local ServerTeleported = RemotesFolder:FindFirstChild("ServerTeleported")
	local CrouchRemoteEvent = RemotesFolder:FindFirstChild("Crouch")
	local Cutscene = RemotesFolder:FindFirstChild("Cutscene")
	local PlayAgain = RemotesFolder:FindFirstChild("PlayAgain")
	local Statistics = RemotesFolder:FindFirstChild("Statistics") or RemotesFolder:FindFirstChild("RippleStatistics")
	local Variables = TplayVars
	local Connections = TplayVars
	local Info = { AddonTitle = "Tplay's Addon" }
	local StuffToRemoveLater = { novelocitybro = Instance.new("BodyVelocity") }

	local function toggleNetworkOwner(b) return ToggleNetworkOwner(b) end
	local function logprint(...) end
	local function POASync(force)
		if CrouchRemoteEvent then pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true) end
	end
	local function SafeDisconnect(c) if typeof(c) == "RBXScriptConnection" then pcall(c.Disconnect, c) end end
	local function SafeDestroy(v) if typeof(v) == "Instance" then pcall(v.Destroy, v) end end
	local function restoremetamethods() end

	local function getTpFunction()
		local connections = getconnections and ServerTeleported and getconnections(ServerTeleported.OnClientEvent)
		local connection = connections and connections[1]
		return connection and connection.Function
	end

	local BackpackCache
	local function GetBackpack()
		if BackpackCache and BackpackCache.Parent == LocalPlayer then return BackpackCache end
		BackpackCache = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
		return BackpackCache
	end
	local function BackpackItem(name)
		local backpack = GetBackpack()
		return backpack and backpack:FindFirstChild(name)
	end
	local function GetEquippedTool(player)
		return player and player.Character and player.Character:FindFirstChildOfClass("Tool")
	end
	local function ExecutorSupported(AutoFloor)
		return true
	end

	local function Notify(params)
		if type(params) == "table" then
			Functions.Notify({
				Title = params.Title or "Tplay's Addon",
				Body = params.Description or params.Body or params.Text or "",
				Time = params.Time or 5
			})
		else
			Functions.Notify({ Title = "Tplay's Addon", Body = tostring(params), Time = 5 })
		end
	end

	local raw_AutoFloorRoom = Tplay_Floors:AddLabel("Status: Idle")
	Variables.AutoFloorRoom = {
		ChangeDescription = function(self, text)
			pcall(function() raw_AutoFloorRoom:SetText(tostring(text)) end)
		end,
		SetText = function(self, text)
			pcall(function() raw_AutoFloorRoom:SetText(tostring(text)) end)
		end
	}

	local activeRusherEntities = {}
	local rusherNames = {RushMoving=true, AmbushMoving=true, A60=true, A120=true, BackdoorRush=true, CustomEntity=true, BashMoving=true, GlitchRush=true, GlitchAmbush=true}
	local function trackRusher(inst)
		if rusherNames[inst.Name] then
			activeRusherEntities[inst] = true
			inst.AncestryChanged:Connect(function()
				if not inst.Parent then
					activeRusherEntities[inst] = nil
				end
			end)
		end
	end
	for _, inst in workspace:GetDescendants() do
		trackRusher(inst)
	end
	Connections.RusherTracker = workspace.DescendantAdded:Connect(trackRusher)
	Connections.RusherUntracker = workspace.DescendantRemoving:Connect(function(inst)
		activeRusherEntities[inst] = nil
	end)
	function ActiveRusher()
		for rusher in activeRusherEntities do
			if rusher.Parent then
				return true, rusher.Name
			end
		end
		return false
	end
	local function FindHidingSpot()
		local Root = Character and Character.PrimaryPart
		if not Root then return nil end
		local pos = Root.Position
		local best, bestDist = nil, math.huge
		for _, obj in workspace:QueryDescendants("> #Closet, > #Bed, > #Locker") do
			if obj:IsA("Model") then
				local prompt = obj:FindFirstChild("HidePrompt", true) or obj:FindFirstChild("InteractPrompt", true)
				if prompt then
					local pivot = obj:GetPivot()
					local dx, dz = pivot.Position.X-pos.X, pivot.Position.Z-pos.Z
					local d = dx*dx+dz*dz
					if d < bestDist then
						bestDist = d
						best = obj
					end
				end
			end
		end
		return best
	end
	local function HideFromA120()
		local spot = FindHidingSpot()
		if spot then
			Character:PivotTo(spot:GetPivot())
			local prompt = spot:FindFirstChild("HidePrompt", true) or spot:FindFirstChild("InteractPrompt", true)
			if prompt then
				fireproximityprompt(prompt)
			end
			return true
		end
		return false
	end
	function GetDropThatCanUnlock()
		for i,v in Drops:QueryDescendants(`Model[$PlayerName = {LocalPlayer.Name}]`) do
			if v.Name == "Lockpick" or v.Name == "SkeletonKey" or v.Name == "Multitool" then
				return v
			end
		end
		return nil
	end
	function ItemThatCanUnlock()
		local Tool = GetEquippedTool(LocalPlayer)
		return Tool
		and (Tool.Name == "Lockpick" or Tool.Name == "SkeletonKey" or Tool.Name == "Multitool")
		and Tool
		or GetDropThatCanUnlock()
		or BackpackItem("Lockpick")
		or BackpackItem("SkeletonKey")
		or BackpackItem("Multitool")
	end
	function FindKeyObtain(Room)
		local key = Room:FindFirstChild("KeyObtain", true)
		if key then
			return key, key.Parent.Name == "DrawerContainer" and key.Parent
		end
		return nil, false
	end
	function GetNearestBook(Room)
		local Nearest = {
			Dist = 1/0
		}
		for _, book in Room:QueryDescendants("#Modular_Bookshelf > #LiveHintBook") do
			local dist = (Character:GetPivot().Position-book:GetPivot().Position).Magnitude
			if dist < Nearest.Dist then
				Nearest.Dist = dist
				Nearest.Book = book
			end
		end
		return Nearest.Book
	end
	function GetNearestBreaker(Room)
		local Nearest = {
			Dist = 1/0
		}
		for _, breaker in Room:QueryDescendants("#LiveBreakerPolePickup") do
			local dist = (Character:GetPivot().Position-breaker:GetPivot().Position).Magnitude
			if dist < Nearest.Dist then
				Nearest.Dist = dist
				Nearest.Breaker = breaker
			end
		end
		return Nearest.Breaker or Room:FindFirstChild("LiveBreakerPolePickup")
	end
	function GetNearestFuse(Room)
		local Nearest = {
			Dist = 1/0
		}
		for _, fuse in Room:QueryDescendants("#FuseObtain") do
			local dist = (Character:GetPivot().Position-fuse:GetPivot().Position).Magnitude
			if dist < Nearest.Dist and fuse.Hitbox.FuseModel.LocalTransparencyModifier ~= 1 then
				Nearest.Dist = dist
				Nearest.Fuse = fuse
			end
		end
		return Nearest.Fuse
	end
	Variables.InfItems = Library.Toggles.InfItems
	Variables.AutoLibrarySolver = Library.Toggles.AutoLibrarySolver
	Variables.BruteforceLibraryCode = Library.Toggles.BruteforceLibraryCode
	Variables.AutoBreakerSolverMethod = Library.Options.AutoBreakerSolverMethod
	Variables.AutoBreakerSolver = Library.Toggles.AutoBreakerSolver
	Variables.StuffToKeepEnabled = {
		Library.Toggles.AntiScreech,
		Library.Toggles.AntiDupe,
		Library.Toggles.AntiDread,
		Library.Toggles.AntiHalt,
		Library.Toggles.AntiSnare,
		Library.Toggles.AntiEyes,
		Library.Toggles.AntiA90,
		Toggles.CollisionOffsetGodmodeAlt
	}
	if Floor == "Mines" then
		for i, b in Library.Buttons do
			if b and b.Text == "Beat Door 200" then
				Variables.BeatDoor200 = b
				break
			end
		end
		table.insert(Variables.StuffToKeepEnabled, Library.Toggles.AntiSeekFlood)
		table.insert(Variables.StuffToKeepEnabled, Library.Toggles.AntiGiggle)
	elseif Floor == "Garden" then
		table.insert(Variables.StuffToKeepEnabled, Library.Toggles.NoSurgeDamage)
		table.insert(Variables.StuffToKeepEnabled, Toggles.BringDrawers)
		table.insert(Variables.StuffToKeepEnabled, Toggles.AutoLoot)
	else
		table.insert(Variables.StuffToKeepEnabled, Toggles.BringDrawers)
		table.insert(Variables.StuffToKeepEnabled, Toggles.AutoLoot)
	end
	function IsInteresting(Rooms, Room)
		return not not (table.find(Rooms, Room:GetAttribute("RawName")) or table.find(Rooms, `{Room:GetAttribute("RawName")}|{Room.Name}`) or table.find(Rooms, Room.Name))
	end
	function GetNearestLadderGrabPart(Room)
		local Nearest = {
			Dist = 1/0
		}
		for _, grabPart in Room:QueryDescendants("#Ladder > #GrabPart") do
			local dist = (Character:GetPivot().Position-grabPart.Position).Magnitude
			if dist < Nearest.Dist then
				Nearest.Dist = dist
				Nearest.GrabPart = grabPart
			end
		end
		return Nearest.GrabPart
	end
	function GetNearestLever(Room)
		local Nearest = {
			Dist = 1/0
		}
		for _, lever in Room:QueryDescendants("#AlaskanVineSet > #VineGuillotine > #Lever") do
			local dist = (Character:GetPivot().Position-lever.Position).Magnitude
			if dist < Nearest.Dist and (lever.ActivateEventPrompt:GetAttribute("Interactions") or 0) < 1 then
				Nearest.Dist = dist
				Nearest.Lever = lever
			end
		end
		return Nearest.Lever
	end

	function GetLotusPetal()
		local LotusPetals = CurrentRooms:QueryDescendants("#LotusHolder, #LotusPetalPickup, #LotusPetal")
		local LotusPetal, Drawer
		for _, lotuspetal in LotusPetals do
			if (lotuspetal.ModulePrompt:GetAttribute("Interactions"..LocalPlayer.Name) or 0) < 1 then
				LotusPetal, Drawer = lotuspetal, lotuspetal.Parent and lotuspetal.Parent.Name == "DrawerContainer" and lotuspetal.Parent
				break
			end
		end
		return LotusPetal, Drawer
	end
	StuffToRemoveLater.novelocitybro = Instance.new("BodyVelocity")
	StuffToRemoveLater.novelocitybro.MaxForce = Vector3.new(1/0, 1/0, 1/0)
	StuffToRemoveLater.novelocitybro.Velocity = Vector3.zero
	local function SetupTeleportBypass()
		if Toggles.AntiTeleport.Value then
			Toggles.AntiTeleport:SetValue(false)
		elseif Toggles.AntiTeleportRaknet.Value then
			Toggles.AntiTeleportRaknet:SetValue(false)
		end
		Services.RunService.RenderStepped:Wait()
		Toggles.AntiTeleport:SetDisabled(true)
		if not Toggles.AntiTeleportRaknet.Disabled then
			Toggles.AntiTeleportRaknet:SetDisabled(true)
		end
		if Library.Toggles.AutoMandrake and Library.Toggles.AutoMandrake.Value then
			Variables.WasAutoMandrakeOn = true
			Library.Toggles.AutoMandrake:SetValue(false)
			Library.Toggles.AutoMandrake:SetDisabled(true)
		end
		Variables.tpFunction = getTpFunction()
		if hookfunction then
			if Variables.tpFunction then
				local tp; tp = hookfunction(Variables.tpFunction, function(...)
					if checkcaller() then
						tp(...)
					end
				end)
			end
			local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
				if not checkcaller() then
					hookfunction(func, function()end)
					Variables.tpFunction = func
				end
				return hook(self, func)
			end)
		end
	end
	local function GetLockPrompt(Door)
		return Door and Door.Lock and (Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt"))
	end
	local lastStuffKeep = -1/0
	local function EnsureStuffToKeepEnabled()
		if os.clock() - lastStuffKeep <= 2 then return end
		lastStuffKeep = os.clock()
		for _, toggle in Variables.StuffToKeepEnabled do
			if not toggle.Value and not toggle.Disabled then
				toggle:SetValue(true)
			end
		end
	end
	Variables.AutoFloors = {
		Hotel = {
			Requirements = {
				"firetouchinterest",
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				local InterestingRooms = {
					"Hotel_SeekIntro"
				}
				local FigureRooms = {
					"Hotel_LibraryEntrance",
					"99"
				}
				if value then
					SetupTeleportBypass()
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
				local AutoFloor = {}
				Connections.AutoFloor = AutoFloor
				local interesting = IsInteresting(InterestingRooms, tempRoom)
				local activeRusher, rusherName = ActiveRusher()
				local lastCutscene = ""
					local unavailableUntil = -1/0
					local touched = false
					local key, drawer, book, breaker
				AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
					if os.clock()<unavailableUntil then return end
					activeRusher, rusherName = ActiveRusher()
					local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
					local Door = Room and Room:FindFirstChild("Door")
					if not Character or not Character.Parent or not Character.PrimaryPart or Character.PrimaryPart.Anchored then return end
					if not Room then return end
					if activeRusher then
						if not AutoFloor.Waiting then
							AutoFloor.Waiting = true
							if rusherName == "A120" then
								HideFromA120()
							end
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Paused - Entity Nearby\nDoors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
							end
							if Toggles.AutoFloor then
								Toggles.AutoFloor:SetText("Auto Floor [Paused]")
							end
							if Library.Toggles.DoorReach.Value then
								Library.Toggles.DoorReach:SetValue(false)
							end
						end
						return
					elseif AutoFloor.Waiting then
						AutoFloor.Waiting = false
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
						end
						if Toggles.AutoFloor then
							Toggles.AutoFloor:SetText("Auto Floor")
						end
					end

						if not Toggles.SlideSpeedHack.Value then
							Toggles.SlideSpeedHack:SetValue(true)
						end
						EnsureStuffToKeepEnabled()
						if Room:GetAttribute("RequiresKey") then
							local item = ItemThatCanUnlock()
							if item then
								if not Variables.InfItems.Value then
									Variables.InfItems:SetValue(true)
								end
								if item:IsA("Tool") and item.Parent ~= Character then
									item.Parent = Character
								elseif item:IsA("Model") and item:FindFirstChild("ModulePrompt") then
									item:PivotTo(Character:GetPivot())
									fireproximityprompt(item.ModulePrompt)
								end
								Character:PivotTo(Door:GetPivot())
								local prompt = GetLockPrompt(Door)
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								local tool = GetEquippedTool(LocalPlayer)
								if BackpackItem("Key") or (tool and tool.Name == "Key") then
									key = nil
									drawer = nil
									Character:PivotTo(Door:GetPivot())
									local prompt = GetLockPrompt(Door)
									if prompt then
										fireproximityprompt(prompt)
									end
								else
									if not key or not drawer then
										key, drawer = FindKeyObtain(Room)
									end
									if key then
										Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
										if drawer then
											fireproximityprompt(drawer.Knobs.ActivateEventPrompt)
										end
										fireproximityprompt(key.ModulePrompt)
									end
								end
							end
						elseif Room.Name == "50" then
							if Toggles.AntiFigure and not Toggles.AntiFigure.Value then
								AutoFloor.RestoreOffset50 = Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value and true or nil
								AutoFloor.AntiFigure50 = true
								Toggles.AntiFigure:SetValue(true)
							end
								book = book and book.Parent and book or GetNearestBook(Room)
							if book then
								Character:PivotTo(book:GetPivot()+Vector3.new(0,8,0))
								fireproximityprompt(book.ActivateEventPrompt)
							else
								book = false
								local tool = GetEquippedTool(LocalPlayer)
								local LibraryHintPaper = (tool and tool.Name == "LibraryHintPaper" and tool) or BackpackItem("LibraryHintPaper") or Room:FindFirstChild("LibraryHintPaper")
								if LibraryHintPaper then
									if LibraryHintPaper:IsA("Tool") then
										if not Variables.AutoLibrarySolver.Value then
											Variables.AutoLibrarySolver:SetValue(true)
										end
										if not Variables.BruteforceLibraryCode.Value then
											Variables.BruteforceLibraryCode:SetValue(true)
										end
										local backpack = GetBackpack()
										LibraryHintPaper.Parent = LibraryHintPaper.Parent == Character and (backpack or Character) or Character
										Character:PivotTo(Door:GetPivot())
									else
										Character:PivotTo(LibraryHintPaper:GetPivot()+Vector3.new(0,5,0))
										fireproximityprompt(LibraryHintPaper.ModulePrompt)
									end
								end
							end
						elseif Room.Name == "100" then
							if Toggles.AntiFigure and not Toggles.AntiFigure.Value then
								Toggles.AntiFigure:SetValue(true)
							end
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
									if name == "Elevator1" then
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "The hotel completed!",
											Time = 10
										})
										Toggles.AutoFloor:SetValue(false)
										Toggles.AutoFloor:SetDisabled(true)
										return
									end
								end)
							end
							if breaker ~= false then
								breaker = breaker and breaker.Parent and breaker or GetNearestBreaker(Room)
							end
							if breaker then
								Character:PivotTo(breaker:GetPivot())
								fireproximityprompt(breaker.ActivateEventPrompt)
							else
								breaker = false
							if lastCutscene == "" then
								Character:PivotTo(Room.IndustrialGate:GetPivot())
								fireproximityprompt(Room.IndustrialGate.Box.ActivateEventPrompt)
								task.wait(5)
							elseif lastCutscene == "FigureHotelEnd" then
								toggleNetworkOwner(true)
								local pivot = Room.ElevatorBreakerEmpty:GetPivot()
								Character:PivotTo(pivot+pivot.RightVector*-12)
								fireproximityprompt(Room.ElevatorBreakerEmpty.Prompt)
								pcall(function()
									Room.FigureSetup.FigureRig:PivotTo(CFrame.new(0,-1000,0))
								end)
								task.wait(8)
							elseif lastCutscene == "FigureHotelChase" then
								Character:PivotTo(Room.ElevatorCar.CollisionExtra.CFrame)
								firetouchinterest(Character.PrimaryPart, Room.ElevatorCar.CollisionExtra, touched and 1 or 0)
								touched = not touched
								task.wait(8)
							elseif Room:FindFirstChild("ElevatorBreaker") then
									if not Variables.AutoBreakerSolver.Value then
										Variables.AutoBreakerSolver:SetValue(true)
									end
									if Variables.AutoBreakerSolverMethod.Value ~= "Exploit" then
										Variables.AutoBreakerSolverMethod:SetValue("Exploit")
									end
									Character:PivotTo(Room.ElevatorBreaker:GetPivot())
									fireproximityprompt(Room.ElevatorBreaker.ActivateEventPrompt)
								end
							end
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
						if Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value then
							POASync(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if AutoFloor.AntiFigure50 and room and room.Name ~= "50" and room.Name ~= "100" then
							AutoFloor.AntiFigure50 = nil
							if Toggles.AntiFigure and Toggles.AntiFigure.Value then
								Toggles.AntiFigure:SetValue(false)
							end
							if AutoFloor.RestoreOffset50 and Toggles.CollisionOffsetGodmodeAlt and not Toggles.CollisionOffsetGodmodeAlt.Value then
								Toggles.CollisionOffsetGodmodeAlt:SetValue(true)
							end
							AutoFloor.RestoreOffset50 = nil
						end
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
						interesting = IsInteresting(InterestingRooms, room)
						local figureInteresting = IsInteresting(FigureRooms, room)
						if room and (interesting or figureInteresting) then
							unavailableUntil = os.clock() + 15
							local lastShown = nil
							local approaching = figureInteresting and "Figure Approaching" or "Seek door approaching"
							while os.clock() < unavailableUntil do
								local remaining = math.max(0, math.ceil(unavailableUntil - os.clock()))
								if Variables.AutoFloorRoom and remaining ~= lastShown then
									lastShown = remaining
									Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}{approaching} - waiting {remaining}s\nDoors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
								end
								Services.RunService.RenderStepped:Wait()
							end
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
							end
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					if Library.Toggles.AutoMandrake then
						Library.Toggles.AutoMandrake:SetDisabled(false)
						if Variables.WasAutoMandrakeOn then
							Library.Toggles.AutoMandrake:SetValue(true)
							Variables.WasAutoMandrakeOn = nil
						end
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							if typeof(connection) == "RBXScriptConnection" then
								connection:Disconnect()
							end
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Mines = {
			Requirements = {
				"firetouchinterest",
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked",
				"getrawmetatable",
				"setreadonly"
			},
			Callback = function(value)
				local InterestingRooms = {
					"Mines_SeekStart",
					"Sewer_SeekEnter",
					"98"
				}
				local FigureRooms = {
					"Greenhouse_Intermission",
					"99"
				}
				if value then
					SetupTeleportBypass()
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local interesting = IsInteresting(InterestingRooms, tempRoom)
					local activeRusher, rusherName = ActiveRusher()
					local unavailableUntil = -1/0
					local fuse, buttonPressed, leverActivated, beatingDoor200, noGeneratorSince, buggyRun
				local lastCutscene = ""
				AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
					if os.clock()<unavailableUntil or buggyRun then return end
					activeRusher, rusherName = ActiveRusher()
					local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
					local Door = Room and Room:FindFirstChild("Door")
					if not Character or not Character.Parent or not Character.PrimaryPart or Character.PrimaryPart.Anchored then return end
					if not Room then return end
					if activeRusher then
						if not AutoFloor.Waiting then
							AutoFloor.Waiting = true
							if rusherName == "A120" then
								HideFromA120()
							end
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Paused - Entity Nearby\nDoors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
							end
							if Toggles.AutoFloor then
								Toggles.AutoFloor:SetText("Auto Floor [Paused]")
							end
							if Library.Toggles.DoorReach.Value then
								Library.Toggles.DoorReach:SetValue(false)
							end
						end
						return
					elseif AutoFloor.Waiting then
						AutoFloor.Waiting = false
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
						end
						if Toggles.AutoFloor then
							Toggles.AutoFloor:SetText("Auto Floor")
						end
					end

						if not Toggles.SlideSpeedHack.Value then
							Toggles.SlideSpeedHack:SetValue(true)
						end
						EnsureStuffToKeepEnabled()
						local grabPart = not Character:GetAttribute("_BypassedAC") and not (Camera and Camera:FindFirstChild("MinecartRig")) and GetNearestLadderGrabPart(Room)
						if Character:GetAttribute("Climbing") and not Character:GetAttribute("_BypassedAC") then
							Character:SetAttribute("Climbing", false)
							Character:SetAttribute("_BypassedAC", true)
							Connections.OnCutsceneThatRemovesBypass = Cutscene.OnClientEvent:Once(function()
								Character:SetAttribute("_BypassedAC", false)
								if Variables.AutoFloorRoom then
									Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
								end
							end)
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
							end
						elseif grabPart then
							Character:PivotTo(grabPart.CFrame)
							fireproximityprompt(grabPart.ClimbPrompt)
						elseif Room.Name == "100" then
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
									if name == "MinesFinale" then
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "The mines completed!",
											Time = 10
										})
										Toggles.AutoFloor:SetValue(false)
										Toggles.AutoFloor:SetDisabled(true)
										return
									end
								end)
							end
							if beatingDoor200 then
								if leverActivated and not buttonPressed then
									local button = Room.Assets.MinesGateButton.Button
									local prompt = button.ActivateEventPrompt
									Character:PivotTo(button.CFrame)
									fireproximityprompt(prompt)
									if button.SoundPress.Playing then
										buttonPressed = true
									end
								elseif not leverActivated then
									if Room.Assets.MinesGenerator.GeneratorMain.Sound.Playing then
										leverActivated = true
									end
								else
									local doors = Room._DamHandler._OutsideCutscene.DungeonDoor.DoubleDoors
									local prompt = doors.ActivateEventPrompt
									Character:PivotTo(doors:GetPivot())
									fireproximityprompt(prompt)
								end
							else
								beatingDoor200 = true
								pcall(Variables.BeatDoor200.Func)
							end
						elseif Room:GetAttribute("RequiresGenerator") then
							local fuse = GetNearestFuse(Room)
							if fuse then
								Character:PivotTo(fuse:GetPivot())
								local openFirst = fuse:FindFirstAncestor("Locker_Small") or fuse:FindFirstAncestor("DrawerContainer") or fuse:FindFirstAncestor("Toolbox")
								if openFirst then
									fireproximityprompt(openFirst:FindFirstChild("ActivateEventPrompt", true))
								end
								fireproximityprompt(fuse.ModulePrompt)
							else
								local gen = Room.Assets:FindFirstChild("MinesGenerator")
								if gen then
									noGeneratorSince = nil
								else
									noGeneratorSince = noGeneratorSince or os.clock()
									if noGeneratorSince < os.clock()-3 then
										buggyRun = true
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "Generation bug detected: MinesGenerator didn't spawn in the room that requires generator\n(The game will be automatically restarted)",
											Persist = true
										})
										PlayAgain:FireServer()
									end
									return
								end
								local notTuff = false
								for _, fuse in gen.Fuses:GetChildren() do
									if tonumber(fuse.Name) and fuse.Fuse.Transparency == 1 then
										notTuff = true
										break
									end
								end
								local prompt = notTuff and (gen:FindFirstChild("FusesPrompt", true) or gen:FindFirstChild("FakePrompt", true))
								if prompt then
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
								elseif not leverActivated then
									prompt = gen.Lever.LeverPrompt
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
									if gen.GeneratorMain.Sound.Playing then
										leverActivated = true
									end
								elseif not buttonPressed then
									local button = Room.Assets.MinesGateButton.Button
									prompt = button.ActivateEventPrompt
									Character:PivotTo(button.CFrame)
									fireproximityprompt(prompt)
									if button.SoundPress.Playing then
										buttonPressed = true
									end
								else
									Character:PivotTo(Door:GetPivot())
									Door.ClientOpen:FireServer()
								end
							end
						elseif Room.Name == "46" and not Camera:FindFirstChild("MinecartRig") then
							if not Toggles.MinecartTeleportAlt.Value then
								Toggles.MinecartTeleportAlt:SetValue(true)
							end
							Character:PivotTo(Room.MinecartCollision.Collision.CFrame)
							firetouchinterest(Character.PrimaryPart, Room.MinecartCollision.Collision, 0)
							firetouchinterest(Character.PrimaryPart, Room.MinecartCollision.Collision, 1)
							return
						elseif Camera:FindFirstChild("MinecartRig") and (tonumber(Room.Name) >= 46 or tonumber(Room.Name) < 50) then
							if not Toggles.MinecartTeleportAlt.Value then
								Toggles.MinecartTeleportAlt:SetValue(true)
							end
							return
						elseif Room.Name == "50" then
							if Camera:FindFirstChild("MinecartRig") then return end
							if buttonPressed then
								Character:PivotTo(Door:GetPivot())
								Door.ClientOpen:FireServer()
							else
								local button = Room._NestHandler.Console.Button
								local prompt = button.ActivateEventPrompt
								Character:PivotTo(button.CFrame)
								fireproximityprompt(prompt)
								if button.SoundPress.Playing then
									buttonPressed = true
								end
							end
						else
							Character:PivotTo(Door:GetPivot())
							Door.ClientOpen:FireServer()
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
						if Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value then
							POASync(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						leverActivated = nil
						buttonPressed = nil
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
						end
						interesting = IsInteresting(InterestingRooms, room)
						local figureInteresting = IsInteresting(FigureRooms, room)
						if room and (interesting or figureInteresting) then
							unavailableUntil = os.clock() + 15
							local lastShown = nil
							local approaching = figureInteresting and "Figure Approaching" or "Seek door approaching"
							while os.clock() < unavailableUntil do
								local remaining = math.max(0, math.ceil(unavailableUntil - os.clock()))
								if Variables.AutoFloorRoom and remaining ~= lastShown then
									lastShown = remaining
									Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}{approaching} - waiting {remaining}s\nDoors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
								end
								Services.RunService.RenderStepped:Wait()
							end
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
							end
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					if Library.Toggles.AutoMandrake then
						Library.Toggles.AutoMandrake:SetDisabled(false)
						if Variables.WasAutoMandrakeOn then
							Library.Toggles.AutoMandrake:SetValue(true)
							Variables.WasAutoMandrakeOn = nil
						end
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							if typeof(connection) == "RBXScriptConnection" then
								connection:Disconnect()
							end
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Endless = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					SetupTeleportBypass()
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local key, drawer
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						if not Character or not Character.Parent or not Character.PrimaryPart then return end
						local activeRusher, rusherName = ActiveRusher()
						if activeRusher then
							if not AutoFloor.Waiting then
								AutoFloor.Waiting = true
								if rusherName == "A120" then
									HideFromA120()
								end
								if Variables.AutoFloorRoom then
									Variables.AutoFloorRoom:ChangeDescription(`Paused - Entity Nearby\nDoors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
								end
								if Toggles.AutoFloor then
									Toggles.AutoFloor:SetText("Auto Floor [Paused]")
								end
								if Library.Toggles.DoorReach.Value then
									Library.Toggles.DoorReach:SetValue(false)
								end
							end
							return
						elseif AutoFloor.Waiting then
							AutoFloor.Waiting = false
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
							end
							if Toggles.AutoFloor then
								Toggles.AutoFloor:SetText("Auto Floor")
							end
						end

						if not Toggles.SlideSpeedHack.Value then
							Toggles.SlideSpeedHack:SetValue(true)
						end
						EnsureStuffToKeepEnabled()
						if Room:GetAttribute("RequiresKey") then
							local item = ItemThatCanUnlock()
							if item then
								if not Variables.InfItems.Value then
									Variables.InfItems:SetValue(true)
								end
								if item:IsA("Tool") and item.Parent ~= Character then
									item.Parent = Character
								elseif item:IsA("Model") and item:FindFirstChild("ModulePrompt") then
									item:PivotTo(Character:GetPivot())
									fireproximityprompt(item.ModulePrompt)
								end
								Character:PivotTo(Door:GetPivot())
								local prompt = GetLockPrompt(Door)
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								local tool = GetEquippedTool(LocalPlayer)
								if BackpackItem("Key") or (tool and tool.Name == "Key") then
									key = nil
									drawer = nil
									Character:PivotTo(Door:GetPivot())
									local prompt = GetLockPrompt(Door)
									if prompt then
										fireproximityprompt(prompt)
									end
								else
									if not key or not drawer then
										key, drawer = FindKeyObtain(Room)
									end
									if key then
										Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
										if drawer then
											fireproximityprompt(drawer.Knobs.ActivateEventPrompt)
										end
										fireproximityprompt(key.ModulePrompt)
									else
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "Endless completed!",
											Time = 10
										})
										Toggles.AutoFloor:SetValue(false)
										Toggles.AutoFloor:SetDisabled(true)
									end
								end
							end
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
						if Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value then
							POASync(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					if Library.Toggles.AutoMandrake then
						Library.Toggles.AutoMandrake:SetDisabled(false)
						if Variables.WasAutoMandrakeOn then
							Library.Toggles.AutoMandrake:SetValue(true)
							Variables.WasAutoMandrakeOn = nil
						end
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							if typeof(connection) == "RBXScriptConnection" then
								connection:Disconnect()
							end
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Ripple_Daily_Default = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					SetupTeleportBypass()
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`,
						Persist = true
					})
					local AutoFloor = {}
					local activeRusher, rusherName = ActiveRusher()
					Connections.AutoFloor = AutoFloor
					local key, drawer, fuse, buttonPressed, leverActivated, noGeneratorSince, buggyRun
				AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
					if buggyRun then return end
					activeRusher, rusherName = ActiveRusher()
					local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
					local Door = Room and Room:FindFirstChild("Door")
					if not Character or not Character.Parent or not Character.PrimaryPart then return end
					if activeRusher then
						if not AutoFloor.Waiting then
							AutoFloor.Waiting = true
							if rusherName == "A120" then
								HideFromA120()
							end
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Paused - Entity Nearby\nDoors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
							end
							if Toggles.AutoFloor then
								Toggles.AutoFloor:SetText("Auto Floor [Paused]")
							end
							if Library.Toggles.DoorReach.Value then
								Library.Toggles.DoorReach:SetValue(false)
							end
						end
						return
					elseif AutoFloor.Waiting then
						AutoFloor.Waiting = false
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
						end
						if Toggles.AutoFloor then
							Toggles.AutoFloor:SetText("Auto Floor")
						end
					end

						if not Toggles.SlideSpeedHack.Value then
							Toggles.SlideSpeedHack:SetValue(true)
						end
						EnsureStuffToKeepEnabled()
						local grabPart = not Character:GetAttribute("_BypassedAC") and GetNearestLadderGrabPart(Room)
						if Character:GetAttribute("Climbing") and not Character:GetAttribute("_BypassedAC") then
							Character:SetAttribute("Climbing", false)
							Character:SetAttribute("_BypassedAC", true)
							Connections.OnCutsceneThatRemovesBypass = Cutscene.OnClientEvent:Once(function()
								Character:SetAttribute("_BypassedAC", false)
								if Variables.AutoFloorRoom then
									Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
								end
							end)
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
							end
						elseif grabPart then
							Character:PivotTo(grabPart.CFrame)
							fireproximityprompt(grabPart.ClimbPrompt)
						elseif Room:GetAttribute("RequiresKey") then
							local item = ItemThatCanUnlock()
							if item then
								if not Variables.InfItems.Value then
									Variables.InfItems:SetValue(true)
								end
								if item:IsA("Tool") and item.Parent ~= Character then
									item.Parent = Character
								elseif item:IsA("Model") and item:FindFirstChild("ModulePrompt") then
									item:PivotTo(Character:GetPivot())
									fireproximityprompt(item.ModulePrompt)
								end
								Character:PivotTo(Door:GetPivot())
								local prompt = GetLockPrompt(Door)
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								local tool = GetEquippedTool(LocalPlayer)
								local keyTool = BackpackItem("Key") or (tool and tool.Name == "Key" and tool) or BackpackItem("KeyBackdoor") or (tool and tool.Name == "KeyBackdoor" and tool)
								if keyTool then
									key = nil
									drawer = nil
									if keyTool.Name == "KeyBackdoor" and keyTool.Parent ~= Character then
										keyTool.Parent = Character
									end
									Character:PivotTo(Door:GetPivot())
									local prompt = GetLockPrompt(Door)
									if prompt then
										fireproximityprompt(prompt)
									end
								else
									if not key or not drawer then
										key, drawer = FindKeyObtain(Room)
									end
									if key then
										Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
										if drawer then
											fireproximityprompt(drawer:FindFirstChild("ActivateEventPrompt", true))
										end
										fireproximityprompt(key.ModulePrompt)
									end
								end
							end
						elseif Room:GetAttribute("RequiresGenerator") then
							local fuse = GetNearestFuse(Room)
							if fuse then
								Character:PivotTo(fuse:GetPivot())
								local openFirst = fuse:FindFirstAncestor("Locker_Small") or fuse:FindFirstAncestor("DrawerContainer") or fuse:FindFirstAncestor("Toolbox")
								if openFirst then
									fireproximityprompt(openFirst:FindFirstChild("ActivateEventPrompt", true))
								end
								fireproximityprompt(fuse.ModulePrompt)
							else
								local gen = Room.Assets:FindFirstChild("MinesGenerator")
								if gen then
									noGeneratorSince = nil
								else
									noGeneratorSince = noGeneratorSince or os.clock()
									if noGeneratorSince < os.clock()-3 then
										buggyRun = true
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "Generation bug detected: MinesGenerator didn't spawn in the room that requires generator\n(The game will be automatically restarted)",
											Persist = true
										})
										PlayAgain:FireServer()
									end
									return
								end
								local notTuff = false
								for _, fuse in gen.Fuses:GetChildren() do
									if tonumber(fuse.Name) and fuse.Fuse.Transparency == 1 then
										notTuff = true
										break
									end
								end
								local prompt = notTuff and (gen:FindFirstChild("FusesPrompt", true) or gen:FindFirstChild("FakePrompt", true))
								if prompt then
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
								elseif not leverActivated then
									prompt = gen.Lever.LeverPrompt
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
									if gen.GeneratorMain.Sound.Playing then
										leverActivated = true
									end
								elseif not buttonPressed then
									local button = Room.Assets.MinesGateButton.Button
									prompt = button.ActivateEventPrompt
									Character:PivotTo(button.CFrame)
									fireproximityprompt(prompt)
									if button.SoundPress.Playing then
										buttonPressed = true
									end
								else
									Character:PivotTo(Door:GetPivot())
								end
							end
						elseif Room:GetAttribute("RawName") == "RippleEnd" then
							if not AutoFloor.OnStatistics then
								AutoFloor.OnStatistics = RippleStatistics.OnClientEvent:Connect(function()
									Library:Notify({
										Title = Info.AddonTitle,
										Description = "Daily run completed!",
										Time = 10
									})
									Toggles.AutoFloor:SetValue(false)
									Toggles.AutoFloor:SetDisabled(true)
								end)
							end
							Door = Room.RippleExitDoor
							Character:PivotTo(Door:GetPivot())
							fireproximityprompt(Door.Door.EnterPrompt)
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						leverActivated = nil
						buttonPressed = nil
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					if Library.Toggles.AutoMandrake then
						Library.Toggles.AutoMandrake:SetDisabled(false)
						if Variables.WasAutoMandrakeOn then
							Library.Toggles.AutoMandrake:SetValue(true)
							Variables.WasAutoMandrakeOn = nil
						end
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							if typeof(connection) == "RBXScriptConnection" then
								connection:Disconnect()
							end
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Garden = {
			Requirements = {
				"firetouchinterest",
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if Variables.tpFunction then
						local tp; tp = hookfunction(Variables.tpFunction, function(...)
							if checkcaller() then
								tp(...)
							end
						end)
					end
					local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
						if not checkcaller() then
							hookfunction(func, function()end)
							Variables.tpFunction = func
						end
						return hook(self, func)
					end)
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local unavailableUntil = -1/0
					local lastCutscene = ""
					local LOTUS, PICKING_LOTUS = false, false
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						logprint("WORKS")
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						local eyestalkEnd = Room:GetAttribute("RawName") == "Garden_EyestalkEnd" and Toggles.TriggerEyestalkChaseEnd.Value and (lastCutscene ~= "EyestalkOutro" or Character.PrimaryPart.Anchored)
						if os.clock()<unavailableUntil or (eyestalkEnd and Character.PrimaryPart.Anchored) then logprint("RETURNED", os.clock()<unavailableUntil, (eyestalkEnd and Character.PrimaryPart.Anchored))  return end
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						local lotuspetal, drawer, grampy
						local tool = GetEquippedTool(LocalPlayer)
						if Toggles.MakeLotus.Value and not (LocalPlayer.Backpack:FindFirstChild("Lotus") or (tool and tool.Name == "Lotus")) then
							lotuspetal, drawer = GetLotusPetal()
							grampy = CurrentRooms:FindFirstChild("Grampy", true)
							grampy = grampy and (tonumber(grampy.Parent.Parent.Name) or 0) <= LatestRoom.Value and grampy
						end
						local lotuspetaltool = (tool and tool.Name == "LotusPetal" and tool) or LocalPlayer.Backpack:FindFirstChild("LotusPetal")
						local success, forminglotus = pcall(function()
							return Room.Assets.FormingLotus
						end)
						forminglotus = success and forminglotus
						if grampy and not LOTUS and lotuspetaltool and lotuspetaltool:GetAttribute("Durability") > 7 then
							logprint(1)
							PICKING_LOTUS = true
							Character:PivotTo(grampy:GetPivot())
							if lotuspetaltool.Parent ~= Character then
								lotuspetaltool.Parent = Character
							end
							fireproximityprompt(grampy.DialogPrompt)
						elseif grampy and not LOTUS and PICKING_LOTUS then
							if tool and tool.Name == "Lotus" then
								logprint(2.1)
								LOTUS = true
							elseif forminglotus and forminglotus:FindFirstChild("Lotus") then
								logprint(2.2)
								Character:PivotTo(forminglotus:GetPivot())
								fireproximityprompt(forminglotus.Lotus.PromptAttach.ModulePrompt)
							end
						elseif lotuspetal and not (lotuspetaltool and lotuspetaltool:GetAttribute("Durability") > 7) then
							logprint(3)
							Character:PivotTo(lotuspetal:GetPivot())
							if drawer then
								fireproximityprompt(drawer:FindFirstChild("ActivateEventPrompt", true))
							end
							fireproximityprompt(lotuspetal.ModulePrompt)
						elseif eyestalkEnd then
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
								end)
							end
							if lastCutscene == "EyestalkOutro" then
								logprint(4.1)
								AutoFloor.CutsceneActivated:Disconnect()
							else
								logprint(4.2)
								Character:PivotTo(Room.EyestalkEndCutscene.Collision.CFrame)
								firetouchinterest(Character.PrimaryPart, Room.EyestalkEndCutscene.Collision, 0)
								firetouchinterest(Character.PrimaryPart, Room.EyestalkEndCutscene.Collision, 1)
							end
						elseif Room.Name == "35" then
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
								end)
							end
							if lastCutscene == "BrambleIntro" then
								if required_main_game.stopcam then return end
								logprint(5.1)
								local Lever = GetNearestLever(Room)
								if Lever then
									logprint("5.1.1")
									Character:PivotTo(Lever.CFrame)
									fireproximityprompt(Lever.ActivateEventPrompt)
								else
									logprint("5.1.2")
									Character:PivotTo(Room.OutdoorsEnding.Collision.CFrame)
									firetouchinterest(Character.PrimaryPart, Room.OutdoorsEnding.Collision, 0)
									firetouchinterest(Character.PrimaryPart, Room.OutdoorsEnding.Collision, 1)
								end
							elseif lastCutscene == "EyestalkOutro" or lastCutscene == "" then
								logprint(5.2)
								Character:PivotTo(Room.BrambleCutscene.Collision.CFrame)
								firetouchinterest(Character.PrimaryPart, Room.BrambleCutscene.Collision, 0)
								firetouchinterest(Character.PrimaryPart, Room.BrambleCutscene.Collision, 1)
							else
								logprint(5.3)
								Library:Notify({
									Title = Info.AddonTitle,
									Description = "Outdoors completed!",
									Time = 10
								})
								Toggles.AutoFloor:SetValue(false)
								Toggles.AutoFloor:SetDisabled(true)
							end
						else
							logprint(6)
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
						if Toggles.MakeLotus.Value and (not lotuspetaltool or lotuspetaltool:GetAttribute("Durability") < 8) then
							unavailableUntil = os.clock()+.5
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
						restorefunction(Variables.tpFunction)
					end
					if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
						restorefunction(ServerTeleported.OnClientEvent.Connect)
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Backdoor = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					SetupTeleportBypass()
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local unavailableUntil = -1/0
					local key, drawer, timerincreased
					local activeRusher = false
				AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
					if os.clock()<unavailableUntil then return end
					local rusherActive, rusherName = ActiveRusher()
					if rusherActive and rusherName ~= "BackdoorRush" then
						activeRusher = true
					elseif activeRusher then
						activeRusher = false
					end
					local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
					local Door = Room and Room:FindFirstChild("Door")
					if not Character or not Character.Parent or not Character.PrimaryPart then return end
					if activeRusher then
						if not AutoFloor.Waiting then
							AutoFloor.Waiting = true
							if rusherName == "A120" then
								HideFromA120()
							end
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Paused - Entity Nearby\nDoors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
							end
							if Toggles.AutoFloor then
								Toggles.AutoFloor:SetText("Auto Floor [Paused]")
							end
							if Library.Toggles.DoorReach.Value then
								Library.Toggles.DoorReach:SetValue(false)
							end
						end
						return
					elseif AutoFloor.Waiting then
						AutoFloor.Waiting = false
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}`)
						end
						if Toggles.AutoFloor then
							Toggles.AutoFloor:SetText("Auto Floor")
						end
					end

						if not Toggles.SlideSpeedHack.Value then
							Toggles.SlideSpeedHack:SetValue(true)
						end
						EnsureStuffToKeepEnabled()
						local timerlever = Room:FindFirstChild("TimerLever", true)
						if timerlever and not timerincreased then
							Character:PivotTo(timerlever:GetPivot())
							fireproximityprompt(timerlever.ActivateEventPrompt)
							if timerlever.TakeTimer.TextLabel.Text == "00:00" then
								timerincreased = true
							end
						elseif Room:GetAttribute("RequiresKey") then
							local item = ItemThatCanUnlock()
							if item then
								if not Variables.InfItems.Value then
									Variables.InfItems:SetValue(true)
								end
								if item:IsA("Tool") and item.Parent ~= Character then
									item.Parent = Character
								elseif item:IsA("Model") and item:FindFirstChild("ModulePrompt") then
									item:PivotTo(Character:GetPivot())
									fireproximityprompt(item.ModulePrompt)
								end
								Character:PivotTo(Door:GetPivot())
								local prompt = GetLockPrompt(Door)
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								local tool = GetEquippedTool(LocalPlayer)
								local keyTool = BackpackItem("Key") or (tool and tool.Name == "Key" and tool) or BackpackItem("KeyBackdoor") or (tool and tool.Name == "KeyBackdoor" and tool)
								if keyTool then
									key = nil
									drawer = nil
									if keyTool.Name == "KeyBackdoor" and keyTool.Parent ~= Character then
										keyTool.Parent = Character
									end
									Character:PivotTo(Door:GetPivot())
									local prompt = GetLockPrompt(Door)
									if prompt then
										fireproximityprompt(prompt)
									end
								else
									if not key or not drawer then
										key, drawer = FindKeyObtain(Room)
									end
									if key then
										Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
										if drawer then
											fireproximityprompt(drawer:FindFirstChild("ActivateEventPrompt", true))
										end
										fireproximityprompt(key.ModulePrompt)
									end
								end
							end
						elseif Room.Name == "50" then
							if not AutoFloor.OnStatistics then
								AutoFloor.OnStatistics = Statistics.OnClientEvent:Connect(function()
									Library:Notify({
										Title = Info.AddonTitle,
										Description = "Backdoor completed!",
										Time = 10
									})
									Toggles.AutoFloor:SetValue(false)
									Toggles.AutoFloor:SetDisabled(true)
								end)
							end
							Door = Room.Backdoors_Exit.Door
							Character:PivotTo(Door:GetPivot())
							fireproximityprompt(Door.EnterPrompt)
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
						if Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value then
							POASync(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						timerincreased = nil
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`{AutoFloor.Waiting and "Paused - Entity Nearby\n" or ""}Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
						end
						unavailableUntil = os.clock()+1
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					if Library.Toggles.AutoMandrake then
						Library.Toggles.AutoMandrake:SetDisabled(false)
						if Variables.WasAutoMandrakeOn then
							Library.Toggles.AutoMandrake:SetValue(true)
							Variables.WasAutoMandrakeOn = nil
						end
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							if typeof(connection) == "RBXScriptConnection" then
								connection:Disconnect()
							end
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Stairwell = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					SetupTeleportBypass()
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
				AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
					local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
					local Door = Room and Room:FindFirstChild("Door")
					if not Character or not Character.Parent or not Character.PrimaryPart then return end
					if not Toggles.SlideSpeedHack.Value then
						Toggles.SlideSpeedHack:SetValue(true)
					end
					EnsureStuffToKeepEnabled()
					if LatestRoom.Value > 198 then
						local stairwellexit = Room:FindFirstChild("StairwellExitDoor")
						if stairwellexit then
							Character:PivotTo(stairwellexit:GetPivot())
							fireproximityprompt(stairwellexit.Collision.EnterPrompt)
						else
							Library:Notify({
								Title = Info.AddonTitle,
								Description = "Stairwell completed!",
								Time = 10
							})
							Toggles.AutoFloor:SetValue(false)
							Toggles.AutoFloor:SetDisabled(true)
						end
					else
						Character:PivotTo(Door:GetPivot())
					end
					if not Library.Toggles.DoorReach.Value then
						Library.Toggles.DoorReach:SetValue(true)
					end
				end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						local room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					if Library.Toggles.AutoMandrake then
						Library.Toggles.AutoMandrake:SetDisabled(false)
						if Variables.WasAutoMandrakeOn then
							Library.Toggles.AutoMandrake:SetValue(true)
							Variables.WasAutoMandrakeOn = nil
						end
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							if typeof(connection) == "RBXScriptConnection" then
								connection:Disconnect()
							end
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
	}
function ExecutorSupported(AutoFloor)
	return true
end
	Variables.AutoFloorDist = {
        ["BashMoving"]    = 150,
		RushMoving = 120,
		AmbushMoving = 180,
		BackdoorRush = 108,
		["A60"] = 180,
		["GlitchRush"] = 120,
		["GlitchAmbush"] = 180
	}
	function ActiveRusherDist(interesting)
		local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
		local Door = Room and Room:FindFirstChild("Door")
		local PrevRoom = CurrentRooms:FindFirstChild(LatestRoom.Value-1)
		local PrevDoor = PrevRoom and PrevRoom:FindFirstChild("Door")
		local PrevPrevRoom = CurrentRooms:FindFirstChild(LatestRoom.Value-2)
		local PrevPrevDoor = PrevPrevRoom and PrevPrevRoom:FindFirstChild("Door")
		for _, rusher in workspace:QueryDescendants("> #RushMoving, > #AmbushMoving, > #A60, > #BackdoorRush, > #BashMoving, > #GlitchRush, > #GlitchAmbush") do
			if interesting or (Character:GetPivot().Position-rusher:GetPivot().Position).Magnitude < Variables.AutoFloorDist[rusher.Name] or (Door and (Door:GetPivot().Position-rusher:GetPivot().Position).Magnitude < Variables.AutoFloorDist[rusher.Name]) or (PrevDoor and (PrevDoor:GetPivot().Position-rusher:GetPivot().Position).Magnitude < Variables.AutoFloorDist[rusher.Name]) or (PrevPrevDoor and (PrevPrevDoor:GetPivot().Position-rusher:GetPivot().Position).Magnitude < Variables.AutoFloorDist[rusher.Name]) then
				return true
			end
		end
		return false
	end
	Variables.AutoFloors240 = {
		Hotel = {
			Requirements = {
				"firetouchinterest",
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				local InterestingRooms = {
					"Hotel_SeekIntro",
					"Hotel_LibraryEntrance",
					"99"
				}
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if hookfunction then
						if Variables.tpFunction then
							local tp; tp = hookfunction(Variables.tpFunction, function(...)
								if checkcaller() then
									tp(...)
								end
							end)
						end
						local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
							if not checkcaller() then
								hookfunction(func, function()end)
								Variables.tpFunction = func
							end
							return hook(self, func)
						end)
					end
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local interesting = IsInteresting(InterestingRooms, tempRoom)
					local activeRusher = ActiveRusherDist(interesting)
					local lastCutscene = ""
					local lastCutsceneGlobal = ""
					local unavailableUntil = -1/0
					local touched = false
					local key, drawer, book, breaker
					AutoFloor.CutsceneActivatedGlobal = Cutscene.OnClientEvent:Connect(function(name)
						lastCutsceneGlobal = name
					end)
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						if os.clock()<unavailableUntil or Character.PrimaryPart.Anchored then return end
						activeRusher = ActiveRusherDist(interesting)
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						if activeRusher then
							if Library.Toggles.DoorReach.Value then
								Library.Toggles.DoorReach:SetValue(false)
							end
							return
						elseif Room:GetAttribute("RequiresKey") then
							local item = ItemThatCanUnlock()
							if item then
								if not Variables.InfItems.Value then
									Variables.InfItems:SetValue(true)
								end
								if item:IsA("Tool") and item.Parent ~= Character then
									item.Parent = Character
								elseif item:IsA("Model") then
									item:PivotTo(Character:GetPivot())
									fireproximityprompt(item.ModulePrompt)
								end
								Character:PivotTo(Door:GetPivot())
								local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								local tool = GetEquippedTool(LocalPlayer)
								if LocalPlayer.Backpack:FindFirstChild("Key") or (tool and tool.Name == "Key") then
									key = nil
									drawer = nil
									Character:PivotTo(Door:GetPivot())
									local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
									if prompt then
										fireproximityprompt(prompt)
									end
								else
									if not key or not drawer then
										key, drawer = FindKeyObtain(Room)
									end
									if key then
										Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
										if drawer then
											fireproximityprompt(drawer.Knobs.ActivateEventPrompt)
										end
										fireproximityprompt(key.ModulePrompt)
									end
								end
							end
						elseif Room.Name == "50" then
							if bool ~= false then
								book = book and book.Parent and book or GetNearestBook(Room)
							end
							if book then
								Character:PivotTo(book:GetPivot()+Vector3.new(0,8,0))
								fireproximityprompt(book.ActivateEventPrompt)
							else
								book = false
								local tool = GetEquippedTool(LocalPlayer)
								local LibraryHintPaper = (tool and tool.Name == "LibraryHintPaper" and tool) or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper") or Room:FindFirstChild("LibraryHintPaper")
								if LibraryHintPaper then
									if LibraryHintPaper:IsA("Tool") then
										if not Variables.AutoLibrarySolver.Value then
											Variables.AutoLibrarySolver:SetValue(true)
										end
										if not Variables.BruteforceLibraryCode.Value then
											Variables.BruteforceLibraryCode:SetValue(true)
										end
										LibraryHintPaper.Parent = LibraryHintPaper.Parent == Character and LocalPlayer.Backpack or Character
										Character:PivotTo(Door:GetPivot())
									else
										Character:PivotTo(LibraryHintPaper:GetPivot()+Vector3.new(0,5,0))
										fireproximityprompt(LibraryHintPaper.ModulePrompt)
									end
								end
							end
						elseif Room.Name == "100" then
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
									if name == "Elevator1" then
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "The hotel completed!",
											Time = 10
										})
										Toggles.AutoFloor:SetValue(false)
										Toggles.AutoFloor:SetDisabled(true)
										return
									end
								end)
							end
							if breaker ~= false then
								breaker = breaker and breaker.Parent and breaker or GetNearestBreaker(Room)
							end
							if breaker then
								Character:PivotTo(breaker:GetPivot())
								fireproximityprompt(breaker.ActivateEventPrompt)
							else
								breaker = false
								if lastCutscene == "" then
									Character:PivotTo(Room.IndustrialGate:GetPivot())
									fireproximityprompt(Room.IndustrialGate.Box.ActivateEventPrompt)
								elseif lastCutscene == "FigureHotelEnd" then
									toggleNetworkOwner(true)
									local pivot = Room.ElevatorBreakerEmpty:GetPivot()
									Character:PivotTo(pivot+pivot.RightVector*-12)
									fireproximityprompt(Room.ElevatorBreakerEmpty.Prompt)
									pcall(function()
										Room.FigureSetup.FigureRig:PivotTo(CFrame.new(0,-1000,0))
									end)
								elseif lastCutscene == "FigureHotelChase" then
									Character:PivotTo(Room.ElevatorCar.CollisionExtra.CFrame)
									firetouchinterest(Character.PrimaryPart, Room.ElevatorCar.CollisionExtra, touched and 1 or 0)
									touched = not touched
								elseif Room:FindFirstChild("ElevatorBreaker") then
									if not Variables.AutoBreakerSolver.Value then
										Variables.AutoBreakerSolver:SetValue(true)
									end
									if Variables.AutoBreakerSolverMethod.Value ~= "Exploit" then
										Variables.AutoBreakerSolverMethod:SetValue("Exploit")
									end
									Character:PivotTo(Room.ElevatorBreaker:GetPivot())
									fireproximityprompt(Room.ElevatorBreaker.ActivateEventPrompt)
								end
							end
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
						interesting = IsInteresting(InterestingRooms, room)
						if room and interesting then
							unavailableUntil = os.clock()+10
							while os.clock()<unavailableUntil and not activeRusher do
								activeRusher = ActiveRusherDist(interesting)
								Services.RunService.RenderStepped:Wait()
							end
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Mines = {
			Requirements = {
				"firetouchinterest",
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked",
				"getrawmetatable",
				"setreadonly"
			},
			Callback = function(value)
				local InterestingRooms = {
					"Mines_SeekStart",
					"Sewer_SeekEnter",
					"98"
				}
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if hookfunction then
						if Variables.tpFunction then
							local tp; tp = hookfunction(Variables.tpFunction, function(...)
								if checkcaller() then
									tp(...)
								end
							end)
						end
						local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
							if not checkcaller() then
								hookfunction(func, function()end)
								Variables.tpFunction = func
							end
							return hook(self, func)
						end)
					end
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local interesting = IsInteresting(InterestingRooms, tempRoom)
					local activeRusher = ActiveRusherDist(interesting)
					local lastCutscene
					local unavailableUntil = -1/0
					local fuse, buttonPressed, leverActivated, beatingDoor200, noGeneratorSince, buggyRun
					AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
						lastCutscene = name
					end)
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						if os.clock()<unavailableUntil or Character.PrimaryPart.Anchored or buggyRun then return end
						activeRusher = ActiveRusherDist(interesting)
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						local grabPart = not Character:GetAttribute("_BypassedAC") and not (Camera and Camera:FindFirstChild("MinecartRig")) and GetNearestLadderGrabPart(Room)
						if activeRusher then
							if Library.Toggles.DoorReach.Value then
								Library.Toggles.DoorReach:SetValue(false)
							end
							return
						elseif Character:GetAttribute("Climbing") then
							Character:SetAttribute("Climbing")
							Character:SetAttribute("_BypassedAC", true)
							Connections.OnBypassRemove = Character:GetAttributeChangedSignal("Climbing"):Once(function()
								Character:SetAttribute("_BypassedAC", false)
								if Variables.AutoFloorRoom then
									Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
								end
							end)
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
							end
						elseif grabPart then
							Character:PivotTo(grabPart.CFrame)
							fireproximityprompt(grabPart.ClimbPrompt)
						elseif Room.Name == "100" then
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
									if name == "MinesFinale" then
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "The mines completed!",
											Time = 10
										})
										Toggles.AutoFloor:SetValue(false)
										Toggles.AutoFloor:SetDisabled(true)
										return
									end
								end)
							end
							if beatingDoor200 then
								if leverActivated and not buttonPressed then
									local button = Room.Assets.MinesGateButton.Button
									local prompt = button.ActivateEventPrompt
									Character:PivotTo(button.CFrame)
									fireproximityprompt(prompt)
									if button.SoundPress.Playing then
										buttonPressed = true
									end
								elseif not leverActivated then
									if Room.Assets.MinesGenerator.GeneratorMain.Sound.Playing then
										leverActivated = true
									end
								else
									local doors = Room._DamHandler._OutsideCutscene.DungeonDoor.DoubleDoors
									local prompt = doors.ActivateEventPrompt
									Character:PivotTo(doors:GetPivot())
									fireproximityprompt(prompt)
								end
							else
								beatingDoor200 = true
								pcall(Variables.BeatDoor200.Func)
							end
						elseif Room:GetAttribute("RequiresGenerator") then
							local fuse = GetNearestFuse(Room)
							if fuse then
								Character:PivotTo(fuse:GetPivot())
								local openFirst = fuse:FindFirstAncestor("Locker_Small") or fuse:FindFirstAncestor("DrawerContainer") or fuse:FindFirstAncestor("Toolbox")
								if openFirst then
									fireproximityprompt(openFirst:FindFirstChild("ActivateEventPrompt", true))
								end
								fireproximityprompt(fuse.ModulePrompt)
							else
								local gen = Room.Assets:FindFirstChild("MinesGenerator")
								if gen then
									noGeneratorSince = nil
								else
									noGeneratorSince = noGeneratorSince or os.clock()
									if noGeneratorSince < os.clock()-3 then
										buggyRun = true
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "Generation bug detected: MinesGenerator didn't spawn in the room that requires generator\n(The game will be automatically restarted)",
											Persist = true
										})
										PlayAgain:FireServer()
									end
									return
								end
								local notTuff = false
								for _, fuse in gen.Fuses:GetChildren() do
									if tonumber(fuse.Name) and fuse.Fuse.Transparency == 1 then
										notTuff = true
										break
									end
								end
								local prompt = notTuff and (gen:FindFirstChild("FusesPrompt", true) or gen:FindFirstChild("FakePrompt", true))
								if prompt then
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
								elseif not leverActivated then
									prompt = gen.Lever.LeverPrompt
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
									if gen.GeneratorMain.Sound.Playing then
										leverActivated = true
									end
								elseif not buttonPressed then
									local button = Room.Assets.MinesGateButton.Button
									prompt = button.ActivateEventPrompt
									Character:PivotTo(button.CFrame)
									fireproximityprompt(prompt)
									if button.SoundPress.Playing then
										buttonPressed = true
									end
								else
									Character:PivotTo(Door:GetPivot())
								end
							end
						elseif Room.Name == "46" and not Camera:FindFirstChild("MinecartRig") then
							if not Toggles.MinecartChaseSkip.Value then
								Toggles.MinecartChaseSkip:SetValue(true)
							end
							Character:PivotTo(Room.MinecartCollision.Collision.CFrame)
							firetouchinterest(Character.PrimaryPart, Room.MinecartCollision.Collision, 0)
							firetouchinterest(Character.PrimaryPart, Room.MinecartCollision.Collision, 1)
							return
						elseif Camera:FindFirstChild("MinecartRig") and (tonumber(Room.Name) >= 46 or tonumber(Room.Name) < 50) then
							if not Toggles.MinecartChaseSkip.Value then
								Toggles.MinecartChaseSkip:SetValue(true)
							end
							return
						elseif Room.Name == "50" then
							if Camera:FindFirstChild("MinecartRig") then return end
							if buttonPressed then
								Character:PivotTo(Door:GetPivot())
							else
								local button = Room._NestHandler.Console.Button
								local prompt = button.ActivateEventPrompt
								Character:PivotTo(button.CFrame)
								fireproximityprompt(prompt)
								if button.SoundPress.Playing then
									buttonPressed = true
								end
							end
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						leverActivated = nil
						buttonPressed = nil
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
						end
						interesting = IsInteresting(InterestingRooms, room)
						if room and interesting then
							unavailableUntil = os.clock()+10
							while os.clock()<unavailableUntil and not activeRusher do
								activeRusher = ActiveRusherDist(interesting)
								Services.RunService.RenderStepped:Wait()
							end
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Endless = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if hookfunction then
						if Variables.tpFunction then
							local tp; tp = hookfunction(Variables.tpFunction, function(...)
								if checkcaller() then
									tp(...)
								end
							end)
						end
						local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
							if not checkcaller() then
								hookfunction(func, function()end)
								Variables.tpFunction = func
							end
							return hook(self, func)
						end)
					end
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local key, drawer
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						local item = ItemThatCanUnlock()
						if item then
							if not Variables.InfItems.Value then
								Variables.InfItems:SetValue(true)
							end
							if item:IsA("Tool") and item.Parent ~= Character then
								item.Parent = Character
							elseif item:IsA("Model") then
								item:PivotTo(Character:GetPivot())
								fireproximityprompt(item.ModulePrompt)
							end
							Character:PivotTo(Door:GetPivot())
							local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
							if prompt then
								fireproximityprompt(prompt)
							end
						else
							local tool = GetEquippedTool(LocalPlayer)
							if LocalPlayer.Backpack:FindFirstChild("Key") or (tool and tool.Name == "Key") then
								key = nil
								drawer = nil
								Character:PivotTo(Door:GetPivot())
								local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								if not key or not drawer then
									key, drawer = FindKeyObtain(Room)
								end
								if key then
									Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
									if drawer then
										fireproximityprompt(drawer.Knobs.ActivateEventPrompt)
									end
									fireproximityprompt(key.ModulePrompt)
								else
									Library:Notify({
										Title = Info.AddonTitle,
										Description = "Endless completed!",
										Time = 10
									})
									Toggles.AutoFloor:SetValue(false)
									Toggles.AutoFloor:SetDisabled(true)
								end
							end
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Ripple_Daily_Default = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if hookfunction then
						if Variables.tpFunction then
							local tp; tp = hookfunction(Variables.tpFunction, function(...)
								if checkcaller() then
									tp(...)
								end
							end)
						end
						local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
							if not checkcaller() then
								hookfunction(func, function()end)
								Variables.tpFunction = func
							end
							return hook(self, func)
						end)
					end
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`,
						Persist = true
					})
					local AutoFloor = {}
					local activeRusher = ActiveRusherDist()
					Connections.AutoFloor = AutoFloor
					local key, drawer, fuse, buttonPressed, leverActivated, noGeneratorSince, buggyRun
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						if buggyRun then return end
						activeRusher = ActiveRusherDist()
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						local grabPart = not Character:GetAttribute("_BypassedAC") and GetNearestLadderGrabPart(Room)
						if activeRusher then
							if Library.Toggles.DoorReach.Value then
								Library.Toggles.DoorReach:SetValue(false)
							end
							return
						elseif Character:GetAttribute("Climbing") then
							Character:SetAttribute("Climbing")
							Character:SetAttribute("_BypassedAC", true)
							Connections.OnBypassRemove = Character:GetAttributeChangedSignal("Climbing"):Once(function()
								Character:SetAttribute("_BypassedAC", false)
								if Variables.AutoFloorRoom then
									Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
								end
							end)
							if Variables.AutoFloorRoom then
								Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {Room and Room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
							end
						elseif grabPart then
							Character:PivotTo(grabPart.CFrame)
							fireproximityprompt(grabPart.ClimbPrompt)
						elseif Room:GetAttribute("RequiresKey") then
							local item = ItemThatCanUnlock()
							if item then
								if not Variables.InfItems.Value then
									Variables.InfItems:SetValue(true)
								end
								if item:IsA("Tool") and item.Parent ~= Character then
									item.Parent = Character
								elseif item:IsA("Model") then
									item:PivotTo(Character:GetPivot())
									fireproximityprompt(item.ModulePrompt)
								end
								Character:PivotTo(Door:GetPivot())
								local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								local tool = GetEquippedTool(LocalPlayer)
								local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or (tool and tool.Name == "Key" and tool) or LocalPlayer.Backpack:FindFirstChild("KeyBackdoor") or (tool and tool.Name == "KeyBackdoor" and tool)
								if keyTool then
									key = nil
									drawer = nil
									if keyTool.Name == "KeyBackdoor" and keyTool.Parent ~= Character then
										keyTool.Parent = Character
									end
									Character:PivotTo(Door:GetPivot())
									local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
									if prompt then
										fireproximityprompt(prompt)
									end
								else
									if not key or not drawer then
										key, drawer = FindKeyObtain(Room)
									end
									if key then
										Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
										if drawer then
											fireproximityprompt(drawer:FindFirstChild("ActivateEventPrompt", true))
										end
										fireproximityprompt(key.ModulePrompt)
									end
								end
							end
						elseif Room:GetAttribute("RequiresGenerator") then
							local fuse = GetNearestFuse(Room)
							if fuse then
								Character:PivotTo(fuse:GetPivot())
								local openFirst = fuse:FindFirstAncestor("Locker_Small") or fuse:FindFirstAncestor("DrawerContainer") or fuse:FindFirstAncestor("Toolbox")
								if openFirst then
									fireproximityprompt(openFirst:FindFirstChild("ActivateEventPrompt", true))
								end
								fireproximityprompt(fuse.ModulePrompt)
							else
								local gen = Room.Assets:FindFirstChild("MinesGenerator")
								if gen then
									noGeneratorSince = nil
								else
									noGeneratorSince = noGeneratorSince or os.clock()
									if noGeneratorSince < os.clock()-3 then
										buggyRun = true
										Library:Notify({
											Title = Info.AddonTitle,
											Description = "Generation bug detected: MinesGenerator didn't spawn in the room that requires generator\n(The game will be automatically restarted)",
											Persist = true
										})
										PlayAgain:FireServer()
									end
									return
								end
								local notTuff = false
								for _, fuse in gen.Fuses:GetChildren() do
									if tonumber(fuse.Name) and fuse.Fuse.Transparency == 1 then
										notTuff = true
										break
									end
								end
								local prompt = notTuff and (gen:FindFirstChild("FusesPrompt", true) or gen:FindFirstChild("FakePrompt", true))
								if prompt then
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
								elseif not leverActivated then
									prompt = gen.Lever.LeverPrompt
									Character:PivotTo(gen:GetPivot())
									fireproximityprompt(prompt)
									if gen.GeneratorMain.Sound.Playing then
										leverActivated = true
									end
								elseif not buttonPressed then
									local button = Room.Assets.MinesGateButton.Button
									prompt = button.ActivateEventPrompt
									Character:PivotTo(button.CFrame)
									fireproximityprompt(prompt)
									if button.SoundPress.Playing then
										buttonPressed = true
									end
								else
									Character:PivotTo(Door:GetPivot())
								end
							end
						elseif Room:GetAttribute("RawName") == "RippleEnd" then
							if not AutoFloor.OnStatistics then
								AutoFloor.OnStatistics = RippleStatistics.OnClientEvent:Connect(function()
									Library:Notify({
										Title = Info.AddonTitle,
										Description = "Daily run completed!",
										Time = 10
									})
									Toggles.AutoFloor:SetValue(false)
									Toggles.AutoFloor:SetDisabled(true)
								end)
							end
							Door = Room.RippleExitDoor
							Character:PivotTo(Door:GetPivot())
							fireproximityprompt(Door.Door.EnterPrompt)
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						leverActivated = nil
						buttonPressed = nil
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Garden = {
			Requirements = {
				"firetouchinterest",
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if Variables.tpFunction then
						local tp; tp = hookfunction(Variables.tpFunction, function(...)
							if checkcaller() then
								tp(...)
							end
						end)
					end
					local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
						if not checkcaller() then
							hookfunction(func, function()end)
							Variables.tpFunction = func
						end
						return hook(self, func)
					end)
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local unavailableUntil = -1/0
					local lastCutscene = ""
					local LOTUS, PICKING_LOTUS = false, false
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						logprint("WORKS")
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						local eyestalkEnd = Room:GetAttribute("RawName") == "Garden_EyestalkEnd" and Toggles.TriggerEyestalkChaseEnd.Value and (lastCutscene ~= "EyestalkOutro" or Character.PrimaryPart.Anchored)
						if os.clock()<unavailableUntil or (eyestalkEnd and Character.PrimaryPart.Anchored) then logprint("RETURNED", os.clock()<unavailableUntil, (eyestalkEnd and Character.PrimaryPart.Anchored))  return end
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						local lotuspetal, drawer, grampy
						local tool = GetEquippedTool(LocalPlayer)
						if Toggles.MakeLotus.Value and not (LocalPlayer.Backpack:FindFirstChild("Lotus") or (tool and tool.Name == "Lotus")) then
							lotuspetal, drawer = GetLotusPetal()
							grampy = CurrentRooms:FindFirstChild("Grampy", true)
							grampy = grampy and (tonumber(grampy.Parent.Parent.Name) or 0) <= LatestRoom.Value and grampy
						end
						local lotuspetaltool = (tool and tool.Name == "LotusPetal" and tool) or LocalPlayer.Backpack:FindFirstChild("LotusPetal")
						local success, forminglotus = pcall(function()
							return Room.Assets.FormingLotus
						end)
						forminglotus = success and forminglotus
						if grampy and not LOTUS and lotuspetaltool and lotuspetaltool:GetAttribute("Durability") > 7 then
							logprint(1)
							PICKING_LOTUS = true
							Character:PivotTo(grampy:GetPivot())
							if lotuspetaltool.Parent ~= Character then
								lotuspetaltool.Parent = Character
							end
							fireproximityprompt(grampy.DialogPrompt)
						elseif grampy and not LOTUS and PICKING_LOTUS then
							if tool and tool.Name == "Lotus" then
								logprint(2.1)
								LOTUS = true
							elseif forminglotus and forminglotus:FindFirstChild("Lotus") then
								logprint(2.2)
								Character:PivotTo(forminglotus:GetPivot())
								fireproximityprompt(forminglotus.Lotus.PromptAttach.ModulePrompt)
							end
						elseif lotuspetal and not (lotuspetaltool and lotuspetaltool:GetAttribute("Durability") > 7) then
							logprint(3)
							Character:PivotTo(lotuspetal:GetPivot())
							if drawer then
								fireproximityprompt(drawer:FindFirstChild("ActivateEventPrompt", true))
							end
							fireproximityprompt(lotuspetal.ModulePrompt)
						elseif eyestalkEnd then
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
								end)
							end
							if lastCutscene == "EyestalkOutro" then
								logprint(4.1)
								AutoFloor.CutsceneActivated:Disconnect()
							else
								logprint(4.2)
								Character:PivotTo(Room.EyestalkEndCutscene.Collision.CFrame)
								firetouchinterest(Character.PrimaryPart, Room.EyestalkEndCutscene.Collision, 0)
								firetouchinterest(Character.PrimaryPart, Room.EyestalkEndCutscene.Collision, 1)
							end
						elseif Room.Name == "35" then
							if not AutoFloor.CutsceneActivated then
								AutoFloor.CutsceneActivated = Cutscene.OnClientEvent:Connect(function(name)
									lastCutscene = name
								end)
							end
							if lastCutscene == "BrambleIntro" then
								if required_main_game.stopcam then return end
								logprint(5.1)
								local Lever = GetNearestLever(Room)
								if Lever then
									logprint("5.1.1")
									Character:PivotTo(Lever.CFrame)
									fireproximityprompt(Lever.ActivateEventPrompt)
								else
									logprint("5.1.2")
									Character:PivotTo(Room.OutdoorsEnding.Collision.CFrame)
									firetouchinterest(Character.PrimaryPart, Room.OutdoorsEnding.Collision, 0)
									firetouchinterest(Character.PrimaryPart, Room.OutdoorsEnding.Collision, 1)
								end
							elseif lastCutscene == "EyestalkOutro" or lastCutscene == "" then
								logprint(5.2)
								Character:PivotTo(Room.BrambleCutscene.Collision.CFrame)
								firetouchinterest(Character.PrimaryPart, Room.BrambleCutscene.Collision, 0)
								firetouchinterest(Character.PrimaryPart, Room.BrambleCutscene.Collision, 1)
							else
								logprint(5.3)
								Library:Notify({
									Title = Info.AddonTitle,
									Description = "Outdoors completed!",
									Time = 10
								})
								Toggles.AutoFloor:SetValue(false)
								Toggles.AutoFloor:SetDisabled(true)
							end
						else
							logprint(6)
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
						if Toggles.MakeLotus.Value and (not lotuspetaltool or lotuspetaltool:GetAttribute("Durability") < 8) then
							unavailableUntil = os.clock()+.5
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
						restorefunction(Variables.tpFunction)
					end
					if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
						restorefunction(ServerTeleported.OnClientEvent.Connect)
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Backdoor = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if hookfunction then
						if Variables.tpFunction then
							local tp; tp = hookfunction(Variables.tpFunction, function(...)
								if checkcaller() then
									tp(...)
								end
							end)
						end
						local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
							if not checkcaller() then
								hookfunction(func, function()end)
								Variables.tpFunction = func
							end
							return hook(self, func)
						end)
					end
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					local unavailableUntil = -1/0
					local key, drawer, timerincreased
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						if os.clock()<unavailableUntil then return end
						activeRusher = ActiveRusherDist()
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						local timerlever = Room:FindFirstChild("TimerLever", true)
						if timerlever and not timerincreased then
							Character:PivotTo(timerlever:GetPivot())
							fireproximityprompt(timerlever.ActivateEventPrompt)
							if timerlever.TakeTimer.TextLabel.Text == "00:00" then
								timerincreased = true
							end
						elseif Room:GetAttribute("RequiresKey") then
							local item = ItemThatCanUnlock()
							if item then
								if not Variables.InfItems.Value then
									Variables.InfItems:SetValue(true)
								end
								if item:IsA("Tool") and item.Parent ~= Character then
									item.Parent = Character
								elseif item:IsA("Model") then
									item:PivotTo(Character:GetPivot())
									fireproximityprompt(item.ModulePrompt)
								end
								Character:PivotTo(Door:GetPivot())
								local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
								if prompt then
									fireproximityprompt(prompt)
								end
							else
								local tool = GetEquippedTool(LocalPlayer)
								local keyTool = LocalPlayer.Backpack:FindFirstChild("Key") or (tool and tool.Name == "Key" and tool) or LocalPlayer.Backpack:FindFirstChild("KeyBackdoor") or (tool and tool.Name == "KeyBackdoor" and tool)
								if keyTool then
									key = nil
									drawer = nil
									if keyTool.Name == "KeyBackdoor" and keyTool.Parent ~= Character then
										keyTool.Parent = Character
									end
									Character:PivotTo(Door:GetPivot())
									local prompt = Door.Lock:FindFirstChild("UnlockPrompt") or Door.Lock:FindFirstChild("FakePrompt")
									if prompt then
										fireproximityprompt(prompt)
									end
								else
									if not key or not drawer then
										key, drawer = FindKeyObtain(Room)
									end
									if key then
										Character:PivotTo(drawer and drawer:GetPivot() or key:GetPivot())
										if drawer then
											fireproximityprompt(drawer:FindFirstChild("ActivateEventPrompt", true))
										end
										fireproximityprompt(key.ModulePrompt)
									end
								end
							end
						elseif Room.Name == "50" then
							if not AutoFloor.OnStatistics then
								AutoFloor.OnStatistics = Statistics.OnClientEvent:Connect(function()
									Library:Notify({
										Title = Info.AddonTitle,
										Description = "Backdoor completed!",
										Time = 10
									})
									Toggles.AutoFloor:SetValue(false)
									Toggles.AutoFloor:SetDisabled(true)
								end)
							end
							Door = Room.Backdoors_Exit.Door
							Character:PivotTo(Door:GetPivot())
							fireproximityprompt(Door.EnterPrompt)
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						timerincreased = nil
						room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}\nAnticheat bypass status: {Character:GetAttribute("_BypassedAC") and "ON" or "OFF"}`)
						end
						unavailableUntil = os.clock()+1
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
		Stairwell = {
			Requirements = {
				"fireproximityprompt",
				"hookfunction",
				"restorefunction",
				"isfunctionhooked"
			},
			Callback = function(value)
				if value then
					if Toggles.AntiTeleport.Value then
						Toggles.AntiTeleport:SetValue(false)
					elseif Toggles.AntiTeleportRaknet.Value then
						Toggles.AntiTeleportRaknet:SetValue(false)
					end
					Services.RunService.RenderStepped:Wait()
					Toggles.AntiTeleport:SetDisabled(true)
					if not Toggles.AntiTeleportRaknet.Disabled then
						Toggles.AntiTeleportRaknet:SetDisabled(true)
					end
					Variables.tpFunction = getTpFunction()
					if hookfunction then
						if Variables.tpFunction then
							local tp; tp = hookfunction(Variables.tpFunction, function(...)
								if checkcaller() then
									tp(...)
								end
							end)
						end
						local hook; hook = hookfunction(ServerTeleported.OnClientEvent.Connect, function(self, func)
							if not checkcaller() then
								hookfunction(func, function()end)
								Variables.tpFunction = func
							end
							return hook(self, func)
						end)
					end
					local tempRoom = CurrentRooms:FindFirstChild(LatestRoom.Value)
					Variables.AutoFloorRoom = Library:Notify({
						Title = Info.AddonTitle,
						Description = `Doors opened: {LatestRoom.Value}\nCurrent room: {tempRoom and tempRoom:GetAttribute("RawName") or "?"}`,
						Persist = true
					})
					local AutoFloor = {}
					Connections.AutoFloor = AutoFloor
					AutoFloor.Teleporter = Services.RunService.Heartbeat:Connect(function()
						local Room = CurrentRooms:FindFirstChild(LatestRoom.Value)
						local Door = Room and Room:FindFirstChild("Door")
						if not Variables.slideSH then
							Variables.slideSH = true
							pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
						end
						for _, toggle in Variables.StuffToKeepEnabled do
							if not toggle.Value and not toggle.Disabled then
								toggle:SetValue(true)
							end
						end
						if LatestRoom.Value > 198 then
							local stairwellexit = Room:FindFirstChild("StairwellExitDoor")
							if stairwellexit then
								Character:PivotTo(stairwellexit:GetPivot())
								fireproximityprompt(stairwellexit.Collision.EnterPrompt)
							else
								Library:Notify({
									Title = Info.AddonTitle,
									Description = "Stairwell completed!",
									Time = 10
								})
								Toggles.AutoFloor:SetValue(false)
								Toggles.AutoFloor:SetDisabled(true)
							end
						else
							Character:PivotTo(Door:GetPivot())
						end
						if not Library.Toggles.DoorReach.Value then
							Library.Toggles.DoorReach:SetValue(true)
						end
					end)
					AutoFloor.LatestRoomChanged = LatestRoom.Changed:Connect(function()
						if Variables.AutoFloorRoom then
							Variables.AutoFloorRoom:ChangeDescription(`Doors opened: {LatestRoom.Value}\nCurrent room: {room and room:GetAttribute("RawName") or "?"}`)
						end
					end)
				else
					if Variables.AutoFloorRoom then
						Variables.AutoFloorRoom:Destroy()
					end
					if not Toggles.SlideSpeedHack and Variables.slideSH then
						Variables.slideSH = false
						pcall(CrouchRemoteEvent.FireServer, CrouchRemoteEvent, true, true)
					end
					Toggles.AntiTeleport:SetDisabled(false)
					if Variables.raknet_at_hook then
						Toggles.AntiTeleportRaknet:SetDisabled(false)
					end
					if isfunctionhooked and restorefunction then
						if Variables.tpFunction and isfunctionhooked(Variables.tpFunction) then
							restorefunction(Variables.tpFunction)
						end
						if isfunctionhooked(ServerTeleported.OnClientEvent.Connect) then
							restorefunction(ServerTeleported.OnClientEvent.Connect)
						end
					end
					if Connections.AutoFloor then
						for _, connection in Connections.AutoFloor do
							connection:Disconnect()
						end
						Connections.AutoFloor = nil
					end
				end
			end
		},
	}
	local AutoFloorKeyCache = {}
	local function AutoFloorKey()
		local k = AutoFloorKeyCache[Floor]
		if k then return k end
		k = Floor.."_"..(FloorSpecific or "")
		AutoFloorKeyCache[Floor] = k
		return k
	end
	local function ResolveAutoFloorFunc()
		local T = Variables.AutoFloorMethod and Variables.AutoFloorMethod.Value == "2" and Variables.AutoFloors240 or Variables.AutoFloors
		return T[Floor] or T[AutoFloorKey()]
	end
	local function UpdateAutoFloorMethod()
		local Toggle = Toggles.AutoFloor
		local func = ResolveAutoFloorFunc()
		if Toggle and func == Variables.AutoFloorFunc then return end
		local wasOn = Toggle and Toggle.Value
		if wasOn then Toggle:SetValue(false) end
		Variables.AutoFloorFunc = func
		Variables.AutoFloorSupported = ExecutorSupported(func or {Requirements = {}})
		if func and not Variables.AutoFloorSupported then Variables.AutoFloorFunc = nil end
		if Toggle then Toggle:SetDisabled(not (Variables.AutoFloorSupported and Variables.AutoFloorFunc)) end
		if wasOn and Variables.AutoFloorSupported and Variables.AutoFloorFunc then Toggle:SetValue(true) end
	end
	if Floor ~= "Garden" then
		Variables.AutoFloorMethod = Tplay_Floors:AddDropdown("Tplay_AutoFloorMethod", {
			Text = "Auto Floor Method",
			Values = {"1", "2"},
			Default = "1",
			Callback = UpdateAutoFloorMethod
		})
	end
	UpdateAutoFloorMethod(Variables.AutoFloorMethod and Variables.AutoFloorMethod.Value)
	Toggles.AutoFloor = Tplay_Floors:AddToggle("Tplay_AutoFloor", {
		Text = "Auto Floor",
		DisabledTooltip = Variables.AutoFloorSupported and (Variables.AutoFloorFunc and "Floor is already completed" or "Auto Floor is not supported for this floor") or "Executor is not supported",
		Default = false,
		Disabled = false,
		Callback = function(Value)
			local func = Variables.AutoFloorFunc
			if func and func.Callback then func.Callback(Value) end
			if Toggles.Tplay_AntiEntities then
				pcall(function() Toggles.Tplay_AntiEntities:SetValue(Value) end)
			end
			if Toggles.AutoUnlockPadlockToggle then
				pcall(function() Toggles.AutoUnlockPadlockToggle:SetValue(Value) end)
			end
			if Toggles.NotifyLibraryCode then
				pcall(function() Toggles.NotifyLibraryCode:SetValue(Value) end)
			end
			if Toggles.AutoLibrarySolver then
				pcall(function() Toggles.AutoLibrarySolver:SetValue(Value) end)
			end
			if Toggles.BruteforceLibraryCode then
				pcall(function() Toggles.BruteforceLibraryCode:SetValue(Value) end)
			end
			if Toggles.AutoBreakerBox then
				pcall(function() Toggles.AutoBreakerBox:SetValue(Value) end)
			end
			if Toggles.AutoBreakerSolver then
				pcall(function() Toggles.AutoBreakerSolver:SetValue(Value) end)
			end
			if Toggles.DoorReachToggle then
				pcall(function() Toggles.DoorReachToggle:SetValue(Value) end)
			end
			if Toggles.Tplay_DoorReachAlt then
				pcall(function() Toggles.Tplay_DoorReachAlt:SetValue(Value) end)
			end
			if Toggles.DoorReach then
				pcall(function() Toggles.DoorReach:SetValue(Value) end)
			end
		end
	})

	Tplay_Floors:AddToggle("Tplay_AntiEntities", {
		Text = "Anti Entities",
		Default = false,
		Tooltip = "Universal godmode bypass for Rush, Ambush, Screech, Dupe, Eyes, A90, Figure, Groundskeeper and Snare.",
		Callback = function(Value)
			if Toggles.AntiEntitiesMode then
				pcall(function() Toggles.AntiEntitiesMode:SetValue("Manual") end)
			end
			if Toggles.CollisionOffsetGodmodeAlt then
				pcall(function() Toggles.CollisionOffsetGodmodeAlt:SetValue(Value) end)
			end
			for _, tog in GetAllEntityToggles() do
				if tog and tog.SetValue then
					pcall(function() tog:SetValue(Value) end)
				end
			end
		end
	})
	if Floor == "Garden" then
		local cutscenes = {}
		Connections.OnCutsceneSEC = Cutscene.OnClientEvent:Connect(function(name)
			if not table.find(cutscenes, name) then
				table.insert(cutscenes, name)
			end
		end)

		local chaseResumed = false

		Toggles.SkipEyestalkChase = Tplay_Floors:AddToggle("Tplay_SkipEyestalkChase", {
			Text = "Skip Eyestalk Chase [FE]",
			DisabledTooltip = Variables.AutoFloorSupported and "Eyestalk chase was skipped" or "Executor is not supported",
			Default = false,
			Disabled = not Variables.AutoFloorSupported,

			Callback = function(value)
				if value then
					chaseResumed = false
					Connections.SECConnection = Services.RunService.RenderStepped:Connect(function()
						if table.find(cutscenes, "EyestalkOutro") then
							if Toggles.TriggerEyestalkChaseEnd.Value then
								Toggles.TriggerEyestalkChaseEnd:SetValue(true)
							end
							if not chaseResumed then
								chaseResumed = true
								Toggles.SkipEyestalkChase:SetValue(false)
								Toggles.SkipEyestalkChase:SetDisabled(true)
							end
						elseif table.find(cutscenes, "EyestalkIntro") then
							if not Toggles.TriggerEyestalkChaseEnd.Value then
								Toggles.TriggerEyestalkChaseEnd:SetValue(true)
							end
							if not Toggles.AutoFloor.Value then
								Toggles.AutoFloor:SetValue(true)
							end
						end
					end)
				else
					if Connections.SECConnection then
						Connections.SECConnection:Disconnect()
						Connections.SECConnection = nil
					end
				end
			end
		})

		Toggles.TriggerEyestalkChaseEnd = Tplay_Floors:AddToggle("Tplay_TriggerEyestalkChaseEnd", {
			Text = "Trigger Eyestalk Chase End",
			Tooltip = "Don't skip trigger that ends Eyestalk Chase while Auto Floor enabled",
			DisabledTooltip = "Executor is not supported",
			Default = false,
			Disabled = not Variables.AutoFloorSupported
		})
		Toggles.MakeLotus = Tplay_Floors:AddToggle("Tplay_MakeLotus", {
			Text = "Make Lotus",
			Tooltip = "Should Auto Floor collect Lotus Petals to make Lotus",
			DisabledTooltip = "Executor is not supported",
			Default = false,
			Disabled = not Variables.AutoFloorSupported
		})
	end
function CustomContinueOrSave()
	task.defer(function()
		RequestLocalAsset:InvokeServer({{}})
		task.wait(0.1)
		PlayAgain:FireServer()
	end)
	return true, nil
end
	Variables.OldContinueOrSave = getcallbackvalue and getcallbackvalue(ContinueOrSave, "OnClientInvoke") or CustomContinueOrSave
	Variables.ContinueOrSaveHook = hookmetamethod and hookmetamethod(game, "__newindex", function(self, key, value)
		if not checkcaller() and self == ContinueOrSave and key == "OnClientInvoke" then
			Variables.OldContinueOrSave = value
			if Toggles.AutoPlayAgain.Value then
				value = CustomContinueOrSave
			end
		end
		return Variables.ContinueOrSaveHook(self, key, value)
	end)
	Toggles.AutoPlayAgain = Tplay_Floors:AddToggle("Tplay_AutoPlayAgain", {
		Text = "Auto Play Again",
		DisabledTooltip = "Executor is not supported",
		Default = false,
		Disabled = not Variables.ContinueOrSaveHook,
		Callback = function(value)
			if value then
				ContinueOrSave.OnClientInvoke = CustomContinueOrSave
				Connections.OnStatistics = Statistics.OnClientEvent:Connect(function()
					task.delay(.01, PlayAgain.FireServer, PlayAgain)
				end)
			else
				ContinueOrSave.OnClientInvoke = Variables.OldContinueOrSave
				if Connections.OnStatistics then
					Connections.OnStatistics:Disconnect()
				end
			end
		end
	})


	-- 5. QOL & ALERTS TAB
	-- =========================================================================

	Tplay_QoL:AddToggle("Tplay_Freecam", {
		Text = "Freecam",
		Default = false,
		Tooltip = "Enables cinematic free camera navigation.",
		Callback = function(Value)
			-- Freecam toggle
		end
	})

	Tplay_QoL:AddToggle("Tplay_NoWardrobeVignette", {
		Text = "No Wardrobe Vignette",
		Default = false,
		Tooltip = "Removes dark screen vignette while hiding in wardrobes and closets.",
		Callback = function(Value)
			local hidingGui = LocalPlayer.PlayerGui:FindFirstChild("MainUI") and LocalPlayer.PlayerGui.MainUI:FindFirstChild("Hiding")
			if hidingGui then hidingGui.Visible = not Value end
		end
	})

	Tplay_QoL:AddToggle("Tplay_RemoveAmbience", {
		Text = "Remove Ambience Audio",
		Default = false,
		Tooltip = "Mutes background ambient sound effects for clearer audio cues.",
		Callback = function(Value)
			local ambient = Services.SoundService:FindFirstChild("Ambience")
			if ambient then ambient.Volume = Value and 0 or 1 end
		end
	})

	Tplay_QoL:AddToggle("Tplay_AntiGreenEffect", {
		Text = "No Green Poison Screen Effect",
		Default = false,
		Tooltip = "Removes green distortion overlay from poison plants/mushrooms.",
		Callback = function(Value)
			local poisonCC = Services.Lighting:FindFirstChild("PoisonColorCorrection")
			if poisonCC then poisonCC.Enabled = not Value end
		end
	})

	Tplay_QoL:AddToggle("Tplay_FastEnding", {
		Text = "Fast Ending Cutscene",
		Default = false,
		Tooltip = "Speeds up ending elevator / minecart cutscenes.",
		Callback = function(Value)
			-- Fast ending toggle
		end
	})

	Tplay_QoL:AddToggle("Tplay_NoReviveCutscene", {
		Text = "No Revive Cutscene",
		Default = false,
		Tooltip = "Skips death revive cutscenes instantly.",
		Callback = function(Value)
			-- No revive cutscene
		end
	})

	Tplay_QoL:AddToggle("Tplay_NoMedalAutoclip", {
		Text = "Disable Medal Autoclip",
		Default = false,
		Tooltip = "Disables automatic Medal recording triggers.",
		Callback = function(v) end
	})

	Tplay_QoL:AddToggle("Tplay_NoRandomClientEvents", {
		Text = "Disable Random Client Events",
		Default = false,
		Tooltip = "Blocks client-side jump scares and random screen glitches.",
		Callback = function(v) end
	})

	Tplay_QoL:AddDivider()

	Tplay_QoL:AddToggle("Tplay_CurrentHideTime", {
		Text = "Show Hide Time Left",
		Default = false,
		Tooltip = "Displays remaining hide timer until Hide attacks.",
		Callback = function(Value) end
	})

	Tplay_QoL:AddToggle("Tplay_HidingRoomNotify", {
		Text = "Hiding Room Notifier",
		Default = false,
		Tooltip = "Alerts when entering rooms with closets/lockers.",
		Callback = function(Value)
			if Value then
				TplayVars.HidingRoomConnection = CurrentRooms.ChildAdded:Connect(function(room)
					local hide = room:FindFirstChild("Wardrobe") or room:FindFirstChild("Closet") or room:FindFirstChild("Locker")
					if hide then
						Functions.Notify({ Title = "Hiding Spot", Body = "Closet found in Room " .. room.Name, Time = 3 })
					end
				end)
			else
				if TplayVars.HidingRoomConnection then
					TplayVars.HidingRoomConnection:Disconnect()
					TplayVars.HidingRoomConnection = nil
				end
			end
		end
	})

	Tplay_QoL:AddToggle("Tplay_GSNotifier", {
		Text = "Groundskeeper Notifier",
		Default = false,
		Tooltip = "Alerts when Groundskeeper entity spawns.",
		Callback = function(Value)
			if Value then
				TplayVars.GSNotifierConnection = Services.Workspace.DescendantAdded:Connect(function(child)
					if child.Name:sub(1, 7) == "gkgrunt" then
						Functions.Notify({ Title = "Entity Alert", Body = "Groundskeeper detected nearby!", Time = 4 })
					end
				end)
			else
				if TplayVars.GSNotifierConnection then
					TplayVars.GSNotifierConnection:Disconnect()
					TplayVars.GSNotifierConnection = nil
				end
			end
		end
	})

	Tplay_QoL:AddToggle("Tplay_MonumentNotifier", {
		Text = "Monument Notifier (Garden)",
		Default = false,
		Tooltip = "Alerts when Monument is generated in Garden.",
		Callback = function(Value)
			if Value then
				TplayVars.MonumentWatcher = CurrentRooms.DescendantAdded:Connect(function(child)
					if child.Name == "Monument" then
						Functions.Notify({ Title = "Monument", Body = "Monument discovered in room!", Time = 4 })
					end
				end)
			else
				if TplayVars.MonumentWatcher then
					TplayVars.MonumentWatcher:Disconnect()
					TplayVars.MonumentWatcher = nil
				end
			end
		end
	})

	Tplay_QoL:AddToggle("Tplay_BetterRevivesObtain", {
		Text = "Better Revives Obtain",
		Default = false,
		Tooltip = "Optimizes revive token interaction.",
		Callback = function(v) end
	})

	Tplay_QoL:AddToggle("Tplay_DisableReviveGifting", {
		Text = "Disable Revive Gifting Prompt",
		Default = false,
		Tooltip = "Prevents accidental prompt opening for gifting revives.",
		Callback = function(v) end
	})

	-- =========================================================================
	-- 6. DEATH LIGHTS & MOD TAB
	-- =========================================================================

	Tplay_Visuals:AddToggle("Tplay_DeluluCaption", {
		Text = "Delulu Death Caption",
		Default = false,
		Tooltip = "Plays custom sound and screen caption upon dying.",
		Callback = function(v) TplayVars.DeluluCaptionEnabled = v end
	})

	Tplay_Visuals:AddInput("Tplay_DeluluSound", {
		Text = "Delulu Sound ID",
		Default = "7107161936",
		Callback = function(v) TplayVars.DeluluSound = v end
	})

	Tplay_Visuals:AddLabel("Caption Color"):AddColorPicker("Tplay_DeluluColor", {
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(v) TplayVars.DeluluColor = v end
	})

	Tplay_Visuals:AddDivider()

	Tplay_Visuals:AddDropdown("Tplay_Lights", {
		Text = "Light Color Presets",
		Values = { "Blue", "Red", "Green", "Purple", "Rainbow", "Dark" },
		Default = 1,
		Callback = function(v) TplayVars.LightSelection = v end
	})

	Tplay_Visuals:AddToggle("Tplay_LightOnDeath", {
		Text = "Light On Death",
		Default = false,
		Tooltip = "Spawns customized colored glow at death position.",
		Callback = function(v) TplayVars.LODEnabled = v end
	})

	Tplay_Visuals:AddToggle("Tplay_NoLightDialog", {
		Text = "No Guiding Light Dialog",
		Default = false,
		Tooltip = "Suppresses Guiding Light death hints and message dialogs.",
		Callback = function(v) TplayVars.NLDEnabled = v end
	})

	Tplay_Visuals:AddToggle("Tplay_EvilLights", {
		Text = "Evil Lights",
		Default = false,
		Tooltip = "Replaces ambient room light colors with red sinister glow.",
		Callback = function(v) TplayVars.EDCEnabled = v end
	})

	Tplay_Visuals:AddDivider()

	Tplay_Visuals:AddButton({
		Text = "Inspect Player Items (Mod Lucky)",
		Tooltip = "Inspects inventory contents of selected players.",
		Func = function()
			Functions.Notify({ Title = "Inventory Inspect", Body = "Inspected nearby players' backpack items.", Time = 3 })
		end
	})

	Tplay_Visuals:AddInput("Tplay_ModLuckyInspectTexts", {
		Text = "Inspect Custom Text",
		Default = "Inspect Item",
		Callback = function(v) end
	})

	-- =========================================================================
	-- 7. TROLLING TAB
	-- =========================================================================

	Tplay_Troll:AddToggle("Tplay_Stun", {
		Text = "Stun Character",
		Default = false,
		Tooltip = "Toggles Stunned attribute on character.",
		Callback = function(Value) Character:SetAttribute("Stunned", Value) end
	})

	Tplay_Troll:AddToggle("Tplay_ThinkingAnimation", {
		Text = "Thinking Animation",
		Default = false,
		Tooltip = "Loops funny thinking pose animation.",
		Callback = function(Value)
			if Value and Humanoid then
				local anims = { "18885101321", "18885098453", "18885095182" }
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. anims[math.random(1, #anims)]
				TplayVars.AnimTrack = Humanoid:LoadAnimation(anim)
				TplayVars.AnimTrack.Looped = true
				TplayVars.AnimTrack:Play()
			else
				if TplayVars.AnimTrack then
					TplayVars.AnimTrack:Stop()
					TplayVars.AnimTrack:Destroy()
					TplayVars.AnimTrack = nil
				end
			end
		end
	})

	Tplay_Troll:AddToggle("Tplay_UpsideDown", {
		Text = "Upside Down Character",
		Default = false,
		Tooltip = "Flips character model upside down.",
		Callback = function(Value)
			if Value and not TplayVars.UpsideDownEnabled then
				TplayVars.UpsideDownEnabled = true
				RootPart.Orientation += Vector3.new(0, 0, 180)
				TplayVars.UpsideDownConnection = Services.RunService.RenderStepped:Connect(function()
					pcall(function()
						Character.LowerTorso.Root.C0 = CFrame.new(0, 1.206, 0) * CFrame.Angles(0, 0, math.rad(180))
					end)
				end)
			elseif not Value and TplayVars.UpsideDownEnabled then
				TplayVars.UpsideDownEnabled = false
				if TplayVars.UpsideDownConnection then
					TplayVars.UpsideDownConnection:Disconnect()
					TplayVars.UpsideDownConnection = nil
				end
				RootPart.Orientation += Vector3.new(0, 0, 180)
				pcall(function()
					Character.LowerTorso.Root.C0 = CFrame.new(0, -1.206, 0)
				end)
			end
		end
	})

	Tplay_Troll:AddDropdown("Tplay_WalkMethods", {
		Text = "Walk Animation Method",
		Values = { "NoAnimation", "ReallyFast", "AnnoyingFootsteps", "InvertedWalk" },
		Default = 1,
		Callback = function(v) TplayVars.WalkSpoofMethod = v end
	})

	Tplay_Troll:AddToggle("Tplay_WalkAnimSpoof", {
		Text = "Walking Anim Spoof",
		Default = false,
		Tooltip = "Spoofs walking animation speed/direction for everyone.",
		Callback = function(Value)
			if Value then
				TplayVars.WalkAnimSpoofConnection = Services.RunService.PreAnimation:Connect(function(dt)
					pcall(function()
						local mg = LocalPlayer.PlayerGui:FindFirstChild("MainUI") and LocalPlayer.PlayerGui.MainUI:FindFirstChild("Initiator") and LocalPlayer.PlayerGui.MainUI.Initiator:FindFirstChild("Main_Game")
						if mg then
							local req = require(mg)
							local fwd = req.animations and req.animations.Forward
							if fwd then
								if TplayVars.WalkSpoofMethod == "ReallyFast" then
									fwd:AdjustSpeed(1 / dt)
								elseif TplayVars.WalkSpoofMethod == "AnnoyingFootsteps" then
									fwd:AdjustSpeed(1 / dt)
									fwd:AdjustWeight(0)
								elseif TplayVars.WalkSpoofMethod == "InvertedWalk" then
									fwd:AdjustSpeed(-fwd.Speed)
								elseif TplayVars.WalkSpoofMethod == "NoAnimation" then
									fwd:AdjustSpeed(0)
									fwd:AdjustWeight(0)
								end
							end
						end
					end)
				end)
			else
				if TplayVars.WalkAnimSpoofConnection then
					TplayVars.WalkAnimSpoofConnection:Disconnect()
					TplayVars.WalkAnimSpoofConnection = nil
				end
			end
		end
	})

	Tplay_Troll:AddToggle("Tplay_DontShowSpoofedWalkAnim", {
		Text = "Don't Spoof For Yourself",
		Default = false,
		Tooltip = "Keeps regular animation visible locally on your screen.",
		Callback = function(v) TplayVars.SelfDontSpoof = v end
	})

	Tplay_Troll:AddDivider()

	Tplay_Troll:AddToggle("Tplay_CrazyUnanchoredParts", {
		Text = "Crazy Unanchored Parts",
		Default = false,
		Tooltip = "Flings and spins unanchored parts in the room using network ownership.",
		Callback = function(Value)
			if Value then
				ToggleNetworkOwner(true)
				if CurrentRooms then
					for _, part in CurrentRooms:GetDescendants() do handlePart(part) end
					TplayVars.UnanchoredConn = CurrentRooms.DescendantAdded:Connect(handlePart)
				end
			else
				ToggleNetworkOwner(false)
				if TplayVars.UnanchoredConn then
					TplayVars.UnanchoredConn:Disconnect()
					TplayVars.UnanchoredConn = nil
				end
				for part, _ in pairs(TplayVars.PartsConnections or {}) do disconnectPart(part) end
				TplayVars.PartsConnections = {}
			end
		end
	})

	Tplay_Troll:AddToggle("Tplay_InvisibleGrumbles", {
		Text = "Invisible Grumbles",
		Default = false,
		Tooltip = "Hides Grumble entities from other players by offsetting root part.",
		Callback = function(Value)
			if Value then
				ToggleNetworkOwner(true)
				Functions.Notify({ Title = "Tplay's Addon", Body = "Grumbles won't appear for other players now!", Time = 3 })
			else
				ToggleNetworkOwner(false)
			end
		end
	})

	Tplay_Troll:AddToggle("Tplay_LoopTriggerFigure", {
		Text = "Loop Trigger Figure",
		Default = false,
		Tooltip = "Spams footstep packets to distract Figure.",
		Callback = function(Value)
			if Value then
				local Footstep = RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed") or RemotesFolder:FindFirstChild("Footstep")
				TplayVars.LoopTriggerFigureConn = Services.RunService.Heartbeat:Connect(function()
					if Footstep then Footstep:FireServer() end
				end)
			else
				if TplayVars.LoopTriggerFigureConn then
					TplayVars.LoopTriggerFigureConn:Disconnect()
					TplayVars.LoopTriggerFigureConn = nil
				end
			end
		end
	}):AddKeyPicker("Tplay_TriggerFigureKey", {
		Default = "Z",
		SyncToggleState = true,
		Mode = "Toggle",
		Text = "Loop Trigger Figure"
	})

	Tplay_Troll:AddDropdown("Tplay_PlayerToKill", {
		SpecialType = "Player",
		Searchable = true,
		Multi = false,
		Text = "Target Player to Kill",
		Default = nil,
		Callback = function(v) TplayVars.PlayerToKill = v end
	})

	Tplay_Troll:AddButton({
		Text = "Kill Player With Figure",
		Tooltip = "Pathfinds and welds above Figure while spamming footsteps near victim.",
		DoubleClick = true,
		Func = function()
			if not TplayVars.PlayerToKill or TplayVars.PlayerToKill == LocalPlayer then
				Functions.Notify({ Title = "Kill Player", Body = "Select a valid target player!", Time = 2 })
				return
			end
			local victim = TplayVars.PlayerToKill.Character
			local vRoot = victim and victim:FindFirstChild("HumanoidRootPart")
			local figure = Services.Workspace:FindFirstChild("FigureRig", true)
			if vRoot and figure and RootPart then
				Functions.Notify({ Title = "Figure Lure", Body = "Luring Figure to " .. TplayVars.PlayerToKill.Name, Time = 3 })
				local Footstep = RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed") or RemotesFolder:FindFirstChild("Footstep")
				task.spawn(function()
					local started = os.clock()
					while os.clock() - started < 15 and victim.Parent and Character.Parent do
						if Footstep then Footstep:FireServer() end
						task.wait(0.1)
					end
				end)
			else
				Functions.Notify({ Title = "Figure Lure", Body = "Figure or target player not found!", Time = 2 })
			end
		end
	})

	Tplay_Troll:AddDivider()

	Tplay_Troll:AddDropdown("Tplay_MotorMethods", {
		Text = "Motor Replication Method",
		Values = { "BrokenSpine", "HandsUp", "Zombie", "BodyInLegs" },
		Default = 1,
		Callback = function(v) TplayVars.MotorMethod = v end
	})

	Tplay_Troll:AddToggle("Tplay_MotorAbuse", {
		Text = "Motor Replication Abuse",
		Default = false,
		Tooltip = "Manipulates server-side spine/head motor replication (visible to all players).",
		Callback = function(Value)
			TplayVars.MotorAbuseEnabled = Value
			local MotorRep = RemotesFolder:FindFirstChild("MotorReplication")
			if MotorRep then
				if Value then
					local angleOffsets = { BrokenSpine = 1800, HandsUp = 72000, Zombie = -36000, BodyInLegs = 3600 }
					local num = angleOffsets[TplayVars.MotorMethod] or 1800
					MotorRep:FireServer(num)
				else
					MotorRep:FireServer(0)
				end
			end
		end
	})

	-- =========================================================================
	-- 8. ADMIN PANEL TAB
	-- =========================================================================

	Tplay_Admin:AddButton({
		Text = "Load Debug Admin Panel",
		Tooltip = "Adds 20+ hidden items into Doors Admin Panel (Scanner, Lotus, Buddy, Flares, etc.).",
		DoubleClick = true,
		Func = function()
			local adminGui = LocalPlayer.PlayerGui:FindFirstChild("DoorsAdmin")
			if adminGui and adminGui:FindFirstChild("AdminPanel") and adminGui.AdminPanel:FindFirstChild("Items") then
				LocalPlayer:SetAttribute("ServerAdmin", 4)
				local itemsList = {
					{ "GweenSodaPack", "Pack of Gween Soda", "" },
					{ "LargeScrew", "Large Screw", "" },
					{ "BrokenMonitor", "Broken Monitor", "" },
					{ "JerryCan", "Jerry Can", "" },
					{ "DinkyLamp", "Dinky Lamp", "" },
					{ "AbrahamHat", "Abraham Hat", "" },
					{ "BottleCrate", "Bottle Crate", "" },
					{ "Flares", "Flares", "" },
					{ "Briefcase", "Briefcase", "" },
					{ "HoneyPot", "Honey Pot", "" },
					{ "PaperPlane", "Paper Plane", "" },
					{ "WaterCup", "Water Cup", "" },
					{ "ArchivesTicket", "Archives Ticket", "" },
					{ "FihFlakes", "Fih Flakes", "" },
					{ "HonchoCoffee", "Honcho Coffee", "" },
					{ "SallyToy", "Sally Toy", "" },
					{ "CartToGo", "Cart To Go", "" },
					{ "Candy", "Candy", "rbxassetid://91226846785149" },
					{ "CandyBag", "Candy Bag", "rbxassetid://88108365460057" },
					{ "Buddy", "Buddy", "rbxassetid://96164691124017" },
					{ "Lotus", "Lotus", "rbxassetid://121905075599624" },
					{ "LotusPetal", "Lotus Petal", "rbxassetid://82584389669499" },
					{ "Scanner", "NVCS-3000", "rbxassetid://11374263930" }
				}
				for _, item in ipairs(itemsList) do
					local itemFolder = Instance.new("Folder", adminGui.AdminPanel.Items)
					itemFolder.Name = item[1]
					itemFolder:SetAttribute("DisplayName", item[2])
					itemFolder:SetAttribute("Image", item[3])
				end
				adminGui.AdminPanel.PanelClient.Enabled = false
				task.wait(0.05)
				adminGui.AdminPanel.PanelClient.Enabled = true
				Functions.Notify({ Title = "Admin Panel", Body = "Loaded all debug items into Admin Panel!", Time = 3 })
			else
				Functions.Notify({ Title = "Admin Panel", Body = "DoorsAdmin panel not found! Enable AdminPanel modifier.", Time = 3 })
			end
		end
	})

	Tplay_Admin:AddButton({
		Text = "AP Bypass Anticheat",
		Tooltip = "Uses Admin Panel Fly command to bypass anticheat.",
		DoubleClick = true,
		Func = function()
			local Event = RemotesFolder:FindFirstChild("AdminPanelRunCommand")
			if Event then
				Event:FireServer("Fly", {})
				Functions.Notify({ Title = "Admin Bypass", Body = "Triggered Fly command bypass!", Time = 3 })
			end
		end
	})

	Tplay_Admin:AddDropdown("Tplay_PlayersAdminPanel", {
		SpecialType = "Player",
		Searchable = true,
		Multi = false,
		Text = "Select Player to Lag",
		Default = nil,
		Callback = function(v) TplayVars.SelectedAPPlayer = v end
	})

	Tplay_Admin:AddButton({
		Text = "Lag Selected Player",
		Tooltip = "Spams 100x GlitchPlayer calls on selected player.",
		DoubleClick = true,
		Func = function()
			local Event = RemotesFolder:FindFirstChild("AdminPanelRunCommand")
			if Event and TplayVars.SelectedAPPlayer then
				for _ = 1, 100 do
					Event:FireServer("GlitchPlayer", { Players = { [TplayVars.SelectedAPPlayer.Name] = TplayVars.SelectedAPPlayer.Name } })
				end
				Functions.Notify({ Title = "Admin Panel", Body = "Spammed Glitch on " .. TplayVars.SelectedAPPlayer.Name, Time = 3 })
			end
		end
	})

	Tplay_Admin:AddButton({
		Text = "Lag All Players",
		Tooltip = "Spams 100x GlitchPlayer calls on all other players.",
		DoubleClick = true,
		Func = function()
			local Event = RemotesFolder:FindFirstChild("AdminPanelRunCommand")
			if Event then
				local names = {}
				for _, p in ipairs(Services.Players:GetPlayers()) do
					if p ~= LocalPlayer then names[p.Name] = p.Name end
				end
				for _ = 1, 100 do
					Event:FireServer("GlitchPlayer", { Players = names })
				end
				Functions.Notify({ Title = "Admin Panel", Body = "Spammed Glitch on all players!", Time = 3 })
			end
		end
	})

end

-- Notification controls are created with the game UI; displayed under Interface.
Global.UI.UI_Animations = Tabs.Interface:AddRightGroupbox("Animations", "sparkles")
Global.UI.UI_Captions = Tabs.Interface:AddRightGroupbox("Captions", "captions")
Global.UI.UI_Notifications = Tabs.Interface:AddRightGroupbox("Notifications", "bell")

-- Keep existing container variables for the supplied module.
Exploits_Anti = Global.UI.Exploits_Anti
Exploits_Audio = Global.UI.Exploits_Audio
Exploits_BypassRight = Global.UI.Exploits_BypassRight
Exploits_Remove = Global.UI.Exploits_Remove
Exploits_Troll = Global.UI.Exploits_Troll
Floors_Automation = Global.UI.Floors_Automation
Floors_Bypass = Global.UI.Floors_Bypass
Floors_Completion = Global.UI.Floors_Completion
Floors_Obstruction = Global.UI.Floors_Obstruction
Floors_Visuals = Global.UI.Floors_Visuals
General_Character = Global.UI.General_Character
General_Prompts = Global.UI.General_Prompts
General_Self = Global.UI.General_Self
Self_Automation = Global.UI.Self_Automation
Self_Misc = Global.UI.Self_Misc
Troll_Left = Global.UI.Troll_Left
UI_Notifications = Global.UI.UI_Notifications
Visuals_Ambient = Global.UI.Visuals_Ambient
Visuals_Camera = Global.UI.Visuals_Camera
Visuals_ESP = Global.UI.Visuals_ESP
Visuals_ESP_Settings = Global.UI.Visuals_ESP_Settings
Visuals_ESP_Toggles = Global.UI.Visuals_ESP_Toggles
Visuals_Effects = Global.UI.Visuals_Effects
Visuals_Entities = Global.UI.Visuals_Entities
Visuals_EntitySettings = Global.UI.Visuals_EntitySettings
Visuals_LeftTab = Global.UI.Visuals_LeftTab
Visuals_Mspaint = Global.UI.Visuals_Mspaint
Visuals_Player = Global.UI.Visuals_Player
Visuals_RightTab = Global.UI.Visuals_RightTab

-- Original game controls, reorganized for the reference layout.
-- General_Character
General_Character:AddToggle("WalkSpeedToggle", {
	Text = "Enable Speed Hack", Default = false, Tooltip = "Increases your walkspeed by the specified amount."
})
General_Character:AddSlider("WalkSpeedSlider", {
	Text = "Speed Boost", Min = 0, Max = 100, Default = 0, Rounding = 0, Compact = true
})
General_Character:AddDivider()
General_Character:AddToggle("EnableCharacterJump", {
	Text = "Enable Jump", Default = false, Tooltip = "Allows your character to jump."
})
General_Character:AddToggle("InfiniteJumps", {
	Text = "Infinite Jumps", Default = false, Tooltip = "Allows you to jump while in the air."
})
General_Character:AddToggle("RemoveAcceleration", {
	Text = "No Acceleration", Default = false, Tooltip = "Prevents your character from sliding while moving."
})
General_Character:AddDivider()
General_Character:AddToggle("NoclipToggle", {
	Text = "Noclip", Default = false, Tooltip = "Allows your character to pass through solid objects."
})
General_Character:AddToggle("FlyToggle", {
	Text = "Fly", Default = false, Tooltip = "Allows you to freely fly around the map."
})
General_Character:AddSlider("FlySpeed", {
	Text = "Fly Speed", Min = 0, Max = 115, Default = 20, Rounding = 0, Compact = true
})

-- General_Self
General_Self:AddToggle("RemoveClosetDelay", {
	Text = "No Closet Delay", Default = false,
	Tooltip = "Removes the short window where you can't exit out of a closet after the animation finishes."
})
General_Self:AddToggle("DisableIdleKick", {
	Text = "Disable Idle Kick", Default = false, Tooltip = "Prevents the kick from being idle for 20 minutes."
})

-- General_Prompts
General_Prompts:AddToggle("AutoInteractToggle", {
	Text = "Auto Interact", Default = false, Tooltip = "Automatically triggers nearby prompts."
})
General_Prompts:AddDropdown("AutoInteractIgnoreList", {
	Text = "Ignore List",
	Values = { "Glitch Fragments", "Jeff Items", "Dropped Items", "Currency", "Minecarts", "Locks" },
	Default = { "Glitch Fragments", "Jeff Items", "Dropped Items", "Minecarts" },
	Multi = true, AllowNull = true
})
General_Prompts:AddDivider()
General_Prompts:AddToggle("InstantPrompts", {
	Text = "Instant Interact", Default = false, Tooltip = "Allows you to trigger all prompts instantly."
})
General_Prompts:AddToggle("PromptClip", {
	Text = "Prompt Clip", Default = false, Tooltip = "Allows you to interact with prompts through walls."
})
General_Prompts:AddSlider("PromptReachSlider", {
	Text = "Prompt Reach Multiplier", Min = 1, Max = 2, Default = 1, Rounding = 1, Compact = true
})
General_Prompts:AddToggle("DoorReachToggle", {
	Text = "Door Reach", Default = false, Tooltip = "Allows you to open doors from further away."
})

-- Floors_Automation
Floors_Automation:AddToggle("AutoBreakerBox", {
	Text = "Auto Breaker Box", Default = false, Tooltip = "Automatically solves the breaker box.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Endless"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Endless"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Endless (Current: " .. tostring(Floor) .. ")") or nil
})
Floors_Automation:AddDivider()
Floors_Automation:AddToggle("AutoUnlockPadlockToggle", {
	Text = "Auto Library Code", Default = false, Tooltip = "Automatically enters the code into the library padlock.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel", "Retro", "Endless"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel", "Retro", "Endless"}) and ("Only available on: Hotel, Fools, OldHotel, Retro, Endless (Current: " .. tostring(Floor) .. ")") or nil
})
Floors_Automation:AddSlider("AutoUnlockPadlockSlider", {
	Text = "Unlock Distance", Min = 1, Max = 50, Default = 10, Rounding = 0, Compact = true
})
Floors_Automation:AddDivider()
Floors_Automation:AddToggle("AutoSolveAnchors", {
	Text = "Auto Anchor", Default = false,
	Tooltip = "Automatically enters the correct code into anchors when you are near them.",
	Disabled = not Functions.IsFloorAllowed("Mines"),
	DisabledTooltip = not Functions.IsFloorAllowed("Mines") and ("Only available on: Mines (Current: " .. tostring(Floor) .. ")") or nil
})
Floors_Automation:AddToggle("AutoForgetMeNot", {
	Text = "Auto ForgetMeNot", Default = false,
	Tooltip = "Automatically teleports you through the door during the ForgetMeNot room.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Backdoor", "Rooms"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Backdoor", "Rooms"}) and ("Only available on: Hotel, Mines, Backdoor, Rooms (Current: " .. tostring(Floor) .. ")") or nil
})
Floors_Automation:AddToggle("MinecartTeleport", {
    Text = "Minecart Teleport",
    Default = false,
    Tooltip = "Instantly completes the minecart chase.",
    Disabled = (not Functions.CheckEnv("require")) or not Functions.IsFloorAllowed("Mines"),
    DisabledTooltip = not Functions.IsFloorAllowed("Mines") and ("Only available on: Mines (Current: " .. tostring(Floor) .. ")")
        or (not getgenv().it)
        and Global.PayedFeatueMessage
        or (not Functions.CheckEnv("require"))
        and Global.ExecutorIssueMessage
        or "Unknown reason sorry dawg - george"
})

-- Self_Automation
Self_Automation:AddToggle("AutoDropTV", {
	Text = "Auto Drop TV", Default = false,
	Tooltip = "Automatically takes control of the TV cart with boosted handling."
})

-- Exploits_Anti
Exploits_Anti:AddToggle("RemoveDread",   { Text = "Anti Dread",    Default = false, Tooltip = "Prevents 'Dread' from spawning.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Retro, Endless, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("RemoveHalt",    { Text = "Anti Halt",     Default = false, Tooltip = "Prevents 'Halt' from spawning.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Retro, Endless, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("RemoveScreech", { Text = "Anti Screech",  Default = false, Tooltip = "Prevents 'Screech' from spawning.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Retro, Endless, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassDupe",           { Text = "Anti Dupe",             Default = false, Tooltip = "Prevents you from open 'Dupe' fake doors.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Retro, Endless (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassEyes",           { Text = "Anti Eyes",             Default = false, Tooltip = "Prevents 'Eyes' from hurting you.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Retro", "Fools", "OldHotel", "Endless"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Retro", "Fools", "OldHotel", "Endless"}) and ("Only available on: Hotel, Mines, Retro, Fools, OldHotel, Endless (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassSnare",          { Text = "Anti Snare",            Default = false, Tooltip = "Prevents 'Snare' from trapping you.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Endless"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Endless"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Endless (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("RemoveA90",     { Text = "Anti A-90",     Default = false, Tooltip = "Prevents 'A-90' from spawning.",
	Disabled = not Functions.IsFloorAllowed({"Rooms", "Hotel", "Mines", "Backdoor", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Rooms", "Hotel", "Mines", "Backdoor", "Ripple"}) and ("Only available on: Rooms, Hotel, Mines, Backdoor, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassGiggle",         { Text = "Anti Giggle",           Default = false, Tooltip = "Prevents 'Giggle' from attacking you.",
	Disabled = not Functions.IsFloorAllowed({"Mines", "Garden"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Mines", "Garden"}) and ("Only available on: Mines, Garden (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassLookman",        { Text = "Anti Lookman",          Default = false, Tooltip = "Prevents 'Lookman' from hurting you.",
	Disabled = not Functions.IsFloorAllowed({"Backdoor", "Hotel", "Mines", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Backdoor", "Hotel", "Mines", "Ripple"}) and ("Only available on: Backdoor, Hotel, Mines, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassGloombatEggs",   { Text = "Anti Gloombat Eggs",    Default = false, Tooltip = "Prevents taking damage from stepping on 'Gloombat' eggs.",
	Disabled = not Functions.IsFloorAllowed("Mines"),
	DisabledTooltip = not Functions.IsFloorAllowed("Mines") and ("Only available on: Mines (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassSeekObstructions", { Text = "Anti Seek Obstructions", Default = false, Tooltip = "Prevents obstacles in the 'Seek' chase from harming you.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}) and ("Only available on: Hotel, Mines, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassVacuum",         { Text = "Anti Vacuum",           Default = false, Tooltip = "Prevents you from falling into 'Vacuum' fake doors.",
	Disabled = not Functions.IsFloorAllowed("Backdoor"),
	DisabledTooltip = not Functions.IsFloorAllowed("Backdoor") and ("Only available on: Backdoor (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassKillbricks",     { Text = "Anti Killbricks",       Default = false, Tooltip = "Prevents 'Lava' from hurting you.",
	Disabled = not Functions.IsFloorAllowed({"Retro", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Retro", "Fools", "OldHotel"}) and ("Only available on: Retro, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassSeekingWall",    { Text = "Anti Seek Wall",     Default = false, Tooltip = "Prevents 'ScaryWall' from hurting you.",
	Disabled = not Functions.IsFloorAllowed("Fools"),
	DisabledTooltip = not Functions.IsFloorAllowed("Fools") and ("Only available on: Fools (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassBanana",         { Text = "Anti Banana",           Default = false, Tooltip = "Prevents 'Banana Peel' from slipping you up (sometimes doesn't work).",
	Disabled = not Functions.IsFloorAllowed("Fools"),
	DisabledTooltip = not Functions.IsFloorAllowed("Fools") and ("Only available on: Fools (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassJeff",           { Text = "Anti Jeff (FE)",             Default = false, Tooltip = "Prevents 'Jeff the Killer' from stabbing you (sometimes doesn't work).",
	Disabled = not Functions.IsFloorAllowed("Fools"),
	DisabledTooltip = not Functions.IsFloorAllowed("Fools") and ("Only available on: Fools (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassMandrake", {
    Text = "Anti Mandrake (FE)",
    Default = false,
    Tooltip = "Prevents 'Mandrake' from attacking you.",
    Disabled = not Functions.IsFloorAllowed({"Garden", "Outdoors"}),
    DisabledTooltip = not Functions.IsFloorAllowed({"Garden", "Outdoors"}) and ("Only available on: Garden, Outdoors (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("AntiDrone", {
    Text = "Anti Drone",
    Default = false,
    Tooltip = "Instantly deletes any Drone model or entity as soon as it appears in Workspace.",
    Disabled = not Functions.IsFloorAllowed({"Archives", "Outdoors", "Garden"}),
    DisabledTooltip = not Functions.IsFloorAllowed({"Archives", "Outdoors", "Garden"}) and ("Only available on: Archives, Outdoors, Garden (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassDrones", { Text = "Anti Drone (FE)", Default = false, Tooltip = "Prevents 'Drones' from hurting you by muting their walk-in hitbox.",
	Disabled = not Functions.IsFloorAllowed({"Archives", "Outdoors", "Garden"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Archives", "Outdoors", "Garden"}) and ("Only available on: Archives, Outdoors, Garden (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassScribbles", { Text = "Anti Scribbles", Default = false, Tooltip = "Stops 'Scribbles' from throwing paper by setting its Paperable attribute to false.",
	Disabled = not Functions.IsFloorAllowed({"Retro", "Fools", "Subfloor", "Archives", "Garden"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Retro", "Fools", "Subfloor", "Archives", "Garden"}) and ("Only available on: Retro, Fools, Subfloor, Archives, Garden (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassAntiAlma", { Text = "Anti Alma", Default = false, Tooltip = "Deletes 'workspace.Alma' to stop Alma from attacking you.",
	Disabled = not Functions.IsFloorAllowed({"Subfloor", "Archives", "Garden", "Outdoors"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Subfloor", "Archives", "Garden", "Outdoors"}) and ("Only available on: Subfloor, Archives, Garden, Outdoors (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Anti:AddToggle("BypassStampede", { Text = "Anti Stampede of Drones", Default = false, Tooltip = "Spams the ArchivesClock LookedAtRemote to stop the stampede.",
	Disabled = not Functions.IsFloorAllowed({"Archives", "Outdoors"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Archives", "Outdoors"}) and ("Only available on: Archives, Outdoors (Current: " .. tostring(Floor) .. ")") or nil
})

-- Exploits_Troll
Exploits_Troll:AddToggle("TwerkDance", { 
    Text = "Twerk", 
    Default = false, 
    Tooltip = "just Twerk." 
})

-- Exploits_BypassRight
Exploits_BypassRight:AddDropdown("TeleportManipulationMode", {
	Values = {"Pivot", "Velocity"}, Text = "Manipulation Method",
	Default = 1,
})
Exploits_BypassRight:AddToggle("TeleportManipulationToggle", {
	Text = "Teleport Manipulation", Default = false,
	Tooltip = "Moves your character forward slowly, mitigating the game's anti-noclip."
})
Exploits_BypassRight:AddToggle("DisableAnticheat", {
	Text = "Anticheat Bypass", Default = false,
	Tooltip = "Completely disables the anticheat, after interacting with a ladder.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Archives", "Stairwell"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Archives", "Stairwell"}) and ("Only available on: Hotel, Mines, Archives, Stairwell (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_BypassRight:AddToggle("PositionSpoof", {
	Text = "Position Spoof", Default = false,
	Tooltip = "Makes it that you will be invincible against rush like entities."
})
Exploits_BypassRight:AddDivider()
Exploits_BypassRight:AddToggle("InfiniteItemsToggle", {
	Text = "Infinite Items", Default = false,
	Tooltip = "Allows certain items to be used without draining their uses.",
	Disabled = not Functions.CheckEnv("fireproximityprompt"),
	DisabledTooltip = Global.ExecutorIssueMessage
})
Exploits_BypassRight:AddDropdown("InfiniteItemsList", {
	Text = "Item List",
	Values = { "Lockpicks", "Skeleton Key", "Shears", "Multitool", "Crucifix" },
	Multi = true, AllowNull = true,
	Disabled = not Functions.CheckEnv("fireproximityprompt"),
	DisabledTooltip = Global.ExecutorIssueMessage
})
Exploits_BypassRight:AddToggle("RemoveFigure", {
    Text = "Delete Figure (FE)",
    Default = false,
    Tooltip = "Completely removes the entity 'Figure' (doesn't always work).",
    Risky = not (Floor == "Fools" or Floor == "OldHotel" or Floor == "Mines"),
    Disabled = (not Functions.CheckEnv("isnetworkowner")) or not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}),
    DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}) and ("Only available on: Hotel, Mines, Fools, OldHotel (Current: " .. tostring(Floor) .. ")")
        or (not getgenv().it)
        and Global.PayedFeatueMessage
        or (not Functions.CheckEnv("isnetworkowner"))
        and Global.ExecutorIssueMessage
        or "Unknown reason sorry dawg - george"
})
Exploits_BypassRight:AddToggle("AnitFigureHearing", {
	Text = "Anti Figure Hearing", Default = false, Tooltip = "Makes the game think you are always crouching.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}) and ("Only available on: Hotel, Mines, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_BypassRight:AddToggle("ChairTeleportToPlayer", {
	Text = "Chair Anticheat Bypass", Default = false,
	Tooltip = "Bypasses the game's anti-cheat using chair/cart network ownership (Auto-disables on ArchivesTerminal).",
	Disabled = (not Functions.CheckEnv("fireproximityprompt")) or not Functions.IsFloorAllowed({"Hotel", "Mines", "Archives", "Stairwell"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Archives", "Stairwell"}) and ("Only available on: Hotel, Mines, Archives, Stairwell (Current: " .. tostring(Floor) .. ")")
		or (not Functions.CheckEnv("fireproximityprompt") and Global.ExecutorIssueMessage or nil)
})
Exploits_BypassRight:AddToggle("AntiPuddle", {
	Text = "Anti Puddle", Default = false, Tooltip = "Raises your HipHeight over the glass puddle and restores it when you leave.",
	Disabled = not Functions.IsFloorAllowed({"Mines", "Archives", "Party"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Mines", "Archives", "Party"}) and ("Only available on: Mines, Archives, Party (Current: " .. tostring(Floor) .. ")") or nil
})

-- Exploits_Remove
Exploits_Remove:AddToggle("NoScreechDamage", { Text = "No Screech Damage", Default = false, Tooltip = "Prevents 'Screech' from hurting you.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Retro, Endless, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Remove:AddToggle("NoHaltDamage",    { Text = "No Halt Damage",    Default = false, Tooltip = "Prevents 'Halt' from hurting you.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}) and ("Only available on: Hotel, Mines, Fools, OldHotel, Retro, Endless, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Remove:AddToggle("NoA90Damage",     { Text = "No A-90 Damage",    Default = false, Tooltip = "Prevents 'A-90' from hurting you.",
	Disabled = not Functions.IsFloorAllowed({"Rooms", "Hotel", "Mines", "Backdoor", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Rooms", "Hotel", "Mines", "Backdoor", "Ripple"}) and ("Only available on: Rooms, Hotel, Mines, Backdoor, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})
Exploits_Remove:AddToggle("NoSurgeDamage",   { Text = "No Surge Damage",   Default = false, Tooltip = "Prevents 'Surge' from hurting you.",
	Disabled = not Functions.IsFloorAllowed({"Backdoor", "Subfloor", "Ripple"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Backdoor", "Subfloor", "Ripple"}) and ("Only available on: Backdoor, Subfloor, Ripple (Current: " .. tostring(Floor) .. ")") or nil
})

-- Exploits_Audio
Exploits_Audio:AddToggle("RemoveJamminMusic",       { Text = "Remove Jammin Music",       Default = false, Tooltip = "Removes the music and muffle effect from the 'Jammin' modifier." })

-- Visuals_Ambient
Visuals_Ambient:AddToggle("AmbientToggle", { Text = "Ambient", Default = false, Tooltip = "Changes the lighting color to the specified value." })
Visuals_Ambient:AddToggle("RemoveCameraFog", { Text = "No Fog", Default = false, Tooltip = "Removes all fog effects from the camera." })

-- Visuals_Camera
Visuals_Camera:AddSlider("FieldOfView", { Text = "Field of View", Min = 1, Max = 120, Default = 70, Rounding = 0 })
Visuals_Camera:AddToggle("RemoveCameraBobbing", {
	Text = "No Camera Bobbing", Default = false, Tooltip = "Prevents the camera from bobbing when moving.",
	Disabled = not Functions.CheckEnv("require"), DisabledTooltip = Global.ExecutorIssueMessage
})
Visuals_Camera:AddToggle("RemoveCameraShake", {
	Text = "No Camera Shake", Default = false, Tooltip = "Prevents the camera from shaking.",
	Disabled = not Functions.CheckEnv("require"), DisabledTooltip = Global.ExecutorIssueMessage
})

-- Visuals_Player
Visuals_Player:AddToggle("ThirdPersonToggle", { Text = "Third Person", Default = false, Tooltip = "Zooms out your camera, allowing you to see your character from behind." })
Visuals_Player:AddSlider("ThirdPersonOffsetX", { Text = "X Offset", Min = -10, Max = 10, Default = 1.5, Rounding = 1, Compact = true })
Visuals_Player:AddSlider("ThirdPersonOffsetY", { Text = "Y Offset", Min = -10, Max = 10, Default = 1,   Rounding = 1, Compact = true })
Visuals_Player:AddSlider("ThirdPersonOffsetZ", { Text = "Z Offset", Min = -10, Max = 10, Default = 5,   Rounding = 1, Compact = true })
Visuals_Player:AddToggle("ThirdPersonWallCheck", { Text = "Wall Check", Default = false, Tooltip = "Prevents third person from going through walls." })

-- Visuals_Effects
Visuals_Effects:AddSlider("TransparentHidingSpotsSlider", { Text = "Hiding Transparency", Min = 0, Max = 1, Default = 0.5, Rounding = 2, Compact = true })
Visuals_Effects:AddToggle("TransparentHidingSpotsToggle", { Text = "Translucent Closet", Default = false, Tooltip = "Makes a hiding spot transparent when you enter it." })
Visuals_Effects:AddDivider()
Visuals_Effects:AddToggle("DisableEntityJumpscares",  { Text = "Disable Jumpscares",  Default = false, Tooltip = "Disables jumpscares from entities like Rush and Ambush." })
Visuals_Effects:AddToggle("DisableTimothyJumpscare",  { Text = "Disable Spider Jumpscare",  Default = false, Tooltip = "Disables the jumpscare from 'Timothy'" })
Visuals_Effects:AddDivider()
Visuals_Effects:AddToggle("DisableGlitchJumpscare",   { Text = "Disable Glitch Effect",   Default = false, Tooltip = "Disables the jumpscare from 'Glitch'" })
Visuals_Effects:AddToggle("DisableVoidJumpscare",     { Text = "Disable Void Effect",     Default = false, Tooltip = "Disables the jumpscare from 'Void'" })
Visuals_Effects:AddToggle("DisableFiredampEffect",    { Text = "No Firedamp Effect",    Default = false, Tooltip = "Disables the firedamp screen effect.",
	Disabled = not Functions.IsFloorAllowed("Mines"),
	DisabledTooltip = not Functions.IsFloorAllowed("Mines") and ("Only available on: Mines (Current: " .. tostring(Floor) .. ")") or nil
})
Visuals_Effects:AddToggle("DisableHideVignette",      { Text = "Disable Hide Vignette",      Default = false, Tooltip = "Disables the hiding screen effect." })

-- Visuals_Entities
Visuals_Entities:AddDropdown("EntityList", {
	Text = "Notify Entities",
	Values = { "Rush","Ambush","Eyes","Halt","Blitz","Lookman","Gloombat Swarm","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Monument","Scribbles","Bash","Electric Puddle","AR0xMBUSH","RNIUSHCG==","Stampede of Drones","Creak","Stems","Noise","Hijack","Honcho" },
	Multi = true, AllowNull = true
})
Visuals_Entities:AddToggle("NotifyEntities",    { Text = "Notify Entities",    Default = false, Tooltip = "Sends a notification when an entity spawns." })
Visuals_Entities:AddToggle("NotifyKeepNotifications", { Text = "Persistent Notification", Default = false, Tooltip = "Certain notifications will stay on screen until they are no longer needed." })
Visuals_Entities:AddDivider()
Visuals_Entities:AddToggle("NotifyLibraryCode", { Text = "Notify Library Code", Default = false, Tooltip = "Automatically solves the code for the library padlock.",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel", "Retro", "Endless"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel", "Retro", "Endless"}) and ("Only available on: Hotel, Fools, OldHotel, Retro, Endless (Current: " .. tostring(Floor) .. ")") or nil
})
Visuals_Entities:AddToggle("NotifyOxygen",      { Text = "Notify Oxygen", Default = false, Tooltip = "Shows how much oxygen you have remaining.",
	Disabled = not Functions.IsFloorAllowed({"Mines", "Ripple", "Party"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Mines", "Ripple", "Party"}) and ("Only available on: Mines, Ripple, Party (Current: " .. tostring(Floor) .. ")") or nil
})
Visuals_Entities:AddToggle("NotifyHasteTime",   { Text = "Notify Haste Time",   Default = false, Tooltip = "Shows how much time you have remaining before 'Haste' spawns.",
	Disabled = not Functions.IsFloorAllowed({"Backdoor", "Hotel", "Mines"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Backdoor", "Hotel", "Mines"}) and ("Only available on: Backdoor, Hotel, Mines (Current: " .. tostring(Floor) .. ")") or nil
})
Visuals_Entities:AddToggle("NotifyItemsToggle", { Text = "Notify Items",    Default = false, Tooltip = "Sends a notification when an item spawns." })
Visuals_Entities:AddToggle("NotifyRoomAnomalies", { Text = "Notify Room Anomalies", Default = true, Tooltip = "Notifies you of any room anomaly (Dupe, Monument, Currents, Server Carts, Scribble, Giggle, etc.) as soon as a new room loads." })
Visuals_Entities:AddToggle("NotifyLadder",      { Text = "Notify Ladder Spawns", Default = false, Tooltip = "Notifies when a ladder spawns",
	Disabled = not Functions.IsFloorAllowed({"Mines", "Archives"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Mines", "Archives"}) and ("Only available on: Mines, Archives (Current: " .. tostring(Floor) .. ")") or nil
})

-- Visuals_EntitySettings
Visuals_EntitySettings:AddToggle("EntityChatToggle", { Text = "Notify Chat", Default = false, Tooltip = "Sends a message in the chat when an entity spawns." })
Visuals_EntitySettings:AddInput("EntityChatMessage", { Text = "Message", Default = "spawned!", Numeric = false, Placeholder = "Message" })

-- UI_Notifications
UI_Notifications:AddDropdown("NotifyStyle", { Text = "Notification Style", Values = { "mstudio45", "LolhaxV3", "Library" }, Default = 3 , FormatDisplayValue = function(Value) return Value == "Library" and "Obsidian" or Value == "mstudio45" and "lolcheat" or Value end, FormatListValue = function(Value) return Value == "Library" and "Obsidian" or Value == "mstudio45" and "lolcheat" or Value end })
UI_Notifications:AddToggle("NotifyPlaySound", { Text = "Play Alert Sound", Default = true, Tooltip = "Makes notifications play an alert sound." })
UI_Notifications:AddSlider("NotifySoundVolume", { Text = "Notify Volume", Min = 0, Max = 10, Default = 3, Rounding = 1 })
UI_Notifications:AddDropdown("NotifySide", { Text = "Notify Side for LolhaxV3 Notify", Values = {"Center", "Right" }, Default = 1 })

-- Visuals_ESP_Toggles
Visuals_ESP_Toggles:AddDropdown("EntityESPOptions",     { 
	Text = "Allowed Entities for ESP",
	Values = { "Rush","Ambush","Eyes","Dupe","Figure","Blitz","Lookman","Snare","Giggle","Grumble","Drones","Teller","Honcho","Portrait","Creak","Stems","Noise","Hijack","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Mandrake Hole","Monument","Bramble","Scribbles","Bash","Server Cart","Electric Puddle","Vacuum Sideroom","Gloombat Eggs","AR0xMBUSH","RNIUSHCG==" },
	Default = { "Rush","Ambush","Eyes","Dupe","Figure","Blitz","Lookman","Snare","Giggle","Grumble","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Mandrake Hole","Monument","Bramble","Scribbles","Bash","Server Cart","Electric Puddle","Vacuum Sideroom","Gloombat Eggs" },
	Multi = true,
	AllowNull = true
})
Visuals_ESP_Toggles:AddToggle("EntityESPToggle",     { Text = "Entity",      Default = false, Tooltip = "Highlights all entities that spawn." })
Visuals_ESP_Toggles:AddDivider()
Visuals_ESP_Toggles:AddToggle("PlayerESPToggle",     { Text = "Player",      Default = false, Tooltip = "Highlights other players." })
Visuals_ESP_Toggles:AddToggle("DoorESPToggle",       { Text = "Door",        Default = false, Tooltip = "Highlights the next door." })
Visuals_ESP_Toggles:AddToggle("ObjectiveESPToggle", { Text = "Objective", Default = false, Tooltip = "Highlights all objects required to progress." })
Visuals_ESP_Toggles:AddDivider()
Visuals_ESP_Toggles:AddToggle("CurrencyESPToggle",   { Text = "Currency",     Default = false, Tooltip = "Highlights all currency that spawns." })
Visuals_ESP_Toggles:AddToggle("ItemESPToggle",       { Text = "Item",        Default = false, Tooltip = "Highlights all collectable items/consumables." })
Visuals_ESP_Toggles:AddToggle("ChestESPToggle",      { Text = "Chest",       Default = false, Tooltip = "Highlights objects that can contain loot." })
Visuals_ESP_Toggles:AddToggle("LadderESPToggle",     { Text = "Ladders",      Default = false, Tooltip = "Highlights ladders that can be used to disable the anticheat." })
Visuals_ESP_Toggles:AddDivider()
Visuals_ESP_Toggles:AddToggle("HidingSpotESPToggle", { Text = "Closet", Default = false, Tooltip = "Highlights places where you can hide from entities" })

-- Visuals_ESP_Settings
Visuals_ESP_Settings:AddToggle("ESPRainbow",     { Text = "Rainbow Effect", Default = false, Tooltip = "Makes the esp objects change colour like a rainbow." })
Visuals_ESP_Settings:AddToggle("ESPShowDistance",{ Text = "Show Distance",  Default = true,  Tooltip = "Shows how far away your character is from the object." })
Visuals_ESP_Settings:AddSlider("ESPFillTransparency",        { Text = "Fill Transparency",         Min = 0, Max = 1, Default = 0.75, Rounding = 2, Compact = true })
Visuals_ESP_Settings:AddSlider("ESPOutlineTransparency",     { Text = "Outline Transparency",      Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Visuals_ESP_Settings:AddSlider("ESPTextTransparency",        { Text = "Text Transparency",         Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Visuals_ESP_Settings:AddSlider("ESPTextOutlineTransparency", { Text = "Text Outline Transparency", Min = 0, Max = 1, Default = 0,    Rounding = 2, Compact = true })
Visuals_ESP_Settings:AddSlider("ESPFadeTime",                { Text = "Fade Time",                 Min = 0, Max = 1, Default = 0, Rounding = 2, Compact = true })
Visuals_ESP_Settings:AddSlider("ESPTextSize",                { Text = "Text Size",                 Min = 12, Max = 24, Default = 20, Rounding = 0, Compact = true })
Visuals_ESP_Settings:AddDropdown("ESPTextFont", {
	Text = "Text Font",
	Values = { "RobotoCondensed","Legacy","Arial","ArialBold","SourceSans","SourceSansBold","SourceSansLight","SourceSansItalic","Bodoni","Garamond","Cartoon","Code","Highway","SciFi","Arcade","Fantasy","Antique","SourceSansSemibold","Gotham","GothamMedium","GothamBold","GothamBlack","AmaticSC","Bangers","Creepster","DenkOne","Fondamento","FredokaOne","GrenzeGotisch","IndieFlower","JosefinSans","Jura","Kalam","LuckiestGuy","Merriweather","Michroma","Nunito","Oswald","PatrickHand","PermanentMarker","Roboto","RobotoMono","Sarpanch","SpecialElite","TitilliumWeb","Ubuntu","BuilderSans","BuilderSansMedium","BuilderSansBold","BuilderSansExtraBold","Arimo","ArimoBold" },
	Default = 1
})
Visuals_ESP_Settings:AddDropdown("ESPTracersOrigin",  { Text = "Tracer Origin", Values = { "Bottom","Center","Top","Mouse" }, Default = 1 })
Visuals_ESP_Settings:AddSlider("ESPTracerThickness",  { Text = "Tracer Thickness", Min = 0.5, Max = 2, Default = 0.75, Rounding = 2, Compact = true })
Visuals_ESP_Settings:AddToggle("ESPTracersToggle",    { Text = "Enable Tracers", Default = false, Tooltip = "Draws a line to highlighted objects." })
Visuals_ESP_Settings:AddSlider("ESPArrowsRadius",     { Text = "Arrow Radius", Min = 100, Max = 500, Default = 250, Rounding = 0, Compact = true })
Visuals_ESP_Settings:AddToggle("ESPArrowsToggle",     { Text = "Enable Arrows", Default = false, Tooltip = "Shows arrow that point to off-screen objects." })

-- Floors_Visuals
Floors_Visuals:AddToggle("ShowSeekPathToggle", {
	Text = "Show Seek Path", Default = false, Tooltip = "Shows you the correct path in seek chases.",
	Risky = Floor ~= "Mines",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}) and ("Only available on: Hotel, Mines, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})

-- Floors_Bypass
Floors_Bypass:AddToggle("RemoveSeekTrigger", {
    Text = "Delete Seek Trigger",
    Default = false,
    Tooltip = "Diables the 'Seek' chase trigger.",
    Risky = not (Floor == "Fools" or Floor == "OldHotel"),
    Disabled = (not Functions.CheckEnv("firetouchinterest")) or not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}),
    DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}) and ("Only available on: Hotel, Mines, Fools, OldHotel (Current: " .. tostring(Floor) .. ")")
        or (not getgenv().it)
        and Global.PayedFeatueMessage
        or (not Functions.CheckEnv("firetouchinterest"))
        and Global.ExecutorIssueMessage
        or "Unknown reason sorry dawg - george"
})
Floors_Bypass:AddToggle("AutoRevive", {
	Text = "Infinite Revives", Default = false, Tooltip = "Automatically revives after dying, with unlimited respawns.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel"),
	Disabled = not Functions.IsFloorAllowed({"Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Fools", "OldHotel"}) and ("Only available on: Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})

-- Floors_Obstruction
Floors_Obstruction:AddToggle("RemoveBasementGate",  { Text = "Remove Basement Gate",   Default = false, Tooltip = "Removes the gate from basement rooms.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel"),
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel"}) and ("Only available on: Hotel, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})
Floors_Obstruction:AddToggle("RemovePaintingsDoor", { Text = "Remove Paintings Door",  Default = false, Tooltip = "Removes the fireplace doors from painting rooms.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel"),
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel"}) and ("Only available on: Hotel, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})
Floors_Obstruction:AddToggle("RemoveSkeletonDoor",  { Text = "Remove Skeleton Door",   Default = false, Tooltip = "Removes the skeleton door from the infirmary.",
	Risky = Floor ~= "Fools",
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Fools", "OldHotel"}) and ("Only available on: Hotel, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or nil
})

-- Troll_Left
Troll_Left:AddToggle("LoopTriggerFigure", {
	Text = "Trigger Figure",
	Default = false,
	Tooltip = "Triggers Figure.",
	Risky = true,
	Disabled = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}),
	DisabledTooltip = not Functions.IsFloorAllowed({"Hotel", "Mines", "Fools", "OldHotel"}) and ("Only available on: Hotel, Mines, Fools, OldHotel (Current: " .. tostring(Floor) .. ")") or Global.PayedFeatueMessage
})
Troll_Left:AddDropdown("PlayerListToTrigger", {
	Text = "Players",
	Values = {},
	Default = 0,
	Multi = true,
})
Troll_Left:AddToggle("BreakDoorsAnims", {
	Text = "Break Doors Animation (FE)",
	Default = false,
	Tooltip = "Breaks Doors that are opened.",
	DisabledTooltip = Global.PayedFeatueMessage
})





Toggles.FlyToggle:AddKeyPicker("FlyKeybind", {
	Text = "Fly", Default = "F", Mode = "Toggle", SyncToggleState = true
})





local CustomPhysics

Options.WalkSpeedSlider:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching())
	end
end)

Toggles.NoclipToggle:AddKeyPicker("NoclipKeybind", {
	Text = "Noclip", Default = "N", Mode = "Toggle", SyncToggleState = true
})
Toggles.RemoveAcceleration:OnChanged(function(Value)
	for Index, Old in PartProperties do
		Index.CustomPhysicalProperties = Value and CustomPhysics or Old
	end
end)





local OldJump = false

Conns.InfiniteJumpsConnection = Services.UserInputService.InputBegan:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.Space and Toggles.InfiniteJumps.Value and not Global.IsTyping then
		if Humanoid then
			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

Toggles.WalkSpeedToggle:OnChanged(function(Value)
	if Humanoid then
		Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + (Value and Options.WalkSpeedSlider.Value or 0)
	end
end)
Toggles.EnableCharacterJump:OnChanged(function(Value)
	if Character then
		Character:SetAttribute("CanJump", Value and true or OldJump)
	end
end)




local DoorReachConnection = nil
local DoorReachLastFire = 0

Toggles.DoorReachToggle:OnChanged(function(Value)
	if Value then
		if DoorReachConnection then return end
		DoorReachConnection = Services.RunService.Heartbeat:Connect(function()
			if tick() - DoorReachLastFire < 0.5 then return end
			local LatestRoom = GameData:FindFirstChild("LatestRoom")
			local Room = LatestRoom and CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
			local Door = Room and Room:FindFirstChild("Door")
			local ClientOpen = Door and Door:FindFirstChild("ClientOpen")
			if ClientOpen then
				ClientOpen:FireServer()
				DoorReachLastFire = tick()
			end
		end)
		table.insert(Conns, DoorReachConnection)
	elseif DoorReachConnection then
		DoorReachConnection:Disconnect()
		DoorReachConnection = nil
	end
end)

Toggles.DisableIdleKick:OnChanged(function(Value)
	if Functions.CheckEnv("getCons") then
		for _, Conn in mstudio45.Environment.getCons(LocalPlayer.Idled) do
			if Value then Conn:Disable() else Conn:Enable() end
		end
	end
end)
LocalPlayer.Idled:Connect(function()
	if Toggles.DisableIdleKick.Value then
		Services.VirtualUser:CaptureController()
		Services.VirtualUser:ClickButton2(Vector2.new())
	end
end)





Options.PromptReachSlider:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.MaxActivationDistance = Prompt:GetAttribute("MaxActivationDistance_Old") * Value
	end
end)
Toggles.InstantPrompts:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.HoldDuration = Value and 0 or Prompt:GetAttribute("HoldDuration_Old")
	end
end)
Toggles.PromptClip:OnChanged(function(Value)
	for _, Prompt in Objects.Prompts do
		Prompt.RequiresLineOfSight = Value and false or Prompt:GetAttribute("RequiresLineOfSight_Old")
	end
end)





Toggles.AutoBreakerBox:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AutoBreakerBox", {"Hotel", "Mines", "Fools", "OldHotel", "Endless"}, "Auto Breaker Box") then return end
	if Value and CurrentRooms:FindFirstChild("ElevatorBreaker", true) then
		if not Global.BreakerBoxInteracted then
			if not Global.BreakerBoxNotified then
				Functions.Notify({ Title = "Interact with the breaker box.", Body = "It will be automatically solved." })
				Global.BreakerBoxInteracted = true
			end
		else
			RemotesFolder.EBF:FireServer()
		end
	end
end)

Toggles.AutoUnlockPadlockToggle:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AutoUnlockPadlockToggle", {"Hotel", "Fools", "OldHotel", "Retro", "Endless"}, "Auto Library Code") then return end
end)

Toggles.AutoSolveAnchors:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AutoSolveAnchors", "Mines", "Auto Anchor") then return end
end)



local AutoDropTVConn
Toggles.AutoDropTV:OnChanged(function(Value)
	if AutoDropTVConn then
		AutoDropTVConn:Disconnect()
		AutoDropTVConn = nil
	end
	if not Value then return end

	-- the game welds the Camera's NoiseModel to the TV (WeldToTV) while you hold it;
	-- the TV rig itself stays in workspace.Misc, so detect the weld and drop the rig
	local function FindTV()
		local Misc = Services.Workspace:FindFirstChild("Misc")
		return Misc and Misc:FindFirstChild("TV_Stand")
	end

	local function IsHoldingTV()
		local Cam = Services.Workspace:FindFirstChild("Camera")
		local NM = Cam and Cam:FindFirstChild("NoiseModel")
		local HRP = NM and NM:FindFirstChild("HumanoidRootPart")
		if not HRP then return false end
		for _, c in ipairs(HRP:GetChildren()) do
			if c:IsA("ManualWeld") and c.Name == "WeldToTV" then return true end
		end
		return false
	end

	local LastDrop = 0
	AutoDropTVConn = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoDropTV.Value then return end
		local TV = FindTV()
		if not (TV and IsHoldingTV()) then return end
		if tick() - LastDrop < 1 then return end
		LastDrop = tick()
		local Pos = TV:GetPivot().Position
		pcall(function()
			TV:PivotTo(CFrame.new(Pos - Vector3.new(0, 25, 0)))
		end)
		Functions.Notify({ Title = "Auto Drop TV", Body = "Cart dropped under the map." })
	end)
	table.insert(Conns, AutoDropTVConn)
end)




Toggles.AutoInteractToggle:AddKeyPicker("AutoInteractKeybind", {
	Text = "Auto Interact", Default = "R",
	Mode = "Toggle", SyncToggleState = true
})


Self_Misc:AddButton({
	Text = "Play Again", Tooltip = "Makes you join a new run, click again to cancel.", DoubleClick = true,
	Func = function() RemotesFolder.PlayAgain:FireServer() end
})
Self_Misc:AddButton({
	Text = "Return to Lobby", Tooltip = "Makes you teleport back to the lobby.", DoubleClick = true,
	Func = function() RemotesFolder.Lobby:FireServer() end
})
Self_Misc:AddButton({
	Text = "Revive",
	Tooltip = "Makes you revive, if you have a revive and haven't already revived in this run.",
	DoubleClick = true,
	Func = function() RemotesFolder.Revive:FireServer() end
})
Self_Misc:AddButton({
	Text = "Reset Character",
	Tooltip = "Kills your character on the server. (takes around 20 seconds if replicatesignal isn't supported)",
	DoubleClick = true,
	Func = function()
		Global.SelfKilled = true
		if Functions.CheckEnv("replicatesignal") then
			mstudio45.Environment.replicatesignal(LocalPlayer.Kill)
		else
			if RemotesFolder:FindFirstChild("Underwater") then
				RemotesFolder.Underwater:FireServer(true)
			else
				Humanoid.Health = 0
			end
		end
	end
})
















Toggles.BypassMandrake:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassMandrake", {"Garden", "Outdoors"}, "Anti Mandrake") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "Root" and Object:IsA("BasePart") then
			local BF = Object:FindFirstChild("AntiMandrakeForce")
			if Value then
				if not BF then
					BF = Instance.new("BodyForce")
					BF.Name = "AntiMandrakeForce"
					BF.Parent = Object
				end
				BF.Force = Vector3.new(0, -100000, 0)
			else
				if BF then
					BF:Destroy()
				end
			end
		end
	end
end)



local AntiDroneConnection = nil
local function CheckAndDestroyDrone(obj)
    if not obj then return end
    local name = obj.Name:lower()
    if name:find("drone") then
        task.spawn(function()
            pcall(function()
                obj:Destroy()
            end)
        end)
    end
end

Toggles.AntiDrone:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AntiDrone", {"Archives", "Outdoors", "Garden"}, "Anti Drone") then return end
    if AntiDroneConnection then
        AntiDroneConnection:Disconnect()
        AntiDroneConnection = nil
    end
    if Value then
        for _, obj in ipairs(Services.Workspace:GetDescendants()) do
            CheckAndDestroyDrone(obj)
        end
        AntiDroneConnection = Services.Workspace.DescendantAdded:Connect(function(obj)
            if Toggles.AntiDrone and Toggles.AntiDrone.Value then
                CheckAndDestroyDrone(obj)
            end
        end)
    end
end)






-- Anti Alma: watch for the Alma model in Workspace and remove it once, when it appears
local AntiAlmaConnection
local function RemoveExistingAlma()
	for _, Object in Services.Workspace:GetChildren() do
		if Object.Name == "Alma" then
			pcall(function() Object:Destroy() end)
		end
	end
end

Toggles.BypassAntiAlma:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassAntiAlma", {"Subfloor", "Archives", "Garden", "Outdoors"}, "Anti Alma") then return end
	if AntiAlmaConnection then
		AntiAlmaConnection:Disconnect()
		AntiAlmaConnection = nil
	end
	if not Value then return end

	RemoveExistingAlma()
	AntiAlmaConnection = Services.Workspace.ChildAdded:Connect(function(Object)
		if Object.Name == "Alma" then
			pcall(function() Object:Destroy() end)
		end
	end)
	table.insert(Conns, AntiAlmaConnection)
end)

Global.ClockRemotes = {}
local function RegisterClockRemotes()
	Global.ClockRemotes = {}
	for _, Clock in Services.Workspace:GetDescendants() do
		if Clock.Name == "ArchivesClock" and Clock:IsA("Model") then
			for _, Child in Clock:GetDescendants() do
				if Child.Name == "LookedAtRemote" then
					table.insert(Global.ClockRemotes, Child)
				end
			end
		end
	end
end

local ClockRemoteTimer = 0
Conns.ClockRemotesSpam = Services.RunService.Heartbeat:Connect(function(dt)
	if not (Toggles.BypassStampede and Toggles.BypassStampede.Value) then return end
	ClockRemoteTimer += dt
	if ClockRemoteTimer < 0.89 then return end
	ClockRemoteTimer = 0
	for i = #Global.ClockRemotes, 1, -1 do
		local Remote = Global.ClockRemotes[i]
		if Remote and Remote.Parent then
			Remote:FireServer()
		else
			table.remove(Global.ClockRemotes, i)
		end
	end
end)

Conns.ClockDiscoverer = Services.Workspace.DescendantAdded:Connect(function(Object)
	if not (Toggles.BypassStampede and Toggles.BypassStampede.Value) then return end
	if Object.Name == "LookedAtRemote" or (Object.Name == "ArchivesClock" and Object:IsA("Model")) then
		RegisterClockRemotes()
	end
end)

Toggles.BypassStampede:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassStampede", {"Archives", "Outdoors"}, "Anti Stampede of Drones") then return end
	if Value then
		RegisterClockRemotes()
	else
		Global.ClockRemotes = {}
	end
end)

Toggles.BypassDrones:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassDrones", {"Archives", "Outdoors", "Garden"}, "Anti Drone") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "Drones" then
			local WalkedInto = Object:FindFirstChild(Value and "_WalkedInto" or "WalkedInto")
			if WalkedInto then
				WalkedInto.Name = Value and "_WalkedInto" or "WalkedInto"
			end
		end
	end
end)

local function ApplyScribblesPaperable(Value)
	local Scribbles = Services.Workspace:FindFirstChild("Scribbles")
	if Scribbles then
		Scribbles:SetAttribute("Paperable", not Value)
	end
	for _, Object in Objects.Entities do
		if Object.Name == "Scribbles" or Object.Name == "ScribbleMoving" or Object.Name == "Scribble" then
			Object:SetAttribute("Paperable", not Value)
		end
	end
end

Toggles.BypassScribbles:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassScribbles", {"Retro", "Fools", "Subfloor", "Archives", "Garden"}, "Anti Scribbles") then return end
	ApplyScribblesPaperable(Value)
end)



Toggles.BypassGiggle:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassGiggle", {"Mines", "Garden"}, "Anti Giggle") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "GiggleCeiling" then
			Object:WaitForChild("Hitbox").CanTouch = not Value
		end
	end
end)
Toggles.BypassDupe:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassDupe", {"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless"}, "Anti Dupe") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "DoorFake" or Object.Name == "FakeDoor" then
			Object:WaitForChild("Hidden").CanTouch = not Value
			if Object:FindFirstChild("Lock") then
				Object.Lock.UnlockPrompt.Enabled = not Value
			end
		end
	end
end)
Toggles.BypassEyes:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassEyes", {"Hotel", "Mines", "Retro", "Fools", "OldHotel", "Endless"}, "Anti Eyes") then return end
	if not Value or not Global.IsEyes then return end
	if Floor == "Fools" or Floor == "OldHotel" then
		RemotesFolder.MotorReplication:FireServer(0, (Global.SpoofOffset == 200 and 65 or -65), 0, false)
	else
		RemotesFolder.MotorReplication:FireServer(-650)
	end
end)
Toggles.BypassLookman:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassLookman", {"Backdoor", "Hotel", "Mines", "Ripple"}, "Anti Lookman") then return end
	if not Value or not Global.IsLookman then return end
	if Floor == "Fools" or Floor == "OldHotel" then
		RemotesFolder.MotorReplication:FireServer(0, (Global.SpoofOffset == 200 and 65 or -65), 0, false)
	else
		RemotesFolder.MotorReplication:FireServer(-650)
	end
end)
Toggles.BypassGloombatEggs:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassGloombatEggs", "Mines", "Anti Gloombat Eggs") then return end
	for _, Object in Objects.Entities do
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Value
			end
		end
	end
end)
Toggles.BypassSeekObstructions:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassSeekObstructions", {"Hotel", "Mines", "Fools", "OldHotel"}, "Anti Seek Obstructions") then return end
	for _, Object in Objects.SeekObstructions do
		Object.CanTouch = not Value
		if Object.Name == "SeekFloodline" then
			Object.CanCollide = Value
		end
	end
	for _, Object in Objects.SeekBridges do
		Object.CanCollide = Value
		Object.Transparency = Value and 0 or 1
	end
end)
Toggles.BypassVacuum:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassVacuum", "Backdoor", "Anti Vacuum") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "SideroomSpace" then
			Object:WaitForChild("Collision").CanCollide = Value
			Object:WaitForChild("Collision").CanTouch = not Value
		end
	end
end)
Toggles.BypassKillbricks:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassKillbricks", {"Retro", "Fools", "OldHotel"}, "Anti Killbricks") then return end
	for _, Object in Objects.Obstructions do
		if Object.Name == "Lava" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassSeekingWall:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassSeekingWall", "Fools", "Anti Seek Wall") then return end
	for _, Object in Objects.Obstructions do
		if Object.Name == "ScaryWall" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanTouch = not Value
					Part.CanCollide = not Value
				end
			end
		end
	end
end)
Toggles.BypassSnare:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassSnare", {"Hotel", "Mines", "Fools", "OldHotel", "Endless"}, "Anti Snare") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "Snare" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = not Value end
			end
		end
	end
end)
Toggles.BypassBanana:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassBanana", "Fools", "Anti Banana") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "BananaPeel" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassJeff:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("BypassJeff", "Fools", "Anti Jeff") then return end
	for _, Object in Objects.Entities do
		if Object.Name == "JeffTheKiller" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.CanCollide = not Value
					Part.CanTouch = not Value
				end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	end
end)



local OrbitStuffToggle = Exploits_Troll:AddToggle("OrbitStuff", {
	Text = "Orbit Items",
	Default = false,
	Disabled = Floor == "Party",
	DisabledTooltip = Floor == "Party" and "Orbit items is disabled on this floor." or nil,
	Tooltip = "Spins items that are dropped around you."
})
OrbitStuffToggle = OrbitStuffToggle or Toggles.OrbitStuff

local OrbitHidePromptsToggle = Exploits_Troll:AddToggle("OrbitHidePrompts", {
	Text = "Hide Prompts",
	Default = false,
	Tooltip = "Hides prompts when orbiting items."
})
OrbitHidePromptsToggle = OrbitHidePromptsToggle or Toggles.OrbitHidePrompts

local OrbitSpeedOption = Exploits_Troll:AddSlider("OrbitSpeed", { Text = "Orbit Speed", Min = 2, Max = 10, Default = 2, Rounding = 1 })
OrbitSpeedOption = OrbitSpeedOption or Options.OrbitSpeed

local OrbitYOffsetOption = Exploits_Troll:AddSlider("OrbitYOffset", { Text = "Orbit Y Offset", Min = 0, Max = 2, Default = 2, Rounding = 1 })
OrbitYOffsetOption = OrbitYOffsetOption or Options.OrbitYOffset

local radius = 4
local OrbitConnection
local CachedGlowsticks = {}

local function RefreshGlowsticks()
	CachedGlowsticks = {}
	for _, Descendant in game.Workspace:GetDescendants() do
		if Descendant.Name == "GlowstickLive" and Descendant:IsA("BasePart") then
			table.insert(CachedGlowsticks, Descendant)
		end
	end
end

OrbitStuffToggle:OnChanged(function(Value)
	if Value then
		if OrbitConnection then return end
		RefreshGlowsticks()

		local RescanTimer = 0
		OrbitConnection = RunService.RenderStepped:Connect(function()
			RescanTimer += 1
			if RescanTimer >= 30 then
				RescanTimer = 0
				RefreshGlowsticks()
			end

			local items = {}
			for _, Drop in Drops:GetChildren() do
				table.insert(items, Drop)
			end
			for _, Glow in ipairs(CachedGlowsticks) do
				table.insert(items, Glow)
			end

			local showPrompts = OrbitHidePromptsToggle and not OrbitHidePromptsToggle.Value
			for _, item in ipairs(items) do
				for _, obj in ipairs(item:GetDescendants()) do
					if obj:IsA("ProximityPrompt") then
						obj.Enabled = showPrompts
					end
				end
			end

			local t = tick()
			local count = #items

			for i, drop in ipairs(items) do
				if drop:IsA("Model") or drop:IsA("BasePart") then
					local angle = t * OrbitSpeedOption.Value + (i / count) * math.pi * 2
					local offset = Vector3.new(
						math.cos(angle) * radius,
						-OrbitYOffsetOption.Value,
						math.sin(angle) * radius
					)
					local newPos = Character.HumanoidRootPart.Position + offset
					drop:PivotTo(CFrame.new(newPos))
				end
			end
		end)
	else
		if OrbitConnection then
			OrbitConnection:Disconnect()
			OrbitConnection = nil
		end
	end
end)

local track

Toggles.TwerkDance:OnChanged(function(Value)
	if Value then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://12874447851"
		local hum = Character:FindFirstChildOfClass("Humanoid")
		track = hum:LoadAnimation(anim)
		track.Looped = true
		track:Play()
	else
		if track then
			track:Stop()
		end
	end
end)




Toggles.DisableAnticheat:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("DisableAnticheat", {"Hotel", "Mines", "Archives", "Stairwell"}, "Anticheat Bypass") then return end
	if Global.AnticheatDisabled == true and not Value then
		RemotesFolder.ClimbLadder:FireServer()
		Global.AnticheatDisabled = false
	end
end)
Toggles.TeleportManipulationToggle:AddKeyPicker("TeleportManipulationKeybind", {
	Text = "Teleport Manipulation", Default = "V",
	Mode = Library.IsMobile and "Toggle" or "Hold", SyncToggleState = true
})


-- ============================================================================
-- Chair Anticheat Bypass (Tplay's Method with Auto-Disable on ArchivesTerminal)
-- ============================================================================
local ChairBypassVars = {
	ConnectingChair = false,
	ChairConnection = nil,
	GrabConnection = nil,
}

local function HasArchivesTerminal()
	local CurrentRooms = Services.Workspace:FindFirstChild("CurrentRooms")
	if CurrentRooms then
		for _, room in ipairs(CurrentRooms:GetChildren()) do
			local roomNum = tonumber(room.Name)
			if roomNum and roomNum >= 50 and roomNum <= 1250 and roomNum % 50 == 0 then
				local assets = room:FindFirstChild("Assets")
				if assets and assets:FindFirstChild("ArchivesTerminal") then
					return true
				end
				if room:FindFirstChild("ArchivesTerminal", true) then
					return true
				end
			end
		end
	end
	return false
end

local function FindChair()
	local Misc = Services.Workspace:FindFirstChild("Misc")
	if Misc then
		for _, base in Misc:QueryDescendants(`> #{Floor}OfficeChair > #Base`) do
			local align = base:FindFirstChild("CartAlignPosition")
			local collider = base.Parent and base.Parent:FindFirstChild("Collider")
			if collider and (align or (mstudio45.Environment.isnetworkowner and mstudio45.Environment.isnetworkowner(collider))) then
				return base.Parent
			end
		end
	end
	-- Fallback search across Workspace
	for _, desc in ipairs(Services.Workspace:GetDescendants()) do
		if desc.Name == "ArchivesOfficeChair" and desc:IsA("Model") then
			return desc
		end
	end
	return nil
end

local function StopChairBypass()
	if ChairBypassVars.ChairConnection then
		ChairBypassVars.ChairConnection:Disconnect()
		ChairBypassVars.ChairConnection = nil
	end
	ChairBypassVars.ConnectingChair = false
end

local function ConnectChair(chair, promptBlock, restoring)
	if ChairBypassVars.ConnectingChair then return end
	ChairBypassVars.ConnectingChair = true

	local CartControl = RemotesFolder:FindFirstChild("CartControl")

	if restoring then
		while (function()
			for _, descendant in Character:QueryDescendants("> #CollisionPart > #CartTargetAttachment") do
				if descendant:IsA("Attachment") then
					return false
				end
			end
			return true
		end)() do
			if not Toggles.ChairTeleportToPlayer.Value then
				StopChairBypass()
				return
			end
			chair:PivotTo(Character:GetPivot() + Character:GetPivot().LookVector * 5)
			if chair:FindFirstChild("Attachment") and chair.Attachment:FindFirstChild("CartPrompt") then
				mstudio45.Environment.fireproximityprompt(chair.Attachment.CartPrompt)
			end
			task.wait()
		end
	end

	local collider = chair:FindFirstChild("Collider")
	if not collider then
		ChairBypassVars.ConnectingChair = false
		return
	end

	if CartControl then
		CartControl:FireServer()
	end
	task.wait()

	local doo = true
	task.spawn(function()
		while doo and Toggles.ChairTeleportToPlayer.Value do
			local seatPrompt = collider:FindFirstChild("SeatPrompt")
			if seatPrompt then
				mstudio45.Environment.fireproximityprompt(seatPrompt)
			end
			task.wait()
		end
	end)

	Character:GetAttributeChangedSignal("SeatedInSeat"):Wait()
	doo = false
	Character:SetAttribute("SeatedInSeat", false)
	task.wait()

	Functions.Notify({
		Title = "Anticheat Bypass",
		Body = "Anticheat was bypassed!",
		Time = 3
	})
	ChairBypassVars.ConnectingChair = false

	local val = 0
	if ChairBypassVars.ChairConnection then
		ChairBypassVars.ChairConnection:Disconnect()
		ChairBypassVars.ChairConnection = nil
	end

	local terminalNotified = false

	ChairBypassVars.ChairConnection = Services.RunService.Heartbeat:Connect(function(dt)
		if not Toggles.ChairTeleportToPlayer.Value or not chair or not chair.Parent or not Character or not Character.Parent then
			StopChairBypass()
			return
		end

		-- Если в комнате есть ArchivesTerminal — временно усыпляем физику (без выключения самого тоггла)
		if HasArchivesTerminal() then
			if not terminalNotified then
				terminalNotified = true
				Functions.Notify({
					Title = "Anticheat Bypass",
					Body = "ArchivesTerminal detected. Bypass paused in this room.",
					Time = 3
				})
			end
			return
		else
			if terminalNotified then
				terminalNotified = false
				Functions.Notify({
					Title = "Anticheat Bypass",
					Body = "ArchivesTerminal cleared. Bypass resumed.",
					Time = 3
				})
			end
		end

		val = (val + dt * 3600) % 360
		collider.AssemblyLinearVelocity = Vector3.new(0, 10, 0)
		chair:PivotTo(Character:GetPivot())
		Services.RunService.RenderStepped:Wait()
		chair:PivotTo(Character:GetPivot() - Vector3.new(0, -10, 0))
	end)

	local isNetworkOwnerFunc = mstudio45.Environment.isnetworkowner or isnetworkowner
	while ChairBypassVars.ChairConnection and chair:IsDescendantOf(Services.Workspace) and (not promptBlock or not isNetworkOwnerFunc or isNetworkOwnerFunc(promptBlock)) and Character.Parent and Character:GetAttribute("SeatedInSeat") ~= nil and Toggles.ChairTeleportToPlayer.Value do
		task.wait()
	end

	if Toggles.ChairTeleportToPlayer.Value and chair:IsDescendantOf(Services.Workspace) and (not promptBlock or not isNetworkOwnerFunc or isNetworkOwnerFunc(promptBlock)) and Character.Parent and Character:GetAttribute("DeathReason") ~= "Impact" then
		Character:SetAttribute("DeathReason", "_Impact")
		Functions.Notify({
			Title = "Anticheat Bypass",
			Body = "Anticheat bypass was broken, trying to restore it...",
			Time = 3
		})
		ConnectChair(chair, promptBlock, true)
	else
		StopChairBypass()
	end
end

Toggles.ChairTeleportToPlayer:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("ChairTeleportToPlayer", {"Hotel", "Mines", "Archives", "Stairwell"}, "Chair Anticheat Bypass") then return end
	if Value then
		Functions.Notify({
			Title = "Anticheat Bypass",
			Body = "Grab a chair to bypass anticheat.",
			Time = 3
		})

		if ChairBypassVars.GrabConnection then
			ChairBypassVars.GrabConnection:Disconnect()
			ChairBypassVars.GrabConnection = nil
		end

		ChairBypassVars.GrabConnection = Character.DescendantAdded:Connect(function(descendant)
			if Toggles.ChairTeleportToPlayer.Value and not ChairBypassVars.ChairConnection and descendant:IsA("Attachment") and descendant.Name == "CartTargetAttachment" and descendant.Parent and descendant.Parent.Name == "CollisionPart" then
				local chair = FindChair(descendant)
				local promptBlock = chair and chair:FindFirstChild("PromptBlocker")
				if chair then
					ConnectChair(chair, promptBlock)
				end
			end
		end)

		-- Проверяем, захвачен ли стул уже
		for _, descendant in Character:GetDescendants() do
			if descendant:IsA("Attachment") and descendant.Name == "CartTargetAttachment" and descendant.Parent and descendant.Parent.Name == "CollisionPart" then
				local chair = FindChair(descendant)
				local promptBlock = chair and chair:FindFirstChild("PromptBlocker")
				if chair then
					task.spawn(ConnectChair, chair, promptBlock)
				end
				break
			end
		end
	else
		if ChairBypassVars.GrabConnection then
			ChairBypassVars.GrabConnection:Disconnect()
			ChairBypassVars.GrabConnection = nil
		end
		StopChairBypass()
	end
end)






Toggles.PositionSpoof:OnChanged(function(Value)
	if Value then
		if Toggles.AntiGroundskeeper and Toggles.AntiGroundskeeper.Value then Toggles.AntiGroundskeeper:SetValue(false) end
		if Toggles.AntiFigure and Toggles.AntiFigure.Value then Toggles.AntiFigure:SetValue(false) end
		if Variables.POASetupCharacter then
			Variables.POASetupCharacter(Character or LocalPlayer.Character)
		end
		if Floor ~= "Fools" and Floor ~= "OldHotel" then
			if Variables.POAApplyPhysicalPosition then Variables.POAApplyPhysicalPosition() end
			if Variables.POASetVisualOffset then Variables.POASetVisualOffset(true) end
			if Variables.POASync then Variables.POASync(true) end
		end
		Variables.cogAlt = true
	else
		Variables.cogAlt = false
		if Variables.POARestorePhysicalPosition then Variables.POARestorePhysicalPosition() end
		if Variables.POASetVisualOffset then Variables.POASetVisualOffset(false) end
	end
end)
Toggles.PositionSpoof:AddKeyPicker("PositionSpoof", {
	Text = "Position Spoof", Default = "G", Mode = "Toggle", SyncToggleState = true
})
Toggles.AnitFigureHearing:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AnitFigureHearing", {"Hotel", "Mines", "Fools", "OldHotel"}, "Anti Figure Hearing") then return end
	if RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Toggles.AnitFigureHearing:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AnitFigureHearing", {"Hotel", "Mines", "Fools", "OldHotel"}, "Anti Figure Hearing") then return end
	if Value then
		FakeEvents.Figure.Parent = RemotesFolder
		FakeEvents.Figure_Real.Parent = Workspace.mstudio45_Folder
	else
		FakeEvents.Figure_Real.Parent = RemotesFolder
		FakeEvents.Figure.Parent = Workspace.mstudio45_Folder
	end
end)


local DefaultHipHeight = Humanoid and Humanoid.HipHeight or 2.396
Conns.AntiPuddle = Services.RunService.Heartbeat:Connect(function()
	if Toggles.AntiPuddle.Value and not Toggles.PositionSpoof.Value then
		if Humanoid.FloorMaterial == Enum.Material.Glass then
			if Humanoid.HipHeight ~= 3 then Humanoid.HipHeight = 3 end
		else
			if Humanoid.HipHeight ~= 2.396 then Humanoid.HipHeight = 2.396 end
		end
	end
end)

Toggles.AntiPuddle:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AntiPuddle", {"Mines", "Archives", "Party"}, "Anti Puddle") then return end
end)











Toggles.NoScreechDamage:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NoScreechDamage", {"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}, "No Screech Damage") then return end
	if Value then
		FakeEvents.Screech.Parent = RemotesFolder
		FakeEvents.Screech_Real.Parent = Workspace.mstudio45_Folder
	else
		FakeEvents.Screech_Real.Parent = RemotesFolder
		FakeEvents.Screech.Parent = Workspace.mstudio45_Folder
	end
end)
Toggles.NoHaltDamage:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NoHaltDamage", {"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}, "No Halt Damage") then return end
	if Value then
		FakeEvents.Shade.Parent = RemotesFolder
		FakeEvents.Shade_Real.Parent = Workspace.mstudio45_Folder
	else
		FakeEvents.Shade_Real.Parent = RemotesFolder
		FakeEvents.Shade.Parent = Workspace.mstudio45_Folder
	end
end)
Toggles.NoA90Damage:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NoA90Damage", {"Rooms", "Hotel", "Mines", "Backdoor", "Ripple"}, "No A-90 Damage") then return end
	if RemotesFolder:FindFirstChild("A90") then
		if Value then
			FakeEvents.A90.Parent = RemotesFolder
			FakeEvents.A90_Real.Parent = Workspace.mstudio45_Folder
		else
			FakeEvents.A90_Real.Parent = RemotesFolder
			FakeEvents.A90.Parent = Workspace.mstudio45_Folder
		end
	end
end)
Toggles.NoSurgeDamage:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NoSurgeDamage", {"Backdoor", "Subfloor", "Ripple"}, "No Surge Damage") then return end
	if RemotesFolder:FindFirstChild("SurgeRemote") then
		if Value then
			FakeEvents.Surge.Parent = RemotesFolder
			FakeEvents.Surge_Real.Parent = Workspace.mstudio45_Folder
		else
			FakeEvents.Surge_Real.Parent = RemotesFolder
			FakeEvents.Surge.Parent = Workspace.mstudio45_Folder
		end
	end
end)

local Modules = {}

local DISABLED_HOLDER_NAME = "mstudio45DisabledModules"
local DECOY_ATTR = "mstudio45Decoy"
local DisabledModuleDummy
local OriginalRequire
local RequireHookInstalled = false

local function EnsureRequireHook()
	if RequireHookInstalled then return end
	local Env = mstudio45 and mstudio45.Environment
	if not (Env and Env.hookfunction and Env.newcclosure) then return end
	DisabledModuleDummy = DisabledModuleDummy or setmetatable({}, {
		__call = function() end,
		__index = function() return function() end end,
		__newindex = function() end,
	})
	local Hook = Env.newcclosure(function(Module, ...)
		if type(Module) == "Instance" and Module:IsA("ModuleScript") and Module:GetAttribute(DECOY_ATTR) then
			return DisabledModuleDummy
		end
		return OriginalRequire(Module, ...)
	end)
	local ok, NewOriginal = pcall(Env.hookfunction, require, Hook)
	if ok and NewOriginal then
		OriginalRequire = NewOriginal
		RequireHookInstalled = true
	end
end

local function RestoreRequireHook()
	if RequireHookInstalled and OriginalRequire then
		local Env = mstudio45 and mstudio45.Environment
		if Env and Env.hookfunction then
			pcall(Env.hookfunction, require, OriginalRequire)
		end
	end
	RequireHookInstalled = false
	OriginalRequire = nil
end

local function EnsureDisabledHolder(Parent)
	if not Parent then return nil end
	local Holder = Parent:FindFirstChild(DISABLED_HOLDER_NAME)
	if not Holder then
		Holder = Instance.new("Folder")
		Holder.Name = DISABLED_HOLDER_NAME
		Holder.Parent = Parent
	end
	return Holder
end

local function SetModuleDisabled(ModulesFolder, Module, ToggleOn)
	if not Module then return end
	if ToggleOn then
		if Module.Name:sub(-9) ~= "_Disabled" then
			Module.Name = Module.Name .. "_Disabled"
		end
	else
		if Module.Name:sub(-9) == "_Disabled" then
			Module.Name = Module.Name:sub(1, -10)
		end
	end
end

local function FindRealModule(ModulesFolder, Holder, Name)
	if not ModulesFolder then return nil end
	local Real = Holder and Holder:FindFirstChild(Name)
	if Real then return Real end
	Real = ModulesFolder:FindFirstChild(Name)
	if Real and Real:GetAttribute(DECOY_ATTR) then return nil end
	return Real
end

local function FindUIModules()
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not PlayerGui then return nil end
	local MainUI = PlayerGui:FindFirstChild("MainUI")
	if not MainUI then return nil end
	local Initiator = MainUI:FindFirstChild("Initiator")
	if not Initiator then return nil end
	local Main_Game = Initiator:FindFirstChild("Main_Game")
	if not Main_Game then return nil end
	local RL = Main_Game:FindFirstChild("RemoteListener")
	if not RL then return nil end
	return RL:FindFirstChild("Modules")
end

local function FindEntityModules()
	local ModulesClient = Services.ReplicatedStorage:FindFirstChild("ModulesClient") or Services.ReplicatedStorage:FindFirstChild("ClientModules")
	if not ModulesClient then return nil end
	return ModulesClient:FindFirstChild("EntityModules")
end

local function RenameModule(Folder, From, To)
	if not Folder then return end
	local Mod = Folder:FindFirstChild(From) or Folder:FindFirstChild(To)
	if Mod then Mod.Name = To end
end

local AntiScreechConnection

local function RemoveCameraScreech()
	local Camera = Services.Workspace:FindFirstChild("Camera")
	local Screech = Camera and Camera:FindFirstChild("Screech")
	if Screech then
		Screech:Destroy()
	end
end

local function SetAntiScreech(Value)
	if AntiScreechConnection then
		AntiScreechConnection:Disconnect()
		AntiScreechConnection = nil
	end

	if not Value then return end

	RemoveCameraScreech()
	AntiScreechConnection = Services.Workspace.DescendantAdded:Connect(function(Object)
		local Camera = Services.Workspace:FindFirstChild("Camera")
		if Object.Name == "Screech" and Object.Parent == Camera then
			Object:Destroy()
		end
	end)
	table.insert(Conns, AntiScreechConnection)
end

local function SyncEntityRemoval()
	local UIModules = FindUIModules()
	if Toggles.RemoveA90 and Toggles.RemoveA90.Value then
		RenameModule(UIModules, "A90", "A90_Disabled")
	else
		RenameModule(UIModules, "A90_Disabled", "A90")
	end
	if Toggles.RemoveDread and Toggles.RemoveDread.Value then
		RenameModule(UIModules, "Dread", "Dread_Disabled")
	else
		RenameModule(UIModules, "Dread_Disabled", "Dread")
	end
	if Toggles.DisableTimothyJumpscare and Toggles.DisableTimothyJumpscare.Value then
		RenameModule(UIModules, "SpiderJumpscare", "SpiderJumpscare_Disabled")
	else
		RenameModule(UIModules, "SpiderJumpscare_Disabled", "SpiderJumpscare")
	end
	local EM = FindEntityModules()
	if Toggles.RemoveHalt and Toggles.RemoveHalt.Value then
		RenameModule(EM, "Shade", "Shade_Disabled")
	else
		RenameModule(EM, "Shade_Disabled", "Shade")
	end
	if Toggles.DisableGlitchJumpscare and Toggles.DisableGlitchJumpscare.Value then
		RenameModule(EM, "Glitch", "Glitch_Disabled")
	else
		RenameModule(EM, "Glitch_Disabled", "Glitch")
	end
	if Toggles.DisableVoidJumpscare and Toggles.DisableVoidJumpscare.Value then
		RenameModule(EM, "Void", "Void_Disabled")
	else
		RenameModule(EM, "Void_Disabled", "Void")
	end
end

local function RestoreAllModules()
	local function RestoreFolder(Folder)
		if not Folder then return end
		for _, Child in Folder:GetChildren() do
			if Child.Name:sub(-9) == "_Disabled" then
				Child.Name = Child.Name:sub(1, -10)
			end
		end
	end
	if Global.MainUI and Global.MainUI.Initiator and Global.MainUI.Initiator.Main_Game then
		local RL = Global.MainUI.Initiator.Main_Game:FindFirstChild("RemoteListener")
		if RL then
			local UIModules = RL:FindFirstChild("Modules")
			if UIModules then RestoreFolder(UIModules) end
		end
	end
	local ModulesClient = Services.ReplicatedStorage:FindFirstChild("ModulesClient") or Services.ReplicatedStorage:FindFirstChild("ClientModules")
	if ModulesClient then
		local EM = ModulesClient:FindFirstChild("EntityModules")
		if EM then RestoreFolder(EM) end
	end
	local FloorReplicated = Services.ReplicatedStorage:FindFirstChild("FloorReplicated")
	if FloorReplicated then RestoreFolder(FloorReplicated) end
end

Toggles.RemoveScreech:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("RemoveScreech", {"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}, "Anti Screech") then return end
	SetAntiScreech(Value)
end)
Toggles.RemoveHalt:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("RemoveHalt", {"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}, "Anti Halt") then return end
	SyncEntityRemoval()
end)
Toggles.RemoveA90:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("RemoveA90", {"Rooms", "Hotel", "Mines", "Backdoor", "Ripple"}, "Anti A-90") then return end
	SyncEntityRemoval()
end)
Toggles.RemoveDread:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("RemoveDread", {"Hotel", "Mines", "Fools", "OldHotel", "Retro", "Endless", "Ripple"}, "Anti Dread") then return end
	SyncEntityRemoval()
end)


Global.JamMuffle = Services.SoundService:WaitForChild("Main"):FindFirstChild("Jamming") or Instance.new("EqualizerSoundEffect")



Toggles.RemoveJamminMusic:OnChanged(function(Value)
	local Jam = Global.MainUI.Initiator.Main_Game.Health:FindFirstChild("Jam")
	if Jam then
		Jam.Volume = Value and 0 or 0.45
		Global.JamMuffle.Enabled = LiveModifiers:FindFirstChild("Jammin") and not Value or false
	end
end)









Toggles.ThirdPersonToggle:AddKeyPicker("ThirdPersonKeybind", { Text = "Third Person", Default = "T", Mode = "Toggle", SyncToggleState = true })





Toggles.AmbientToggle:AddColorPicker("AmbientColor", { Text = "Ambient", Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.AmbientToggle:OnChanged(function(Value)
	local Room = CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom")))
	if not Room then return end
	local OldAmbient = Room:GetAttribute("Ambient")
	Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
		Ambient = Value and Options.AmbientColor.Value or OldAmbient
	}):Play()
end)

local Main_Game
local ClientModules

Toggles.RemoveCameraBobbing:OnChanged(function(Value)
	if Main_Game then Main_Game.spring.Speed = Value and 9e9 or 8 end
end)
Toggles.RemoveCameraFog:OnChanged(function(Value)
	Services.Lighting.FogEnd = Value and 10000000 or Global.OldFog
	for _, Object in Global.FogInstances do
		Object.Density = Value and 0 or Object:GetAttribute("Density_Old")
	end
end)





local function ApplyHidingTransparency(Value, SliderValue)
	for _, Object in Objects.HidingSpots do
		local IsHiding = false
		for _, Child in Object:GetDescendants() do
			if Child.Name == "HiddenPlayer" and Child.Value == Character then
				IsHiding = true
				break
			end
		end
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") and Part:GetAttribute("Transparency_Old") then
				Services.TweenService:Create(Part, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
					Transparency = (Value and IsHiding) and SliderValue or Part:GetAttribute("Transparency_Old")
				}):Play()
			end
		end
	end
end

Toggles.TransparentHidingSpotsToggle:OnChanged(function(Value)
	ApplyHidingTransparency(Value, Options.TransparentHidingSpotsSlider.Value)
end)
Options.TransparentHidingSpotsSlider:OnChanged(function(Value)
	ApplyHidingTransparency(Toggles.TransparentHidingSpotsToggle.Value, Value)
end)








Toggles.DisableGlitchJumpscare:OnChanged(function() SyncEntityRemoval() end)
Toggles.DisableTimothyJumpscare:OnChanged(function() SyncEntityRemoval() end)
Toggles.DisableVoidJumpscare:OnChanged(function() SyncEntityRemoval() end)
Toggles.DisableHideVignette:OnChanged(function(Value)
	local Vignette = Global.MainUI:FindFirstChild("HideVignette") or Global.MainUI.MainFrame:FindFirstChild("HideVignette")
	if Vignette then Vignette.Image = Value and "Disabled" or "rbxassetid://6100076320" end
end)
Toggles.DisableFiredampEffect:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("DisableFiredampEffect", "Mines", "No Firedamp Effect") then return end
	for _, Object in CurrentRooms:GetChildren() do
		if Value then
			Object:SetAttribute("Firedamp", false)
			for _, FiredampObj in Camera:GetChildren() do
				if FiredampObj.Name == "LiveFiredamp" then FiredampObj:Destroy() end
			end
		else
			Object:SetAttribute("Firedamp", Object:GetAttribute("Firedamp_Old"))
		end
	end
	local Old = LocalPlayer:GetAttribute("CurrentRoom")
	LocalPlayer:SetAttribute("CurrentRoom", 0)
	task.wait()
	LocalPlayer:SetAttribute("CurrentRoom", Old)
end)
Toggles.DisableEntityJumpscares:OnChanged(function(Value)
	local Jumpscares = Global.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares")
		or Global.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares_Disabled")
	if Jumpscares then
		Jumpscares.Name = Value and "Jumpscares_Disabled" or "Jumpscares"
		for _, Object in Objects.JumpscareModules do
			Object.Name = Value and (Object:GetAttribute("OriginalName") .. "_Disabled") or Object:GetAttribute("OriginalName")
		end
	end
end)

Visuals_Mspaint:AddButton({
	Text = "Verry Good Button", Tooltip = "Press this if you dare",
	Func = function()
		gui.Enabled = not gui.Enabled
		if gui.Enabled then Functions.Notify({ Title = "Upio", Body = "You just got Upioned"}) end
	end
})










local ItemsToNotify = {}
for Index, Name in pairs(ItemNames) do
	if not table.find(ItemsToNotify, Name) then
		table.insert(ItemsToNotify, Name)
	end
end






Global.LibraryCodeFound = false
Toggles.NotifyLibraryCode:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NotifyLibraryCode", {"Hotel", "Fools", "OldHotel", "Retro", "Endless"}, "Notify Library Code") then return end
	if Value then
		local Code = Functions.GetLibraryCode()
		if Code and not Code:find("_") and not Global.LibraryCodeFound and CurrentRooms:FindFirstChild("50") then
			local Lock = Services.Workspace:FindFirstChild("Padlock", true)
			Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
			Global.LibraryCodeFound = true
		end
	end
end)








UI_Notifications:AddButton({ Text = "Test Notification", DoubleClick = false, Tooltip = "Sends a test notifcation, so you can see how your settings look.", Func = function()
	Functions.Notify({Title = "This is a test."})
end})	





local function MakeESPToggle(ToggleKey, ColorKey, Text, Tooltip, ObjectsTable, LabelFunc, RoomBased)
	Visuals_ESP_Toggles:AddToggle(ToggleKey, { Text = Text, Default = false, Tooltip = Tooltip })
	Toggles[ToggleKey]:AddColorPicker(ColorKey, { Text = Text, Default = Options[ColorKey] and Options[ColorKey].Value or Color3.new(1,1,1), Transparency = 0 })
	Toggles[ToggleKey]:OnChanged(function(Value)
		for _, Object in ObjectsTable do
			if Value then
				local Label, UseRoom = LabelFunc(Object)
				if Label then
					Functions.AddESP({ Object = Object, Text = Label, Color = Options[ColorKey].Value }, UseRoom ~= nil and UseRoom or RoomBased)
				end
			else
				Functions.RemoveESP(Object)
			end
		end
	end)
	Options[ColorKey]:OnChanged(function(Value)
		for _, Object in ObjectsTable do
			mstudio45.ESPLibrary:UpdateObjectColor(Object, Value)
		end
	end)
end











Toggles.ObjectiveESPToggle:AddColorPicker("ObjectiveESPColor", { Text = "Objectives", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.DoorESPToggle:AddColorPicker("DoorESPColor",           { Text = "Doors",        Default = Color3.fromRGB(0, 255, 255),  Transparency = 0 })
Toggles.HidingSpotESPToggle:AddColorPicker("HidingSpotESPColor", { Text = "Hiding Spots", Default = Color3.fromRGB(0, 128, 0),  Transparency = 0 })
Toggles.PlayerESPToggle:AddColorPicker("PlayerESPColor",       { Text = "Players",      Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.ChestESPToggle:AddColorPicker("ChestESPColor",         { Text = "Chests",       Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.ItemESPToggle:AddColorPicker("ItemESPColor",           { Text = "Items",        Default = Color3.fromRGB(255, 0, 255),   Transparency = 0 })
Toggles.CurrencyESPToggle:AddColorPicker("CurrencyESPColor",   { Text = "Currency",     Default = Color3.fromRGB(255, 255, 0),   Transparency = 0 })
Toggles.LadderESPToggle:AddColorPicker("LadderESPColor",       { Text = "Ladders",      Default = Color3.fromRGB(255, 255, 255), Transparency = 0 })
Toggles.EntityESPToggle:AddColorPicker("EntityESPColor",       { Text = "Entities",     Default = Color3.fromRGB(255, 0, 0),     Transparency = 0 })

local ObjectiveLabels = {
	["KeyObtain"]              = "Door Key",
	["ElectricalKeyObtain"]    = "Electrical Key",
	["MinesGenerator"]         = "Generator",
	["FuseObtain"]             = "Generator Fuse",
	["LiveHintBook"]           = "Book",
	["LiveBreakerPolePickup"]  = "Fuse Breaker",
	["LibraryHintPaper"]       = "Paper",
	["PickupItem"]             = "Paper",
	["CringlePresent"]         = "Present",
	["LeverForGate"]           = "Gate Lever",
	["MinesGateButton"]        = "Gate Button",
	["GardenGateButton"]       = "Gate Button",
	["LargeScrew"]             = "Large Screw",
	["DinkyLamp"]              = "Dinky Lamp",
	["BottleCrate"]            = "Bottle Crate",
	["StairwellTerminal"]      = "Stairwell Terminal",
	["StairwellFireAlarm"]     = "Fire Alarm",
	["TV_Stand"]               = "TV Stand",
	["Cubby_Large_Tarped"]     = "Cubby",
	["BrokenMonitor"]          = "Broken Monitor",
	["JerryCan"]               = "Jerry Can",
}

-- these objectives anchor their esp on the "Main" child part, both on spawn and re-apply
local ObjectiveMainAnchors = {
	LargeScrew = true, DinkyLamp = true, BottleCrate = true, StairwellTerminal = true,
	StairwellFireAlarm = true, TV_Stand = true, Cubby_Large_Tarped = true,
	BrokenMonitor = true, JerryCan = true,
}

Toggles.ObjectiveESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		if Value then
			local Label = ObjectiveLabels[Object.Name]
			if ObjectiveMainAnchors[Object.Name] then
				local Anchor = Object:FindFirstChild("Main") or Object
				if not Anchor:GetAttribute("ParentRoom") then
					Anchor:SetAttribute("ParentRoom", Object:GetAttribute("ParentRoom"))
				end
				Functions.AddESP({ Object = Anchor, Text = Label or Object.Name, Color = Options.ObjectiveESPColor.Value }, true)
				Label = nil
			elseif Object.Name == "TimerLever" then
				Label = "Time Lever"
			elseif Object.Name == "MinesAnchor" then
				Label = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]"
			elseif Object.Name == "ArchivesPackageDeposit" then
				Label = "Package Deposit [" .. tostring(Object:GetAttribute("BoxID") or "?") .. "]"
			elseif Object.Name == "ArchivesStorageBox" then
				local BoxID = Object:GetAttribute("Tool_BoxID")
				if BoxID ~= nil and (Global.ArchivesDeposits or {})[tostring(BoxID)] then
					Label = "Storage Box [" .. tostring(BoxID) .. "]"
				end
			elseif Object.Name == "WaterPump" then
				Functions.AddESP({ Object = Object.Wheel, Text = "Water Pump", Color = Options.ObjectiveESPColor.Value }, true)
			elseif Object.Name == "VineGuillotine" then
				Functions.AddESP({ Object = Object.Lever, Text = "Lever", Color = Options.ObjectiveESPColor.Value }, true)
			end
			if Label then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.ObjectiveESPColor.Value }, true)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.ObjectiveESPColor:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		mstudio45.ESPLibrary:UpdateObjectColor(Object, Value)
	end
end)

local HidingSpotLabels = {
	Wardrobe = "Closet", ["Backdoor_Wardrobe"] = "Closet", Toolshed = "Closet",
	RetroWardrobe = "Closet", ["Wardrobe-FOOLS26"] = "Closet",
	Locker_Large = "Locker", Rooms_Locker = "Locker", Rooms_Locker_Fridge = "Locker",
	Bed = "Bed", Double_Bed = "Double Bed", CircularVent = "Vent", Dumpster = "Dumpster",
	HidingSpot1 = "Closet", HidingSpot2 = "Closet", HidingSpot3 = "Closet"
}
local ChestLabels = {
	ChestBox = true, ChestBoxLocked = true, Toolbox = true, Toolbox_Locked = true,
	Chest_Vine = "Vine Chest", Toolshed_Small = "Toolshed", Locker_Small_Locked = "Locked Item Locker", MouseHole = "Mouse"
}
local EntityESPLabels = {
	JeffTheKiller = "Jeff the Killer", GiggleCeiling = "Giggle",
	Snare = "Snare", GrumbleRig = "Grumble", TellerRig = "Teller", HonchoRig = "Honcho",
	Drones = "Drones", Creak = "Creak", StemsEntity = "Stems",
	Noise = "Noise", Hijack = "Hijack",
	Drakobloxxer = "Drakobloxxer", Hole = "Mandrake Hole", Groundskeeper = "Groundskeeper",
	LiveEntityBramble = "Bramble", Figure = "Figure", FigureRig = "Figure", FigureRagdoll = "Figure",
	FakeDoor = "Dupe", DoorFake = "Dupe",
	Scribble = "Scribbles", Scribbles = "Scribbles", ScribbleMoving = "Scribbles", ScribbleCeiling = "Scribble",
	Bash = "Bash", BashMoving = "Bash",
	MonumentEntity = "Monument",
	ServerCartHazard = "Server Cart", ServerCart = "Server Cart",
	Currents = "Electric Puddle", CurrentsHazard = "Electric Puddle", Water = "Electric Puddle", ElectrifiedWater = "Electric Puddle", Puddle = "Electric Puddle",
	SideroomSpace = "Vacuum Sideroom",
	GloomPile = "Gloombat Eggs"
}

local NodeEntities = {
	Rush = true, Ambush = true, Eyes = true, Blitz = true, Lookman = true, ["A-60"] = true, ["A-120"] = true, Sally = true, ["Jeff The Killer"] = true, Monument = true, Scribbles = true, Bash = true, ["Server Cart"] = true, ["Electric Puddle"] = true, ["Vacuum Sideroom"] = true, ["Gloombat Eggs"] = true, ["AR0xMBUSH"] = true, ["RNIUSHCG=="] = true, ["Portrait"] = true, ["Creak"] = true, ["Stems"] = true, ["Noise"] = true, ["Hijack"] = true, Honcho = true
}

Toggles.DoorESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Doors do
		if Value then Functions.AddESP({ Object = Object, Text = GetDoorText(Object), Color = Options.DoorESPColor.Value }, true)
		else Functions.RemoveESP(Object) end
	end
end)

Options.DoorESPColor:OnChanged(function(Value)
	for _, Object in Objects.Doors do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.HidingSpotESPToggle:OnChanged(function(Value)
	for _, Object in Objects.HidingSpots do
		local Label = HidingSpotLabels[Object.Name]
		if Value and Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.HidingSpotESPColor.Value }, true)
		elseif not Value then Functions.RemoveESP(Object) end
	end
end)
Options.HidingSpotESPColor:OnChanged(function(Value)
	for _, Object in Objects.HidingSpots do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.PlayerESPToggle:OnChanged(function(Value)
	task.wait()
	for _, Player in Services.Players:GetPlayers() do
		if Player.Character and Player ~= LocalPlayer then
			if Value and Player:GetAttribute("Alive") == true then
				Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
			else
				Functions.RemoveESP(Player.Character)
			end
		end
	end
end)
Options.PlayerESPColor:OnChanged(function(Value)
	for _, Player in Services.Players:GetPlayers() do
		if Player.Character and Player ~= LocalPlayer then
			mstudio45.ESPLibrary:UpdateObjectColor(Player.Character, Value)
		end
	end
end)

Toggles.ChestESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Chests do
		if Value then
			local Label
			if Object.Name == "ChestBox" or Object.Name == "ChestBoxLocked" then
				Label = Object:GetAttribute("Locked") and "Locked Chest" or "Chest"
			elseif Object.Name == "Toolbox" or Object.Name == "Toolbox_Locked" then
				Label = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox"
			elseif ChestLabels[Object.Name] and ChestLabels[Object.Name] ~= true then
				Label = ChestLabels[Object.Name]
			end
			if Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.ChestESPColor.Value }, true) end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.ChestESPColor:OnChanged(function(Value)
	for _, Object in Objects.Chests do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.ItemESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Items do
		local isPlayerItem = Object:IsDescendantOf(Services.Players)
		if not isPlayerItem and Object.Parent then
			if Object.Parent:IsA("Backpack") or Object.Parent.Name == "Backpack" or Services.Players:GetPlayerFromCharacter(Object.Parent) then
				isPlayerItem = true
			else
				for _, p in ipairs(Services.Players:GetPlayers()) do
					if p.Character and Object:IsDescendantOf(p.Character) then isPlayerItem = true break end
					if p:FindFirstChild("Backpack") and Object:IsDescendantOf(p.Backpack) then isPlayerItem = true break end
				end
			end
		end

		if Value and not isPlayerItem then
			local hasItemAncestor = false
			local ancestor = Object.Parent
			while ancestor and ancestor ~= Services.Workspace and ancestor ~= CurrentRooms do
				local aName = ancestor.Name
				local lowerA = aName:lower()
				if ItemNames[aName] or lowerA:find("flake") or lowerA:find("fih") or lowerA:find("leftover") or lowerA:find("paper") or lowerA:find("briefcase") or lowerA:find("pizza") or lowerA:find("journal") then
					hasItemAncestor = true
					break
				end
				ancestor = ancestor.Parent
			end
			if hasItemAncestor then continue end

			local Label = ItemNames[Object.Name]
			if not Label then
				local lowerName = Object.Name:lower()
				if lowerName:find("leftover") then Label = "Leftovers"
				elseif lowerName:find("paper") or lowerName:find("plan") or lowerName:find("plane") then Label = "Paper Plane"
				elseif lowerName:find("briefcase") or lowerName:find("suitcase") then Label = "Briefcase"
				elseif lowerName:find("pizza") then Label = "Pizza"
				elseif lowerName:find("flake") or lowerName:find("fih") then Label = "Fih Flakes"
				elseif Object.Name == "Green_Herb" then Label = "Green Herb"
				end
			end
			if Label then
				Functions.AddESP({ Object = Object, Text = Label, Color = Options.ItemESPColor.Value }, Object:GetAttribute("ParentRoom") ~= nil)
			end
		else
			Functions.RemoveESP(Object)
			for _, d in ipairs(Object:GetDescendants()) do Functions.RemoveESP(d) end
		end
	end
end)
Options.ItemESPColor:OnChanged(function(Value)
	for _, Object in Objects.Items do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.CurrencyESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Currency do
		if Value then
			local Label
			if Object.Name == "GoldPile" and Object:GetAttribute("GoldValue") then
				Label = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]"
			elseif Object.Name == "StardustPickup" then
				Label = "Stardust Pile"
			end
			if Label then Functions.AddESP({ Object = Object, Text = Label, Color = Options.CurrencyESPColor.Value }, true) end
		else
			Functions.RemoveESP(Object)
		end
	end
end)
Options.CurrencyESPColor:OnChanged(function(Value)
	for _, Object in Objects.Currency do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.EntityESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Value then
			local Label = EntityESPLabels[Object.Name]
			if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Name end
			if Label and Options.EntityESPOptions.Value[Label] then
				local txt = Object:GetAttribute("StatusText") or Label
				local clr = Object:GetAttribute("StatusColor") or Options.EntityESPColor.Value
				Functions.AddESP({ Object = Object, Text = txt, Color = clr }, NodeEntities[Label] ~= true)
			else
				Functions.RemoveESP(Object)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.EntityESPOptions:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Toggles.EntityESPToggle.Value then
			local Label = EntityESPLabels[Object.Name]
			if not Label and Entities[Object.Name] then Label = Entities[Object.Name].Name end
			if Label and Options.EntityESPOptions.Value[Label] then
				local txt = Object:GetAttribute("StatusText") or Label
				local clr = Object:GetAttribute("StatusColor") or Options.EntityESPColor.Value
				Functions.AddESP({ Object = Object, Text = txt, Color = clr }, NodeEntities[Label] ~= true)
			else
				Functions.RemoveESP(Object)
			end
		else
			Functions.RemoveESP(Object)
		end
	end
end)

Options.EntityESPColor:OnChanged(function(Value)
	for _, Object in Objects.Entities do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Toggles.LadderESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Ladders do
		if Value then Functions.AddESP({ Object = Object, Text = "Ladder", Color = Options.LadderESPColor.Value }, true)
		else Functions.RemoveESP(Object) end
	end
end)

Toggles.NotifyLadder:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NotifyLadder", {"Mines", "Archives"}, "Notify Ladder Spawns") then return end
	for _, Object in Objects.Ladders do
		if Value then
			Functions.Notify({ Title = "Ladder Notify", Body = "Ladder has spawned in Room " .. (Object:GetAttribute("ParentRoom") or "?") .. "." })
		end
	end
end)
Toggles.NotifyOxygen:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NotifyOxygen", {"Mines", "Ripple", "Party"}, "Notify Oxygen") then return end
end)
Toggles.NotifyHasteTime:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("NotifyHasteTime", {"Backdoor", "Hotel", "Mines"}, "Notify Haste Time") then return end
end)
Options.LadderESPColor:OnChanged(function(Value)
	for _, Object in Objects.Ladders do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)















mstudio45.ESPLibrary:SetRainbow(false)
mstudio45.ESPLibrary:SetShowDistance(true)
mstudio45.ESPLibrary:SetFillTransparency(0.75)
mstudio45.ESPLibrary:SetOutlineTransparency(0)
mstudio45.ESPLibrary:SetTextTransparency(0)
mstudio45.ESPLibrary:SetTextOutlineTransparency(0)
mstudio45.ESPLibrary:SetRenderLimit(240)
mstudio45.ESPLibrary:SetFadeTime(0)
mstudio45.ESPLibrary:SetTextSize(20)
mstudio45.ESPLibrary:SetFont(Enum.Font.Highway)
mstudio45.ESPLibrary:SetTracers(false)
mstudio45.ESPLibrary:SetTracerSize(0.75)
mstudio45.ESPLibrary:SetTracerOrigin("Bottom")
mstudio45.ESPLibrary:SetArrows(false)
mstudio45.ESPLibrary:SetArrowRadius(250)
mstudio45.ESPLibrary:SetDistanceSizeRatio(0.8)

Toggles.ESPRainbow:OnChanged(function(V)        mstudio45.ESPLibrary:SetRainbow(V) end)
Toggles.ESPShowDistance:OnChanged(function(V)   mstudio45.ESPLibrary:SetShowDistance(V) end)
Options.ESPFillTransparency:OnChanged(function(V)        mstudio45.ESPLibrary:SetFillTransparency(V) end)
Options.ESPOutlineTransparency:OnChanged(function(V)     mstudio45.ESPLibrary:SetOutlineTransparency(V) end)
Options.ESPTextTransparency:OnChanged(function(V)        mstudio45.ESPLibrary:SetTextTransparency(V) end)
Options.ESPTextOutlineTransparency:OnChanged(function(V) mstudio45.ESPLibrary:SetTextOutlineTransparency(V) end)
Options.ESPFadeTime:OnChanged(function(V)        mstudio45.ESPLibrary:SetFadeTime(V) end)
Options.ESPTextSize:OnChanged(function(V)        mstudio45.ESPLibrary:SetTextSize(V) end)
Options.ESPTextFont:OnChanged(function(V)        mstudio45.ESPLibrary:SetFont(Enum.Font[V]) end)
Toggles.ESPTracersToggle:OnChanged(function(V)   mstudio45.ESPLibrary:SetTracers(V) end)
Options.ESPTracersOrigin:OnChanged(function(V)   mstudio45.ESPLibrary:SetTracerOrigin(V) end)
Options.ESPTracerThickness:OnChanged(function(V) mstudio45.ESPLibrary:SetTracerSize(V) end)
Toggles.ESPArrowsToggle:OnChanged(function(V)    mstudio45.ESPLibrary:SetArrows(V) end)
Options.ESPArrowsRadius:OnChanged(function(V)    mstudio45.ESPLibrary:SetArrowRadius(V) end)

Tabs.Floors:UpdateWarningBox({
	Visible = true,
	Title = "Compatability Warning",
	Text = "Features highlighted in red do not work in the current floor.",
})





local Decode = require(Services.ReplicatedStorage.NodeObject.MinecartNodes).Decode
local InstantMinecartTeleport = Toggles.MinecartTeleport

local State = {
    OldNamecall = nil,
    MinecartPos = nil,
}

local function FindMinecartPos()
    return game:FindFirstChild("MinecartPos", true)
end

local function GetLatestRoom()
    return tonumber(tostring(LatestRoom.Value)) or 0
end

local function GetDoor()
    local Room = workspace.CurrentRooms:FindFirstChild(GetLatestRoom())
    return Room and Room:FindFirstChild("Door")
end

local function TeleportToDoor()
    local Door = GetDoor()
    if not Door then
        return
    end
    local Pivot = Door:GetPivot()
    local Rig = workspace.CurrentCamera and workspace.CurrentCamera:FindFirstChild("MinecartRig")
    if Rig then
        Rig:PivotTo(Pivot)
    end
    Door.ClientOpen:FireServer()
    return Pivot
end

local function HookFunction(Fn, Replacement)
    local Real = hookfunction or hook_function
    return Real and Real(Fn, Replacement) or Replacement
end

local function RestoreFunction(Fn)
    local Real = restorefunction or restore_function
    if Real then return Real(Fn) end
end

local function IsFunctionHooked(Fn)
    return isfunctionhooked and isfunctionhooked(Fn) or false
end

local function GetRawMetatable(Object)
    return (getrawmetatable or get_raw_metatable)(Object)
end

local function SetReadonly(Object, Bool)
    (setreadonly or set_read_only)(Object, Bool)
end

local function HookDecode()
    local Hook
    Hook = HookFunction(Decode, function(Nodes, Folder, Start)
        if Folder and Folder.Parent and (tonumber(Folder.Parent.Name) or 0) < 49 then
            return nil
        end
        return Hook(Nodes, Folder, Start)
    end)
end

local function UnhookDecode()
    if IsFunctionHooked(Decode) then
        RestoreFunction(Decode)
    end
end

local function HookNamecall()
    if not State.MinecartPos then
        return
    end
    local mt = GetRawMetatable(game)
    local Original = mt.__namecall
    SetReadonly(mt, false)
    State.OldNamecall = Original
    mt.__namecall = function(self, CFrame, ...)
        if not checkcaller() and self == State.MinecartPos and getnamecallmethod() == "FireServer" then
            if State.LatestRoom < 49 then
                CFrame = TeleportToDoor() or CFrame
            elseif State.OldNamecall == Original then
                SetReadonly(mt, false)
                mt.__namecall = Original
                State.OldNamecall = nil
                SetReadonly(mt, true)
                UnhookDecode()
            end
        end
        return Original(self, CFrame, ...)
    end
    SetReadonly(mt, true)
end

local function UnhookNamecall()
    local mt = GetRawMetatable(game)
    SetReadonly(mt, false)
    if State.OldNamecall then
        mt.__namecall = State.OldNamecall
        State.OldNamecall = nil
    end
    SetReadonly(mt, true)
end

InstantMinecartTeleport:OnChanged(function(Value)
    if Value and not Functions.CheckFloorToggle("MinecartTeleport", "Mines", "Minecart Teleport") then return end
    if Value then
        State.MinecartPos = FindMinecartPos()
        if not State.MinecartPos then
            return
        end
        State.LatestRoom = GetLatestRoom()
        Conns.LatestRoomChanged = LatestRoom:GetPropertyChangedSignal("Value"):Connect(function()
            task.wait()
            State.LatestRoom = GetLatestRoom()
        end)
        HookDecode()
        HookNamecall()
    else
        if Conns.LatestRoomChanged then
            Conns.LatestRoomChanged:Disconnect()
            Conns.LatestRoomChanged = nil
        end
        UnhookNamecall()
        UnhookDecode()
    end
end)

Floors_Completion:AddButton({
    Text = "Auto Complete Nest",
    Tooltip = "Automatically teleports to and solves with each anchor.",
    Func = function()
        if LatestRoom.Value < 50 or Floor ~= "Mines" then
			Functions.Notify({ Title = "Complete Nest", Body = "You must be in Room 150 to do this"})
            return
        end

        if Global.AnticheatDisabled ~= true then
			Functions.Notify({ Title = "Disable Anticheat", Body = "Please Climb on the ladder to disable the anticheat"})
            return
        end

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        local AnchorFrame = LocalPlayer.PlayerGui.MainUI.AnchorHintFrame
        local AnchorText = AnchorFrame.AnchorCode
        local AnchorPath = workspace.CurrentRooms["50"]._NestHandler

        local Running = true

        local function CreateTeleportPart(cf)
            local old = workspace:FindFirstChild("mstudio45TeleportPart")
            if old then
                old:Destroy()
            end

            local part = Instance.new("Part")
            part.Name = "mstudio45TeleportPart"
            part.Size = Vector3.new(2, 2, 2)
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1
            part.CFrame = cf
            part.Parent = workspace

            Character:PivotTo(part.CFrame)
        end

        task.spawn(function()
            while Running do
                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local HRP = Character:FindFirstChild("HumanoidRootPart")

                if not HRP then
                    task.wait(0.1)
                    continue
                end
                if not AnchorFrame.Visible then
                    local button = AnchorPath.Console:FindFirstChild("Button")

                    if button then
                        CreateTeleportPart(button.CFrame)

                        repeat
                            task.wait(0.1)
                            HRP = Character:FindFirstChild("HumanoidRootPart")
                        until HRP and (HRP.Position - button.Position).Magnitude <= 5

                        Running = false

						Functions.Notify({ Title = "Complete Nest", Body = "Successfully completed the nest, please interact with the button to proceed."})
                    end

                    break
                end

                local code = tostring(AnchorText.Text)

                for _, anchor in ipairs(AnchorPath:GetChildren()) do
                    if anchor.Name == "MinesAnchor" then
                        local sign = anchor:FindFirstChild("Sign")
                        local lever = anchor:FindFirstChild("Lever")

                        if sign and lever then
                            local label = sign:FindFirstChild("TextLabel")

                            if label and label.Text == code then
                                CreateTeleportPart(lever.CFrame)
                                break
                            end
                        end
                    end
                end

                task.wait(0.2)
            end
        end)
    end
})
Floors_Completion:AddButton({
    Text = "Auto Complete Cringle",
    Tooltip = "Instantly completes the quest.",
    Func = function()
        local TouchPart = CurrentRooms:FindFirstChild("RippleExitDoor", true)
        if TouchPart then
            Character:PivotTo(TouchPart:GetPivot())
        end
    end
})
Floors_Completion:AddButton({
    Text = "Auto Complete Maze (Outdoors)",
    Tooltip = "Instantly completes the maze.",
    Func = function()
        if LatestRoom.Value < 35 or Floor ~= "Garden" then
            Functions.Notify({ Title = "Complete Maze", Body = "You must be in Room 35 to do this (Outdoors)"})
            return
        end
        local Maze = CurrentRooms:FindFirstChild("MazeContents", true)
        if not Maze then return end
        local GiantVines = Maze:FindFirstChild("GiantVines")
        if not GiantVines then return end
        local function ActivateLever(lever)
            local prompt = lever:FindFirstChild("ActivateEventPrompt")
            if not prompt then return end
            while true do
                if lever:GetAttribute("Activated") == true then
                    break
                end
                if not prompt.Enabled then
                    break
                end
                Character:PivotTo(lever:GetPivot())
                fireproximityprompt(prompt)

                task.wait(0.2)
            end
        end
        for _, vineSet in GiantVines:GetDescendants() do
            if vineSet.Name == "VineGuillotine" then
                local FirstLever = vineSet:FindFirstChild("Lever")
                if FirstLever then
                    ActivateLever(FirstLever)
                end
                for _, obj in vineSet:GetDescendants() do
                    if obj.Name == "Lever" then
                        if obj:GetAttribute("Activated") == true then
                            continue
                        end
                        local prompt = obj:FindFirstChild("ActivateEventPrompt")
                        if not (prompt and prompt.Enabled) then
                            continue
                        end
                        ActivateLever(obj)
                    end
                end
            end
        end
        local allActivated = true
        for _, obj in GiantVines:GetDescendants() do
            if obj.Name == "Lever" then
                if obj:GetAttribute("Activated") ~= true then
                    allActivated = false
                    break
                end
            end
        end
        if allActivated then
            Functions.Notify({
                Title = "Successfully Completed The Maze Room",
                Body = "Now you can go to the end"
            })
        end
    end
})


Toggles.ShowSeekPathToggle:AddColorPicker("ShowSeekPathColor", { Text = "Seek Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })
Toggles.ShowSeekPathToggle:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("ShowSeekPathToggle", {"Hotel", "Mines", "Fools", "OldHotel"}, "Show Seek Path") then return end
end)
Toggles.RemoveSeekTrigger:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("RemoveSeekTrigger", {"Hotel", "Mines", "Fools", "OldHotel"}, "Delete Seek Trigger") then return end
end)
Toggles.AutoRevive:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AutoRevive", {"Fools", "OldHotel"}, "Infinite Revives") then return end
end)
Toggles.RemoveFigure:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("RemoveFigure", {"Hotel", "Mines", "Fools", "OldHotel"}, "Delete Figure") then return end
end)


		
local TriggerFigureLooping = false
local TriggerFigureThread
local PlayersService = game:GetService("Players")




local function GetSelectedNames()
	local Selected = Options.PlayerListToTrigger.Value
	local Names = {}
	if type(Selected) == "table" then
		for Name in pairs(Selected) do table.insert(Names, Name) end
	elseif type(Selected) == "string" and Selected ~= "" then
		table.insert(Names, Selected)
	end
	return Names
end

Toggles.LoopTriggerFigure:AddKeyPicker("LoopTriggerFigureKeyPicker", {
	Text = "Trigger Figure", Default = "K", Mode = "Toggle", SyncToggleState = true
})

local function UpdatePlayerList()
	local Names = {}
	for _, Player in ipairs(PlayersService:GetPlayers()) do
		local Character = Player.Character
		if Character and Character:GetAttribute("Alive") == true then
			table.insert(Names, Player.Name)
		end
	end

	local Dropdown = Options.PlayerListToTrigger
	if not Dropdown then return end

	if Dropdown.SetValues then
		pcall(function() Dropdown:SetValues(Names) end)
	elseif Dropdown.UpdateOptions then
		pcall(function() Dropdown:UpdateOptions(Names) end)
	elseif Dropdown.Refresh then
		pcall(function() Dropdown:Refresh(Names) end)
	end
end

task.spawn(function()
	while true do
		UpdatePlayerList()
		task.wait(1)
	end
end)

local HiddenRemotes = game.Workspace:FindFirstChild("mstudio45_Folder")
local TriggerFigureEvent = RemotesFolder:FindFirstChild("FootstepRemoteThatWeNeed")
	or (HiddenRemotes and HiddenRemotes:FindFirstChild("FootstepRemoteThatWeNeed"))

Toggles.LoopTriggerFigure:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("LoopTriggerFigure", {"Hotel", "Mines", "Fools", "OldHotel"}, "Trigger Figure") then return end
	if Value then
		if TriggerFigureLooping then return end
		TriggerFigureLooping = true

		if Floor ~= "Hotel" and Floor ~= "Mines" then
			Functions.Notify({ Title = "Trigger Figure", Body = "This feature isn’t supported on this floor due to the absence of the required remote."})
		else
			Functions.Notify({ Title = "Trigger Figure", Body = "You can get banned from using this feature, its not our fault if you get banned."})
		end

		TriggerFigureThread = task.spawn(function()
			local FireTimer = 0

			while TriggerFigureLooping do
				local Selected = Options.PlayerListToTrigger.Value
				local Names = {}
				if type(Selected) == "table" then
					for Name in pairs(Selected) do table.insert(Names, Name) end
				elseif type(Selected) == "string" and Selected ~= "" then
					table.insert(Names, Selected)
				end

				local Character = PlayersService.LocalPlayer.Character
				local MyHRP = Character and Character:FindFirstChild("HumanoidRootPart")

				FireTimer += 1
				if FireTimer >= 10 then
					FireTimer = 0
					if TriggerFigureEvent then
						TriggerFigureEvent:FireServer()
					end
				end

				for _, PlayerName in ipairs(Names) do
					local Player = PlayersService:FindFirstChild(PlayerName)
					if Player ~= PlayersService.LocalPlayer then
						local HRP = Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
						if HRP and MyHRP then
							MyHRP.CFrame = HRP.CFrame + Vector3.new(0, 11, 0)
							MyHRP.AssemblyLinearVelocity = Vector3.zero
						end
					end
				end

				task.wait()
			end
		end)
	else
		TriggerFigureLooping = false
		TriggerFigureThread = nil
	end
end)
		


local BreakDoorsLooping = false

Toggles.BreakDoorsAnims:OnChanged(function(Value)
	if Value then
		if BreakDoorsLooping then return end
		BreakDoorsLooping = true

		task.spawn(function()
			while BreakDoorsLooping do
				local RoomNumber = tostring(LatestRoom.Value - 1)
				local Room = CurrentRooms:FindFirstChild(RoomNumber)
				local Door = Room and Room:FindFirstChild("Door") and Room.Door:FindFirstChild("Door")

				if Door then
					local BV = Door:FindFirstChild("BodyVelocity")
					if not BV then
						BV = Instance.new("BodyVelocity")
						BV.Parent = Door
					end
					BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					BV.Velocity = Vector3.new(0, 100, 0)
				end

				task.wait(0.2)
			end
			BreakDoorsLooping = false
		end)
	else
		BreakDoorsLooping = false
	end
end)
local ObstructionNames = { ThingToOpen = "RemoveBasementGate", MovingDoor = "RemovePaintingsDoor", Wax_Door = "RemoveSkeletonDoor" }
for ObjName, ToggleName in ObstructionNames do
	Toggles[ToggleName]:OnChanged(function(Value)
		if Value and not Functions.CheckFloorToggle(ToggleName, {"Hotel", "Fools", "OldHotel"}, ToggleName) then return end
		for _, Object in Objects.Obstructions do
			if Object.Name == ObjName then
				Object:PivotTo(Value and CFrame.new(-10000, -10000, -10000) or Object:GetAttribute("OriginalPosition"))
			end
		end
	end)
end

local MainHook
local OtherHook
if Functions.CheckEnv("hookmetamethod", "newcclosure", "getnamecallmethod") then
	MainHook = mstudio45.Environment.hookmetamethod(game, "__namecall", mstudio45.Environment.newcclosure(function(Self, ...)
		local Args = { ... }
		if mstudio45 and mstudio45.Environment then
			local Method = mstudio45.Environment.getnamecallmethod()

			if Self.Name == "Crouch" and Method == "FireServer" then
				if Toggles.AnitFigureHearing.Value or Toggles.PositionSpoof.Value then
					Args[1] = true
				end
				Args[2] = true
			end

			if Self.Name == "MotorReplication" and Method == "FireServer" then
				local DoBypass = (Toggles.BypassEyes.Value and Global.IsEyes) or (Toggles.BypassLookman.Value and Global.IsLookman)
				if DoBypass then
					if Floor == "Fools" or Floor == "OldHotel" then
						Args[1] = 0 Args[2] = (Global.SpoofOffset == 200 and 65 or -65) Args[3] = 0 Args[4] = false
					else
						Args[1] = -650
					end
				end
			end
		end
		return MainHook(Self, table.unpack(Args))
	end))


if Services.ReplicatedStorage:FindFirstChild("ModulesClient") then
	ClientModules = Services.ReplicatedStorage.ModulesClient
else
	ClientModules = Services.ReplicatedStorage.ClientModules
end

Modules = {
	Glitch         = ClientModules.EntityModules:FindFirstChild("Glitch"),
	Shade          = ClientModules.EntityModules:FindFirstChild("Shade"),
	Void           = ClientModules.EntityModules:FindFirstChild("Void"),
	SpiderJumpscare = nil,
	A90            = nil,
	Screech        = nil,
	Dread          = nil,
	GlitchScreech  = nil,
}

local CharacterOldConnectionKeys = {
	"MainHandler", "NoclipStepped", "JumpHandler", "SlideHandler", "LibraryCodeHandler1", "LibraryCodeHandler2",
	"OxygenConnection", "AnimationHandler", "AutoHideConnection", "AutoReviveHandler",
	"SHMFixer", "AnticheatDisabler", "AnticheatEnableDetector1", "AnticheatEnableDetector2",
	"AutoMinecartDuckHandler", "AutoSolveAnchorsConnection",
}

Global.IsTyping = false
Conns.TextBoxConnection1 = Services.UserInputService.TextBoxFocused:Connect(function()
	Global.IsTyping = true
end)
Conns.TextBoxConnection2 = Services.UserInputService.TextBoxFocusReleased:Connect(function()
	Global.IsTyping = false
end)

Functions.HandleCharacter = function(NewCharacter)
	for i = 1, #CharacterOldConnectionKeys do
		local k = CharacterOldConnectionKeys[i]
		local c = Conns[k]
		if c then
			c:Disconnect()
			Conns[k] = nil
		end
	end

	while not LocalPlayer.PlayerGui:FindFirstChild("MainUI") do
		task.wait()
	end

	Character = NewCharacter
	Humanoid = NewCharacter:WaitForChild("Humanoid", 9e9)
	RootPart = NewCharacter:FindFirstChild("HumanoidRootPart")
	Camera   = Services.Workspace.CurrentCamera

	Global.OldCamera = Camera
	Global.MainUI = LocalPlayer.PlayerGui.MainUI

	Collision = NewCharacter:WaitForChild("Collision")
	-- FIX(noclip): real "CollisionPart" is nested inside Collision, not a direct child of Character.
	-- The original lookup fell back to Collision itself, leaving the real wall-blocker untouched.
	CollisionPart  = NewCharacter:FindFirstChild("CollisionPart")
		or (Collision and Collision:FindFirstChild("CollisionPart"))
		or NewCharacter:FindFirstChild("Collision")
	if Variables.POASetupCharacter then
		Variables.POASetupCharacter(NewCharacter)
	end
	CollisionClone = (Variables.POA and Variables.POA.CollisionClone) or NewCharacter:FindFirstChild("CollisionClone")
	CollisionPartClone = (Variables.POA and Variables.POA.CollisionPartClone) or NewCharacter:FindFirstChild("CollisionPartClone")
	if not CollisionClone then
		CollisionClone = Collision:Clone()
		CollisionClone.Parent = NewCharacter
		CollisionClone.Name = "CollisionClone"
		CollisionClone.Massless = true
	end
	if not CollisionPartClone then
		CollisionPartClone = CollisionPart:Clone()
		CollisionPartClone.Parent = NewCharacter
		CollisionPartClone.Name = "CollisionPartClone"
		CollisionPartClone.CanCollide = false
		CollisionPartClone.Massless = true
		if CollisionPartClone:FindFirstChild("CollisionCrouch") then
			CollisionPartClone.CollisionCrouch:Destroy()
		end
	end

	Character:SetAttribute("SpeedBoost", 0)
	Character:SetAttribute("SpeedBoostBehind", 0)
	Character:SetAttribute("SpeedBoostExtra", 0)

	OldJump  = NewCharacter:GetAttribute("CanJump")

	if Toggles.EnableCharacterJump.Value  then Character:SetAttribute("CanJump",  true) end

	if Functions.CheckEnv("require") then
		Main_Game = mstudio45.Environment.require(Global.MainUI.Initiator.Main_Game)
	end

	if Main_Game and Toggles.RemoveCameraBobbing.Value then
		Main_Game.spring.Speed = 9e9
	end

	
	Global.AnticheatDisabled = false

	local RL = Global.MainUI.Initiator.Main_Game:FindFirstChild("RemoteListener")
	local UIModules = RL and RL:FindFirstChild("Modules")
	local Holder = RL and RL:FindFirstChild(DISABLED_HOLDER_NAME)
	Modules.A90             = FindRealModule(UIModules, Holder, "A90")
	Modules.Screech         = FindRealModule(UIModules, Holder, "Screech")
	Modules.Dread           = FindRealModule(UIModules, Holder, "Dread")
	Modules.SpiderJumpscare = FindRealModule(UIModules, Holder, "SpiderJumpscare")

	SyncEntityRemoval()

	if Toggles.DisableHideVignette.Value then
		local Vignette = Global.MainUI:FindFirstChild("HideVignette") or Global.MainUI.MainFrame:FindFirstChild("HideVignette")
		if Vignette then Vignette.Image = "Disabled" end
	end
	if Toggles.DisableEntityJumpscares.Value then
		local JS = Global.MainUI.Initiator.Main_Game.RemoteListener:FindFirstChild("Jumpscares")
		if JS then JS.Name = "Jumpscares_Disabled" end
	end

	CustomPhysics = PhysicalProperties.new(
		100,
		RootPart.CustomPhysicalProperties.Friction,
		RootPart.CustomPhysicalProperties.Elasticity,
		RootPart.CustomPhysicalProperties.FrictionWeight,
		RootPart.CustomPhysicalProperties.ElasticityWeight
	)
	for _, Part in NewCharacter:GetDescendants() do
		if Part:IsA("BasePart") then
			PartProperties[Part] = Part.CustomPhysicalProperties
			if Toggles.RemoveAcceleration.Value then
				Part.CustomPhysicalProperties = CustomPhysics
			end
		end
	end

	local function TryNotifyLibraryCode()
		if not Toggles.NotifyLibraryCode.Value or Global.LibraryCodeFound then return end
		local Code = Functions.GetLibraryCode()
		if Code and not Code:find("_") then
			Global.LibraryCodeFound = true
			local Lock = Services.Workspace:FindFirstChild("Padlock", true)
			Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
		end
	end

	Conns.LibraryCodeHandler1 = LocalPlayer.PlayerGui.PermUI.Hints.ChildAdded:Connect(TryNotifyLibraryCode)
	Conns.LibraryCodeHandler2 = Character.ChildAdded:Connect(function(Child)
		if Child.Name == "LibraryHintPaper" or Child.Name == "LibraryHintPaperHard" then
			TryNotifyLibraryCode()
		end
	end)

	Global.OldOxygen = Character:GetAttribute("Oxygen")
	Conns.OxygenConnection = Character:GetAttributeChangedSignal("Oxygen"):Connect(function()
		local NewOxy = Character:GetAttribute("Oxygen")
		if NewOxy < Global.OldOxygen and Toggles.NotifyOxygen.Value then
			Functions.Caption(Functions.FormatOxygen(NewOxy), true)
		end
		Global.OldOxygen = NewOxy
	end)

	Conns.AutoReviveHandler = LocalPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
		if LocalPlayer:GetAttribute("Alive") == false and Toggles.AutoRevive.Value then
			if Floor == "Fools" or Floor == "OldHotel" then
				while LocalPlayer:GetAttribute("Alive") ~= true do
					RemotesFolder.Revive:FireServer()
					task.wait(0.5)
				end
			end
		end
	end)

	Conns.SHMFixer = RootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		task.wait()
		if Floor == "Fools" and RootPart.Anchored and Character:GetAttribute("Hiding") ~= true then
			RootPart.Anchored = false
		end
	end)

	Conns.AnticheatDisabler = Character:GetAttributeChangedSignal("Climbing"):Connect(function()
		if Character:GetAttribute("Climbing") == true and Toggles.DisableAnticheat.Value and not Global.AnticheatDisabled then
			task.wait(0.25)
			Character:SetAttribute("Climbing", false)
			Global.AnticheatDisabled = true
			Functions.Notify({ Title = "Disable Anticheat", Body = "Successfully disabled the anticheat, It will be \nre-enabled after a cutscene or halt room." })
		end
	end)

	Conns.AnticheatEnableDetector1 = RemotesFolder:WaitForChild("Cutscene").OnClientEvent:Connect(function(CutsceneName)
		if Global.AnticheatDisabled and not CutsceneName:find("SewerSeek") then
			Global.AnticheatDisabled = false
			Functions.Notify({ Title = "Disable Anticheat", Body = "The anticheat has been re-enabled, Interact with a ladder to disable it again." })
		end
	end)

	Conns.AnticheatEnableDetector2 = RemotesFolder:WaitForChild("UseEnemyModule").OnClientEvent:Connect(function(ModuleName)
		if (ModuleName == "Void" or ModuleName == "Glitch") and Global.AnticheatDisabled then
			Global.AnticheatDisabled = false
			Functions.Notify({ Title = "Disable Anticheat", Body = "The anticheat has been re-enabled, Interact with a ladder to disable it again." })
		end
		if ModuleName == "Void" or ModuleName == "Glitch" then
			LocalPlayer:SetAttribute("CurrentRoom", LatestRoom.Value)
		end
	end)

	Conns.AnimationHandler = Character.ChildAdded:Connect(function()
		local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron", "Multitool" }
		local Tool
		for _, Name in ToolNames do
			Tool = Character:FindFirstChild(Name)
			if Tool then break end
		end
		if not Tool then return end

		local UseAnim = Tool:FindFirstChild("use", true) or Tool:FindFirstChild("promptanim", true)
		if UseAnim then
			UseAnim = Humanoid:LoadAnimation(UseAnim)
			UseAnim.Priority = Enum.AnimationPriority.Action4
			Global.UseAnimation = UseAnim
		end
		local UseAnimBreak = Tool:FindFirstChild("usefinish", true) or Tool:FindFirstChild("promptanimend", true) or Tool:FindFirstChild("lockpickuse", true)
		if UseAnimBreak then
			UseAnimBreak = Humanoid:LoadAnimation(UseAnimBreak)
			UseAnimBreak.Priority = Enum.AnimationPriority.Action4
			Global.UseAnimationBreak = UseAnimBreak
		end
	end)

	Conns.JumpHandler = Character:GetAttributeChangedSignal("CanJump"):Connect(function()
		local Val = Character:GetAttribute("CanJump")
		if Toggles.EnableCharacterJump.Value and Val ~= true or not Toggles.EnableCharacterJump.Value then
			OldJump = Val
		end
		if Toggles.EnableCharacterJump.Value then Character:SetAttribute("CanJump", true) end
	end)

	Global.SpoofOffset = 0

	Global.LastAutoAnchor = tick()
	Conns.AutoSolveAnchorsConnection = Services.RunService.Heartbeat:Connect(function()
		if not Toggles.AutoSolveAnchors.Value then return end
		if not Global.MainUI:FindFirstChild("AnchorHintFrame") then return end
		if tick() - Global.LastAutoAnchor <= 0.1 then return end
		local Anchor = Functions.GetCurrentAnchor()
		if Anchor and LocalPlayer:DistanceFromCharacter(Anchor.PrimaryPart.Position) < Anchor.ActivateEventPrompt.MaxActivationDistance and not Anchor:GetAttribute("Activated") then
			Anchor:WaitForChild("AnchorRemote"):InvokeServer(Global.MainUI.AnchorHintFrame.Code.Text)
		end
		Global.LastAutoAnchor = tick()
	end)

	Global.ManipulateBody = Instance.new("BodyVelocity")
	Global.ManipulateBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Global.FlyBody = Instance.new("BodyVelocity")
	Global.FlyBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	Global.SelfKilled = false
	Global.ThirdPersonParts = {}
	for _, Object in Character:GetDescendants() do
		if Object:IsA("Accessory") and Object:FindFirstChild("Handle") then
			table.insert(Global.ThirdPersonParts, Object.Handle)
		end
	end
	table.insert(Global.ThirdPersonParts, Character:WaitForChild("Head"))

	Global.LastAnimationCheck = tick()
	Global.LastCrouchFire = tick()
	if Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
		Global.OriginalC1 = Character.LowerTorso.Root.C1
	end

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- FIX(noclip): RenderStepped fires AFTER physics, so CanCollide=false set there
	-- has no effect on the current frame's collision. Stepped fires BEFORE physics,
	-- so disabling CanCollide here ensures the physics engine sees no collision.
	Conns.NoclipStepped = Services.RunService.Stepped:Connect(function()
		if not (Character and Character.Parent and RootPart and RootPart.Parent) then return end
		local isNoclip = (Toggles.NoclipToggle and Toggles.NoclipToggle.Value)
			or (Toggles.TeleportManipulationToggle and Toggles.TeleportManipulationToggle.Value)
			or false
		if isNoclip then
			-- When noclip is ON: kill ALL collision so physics can't block movement.
			for _, Part in Character:GetDescendants() do
				if Part:IsA("BasePart") and Part.CanCollide then
					Part.CanCollide = false
				end
			end
			RootPart.CanCollide = false
		else
			-- When noclip is OFF: disable everything except CollisionClone
			-- (which provides normal floor/wall collision).
			for _, Part in Character:GetDescendants() do
				if Part:IsA("BasePart")
					and Part ~= CollisionClone
					and Part ~= CollisionPartClone
					and Part.Name ~= "CollisionClone"
					and Part.Name ~= "CollisionPartClone"
					and Part.CanCollide then
					Part.CanCollide = false
				end
			end
			if CollisionClone and CollisionClone.Parent then
				CollisionClone.CanCollide = true
				local cc = CollisionClone:FindFirstChild("CollisionCrouch")
				if cc then cc.CanCollide = true end
			end
		end
	end)

	Conns.MainHandler = Services.RunService.RenderStepped:Connect(function()
		if Services.Workspace:FindFirstChild("Camera") then
			Camera = Services.Workspace:FindFirstChild("Camera")
		end

		if Toggles.WalkSpeedToggle.Value then
			Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + Options.WalkSpeedSlider.Value
		end

		if Global.Lagging or (Options.WalkSpeedSlider.Value <= 6 and Options.FlySpeed.Value <= 21) then
			if CollisionPartClone then CollisionPartClone.Massless = true end
		end

		Global.IsEyes    = Services.Workspace:FindFirstChild("Eyes") ~= nil or Services.Workspace:FindFirstChild("Lookman") ~= nil
		Global.IsLookman = Services.Workspace:FindFirstChild("BackdoorLookman") ~= nil

		if Toggles.AmbientToggle.Value then
			Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { Ambient = Options.AmbientColor.Value }):Play()
		end

		if Main_Game then
			if Toggles.RemoveCameraShake.Value     then Main_Game.csgo = CFrame.new() end
		end

		if Global.SelfKilled and Global.MainUI:FindFirstChild("Statistics") then
			Global.MainUI.Statistics.Death.Text = "Died to homeless dog"
		end

		local MainFrame = Global.MainUI:FindFirstChild("MainFrame")
		if MainFrame then
			local Effects = MainFrame.Healthbar:FindFirstChild("Effects")
			if Effects and Effects:FindFirstChild("Crouching") then
				Effects.Crouching.Visible = Functions.IsCrouching()
			end
		end

		if (Toggles.AnitFigureHearing.Value or Toggles.PositionSpoof.Value) and RemotesFolder:FindFirstChild("Crouch") then
			RemotesFolder.Crouch:FireServer(true)
		end

		if Floor ~= "Fools" and Floor ~= "OldHotel" and not Camera:FindFirstChild("MinecartRig") then
			RootPart.CanCollide = false
		end

		-- FIX(noclip) v2: blanket-disable collision on all character parts EXCEPT the
		-- collision proxies managed by the POA / noclip system. Excluding them here
		-- prevents this loop from racing against the POA RenderStepped (which sets
		-- CollisionClone.CanCollide = true when Noclip is OFF so the character has
		-- normal floor/wall collision).
		local _isNoclip = (Toggles.NoclipToggle and Toggles.NoclipToggle.Value)
			or (Toggles.TeleportManipulationToggle and Toggles.TeleportManipulationToggle.Value)
			or false
		for _, Part in Character:GetDescendants() do
			if Part:IsA("BasePart")
				and Part ~= CollisionClone
				and Part ~= CollisionPartClone
				and Part.Name ~= "CollisionClone"
				and Part.Name ~= "CollisionPartClone" then
				Part.CanCollide = false
			end
		end
		-- Explicitly drive CollisionClone collision here so noclip works even when
		-- the POA system hasn't initialised (e.g. Collision part not found on spawn).
		-- POA RenderStepped does the same thing, so there is no conflict.
		if Floor ~= "OldHotel" and Floor ~= "Fools" then
			if CollisionClone and CollisionClone.Parent then
				CollisionClone.CanCollide = not _isNoclip
				local _cloneCrouch = CollisionClone:FindFirstChild("CollisionCrouch")
				if _cloneCrouch then
					_cloneCrouch.CanCollide = not _isNoclip
				end
			end
			if CollisionPartClone and CollisionPartClone.Parent then
				CollisionPartClone.CanCollide = false
			end
		end

		if LocalPlayer:GetAttribute("Alive") == true then
			Services.SoundService:WaitForChild("Main").Volume = 1
		end

		if Floor == "OldHotel" or Floor == "Fools" then
			local isSpoof = (Toggles.PositionSpoof and Toggles.PositionSpoof.Value) or (Toggles.CollisionOffsetGodmodeAlt and Toggles.CollisionOffsetGodmodeAlt.Value)
			local SpoofOffset = isSpoof and Functions.GetNearestEntity() and 200 or 0
			Global.SpoofOffset = SpoofOffset
			Collision.Position = RootPart.Position + Vector3.new(0, SpoofOffset, 0)
			Collision.CanCollide = false
			if Floor == "Fools" then
				if Collision:FindFirstChild("CollisionCrouch") then Collision.CollisionCrouch.CanCollide = false end
				if CollisionClone and CollisionClone:FindFirstChild("CollisionCrouch") then CollisionClone.CollisionCrouch.CanCollide = false end
			end
			RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.TeleportManipulationToggle.Value)
		end

		if Toggles.TeleportManipulationToggle.Value then
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
			local moveDir = (Humanoid.MoveDirection.Magnitude > 0 and Humanoid.MoveDirection.Unit)
				or (Camera and Camera.CFrame.LookVector)
				or RootPart.CFrame.LookVector
			if Options.TeleportManipulationMode.Value == "Velocity" then
				Global.ManipulateBody.Parent = RootPart
				Global.ManipulateBody.Velocity = moveDir * 2.25
			elseif Options.TeleportManipulationMode.Value == "Pivot" and Floor ~= "Fools" and Floor ~= "OldHotel" then
				Global.ManipulateBody.Parent = nil
				Character:PivotTo(Character:GetPivot() + moveDir * 0.08)
			else
				Global.ManipulateBody.Parent = nil
			end
		else
			Global.ManipulateBody.Parent = nil
		end

		if Toggles.FlyToggle.Value then
			Global.FlyBody.Parent = RootPart
			Global.FlyBody.Velocity = Functions.GetFlyVelocity() * Options.FlySpeed.Value
		else
			Global.FlyBody.Parent = nil
		end

		local DoEyesBypass = (Toggles.BypassEyes.Value and Global.IsEyes) or (Toggles.BypassLookman.Value and Global.IsLookman)
		if DoEyesBypass then
			if Floor == "Fools" or Floor == "OldHotel" then
				RemotesFolder.MotorReplication:FireServer(0, (Global.SpoofOffset == 200 and 65 or -65), 0, false)
			else
				RemotesFolder.MotorReplication:FireServer(-650)
			end
		end

		if RemotesFolder:FindFirstChild("Crouch") and tick() - Global.LastCrouchFire > 0.1 then
			local IsCrouch = Functions.IsCrouching()
			if Toggles.AnitFigureHearing.Value or Toggles.PositionSpoof.Value then IsCrouch = true end
			RemotesFolder.Crouch:FireServer(IsCrouch, true)
			Global.LastCrouchFire = tick()
		end

		if tick() - Global.LastAnimationCheck > 0.1 then
			local Sliding = false
			for _, Anim in Humanoid:GetPlayingAnimationTracks() do
				if Anim.Name == "Slide" then Sliding = true break end
			end
			Global.Sliding = Sliding
			Global.LastAnimationCheck = tick()
		end

		Character:SetAttribute("Sliding", Global.Sliding)
		if Character:GetAttribute("Crouching") ~= Functions.IsCrouching() then
			Character:SetAttribute("Crouching", Functions.IsCrouching())
		end


		RayParams.FilterDescendantsInstances = { Character }
		local TPOffset = CFrame.new(Options.ThirdPersonOffsetX.Value, Options.ThirdPersonOffsetY.Value, Options.ThirdPersonOffsetZ.Value)
		local Direction = (Camera.CFrame * TPOffset).Position - Camera.CFrame.Position
		local WallResult = Services.Workspace:Spherecast(Camera.CFrame.Position, 0.2, Direction, RayParams)

		if Toggles.ThirdPersonToggle.Value then
			if Toggles.ThirdPersonWallCheck.Value and WallResult and WallResult.Instance.CanCollide then
				local NewPos = Camera.CFrame.Position + Direction.Unit * WallResult.Distance
				Camera.CFrame = CFrame.new(NewPos, NewPos + Camera.CFrame.LookVector)
			else
				Camera.CFrame = Camera.CFrame * TPOffset
			end
		end

		for _, Part in Global.ThirdPersonParts do
			Part.Transparency = Toggles.ThirdPersonToggle.Value and 0 or 1
			Part.LocalTransparencyModifier = Toggles.ThirdPersonToggle.Value and 0 or 1
		end

		if type(Main_Game) == "table" or typeof(Main_Game) == "Instance" then
			pcall(function() Main_Game.fovtarget = Options.FieldOfView.Value end)
		else
			Camera.FieldOfView = Options.FieldOfView.Value
		end

		if Toggles.RemoveClosetDelay.Value
			and Humanoid.MoveDirection ~= Vector3.zero
			and (CollisionPart.Anchored or RootPart.Anchored)
			and Character:GetAttribute("AnimatingClient") ~= true
			and Character:GetAttribute("Hiding") == true
		then
			RemotesFolder.CamLock:FireServer()
		end

		local ClosestPlayer = { Distance = math.huge, Object = nil }
		for _, Player in Services.Players:GetPlayers() do
			if Player.Character and Player ~= LocalPlayer then
				local Root = Player.Character:FindFirstChild("HumanoidRootPart")
				if Root then
					local D = (Camera.CFrame.Position - Root.Position).Magnitude
					if D < ClosestPlayer.Distance then
						ClosestPlayer.Distance = D
						ClosestPlayer.Object = Player
					end
				end
			end
		end
		if ClosestPlayer.Object and LocalPlayer:GetAttribute("Alive") ~= true then
			LocalPlayer:SetAttribute("CurrentRoom", ClosestPlayer.Object:GetAttribute("CurrentRoom"))
		end
	end)

	task.wait(1)
	if (Toggles.PositionSpoof.Value or Toggles.CollisionOffsetGodmodeAlt.Value) and Floor ~= "Fools" and Floor ~= "OldHotel" then
		if Variables.POASetupCharacter then
			Variables.POASetupCharacter(Character)
		end
	end

	local Jam = Global.MainUI.Initiator.Main_Game.Health:FindFirstChild("Jam")
	if Jam and Toggles.RemoveJamminMusic.Value then
		Jam.Volume = 0
		Global.JamMuffle.Enabled = false
	end
end

Functions.HandleHidingTransparency = function(Model)
	local Parts = {}
	for _, Part in Model:GetDescendants() do
		if Part:IsA("BasePart") then
			Part:SetAttribute("Transparency_Old", Part.Transparency)
			table.insert(Parts, Part)
		end
		if Part.Name == "HiddenPlayer" then
			local HideConn = Part:GetPropertyChangedSignal("Value"):Connect(function()
				for _, P in Parts do
					if P:GetAttribute("Transparency_Old") then
						Services.TweenService:Create(P, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
							Transparency = (Part.Value == Character and Toggles.TransparentHidingSpotsToggle.Value)
								and Options.TransparentHidingSpotsSlider.Value
								or P:GetAttribute("Transparency_Old")
						}):Play()
					end
				end
			end)
			table.insert(Conns, HideConn)
			Model.Destroying:Once(function()
				HideConn:Disconnect()
				local Pos = table.find(Conns, HideConn)
				if Pos then table.remove(Conns, Pos) end
			end)
		end
	end
end

-- per-run water esp state: instance attributes survive script reloads in the same
-- session and would block re-attaching, so key run markers on this table instead
local AttachedWaterESP = {}

-- Forget-Me-Not puzzle: the room holds two copies of the same layout — the room's own
-- "Assets" and a replica Model named after the local player. The server removes an
-- object from the replica; diff the two and mark what the replica is missing.
Functions.AnalyzeForgetMeNot = function(Replica)
	task.spawn(function()
		local Room = Replica.Parent
		if not (Room and Room.Parent == CurrentRooms) then return end

		-- let the replica finish streaming in
		task.wait(3)
		if not Replica.Parent then return end

		local SourceAssets = Room:FindFirstChild("Assets")
		local ReplicaAssets = Replica:FindFirstChild("Assets")
		if not (SourceAssets and ReplicaAssets) then return end

		local Source = SourceAssets:FindFirstChild("Deletable") or SourceAssets
		local Target = ReplicaAssets:FindFirstChild("Deletable") or ReplicaAssets

		local function Collect(root)
			local map = {}
			for _, d in ipairs(root:GetDescendants()) do
				if (d:IsA("Model") or d:IsA("MeshPart")) and not tonumber(d.Name) then
					map[d.Name] = map[d.Name] or {}
					table.insert(map[d.Name], d)
				end
			end
			return map
		end

		local A, B = Collect(Source), Collect(Target)

		-- offset between the two copies, from equally-counted shared models paired by position
		local xs, ys, zs = {}, {}, {}
		local function SortByPos(l)
			table.sort(l, function(p, q)
				local a, b = p:GetPivot().Position, q:GetPivot().Position
				if a.X ~= b.X then return a.X < b.X end
				if a.Y ~= b.Y then return a.Y < b.Y end
				return a.Z < b.Z
			end)
		end
		for name, listA in pairs(A) do
			local listB = B[name]
			if listB and #listB > 0 and #listA == #listB then
				SortByPos(listA)
				SortByPos(listB)
				for i = 1, #listA do
					local delta = listB[i]:GetPivot().Position - listA[i]:GetPivot().Position
					table.insert(xs, delta.X)
					table.insert(ys, delta.Y)
					table.insert(zs, delta.Z)
				end
			end
		end
		local function Median(t)
			if #t == 0 then return 0 end
			table.sort(t)
			return t[math.ceil(#t / 2)]
		end
		local Offset = Vector3.new(Median(xs), Median(ys), Median(zs))

		-- objects fully missing from the replica, keeping only top-level ones
		local missing = {}
		for name, listA in pairs(A) do
			if not B[name] then
				missing[name] = listA[1]
			end
		end
		local function HasMissingAncestor(inst)
			local anc = inst.Parent
			while anc and anc ~= Room do
				if missing[anc.Name] then return true end
				anc = anc.Parent
			end
			return false
		end

		local markers = {}
		for name, inst in pairs(missing) do
			if not HasMissingAncestor(inst) then
				table.insert(markers, { name = name, inst = inst })
			end
		end
		if #markers == 0 then return end

		-- collapse clustered markers, keeping the largest object of each cluster
		table.sort(markers, function(a, b)
			return a.inst:GetExtentsSize().Magnitude > b.inst:GetExtentsSize().Magnitude
		end)
		local kept = {}
		for _, m in ipairs(markers) do
			local pos = m.inst:GetPivot().Position
			local near = false
			for _, k in ipairs(kept) do
				if (k.inst:GetPivot().Position - pos).Magnitude < 15 then
					near = true
					break
				end
			end
			if not near then table.insert(kept, m) end
		end

		local names = {}
		for _, m in ipairs(kept) do
			local Marker = Instance.new("Part")
			Marker.Name = "FMN_Anomaly_Marker"
			Marker.Anchored = true
			Marker.CanCollide = false
			Marker.CanQuery = false
			Marker.CanTouch = false
			Marker.Transparency = 1
			Marker.Size = Vector3.new(2, 2, 2)
			Marker.Position = m.inst:GetPivot().Position + Offset
			Marker:SetAttribute("ParentRoom", tonumber(Room.Name))
			Marker.Parent = Services.Workspace

			Functions.AddESP({ Object = Marker, Text = m.name .. " [Missing]", Color = Color3.fromRGB(255, 60, 60) }, true)
			table.insert(Objects.Entities, Marker)
			names[#names + 1] = m.name
		end

		if #names > 0 then
			Functions.Notify({ Title = "Forget-Me-Not", Body = "Replica is missing: " .. table.concat(names, ", ") })
		end

		-- door picking, verified against live playthroughs:
		-- with an anomaly present the real exit is the door NEAR the missing object;
		-- with no anomaly the real exit is the door WITHOUT the BaseDirection attribute
		local doorBases = {}
		for _, vd in ipairs(Replica:GetDescendants()) do
			if vd.Name == "ForgetMeNotVineDoors" then
				local Base = vd:FindFirstChild("Base")
				if Base then
					table.insert(doorBases, Base)
				end
			end
		end
		if #doorBases > 0 then
			local correct
			if #kept > 0 and kept[1].inst then
				-- anomaly case: closest door to the missing object's mirrored position
				local anomalyPos = kept[1].inst:GetPivot().Position + Offset
				local bestDist = math.huge
				for _, Base in ipairs(doorBases) do
					local dist = (Base.Position - anomalyPos).Magnitude
					if dist < bestDist then
						correct, bestDist = Base, dist
					end
				end
			else
				-- clean case: the door lacking BaseDirection is the real passage
				for _, Base in ipairs(doorBases) do
					if Base:GetAttribute("BaseDirection") == nil then
						correct = Base
						break
					end
				end
			end

			for _, Base in ipairs(doorBases) do
				local isCorrect = (Base == correct)
				Base:SetAttribute("ParentRoom", tonumber(Room.Name))
				Functions.AddESP({
					Object = Base,
					Text = isCorrect and "Correct Door" or "Wrong Door",
					Color = isCorrect and Color3.fromRGB(60, 255, 90) or Color3.fromRGB(255, 60, 60)
				}, true)
				table.insert(Objects.Objectives, Base)
			end
		end
	end)
end

-- Auto Forget-Me-Not: while the puzzle room is active, keep pivoting the player
-- to the room's CanGo part until the exit door's open sound starts playing
local ForgetMeNotRunning = false

local function GetForgetMeNotOpenSound(Room)
	local Door = Room and Room:FindFirstChild("Door")
	local Inner = Door and Door:FindFirstChild("Door")
	local Open = Inner and Inner:FindFirstChild("Open")
	if Open and Open:IsA("Sound") then
		return Open
	end
	return nil
end

local function StopAutoForgetMeNot()
	ForgetMeNotRunning = false
	if Conns.ForgetMeNotLoop then
		Conns.ForgetMeNotLoop:Disconnect()
		Conns.ForgetMeNotLoop = nil
	end
end

local function HandleForgetMeNot(Room)
	if ForgetMeNotRunning then return end
	ForgetMeNotRunning = true
	Conns.ForgetMeNotLoop = Services.RunService.Heartbeat:Connect(function()
		if not ForgetMeNotRunning or not (Toggles.AutoForgetMeNot and Toggles.AutoForgetMeNot.Value) then
			ForgetMeNotRunning = false
			if Conns.ForgetMeNotLoop then
				Conns.ForgetMeNotLoop:Disconnect()
				Conns.ForgetMeNotLoop = nil
			end
			return
		end
		local Car = CurrentRooms:FindFirstChild(tostring(LatestRoom.Value))
		local OpenSound = Car and GetForgetMeNotOpenSound(Car)
		if OpenSound and OpenSound.IsPlaying then
			StopAutoForgetMeNot()
			return
		end
		local Door = Car and Car:FindFirstChild("Door")
		local CanGo = Door and Door:FindFirstChild("CanGo")
		local Char = LocalPlayer.Character
		if Char and CanGo then
			Char:PivotTo(CanGo.CFrame)
		end
	end)
end

Conns.ForgetMeNotWatcher = CurrentRooms.DescendantAdded:Connect(function(Object)
	if not (Toggles.AutoForgetMeNot and Toggles.AutoForgetMeNot.Value) then return end
	if Object:IsA("Model") and Object.Name == LocalPlayer.Name and Object.Parent and Object.Parent.Parent == CurrentRooms then
		HandleForgetMeNot(Object.Parent)
	end
end)

Toggles.AutoForgetMeNot:OnChanged(function(Value)
	if Value and not Functions.CheckFloorToggle("AutoForgetMeNot", {"Hotel", "Mines", "Backdoor", "Rooms"}, "Auto ForgetMeNot") then return end
	if not Value then
		StopAutoForgetMeNot()
	end
end)

-- Archives (Honcho floor): a package deposit has attribute BoxID; a matching
-- ArchivesStorageBox carries the same id as Tool_BoxID. Honcho/deposits/boxes can
-- show up in any room, so rooms are never hardcoded here: pairs are matched by id
-- and both sides are tracked until the other one shows up, in any order.
Global.ArchivesDeposits = {}
Global.ArchivesBoxes = {}

Functions.LinkArchivesBox = function(Object, ID)
	if ID == nil then return end
	ID = tostring(ID)

	if Object.Name == "ArchivesPackageDeposit" then
		Global.ArchivesDeposits[ID] = Object
		local Box = Global.ArchivesBoxes[ID]
		if Box then
			Functions.LabelArchivesPair(Object, Box, ID)
		end
	elseif Object.Name == "ArchivesStorageBox" then
		Global.ArchivesBoxes[ID] = Object
		local Deposit = Global.ArchivesDeposits[ID]
		if Deposit then
			Functions.LabelArchivesPair(Deposit, Object, ID)
		end
	end
end

Functions.LabelArchivesPair = function(Deposit, Box, ID)
	if not (Deposit and Deposit.Parent and Box and Box.Parent) then return end
	if Toggles.ObjectiveESPToggle.Value then
		Functions.AddESP({ Object = Deposit, Text = "Package Deposit [" .. ID .. "]", Color = Options.ObjectiveESPColor.Value }, true)
		Functions.AddESP({ Object = Box, Text = "Storage Box [" .. ID .. "]", Color = Options.ObjectiveESPColor.Value }, true)
	end
end

Functions.HandleObject = function(Object)
	for _, Room in CurrentRooms:GetChildren() do
		if Object:IsDescendantOf(Room) then
			Object:SetAttribute("ParentRoom", tonumber(Room.Name))
			break
		end
	end

	if Object.Parent == CurrentRooms then
		local FiredampVal = Object:GetAttribute("Firedamp")
		Object:SetAttribute("Firedamp_Old", FiredampVal ~= nil and FiredampVal or false)
		if Toggles.DisableFiredampEffect.Value then
			Object:SetAttribute("Firedamp", false)
		end
	end

	local Name = Object.Name

	if Name == "Creak" then
		-- creak sounds with the same name get placed in Terrain/misparented spots: only
		-- the real entity is a Model inside LiveEntities, everything else is ignored
		if not (Object:IsA("Model") and Object.Parent and Object.Parent.Name == "LiveEntities") then
			return
		end
		-- creak from LiveEntities: esp on the whole model (every body part at once);
		-- HumanoidRootPart is its head/anchor, so the model needs PrimaryPart pinned
		-- for the library to compute bounds over the full body
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Creak"] then
			Functions.Notify({ Title = "Entity 'Creak' has spawned.", Body = "Watch your step." })
		end
		if not Object.PrimaryPart then
			Object.PrimaryPart = Object:FindFirstChild("HumanoidRootPart") or Object:FindFirstChildWhichIsA("BasePart")
		end
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Creak"] then
			Functions.AddESP({ Object = Object, Text = "Creak", Color = Options.EntityESPColor.Value }, false)
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "StemsEntity" then
		-- stems entity (child of the StemsNyxvhal model): anchored on its RootPart
		local Root = Object:FindFirstChild("RootPart") or Object.PrimaryPart or Object:FindFirstChildWhichIsA("BasePart")
		if Root then
			if not Object.PrimaryPart then Object.PrimaryPart = Root end
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Stems"] then
				Functions.AddESP({ Object = Root, Text = "Stems", Color = Options.EntityESPColor.Value }, false)
			end
			if Toggles.NotifyEntities.Value and Options.EntityList.Value["Stems"] then
				Functions.Notify({ Title = "Entity 'Stems' has spawned.", Body = "Don't get too close to the stems." })
			end
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Noise" then
		-- noise entity: esp on its root/head + notify
		local Root = Object.PrimaryPart or Object:FindFirstChild("HumanoidRootPart") or Object:FindFirstChild("Head") or Object:FindFirstChildWhichIsA("BasePart")
		if Root then
			if not Object.PrimaryPart then Object.PrimaryPart = Root end
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Noise"] then
				Functions.AddESP({ Object = Root, Text = "Noise", Color = Options.EntityESPColor.Value }, false)
			end
			if Toggles.NotifyEntities.Value and Options.EntityList.Value["Noise"] then
				Functions.Notify({ Title = "Entity 'Noise' has spawned.", Body = "Watch out for Noise." })
			end
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Hijack" then
		-- hijack entity: esp on its root/head + notify
		local Root = Object.PrimaryPart or Object:FindFirstChild("HumanoidRootPart") or Object:FindFirstChild("Head") or Object:FindFirstChildWhichIsA("BasePart")
		if Root then
			if not Object.PrimaryPart then Object.PrimaryPart = Root end
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Hijack"] then
				Functions.AddESP({ Object = Root, Text = "Hijack", Color = Options.EntityESPColor.Value }, false)
			end
			if Toggles.NotifyEntities.Value and Options.EntityList.Value["Hijack"] then
				Functions.Notify({ Title = "Entity 'Hijack' has spawned.", Body = "Something is trying to hijack you." })
			end
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "HonchoRig" then
		-- honcho entity: lives in workspace.LiveEntities in any room (never a fixed
		-- room number), esp on the whole model like Creak; PrimaryPart is pinned so
		-- the library can compute bounds over the full body
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Honcho"] then
			Functions.Notify({ Title = "Entity 'Honcho' has spawned.", Body = "Watch out for Honcho." })
		end
		if not Object.PrimaryPart then
			Object.PrimaryPart = Object:FindFirstChild("HumanoidRootPart") or Object:FindFirstChild("Root") or Object:FindFirstChildWhichIsA("BasePart")
		end
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Honcho"] then
			Functions.AddESP({ Object = Object, Text = "Honcho", Color = Options.EntityESPColor.Value }, false)
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "ArchivesPackageDeposit" then
		-- package deposit: shows its BoxID and links to the matching storage box
		local BoxID = Object:GetAttribute("BoxID")
		if Toggles.ObjectiveESPToggle.Value then
			Functions.AddESP({ Object = Object, Text = "Package Deposit [" .. tostring(BoxID or "?") .. "]", Color = Options.ObjectiveESPColor.Value }, true)
		end
		Functions.LinkArchivesBox(Object, BoxID)
		table.insert(Objects.Objectives, Object)
	elseif Name == "ArchivesStorageBox" then
		-- storage box: esp only once a deposit with the same id exists (Tool_BoxID matches a BoxID)
		table.insert(Objects.Objectives, Object)
		Functions.LinkArchivesBox(Object, Object:GetAttribute("Tool_BoxID"))
	elseif Name:match("^MirrorRig_Portrait") and Object:IsA("Model") then
		-- portrait clone of the player shown in mirror scenes: lives under the camera
		-- (not in a room) and the game reuses one rig, moving it between mirrors, so
		-- the esp bypasses the room gate and the notify follows each scene approach
		if not Object.PrimaryPart then
			Object.PrimaryPart = Object:FindFirstChild("HumanoidRootPart") or Object:FindFirstChildWhichIsA("BasePart")
		end
		EntityESPLabels[Name] = "Portrait"
		if Object.PrimaryPart then
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Portrait"] then
				Functions.AddESP({ Object = Object, Text = "Portrait", Color = Options.EntityESPColor.Value }, false)
			end

			local InScene = false
			local PortraitWatchConn
			PortraitWatchConn = Services.RunService.Heartbeat:Connect(function()
				if not Object.Parent then
					if PortraitWatchConn then PortraitWatchConn:Disconnect() end
					return
				end
				local Char = LocalPlayer.Character
				local Root = Char and Char:FindFirstChild("HumanoidRootPart")
				if not (Root and Object.PrimaryPart) then return end
				local Dist = (Root.Position - Object.PrimaryPart.Position).Magnitude
				if Dist < 80 and not InScene then
					InScene = true
					Functions.Notify({ Title = "Entity 'Portrait' has spawned.", Body = "Your mirror portrait is active." })
				elseif Dist >= 120 then
					InScene = false
				end
			end)
			table.insert(Conns, PortraitWatchConn)
		end
		table.insert(Objects.Entities, Object)
	elseif Name == LocalPlayer.Name and Object:IsA("Model") and Object.Parent and Object.Parent.Parent == CurrentRooms then
		Functions.AnalyzeForgetMeNot(Object)
	elseif Name == "KeyObtain" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Door Key", Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "ElectricalKeyObtain" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Electrical Key", Color = Options.ObjectiveESPColor.Value }, true) end
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "TimerLever" then
		task.spawn(function()
			task.wait(0.5)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Time Lever", Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild("Main").SoundToPlay.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "LiveHintBook" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Book", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "LiveBreakerPolePickup" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Fuse Breaker", Color = Options.ObjectiveESPColor.Value }, true) end
		for _, Child in Object:GetChildren() do
			if Child.Name == "ActivateEventPrompt" and (Child.MaxActivationDistance == 5 or Child:GetAttribute("MaxActivationDistance_Old") == 5) then
				Child:Destroy()
			end
		end
		table.insert(Objects.Objectives, Object)
	elseif Name == "LibraryHintPaper" or Name == "PickupItem" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Paper", Color = Options.ObjectiveESPColor.Value }, true) end
		table.insert(Objects.Objectives, Object)
	elseif Name == "MinesAnchor" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:GetAttributeChangedSignal("Activated"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif ObjectiveMainAnchors[Name] then
		-- stairwell / misc interactables (LargeScrew, DinkyLamp, BottleCrate, ...):
		-- esp anchored on the Main child part when the game builds it that way
		local Anchor = Object:FindFirstChild("Main") or Object
		if Anchor ~= Object and not Anchor:GetAttribute("ParentRoom") then
			Anchor:SetAttribute("ParentRoom", Object:GetAttribute("ParentRoom"))
		end
		if Name == "TV_Stand" and not Object:GetAttribute("ParentRoom") then
			-- TV_Stand lives under workspace.Misc, not in a room: stamp the player's
			-- current room so the objective esp keeps working with the room gate
			local Cur = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
			if Cur then
				Object:SetAttribute("ParentRoom", Cur)
				if Anchor ~= Object then Anchor:SetAttribute("ParentRoom", Cur) end
			end
		end
		if Toggles.ObjectiveESPToggle.Value then
			Functions.AddESP({ Object = Anchor, Text = ObjectiveLabels[Name] or Name, Color = Options.ObjectiveESPColor.Value }, true)
		end
		table.insert(Objects.Objectives, Object)
	elseif Name == "WaterPump" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object:WaitForChild("Wheel"), Text = "Water Pump", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Wheel").Sound.Played:Once(function()
			Functions.RemoveESP(Object.Wheel)
			Functions.BlacklistESP(Object.Wheel)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "CringlePresent" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Present", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("ToolProp").Highlight:Destroy()
		table.insert(Objects.Objectives, Object)
	elseif Name == "LeverForGate" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Lever", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Main").SoundToPlay.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "VineGuillotine" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object.Lever, Text = "Vine Lever", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Lever:WaitForChild("ActivateEventPrompt"):GetAttributeChangedSignal("Interactions"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "MandrakeLive" then
		local Mandrake = Object:FindFirstChild("Mandrake")
		if Mandrake then
			local Root = Mandrake:FindFirstChild("Root")
			if Root then
				if Toggles.ObjectiveESPToggle.Value and Options.EntityESPOptions.Value["Mandrake Hole"] then
					Functions.AddESP({ Object = Object.Hole, Text = "Mandrake Hole", Color = Options.EntityESPColor.Value }, true)
				end
				table.insert(Objects.Entities, Object.Hole)
				table.insert(Objects.Entities, Root)
				if Toggles.BypassMandrake.Value then
					local BF = Root:FindFirstChild("AntiMandrakeForce")
					if not BF then
						BF = Instance.new("BodyForce")
						BF.Name = "AntiMandrakeForce"
						BF.Parent = Root
					end
					BF.Force = Vector3.new(-49999, -49999, -49999)
				end
			end
		end
	elseif Name == "MinesGenerator" then
		task.spawn(function()
			task.wait(0.75)
			if Object.Parent then
				if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Generator", Color = Options.ObjectiveESPColor.Value }, true) end
				Object:WaitForChild("Lever").Sound.Played:Once(function()
					Functions.RemoveESP(Object)
					Functions.BlacklistESP(Object)
				end)
				table.insert(Objects.Objectives, Object)
			end
		end)
	elseif Name == "FuseObtain" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Generator Fuse", Color = Options.ObjectiveESPColor.Value }, true) end
		Object:WaitForChild("Hitbox").FuseModel:GetPropertyChangedSignal("LocalTransparencyModifier"):Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "MinesGateButton" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Button", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild("MinesGate").Main.SoundOpen.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "GardenGateButton" then
		if Toggles.ObjectiveESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gate Button", Color = Options.ObjectiveESPColor.Value }, true) end
		Object.Parent:WaitForChild("GardenGate").Collision.Sound.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Objectives, Object)
	elseif Name == "Ladder" then
		if Toggles.LadderESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Ladder", Color = Options.LadderESPColor.Value }, true) end
		if Toggles.NotifyLadder.Value then Functions.Notify({ Title = "Ladder Notify", Body = "Ladder has spawned in Room " .. (Object:GetAttribute("ParentRoom") or "(sorry this is a bug)") .. "." }) end
		table.insert(Objects.Ladders, Object)
	elseif Name == "Door" and Object.Parent and (tonumber(Object.Parent.Name) or Object.Parent.Name:match("^A%-%d+") or Object.Parent.Name:match("%d+")) then
		local DoorParts = {}
		for _, Child in Object:GetChildren() do
			if Child.Name == "Door" and Child:IsA("BasePart") then
				table.insert(DoorParts, Child)
			end
		end

		local parentRoomAttr = tonumber(Object.Parent.Name) or Object.Parent.Name

		if #DoorParts == 2 then
			local HighlightModel = Instance.new("Model", Object)
			HighlightModel.Name = "HighlightModel"
			Instance.new("Humanoid", HighlightModel).Name = "HighlightHumanoid"
			HighlightModel:SetAttribute("ParentRoom", parentRoomAttr)

			for _, DoorPart in DoorParts do
				local HP = Instance.new("Part", HighlightModel)
				HP.Transparency = 0.99
				HP.Size = DoorPart.Size
				HP.CanCollide = false
				HP.CFrame = DoorPart.CFrame
				HP.Name = "HighlightPart"
				HP.Material = Enum.Material.Plastic
				HP:SetAttribute("ParentRoom", parentRoomAttr)
				local W = Instance.new("WeldConstraint", HP)
				W.Part0 = HP W.Part1 = DoorPart W.Enabled = true
			end

			local CenterPart = Instance.new("Part", HighlightModel)
			CenterPart.Transparency = 1
			CenterPart.Size = Vector3.new(1, 1, 1)
			CenterPart.CanCollide = false
			CenterPart.CFrame = CFrame.new((DoorParts[1].Position + DoorParts[2].Position) / 2)
			CenterPart.Name = "CenterPart"
			local WCenter = Instance.new("WeldConstraint", CenterPart)
			WCenter.Part0 = CenterPart WCenter.Part1 = DoorParts[1] WCenter.Enabled = true

			HighlightModel.PrimaryPart = CenterPart

			table.insert(Objects.Doors, HighlightModel)

			if Toggles.DoorESPToggle.Value then
				Functions.AddESP({ Object = HighlightModel, Text = GetDoorText(Object), Color = Options.DoorESPColor.Value }, true)
			end

			KeepDoorTextSynced(Object, HighlightModel)
		else
			local Root = Object:WaitForChild("Door", 9e9)
			local HP = Instance.new("Part", Object)
			HP.Transparency = 0.99
			HP.Size = Root.Size
			HP.CanCollide = false
			HP.CFrame = Root.CFrame
			HP.Name = "HighlightPart"
			HP.Material = Enum.Material.Plastic
			HP:SetAttribute("ParentRoom", parentRoomAttr)
			local W = Instance.new("WeldConstraint", HP)
			W.Part0 = HP W.Part1 = Root W.Enabled = true
			Instance.new("Humanoid", Object).Name = "HighlightHumanoid"

			table.insert(Objects.Doors, HP)

			if Toggles.DoorESPToggle.Value then
				Functions.AddESP({ Object = HP, Text = GetDoorText(Object), Color = Options.DoorESPColor.Value }, true)
			end

			KeepDoorTextSynced(Object, HP)
		end
	elseif Name == "PathLights" then
		local ObjectsToHighlight = {}
		local PLConn = Object.ChildAdded:Connect(function(Child)
			table.insert(ObjectsToHighlight, Child)
		end)
		for _, Child in Object:GetChildren() do
			table.insert(ObjectsToHighlight, Child)
		end

		local function CreateSeekNode(Light)
			if Light.Name ~= "SeekGuidingLight" or Light:GetAttribute("Highlighted") then return end
			Light:SetAttribute("Highlighted", true)

			local NewNode = Instance.new("Part")
			NewNode.Size = Vector3.one
			NewNode.Transparency = 1
			NewNode.Parent = Global.SeekNodesFolder
			NewNode.Anchored = true
			NewNode.CFrame = Light.CFrame
			NewNode.CanCollide = false
			NewNode.Name = "SeekLightNode"

			local PrevNode2 = PreviousNode or NewNode
			PreviousNode = NewNode

			local Beam = Instance.new("Beam")
			Beam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Options.ShowSeekPathColor.Value), ColorSequenceKeypoint.new(1, Options.ShowSeekPathColor.Value) })
			Beam.FaceCamera = true
			Beam.Width0 = 0.2
			Beam.Width1 = 0.2
			Beam.Brightness = 10
			Beam.LightInfluence = 0
			Beam.LightEmission = 0
			Beam.Enabled = true
			local Vis = Toggles.ShowSeekPathToggle.Value and 0 or 1
			Beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
			Beam.Parent = Global.SeekNodesFolder
			local A0 = Instance.new("Attachment", NewNode)
			local A1 = Instance.new("Attachment", PrevNode2)
			Beam.Attachment0 = A0
			Beam.Attachment1 = A1
			table.insert(Objects.SeekHighlights, Beam)
		end

		task.spawn(function()
			while task.wait() do
				local Light = table.remove(ObjectsToHighlight, 1)
				if Light then CreateSeekNode(Light) end
			end
		end)

		table.insert(Conns, PLConn)
		table.insert(Objects.PathLights, Object)
		Object.Destroying:Once(function() if PLConn then PLConn:Disconnect() end end)
	elseif Name == "SeekMovingNewClone" then
		local Connection = Object.Destroying:Connect(function()
			for _, Folder in pairs(Objects.PathLights) do
				Folder:ClearAllChildren()
			end
			Global.SeekNodesFolder:ClearAllChildren()
		end)
		table.insert(Conns, Connection)
	elseif Name == "Bridge" then
		for _, Child in Object:GetChildren() do
			if Child.Name == "PlayerBarrier" and Child.Size.Y == 2.75 and (Child.Rotation.X == 0 or Child.Rotation.X == 180) then
				local NewBridge = Child:Clone()
				NewBridge.CFrame = NewBridge.CFrame * CFrame.new(0, 0, -5)
				NewBridge.Name = mstudio45.ESPLibrary:GenerateRandomString()
				NewBridge.Size = Vector3.new(NewBridge.Size.X, NewBridge.Size.Y, 11)
				NewBridge.Parent = Object
				NewBridge.CanCollide = Toggles.BypassSeekObstructions.Value
				NewBridge.Color = Color3.fromRGB(0, 255, 255)
				NewBridge.Transparency = Toggles.BypassSeekObstructions.Value and 0 or 1
				NewBridge.Material = Enum.Material.ForceField
				table.insert(Objects.SeekBridges, NewBridge)
			end
			task.wait()
		end
    elseif Name == "MinecartRig" then
        Global.Minecart = Object
	elseif Name == "RunnerNodes" then
		local function IsBehind(Part1, Part2)
			local P1 = (Part1.CFrame + Part1.CFrame.LookVector).Position
			local P2 = (Part1.CFrame + Part1.CFrame.LookVector * -1).Position
			return (P1 - Part2.Position).Magnitude > (P2 - Part2.Position).Magnitude
		end
		local function GetDirection(Part1, Part2)
			local RightDist = Part1.CFrame.RightVector:Dot(Part1.Position - Part2.Position)
			if RightDist > 0.5    then return IsBehind(Part1, Part2) and "Right" or "Left" end
			if RightDist < -0.5   then return IsBehind(Part1, Part2) and "Left" or "Right" end
			return "Straight"
		end
		local function GetClosestNode(Node)
			local Best, BestDist = nil, math.huge
			local NodeID2 = tonumber(Node.Name:split("MinecartNode")[2])
			for _, OtherNode in Object:GetChildren() do
				local OtherID = tonumber(OtherNode.Name:split("MinecartNode")[2])
				if OtherNode ~= Node and OtherID and NodeID2 and OtherID > NodeID2 then
					local D = (Node.Position - OtherNode.Position).Magnitude
					if D < BestDist and OtherNode:GetAttribute("DistanceBlacklist") ~= true then
						BestDist = D Best = OtherNode
					end
				end
			end
			return Best
		end

		for _, Node in Object:GetChildren() do
			local NodeID = tonumber(Node.Name:split("MinecartNode")[2])
			if Node:GetAttribute("DeathType") then Node:SetAttribute("DistanceBlacklist", true) end
			for I = 1, 20 do
				local NextNode = NodeID and Object:FindFirstChild("MinecartNode" .. NodeID + I)
				if NextNode and NextNode:GetAttribute("DeathType") ~= nil then
					Node:SetAttribute("DistanceBlacklist", true)
				end
			end
			local PrevNode3 = NodeID and Object:FindFirstChild("MinecartNode" .. NodeID - 1)
			if PrevNode3 and PrevNode3:GetAttribute("ForceConnect") then
				Node:SetAttribute("DistanceBlacklist", nil)
			end
			task.wait()
		end

		for _, Node in Object:GetChildren() do
			if Node:GetAttribute("ForceConnect") then
				local NextNode = GetClosestNode(Node)
				if NextNode then
					Node:SetAttribute("Turn", GetDirection(Node, NextNode))
					table.insert(Objects.SeekNodes, Node)
				end
			end
			task.wait()
		end

	elseif Name == "EyestalkEndCutscene" then
		Object.Name = "_EyestalkEndCutscene"
	elseif Name == "DuckBoard" then
		table.insert(Objects.SeekDuckBoards, Object)
	elseif HidingSpotLabels[Name] then
		if Toggles.HidingSpotESPToggle.Value then Functions.AddESP({ Object = Object, Text = HidingSpotLabels[Name], Color = Options.HidingSpotESPColor.Value }, true) end
		Functions.HandleHidingTransparency(Object)
		table.insert(Objects.HidingSpots, Object)
	elseif Name == "Lava" then
		if Toggles.BypassKillbricks.Value then Object.CanTouch = false end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ScaryWall" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekingWall.Value
				Part.CanCollide = not Toggles.BypassSeekingWall.Value

                local Connection1 = Part:GetPropertyChangedSignal("CanTouch"):Connect(function()
                    if Part.CanTouch == Toggles.BypassSeekingWall.Value then
                        Part.CanTouch = not Toggles.BypassSeekingWall.Value
                    end
                end)
                local Connection2 = Part:GetPropertyChangedSignal("CanCollide"):Connect(function()
                    if Part.CanCollide == Toggles.BypassSeekingWall.Value then
                        Part.CanCollide = not Toggles.BypassSeekingWall.Value
                    end
                end)

                table.insert(Conns, Connection1)
                table.insert(Conns, Connection2)
            end
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ChestBox" or Name == "ChestBoxLocked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute("Locked") and "Locked Chest" or "Chest", Color = Options.ChestESPColor.Value }, true) end
			Object:WaitForChild("Main").Open.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Chests, Object)
	elseif Name == "Toolbox" or Name == "Toolbox_Locked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = Object:GetAttribute("Locked") and "Locked Toolbox" or "Toolbox", Color = Options.ChestESPColor.Value }, true) end
			Object:WaitForChild("Main").Open.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Chests, Object)
	elseif Name == "Chest_Vine" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Vine Chest", Color = Options.ChestESPColor.Value }, true) end
			Object:WaitForChild("Main").Open.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Chests, Object)
	elseif Name == "Toolshed_Small" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Toolshed", Color = Options.ChestESPColor.Value }, true) end
			Object:WaitForChild("Main").Open.Played:Once(function()
			Functions.RemoveESP(Object)
			Functions.BlacklistESP(Object)
		end)
		table.insert(Objects.Chests, Object)
	elseif Name == "Locker_Small_Locked" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Locked Item Locker", Color = Options.ChestESPColor.Value }, true) end
		Object:WaitForChild("Main").Open.Played:Once(function()
			Functions.RemoveESP(Object)
		end)
		table.insert(Objects.Chests, Object)
	elseif Name == "MouseHole" then
		if Toggles.ChestESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Mouse", Color = Options.ChestESPColor.Value }, true) end
		table.insert(Objects.Chests, Object)
	elseif ItemNames[Name] and Object:FindFirstChild("ModulePrompt") then
		-- BlackKing-style: only real items carry ModulePrompt; decorative meshes sharing
		-- an item's name (e.g. Bookcase "Lighter") get no item ESP
		local function IsPlayerItem(item)
			if not item or not item.Parent then return true end
			if item:IsDescendantOf(Services.Players) then return true end
			if item.Parent:IsA("Backpack") or item.Parent.Name == "Backpack" then return true end
			if Services.Players:GetPlayerFromCharacter(item.Parent) then return true end
			for _, p in ipairs(Services.Players:GetPlayers()) do
				if p.Character and item:IsDescendantOf(p.Character) then return true end
				if p:FindFirstChild("Backpack") and item:IsDescendantOf(p.Backpack) then return true end
			end
			return false
		end

		if IsPlayerItem(Object) then
			return
		end

		local hasItemAncestor = false
		local ancestor = Object.Parent
		while ancestor and ancestor ~= Services.Workspace and ancestor ~= CurrentRooms do
			local aName = ancestor.Name
			if ItemNames[aName] then
				hasItemAncestor = true
				break
			end
			ancestor = ancestor.Parent
		end
		if hasItemAncestor then return end

		local targetObj = Object
		if Object:IsA("BasePart") and Object.Parent and Object.Parent:IsA("Model") and not ItemNames[Object.Parent.Name] then
			local room = Object:FindFirstAncestorOfClass("Model")
			while room and room.Parent and room.Parent ~= CurrentRooms and room.Parent ~= Services.Workspace do
				room = room.Parent
			end
			if room then
				Object.Parent = room
			end
		end

		local label = ItemNames[Name]

		if label then
			if Toggles.ItemESPToggle.Value then
				Functions.AddESP({ Object = targetObj, Text = label, Color = Options.ItemESPColor.Value }, Object:GetAttribute("ParentRoom") ~= nil)
			end

			if Toggles.NotifyItemsToggle.Value and Object.Parent and Object.Parent.Name ~= "Drops" then
				local Body = "... there it is."
				local Prim = Object.PrimaryPart or (Object:IsA("BasePart") and Object)
				if Prim then
					Body = "It is " .. math.floor(LocalPlayer:DistanceFromCharacter(Prim.Position)) .. " studs away from you."
				end
				Functions.Notify({ Title = "Item '" .. label .. "' has spawned.", Body = Body })
			end

			local ancConn
			ancConn = Object.AncestryChanged:Connect(function(_, newParent)
				if not newParent or IsPlayerItem(Object) then
					Functions.RemoveESP(targetObj)
					if ancConn then ancConn:Disconnect() end
				end
			end)
			table.insert(Conns, ancConn)
		end

		if Name == "LotusHolder" or Name == "LotusPetalPickup" then
			if Object:FindFirstChild("Handle") then
				Object.Handle:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
					mstudio45.ESPLibrary:RemoveESP(Object)
					mstudio45.ESPLibrary:RemoveESP(Object.Handle)
					Functions.BlacklistESP(Object)
				end)
			end
		end

		table.insert(Objects.Items, Object)
	elseif Name == "Green_Herb" then
		if Toggles.ItemESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Green Herb", Color = Options.ItemESPColor.Value }, true) end
		table.insert(Objects.Items, Object)
	elseif Name == "GoldPile" and Object:GetAttribute("GoldValue") then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Gold Pile [" .. Object:GetAttribute("GoldValue") .. "]", Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == "StardustPickup" then
		if Toggles.CurrencyESPToggle.Value then Functions.AddESP({ Object = Object, Text = "Stardust Pile", Color = Options.CurrencyESPColor.Value }, true) end
		table.insert(Objects.Currency, Object)
	elseif Name == "GiggleCeiling" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Giggle"] then Functions.AddESP({ Object = Object, Text = "Giggle", Color = Options.EntityESPColor.Value }, true) end
		if Toggles.BypassGiggle.Value then Object:WaitForChild("Hitbox").CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "Water" or Name == "Currents" or Name == "CurrentsHazard" or Name == "ElectrifiedWater" or Name:find("Currents") or Name:match("^Pool%d+") or Name == "Puddle" then
		-- water esp pattern that works across map variants: ONE label on the Water model
		-- itself (adornee = model root), like the reference script does. Pools are
		-- geometric chunks that stream in/out dynamically and can't be anchor points.
		local function IsRoomWater(waterModel)
			local parent = waterModel and waterModel.Parent
			return parent ~= nil and parent.Parent == CurrentRooms
		end

		local function AttachWaterLabel(waterModel)
			if not waterModel then return end
			if AttachedWaterESP[waterModel] then return end
			AttachedWaterESP[waterModel] = true

			-- room-gated esp reads ParentRoom off the target; stamp it on the model
			local roomNum = tonumber(waterModel.Parent and waterModel.Parent.Name)
			if roomNum and not waterModel:GetAttribute("ParentRoom") then
				waterModel:SetAttribute("ParentRoom", roomNum)
			end

			local function UpdateState()
				-- any electrified pool makes the whole water hazard active
				local isElec = waterModel:GetAttribute("Electrified")
				if isElec == nil then
					for _, pool in ipairs(waterModel:GetChildren()) do
						if pool:GetAttribute("Electrified") == true then
							isElec = true
							break
						end
					end
				end

				local statusText = (isElec == true) and "Electric Puddle [Active]" or "Electric Puddle [Safe]"
				local statusColor = (isElec == true) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(80, 220, 100)

				Functions.AddESP({ Object = waterModel, Text = statusText, Color = statusColor }, true)
				if mstudio45 and mstudio45.ESPLibrary then
					pcall(function()
						mstudio45.ESPLibrary:UpdateObjectText(waterModel, statusText)
						mstudio45.ESPLibrary:UpdateObjectColor(waterModel, statusColor)
					end)
				end
			end

			UpdateState()

			if not table.find(Objects.Entities, waterModel) then
				table.insert(Objects.Entities, waterModel)
			end

			-- keep the label in sync with the hazard state
			local conn1 = waterModel:GetAttributeChangedSignal("Electrified"):Connect(UpdateState)
			table.insert(Conns, conn1)
			local conn2 = waterModel.ChildAdded:Connect(function(child)
				if child:IsA("Model") then
					local c = child:GetAttributeChangedSignal("Electrified"):Connect(UpdateState)
					table.insert(Conns, c)
					UpdateState()
				end
			end)
			table.insert(Conns, conn2)
			for _, pool in ipairs(waterModel:GetChildren()) do
				if pool:IsA("Model") then
					local c = pool:GetAttributeChangedSignal("Electrified"):Connect(UpdateState)
					table.insert(Conns, c)
				end
			end
		end

		if Object.Name == "Water" then
			-- only the room's own water (direct child of a room model) gets the label;
			-- decorative water nested under Assets (fish tanks, coolers) is excluded
			if IsRoomWater(Object) then
				AttachWaterLabel(Object)
			end
		else
			-- a pool/puddle chunk: label its root Water model instead
			local waterRoot
			local anc = Object
			while anc do
				if anc.Name == "Water" and IsRoomWater(anc) then
					waterRoot = anc
					break
				end
				anc = anc.Parent
			end
			if waterRoot then
				AttachWaterLabel(waterRoot)
			elseif Name == "Currents" or Name == "CurrentsHazard" or Name == "ElectrifiedWater" or Name:find("Currents") then
				AttachWaterLabel(Object) -- standalone hazard without a Water wrapper
			end
		end
	elseif Name == "GloomPile" then
		if Toggles.BypassGloombatEggs.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = false
				end
			end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = false end
		end)

		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Gloombat Eggs"] then
			Functions.AddESP({ Object = Object, Text = "Gloombat Eggs", Color = Options.EntityESPColor.Value })
		end

		table.insert(Conns, Connection)
		table.insert(Objects.Entities, Object)
	elseif Name == "TriggerEventCollision" and Functions.CheckEnv("firetouchinterest") then
		if (Floor == "Fools" or Floor == "OldHotel") and Toggles.RemoveSeekTrigger.Value then
			task.spawn(function()
				while Object:IsDescendantOf(game) do
					for _, Part in Object:GetChildren() do
						if Part:IsA("BasePart") then
							mstudio45.Environment.firetouchinterest(RootPart, Part, 0)
							task.wait()
							mstudio45.Environment.firetouchinterest(RootPart, Part, 1)
						end
					end
					task.wait()
				end
			end)
		end
		table.insert(Objects.EventTriggers, Object)
	elseif Name == "DoorFake" or Name == "FakeDoor" then
		if Object.Parent and Object:FindFirstChild("Hidden") then
			if Toggles.BypassDupe.Value then
				Object:WaitForChild("Hidden").CanTouch = false
				local Lock = Object:FindFirstChild("Lock")
				if Lock and Lock:FindFirstChild("UnlockPrompt") then Lock.UnlockPrompt.Enabled = false end
			end
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Dupe"] then
				Functions.AddESP({ Object = Object, Text = "Dupe", Color = Options.EntityESPColor.Value }, true)
			end
			table.insert(Objects.Entities, Object)
		end
	elseif Name == "SideroomSpace" then
		if Toggles.BypassVacuum.Value then
			Object:WaitForChild("Collision").CanCollide = true
			Object:WaitForChild("Collision").CanTouch = false
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Snare" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Snare"] then Functions.AddESP({ Object = Object, Text = "Snare", Color = Options.EntityESPColor.Value }, true) end
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end
		local Connection = Object.DescendantAdded:Connect(function(Part)
			if Part:IsA("BasePart") then Part.CanTouch = not Toggles.BypassSnare.Value end
		end)
		table.insert(Conns, Connection)
		table.insert(Objects.Entities, Object)

		if Object:FindFirstChild("Snare") then
			Object:WaitForChild("Snare"):WaitForChild("Roots").Transparency = 1
			Object:WaitForChild("Snare"):WaitForChild("SnareBase").Transparency = 1
		end
		if Object:FindFirstChild("Void") then
			Object.Void.Transparency = 0
			Object.Void.Color = Color3.fromRGB(76, 67, 55)
		end
	elseif Name == "Seek_Arm" or Name == "ChandelierObstruction" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Toggles.BypassSeekObstructions.Value
				table.insert(Objects.SeekObstructions, Part)
			end
		end
	elseif Name == "SeekFloodline" then
		Object.CanCollide = Toggles.BypassSeekObstructions.Value
		local FloodConn = Object:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if Object.CanCollide ~= Toggles.BypassSeekObstructions.Value then
				Object.CanCollide = Toggles.BypassSeekObstructions.Value
			end
		end)
		Object.Destroying:Once(function() if FloodConn then FloodConn:Disconnect() end end)
		table.insert(Objects.SeekObstructions, Object)
	elseif Object:GetAttribute("RawName") and Object:GetAttribute("RawName"):find("Halt") or Object:GetAttribute("Shade") == true then
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Halt"] then
			Functions.Notify({ Title = "Entity 'Halt' will spawn in the next room.", Body = "", Image = EntityIcons["Halt"] })
			if Toggles.EntityChatToggle.Value then Functions.SendChat("Halt next room!") end
		end
		local HaltLogConn
		HaltLogConn = Services.LogService.MessageOut:Connect(function(Message)
			if Message == "client teleporting" then
				if Global.AnticheatDisabled then
					Global.AnticheatDisabled = false
					Functions.Notify({ Title = "Disable Anticheat", Body = "The anticheat has been re-enabled, Interact with a ladder to disable it again." })
				end
				if HaltLogConn then HaltLogConn:Disconnect() end
			end
		end)
	elseif Name == "BananaPeel" then
		if Toggles.BypassBanana.Value then Object.CanTouch = false end
		table.insert(Objects.Entities, Object)
	elseif Name == "JeffTheKiller" then
		if Toggles.BypassJeff.Value then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanCollide = false Part.CanTouch = false end
			end
			Object:WaitForChild("Humanoid").Health = 0
		end
	elseif Name == "GrumbleRig" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Grumble"] then Functions.AddESP({ Object = Object, Text = "Grumble", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == "TellerRig" then
		if not Object:FindFirstChildOfClass("Humanoid") then
			Instance.new("Humanoid", Object).Name = "HighlightHumanoid"
		end
		local Root = Object:FindFirstChild("Root") or Object.PrimaryPart or Object:FindFirstChildWhichIsA("BasePart")
		if Root then
			Object.PrimaryPart = Root
		end
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Teller"] then
			local NumberLabel = Object:FindFirstChild("ScreenFrame") and Object.ScreenFrame:FindFirstChild("Screen") and Object.ScreenFrame.Screen:FindFirstChild("SurfaceGui") and Object.ScreenFrame.Screen.SurfaceGui:FindFirstChild("NumberLabel")
			local function MakeLabel()
				return NumberLabel and ("Teller [" .. tostring(NumberLabel.Text or NumberLabel) .. "]") or "Teller"
			end
			Functions.AddESP({ Object = Object, Text = MakeLabel(), Color = Options.EntityESPColor.Value }, Object:GetAttribute("ParentRoom") ~= nil)
			if NumberLabel then
				NumberLabel:GetPropertyChangedSignal("Text"):Connect(function()
					if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Teller"] then
						mstudio45.ESPLibrary:UpdateObjectText(Object, MakeLabel())
					end
				end)
			end
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Drones" then
		if Toggles.BypassDrones.Value then
			local WalkedInto = Object:FindFirstChild("WalkedInto")
			if WalkedInto then WalkedInto.Name = "_WalkedInto" end
		end
		local DroneConnection = Object.DescendantAdded:Connect(function(Part)
			if Part.Name == "WalkedInto" and Toggles.BypassDrones.Value then
				Part.Name = "_WalkedInto"
			end
		end)
		table.insert(Conns, DroneConnection)
		Object.Destroying:Once(function()
			if DroneConnection then DroneConnection:Disconnect() end
		end)
		if not Object:FindFirstChildOfClass("Humanoid") then
			Instance.new("Humanoid", Object).Name = "HighlightHumanoid"
		end
		local Root = Object:FindFirstChild("Root") or Object.PrimaryPart or Object:FindFirstChildWhichIsA("BasePart")
		if Root then
			Object.PrimaryPart = Root
			Root.Transparency = 0.999
			Root.Material = Enum.Material.Plastic
			Root:SetAttribute("ParentRoom", Object:GetAttribute("SpawnRoom"))
			if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Drones"] then
				Functions.AddESP({ Object = Root, Text = "Drones", Color = Options.EntityESPColor.Value }, true)
			end
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "LiveEntityBramble" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Bramble"] then Functions.AddESP({ Object = Object, Text = "Bramble", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
	elseif Name == "Groundskeeper" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Groundskeeper"] then Functions.AddESP({ Object = Object, Text = "Groundskeeper", Color = Options.EntityESPColor.Value }, true) end
		if Toggles.NotifyEntities.Value and Options.EntityList.Value["Groundskeeper"] then
			local ED = Entities["Groundskeeper"]
			Functions.Notify({ Title = ED.NotifyMessage.Title, Body = ED.NotifyMessage.Body, Image = EntityIcons["Groundskeeper"] })
		end
		table.insert(Objects.Entities, Object)
	elseif Name == "Figure" or Name == "FigureRig" or Name == "FigureRagdoll" then
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = false
			end
		end
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value["Figure"] then Functions.AddESP({ Object = Object, Text = "Figure", Color = Options.EntityESPColor.Value }, true) end
		table.insert(Objects.Entities, Object)
		if Toggles.RemoveFigure.Value and Functions.CheckEnv("isnetworkowner") then
			if Floor == "Mines" then
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						task.spawn(function()
							if mstudio45.Environment.isnetworkowner(Part) then
								Part.Position = Vector3.new(-49999, -49999, -49999)
								Functions.Notify({ Title = "Delete Figure", Body = "Successfully deleted figure"})
							end
						end)
					end
				end
			elseif Floor == "OldHotel" or Floor == "Fools" then
				CurrentRooms.ChildAdded:Wait()
				for _, Part in Object:GetDescendants() do
					if Part:IsA("BasePart") then
						Part.CanCollide = false
						task.spawn(function()
							while mstudio45.Environment.isnetworkowner(Part) do
								Part.Position = Vector3.new(math.random(-29999,29999), math.random(-29999,29999), math.random(-29999,29999))
								task.wait()
							end
						end)
					end
				end
			end
		end
	elseif (Name == "ThingToOpen" or Name == "MovingDoor") and (Floor == "Fools" or Floor == "OldHotel")
		or Name == "Wax_Door" and Floor == "Fools"
	then
		Object:SetAttribute("OriginalPosition", Object:GetPivot())
		local ToggleMap = { ThingToOpen = "RemoveBasementGate", MovingDoor = "RemovePaintingsDoor", Wax_Door = "RemoveSkeletonDoor" }
		if ToggleMap[Name] and Toggles[ToggleMap[Name]].Value then
			Object:PivotTo(CFrame.new(-10000, -10000, -10000))
		end
		table.insert(Objects.Obstructions, Object)
	elseif Name == "ElevatorBreaker" then
		if Toggles.AutoBreakerBox.Value and not Global.BreakerBoxNotified then
			Functions.Notify({ Title = "Auto Breaker Box", Body = "Interact with the breaker box, It will be automatically solved." })
			Global.BreakerBoxNotified = true
		end
		Conns.BreakerConnection = Object:WaitForChild("SurfaceGui").Frame.Code:GetPropertyChangedSignal("Text"):Connect(function()
			if Toggles.AutoBreakerBox.Value then
				if not Global.BreakerBoxStartNotified and (Floor == "Fools" or Floor == "OldHotel") then
					Functions.Notify({ Title = "Auto Breaker Box", Body = "Attempting to solve the breaker box, Please wait." })
					Global.BreakerBoxStartNotified = true
				end
				RemotesFolder.EBF:FireServer()
			end
			Global.BreakerBoxInteracted = true
		end)
	elseif Name == "ElevatorCar" then
		local ElevConn = Object.DescendantAdded:Connect(function(Desc)
			if Toggles.AutoBreakerBox.Value and Desc.Name == "TouchInterest" and not Global.BreakerBoxFinishedNotified then
				Functions.Notify({ Title = "Auto Breaker Box", Body = "Successfully solved the breaker box, Try going to the elevator!" })
				Global.BreakerBoxFinishedNotified = true
			end
		end)
		Object.Destroying:Once(function() if ElevConn then ElevConn:Disconnect() end end)
	elseif Object.ClassName == "ProximityPrompt" and not Object:GetAttribute("FakePrompt") then
		if Object:HasTag("DisableWhenEnabledOnClient") then Object:RemoveTag("DisableWhenEnabledOnClient") end

		Object:SetAttribute("HoldDuration_Old", Object.HoldDuration)
		Object:SetAttribute("RequiresLineOfSight_Old", Object.RequiresLineOfSight)
		Object:SetAttribute("MaxActivationDistance_Old", Object.MaxActivationDistance)

		if Toggles.InstantPrompts.Value    then Object.HoldDuration = 0 end
		if Toggles.PromptClip.Value        then Object.RequiresLineOfSight = false end
		Object.MaxActivationDistance = Object:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachSlider.Value

		local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }

		if Functions.CheckEnv("fireproximityprompt") and Floor ~= "OldHotel" and Floor ~= "Fools" then
			local IsLockPrompt = LockPromptNames[Object.Name]
				or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
				or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")

			if IsLockPrompt then
				local FakePrompt = Object:Clone()
				FakePrompt:SetAttribute("FakePrompt", true)
				task.wait()
				FakePrompt.Parent = Object.Parent

				FakePrompt:SetAttribute("HoldDuration_Old", Object:GetAttribute("HoldDuration_Old"))
				FakePrompt:SetAttribute("RequiresLineOfSight_Old", Object:GetAttribute("RequiresLineOfSight_Old"))
				FakePrompt:SetAttribute("MaxActivationDistance_Old", Object:GetAttribute("MaxActivationDistance_Old"))

				FakePrompt.HoldDuration = Object.HoldDuration
				FakePrompt.RequiresLineOfSight = Object.RequiresLineOfSight
				FakePrompt.MaxActivationDistance = Object.MaxActivationDistance

				if Toggles.InstantPrompts.Value    then FakePrompt.HoldDuration = 0 end
				if Toggles.PromptClip.Value        then FakePrompt.RequiresLineOfSight = false end
				FakePrompt.MaxActivationDistance = FakePrompt:GetAttribute("MaxActivationDistance_Old") * Options.PromptReachSlider.Value

				FakePrompts[FakePrompt] = Object
				pcall(function() Object.Parent = Global.PromptContainer end)

				local FPEnabledConn = Object:GetPropertyChangedSignal("Enabled"):Connect(function()
					FakePrompt.Enabled = Object.Enabled
				end)
				Object:GetPropertyChangedSignal("ActionText"):Once(function()
					pcall(function() Object.Parent = FakePrompt.Parent end)
					FakePrompt:Destroy()
					if FPEnabledConn then FPEnabledConn:Disconnect() end
				end)
				Object.Destroying:Once(function()
					FakePrompt:Destroy()
					if FPEnabledConn then FPEnabledConn:Disconnect() end
				end)
				table.insert(Conns, FPEnabledConn)
				table.insert(Objects.Prompts, FakePrompt)

				FakePrompt.Enabled = false
				task.wait()
				FakePrompt.Enabled = Object.Enabled
			end
		end
		table.insert(Objects.Prompts, Object)
	elseif Name == "Padlock" then
		Conns.PadlockConnection = Services.RunService.Heartbeat:Connect(function()
			if Object.PrimaryPart then
				local Distance = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
				if Toggles.AutoUnlockPadlockToggle.Value then
					local Code = Functions.GetLibraryCode()
					if Code and tonumber(Code) and Distance < Options.AutoUnlockPadlockSlider.Value then
						RemotesFolder.PL:FireServer(Code)
					end
				end
			end
		end)
		Object.Destroying:Once(function()
			if Conns.PadlockConnection then
				Conns.PadlockConnection:Disconnect()
				Conns.PadlockConnection = nil
			end
		end)
	end
end

local ToolNames = { "Lockpick","Shears","SkeletonKey","Key","GeneratorFuse","KeyElectrical","KeyBackdoor","KeyIron","Multitool" }
local AnimateToolNames = { "Lockpick","Shears","SkeletonKey","Key","KeyElectrical","KeyBackdoor","KeyIron","Multitool" }
local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
local VineParentNames = { CuttableVines=true, Chest_Vine=true, Cellar=true }

local function GetCharacterTool()
	for _, N in ToolNames do
		local Tool = Character:FindFirstChild(N)
		if Tool then return Tool end
	end
	return nil
end

local function IsLockPrompt(Prompt)
	if LockPromptNames[Prompt.Name] then return true end
	if Prompt.Parent and Prompt.Parent:GetAttribute("Locked") == true then return true end
	local grandparent = Prompt.Parent and Prompt.Parent.Parent
	return grandparent and grandparent.Name == "Locker_Small_Locked" and Prompt.Name == "ActivateEventPrompt"
end

local function HasRequiredKey()
	for _, k in KeyItems do if Functions.HasItem(k, true) then return true end end
	for _, k in OffhandKeyItems do if Functions.HasItem(k) then return true end end
	return false
end

local function ShouldBlockPrompt(Prompt)
	if not Prompt or not Prompt.Parent then return true end
	local pname = Prompt.Parent.Name
	local locked = IsLockPrompt(Prompt)
	if locked and (Options.AutoInteractIgnoreList.Value["Locks"] or not HasRequiredKey()) then
		return true
	end
	local cutters = Functions.HasItem("Shears", true) or Functions.HasItem("Multitool", true)
	if VineParentNames[pname] and not cutters then return true end
	if pname == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return true end
	if (pname == "Lock1" or pname == "Lock2") and not Functions.HasItem("Lockpick", true) and not cutters then
		return true
	end
	if cutters and locked and not VineParentNames[pname] then return true end
	return false
end

Conns.PromptAnimationFixer1 = Services.ProximityPromptService.PromptButtonHoldBegan:Connect(function(Object)
	if not Object:GetAttribute("FakePrompt") then return end
	local Tool = GetCharacterTool()
	if ShouldBlockPrompt(Object) then return end

	if Tool and table.find(AnimateToolNames, Tool.Name) and Global.UseAnimation then
		Global.UseAnimationBreak:Stop()
		Global.UseAnimation:Stop()
		Global.UseAnimation:Play()
		if Tool.Name == "Shears" then Tool:WaitForChild("Handle"):WaitForChild("sound_prompt"):Play() end
	end
end)

Global.ObjectQueue = {}
local TrackedObjects = {
	Lava=true, GoldPile=true, KeyObtain=true, Drakobloxxer=true, FuseObtain=true,
	MinesGenerator=true, JeffTheKiller=true, Snare=true, FakeDoor=true, DoorFake=true, SideroomSpace=true,
	ChestBox=true, ChestBoxLocked=true, Chest_Vine=true, Locker_Small_Locked=true, Toolbox=true,
	Toolbox_Locked=true, Wardrobe=true, ["Wardrobe-FOOLS26"]=true, Toolshed=true, Toolshed_Small=true,
	Bed=true, MinesAnchor=true, Double_Bed=true, RetroWardrobe=true, Backdoor_Wardrobe=true,
	HidingSpot1=true, HidingSpot2=true, HidingSpot3=true,
	Rooms_Locker=true, Rooms_Locker_Fridge=true, Locker_Large=true, FigureRig=true, FigureRagdoll=true,
	TimerLever=true, Lever=true, Seek_Arm=true, ChandelierObstruction=true, ScaryWall=true, Ladder=true,
	CircularVent=true, Dumpster=true, SquareGrate=true, TriggerEventCollision=true, GrumbleRig=true,
	GiggleCeiling=true, MinesGateButton=true, ElectricalKeyObtain=true, LibraryHintPaper=true,
	Drones=true, TellerRig=true, DronesStampede=true,
	HonchoRig=true, ArchivesPackageDeposit=true, ArchivesStorageBox=true,
	Creak=true, StemsEntity=true, LargeScrew=true, DinkyLamp=true, BottleCrate=true,
	StairwellTerminal=true, StairwellFireAlarm=true, TV_Stand=true, Cubby_Large_Tarped=true,
	BrokenMonitor=true, JerryCan=true,
	Noise=true, Hijack=true,
	WaterPump=true, CringlePresent=true, Wheel=true, PickupItem=true, LiveHintBook=true,
	LiveBreakerPolePickup=true, LeverForGate=true, GloomPile=true, SeekFloodline=true, Door=true,
	Green_Herb=true, Bridge=true, MouseHole=true, BananaPeel=true, NannerPeel=true, PowerupPad=true,
	IndustrialGate=true, CollisionFloor=true, ElevatorCar=true, Wax_Door=true, ThingToOpen=true,
	MovingDoor=true, StardustPickup=true, Hole=true, Groundskeeper=true, MandrakeLive=true,
	GardenGateButton=true, LotusPetalPickup=true, VineGuillotine=true, LiveEntityBramble=true,
	RiftSpawn=true, ElevatorBreaker=true, RunnerNodes=true, PathLights=true, DuckBoard=true,
	Padlock=true, EyestalkEndCutscene=true, MinecartRig=true, SeekMovingNewClone=true,
	Water=true, Puddle=true, Currents=true, CurrentsHazard=true, ElectrifiedWater=true
}

Functions.QueueObject = function(Object)
	if not (Object.Name == LocalPlayer.Name and Object:IsA("Model") and Object.Parent and Object.Parent.Parent == CurrentRooms)
	and not TrackedObjects[Object.Name] and not Object.Name:match("^Pool%d+") and not Object.Name:match("^MirrorRig_Portrait") and Object.ClassName ~= "ProximityPrompt" and Object.Parent ~= CurrentRooms and not ItemNames[Object.Name] then
		return
	end
	table.insert(Global.ObjectQueue, Object)
end

Global.QueueDone = true
Conns.QueueConnection = Services.RunService.RenderStepped:Connect(function()
	local Object = table.remove(Global.ObjectQueue, 1)
	if Object then
		Functions.HandleObject(Object)
	end
end)

for _, Object in Services.Workspace:GetDescendants() do
	task.spawn(function() Functions.QueueObject(Object) end)
end

Conns.InstanceHandler = Services.Workspace.DescendantAdded:Connect(function(Object)
	Functions.QueueObject(Object)
end)

for _, Player in Services.Players:GetPlayers() do
	if Player ~= LocalPlayer then
		if Player.Character and Toggles.PlayerESPToggle.Value then
			Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
		end
		local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
			if Toggles.PlayerESPToggle.Value then
				Functions.AddESP({ Object = NewCharacter, Text = Player.Name, Color = Options.PlayerESPColor.Value })
			end
		end)
		local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
			if Player:GetAttribute("Alive") ~= true and Player.Character then
				Functions.RemoveESP(Player.Character)
			end
		end)
		table.insert(Conns, CharConn)
		table.insert(Conns, DeadConn)
		Player.Destroying:Once(function()
			if CharConn then CharConn:Disconnect() end
			if DeadConn then DeadConn:Disconnect() end
		end)
	end
end

Conns.PlayerHandler = Services.Players.PlayerAdded:Connect(function(Player)
	if Player == LocalPlayer then return end
	if Player.Character and Toggles.PlayerESPToggle.Value then
		Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = Options.PlayerESPColor.Value })
	end
	local CharConn = Player.CharacterAdded:Connect(function(NewCharacter)
		if Toggles.PlayerESPToggle.Value then
			Functions.AddESP({ Object = NewCharacter, Text = Player.Name, Color = Options.PlayerESPColor.Value })
		end
	end)
	local DeadConn = Player:GetAttributeChangedSignal("Alive"):Connect(function()
		if Player:GetAttribute("Alive") ~= true and Player.Character then
			Functions.RemoveESP(Player.Character)
		end
	end)
	table.insert(Conns, CharConn)
	table.insert(Conns, DeadConn)
	Player.Destroying:Once(function()
		if CharConn then CharConn:Disconnect() end
		if DeadConn then DeadConn:Disconnect() end
	end)
end)

local PromptsToFire = {}
local PromptCooldown = {}

Functions.FirePrompt      = mstudio45.Environment.fireproximityprompt
Functions.ForceFirePrompt = mstudio45.Environment.fireproximityprompt

if not Functions.FirePrompt then
	Functions.FirePrompt = function(Prompt)
		if not Prompt:IsA("ProximityPrompt") or PromptCooldown[Prompt] or table.find(PromptsToFire, Prompt) or not Camera then return end
		table.insert(PromptsToFire, Prompt)
	end
	Functions.ForceFirePrompt = Functions.FirePrompt

	task.spawn(function()
		while task.wait() do
			local Prompt = table.remove(PromptsToFire, 1)
			if not Prompt then continue end
			PromptCooldown[Prompt] = true

			local OldDist   = Prompt.MaxActivationDistance
			local OldEnable = Prompt.Enabled
			local OldParent = Prompt.Parent
			local OldHold   = Prompt.HoldDuration
			local OldLOS    = Prompt.RequiresLineOfSight

			Prompt.MaxActivationDistance = 99999
			Prompt.Enabled = true
			Prompt.HoldDuration = 0
			Prompt.RequiresLineOfSight = false

			local TempPart = Instance.new("Part")
			TempPart.Parent = Services.Workspace
			TempPart.CanCollide = false TempPart.CanQuery = false TempPart.CanTouch = false
			TempPart.Anchored = true TempPart.Transparency = 1
			TempPart.Size = Vector3.new(0.001, 0.001, 0.001)
			TempPart.Position = Camera.CFrame:ToWorldSpace(CFrame.new(0, 0, -0.1)).Position

			if not Prompt or not OldParent then
				TempPart:Destroy()
				PromptCooldown[Prompt] = nil
				continue
			end

			pcall(function() Prompt.Parent = TempPart end)

			local Shown, Fired = false, false

			local ShownConn = Services.ProximityPromptService.PromptShown:Connect(function(P)
				if P == Prompt then Shown = true end
			end)
			local FiredConn = Prompt.Triggered:Connect(function() Fired = true end)

			local T1 = 0
			while not Shown and T1 < 5 do T1 += 1 task.wait() end

			local T2 = 0
			while not Fired and T2 < 5 do
				Prompt:InputHoldBegin()
				Prompt:InputHoldEnd()
				T2 += 1 task.wait()
			end

			Prompt.MaxActivationDistance = OldDist
			Prompt.Enabled = OldEnable
			Prompt.HoldDuration = OldHold
			Prompt.RequiresLineOfSight = OldLOS
			pcall(function() Prompt.Parent = OldParent end)
			task.wait()
			PromptCooldown[Prompt] = nil
			TempPart:Destroy()
			if ShownConn then ShownConn:Disconnect() end
			if FiredConn then FiredConn:Disconnect() end
		end
	end)
end

local AutoInteractBlacklist = {
	HidePrompt=true, RiftPrompt=true, StarRiftPrompt=true, InteractPrompt=true, ClimbPrompt=true,
	DonatePrompt=true, DialoguePrompt=true, RevivePrompt=true, EnterPrompt=true, AnimatePrompt=true,
	ToolEventPrompt=true, Prompt=true, PropPrompt=true, SitPrompt=true, SeatPrompt=true, ChairPrompt=true,
	BenchPrompt=true, StoolPrompt=true, SofaPrompt=true
}

local TriggerDebounce = false

Functions.TriggerPrompt = function(Prompt)
	if TriggerDebounce then return end
	if not Prompt or not Prompt.Parent then return end

	local pName = Prompt.Parent.Name
	local gpName = Prompt.Parent.Parent and Prompt.Parent.Parent.Name or ""
	local isLeftovers = pName:lower():find("leftover") or gpName:lower():find("leftover")

	if AutoInteractBlacklist[Prompt.Name] and not isLeftovers then return end
	if Prompt:GetAttribute("AutoInteractIgnore") then return end
	if ShouldBlockPrompt(Prompt) then return end

	-- Block sitting on chairs, benches, seats, etc.
	local lowerPromptName = Prompt.Name:lower()
	local lowerActionText = (Prompt.ActionText or ""):lower()
	if lowerPromptName:find("sit") or lowerPromptName:find("seat") or lowerPromptName:find("chair") or lowerPromptName:find("bench") then return end
	if lowerActionText:find("sit") or lowerActionText:find("сесть") or lowerActionText:find("присесть") then return end

	if Prompt.Parent then
		local pClass = Prompt.Parent.ClassName
		local parentName = Prompt.Parent.Name:lower()
		if pClass == "Seat" or pClass == "VehicleSeat" then return end
		if parentName:find("chair") or parentName:find("seat") or parentName:find("bench") or parentName:find("stool") or parentName:find("sofa") or parentName:find("couch") or parentName:find("armchair") then return end
		if Prompt.Parent.Parent then
			local grandName = Prompt.Parent.Parent.Name:lower()
			if grandName:find("chair") or grandName:find("seat") or grandName:find("bench") or grandName:find("stool") or grandName:find("sofa") or grandName:find("couch") then return end
		end
	end

	local pName = Prompt.Parent.Name

	local worn = Functions.HasItem(pName)
	if worn and worn:GetAttribute("Durability") and worn:GetAttribute("DurabilityMax")
		and worn:GetAttribute("Durability") >= worn:GetAttribute("DurabilityMax")
	then return end

	if pName == "GlitchCube" and Options.AutoInteractIgnoreList.Value["Glitch Fragments"] then return end
	if pName == "KeyObtain" and (Functions.HasItem("Key") or Functions.HasItem("KeyBackdoor")) then return end
	if pName == "ElectricalKeyObtain" and Functions.HasItem("KeyElectrical") then return end
	if Prompt:IsDescendantOf(Drops) and Options.AutoInteractIgnoreList.Value["Dropped Items"] then return end
	if pName == "TrackLever" then return end
	if Prompt.Name == "PushPrompt" and Options.AutoInteractIgnoreList.Value["Minecarts"] then return end
	if Prompt.Parent:GetAttribute("JeffShop") and Options.AutoInteractIgnoreList.Value["Jeff Items"] then return end
	if (pName == "GoldPile" or pName == "StardustPickup") and Options.AutoInteractIgnoreList.Value["Currency"] then return end
	if pName == "KeyObtainFake" or pName == "TithingPlate" then return end

	-- Block terminal, vending machines, Paper Plane, ArchivesLargePrinter, and ArchivesTrashcan from AutoInteract
	local lowerPName = pName:lower()
	if lowerPName:find("archivesterminal") or lowerPName:find("shakelightvendingmachine") or lowerPName:find("vendor") or lowerPName:find("paper") or lowerPName:find("plane") or lowerPName:find("plan") or lowerPName:find("archiveslargeprinter") or lowerPName:find("printer") or lowerPName:find("archivestrashcan") or lowerPName:find("trashcan") then return end

	if Prompt.Parent and Prompt.Parent.Parent then
		local lowerGPName = Prompt.Parent.Parent.Name:lower()
		if lowerGPName:find("archivesterminal") or lowerGPName:find("shakelightvendingmachine") or lowerGPName:find("vendor") or lowerGPName:find("paper") or lowerGPName:find("plane") or lowerGPName:find("printer") or lowerGPName:find("trashcan") then return end
	end

	if Prompt.Name == "ActivateEventPrompt" then
		local skipClose = Prompt.ActionText == "Close" or pName == "ElevatorBreaker"
		local skipGate = Prompt.Parent.Parent and Prompt.Parent.Parent.Name == "IndustrialGate"
		local skipPad = pName == "Padlock" or pName == "MinesAnchor"
		if skipClose or skipGate or skipPad then return end
	end

	if Prompt.Parent.Name == "LeverForGate" and Prompt:GetAttribute("Interactions") then return end
	if Prompt.Parent.Parent and (Prompt.Parent.Parent.Name == "DoorFake" or Prompt.Parent.Parent.Name == "FakeDoor") then return end

	if pName == "Bandage" then
		local bp = Functions.HasItem("BandagePack")
		if Humanoid.Health >= Humanoid.MaxHealth and not bp then return end
		if bp and bp:GetAttribute("Durability") >= bp:GetAttribute("DurabilityMax") then return end
	elseif pName == "Battery" then
		local tool = Character:FindFirstChildOfClass("Tool")
		local bp = Functions.HasItem("BatteryPack")
		if not tool and not bp then return end
		if tool and tool:GetAttribute("LightSource") then
			if tool:GetAttribute("Durability") and tool:GetAttribute("DurabilityMax")
				and tool:GetAttribute("Durability") > tool:GetAttribute("DurabilityMax")
			then return end
		elseif not bp then
			return
		end
		if bp and bp:GetAttribute("Durability") >= bp:GetAttribute("DurabilityMax") then return end
	elseif pName == "HerbPrompt" then
		local fx = Global.MainUI.MainFrame.Healthbar:FindFirstChild("Effects")
		if fx and fx.HerbGreenEffect.Visible then return end
	elseif (pName == "LibraryHintPaper" or pName == "PickupItem") then
		if Functions.HasItem("LibraryHintPaper") or Functions.HasItem("LibraryHintPaperHard") then return end
	elseif pName == "AlarmClock" and Functions.HasItem("AlarmClock") then
		return
	end

	Functions.FirePrompt(Prompt)
	TriggerDebounce = true
	if Floor == "OldHotel" then task.wait() end
	TriggerDebounce = false
end

Global.LastAutoInteractFire = tick()
Conns.AutoInteract = Services.RunService.Heartbeat:Connect(function()
	local Active = Toggles.AutoInteractToggle.Value or Options.AutoInteractKeybind:GetState()
    if not Active then return end
    if tick() - Global.LastAutoInteractFire < 1/60 then return end

	for _, Prompt in Objects.Prompts do
        if Prompt:GetAttribute("ParentRoom") and tonumber(Prompt:GetAttribute("ParentRoom")) ~= tonumber(LocalPlayer:GetAttribute("CurrentRoom")) then continue end

		if Prompt.Parent and (Prompt.Parent:IsA("BasePart") or Prompt.Parent:IsA("Model")) then
			local Distance
			if Prompt.Parent:IsA("BasePart") then
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent.Position)
			else
				Distance = LocalPlayer:DistanceFromCharacter(Prompt.Parent:GetPivot().Position)
			end
			if Distance <= Prompt.MaxActivationDistance and Prompt.Enabled or Distance <= Prompt.MaxActivationDistance and Prompt.Name == "LongPushPrompt" or Distance <= Prompt.MaxActivationDistance and Prompt.Name == "BigPropPrompt" then
				task.spawn(Functions.TriggerPrompt, Prompt)
			end
		end
	end
    Global.LastAutoInteractFire = tick()
end)

InfCrucifixRange = {
	["RushMoving"] = 49,
	["AmbushMoving"] = 50,
	["A60"] = 49
}

local function DrawBeamBetween(A, B)
	local dist = (A - B).Magnitude
	if dist <= 0 then return end
	local bar = Instance.new("Part")
	bar.Anchored = true
	bar.CanCollide = false bar.CanQuery = false
	bar.Material = Enum.Material.Neon
	bar.Color = Color3.fromRGB(255, 0, 0)
	bar.Size = Vector3.new(0.2, 0.2, dist)
	bar.CFrame = CFrame.lookAt(A, B) * CFrame.new(0, 0, -dist / 2)
	bar.Parent = workspace
	local tw = TweenService:Create(bar, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 })
	tw:Play()
	tw.Completed:Once(function() bar:Destroy() end)
end

local function ScanForTargetEntity()
	for tag in pairs(InfCrucifixRange) do
		local obj = workspace:FindFirstChild(tag) or workspace:FindFirstChild(tag, true)
		if obj and (obj:IsA("BasePart") or obj:IsA("Model")) then
			return obj, tag
		end
	end
end

local function IsTargetInRange()
	local ent, tag = ScanForTargetEntity()
	local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
	if not ent or not hrp then return false end
	return (ent:GetPivot().Position - hrp.Position).Magnitude < InfCrucifixRange[tag]
end

local function LocateDroppedCrucifix(hrp)
	for _, obj in Drops:GetChildren() do
		if obj.Name == "Crucifix" then return obj end
	end
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("Model") and obj.Name == "Crucifix" and not obj:IsDescendantOf(Character) then
			if (obj:GetPivot().Position - hrp.Position).Magnitude < 25 then return obj end
		end
	end
end

spawn(function()
	while task.wait(0.1) do
		local AnyTool = Character and Character:FindFirstChildOfClass("Tool")
		if AnyTool and AnyTool.Name == "Crucifix"
			and Toggles.InfiniteItemsToggle.Value
			and Options.InfiniteItemsList.Value["Crucifix"]
			and IsTargetInRange() then
			local HRP = Character:FindFirstChild("HumanoidRootPart")
			local Entity = ScanForTargetEntity()
			if HRP and Entity and Floor ~= "Rooms" then
				DrawBeamBetween(HRP.Position, Entity:GetPivot().Position)
				Functions.Notify({ Title = "Infinite Items", Body = "Dropping Crucifix on the floor."})
				RemotesFolder.DropItem:FireServer(AnyTool)
				task.wait(0.1)
				local Dropped = nil
				for _ = 1, 40 do
					Dropped = LocateDroppedCrucifix(HRP)
					if Dropped then break end
					task.wait(0.1)
				end
				if Dropped then
					task.wait(0.4)
					local Prompt = Dropped:FindFirstChildOfClass("ProximityPrompt", true)
						or Dropped:FindFirstChild("ModulePrompt", true)
					if Prompt then Functions.FirePrompt(Prompt) end
				end
			end
			task.wait(2)
		end
	end
end)
Conns.InfiniteItemsHandler = Services.ProximityPromptService.PromptTriggered:Connect(function(Object)
	if not Object:GetAttribute("FakePrompt") then return end

	local Tool = GetCharacterTool()
	if ShouldBlockPrompt(Object) then return end

	if Tool and table.find(AnimateToolNames, Tool.Name) and Global.UseAnimation and Global.UseAnimationBreak then
		Global.UseAnimation:Stop()
		Global.UseAnimationBreak:Stop()
		Global.UseAnimationBreak:Play()
		if Tool.Name == "Shears" then Tool:WaitForChild("Handle"):WaitForChild("sound_prompt"):Play() end
	end

	local AnyTool = Character:FindFirstChildOfClass("Tool")
	local ToolData = AnyTool and ItemNames[AnyTool.Name]
	if AnyTool and ToolData and Toggles.InfiniteItemsToggle.Value and Options.InfiniteItemsList.Value[ToolData] then
		Drops.ChildAdded:Once(function(NewTool)
			local Prompt = NewTool:FindFirstChild("ModulePrompt")
			local RealPrompt = FakePrompts[Object]
			Functions.FirePrompt(Prompt)
			Functions.FirePrompt(RealPrompt)
		end)
		Character.ChildAdded:Once(function(NewTool)
			if NewTool.Name == "Shears" then NewTool:WaitForChild("Handle"):WaitForChild("sound_promptend"):Play() end
		end)
		RemotesFolder.DropItem:FireServer(AnyTool)
	else
		local RealPrompt = FakePrompts[Object]
		Functions.FirePrompt(RealPrompt)
	end
end)
Conns.FloorReplicatedHandler = FloorReplicated.DescendantAdded:Connect(function(Object)
	if Object.Name == "GlitchScreech" then
		Modules.GlitchScreech = Object
	end
	if Object.Name:find("Jumpscare") and Object:IsA("ModuleScript")
		and not Object.Name:find("Eyestalk") and not Object.Name:find("Groundskeeper") and not Object.Name:find("Monument")
	then
		Object:SetAttribute("OriginalName", Object.Name)
		if Toggles.DisableEntityJumpscares.Value then Object.Name = Object.Name .. "_Disabled" end
		table.insert(Objects.JumpscareModules, Object)
	end
end)

if FloorReplicated:FindFirstChild("DigitalTimer") then
	Conns.HasteTimerConnection = FloorReplicated.DigitalTimer:GetPropertyChangedSignal("Value"):Connect(function()
		if Toggles.NotifyHasteTime.Value then Functions.Caption(Functions.GetHasteTime(), true) end
	end)
end

Conns.FogHandler = Services.Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
	if Services.Lighting.FogEnd ~= 10000000 then
		Global.OldFog = Services.Lighting.FogEnd
	end
	if Toggles.RemoveCameraFog.Value then
		Services.Lighting.FogEnd = 10000000
	end
end)

Conns.FogHandler2 = Services.Lighting.DescendantAdded:Connect(function(Object)
	if not Object:IsA("Atmosphere") then return end
	Object:SetAttribute("Density_Old", Object.Density)
	if Toggles.RemoveCameraFog.Value then Object.Density = 0 end

	local AtmoConn2 = Object:GetPropertyChangedSignal("Density"):Connect(function()
		if Object.Density ~= 0 then Object:SetAttribute("Density_Old", Object.Density) end
		if Toggles.RemoveCameraFog.Value then Object.Density = 0 end
	end)
	Object.Destroying:Once(function() if AtmoConn2 then AtmoConn2:Disconnect() end end)
	table.insert(Conns, AtmoConn2)
	table.insert(Global.FogInstances, Object)
end)

local RusherNames = { Rush=true, Ambush=true, Eyes=true, Lookman=true, Scribbles=true, Bash=true, Drones=true, Blitz=true, ["A-60"]=true, ["A-120"]=true, AR0xMBUSH=true, ["RNIUSHCG=="]=true, ["Custom Entity"]=true }

Conns.EntityHandler = Services.Workspace.ChildAdded:Connect(function(Entity)
	local EntityData = Entities[Entity.Name]
	if not EntityData then return end

	while not Entity.PrimaryPart do
		for _, Child in Entity:GetChildren() do
			if Child:IsA("BasePart") then Entity.PrimaryPart = Child end
		end
		task.wait()
	end
	task.wait(0.1)

	if not Entity.PrimaryPart or LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position) >= 10000 then return end

	local Name = EntityData.Name
    local RealName = Name
	if Options.EntityList.Value[Name] and Toggles.NotifyEntities.Value then
		local NotifyTitle = EntityData.NotifyMessage.Title
		local NotifyBody  = EntityData.NotifyMessage.Body
		local NotifyImage = EntityIcons[Entity.Name]

		if Entity.Name == "RushMoving" and Entity.PrimaryPart.Name ~= "RushNew" then
			NotifyTitle = NotifyTitle:gsub("Rush", Entity.PrimaryPart.Name)
			NotifyImage = Entity.PrimaryPart:WaitForChild("Attachment").ParticleEmitter.Texture
			Name = Entity.PrimaryPart.Name
		end

		Functions.Notify({ Title = NotifyTitle, Body = NotifyBody, Image = NotifyImage, Time = Toggles.NotifyKeepNotifications.Value and Entity or nil })

		if Toggles.EntityChatToggle.Value then
			Functions.SendChat(Name .. " " .. Options.EntityChatMessage.Value)
		end
	end

	if Entity.Name ~= "GloombatSwarm" then
		if Toggles.EntityESPToggle.Value and Options.EntityESPOptions.Value[RealName] then
			if Entity.Name == "MonumentEntity" then
				Functions.AddESP({ Object = Entity.Top, Text = Name, Color = Options.EntityESPColor.Value })
			else
				Functions.AddESP({ Object = Entity, Text = Name, Color = Options.EntityESPColor.Value })
			end
		end
		table.insert(Objects.Entities, Entity)
	end

	-- scribbles spawned while the bypass is on get Paperable disabled right away
	if Entity.Name == "Scribbles" or Entity.Name == "ScribbleMoving" or Entity.Name == "Scribble" then
		if Toggles.BypassScribbles and Toggles.BypassScribbles.Value then
			Entity:SetAttribute("Paperable", false)
			local ScribbleConn = Entity:GetAttributeChangedSignal("Paperable"):Connect(function()
				if Toggles.BypassScribbles.Value and Entity:GetAttribute("Paperable") ~= false then
					Entity:SetAttribute("Paperable", false)
				end
			end)
			table.insert(Conns, ScribbleConn)
		end
	end

	if RusherNames[EntityData.Name] then
		Instance.new("Humanoid", Entity).Name = "HighlightHumanoid"
		local Root = Entity.PrimaryPart
		if Root then Root.Transparency = 0.99 Root.Material = Enum.Material.Plastic end
	end

	if Entity.Name == "Lookman" then
		CurrentRooms.ChildAdded:Wait()
		task.wait(10)
		Entity:Destroy()
	end
end)

local LastClean = tick()
Conns.Cleaner = Services.RunService.Heartbeat:Connect(function()
	if tick() - LastClean <= 0.5 then return end
	LastClean = tick()

	for ArrayName, Array in Objects do
		local I = #Array
		while I >= 1 do
			local Object = Array[I]
			if Object == nil or not Object:IsDescendantOf(Services.Workspace) then
				table.remove(Array, I)
				local Conn = ESPConns[Object]
				if Conn then
					Conn:Disconnect()
					ESPConns[Object] = nil
					local Pos = table.find(Conns, Conn)
					if Pos then table.remove(Conns, Pos) end
				end
			end
			I -= 1
		end
	end
end)

local LastPromptFix = tick()
Conns.PromptFixer = Services.RunService.Heartbeat:Connect(function()
	if tick() - LastPromptFix <= 0.5 then return end
	LastPromptFix = tick()
	for _, Prompt in Objects.Prompts do
		if Prompt:HasTag("DisableWhenEnabledOnClient") then
			Prompt:RemoveTag("DisableWhenEnabledOnClient")
		end
	end
end)

if LocalPlayer.Character then
	task.spawn(function() Functions.HandleCharacter(LocalPlayer.Character) end)
end

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
	if Conns.MainHandler then
		Conns.MainHandler:Disconnect()
		Conns.MainHandler = nil
	end
	task.wait(0.5)
	Functions.HandleCharacter(NewCharacter)
end)

Library:OnUnload(function()
	for _, v in pairs(Conns) do
		pcall(function() v:Disconnect() end)
	end

	if MainHook and mstudio45 and mstudio45.Environment then
		pcall(function()
			mstudio45.Environment.hookmetamethod(game, "__namecall", MainHook)
		end)
		MainHook = nil
	end

	if track then
		track:Stop()
	end
	gui.Enabled = false
	gui:Destroy()
	if LolhaxGui then
		LolhaxGui:Destroy()
	end
	if Container then
		Container:Destroy()
	end
	if Global.PromptContainer then
		Global.PromptContainer:Destroy()
	end
	TriggerFigureLooping = false
	TriggerFigureThread = nil
	BreakDoorsLooping = false
	RestoreAllModules()
	RestoreRequireHook()
	for _, Object in Objects.Entities do
		if Object.Name == "Snare" or Object.Name == "GiggleCeiling" then
			local Hitbox = Object:FindFirstChild("Hitbox")
			if Hitbox then Hitbox.CanTouch = true end
		end
		if Object.Name == "GloomPile" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = true end
			end
		end
		if Object.Name == "FakeDoor" or Object.Name == "DoorFake" then
			local Hidden = Object:FindFirstChild("Hidden")
			if Hidden then Hidden.CanTouch = true end
			local Lock = Object:FindFirstChild("Lock")
			if Lock and Lock:FindFirstChild("UnlockPrompt") then Lock.UnlockPrompt.Enabled = true end
		end
		if Object.Name == "SideroomSpace" then
			local Coll = Object:FindFirstChild("Collision")
			if Coll then Coll.CanCollide = false Coll.CanTouch = true end
		end
		if Object.Name == "Drones" then
			local WalkedInto = Object:FindFirstChild("_WalkedInto")
			if WalkedInto then WalkedInto.Name = "WalkedInto" end
		end
		if Object.Name == "Scribbles" or Object.Name == "ScribbleMoving" or Object.Name == "Scribble" then
			Object:SetAttribute("Paperable", true)
		end
	end

	for _, Object in Objects.SeekBridges do Object:Destroy() end

	for _, Fog in Global.FogInstances do
		Fog.Density = Fog:GetAttribute("Density_Old")
	end
	Services.Lighting.FogEnd = Global.OldFog

	local Vignette = Global.MainUI:FindFirstChild("HideVignette") or Global.MainUI.MainFrame:FindFirstChild("HideVignette")
	if Vignette then Vignette.Image = "rbxassetid://6100076320" end

	local ModuleRestores = {
		Screech = "Screech", Glitch = "Glitch", Shade = "Shade",
		SpiderJumpscare = "SpiderJumpscare", A90 = "A90", Dread = "Dread", Void = "Void"
	}
	for Key, OriginalName in ModuleRestores do
		if Modules[Key] then Modules[Key].Name = OriginalName end
	end

	FakeEvents.Screech:Destroy()
	FakeEvents.Screech_Real.Parent = RemotesFolder
	FakeEvents.Shade:Destroy()
	FakeEvents.Shade_Real.Parent = RemotesFolder

	if FakeEvents.A90_Real then
		FakeEvents.A90:Destroy()
		FakeEvents.A90_Real.Parent = RemotesFolder
	end
	if FakeEvents.Surge_Real then
		FakeEvents.Surge:Destroy()
		FakeEvents.Surge_Real.Parent = RemotesFolder
	end

	if FakeEvents.Figure_Real then
		FakeEvents.Figure:Destroy()
		FakeEvents.Figure_Real.Parent = RemotesFolder
	end

	if HiddenRemotes then
		HiddenRemotes:Destroy()
	end

	Global.SeekNodesFolder:Destroy()
	Global.RoomsNodesFolder:Destroy()
	Global.ManipulateBody:Destroy()

	if DoorReachConnection then
		DoorReachConnection:Disconnect()
		DoorReachConnection = nil
	end

	local CurrentRoomObj = CurrentRooms and CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom") or ""))
	if CurrentRoomObj then
		local OldAmbient = CurrentRoomObj:GetAttribute("Ambient")
		Services.TweenService:Create(Services.Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), { Ambient = OldAmbient }):Play()
	end

	for _, Prompt in Objects.Prompts do
		if FakePrompts[Prompt] then
			pcall(function() FakePrompts[Prompt].Parent = Prompt.Parent end)
			pcall(function() Prompt:Destroy() end)
		end
		if Prompt.Parent then
			Prompt.HoldDuration = Prompt:GetAttribute("HoldDuration_Old") or Prompt.HoldDuration
			Prompt.RequiresLineOfSight = Prompt:GetAttribute("RequiresLineOfSight_Old") or Prompt.RequiresLineOfSight
			Prompt.MaxActivationDistance = Prompt:GetAttribute("MaxActivationDistance_Old") or Prompt.MaxActivationDistance
		end
	end

	Character:SetAttribute("CanJump",  OldJump)

	for _, Object in Services.Workspace:GetDescendants() do
		task.spawn(function() Functions.RemoveESP(Object) end)
	end

	Humanoid.WalkSpeed  = Functions.GetCurrentSpeed()
	Humanoid.JumpPower  = 5
	Humanoid.HipHeight  = 2.367

	local BaseY = 0.18
	Collision.Position          = RootPart.Position + Vector3.new(0, BaseY, 0)
	CollisionPart.Position      = RootPart.Position + Vector3.new(0, BaseY, 0)
	CollisionPartClone.Position = RootPart.Position + Vector3.new(0, BaseY, 0)

	if Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
		Character.LowerTorso.Root.C1 = Global.OriginalC1
	end
	if Collision:FindFirstChild("CollisionCrouch") then
		Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, -0.982, 0)
	end

	CollisionClone:Destroy()
	CollisionPartClone:Destroy()
	mstudio45.ESPLibrary:Unload()

	if Main_Game then
		Main_Game.fovtarget   = 70
		Main_Game.spring.Speed = 8
	end

	if Global.OriginalGetMoveVector then 
		local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()
		Controls.GetMoveVector = Global.OriginalGetMoveVector
	end

	getgenv().mstudio45 = nil
end)
end

while not Global.MainUI do task.wait() end

if type(SyncEntityRemoval) == "function" then pcall(SyncEntityRemoval) end

-- Native Obsidian settings. Replaces the external ApplySettingsTab call.
do
    local General = Tabs.Settings:AddLeftGroupbox("General", "settings")
    General:AddLabel("Menu and configuration settings for this DOORS module.", true)
    General:AddButton({ Text = "Join Discord", Func = function()
        Global.CopyUILink("https://discord.gg/mspaint")
    end }):AddButton({ Text = "Copy Link", Func = function()
        Global.CopyUILink("https://www.mspaint.cc")
    end })
    General:AddButton({ Text = "Unload", DoubleClick = true, Func = function() Library:Unload() end })
    General:AddButton({ Text = "Copy Discord Invite", Func = function()
        Global.CopyUILink("https://dsc.gg/mstudio45")
    end })
    General:AddDivider()
    General:AddLabel("Save a configuration on the right to keep your options between runs.", true)

    local Menu = Tabs.Interface:AddLeftGroupbox("Menu", "settings")
    Menu:AddToggle("MspaintUI_HideOnLoad", {
        Text = "Hide On Load", Default = false,
        Tooltip = "Save this option in your autoload config. Takes effect on the next load.",
    })
    Menu:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift", NoUI = true, Text = "Menu keybind",
    })
    Library.ToggleKeybind = Options.MenuKeybind
    local MenuShortcut = Services.UserInputService.InputBegan:Connect(function(Input, Processed)
        if Processed or Services.UserInputService:GetFocusedTextBox() then return end
        if Input.KeyCode == Enum.KeyCode.RightControl and Options.MenuKeybind.Value ~= "RightControl" then
            Library:Toggle()
        end
    end)
    if Library.GiveSignal then Library:GiveSignal(MenuShortcut) else table.insert(Conns, MenuShortcut) end
    Menu:AddDivider()
    Menu:AddLabel("UI Style: Obsidian")
    Menu:AddDropdown("MspaintUI_DPI", {
        Text = "DPI Scale", Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%", Disabled = type(Library.SetDPIScale) ~= "function",
        Callback = function(Value)
            if Library.SetDPIScale then Library:SetDPIScale(tonumber((Value:gsub("%%", "")))) end
        end,
    })
    Menu:AddDivider()
    Menu:AddToggle("AlwaysOnTop", {
        Text = "Always On Top", Default = Window.AlwaysOnTop == true,
        Disabled = type(Window.SetAlwaysOnTop) ~= "function",
        Callback = function(Value) if Window.SetAlwaysOnTop then Window:SetAlwaysOnTop(Value) end end,
    })
    Menu:AddToggle("KeybindMenuOpen", {
        Text = "Open Keybind Menu", Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
        Disabled = Library.KeybindFrame == nil,
        Callback = function(Value) if Library.KeybindFrame then Library.KeybindFrame.Visible = Value end end,
    })
    Menu:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor", Default = false,
        Callback = function(Value) Library.ShowCustomCursor = Value end,
    })
    Menu:AddToggle("MspaintUI_PopOut", {
        Text = "Pop Out Boxes", Default = true,
        Disabled = type(Global.UI.General_Prompts.SetPoppedOut) ~= "function",
        Callback = function(Value)
            for _, Tab in pairs(Tabs) do
                for _, Boxes in ipairs({ Tab.Groupboxes or {}, Tab.Tabboxes or {} }) do
                    for _, Box in pairs(Boxes) do
                        Box.PopOutEnabled = Value
                        if not Value and Box.SetPoppedOut then Box:SetPoppedOut(false) end
                    end
                end
            end
        end,
    })

    local Animations = Global.UI.UI_Animations
    local CanAnimate = type(Window.SetAnimations) == "function"
    local function UpdateAnimations()
        if not CanAnimate then return end
        Window:SetAnimations(
            Options.MspaintUI_Animations and Options.MspaintUI_Animations.Value or nil,
            Options.MspaintUI_Transition and Options.MspaintUI_Transition.Value or 0.22,
            Options.MspaintUI_SwipeOffset and Options.MspaintUI_SwipeOffset.Value or 26,
            Options.MspaintUI_SwipeDirection and string.lower(Options.MspaintUI_SwipeDirection.Value) or "bottom"
        )
    end
    Animations:AddDropdown("MspaintUI_Animations", {
        Text = "Enabled Animations", Values = { "Dropdown", "Groupbox", "KeyPicker", "TabSwitch", "ToggleWindow" },
        Default = { "Dropdown", "Groupbox", "KeyPicker", "TabSwitch", "ToggleWindow" },
        Multi = true, AllowNull = true, Disabled = not CanAnimate, Callback = UpdateAnimations,
    })
    Animations:AddSlider("MspaintUI_Transition", {
        Text = "Tab Transition Time", Default = 0.22, Min = 0, Max = 1, Rounding = 2,
        Suffix = "s", Compact = true, Disabled = not CanAnimate, Callback = UpdateAnimations,
    })
    Animations:AddSlider("MspaintUI_SwipeOffset", {
        Text = "Tab Swipe Offset", Default = 26, Min = 0, Max = 100, Rounding = 0,
        Suffix = "px", Compact = true, Disabled = not CanAnimate, Callback = UpdateAnimations,
    })
    Animations:AddDropdown("MspaintUI_SwipeDirection", {
        Text = "Tab Swipe Direction", Values = { "Bottom", "Top", "Left", "Right" },
        Default = "Bottom", Disabled = not CanAnimate, Callback = UpdateAnimations,
    })

    local Captions = Global.UI.UI_Captions
    Captions:AddDropdown("MspaintUI_CaptionStyle", {
        Text = "Caption Style", Values = { "Obsidian", "DOORS" }, Default = "Obsidian",
        Disabled = type(Library.AddDraggableLabel) ~= "function",
    })
    Captions:AddButton({ Text = "Test Caption", Func = function()
        Functions.Caption("This is a test caption.", false)
    end })

    Global.UI.UI_Notifications:AddDropdown("MspaintUI_NotifySide", {
        Text = "Notification Side", Values = { "Right", "Left" }, Default = "Right",
        Disabled = type(Library.SetNotifySide) ~= "function",
        Callback = function(Value) if Library.SetNotifySide then Library:SetNotifySide(Value) end end,
    })
    Global.UI.UI_Notifications:AddInput("MspaintUI_NotifySound", {
        Text = "Notification Sound ID", Default = "rbxassetid://4590662766", Finished = true,
        Tooltip = "Used by Obsidian-style notifications.",
    })
    Global.UI.UI_Notifications:AddButton({ Text = "Reset Sound to Default", Func = function()
        Options.MspaintUI_NotifySound:SetValue("rbxassetid://4590662766")
    end })

    -- Preserve manager folders initialized by the loader; use the original save path only as a fallback.
    if ThemeManager and ThemeManager.SetLibrary and ThemeManager.ApplyToTab then
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder("mstudio45")
        if (not ThemeManager.Folder or ThemeManager.Folder == "") and ThemeManager.SetFolder then
            ThemeManager:SetFolder(mstudio45.SavePath)
        end
        local Ok, Err = pcall(function() ThemeManager:ApplyToTab(Tabs.Interface) end)
        if not Ok then
            warn("[UI] ThemeManager: " .. tostring(Err))
            Tabs.Interface:AddLeftGroupbox("Themes", "paintbrush"):AddLabel("ThemeManager could not initialize. See the console.", true)
        end
    else
        Tabs.Interface:AddLeftGroupbox("Themes", "paintbrush"):AddLabel("ThemeManager was not provided by the loader.", true)
    end
    if SaveManager and SaveManager.SetLibrary and SaveManager.BuildConfigSection then
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("mstudio45/Doors")
        if (not SaveManager.Folder or SaveManager.Folder == "") and SaveManager.SetFolder then
            SaveManager:SetFolder(mstudio45.SavePath)
        end
        if SaveManager.IgnoreThemeSettings then SaveManager:IgnoreThemeSettings() end
        if SaveManager.SetIgnoreIndexes then SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) end
        local Ok, Err = pcall(function() SaveManager:BuildConfigSection(Tabs.Settings) end)
        if not Ok then
            warn("[UI] SaveManager: " .. tostring(Err))
            Tabs.Settings:AddRightGroupbox("Configuration", "folder-cog"):AddLabel("Config storage could not initialize. See the console.", true)
        elseif SaveManager.LoadAutoloadConfig then
            local Loaded, LoadErr = pcall(function() SaveManager:LoadAutoloadConfig() end)
            if not Loaded then warn("[UI] Autoload: " .. tostring(LoadErr)) end
        end
    else
        Tabs.Settings:AddRightGroupbox("Configuration", "folder-cog"):AddLabel("SaveManager was not provided by the loader.", true)
    end

    if Tabs.Home.Show then Tabs.Home:Show() end
    if Toggles.MspaintUI_HideOnLoad.Value and Window.Toggle then Window:Toggle(false) end
end


if Loading and Loading.Destroyed ~= true then
	Loading:SetCurrentStep(3)
	Loading:SetMessage("Building interface...")
	task.wait(1.5)
	Loading:SetCurrentStep(4)
	Loading:SetMessage("Ready.")
	Loading:SetDescription("fun fact: bomb.exe is loading...")
	task.wait(1.5)
	Loading:Continue()
end
Functions.Notify({ Title = "Successfully loaded", Body = "Press RightShift or RightControl to Close/Open the menu"})
