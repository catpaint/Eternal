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

local Global = {}
local Conns = {}
local ESPConns = {}
local FakePrompts = {}
local Functions = {}
local PartProperties = {}

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
local Floor           = GameData:WaitForChild("Floor").Value
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
    title.Text = "[mstudio45] " .. tostring(TitleText or "Notification")
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
        snd.SoundId = "rbxassetid://4590662766"
        snd.Volume = (Toggles.NotifyPlaySound and Toggles.NotifyPlaySound.Value and Options.NotifySoundVolume.Value) or (Toggles.NotifyPlaySound and 0 or 3)
        snd.PlayOnRemove = true
        snd:Destroy()
        NotificationLibrary:Notify(Settings.Title, Settings.Body, Settings.Time or 5)
    else
        Library:OldNotify({ Title = Settings.Title, Description = Settings.Body, Time = Settings.Time })
    end
end
Functions.Caption = function(Text, PlaySound)
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
Library.Notify = function(Data, Body, Time)
	Functions.Notify({ Title = Body, Time = Time or 5 })
end

if not LocalPlayer.Character or not CurrentRooms:FindFirstChildOfClass("Model") then
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
	["RushMoving"]    = 85,
	["AmbushMoving"]  = 150,
	["A60"]           = 125,
	["A120"]          = 85,
	["GlitchRush"]    = 90,
	["GlitchAmbush"]  = 175,
	["BackdoorRush"]  = 85,
	["CustomEntity"]  = 85,
}

Functions.GetNearestEntity = function(CheckDisabled, List)
	local best, bestDist = nil, math.huge

	for _, ent in Services.Workspace:GetChildren() do
		local range = ent and ent.PrimaryPart and EntityDistances[ent.Name]
		if range then
			local skip = (List and List[Entities[ent.Name].Name])
			local inactive = CheckDisabled and ent:GetAttribute("Inactive") == true
			if not skip and not inactive then
				local d = LocalPlayer:DistanceFromCharacter(ent.PrimaryPart.Position)
				if d < range and d < bestDist then
					best, bestDist = ent, d
				end
			end
		end
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

