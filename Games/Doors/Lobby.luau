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
    if mstudio45 and mstudio45.Environment.cloneref then
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

local NotificationLibrary = {
	LiveNotifications = 0,
    Notifications = 1
}

local Container = Instance.new("ScreenGui")
Container.Name = (mstudio45.ESPLibrary and type(mstudio45.ESPLibrary.GenerateRandomString) == "function" and mstudio45.ESPLibrary:GenerateRandomString()) or "mstudio45_Lobby_UI"
Container.Parent = GetHiddenContainer()
Container.DisplayOrder = 32767
Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if not Library.Scheme then
    Library.Scheme = setmetatable({}, {
        __index = function(self, Name)
            return Library[Name]
        end
    })
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
Functions.Notify = function(Settings)
    local Container
    if Functions.CheckCompatability({"gethui"}) then
        Container = mstudio45.Environment.gethui()
    else
        Container = Services.CoreGui
    end

		local Sound = Instance.new("Sound")
		Sound.SoundId = "rbxassetid://8784885431"
		Sound.Volume = 3
		Sound.PlayOnRemove = true
		Sound.Parent = Container
		Sound:Destroy()

        NotificationLibrary:Notify(
            Settings.Title,
            Settings.Body,
            Settings.Time or 5
        )

end

Library.Notify = function(Data, Body, Time)
    Functions.Notify({Title = Body, Time = Time or 5})
end

Functions.CheckElevators = function()
    local TargetFound = false
	if not Toggles.AutoJoinElevator.Value then
		return
	end
	local TargetCharacter
	if typeof(Options.AutoJoinElevatorTarget.Value) == "Instance" then
		TargetCharacter = Options.AutoJoinElevatorTarget.Value.Character
	elseif typeof(Options.AutoJoinElevatorTarget.Value) == "string" then
		TargetCharacter = Services.Players:FindFirstChild(Options.AutoJoinElevatorTarget.Value).Character
	end

	for Index, Elevator in pairs(Services.Workspace.Lobby.LobbyElevators:GetChildren()) do
		if TargetCharacter and Elevator and TargetCharacter:GetAttribute("InGameElevator") and Elevator:GetAttribute("ID") and Elevator:GetAttribute("ID") == TargetCharacter:GetAttribute("InGameElevator") then
			TargetFound = true
			RemotesFolder.ElevatorJoin:FireServer(Elevator)
        end
    end
	if TargetFound == false then
		RemotesFolder.ElevatorExit:FireServer()
	end
end

Globals.RedeemingCodes = false
Globals.CodesList = {
    "67",
	"54",
	"41",
	"CHEDDAR BALLS",
	"XQC",
	"PENGUINZ0",
	"KREEKCRAFT",
	"ISHOWSPEED",
	"DANTDM",
	"KUBZ SCOUTS",
	"FIND THE TROLLFACES",
	"THINKNOODLES",
	"W",
	"RAGDOLL UNIVERSE",
	"RAGDOLL MAYHEM",
	"BIJUU MIKE",
	"8BITRYAN",
	"SCREECHSUCKS",
	"LORE",
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	"FIND THE TROLLFACES",
	"3rd",
	"LAZYDEVS",
	"RAGDOLL COMBAT",
	"VOCAB HAVOC",
	"PATHSWAP",
	"JUMP OVER THE BRICK"
}
Globals.UnlockedBadges = {}

General_Character = Tabs.General:AddLeftGroupbox("Character")

General_Character:AddToggle("AutoJoinElevator", {
    Text = "Auto Join Elevator",
    Default = false,
    Tooltip = "Automatically joins the selected player's elevator."
})

General_Character:AddDropdown("AutoJoinElevatorTarget", {
    Text = "Target",
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Searchable = true
})
General_Character:AddDivider()
General_Character:AddToggle("TwerkDance", { 
    Text = "Twerk", 
    Default = false, 
    Tooltip = "just Twerk." 
})
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
General_Automation = Tabs.General:AddLeftGroupbox("Automation")

General_Automation:AddToggle("CycleAchievements", {
    Text = "Cycle Achievements",
    Default = false,
    Tooltip = "Rapidly equips a random badge."
})

General_Automation:AddSlider("CycleAchievementsDelay", {
    Text = "Cycle Delay",
    Min = 0,
    Max = 1,
    Default = 0.1,
    Rounding = 2,
    Compact = true
})

General_Automation:AddDivider()

General_Automation:AddButton("Redeem All Codes", function()
    if Globals.RedeemingCodes then
        return
    end

    Functions.Notify({Title = "Redeeming " .. #Globals.CodesList .. " codes.", Body = "Please wait."})
    Globals.RedeemingCodes = true
    for Index, Code in pairs(Globals.CodesList) do
        RemotesFolder.ShopCode:FireServer(Code)
        task.wait(5.1)
    end
end)

for Index, Frame in pairs(LocalPlayer.PlayerGui.MainUI.LobbyFrame.Achievements.List:GetChildren()) do
	if Frame:IsA("ImageButton") and Frame.ImageTransparency == 0 then
		table.insert(Globals.UnlockedBadges, Frame.Name)
	end
end

Con.BadgeAddedConnection = LocalPlayer.PlayerGui.MainUI.LobbyFrame.Achievements.List.ChildAdded:Connect(function(Frame)
	Services.RunService.Heartbeat:Wait()
	if Frame:IsA("ImageButton") and Frame.ImageTransparency == 0 then
		table.insert(Globals.UnlockedBadges, Frame.Name)
	end
end)

Globals.LastBadgeChange = tick()
Globals.LastElevatorCheck = tick()
Con.MainConnection = Services.RunService.Heartbeat:Connect(function()
	if tick() - Globals.LastElevatorCheck > 0.25 then
    	Functions.CheckElevators()
		Globals.LastElevatorCheck = tick()
	end

    if Toggles.CycleAchievements.Value and tick() - Globals.LastBadgeChange > Options.CycleAchievementsDelay.Value then
        local Badge = Globals.UnlockedBadges[math.random(1, #Globals.UnlockedBadges)]
        if Badge == PreviousBadge then
            while task.wait() do
				local NewBadge = Globals.UnlockedBadges[math.random(1, #Globals.UnlockedBadges)]
				if NewBadge ~= PreviousBadge then
					Badge = NewBadge
					break
				end
			end
		end
		for Index, Frame in pairs(LocalPlayer.PlayerGui.MainUI.LobbyFrame.Achievements.List:GetChildren()) do
			if Frame:IsA("ImageButton") and Frame.ImageTransparency == 0 then
				LocalPlayer.PlayerGui.MainUI.LobbyFrame.Achievements.List:FindFirstChild(Frame.Name).Icons.Star.Visible = false
			end
		end
		RemotesFolder:WaitForChild("FlexAchievement"):FireServer(Badge)
		PreviousBadge = Badge
		LocalPlayer.PlayerGui.MainUI.LobbyFrame.Achievements.List:FindFirstChild(Badge).Icons.Star.Visible = true

        Globals.LastBadgeChange = tick()
	end
end)

General_CreateElevator = Tabs.General:AddRightGroupbox("Create Elavotr")
General_CreateElevator:AddSlider("AmountOfPlayers", {
    Text = "Amount Of Players",
    Min = 1,
    Max = 50,
    Default = 1,
    Rounding = 0,
    Compact = true
})
General_CreateElevator:AddLabel("With Progress", true)
General_CreateElevator:AddButton({
	Text = "The Hotel",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Hotel",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "The Mines",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Mines",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "The Backdoor",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Backdoor",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "The Rooms",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Rooms",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "The Outdoors",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Garden",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddLabel("Visuals", true)

General_CreateElevator:AddButton({
	Text = "Daily Run",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
			Mods = {},
			Settings = {},
			Destination = "Daily",
			FriendsOnly = false,
			MaxPlayers = Options.AmountOfPlayers.Value
		})
	end
})

General_CreateElevator:AddButton({
	Text = "Cringles Workshop",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "CringlesWorkshop",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "Battle Mode",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Party",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "Retro Mode",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Retro",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "Rush Mode",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "Fools26",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "Hotel-",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "BeforePlus",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "Super Hard Mode",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {},
        	Destination = "SuperHardMode",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddLabel("Without Progress", true)

General_CreateElevator:AddButton({
	Text = "The Rooms",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {
				"AdminPanel"
			},
        	Settings = {},
        	Destination = "Rooms",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddButton({
	Text = "The Outdoors",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {
				"AdminPanel"
			},
        	Settings = {},
        	Destination = "Garden",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})

General_CreateElevator:AddLabel("Challenges", true)
General_CreateElevator:AddButton({
	Text = "Hotel Hell",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        Mods = {
            "PlayerHealthLess",
            "Gloombat",
            "RoomsA90",
            "EntitiesMost",
            "EyesLevel2",
            "DupeMost",
            "BackdoorVacuum",
            "BackdoorLookman",
            "NoKeySound",
            "BackdoorRush",
            "EyesMore",
            "Dread",
            "FigureFaster",
            "RushMore",
            "LockMost",
            "FiredampMost"
        },
        	Settings = {},
        	Destination = "Hotel",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})
General_CreateElevator:AddButton({
	Text = "Not Five Stars",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        Mods = {
            "PlayerHealthLess",
            "Gloombat",
            "NoKeySound",
            "PlayerLessSlots",
            "GoldSpawnNone",
            "LockMost"
        },
        	Settings = {},
        	Destination = "Hotel",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})
General_CreateElevator:AddButton({
	Text = "A hard Place",
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
        	Destination = "Mines",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})
General_CreateElevator:AddButton({
	Text = "Rocky Road",
	DoubleClick = false,
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {
			"PlayerHealthLess",
            "PlayerLessSlots",
            "GoldSpawnNone",
            "RushQuiet",
            "FiredampMost"
			},
        	Settings = {},
        	Destination = "Mines",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers.Value
    	})
	end
})
Library:OnUnload(function()
    Con.MainConnection:Disconnect()
        if track then
            track:Stop()
        end
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