local Window = Library:CreateWindow({
	Title = "mstudio45 V4",
	Footer = "Game: DOORS | dsc.gg/mstudio45",
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
	Exploits = Window:AddTab("Exploits", "shield"),
	Visuals  = Window:AddTab("Visuals", "eye"),
	Floors   = Window:AddTab("Floors", "globe"),
	Troll    = Window:AddTab("Troll", "smile"),
	Settings = Window:AddTab("Settings", "settings"),
}

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
	Text = "Open Keybind Menu",
	Callback = function(value)
		if Library.KeybindFrame then Library.KeybindFrame.Visible = value end
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = false,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddToggle("AlwaysOnTop", {
	Text = "Always On Top",
	Default = Window.AlwaysOnTop or false,
	Callback = function(Value)
		if Window.SetAlwaysOnTop then Window:SetAlwaysOnTop(Value) end
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Copy Discord Invite", function()
	if toclipboard then toclipboard("https://dsc.gg/mstudio45") end
	Library:Notify("Discord invite copied.")
end)
MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

Options.MenuKeybind:OnClick(function()
	Library:Toggle()
end)

Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.RightShift then
		Library:Toggle()
	end
end)

pcall(function()
	if ThemeManager and SaveManager then
		ThemeManager:SetLibrary(Library)
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		ThemeManager:SetFolder("mstudio45")
		SaveManager:SetFolder("mstudio45/Doors")
		SaveManager:BuildConfigSection(Tabs.Settings)
		ThemeManager:ApplyToTab(Tabs.Settings)
	end
end)

General_Character = Tabs.General:AddLeftGroupbox("Character")
General_Character:AddSlider("WalkSpeedSlider", {
	Text = "WalkSpeed", Min = 0, Max = 100, Default = 0, Rounding = 0, Compact = true
})
General_Character:AddToggle("WalkSpeedToggle", {
	Text = "Enable Walk Speed", Default = false, Tooltip = "Increases your walkspeed by the specified amount."
})
General_Character:AddToggle("FlyToggle", {
	Text = "Fly", Default = false, Tooltip = "Allows you to freely fly around the map."
})
Toggles.FlyToggle:AddKeyPicker("FlyKeybind", {
	Text = "Fly", Default = "F", Mode = "Toggle", SyncToggleState = true
})
General_Character:AddSlider("FlySpeed", {
	Text = "Fly Speed", Min = 0, Max = 115, Default = 20, Rounding = 0, Compact = true
})
General_Character:AddDivider()
General_Character:AddToggle("NoclipToggle", {
	Text = "Noclip", Default = false, Tooltip = "Allows your character to pass through solid objects."
})
General_Character:AddToggle("RemoveClosetDelay", {
	Text = "No Closet Delay", Default = false,
	Tooltip = "Removes the short window where you can't exit out of a closet after the animation finishes."
})
General_Character:AddToggle("RemoveAcceleration", {
	Text = "Remove Acceleration", Default = false, Tooltip = "Prevents your character from sliding while moving."
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

General_Character:AddDivider()
General_Character:AddToggle("EnableCharacterJump", {
	Text = "Enable Jumping", Default = false, Tooltip = "Allows your character to jump."
})

local OldJump = false

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

General_Self = Tabs.General:AddLeftGroupbox("Player")
General_Self:AddToggle("DoorReachToggle", {
	Text = "Door Reach", Default = false, Tooltip = "Allows you to open doors from further away."
})

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
General_Self:AddToggle("DisableIdleKick", {
	Text = "Disable Idle Kick", Default = false, Tooltip = "Prevents the kick from being idle for 20 minutes."
})
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

General_Self:AddDivider()
General_Self:AddSlider("PromptReachSlider", {
	Text = "Prompt Reach Multiplier", Min = 1, Max = 2, Default = 1, Rounding = 1, Compact = true
})
General_Self:AddToggle("InstantPrompts", {
	Text = "Instant Prompts", Default = false, Tooltip = "Allows you to trigger all prompts instantly."
})
General_Self:AddToggle("PromptClip", {
	Text = "Prompt Clip", Default = false, Tooltip = "Allows you to interact with prompts through walls."
})

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

Self_Misc = Tabs.General:AddRightGroupbox("Game")
Self_Automation = Tabs.General:AddRightGroupbox("Automation")
Self_Automation:AddToggle("AutoBreakerBox", {
	Text = "Auto Breaker Box", Default = false, Tooltip = "Automatically solves the breaker box."
})
Self_Automation:AddToggle("AutoSolveAnchors", {
	Text = "Auto Anchor", Default = false,
	Tooltip = "Automatically enters the correct code into anchors when you are near them."
})
Toggles.AutoBreakerBox:OnChanged(function(Value)
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

Self_Automation:AddDivider()
Self_Automation:AddToggle("AutoUnlockPadlockToggle", {
	Text = "Auto Unlock Padlock", Default = false, Tooltip = "Automatically enters the code into the library padlock."
})
Self_Automation:AddSlider("AutoUnlockPadlockSlider", {
	Text = "Unlock Distance", Min = 1, Max = 50, Default = 10, Rounding = 0, Compact = true
})
Self_Automation:AddDivider()
Self_Automation:AddToggle("AutoInteractToggle", {
	Text = "Auto Interact", Default = false, Tooltip = "Automatically triggers nearby prompts."
})
Toggles.AutoInteractToggle:AddKeyPicker("AutoInteractKeybind", {
	Text = "Auto Interact", Default = "R",
	Mode = "Toggle", SyncToggleState = true
})
Self_Automation:AddDropdown("AutoInteractIgnoreList", {
	Text = "Ignore List",
	Values = { "Glitch Fragments", "Jeff Items", "Dropped Items", "Currency", "Minecarts", "Locks" },
	Default = { "Glitch Fragments", "Jeff Items", "Dropped Items", "Minecarts" },
	Multi = true, AllowNull = true
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

Exploits_Anti = Tabs.Exploits:AddLeftGroupbox("Anti")
Exploits_Anti:AddToggle("BypassGiggle",         { Text = "Anti Giggle",           Default = false, Tooltip = "Prevents 'Giggle' from attacking you." })
Exploits_Anti:AddToggle("BypassDupe",           { Text = "Anti Dupe",             Default = false, Tooltip = "Prevents you from open 'Dupe' fake doors." })
Exploits_Anti:AddToggle("BypassEyes",           { Text = "Anti Eyes",             Default = false, Tooltip = "Prevents 'Eyes' from hurting you." })
Exploits_Anti:AddToggle("BypassLookman",        { Text = "Anti Lookman",          Default = false, Tooltip = "Prevents 'Lookman' from hurting you." })
Exploits_Anti:AddToggle("BypassGloombatEggs",   { Text = "Anti Gloombat Eggs",    Default = false, Tooltip = "Prevents taking damage from stepping on 'Gloombat' eggs." })
Exploits_Anti:AddToggle("BypassSeekObstructions", { Text = "Anti Seek Obstructions", Default = false, Tooltip = "Prevents obstacles in the 'Seek' chase from harming you." })
Exploits_Anti:AddToggle("BypassVacuum",         { Text = "Anti Vacuum",           Default = false, Tooltip = "Prevents you from falling into 'Vacuum' fake doors." })
Exploits_Anti:AddToggle("BypassKillbricks",     { Text = "Anti Killbricks",       Default = false, Tooltip = "Prevents 'Lava' from hurting you." })
Exploits_Anti:AddToggle("BypassSeekingWall",    { Text = "Anti Seek Wall",     Default = false, Tooltip = "Prevents 'ScaryWall' from hurting you." })
Exploits_Anti:AddToggle("BypassSnare",          { Text = "Anti Snare",            Default = false, Tooltip = "Prevents 'Snare' from trapping you." })
Exploits_Anti:AddToggle("BypassBanana",         { Text = "Anti Banana",           Default = false, Tooltip = "Prevents 'Banana Peel' from slipping you up (sometimes doesn't work)." })
Exploits_Anti:AddToggle("BypassJeff",           { Text = "Anti Jeff (FE)",             Default = false, Tooltip = "Prevents 'Jeff the Killer' from stabbing you (sometimes doesn't work)." })
Exploits_Anti:AddToggle("BypassMandrake", {
    Text = "Anti Mandrake (FE)",
    Default = false,
    Tooltip = "Prevents 'Mandrake' from attacking you.",
    Disabled = false,
    DisabledTooltip = nil
})

Toggles.BypassMandrake:OnChanged(function(Value)
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

Exploits_Anti:AddToggle("AntiDrone", {
    Text = "Anti Drone",
    Default = false,
    Tooltip = "Instantly deletes any Drone model or entity as soon as it appears in Workspace."
})

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



Toggles.BypassGiggle:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "GiggleCeiling" then
			Object:WaitForChild("Hitbox").CanTouch = not Value
		end
	end
end)
Toggles.BypassDupe:OnChanged(function(Value)
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
	if not Value or not Global.IsEyes then return end
	if Floor == "Fools" or Floor == "OldHotel" then
		RemotesFolder.MotorReplication:FireServer(0, (Global.SpoofOffset == 200 and 65 or -65), 0, false)
	else
		RemotesFolder.MotorReplication:FireServer(-650)
	end
end)
Toggles.BypassLookman:OnChanged(function(Value)
	if not Value or not Global.IsLookman then return end
	if Floor == "Fools" or Floor == "OldHotel" then
		RemotesFolder.MotorReplication:FireServer(0, (Global.SpoofOffset == 200 and 65 or -65), 0, false)
	else
		RemotesFolder.MotorReplication:FireServer(-650)
	end
end)
Toggles.BypassGloombatEggs:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		for _, Part in Object:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CanTouch = not Value
			end
		end
	end
end)
Toggles.BypassSeekObstructions:OnChanged(function(Value)
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
	for _, Object in Objects.Entities do
		if Object.Name == "SideroomSpace" then
			Object:WaitForChild("Collision").CanCollide = Value
			Object:WaitForChild("Collision").CanTouch = not Value
		end
	end
end)
Toggles.BypassKillbricks:OnChanged(function(Value)
	for _, Object in Objects.Obstructions do
		if Object.Name == "Lava" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassSeekingWall:OnChanged(function(Value)
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
	for _, Object in Objects.Entities do
		if Object.Name == "Snare" then
			for _, Part in Object:GetDescendants() do
				if Part:IsA("BasePart") then Part.CanTouch = not Value end
			end
		end
	end
end)
Toggles.BypassBanana:OnChanged(function(Value)
	for _, Object in Objects.Entities do
		if Object.Name == "BananaPeel" then Object.CanTouch = not Value end
	end
end)
Toggles.BypassJeff:OnChanged(function(Value)
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

Exploits_Troll = Tabs.Exploits:AddRightGroupbox("Other")
Exploits_Troll:AddToggle("TwerkDance", { 
    Text = "Twerk", 
    Default = false, 
    Tooltip = "just Twerk." 
})
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

Exploits_BypassRight = Tabs.Exploits:AddRightGroupbox("Bypass")
Exploits_BypassRight:AddToggle("DisableAnticheat", {
	Text = "Anticheat Bypass", Default = false,
	Tooltip = "Completely disables the anticheat, after interacting with a ladder."
})
Exploits_BypassRight:AddToggle("TeleportManipulationToggle", {
	Text = "Teleport Manipulation", Default = false,
	Tooltip = "Moves your character forward slowly, mitigating the game's anti-noclip."
})
Toggles.DisableAnticheat:OnChanged(function(Value)
	if Global.AnticheatDisabled == true and not Value then
		RemotesFolder.ClimbLadder:FireServer()
		Global.AnticheatDisabled = false
	end
end)
Toggles.TeleportManipulationToggle:AddKeyPicker("TeleportManipulationKeybind", {
	Text = "Teleport Manipulation", Default = "V",
	Mode = Library.IsMobile and "Toggle" or "Hold", SyncToggleState = true
})
Exploits_BypassRight:AddDropdown("TeleportManipulationMode", {
	Values = {"Pivot", "Velocity"}, Text = "Manipulation Method",
	Default = 1,
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

Exploits_BypassRight:AddDivider()
Exploits_BypassRight:AddToggle("PositionSpoof", {
	Text = "Position Spoof", Default = false,
	Tooltip = "Makes it that you will be invincible against rush like entities."
})
Exploits_BypassRight:AddToggle("AnitFigureHearing", {
	Text = "Anti Figure Hearing", Default = false, Tooltip = "Makes the game think you are always crouching."
})
Toggles.PositionSpoof:OnChanged(function(Value)
	if Floor ~= "Fools" and Floor ~= "OldHotel" then
		if Value then
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
			Humanoid.HipHeight = 0.05
			RemotesFolder.Crouch:FireServer(true, true)
		else
			RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 2.346, 0)
			Humanoid.HipHeight = 2.396
		end
	end
end)
Toggles.PositionSpoof:AddKeyPicker("PositionSpoof", {
	Text = "Position Spoof", Default = "G", Mode = "Toggle", SyncToggleState = true
})
Toggles.AnitFigureHearing:OnChanged(function(Value)
	if RemotesFolder:FindFirstChild("Crouch") then
		RemotesFolder.Crouch:FireServer(Value and true or Functions.IsCrouching(), true)
	end
end)

Toggles.AnitFigureHearing:OnChanged(function(Value)
	if Value then
		FakeEvents.Figure.Parent = RemotesFolder
		FakeEvents.Figure_Real.Parent = Workspace.mstudio45_Folder
	else
		FakeEvents.Figure_Real.Parent = RemotesFolder
		FakeEvents.Figure.Parent = Workspace.mstudio45_Folder
	end
end)

Exploits_Remove = Tabs.Exploits:AddRightGroupbox("Remove")
Exploits_Remove:AddToggle("RemoveScreech", { Text = "Remove Screech",  Default = false, Tooltip = "Prevents 'Screech' from spawning." })
Exploits_Remove:AddToggle("RemoveHalt",    { Text = "Remove Halt",     Default = false, Tooltip = "Prevents 'Halt' from spawning." })
Exploits_Remove:AddToggle("RemoveA90",     { Text = "Remove A-90",     Default = false, Tooltip = "Prevents 'A-90' from spawning." })
Exploits_Remove:AddToggle("RemoveDread",   { Text = "Remove Dread",    Default = false, Tooltip = "Prevents 'Dread' from spawning." })
Exploits_Remove:AddDivider()
Exploits_Remove:AddToggle("NoScreechDamage", { Text = "No Screech Damage", Default = false, Tooltip = "Prevents 'Screech' from hurting you." })
Exploits_Remove:AddToggle("NoHaltDamage",    { Text = "No Halt Damage",    Default = false, Tooltip = "Prevents 'Halt' from hurting you." })
Exploits_Remove:AddToggle("NoA90Damage",     { Text = "No A-90 Damage",    Default = false, Tooltip = "Prevents 'A-90' from hurting you." })
Exploits_Remove:AddToggle("NoSurgeDamage",   { Text = "No Surge Damage",   Default = false, Tooltip = "Prevents 'Surge' from hurting you." })

Toggles.NoScreechDamage:OnChanged(function(Value)
	if Value then
		FakeEvents.Screech.Parent = RemotesFolder
		FakeEvents.Screech_Real.Parent = Workspace.mstudio45_Folder
	else
		FakeEvents.Screech_Real.Parent = RemotesFolder
		FakeEvents.Screech.Parent = Workspace.mstudio45_Folder
	end
end)
Toggles.NoHaltDamage:OnChanged(function(Value)
	if Value then
		FakeEvents.Shade.Parent = RemotesFolder
		FakeEvents.Shade_Real.Parent = Workspace.mstudio45_Folder
	else
		FakeEvents.Shade_Real.Parent = RemotesFolder
		FakeEvents.Shade.Parent = Workspace.mstudio45_Folder
	end
end)
Toggles.NoA90Damage:OnChanged(function(Value)
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

local function SyncEntityRemoval()
	local UIModules = FindUIModules()
	if Toggles.RemoveScreech and Toggles.RemoveScreech.Value then
		RenameModule(UIModules, "Screech", "Screech_Disabled")
	else
		RenameModule(UIModules, "Screech_Disabled", "Screech")
	end
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

Toggles.RemoveScreech:OnChanged(function() SyncEntityRemoval() end)
Toggles.RemoveHalt:OnChanged(function() SyncEntityRemoval() end)
Toggles.RemoveA90:OnChanged(function() SyncEntityRemoval() end)
Toggles.RemoveDread:OnChanged(function() SyncEntityRemoval() end)

Exploits_Audio = Tabs.Exploits:AddLeftGroupbox("Sound")
Global.JamMuffle = Services.SoundService:WaitForChild("Main"):FindFirstChild("Jamming") or Instance.new("EqualizerSoundEffect")

Exploits_Audio:AddToggle("RemoveJamminMusic",       { Text = "Remove Jammin Music",       Default = false, Tooltip = "Removes the music and muffle effect from the 'Jammin' modifier." })

Toggles.RemoveJamminMusic:OnChanged(function(Value)
	local Jam = Global.MainUI.Initiator.Main_Game.Health:FindFirstChild("Jam")
	if Jam then
		Jam.Volume = Value and 0 or 0.45
		Global.JamMuffle.Enabled = LiveModifiers:FindFirstChild("Jammin") and not Value or false
	end
end)

Visuals_LeftTab = Tabs.Visuals:AddLeftTabbox("Camera / Effects")
Visuals_Camera = Visuals_LeftTab:AddTab("Camera")
Visuals_Camera:AddToggle("AmbientToggle", { Text = "Ambient", Default = false, Tooltip = "Changes the lighting color to the specified value." })
Visuals_Camera:AddSlider("FieldOfView", { Text = "Field of View", Min = 1, Max = 120, Default = 70, Rounding = 0 })
Visuals_Camera:AddDivider()
Visuals_Camera:AddToggle("RemoveCameraShake", {
	Text = "Remove Camera Shake", Default = false, Tooltip = "Prevents the camera from shaking.",
	Disabled = not Functions.CheckEnv("require"), DisabledTooltip = Global.ExecutorIssueMessage
})
Visuals_Camera:AddToggle("RemoveCameraBobbing", {
	Text = "Remove Camera Bobbing", Default = false, Tooltip = "Prevents the camera from bobbing when moving.",
	Disabled = not Functions.CheckEnv("require"), DisabledTooltip = Global.ExecutorIssueMessage
})
Visuals_Camera:AddToggle("RemoveCameraFog", { Text = "Remove Fog", Default = false, Tooltip = "Removes all fog effects from the camera." })
Visuals_Camera:AddDivider()
Visuals_Camera:AddToggle("ThirdPersonToggle", { Text = "Third Person", Default = false, Tooltip = "Zooms out your camera, allowing you to see your character from behind." })
Toggles.ThirdPersonToggle:AddKeyPicker("ThirdPersonKeybind", { Text = "Third Person", Default = "T", Mode = "Toggle", SyncToggleState = true })
Visuals_Camera:AddSlider("ThirdPersonOffsetX", { Text = "X Offset", Min = -10, Max = 10, Default = 1.5, Rounding = 1, Compact = true })
Visuals_Camera:AddSlider("ThirdPersonOffsetY", { Text = "Y Offset", Min = -10, Max = 10, Default = 1,   Rounding = 1, Compact = true })
Visuals_Camera:AddSlider("ThirdPersonOffsetZ", { Text = "Z Offset", Min = -10, Max = 10, Default = 5,   Rounding = 1, Compact = true })
Visuals_Camera:AddToggle("ThirdPersonWallCheck", { Text = "Wall Check", Default = false, Tooltip = "Prevents third person from going through walls." })

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

Visuals_Effects = Visuals_LeftTab:AddTab("Effects")
Visuals_Effects:AddToggle("TransparentHidingSpotsToggle", { Text = "Transparent Hiding Spots", Default = false, Tooltip = "Makes a hiding spot transparent when you enter it." })
Visuals_Effects:AddSlider("TransparentHidingSpotsSlider", { Text = "Transparency", Min = 0, Max = 1, Default = 0.5, Rounding = 2, Compact = true })

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

Visuals_Effects:AddDivider()
Visuals_Effects:AddToggle("DisableGlitchJumpscare",   { Text = "Disable Glitch Jumpscare",   Default = false, Tooltip = "Disables the jumpscare from 'Glitch'" })
Visuals_Effects:AddToggle("DisableTimothyJumpscare",  { Text = "Disable Timothy Jumpscare",  Default = false, Tooltip = "Disables the jumpscare from 'Timothy'" })
Visuals_Effects:AddToggle("DisableVoidJumpscare",     { Text = "Disable Void Jumpscare",     Default = false, Tooltip = "Disables the jumpscare from 'Void'" })
Visuals_Effects:AddDivider()
Visuals_Effects:AddToggle("DisableHideVignette",      { Text = "Disable Hide Vignette",      Default = false, Tooltip = "Disables the hiding screen effect." })
Visuals_Effects:AddToggle("DisableFiredampEffect",    { Text = "Disable Firedamp Effect",    Default = false, Tooltip = "Disables the firedamp screen effect." })
Visuals_Effects:AddToggle("DisableEntityJumpscares",  { Text = "Disable Entity Jumpscares",  Default = false, Tooltip = "Disables jumpscares from entities like Rush and Ambush." })

Toggles.DisableGlitchJumpscare:OnChanged(function() SyncEntityRemoval() end)
Toggles.DisableTimothyJumpscare:OnChanged(function() SyncEntityRemoval() end)
Toggles.DisableVoidJumpscare:OnChanged(function() SyncEntityRemoval() end)
Toggles.DisableHideVignette:OnChanged(function(Value)
	local Vignette = Global.MainUI:FindFirstChild("HideVignette") or Global.MainUI.MainFrame:FindFirstChild("HideVignette")
	if Vignette then Vignette.Image = Value and "Disabled" or "rbxassetid://6100076320" end
end)
Toggles.DisableFiredampEffect:OnChanged(function(Value)
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
Visuals_Mspaint = Tabs.Visuals:AddLeftGroupbox("Mspaint")
Visuals_Mspaint:AddButton({
	Text = "Verry Good Mspaint Button", Tooltip = "Press this if you dare",
	Func = function()
		gui.Enabled = not gui.Enabled
		if gui.Enabled then Functions.Notify({ Title = "Upio", Body = "You just got Upioned"}) end
	end
})

Visuals_RightTab     = Tabs.Visuals:AddRightTabbox("Entities / Settings")
Visuals_Entities     = Visuals_RightTab:AddTab("Entities")
Visuals_EntitySettings = Visuals_RightTab:AddTab("Settings")

Visuals_Entities:AddDropdown("EntityList", {
	Text = "Entity List",
	Values = { "Rush","Ambush","Eyes","Halt","Blitz","Lookman","Gloombat Swarm","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Monument","Scribbles","Bash","Electric Puddle","AR0xMBUSH","RNIUSHCG==" },
	Multi = true, AllowNull = true
})
Visuals_Entities:AddToggle("NotifyEntities",    { Text = "Notify Entities",    Default = false, Tooltip = "Sends a notification when an entity spawns." })
Visuals_Entities:AddToggle("NotifyRoomAnomalies", { Text = "Notify Room Anomalies", Default = true, Tooltip = "Notifies you of any room anomaly (Dupe, Monument, Currents, Server Carts, Scribble, Giggle, etc.) as soon as a new room loads." })
Visuals_Entities:AddDivider()

local ItemsToNotify = {}
for Index, Name in pairs(ItemNames) do
	if not table.find(ItemsToNotify, Name) then
		table.insert(ItemsToNotify, Name)
	end
end

Visuals_Entities:AddToggle("NotifyLadder",      { Text = "Notify Ladder Spawns", Default = false, Tooltip = "Notifies when a ladder spawns" })
Visuals_Entities:AddToggle("NotifyLibraryCode", { Text = "Notify Library Code", Default = false, Tooltip = "Automatically solves the code for the library padlock." })
Visuals_Entities:AddToggle("NotifyOxygen",      { Text = "Notify Oxygen Level", Default = false, Tooltip = "Shows how much oxygen you have remaining." })
Visuals_Entities:AddToggle("NotifyHasteTime",   { Text = "Notify Haste Time",   Default = false, Tooltip = "Shows how much time you have remaining before 'Haste' spawns." })

Global.LibraryCodeFound = false
Toggles.NotifyLibraryCode:OnChanged(function(Value)
	if Value then
		local Code = Functions.GetLibraryCode()
		if Code and not Code:find("_") and not Global.LibraryCodeFound and CurrentRooms:FindFirstChild("50") then
			local Lock = Services.Workspace:FindFirstChild("Padlock", true)
			Functions.Notify({ Title = "Padlock code found!", Body = "The code is: '" .. Code .. "'", Time = Toggles.NotifyKeepNotifications.Value and Lock or 15 })
			Global.LibraryCodeFound = true
		end
	end
end)

Visuals_EntitySettings:AddToggle("EntityChatToggle", { Text = "Notify Chat", Default = false, Tooltip = "Sends a message in the chat when an entity spawns." })
Visuals_EntitySettings:AddInput("EntityChatMessage", { Text = "Message", Default = "spawned!", Numeric = false, Placeholder = "Message" })
Visuals_EntitySettings:AddDivider()
Visuals_EntitySettings:AddDropdown("NotifyStyle", { Text = "Notify Style", Values = { "mstudio45", "LolhaxV3", "Library" }, Default = 1 })
Visuals_EntitySettings:AddDropdown("NotifySide", { Text = "Notify Side for LolhaxV3 Notify", Values = {"Center", "Right" }, Default = 1 })
Visuals_EntitySettings:AddSlider("NotifySoundVolume", { Text = "Sound Volume", Min = 0, Max = 10, Default = 3, Rounding = 1 })
Visuals_EntitySettings:AddToggle("NotifyPlaySound", { Text = "Play Sound", Default = true, Tooltip = "Makes notifications play an alert sound." })
Visuals_EntitySettings:AddToggle("NotifyKeepNotifications", { Text = "Keep Notifications", Default = false, Tooltip = "Certain notifications will stay on screen until they are no longer needed." })
Visuals_EntitySettings:AddButton({ Text = "Test Notification", DoubleClick = false, Tooltip = "Sends a test notifcation, so you can see how your settings look.", Func = function()
	Functions.Notify({Title = "This is a test."})
end})	

Visuals_ESP          = Tabs.Visuals:AddRightTabbox("ESP/Settings")
Visuals_ESP_Toggles  = Visuals_ESP:AddTab("ESP")
Visuals_ESP_Settings = Visuals_ESP:AddTab("Settings")

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

Visuals_ESP_Toggles:AddDropdown("EntityESPOptions",     { 
	Text = "Entity List",
	Values = { "Rush","Ambush","Eyes","Dupe","Figure","Blitz","Lookman","Snare","Giggle","Grumble","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Mandrake Hole","Monument","Bramble","Scribbles","Bash","Server Cart","Electric Puddle","Vacuum Sideroom","Gloombat Eggs","AR0xMBUSH","RNIUSHCG==" },
	Default = { "Rush","Ambush","Eyes","Dupe","Figure","Blitz","Lookman","Snare","Giggle","Grumble","A-60","A-120","Sally","Jeff the Killer","Groundskeeper","Mandrake Hole","Monument","Bramble","Scribbles","Bash","Server Cart","Electric Puddle","Vacuum Sideroom","Gloombat Eggs" },
	Multi = true,
	AllowNull = true
})
Visuals_ESP_Toggles:AddToggle("EntityESPToggle",     { Text = "Entities",      Default = false, Tooltip = "Highlights all entities that spawn." })
Visuals_ESP_Toggles:AddDivider()
Visuals_ESP_Toggles:AddToggle("DoorESPToggle",       { Text = "Doors",        Default = false, Tooltip = "Highlights the next door." })
Visuals_ESP_Toggles:AddToggle("PlayerESPToggle",     { Text = "Players",      Default = false, Tooltip = "Highlights other players." })
Visuals_ESP_Toggles:AddToggle("ObjectiveESPToggle", { Text = "Objectives", Default = false, Tooltip = "Highlights all objects required to progress." })
Visuals_ESP_Toggles:AddDivider()
Visuals_ESP_Toggles:AddToggle("HidingSpotESPToggle", { Text = "Hiding Spots", Default = false, Tooltip = "Highlights places where you can hide from entities" })
Visuals_ESP_Toggles:AddToggle("ChestESPToggle",      { Text = "Chests",       Default = false, Tooltip = "Highlights objects that can contain loot." })
Visuals_ESP_Toggles:AddToggle("ItemESPToggle",       { Text = "Items",        Default = false, Tooltip = "Highlights all collectable items/consumables." })
Visuals_ESP_Toggles:AddToggle("CurrencyESPToggle",   { Text = "Currency",     Default = false, Tooltip = "Highlights all currency that spawns." })
Visuals_ESP_Toggles:AddToggle("LadderESPToggle",     { Text = "Ladders",      Default = false, Tooltip = "Highlights ladders that can be used to disable the anticheat." })
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
}

Toggles.ObjectiveESPToggle:OnChanged(function(Value)
	for _, Object in Objects.Objectives do
		if Value then
			local Label = ObjectiveLabels[Object.Name]
			if Object.Name == "TimerLever" then
				Label = "Time Lever"
			elseif Object.Name == "MinesAnchor" then
				Label = "Anchor [" .. Object:WaitForChild("Sign").TextLabel.Text .. "]"
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
	Snare = "Snare", GrumbleRig = "Grumble",
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
	Rush = true, Ambush = true, Eyes = true, Blitz = true, Lookman = true, ["A-60"] = true, ["A-120"] = true, Sally = true, ["Jeff The Killer"] = true, Monument = true, Scribbles = true, Bash = true, ["Server Cart"] = true, ["Electric Puddle"] = true, ["Vacuum Sideroom"] = true, ["Gloombat Eggs"] = true, ["AR0xMBUSH"] = true, ["RNIUSHCG=="] = true
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
	for _, Object in Objects.Ladders do
		if Value then
			Functions.Notify({ Title = "Ladder Notify", Body = "Ladder has spawned in Room " .. (Object:GetAttribute("ParentRoom") or "?") .. "." })
		end
	end
end)
Options.LadderESPColor:OnChanged(function(Value)
	for _, Object in Objects.Ladders do mstudio45.ESPLibrary:UpdateObjectColor(Object, Value) end
end)

Visuals_ESP_Settings:AddToggle("ESPRainbow",     { Text = "Rainbow Effect", Default = false, Tooltip = "Makes the esp objects change colour like a rainbow." })
Visuals_ESP_Settings:AddToggle("ESPShowDistance",{ Text = "Show Distance",  Default = true,  Tooltip = "Shows how far away your character is from the object." })
Visuals_ESP_Settings:AddDivider()
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
Visuals_ESP_Settings:AddDivider()
Visuals_ESP_Settings:AddDropdown("ESPTracersOrigin",  { Text = "Tracer Origin", Values = { "Bottom","Center","Top","Mouse" }, Default = 1 })
Visuals_ESP_Settings:AddSlider("ESPTracerThickness",  { Text = "Tracer Thickness", Min = 0.5, Max = 2, Default = 0.75, Rounding = 2, Compact = true })
Visuals_ESP_Settings:AddToggle("ESPTracersToggle",    { Text = "Enable Tracers", Default = false, Tooltip = "Draws a line to highlighted objects." })
Visuals_ESP_Settings:AddDivider()
Visuals_ESP_Settings:AddSlider("ESPArrowsRadius",     { Text = "Arrow Radius", Min = 100, Max = 500, Default = 250, Rounding = 0, Compact = true })
Visuals_ESP_Settings:AddToggle("ESPArrowsToggle",     { Text = "Enable Arrows", Default = false, Tooltip = "Shows arrow that point to off-screen objects." })

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

Floors_Automation = Tabs.Floors:AddRightGroupbox("Automation")
Floors_Automation:AddToggle("MinecartTeleport", {
    Text = "Minecart Teleport",
    Default = false,
    Tooltip = "Instantly completes the minecart chase.",
    Disabled = (not Functions.CheckEnv("require")),
    DisabledTooltip = (not getgenv().it)
        and Global.PayedFeatueMessage
        or (not Functions.CheckEnv("require"))
        and Global.ExecutorIssueMessage
        or "Unknown reason sorry dawg - george"
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
Floors_Completion = Tabs.Floors:AddRightGroupbox("Completion")
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
Floors_Visuals = Tabs.Floors:AddLeftGroupbox("Visuals")
Floors_Visuals:AddToggle("ShowSeekPathToggle", {
	Text = "Show Seek Path", Default = false, Tooltip = "Shows you the correct path in seek chases.",
	Risky = Floor ~= "Mines"
})
Toggles.ShowSeekPathToggle:AddColorPicker("ShowSeekPathColor", { Text = "Seek Path", Default = Color3.fromRGB(0, 255, 0), Transparency = 0 })

Floors_Bypass = Tabs.Floors:AddLeftGroupbox("Bypass")
Floors_Bypass:AddToggle("RemoveSeekTrigger", {
    Text = "Delete Seek Trigger",
    Default = false,
    Tooltip = "Diables the 'Seek' chase trigger.",
    Risky = not (Floor == "Fools" or Floor == "OldHotel"),
    Disabled = (not Functions.CheckEnv("firetouchinterest")),
    DisabledTooltip = (not getgenv().it)
        and Global.PayedFeatueMessage
        or (not Functions.CheckEnv("firetouchinterest"))
        and Global.ExecutorIssueMessage
        or "Unknown reason sorry dawg - george"
})
Floors_Bypass:AddToggle("RemoveFigure", {
    Text = "Delete Figure",
    Default = false,
    Tooltip = "Completely removes the entity 'Figure' (doesn't always work).",
    Risky = not (Floor == "Fools" or Floor == "OldHotel" or Floor == "Mines"),
    Disabled = (not Functions.CheckEnv("isnetworkowner")),-- or (not getgenv().it),
    DisabledTooltip = (not getgenv().it)
        and Global.PayedFeatueMessage
        or (not Functions.CheckEnv("isnetworkowner"))
        and Global.ExecutorIssueMessage
        or "Unknown reason sorry dawg - george"
})

Floors_Bypass:AddToggle("AutoRevive", {
	Text = "Infinite Revives", Default = false, Tooltip = "Automatically revives after dying, with unlimited respawns.",
	Risky = not (Floor == "Fools" or Floor == "OldHotel")
})
Floors_Bypass:AddDivider()
Floors_Bypass:AddToggle("RemoveBasementGate",  { Text = "Remove Basement Gate",   Default = false, Tooltip = "Removes the gate from basement rooms.",            Risky = not (Floor == "Fools" or Floor == "OldHotel") })
Floors_Bypass:AddToggle("RemovePaintingsDoor", { Text = "Remove Paintings Door",  Default = false, Tooltip = "Removes the fireplace doors from painting rooms.", Risky = not (Floor == "Fools" or Floor == "OldHotel") })
Floors_Bypass:AddToggle("RemoveSkeletonDoor",  { Text = "Remove Skeleton Door",   Default = false, Tooltip = "Removes the skeleton door from the infirmary.",    Risky = Floor ~= "Fools" })
Troll_Left = Tabs.Troll:AddLeftGroupbox("Trolling/Fun")
		
local TriggerFigureLooping = false
local TriggerFigureThread
local PlayersService = game:GetService("Players")

Troll_Left:AddToggle("LoopTriggerFigure", {
	Text = "Trigger Figure",
	Default = false,
	Tooltip = "Triggers Figure.",
	Risky = true,
	--Disabled = (not getgenv().it),
	DisabledTooltip = Global.PayedFeatueMessage
})
Self_Misc:AddDivider()
Troll_Left:AddDropdown("PlayerListToTrigger", {
	Text = "Players",
	Values = {},
	Default = 0,
	Multi = true,
})

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
		
Troll_Left:AddToggle("BreakDoorsAnims", {
	Text = "Break Doors Animation (FE)",
	Default = false,
	Tooltip = "Breaks Doors that are opened.",
	DisabledTooltip = Global.PayedFeatueMessage
})

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
	"MainHandler", "JumpHandler", "SlideHandler", "LibraryCodeHandler1", "LibraryCodeHandler2",
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
	CollisionPart  = NewCharacter:FindFirstChild("CollisionPart") or NewCharacter:FindFirstChild("Collision")
	CollisionClone = Collision:Clone()
	CollisionClone.Parent = NewCharacter
	CollisionClone.Name = "CollisionClone"
	CollisionClone.Massless = true

	CollisionPartClone = CollisionPart:Clone()
	CollisionPartClone.Parent = NewCharacter
	CollisionPartClone.Name = "CollisionPartClone"
	CollisionPartClone.CanCollide = false
	CollisionPartClone.Massless = true

	if CollisionPartClone:FindFirstChild("CollisionCrouch") then
		CollisionPartClone.CollisionCrouch:Destroy()
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
	Global.OriginalC1 = Character.LowerTorso.Root.C1

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	Conns.MainHandler = Services.RunService.RenderStepped:Connect(function()
		if Services.Workspace:FindFirstChild("Camera") then
			Camera = Services.Workspace:FindFirstChild("Camera")
		end

		if Toggles.WalkSpeedToggle.Value then
			Humanoid.WalkSpeed = Functions.GetCurrentSpeed() + Options.WalkSpeedSlider.Value
		end

		if Global.Lagging or (Options.WalkSpeedSlider.Value <= 6 and Options.FlySpeed.Value <= 21) then
			CollisionPartClone.Massless = true
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
			Global.MainUI.Statistics.Death.Text = "Died to mstudio45"
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

		for _, Part in Character:GetChildren() do
			if Part:IsA("BasePart") then Part.CanCollide = false end
		end

		if LocalPlayer:GetAttribute("Alive") == true then
			Services.SoundService:WaitForChild("Main").Volume = 1
		end

		if Floor == "OldHotel" or Floor == "Fools" then
			local SpoofOffset = Toggles.PositionSpoof.Value and Functions.GetNearestEntity() and 200 or 0
			Global.SpoofOffset = SpoofOffset
			Collision.Position = RootPart.Position + Vector3.new(0, SpoofOffset, 0)
			Collision.CanCollide = false
			if Floor == "Fools" then
				Collision.CollisionCrouch.CanCollide = false
				CollisionClone.CollisionCrouch.CanCollide = false
			end
			RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.TeleportManipulationToggle.Value)
		else
			Collision.CanCollide = false
			if Collision:FindFirstChild("CollisionCrouch") then Collision.CollisionCrouch.CanCollide = false end

			if CollisionClone:FindFirstChild("CollisionCrouch") then
				local IsCrouch = Functions.IsCrouching()
				CollisionClone.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.TeleportManipulationToggle.Value or IsCrouch)
				CollisionClone.CollisionCrouch.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.TeleportManipulationToggle.Value or not IsCrouch)
			else
				RootPart.CanCollide = not (Toggles.NoclipToggle.Value or Toggles.TeleportManipulationToggle.Value)
			end

			if Character:FindFirstChild("LowerTorso") and Character.LowerTorso:FindFirstChild("Root") then
				Character.LowerTorso.Root.C1 = Global.OriginalC1 * CFrame.new(0, Toggles.PositionSpoof.Value and -2.346 or 0, 0)
			end

			local SpoofY = Toggles.PositionSpoof.Value and 2.328 or 0.18
			Collision.Position     = RootPart.Position + Vector3.new(0, SpoofY, 0)
			CollisionPart.Position = RootPart.Position + Vector3.new(0, SpoofY, 0)

			if Collision:FindFirstChild("CollisionCrouch") and CollisionClone:FindFirstChild("CollisionCrouch") then
				local CrouchY = Toggles.PositionSpoof.Value and 1.328 or -0.982
				Collision.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, CrouchY, 0)
				CollisionClone.CollisionCrouch.CollisionGroup = Collision.CollisionCrouch.CollisionGroup
			end
			if CollisionClone:FindFirstChild("CollisionCrouch") then
				CollisionClone.CollisionCrouch.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 0.75 or -0.982, 0)
			end
		end

		CollisionClone.CollisionGroup = Collision.CollisionGroup
		CollisionClone.Position = RootPart.Position + Vector3.new(0, Toggles.PositionSpoof.Value and 1.75 or 0.18, 0)

		if Toggles.TeleportManipulationToggle.Value and Options.TeleportManipulationMode.Value == "Velocity" then
			Global.ManipulateBody.Parent = RootPart
			Global.ManipulateBody.Velocity = RootPart.CFrame.LookVector * 2.25
		else
			Global.ManipulateBody.Parent = nil
		end

		if Toggles.TeleportManipulationToggle.Value and Options.TeleportManipulationMode.Value == "Pivot" and Floor ~= "Fools" and Floor ~= "OldHotel" then
			Character:PivotTo(Camera:GetPivot() * CFrame.new(0, 0, 2560))
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
	if Toggles.PositionSpoof.Value and Floor ~= "Fools" and Floor ~= "OldHotel" then
		RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -2.346, 0)
		Humanoid.HipHeight = 0.05
		RemotesFolder.Crouch:FireServer(true, true)
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

	if Name == "KeyObtain" then
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
		local function SetupWaterESP(waterModel)
			if not waterModel or waterModel:GetAttribute("WaterESPHandled") then return end
			waterModel:SetAttribute("WaterESPHandled", true)

			local puddles = {}
			for _, desc in ipairs(waterModel:GetDescendants()) do
				if desc.Name == "Puddle" and desc:IsA("BasePart") and not table.find(puddles, desc) then
					table.insert(puddles, desc)
				end
			end

			if #puddles == 0 and waterModel:IsA("BasePart") then
				table.insert(puddles, waterModel)
			end

			if #puddles == 0 then return end

			local function UpdateState()
				local isElec = waterModel:GetAttribute("Electrified")
				if isElec == nil and #puddles > 0 and puddles[1].Parent then
					isElec = puddles[1].Parent:GetAttribute("Electrified")
				end
				if isElec == nil and #puddles > 0 then
					isElec = puddles[1]:GetAttribute("Electrified")
				end

				local statusText = (isElec == true) and "Electric Puddle [Active]" or "Electric Puddle [Safe]"
				local statusColor = (isElec == true) and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(80, 220, 100)

				for idx, puddlePart in ipairs(puddles) do
					if not table.find(Objects.Entities, puddlePart) then
						table.insert(Objects.Entities, puddlePart)
					end
					local labelText = (idx == 1) and statusText or " "
					puddlePart:SetAttribute("StatusText", labelText)
					puddlePart:SetAttribute("StatusColor", statusColor)

					Functions.AddESP({ Object = puddlePart, Text = labelText, Color = statusColor }, true)
					if mstudio45 and mstudio45.ESPLibrary then
						pcall(function()
							mstudio45.ESPLibrary:UpdateObjectText(puddlePart, labelText)
							mstudio45.ESPLibrary:UpdateObjectColor(puddlePart, statusColor)
						end)
					end
				end
			end

			UpdateState()

			local conn1 = waterModel:GetAttributeChangedSignal("Electrified"):Connect(UpdateState)
			table.insert(Conns, conn1)
			if #puddles > 0 and puddles[1].Parent then
				local conn2 = puddles[1].Parent:GetAttributeChangedSignal("Electrified"):Connect(UpdateState)
				table.insert(Conns, conn2)
			end
		end

		local waterObj = Object
		if Object.Name:match("^Pool%d+") or Object.Name == "Puddle" then
			if Object.Parent and (Object.Parent.Name == "Water" or Object.Parent.Name:find("Current")) then
				waterObj = Object.Parent
			elseif Object.Parent and Object.Parent.Parent and (Object.Parent.Parent.Name == "Water" or Object.Parent.Parent.Name:find("Current")) then
				waterObj = Object.Parent.Parent
			end
		end

		SetupWaterESP(waterObj)
		table.insert(Objects.Entities, Object)
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
	if not TrackedObjects[Object.Name] and not Object.Name:match("^Pool%d+") and Object.ClassName ~= "ProximityPrompt" and Object.Parent ~= CurrentRooms and not ItemNames[Object.Name] then
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

local RusherNames = { Rush=true, Ambush=true, Eyes=true, Lookman=true, Blitz=true, ["A-60"]=true, ["A-120"]=true, AR0xMBUSH=true, ["RNIUSHCG=="]=true, ["Custom Entity"]=true }

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
Functions.Notify({ Title = "Successfully loaded", Body = "Press RightControl to Close/Open the menu"})
