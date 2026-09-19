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

-- Compatibility & Executor Helpers
local queue_on_teleport = (typeof(queue_on_teleport) == "function" and queue_on_teleport)
    or (typeof(queueonteleport) == "function" and queueonteleport)
    or (syn and typeof(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)

local clear_teleport_queue = (typeof(clear_teleport_queue) == "function" and clear_teleport_queue)
    or (typeof(clearteleportqueue) == "function" and clearteleportqueue)
    or (syn and typeof(syn.clear_teleport_queue) == "function" and syn.clear_teleport_queue)

local isnetworkowner = (typeof(isnetworkowner) == "function" and isnetworkowner)

Functions.GetFunction = function(name, ignoreExec, scriptInstance)
    local success, result = pcall(function()
        if filtergc then
            local res = filtergc("function", {
                Name = name,
                IgnoreExecutor = not ignoreExec,
            }, true)
            if typeof(res) == "table" and typeof(scriptInstance) == "Instance" and scriptInstance:IsA("Script") then
                local src = scriptInstance:GetFullName()
                for _, fn in ipairs(res) do
                    local info = debug.getinfo(fn)
                    if info and (info.short_src == src or info.source == src) then return fn end
                end
            end
            return type(res) == "table" and res[1] or res
        end
        if getgc then
            for _, fn in pairs(getgc(false)) do
                if type(fn) == "function" and (not islclosure or islclosure(fn)) and (not isexecutorclosure or not isexecutorclosure(fn)) then
                    local info = debug.getinfo(fn)
                    if info and info.name == name then
                        return fn
                    end
                end
            end
        end
        return nil
    end)
    return (success and result) or nil
end

-- Teleport Observer Handler for Bloxfest Battle Mode
if writefile and readfile and queue_on_teleport and clear_teleport_queue then
    pcall(function()
        writefile("teleporthandler", [[if game.PlaceId ~= 6839171747 then return end
function GetFunction(fn: string, e: boolean, fs: Instance): (any) -> any
	local success, result = pcall(function()
		return filtergc("function", {
			Name = fn,
			Source = fs and (typeof(fs) == "string" and fs or typeof(fs) == "Instance" and fs.Name),
			IgnoreExecutor = not e,
		}, true)
	end)
	return success and result
end
local players = game:GetService("Players")
local player = players.LocalPlayer
if not player then
    players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = players.LocalPlayer
end
local tpdata = game:GetService("TeleportService"):GetLocalPlayerTeleportData()
if tpdata and tpdata.Settings and tpdata.Settings.cMode == "true" and tpdata.Host == player.UserId then
    player:SetAttribute("Observer", true)
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	workspace.CurrentRooms.ChildAdded:Once(function()
		replicatesignal(player.Kill)
	end)
	task.wait()
	while not pcall(function()GetFunction("healthChanged")(0)end)do task.wait()end
end
queue_on_teleport(readfile("teleporthandler"))]])
        local execute = readfile("teleporthandler")
        if execute and #execute > 0 then
            queue_on_teleport(execute)
        end
    end)
end

local PlayAnim = Functions.GetFunction("PlayAnim")
local AdjustAnim = Functions.GetFunction("AdjustAnim")
local AnimPlaying = Functions.GetFunction("AnimPlaying")
local StopAnim = Functions.GetFunction("StopAnim")

-- Obsidian loading screen: created before the window so AutoShow waits for it
if Library.ActiveLoading and Library.ActiveLoading.Destroyed ~= true then
    pcall(function() Library.ActiveLoading:Destroy() end)
end
local Loading = Library:CreateLoading({
    Title = "lolcheat V4",
    Icon = 98291729947083,
    TotalSteps = 4,
    ShowSidebar = true,
    AlwaysOnTop = true,
})
Loading:SetCurrentStep(1)
Loading:SetMessage("Loading lolcheat V4...")
Loading:SetDescription("fun fact: bomb.exe is loading...")
pcall(function()
    Loading.Sidebar:AddLabel("Game: DOORS LOBBY")
    Loading.Sidebar:AddLabel("Player: " .. LocalPlayer.Name)
    Loading.Sidebar:AddLabel("UI Library: Obsidian")
    if mstudio45.TotalExecutions then
        Loading.Sidebar:AddLabel("Total Executions: " .. mstudio45.TotalExecutions)
    end
end)
task.wait(1)

local Window = Library:CreateWindow({
    Title = "lolcheat V4",
    Footer = "Game: DOORS LOBBY | dsc.gg/PB9AHh6sub",
    Icon = 98291729947083,
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
    Practice = Window:AddTab("Practice", "target"),
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
	if toclipboard then toclipboard("https://dsc.gg/PB9AHh6sub") end
	Library:Notify("Discord invite copied.")
end)
MenuGroup:AddButton("Unload", function()
	Library:Unload()
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
		Notification.BackgroundColor3 = (Library.Scheme and Library.Scheme.BackgroundColor) or Color3.fromRGB(25, 25, 25)
		Notification.BackgroundTransparency = 0.4
		Notification.BorderSizePixel = 0
		Notification.Size = UDim2.new(NotifyScaleX, 0, 0, 50)

		Line.Name = "Line"
		Line.Parent = Notification
		Line.BackgroundColor3 = (Library.Scheme and Library.Scheme.AccentColor) or Color3.fromRGB(0, 120, 255)
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
		Warning.ImageColor3 = (Library.Scheme and Library.Scheme.AccentColor) or Color3.fromRGB(0, 120, 255)
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
		Title.TextColor3 = (Library.Scheme and Library.Scheme.FontColor) or Color3.fromRGB(255, 255, 255)
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
		Description.TextColor3 = (Library.Scheme and Library.Scheme.FontColor) or Color3.fromRGB(200, 200, 200)
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
    local C
    if Functions.CheckCompatability({"gethui"}) then
        C = mstudio45.Environment.gethui()
    else
        C = Services.CoreGui
    end

	local Sound = Instance.new("Sound")
	Sound.SoundId = "rbxassetid://8784885431"
	Sound.Volume = 3
	Sound.PlayOnRemove = true
	Sound.Parent = C
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

-- General Tab: Character
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

General_Character:AddToggle("JournalSpoof", {
    Text = "Journal Spoof",
    Default = false,
    Tooltip = "Makes you appear like you are reading the Journal.",
    Callback = function(value)
        pcall(function()
            RemotesFolder.JournalPresence:FireServer(value, false)
        end)
        if value then
            if PlayAnim then PlayAnim("Idle", 0.2, 1, 1) end
            if AnimPlaying and AdjustAnim and PlayAnim then
                if AnimPlaying("Open") then
                    AdjustAnim("Open", 1)
                elseif AnimPlaying("Close") then
                    AdjustAnim("Close", -1)
                else
                    PlayAnim("Open", 0, 1, 0.85)
                end
            end
        else
            if StopAnim then StopAnim("Idle", 0.1) end
            if AnimPlaying and AdjustAnim and PlayAnim then
                if AnimPlaying("Close") then
                    AdjustAnim("Close", 1)
                elseif AnimPlaying("Open") then
                    AdjustAnim("Open", -1)
                else
                    PlayAnim("Close", 0, 1, 0.9)
                end
            end
        end
    end
})

-- General Tab: Automation
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

-- General Tab: Utility
General_Utility = Tabs.General:AddLeftGroupbox("Utility")

local HideRankScript = [[while not game:GetService('ReplicatedStorage'):FindFirstChild('RemotesFolder') do
	task.wait()
end
while not game:GetService('ReplicatedStorage'):FindFirstChild('RemotesFolder'):FindFirstChild('CheckRank') do
	task.wait()
end
game:GetService('ReplicatedStorage').RemotesFolder.CheckRank:Destroy()]]

General_Utility:AddToggle("HideRank", {
    Text = "Hide Rank",
    Default = false,
    Tooltip = "Hides your rank in-game while the Hardstuck badge is equipped (requires queue_on_teleport).",
})

General_Utility:AddButton({
    Text = "Rejoin Server",
    DoubleClick = true,
    Tooltip = "Rejoins the current lobby server instance.",
    Func = function()
        if Toggles.HideRank and Toggles.HideRank.Value and queue_on_teleport then
            queue_on_teleport(HideRankScript)
        end
        Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end
})

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

-- General Tab: Create Elevator
General_CreateElevator = Tabs.General:AddRightGroupbox("Create Elevator")
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

General_CreateElevator:AddDivider()
General_CreateElevator:AddButton({
	Text = "Bloxfest Battle Elevator",
	DoubleClick = false,
	Tooltip = "Create battle elevator with observer powers (used for RB Battles)",
	Func = function()
		RemotesFolder.CreateElevator:FireServer({
        	Mods = {},
        	Settings = {
				cMode = "true"
			},
        	Destination = "Party",
        	FriendsOnly = false,
        	MaxPlayers = Options.AmountOfPlayers and Options.AmountOfPlayers.Value or 20
    	})
	end
})

-- General Tab: Troll & Exploits
General_Troll = Tabs.General:AddRightGroupbox("Troll & Exploits")

local UnanchoredParts = {}
local function UpdateUnanchoredParts()
    table.clear(UnanchoredParts)
    local Lobby = workspace:FindFirstChild("Lobby")
    if Lobby then
        for _, Part in ipairs(Lobby:GetDescendants()) do
            if Part:IsA("BasePart") and Part.Anchored == false then
                table.insert(UnanchoredParts, Part)
            end
        end
    end
end
UpdateUnanchoredParts()

General_Troll:AddToggle("FlingElevatorDoors", {
    Text = "Fling Elevator Doors [FE]",
    Default = false,
    Tooltip = "Flings unanchored elevator doors/parts around using network ownership. Seen by other players.",
    Callback = function(value)
        if value then
            UpdateUnanchoredParts()
        else
            for _, Door in ipairs(UnanchoredParts) do
                if Door and Door.Parent then
                    local bp = Door:FindFirstChild("DoorBreakVelocity")
                    if bp then bp:Destroy() end
                end
            end
        end
    end
})

Con.FlingDoorsConnection = Services.RunService.Heartbeat:Connect(function()
    if not (Toggles.FlingElevatorDoors and Toggles.FlingElevatorDoors.Value and isnetworkowner) then
        return
    end
    for _, Door in ipairs(UnanchoredParts) do
        if Door and Door.Parent then
            if isnetworkowner(Door) then
                local bp = Door:FindFirstChild("DoorBreakVelocity")
                if not bp then
                    bp = Instance.new("BodyPosition")
                    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bp.Name = "DoorBreakVelocity"
                    bp.Position = Vector3.new(math.random(-150, 150), math.random(-150, 150), math.random(-150, 150))
                    bp.Parent = Door
                else
                    bp.Position = Vector3.new(math.random(-150, 150), math.random(-150, 150), math.random(-150, 150))
                end
            else
                local bp = Door:FindFirstChild("DoorBreakVelocity")
                if bp then bp:Destroy() end
            end
        end
    end
end)

General_Troll:AddDivider()

local CrashFloodActive = false
General_Troll:AddToggle("CrashElevators", {
    Text = "Crash / Flood Elevators",
    Default = false,
    Tooltip = "Repeatedly floods the lobby with overflow modifier creation requests and unicode seeds.",
    Callback = function(value)
        CrashFloodActive = value
        if value then
            task.spawn(function()
                local coolseed = string.rep(utf8.char(2^16), 2^6)
                local floodMods = {
                    "AdminPanel", "Chaos3", "Gloombat", "NoGuidingLight", "PlayerCrouchSlow",
                    "TimothyMore", "ItemDurabilityLess", "AmbushMore", "ScreechLight", "ScreechFast",
                    "EyesTwice", "EyesLevel2", "AmbushFaster", "RushFaster", "BackdoorHaste",
                    "BackdoorVacuum", "BackdoorLookman", "SnareMoster", "NoKeySound", "BackdoorRush",
                    "LightsLess", "LeastHidingSpots", "Rooms", "Fog", "GiggleMore",
                    "StreamerMode", "DreadMost", "HideLevel2", "GoldSpawnNone", "FigureFaster",
                    "Slippery", "CustomSeed", "Voicelines", "RushLevel2", "RushQuiet",
                    "RushMore", "EntitiesMoster", "LockMore", "DupeMore", "FiredampMost",
                    "PlayerDamageMore"
                }
                while CrashFloodActive and Toggles.CrashElevators and Toggles.CrashElevators.Value do
                    for i = 1, 50 do
                        if not CrashFloodActive then break end
                        task.spawn(function()
                            RemotesFolder.CreateElevator:FireServer({
                                Mods = (i % 2 == 1 and floodMods) or { "AdminPanel" },
                                Settings = {
                                    seed = coolseed,
                                    cMode = coolseed
                                },
                                Destination = "Hotel",
                                FriendsOnly = false,
                                MaxPlayers = "50"
                            })
                            RemotesFolder.ElevatorExit:FireServer()
                        end)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- Practice Mode Scripts

local PracticeRansomScript = [=[
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end

			print("loading ransom practice...")

			type MainCaption = {
				Caption: TextLabel,
				Type: any,
				Smooth: boolean,
				Edit: (self: MainCaption, Text: string, Type: any?, Smooth: boolean?) -> MainCaption,
				Destroy: (self: MainCaption) -> (),
				Delay: (self: MainCaption, Delay: number) -> MainCaption
			}

			local BetterCaption = {
				Captions = {}
			}

			local TweenService = game:GetService("TweenService")
			local RunService = game:GetService("RunService")
			local SoundService = game:GetService("SoundService")

			local function NewSound(Sound: {[string]: any}?)
				local SoundObj = Instance.new("Sound", SoundService)
				for Prop, Value in Sound do
					SoundObj[Prop] = Value
				end
				SoundObj.Looped = false
				return {
					Playing = false,
					Play = function(self, destroy: boolean)
						self.Playing = true
						SoundObj:Play()
						if destroy then
							SoundObj.Ended:Wait()
							self:Destroy()
						end
					end,
					Stop = function(self)
						self.Playing = false
						SoundObj:Stop()
					end,
					Destroy = function(self)
						SoundObj:Destroy()
						self = nil
					end
				}
			end

			function BetterCaption:GetCaptionIndex(Caption: MainCaption): number?
				for Index, OtherCaption in self.Captions do
					if OtherCaption.Caption == Caption.Caption then
						return Index
					end
				end
				return
			end

			function BetterCaption:Caption(Text: string, Type: any?, Smooth: boolean?, Sound: {[string]: any}?): MainCaption
				Type = Type or "info"
				if Smooth == nil or typeof(Smooth) ~= "boolean" then
					Smooth = true 
				end
				Sound = typeof(Sound) == "table" and Sound or {
					SoundId = "rbxassetid://3848738542",
					Volume = .1,
					PlaybackSpeed = 1
				}
				Sound.SoundId = Sound.SoundId or "rbxassetid://3848738542"
				if Type ~= "thought" or game.ReplicatedStorage.GameData.Floor.Value ~= "Party" then
					if Text ~= "" and (Text ~= " " and Text ~= nil) then
						local Caption = BetterCaption.MainUI.MainFrame.NewCaption:Clone()
						Caption.Name = "LiveCaption"
						Caption.Visible = true
						Caption.Text = Text
						Caption.TextTransparency = 1
						Caption.TextStrokeTransparency = 1
						Caption.BackgroundTransparency = 1
						Caption.MaxVisibleGraphemes = Smooth and 0 or -1
						local function SetType(Type)
							local first = 1
							local second = 0
							local old = Caption:GetAttribute("Active")
							Caption:SetAttribute("Active", old and old+1 or 0)
							if Type == "thought" then
								Caption.TextColor3 = Color3.fromRGB(229, 224, 218)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Light, Enum.FontStyle.Normal)
								second = .6
							elseif Type == "info" then
								Caption.TextColor3 = Color3.fromRGB(255, 222, 189)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "rgb" then
								local CurrentNumber = Caption:GetAttribute("Active")
								local Gradient = Caption:FindFirstChildOfClass("UIGradient")
								Gradient = Gradient and Gradient:Clone() or Instance.new("UIGradient")
								Gradient.Parent = Caption
								Gradient.Enabled = true
								Gradient.Rotation = 0
								Gradient.Transparency = NumberSequence.new(0)
								Gradient.Color = ColorSequence.new({
									ColorSequenceKeypoint.new(
										0, Color3.fromHSV(0,1,1)
									),
									ColorSequenceKeypoint.new(
										1/6, Color3.fromHSV(1/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1/3, Color3.fromHSV(1/3,1,1)
									),
									ColorSequenceKeypoint.new(
										1/2, Color3.fromHSV(1/2,1,1)
									),
									ColorSequenceKeypoint.new(
										2/3, Color3.fromHSV(2/3,1,1)
									),
									ColorSequenceKeypoint.new(
										5/6, Color3.fromHSV(5/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1, Color3.fromHSV(1,1,1)
									)
								})
								local c; c = RunService.RenderStepped:Connect(function(DeltaTime)
									if CurrentNumber == Caption:GetAttribute("Active") and Caption.Parent then
										local NewKeypoints = {}
										for Key, Value in Gradient.Color.Keypoints do
											local H,S,V = Value.Value:ToHSV()
											NewKeypoints[Key] = ColorSequenceKeypoint.new(Value.Time, Color3.fromHSV((H+DeltaTime)%1,S,V))
										end
										Gradient.Color = ColorSequence.new(NewKeypoints)
									else
										c:Disconnect()
										Gradient:Destroy()
									end
								end)
								Caption.TextColor3 = Color3.new(1, 1, 1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "warning" then
								Caption.TextColor3 = Color3.fromRGB(225, 177, 138)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								Caption.BackgroundColor3 = Color3.fromRGB(36, 28, 26)
								first = .75
								second = .7
							else
								local Success, Color = pcall(function()
									return typeof(Type) == "Color3" and Type or typeof(Type) == "string" and Color3.fromHex(Type)
								end)
								Caption.TextColor3 = Success and Color or Color3.new(1,1,1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							end
							return first, second
						end
						local first, second = SetType(Type)
						Caption.Parent = BetterCaption.MainUI.CaptionHolder
						local CaptionSound = NewSound(Sound)
						CaptionSound:Play()
						TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
							BackgroundTransparency = nil,
							TextTransparency = 0,
							TextStrokeTransparency = nil,
							BackgroundTransparency = first,
							TextStrokeTransparency = second
						}):Play()
						if Smooth then
							TweenService:Create(Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
								MaxVisibleGraphemes = #Text
							}):Play()
							task.delay(.25, function()
								Caption.MaxVisibleGraphemes = -1
							end)
						end
						local MainCaption = {
							Caption = Caption,
							Type = Type,
							Smooth = Smooth,
							Edit = function(self, Text: string, Type: any?, Smooth: boolean?)
								self.Caption.Text = Text
								Type = Type == nil and self.Type or Type
								Smooth = Smooth == nil and self.Smooth or Smooth
								self.Type = Type
								self.Smooth = Smooth
								local first, second = SetType(Type)
								CaptionSound:Play()
								TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
									BackgroundTransparency = nil,
									TextTransparency = 0,
									TextStrokeTransparency = nil,
									BackgroundTransparency = first,
									TextStrokeTransparency = second
								}):Play()
								if Smooth then
									self.Caption.MaxVisibleGraphemes = 0
									TweenService:Create(self.Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
										MaxVisibleGraphemes = #Text
									}):Play()
									task.delay(.25, function()
										self.Caption.MaxVisibleGraphemes = -1
									end)
								end
								return self
							end,
							Destroy = function(self)
								table.remove(BetterCaption.Captions, BetterCaption:GetCaptionIndex(self))
								local Caption = self.Caption
								self = nil
								TweenService:Create(Caption, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
									BackgroundTransparency = 1,
									TextTransparency = 1,
									TextStrokeTransparency = 1
								}):Play()
								task.delay(1, function()
									CaptionSound:Destroy()
									Caption:Destroy()
								end)
							end,
							Delay = function(self, Delay: number)
								task.wait(Delay)
								return self
							end
						}
						table.insert(self.Captions, MainCaption)
						return MainCaption
					end
				end
				return nil
			end

			function BetterCaption:ClearAllCaptions()
				for _, Caption in BetterCaption.Captions do
					task.delay(.001, function()
						Caption:Destroy()
					end)
				end
			end

			BetterCaption:Caption(text, "rgb", false)

			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local ReplicatedFirst = game:GetService("ReplicatedFirst")
			local SoundService = game:GetService("SoundService")
			local Players = game:GetService("Players")
			local RunService = game:GetService("RunService")

			local LocalPlayer = Players.LocalPlayer
			local PlayerGui = LocalPlayer.PlayerGui

			task.spawn(function()
				PlayerGui:WaitForChild("DoorsAdmin", 1/0):Destroy()
			end)

			local RemotesFolder = ReplicatedStorage.RemotesFolder
			local GameData = ReplicatedStorage.GameData
			local _Loaded = ReplicatedFirst._Loaded

			local AdminPanelRunCommand = RemotesFolder.AdminPanelRunCommand
			local RequestLocalAsset = RemotesFolder.RequestLocalAsset
			local ServerTeleported = RemotesFolder.ServerTeleported
			local ToggleLoading = RemotesFolder.ToggleLoading
			local GetCurrency = RemotesFolder.GetCurrency
			local DeathHint = RemotesFolder.DeathHint
			local Crouch = RemotesFolder.Crouch
			local Lobby = RemotesFolder.Lobby

			local LatestRoom = GameData.LatestRoom

			local limit = 6

			local function getNilInstanceByName(name: string): Instance?
				for i,v in getnilinstances() do
					if v.Name == name then
						return v
					end
				end
				return nil
			end

			local ready = false
			task.spawn(function()
				while not ready do
					local Main = SoundService:FindFirstChild("Main")
					if Main then
						Main.Volume = 0
					end
					_Loaded.Value = false
					task.wait()
				end
				local MainUI = PlayerGui.MainUI
				local TopbarUI = PlayerGui.TopbarUI
				BetterCaption.MainUI = MainUI
				TopbarUI.ButtonsLeft.PanelButton.Visible = false
				TopbarUI.Topbar.Modifiers.Visible = false
				task.spawn(function()
					local TempMods = MainUI:WaitForChild("TempMods", 1/0)
					if TempMods then
						TempMods:Destroy()
					end
				end)
				SoundService.Main.Volume = 1
				_Loaded.Value = true
			end)

			local function lerp(a,b,c)
				return a * (1 - c) + b * c
			end

			local lerpProgress = LatestRoom.Value

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				local TravelText = LoadingUI.Loading.LoadingText.TravelText
				while math.round(lerpProgress/limit*100) < 100 do
					local dt = task.wait()
					lerpProgress = lerp(lerpProgress, LatestRoom.Value, math.clamp(dt*8, 0, 1))
					local text = `Loading progress: {math.round(lerpProgress/limit*100)}%`
					TravelText.Text = text
					TravelText.TravelShadow.Text = text
				end
			end)

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				while math.round(lerpProgress/limit*100) < 100 do
					if not LoadingUI.Enabled then
						LoadingUI.Enabled = true
						LoadingUI.Loading.Visible = true
						LoadingUI.Loading.BackgroundTransparency = 0
						LoadingUI.Loading.FloorBackground.ImageTransparency = 0.75
						LoadingUI.Loading.LoadingText.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.Shadow.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TextTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TravelShadow.TextTransparency = 0
					end
					task.wait()
				end
				ToggleLoading:Fire(false)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 100,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 100,
				["Allow Jumping"] = false,
				["God Mode"] = true
			})

			local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
			
			task.wait(.5)
			
			AdminPanelRunCommand:FireServer("Fly", {})

local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
			while not Room or Room:GetAttribute("RawName") ~= "Garden_EyestalkStart" do
				Crouch:FireServer(true,true)
				Character:PivotTo(Room and Room:FindFirstChild("Door") and Room.Door:GetPivot() or Character:GetPivot())
				RequestLocalAsset:InvokeServer({{}})
				Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				if not (not Room or Room:GetAttribute("RawName") ~= "Garden_EyestalkStart") then break end
				AdminPanelRunCommand:FireServer("SkipRoom", {})
			end

			while math.round(lerpProgress/limit*100) < 100 do
				task.wait()
			end

			AdminPanelRunCommand:FireServer("Fly", {})
			Crouch:FireServer()

			ready = true

			local End = false

			task.spawn(function()
				while not End do
					task.wait()
				end
				for _, door in workspace.CurrentRooms:QueryDescendants("> Model > #Door") do
					door:Clone().Parent = door.Parent
					door:Destroy()
				end
				workspace.CurrentRooms.DescendantAdded:Connect(function(door)
					if door.Name == "Door" and door.Parent:IsA("Model") and door.Parent.Parent == workspace.CurrentRooms then
						door:Clone().Parent = door.Parent
						door:Destroy()
					end
				end)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 50,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 50,
				["Allow Jumping"] = false,
				["God Mode"] = false
			})

			RequestLocalAsset:InvokeServer({{}})

			AdminPanelRunCommand:FireServer("RansomPlayer", {
				Players = {}
			})

			local currentGold = 0
			local currency; currency = GetCurrency.OnClientEvent:Connect(function(_,gold,str)
				if str == "RansomGold" then
					currentGold += gold
					if currentGold >= 150 then
						currency:Disconnect()
						End = true
						task.wait(5)
						BetterCaption:Caption("Teleporting to Lobby in 3 seconds...", "rgb", false):Delay(3)
						Lobby:FireServer()
					end
				end
			end)

			local texts = table.create(10000, "Teleporting to Lobby in 10 seconds...")
			Character.Humanoid.Died:Once(function()
				End = true
				firesignal(DeathHint.OnClientEvent, texts, "Glitch")
				task.wait(3.33)
				task.wait(10)
				Lobby:FireServer()
			end)

			workspace:WaitForChild("Ransom", 1/0)
			task.wait(.4)

			firesignal(ServerTeleported.OnClientEvent, Character:GetPivot().Position+Character:GetPivot().LookVector, -workspace.CurrentCamera.CFrame.LookVector)
			task.wait(.6)
			firesignal(ServerTeleported.OnClientEvent, Character:GetPivot().Position+Character:GetPivot().LookVector, -workspace.CurrentCamera.CFrame.LookVector)
			]]
]=]

local PracticeFirstSeekHotelScript = [=[
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end

			print("loading first seek hotel...")

			type MainCaption = {
				Caption: TextLabel,
				Type: any,
				Smooth: boolean,
				Edit: (self: MainCaption, Text: string, Type: any?, Smooth: boolean?) -> MainCaption,
				Destroy: (self: MainCaption) -> (),
				Delay: (self: MainCaption, Delay: number) -> MainCaption
			}

			local BetterCaption = {
				Captions = {}
			}

			local TweenService = game:GetService("TweenService")
			local RunService = game:GetService("RunService")
			local SoundService = game:GetService("SoundService")

			local function NewSound(Sound: {[string]: any}?)
				local SoundObj = Instance.new("Sound", SoundService)
				for Prop, Value in Sound do
					SoundObj[Prop] = Value
				end
				SoundObj.Looped = false
				return {
					Playing = false,
					Play = function(self, destroy: boolean)
						self.Playing = true
						SoundObj:Play()
						if destroy then
							SoundObj.Ended:Wait()
							self:Destroy()
						end
					end,
					Stop = function(self)
						self.Playing = false
						SoundObj:Stop()
					end,
					Destroy = function(self)
						SoundObj:Destroy()
						self = nil
					end
				}
			end

			function BetterCaption:GetCaptionIndex(Caption: MainCaption): number?
				for Index, OtherCaption in self.Captions do
					if OtherCaption.Caption == Caption.Caption then
						return Index
					end
				end
				return
			end

			function BetterCaption:Caption(Text: string, Type: any?, Smooth: boolean?, Sound: {[string]: any}?): MainCaption
				Type = Type or "info"
				if Smooth == nil or typeof(Smooth) ~= "boolean" then
					Smooth = true 
				end
				Sound = typeof(Sound) == "table" and Sound or {
					SoundId = "rbxassetid://3848738542",
					Volume = .1,
					PlaybackSpeed = 1
				}
				Sound.SoundId = Sound.SoundId or "rbxassetid://3848738542"
				if Type ~= "thought" or game.ReplicatedStorage.GameData.Floor.Value ~= "Party" then
					if Text ~= "" and (Text ~= " " and Text ~= nil) then
						local Caption = BetterCaption.MainUI.MainFrame.NewCaption:Clone()
						Caption.Name = "LiveCaption"
						Caption.Visible = true
						Caption.Text = Text
						Caption.TextTransparency = 1
						Caption.TextStrokeTransparency = 1
						Caption.BackgroundTransparency = 1
						Caption.MaxVisibleGraphemes = Smooth and 0 or -1
						local function SetType(Type)
							local first = 1
							local second = 0
							local old = Caption:GetAttribute("Active")
							Caption:SetAttribute("Active", old and old+1 or 0)
							if Type == "thought" then
								Caption.TextColor3 = Color3.fromRGB(229, 224, 218)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Light, Enum.FontStyle.Normal)
								second = .6
							elseif Type == "info" then
								Caption.TextColor3 = Color3.fromRGB(255, 222, 189)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "rgb" then
								local CurrentNumber = Caption:GetAttribute("Active")
								local Gradient = Caption:FindFirstChildOfClass("UIGradient")
								Gradient = Gradient and Gradient:Clone() or Instance.new("UIGradient")
								Gradient.Parent = Caption
								Gradient.Enabled = true
								Gradient.Rotation = 0
								Gradient.Transparency = NumberSequence.new(0)
								Gradient.Color = ColorSequence.new({
									ColorSequenceKeypoint.new(
										0, Color3.fromHSV(0,1,1)
									),
									ColorSequenceKeypoint.new(
										1/6, Color3.fromHSV(1/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1/3, Color3.fromHSV(1/3,1,1)
									),
									ColorSequenceKeypoint.new(
										1/2, Color3.fromHSV(1/2,1,1)
									),
									ColorSequenceKeypoint.new(
										2/3, Color3.fromHSV(2/3,1,1)
									),
									ColorSequenceKeypoint.new(
										5/6, Color3.fromHSV(5/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1, Color3.fromHSV(1,1,1)
									)
								})
								local c; c = RunService.RenderStepped:Connect(function(DeltaTime)
									if CurrentNumber == Caption:GetAttribute("Active") and Caption.Parent then
										local NewKeypoints = {}
										for Key, Value in Gradient.Color.Keypoints do
											local H,S,V = Value.Value:ToHSV()
											NewKeypoints[Key] = ColorSequenceKeypoint.new(Value.Time, Color3.fromHSV((H+DeltaTime)%1,S,V))
										end
										Gradient.Color = ColorSequence.new(NewKeypoints)
									else
										c:Disconnect()
										Gradient:Destroy()
									end
								end)
								Caption.TextColor3 = Color3.new(1, 1, 1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "warning" then
								Caption.TextColor3 = Color3.fromRGB(225, 177, 138)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								Caption.BackgroundColor3 = Color3.fromRGB(36, 28, 26)
								first = .75
								second = .7
							else
								local Success, Color = pcall(function()
									return typeof(Type) == "Color3" and Type or typeof(Type) == "string" and Color3.fromHex(Type)
								end)
								Caption.TextColor3 = Success and Color or Color3.new(1,1,1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							end
							return first, second
						end
						local first, second = SetType(Type)
						Caption.Parent = BetterCaption.MainUI.CaptionHolder
						local CaptionSound = NewSound(Sound)
						CaptionSound:Play()
						TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
							BackgroundTransparency = nil,
							TextTransparency = 0,
							TextStrokeTransparency = nil,
							BackgroundTransparency = first,
							TextStrokeTransparency = second
						}):Play()
						if Smooth then
							TweenService:Create(Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
								MaxVisibleGraphemes = #Text
							}):Play()
							task.delay(.25, function()
								Caption.MaxVisibleGraphemes = -1
							end)
						end
						local MainCaption = {
							Caption = Caption,
							Type = Type,
							Smooth = Smooth,
							Edit = function(self, Text: string, Type: any?, Smooth: boolean?)
								self.Caption.Text = Text
								Type = Type == nil and self.Type or Type
								Smooth = Smooth == nil and self.Smooth or Smooth
								self.Type = Type
								self.Smooth = Smooth
								local first, second = SetType(Type)
								CaptionSound:Play()
								TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
									BackgroundTransparency = nil,
									TextTransparency = 0,
									TextStrokeTransparency = nil,
									BackgroundTransparency = first,
									TextStrokeTransparency = second
								}):Play()
								if Smooth then
									self.Caption.MaxVisibleGraphemes = 0
									TweenService:Create(self.Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
										MaxVisibleGraphemes = #Text
									}):Play()
									task.delay(.25, function()
										self.Caption.MaxVisibleGraphemes = -1
									end)
								end
								return self
							end,
							Destroy = function(self)
								table.remove(BetterCaption.Captions, BetterCaption:GetCaptionIndex(self))
								local Caption = self.Caption
								self = nil
								TweenService:Create(Caption, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
									BackgroundTransparency = 1,
									TextTransparency = 1,
									TextStrokeTransparency = 1
								}):Play()
								task.delay(1, function()
									CaptionSound:Destroy()
									Caption:Destroy()
								end)
							end,
							Delay = function(self, Delay: number)
								task.wait(Delay)
								return self
							end
						}
						table.insert(self.Captions, MainCaption)
						return MainCaption
					end
				end
				return nil
			end

			function BetterCaption:ClearAllCaptions()
				for _, Caption in BetterCaption.Captions do
					task.delay(.001, function()
						Caption:Destroy()
					end)
				end
			end

			BetterCaption:Caption(text, "rgb", false)

			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local ReplicatedFirst = game:GetService("ReplicatedFirst")
			local SoundService = game:GetService("SoundService")
			local Players = game:GetService("Players")
			local RunService = game:GetService("RunService")

			local LocalPlayer = Players.LocalPlayer
			local PlayerGui = LocalPlayer.PlayerGui

			task.spawn(function()
				PlayerGui:WaitForChild("DoorsAdmin", 1/0):Destroy()
			end)

			local RemotesFolder = ReplicatedStorage.RemotesFolder
			local GameData = ReplicatedStorage.GameData
			local _Loaded = ReplicatedFirst._Loaded

			local AdminPanelRunCommand = RemotesFolder.AdminPanelRunCommand
			local RequestLocalAsset = RemotesFolder.RequestLocalAsset
			local ToggleLoading = RemotesFolder.ToggleLoading
			local DeathHint = RemotesFolder.DeathHint
			local Crouch = RemotesFolder.Crouch
			local Lobby = RemotesFolder.Lobby

			local LatestRoom = GameData.LatestRoom

			local function getNilInstanceByName(name: string): Instance?
				for i,v in getnilinstances() do
					if v.Name == name then
						return v
					end
				end
				return nil
			end

			local ready = false
			task.spawn(function()
				while not ready do
					local Main = SoundService:FindFirstChild("Main")
					if Main then
						Main.Volume = 0
					end
					_Loaded.Value = false
					task.wait()
				end
				local MainUI = PlayerGui.MainUI
				local TopbarUI = PlayerGui.TopbarUI
				BetterCaption.MainUI = MainUI
				TopbarUI.ButtonsLeft.PanelButton.Visible = false
				TopbarUI.Topbar.Modifiers.Visible = false
				task.spawn(function()
					local TempMods = MainUI:WaitForChild("TempMods", 1/0)
					if TempMods then
						TempMods:Destroy()
					end
				end)
				SoundService.Main.Volume = 1
				_Loaded.Value = true
			end)

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				local TravelText = LoadingUI.Loading.LoadingText.TravelText
				local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				while (not Room or Room:GetAttribute("RawName") ~= "Hotel_SeekIntro") and task.wait() do
					local text = `Heading to first Seek Chase in Hotel (Room {LatestRoom.Value})`
					TravelText.Text = text
					TravelText.TravelShadow.Text = text
					Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				end
			end)

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				while not Room or Room:GetAttribute("RawName") ~= "Hotel_SeekIntro" do
					if not LoadingUI.Enabled then
						LoadingUI.Enabled = true
						LoadingUI.Loading.Visible = true
						LoadingUI.Loading.BackgroundTransparency = 0
						LoadingUI.Loading.FloorBackground.ImageTransparency = 0.75
						LoadingUI.Loading.LoadingText.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.Shadow.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TextTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TravelShadow.TextTransparency = 0
					end
					task.wait()
					Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				end
				ToggleLoading:Fire(false)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 100,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 100,
				["Allow Jumping"] = false,
				["God Mode"] = true
			})

			local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

			task.delay(.5, function()
				AdminPanelRunCommand:FireServer("Fly", {})
			end)

			task.spawn(function()
				while task.wait(.1) do
					AdminPanelRunCommand:FireServer("DELETE ALL", {})
				end
			end)

			local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
			while not Room or Room:GetAttribute("RawName") ~= "Hotel_SeekIntro" do
				Crouch:FireServer(true,true)
				Character:PivotTo(Room and Room:FindFirstChild("Door") and Room.Door:GetPivot() or Character:GetPivot())
				RequestLocalAsset:InvokeServer({{}})
				Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				if not (not Room or Room:GetAttribute("RawName") ~= "Hotel_SeekIntro") then break end
				AdminPanelRunCommand:FireServer("SkipRoom", {})
			end

			AdminPanelRunCommand:FireServer("Fly", {})
			Crouch:FireServer()

			ready = true

			local End = false
			local goodend = true

			task.spawn(function()
				while not End do
					task.wait()
				end
				task.spawn(function()
					if not goodend then return end
					BetterCaption:Caption("Teleporting to Lobby in 5 seconds...", "rgb", false):Delay(5)
					Lobby:FireServer()
				end)
				for _, door in workspace.CurrentRooms:QueryDescendants("> Model > #Door") do
					door:Clone().Parent = door.Parent
					door:Destroy()
				end
				workspace.CurrentRooms.DescendantAdded:Connect(function(door)
					if door.Name == "Door" and door.Parent:IsA("Model") and door.Parent.Parent == workspace.CurrentRooms then
						door:Clone().Parent = door.Parent
						door:Destroy()
					end
				end)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 100,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 100,
				["Allow Jumping"] = false,
				["God Mode"] = false
			})

			local texts = table.create(10000, "Teleporting to Lobby in 10 seconds...")
			Character.Humanoid.Died:Once(function()
				goodend = false
				End = true
				firesignal(DeathHint.OnClientEvent, texts, "Glitch")
				task.wait(3.33)
				task.wait(10)
				Lobby:FireServer()
			end)

			local endRoom = LatestRoom.Value+6
			repeat task.wait() until LatestRoom.Value >= endRoom
			End = true
			]]
]=]

local PracticeFirstSeekMinesScript = [=[
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end

			print("loading first seek mines...")

			type MainCaption = {
				Caption: TextLabel,
				Type: any,
				Smooth: boolean,
				Edit: (self: MainCaption, Text: string, Type: any?, Smooth: boolean?) -> MainCaption,
				Destroy: (self: MainCaption) -> (),
				Delay: (self: MainCaption, Delay: number) -> MainCaption
			}

			local BetterCaption = {
				Captions = {}
			}

			local TweenService = game:GetService("TweenService")
			local RunService = game:GetService("RunService")
			local SoundService = game:GetService("SoundService")

			local function NewSound(Sound: {[string]: any}?)
				local SoundObj = Instance.new("Sound", SoundService)
				for Prop, Value in Sound do
					SoundObj[Prop] = Value
				end
				SoundObj.Looped = false
				return {
					Playing = false,
					Play = function(self, destroy: boolean)
						self.Playing = true
						SoundObj:Play()
						if destroy then
							SoundObj.Ended:Wait()
							self:Destroy()
						end
					end,
					Stop = function(self)
						self.Playing = false
						SoundObj:Stop()
					end,
					Destroy = function(self)
						SoundObj:Destroy()
						self = nil
					end
				}
			end

			function BetterCaption:GetCaptionIndex(Caption: MainCaption): number?
				for Index, OtherCaption in self.Captions do
					if OtherCaption.Caption == Caption.Caption then
						return Index
					end
				end
				return
			end

			function BetterCaption:Caption(Text: string, Type: any?, Smooth: boolean?, Sound: {[string]: any}?): MainCaption
				Type = Type or "info"
				if Smooth == nil or typeof(Smooth) ~= "boolean" then
					Smooth = true 
				end
				Sound = typeof(Sound) == "table" and Sound or {
					SoundId = "rbxassetid://3848738542",
					Volume = .1,
					PlaybackSpeed = 1
				}
				Sound.SoundId = Sound.SoundId or "rbxassetid://3848738542"
				if Type ~= "thought" or game.ReplicatedStorage.GameData.Floor.Value ~= "Party" then
					if Text ~= "" and (Text ~= " " and Text ~= nil) then
						local Caption = BetterCaption.MainUI.MainFrame.NewCaption:Clone()
						Caption.Name = "LiveCaption"
						Caption.Visible = true
						Caption.Text = Text
						Caption.TextTransparency = 1
						Caption.TextStrokeTransparency = 1
						Caption.BackgroundTransparency = 1
						Caption.MaxVisibleGraphemes = Smooth and 0 or -1
						local function SetType(Type)
							local first = 1
							local second = 0
							local old = Caption:GetAttribute("Active")
							Caption:SetAttribute("Active", old and old+1 or 0)
							if Type == "thought" then
								Caption.TextColor3 = Color3.fromRGB(229, 224, 218)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Light, Enum.FontStyle.Normal)
								second = .6
							elseif Type == "info" then
								Caption.TextColor3 = Color3.fromRGB(255, 222, 189)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "rgb" then
								local CurrentNumber = Caption:GetAttribute("Active")
								local Gradient = Caption:FindFirstChildOfClass("UIGradient")
								Gradient = Gradient and Gradient:Clone() or Instance.new("UIGradient")
								Gradient.Parent = Caption
								Gradient.Enabled = true
								Gradient.Rotation = 0
								Gradient.Transparency = NumberSequence.new(0)
								Gradient.Color = ColorSequence.new({
									ColorSequenceKeypoint.new(
										0, Color3.fromHSV(0,1,1)
									),
									ColorSequenceKeypoint.new(
										1/6, Color3.fromHSV(1/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1/3, Color3.fromHSV(1/3,1,1)
									),
									ColorSequenceKeypoint.new(
										1/2, Color3.fromHSV(1/2,1,1)
									),
									ColorSequenceKeypoint.new(
										2/3, Color3.fromHSV(2/3,1,1)
									),
									ColorSequenceKeypoint.new(
										5/6, Color3.fromHSV(5/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1, Color3.fromHSV(1,1,1)
									)
								})
								local c; c = RunService.RenderStepped:Connect(function(DeltaTime)
									if CurrentNumber == Caption:GetAttribute("Active") and Caption.Parent then
										local NewKeypoints = {}
										for Key, Value in Gradient.Color.Keypoints do
											local H,S,V = Value.Value:ToHSV()
											NewKeypoints[Key] = ColorSequenceKeypoint.new(Value.Time, Color3.fromHSV((H+DeltaTime)%1,S,V))
										end
										Gradient.Color = ColorSequence.new(NewKeypoints)
									else
										c:Disconnect()
										Gradient:Destroy()
									end
								end)
								Caption.TextColor3 = Color3.new(1, 1, 1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "warning" then
								Caption.TextColor3 = Color3.fromRGB(225, 177, 138)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								Caption.BackgroundColor3 = Color3.fromRGB(36, 28, 26)
								first = .75
								second = .7
							else
								local Success, Color = pcall(function()
									return typeof(Type) == "Color3" and Type or typeof(Type) == "string" and Color3.fromHex(Type)
								end)
								Caption.TextColor3 = Success and Color or Color3.new(1,1,1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							end
							return first, second
						end
						local first, second = SetType(Type)
						Caption.Parent = BetterCaption.MainUI.CaptionHolder
						local CaptionSound = NewSound(Sound)
						CaptionSound:Play()
						TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
							BackgroundTransparency = nil,
							TextTransparency = 0,
							TextStrokeTransparency = nil,
							BackgroundTransparency = first,
							TextStrokeTransparency = second
						}):Play()
						if Smooth then
							TweenService:Create(Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
								MaxVisibleGraphemes = #Text
							}):Play()
							task.delay(.25, function()
								Caption.MaxVisibleGraphemes = -1
							end)
						end
						local MainCaption = {
							Caption = Caption,
							Type = Type,
							Smooth = Smooth,
							Edit = function(self, Text: string, Type: any?, Smooth: boolean?)
								self.Caption.Text = Text
								Type = Type == nil and self.Type or Type
								Smooth = Smooth == nil and self.Smooth or Smooth
								self.Type = Type
								self.Smooth = Smooth
								local first, second = SetType(Type)
								CaptionSound:Play()
								TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
									BackgroundTransparency = nil,
									TextTransparency = 0,
									TextStrokeTransparency = nil,
									BackgroundTransparency = first,
									TextStrokeTransparency = second
								}):Play()
								if Smooth then
									self.Caption.MaxVisibleGraphemes = 0
									TweenService:Create(self.Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
										MaxVisibleGraphemes = #Text
									}):Play()
									task.delay(.25, function()
										self.Caption.MaxVisibleGraphemes = -1
									end)
								end
								return self
							end,
							Destroy = function(self)
								table.remove(BetterCaption.Captions, BetterCaption:GetCaptionIndex(self))
								local Caption = self.Caption
								self = nil
								TweenService:Create(Caption, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
									BackgroundTransparency = 1,
									TextTransparency = 1,
									TextStrokeTransparency = 1
								}):Play()
								task.delay(1, function()
									CaptionSound:Destroy()
									Caption:Destroy()
								end)
							end,
							Delay = function(self, Delay: number)
								task.wait(Delay)
								return self
							end
						}
						table.insert(self.Captions, MainCaption)
						return MainCaption
					end
				end
				return nil
			end

			function BetterCaption:ClearAllCaptions()
				for _, Caption in BetterCaption.Captions do
					task.delay(.001, function()
						Caption:Destroy()
					end)
				end
			end

			BetterCaption:Caption(text, "rgb", false)

			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local ReplicatedFirst = game:GetService("ReplicatedFirst")
			local SoundService = game:GetService("SoundService")
			local Players = game:GetService("Players")
			local RunService = game:GetService("RunService")

			local LocalPlayer = Players.LocalPlayer
			local PlayerGui = LocalPlayer.PlayerGui

			task.spawn(function()
				PlayerGui:WaitForChild("DoorsAdmin", 1/0):Destroy()
			end)

			local RemotesFolder = ReplicatedStorage.RemotesFolder
			local GameData = ReplicatedStorage.GameData
			local _Loaded = ReplicatedFirst._Loaded

			local AdminPanelRunCommand = RemotesFolder.AdminPanelRunCommand
			local RequestLocalAsset = RemotesFolder.RequestLocalAsset
			local ToggleLoading = RemotesFolder.ToggleLoading
			local DeathHint = RemotesFolder.DeathHint
			local Crouch = RemotesFolder.Crouch
			local Lobby = RemotesFolder.Lobby

			local LatestRoom = GameData.LatestRoom

			local function getNilInstanceByName(name: string): Instance?
				for i,v in getnilinstances() do
					if v.Name == name then
						return v
					end
				end
				return nil
			end

			local ready = false
			task.spawn(function()
				while not ready do
					local Main = SoundService:FindFirstChild("Main")
					if Main then
						Main.Volume = 0
					end
					_Loaded.Value = false
					task.wait()
				end
				local MainUI = PlayerGui.MainUI
				local TopbarUI = PlayerGui.TopbarUI
				BetterCaption.MainUI = MainUI
				TopbarUI.ButtonsLeft.PanelButton.Visible = false
				TopbarUI.Topbar.Modifiers.Visible = false
				task.spawn(function()
					local TempMods = MainUI:WaitForChild("TempMods", 1/0)
					if TempMods then
						TempMods:Destroy()
					end
				end)
				SoundService.Main.Volume = 1
				_Loaded.Value = true
			end)

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				local TravelText = LoadingUI.Loading.LoadingText.TravelText
				local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				while (not Room or Room:GetAttribute("RawName") ~= "Mines_SeekStart") and task.wait() do
					local text = `Heading to first Seek Chase in Mines (Room {LatestRoom.Value})`
					TravelText.Text = text
					TravelText.TravelShadow.Text = text
					Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				end
			end)

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				while not Room or Room:GetAttribute("RawName") ~= "Mines_SeekStart" do
					if not LoadingUI.Enabled then
						LoadingUI.Enabled = true
						LoadingUI.Loading.Visible = true
						LoadingUI.Loading.BackgroundTransparency = 0
						LoadingUI.Loading.FloorBackground.ImageTransparency = 0.75
						LoadingUI.Loading.LoadingText.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.Shadow.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TextTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TravelShadow.TextTransparency = 0
					end
					task.wait()
					Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				end
				ToggleLoading:Fire(false)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 100,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 100,
				["Allow Jumping"] = false,
				["God Mode"] = true
			})

			local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

			task.delay(.5, function()
				AdminPanelRunCommand:FireServer("Fly", {})
			end)

			task.spawn(function()
				while task.wait(.1) do
					AdminPanelRunCommand:FireServer("DELETE ALL", {})
				end
			end)

			local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
			while not Room or Room:GetAttribute("RawName") ~= "Mines_SeekStart" do
				Crouch:FireServer(true,true)
				Character:PivotTo(Room and Room:FindFirstChild("Door") and Room.Door:GetPivot() or Character:GetPivot())
				RequestLocalAsset:InvokeServer({{}})
				Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				if not (not Room or Room:GetAttribute("RawName") ~= "Mines_SeekStart") then break end
				AdminPanelRunCommand:FireServer("SkipRoom", {})
			end

			AdminPanelRunCommand:FireServer("Fly", {})
			Crouch:FireServer()

			ready = true

			local End = false
			local goodend = true

			task.spawn(function()
				while not End do
					task.wait()
				end
				task.spawn(function()
					if not goodend then return end
					BetterCaption:Caption("Teleporting to Lobby in 5 seconds...", "rgb", false):Delay(5)
					Lobby:FireServer()
				end)
				for _, door in workspace.CurrentRooms:QueryDescendants("> Model > #Door") do
					door:Clone().Parent = door.Parent
					door:Destroy()
				end
				workspace.CurrentRooms.DescendantAdded:Connect(function(door)
					if door.Name == "Door" and door.Parent:IsA("Model") and door.Parent.Parent == workspace.CurrentRooms then
						door:Clone().Parent = door.Parent
						door:Destroy()
					end
				end)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 100,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 100,
				["Allow Jumping"] = false,
				["God Mode"] = false
			})

			local texts = table.create(10000, "Teleporting to Lobby in 10 seconds...")
			Character.Humanoid.Died:Once(function()
				goodend = false
				End = true
				firesignal(DeathHint.OnClientEvent, texts, "Glitch")
				task.wait(3.33)
				task.wait(10)
				Lobby:FireServer()
			end)

			local endRoom = 49
			repeat task.wait() until LatestRoom.Value >= endRoom
			End = true
			]]
]=]

local PracticeEyestalkChaseScript = [=[
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end

			print("loading eyestalk chase...")

			type MainCaption = {
				Caption: TextLabel,
				Type: any,
				Smooth: boolean,
				Edit: (self: MainCaption, Text: string, Type: any?, Smooth: boolean?) -> MainCaption,
				Destroy: (self: MainCaption) -> (),
				Delay: (self: MainCaption, Delay: number) -> MainCaption
			}

			local BetterCaption = {
				Captions = {}
			}

			local TweenService = game:GetService("TweenService")
			local RunService = game:GetService("RunService")
			local SoundService = game:GetService("SoundService")

			local function NewSound(Sound: {[string]: any}?)
				local SoundObj = Instance.new("Sound", SoundService)
				for Prop, Value in Sound do
					SoundObj[Prop] = Value
				end
				SoundObj.Looped = false
				return {
					Playing = false,
					Play = function(self, destroy: boolean)
						self.Playing = true
						SoundObj:Play()
						if destroy then
							SoundObj.Ended:Wait()
							self:Destroy()
						end
					end,
					Stop = function(self)
						self.Playing = false
						SoundObj:Stop()
					end,
					Destroy = function(self)
						SoundObj:Destroy()
						self = nil
					end
				}
			end

			function BetterCaption:GetCaptionIndex(Caption: MainCaption): number?
				for Index, OtherCaption in self.Captions do
					if OtherCaption.Caption == Caption.Caption then
						return Index
					end
				end
				return
			end

			function BetterCaption:Caption(Text: string, Type: any?, Smooth: boolean?, Sound: {[string]: any}?): MainCaption
				Type = Type or "info"
				if Smooth == nil or typeof(Smooth) ~= "boolean" then
					Smooth = true 
				end
				Sound = typeof(Sound) == "table" and Sound or {
					SoundId = "rbxassetid://3848738542",
					Volume = .1,
					PlaybackSpeed = 1
				}
				Sound.SoundId = Sound.SoundId or "rbxassetid://3848738542"
				if Type ~= "thought" or game.ReplicatedStorage.GameData.Floor.Value ~= "Party" then
					if Text ~= "" and (Text ~= " " and Text ~= nil) then
						local Caption = BetterCaption.MainUI.MainFrame.NewCaption:Clone()
						Caption.Name = "LiveCaption"
						Caption.Visible = true
						Caption.Text = Text
						Caption.TextTransparency = 1
						Caption.TextStrokeTransparency = 1
						Caption.BackgroundTransparency = 1
						Caption.MaxVisibleGraphemes = Smooth and 0 or -1
						local function SetType(Type)
							local first = 1
							local second = 0
							local old = Caption:GetAttribute("Active")
							Caption:SetAttribute("Active", old and old+1 or 0)
							if Type == "thought" then
								Caption.TextColor3 = Color3.fromRGB(229, 224, 218)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Light, Enum.FontStyle.Normal)
								second = .6
							elseif Type == "info" then
								Caption.TextColor3 = Color3.fromRGB(255, 222, 189)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "rgb" then
								local CurrentNumber = Caption:GetAttribute("Active")
								local Gradient = Caption:FindFirstChildOfClass("UIGradient")
								Gradient = Gradient and Gradient:Clone() or Instance.new("UIGradient")
								Gradient.Parent = Caption
								Gradient.Enabled = true
								Gradient.Rotation = 0
								Gradient.Transparency = NumberSequence.new(0)
								Gradient.Color = ColorSequence.new({
									ColorSequenceKeypoint.new(
										0, Color3.fromHSV(0,1,1)
									),
									ColorSequenceKeypoint.new(
										1/6, Color3.fromHSV(1/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1/3, Color3.fromHSV(1/3,1,1)
									),
									ColorSequenceKeypoint.new(
										1/2, Color3.fromHSV(1/2,1,1)
									),
									ColorSequenceKeypoint.new(
										2/3, Color3.fromHSV(2/3,1,1)
									),
									ColorSequenceKeypoint.new(
										5/6, Color3.fromHSV(5/6,1,1)
									),
									ColorSequenceKeypoint.new(
										1, Color3.fromHSV(1,1,1)
									)
								})
								local c; c = RunService.RenderStepped:Connect(function(DeltaTime)
									if CurrentNumber == Caption:GetAttribute("Active") and Caption.Parent then
										local NewKeypoints = {}
										for Key, Value in Gradient.Color.Keypoints do
											local H,S,V = Value.Value:ToHSV()
											NewKeypoints[Key] = ColorSequenceKeypoint.new(Value.Time, Color3.fromHSV((H+DeltaTime)%1,S,V))
										end
										Gradient.Color = ColorSequence.new(NewKeypoints)
									else
										c:Disconnect()
										Gradient:Destroy()
									end
								end)
								Caption.TextColor3 = Color3.new(1, 1, 1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							elseif Type == "warning" then
								Caption.TextColor3 = Color3.fromRGB(225, 177, 138)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								Caption.BackgroundColor3 = Color3.fromRGB(36, 28, 26)
								first = .75
								second = .7
							else
								local Success, Color = pcall(function()
									return typeof(Type) == "Color3" and Type or typeof(Type) == "string" and Color3.fromHex(Type)
								end)
								Caption.TextColor3 = Success and Color or Color3.new(1,1,1)
								Caption.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
								second = .7
							end
							return first, second
						end
						local first, second = SetType(Type)
						Caption.Parent = BetterCaption.MainUI.CaptionHolder
						local CaptionSound = NewSound(Sound)
						CaptionSound:Play()
						TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
							BackgroundTransparency = nil,
							TextTransparency = 0,
							TextStrokeTransparency = nil,
							BackgroundTransparency = first,
							TextStrokeTransparency = second
						}):Play()
						if Smooth then
							TweenService:Create(Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
								MaxVisibleGraphemes = #Text
							}):Play()
							task.delay(.25, function()
								Caption.MaxVisibleGraphemes = -1
							end)
						end
						local MainCaption = {
							Caption = Caption,
							Type = Type,
							Smooth = Smooth,
							Edit = function(self, Text: string, Type: any?, Smooth: boolean?)
								self.Caption.Text = Text
								Type = Type == nil and self.Type or Type
								Smooth = Smooth == nil and self.Smooth or Smooth
								self.Type = Type
								self.Smooth = Smooth
								local first, second = SetType(Type)
								CaptionSound:Play()
								TweenService:Create(Caption, TweenInfo.new(.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
									BackgroundTransparency = nil,
									TextTransparency = 0,
									TextStrokeTransparency = nil,
									BackgroundTransparency = first,
									TextStrokeTransparency = second
								}):Play()
								if Smooth then
									self.Caption.MaxVisibleGraphemes = 0
									TweenService:Create(self.Caption, TweenInfo.new(.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
										MaxVisibleGraphemes = #Text
									}):Play()
									task.delay(.25, function()
										self.Caption.MaxVisibleGraphemes = -1
									end)
								end
								return self
							end,
							Destroy = function(self)
								table.remove(BetterCaption.Captions, BetterCaption:GetCaptionIndex(self))
								local Caption = self.Caption
								self = nil
								TweenService:Create(Caption, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
									BackgroundTransparency = 1,
									TextTransparency = 1,
									TextStrokeTransparency = 1
								}):Play()
								task.delay(1, function()
									CaptionSound:Destroy()
									Caption:Destroy()
								end)
							end,
							Delay = function(self, Delay: number)
								task.wait(Delay)
								return self
							end
						}
						table.insert(self.Captions, MainCaption)
						return MainCaption
					end
				end
				return nil
			end

			function BetterCaption:ClearAllCaptions()
				for _, Caption in BetterCaption.Captions do
					task.delay(.001, function()
						Caption:Destroy()
					end)
				end
			end

			BetterCaption:Caption(text, "rgb", false)

			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local ReplicatedFirst = game:GetService("ReplicatedFirst")
			local SoundService = game:GetService("SoundService")
			local Players = game:GetService("Players")
			local RunService = game:GetService("RunService")

			local LocalPlayer = Players.LocalPlayer
			local PlayerGui = LocalPlayer.PlayerGui

			task.spawn(function()
				PlayerGui:WaitForChild("DoorsAdmin", 1/0):Destroy()
			end)

			local RemotesFolder = ReplicatedStorage.RemotesFolder
			local GameData = ReplicatedStorage.GameData
			local _Loaded = ReplicatedFirst._Loaded

			local AdminPanelRunCommand = RemotesFolder.AdminPanelRunCommand
			local RequestLocalAsset = RemotesFolder.RequestLocalAsset
			local ToggleLoading = RemotesFolder.ToggleLoading
			local DeathHint = RemotesFolder.DeathHint
			local Cutscene = RemotesFolder.Cutscene
			local Crouch = RemotesFolder.Crouch
			local Lobby = RemotesFolder.Lobby

			local LatestRoom = GameData.LatestRoom

			local function getNilInstanceByName(name: string): Instance?
				for i,v in getnilinstances() do
					if v.Name == name then
						return v
					end
				end
				return nil
			end

			local ready = false
			task.spawn(function()
				while not ready do
					local Main = SoundService:FindFirstChild("Main")
					if Main then
						Main.Volume = 0
					end
					_Loaded.Value = false
					task.wait()
				end
				local MainUI = PlayerGui.MainUI
				local TopbarUI = PlayerGui.TopbarUI
				BetterCaption.MainUI = MainUI
				TopbarUI.ButtonsLeft.PanelButton.Visible = false
				TopbarUI.Topbar.Modifiers.Visible = false
				task.spawn(function()
					local TempMods = MainUI:WaitForChild("TempMods", 1/0)
					if TempMods then
						TempMods:Destroy()
					end
				end)
				SoundService.Main.Volume = 1
				_Loaded.Value = true
			end)

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				local TravelText = LoadingUI.Loading.LoadingText.TravelText
				local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				while (not Room or Room:GetAttribute("RawName") ~= "Garden_EyestalkStart") and task.wait() do
					local text = `Heading to Eyestalk Chase (Room {LatestRoom.Value})`
					TravelText.Text = text
					TravelText.TravelShadow.Text = text
					Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				end
			end)

			task.spawn(function()
				local LoadingUI = PlayerGui.LoadingUI
				local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				while not Room or Room:GetAttribute("RawName") ~= "Garden_EyestalkStart" do
					if not LoadingUI.Enabled then
						LoadingUI.Enabled = true
						LoadingUI.Loading.Visible = true
						LoadingUI.Loading.BackgroundTransparency = 0
						LoadingUI.Loading.FloorBackground.ImageTransparency = 0.75
						LoadingUI.Loading.LoadingText.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.Shadow.ImageTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TextTransparency = 0
						LoadingUI.Loading.LoadingText.TravelText.TravelShadow.TextTransparency = 0
					end
					task.wait()
					Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				end
				ToggleLoading:Fire(false)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 100,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 100,
				["Allow Jumping"] = false,
				["God Mode"] = true
			})

			local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

			task.delay(.5, function()
				AdminPanelRunCommand:FireServer("Fly", {})
			end)

			task.spawn(function()
				while task.wait(.1) do
					AdminPanelRunCommand:FireServer("DELETE ALL", {})
				end
			end)

			local Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
			while not Room or Room:GetAttribute("RawName") ~= "Mines_SeekStart" do
				Crouch:FireServer(true,true)
				Character:PivotTo(Room and Room:FindFirstChild("Door") and Room.Door:GetPivot() or Character:GetPivot())
				RequestLocalAsset:InvokeServer({{}})
				Room = workspace.CurrentRooms:FindFirstChild(LatestRoom.Value)
				if not (not Room or Room:GetAttribute("RawName") ~= "Mines_SeekStart") then break end
				AdminPanelRunCommand:FireServer("SkipRoom", {})
			end

			AdminPanelRunCommand:FireServer("Fly", {})
			Crouch:FireServer()

			ready = true

			local End = false
			local goodend = true

			task.spawn(function()
				while not End do
					task.wait()
				end
				task.spawn(function()
					if not goodend then return end
					BetterCaption:Caption("Teleporting to Lobby in 30 seconds...", "rgb", false):Delay(30)
					Lobby:FireServer()
				end)
				for _, door in workspace.CurrentRooms:QueryDescendants("> Model > #Door") do
					door:Clone().Parent = door.Parent
					door:Destroy()
				end
				workspace.CurrentRooms.DescendantAdded:Connect(function(door)
					if door.Name == "Door" and door.Parent:IsA("Model") and door.Parent.Parent == workspace.CurrentRooms then
						door:Clone().Parent = door.Parent
						door:Destroy()
					end
				end)
			end)

			AdminPanelRunCommand:FireServer("Apply Changes", {
				Players = {},
				["Max Health"] = 100,
				["Allow Sliding"] = false,
				["Star Shield"] = 0,
				["Speed Boost"] = 0,
				Health = 100,
				["Allow Jumping"] = false,
				["God Mode"] = false
			})

			local texts = table.create(10000, "Teleporting to Lobby in 10 seconds...")
			Character.Humanoid.Died:Once(function()
				goodend = false
				End = true
				firesignal(DeathHint.OnClientEvent, texts, "Glitch")
				task.wait(3.33)
				task.wait(10)
				Lobby:FireServer()
			end)

			Cutscene.OnClientEvent:Connect(function(name)
				if name == "EyestalkOutro" then
					End = true
				end
			end)
			]]
]=]


-- Practice Tab
Practice_Main = Tabs.Practice:AddLeftGroupbox("Practice Encounters")
Practice_Info = Tabs.Practice:AddRightGroupbox("Information")

Practice_Info:AddLabel("Requirements:\n- Executor with queue_on_teleport support\n- In-game Admin Panel mod access\n\nHow it works:\n1. Spawns a solo elevator with AdminPanel modifier.\n2. Injects encounter script upon game loading.\n3. Automatically skips rooms directly to the encounter.\n4. Sets up god mode & custom smooth animated status captions.\n5. Automatically teleports you back to Lobby upon completion or death.", true)

Practice_Main:AddButton({
    Text = "Practice Ransom",
    DoubleClick = true,
    Tooltip = "Hotel solo run, skips rooms to Ransom encounter, collects 150 gold then returns to lobby.",
    Func = function()
        if not queue_on_teleport then
            Library:Notify({ Title = "Practice Mode", Body = "Executor does not support queue_on_teleport!" })
            return
        end
        RemotesFolder.CreateElevator:FireServer({
            Mods = { "AdminPanel" },
            Settings = {},
            Destination = "Hotel",
            MaxPlayers = "1"
        })
        queue_on_teleport(PracticeRansomScript)
    end
})

Practice_Main:AddButton({
    Text = "First Seek (Hotel)",
    DoubleClick = true,
    Tooltip = "Hotel solo run, skips rooms straight to Hotel Seek Chase.",
    Func = function()
        if not queue_on_teleport then
            Library:Notify({ Title = "Practice Mode", Body = "Executor does not support queue_on_teleport!" })
            return
        end
        RemotesFolder.CreateElevator:FireServer({
            Mods = { "AdminPanel" },
            Settings = {},
            Destination = "Hotel",
            MaxPlayers = "1"
        })
        queue_on_teleport(PracticeFirstSeekHotelScript)
    end
})

Practice_Main:AddButton({
    Text = "First Seek (Mines)",
    DoubleClick = true,
    Tooltip = "Mines solo run, skips rooms straight to Mines Seek Chase (up to room 49).",
    Func = function()
        if not queue_on_teleport then
            Library:Notify({ Title = "Practice Mode", Body = "Executor does not support queue_on_teleport!" })
            return
        end
        RemotesFolder.CreateElevator:FireServer({
            Mods = { "AdminPanel" },
            Settings = {},
            Destination = "Mines",
            MaxPlayers = "1"
        })
        queue_on_teleport(PracticeFirstSeekMinesScript)
    end
})

Practice_Main:AddButton({
    Text = "Eyestalk Chase (Garden)",
    DoubleClick = true,
    Tooltip = "Garden solo run, skips rooms straight to Eyestalk Chase encounter.",
    Func = function()
        if not queue_on_teleport then
            Library:Notify({ Title = "Practice Mode", Body = "Executor does not support queue_on_teleport!" })
            return
        end
        RemotesFolder.CreateElevator:FireServer({
            Mods = { "AdminPanel" },
            Settings = {},
            Destination = "Garden",
            MaxPlayers = "1"
        })
        queue_on_teleport(PracticeEyestalkChaseScript)
    end
})

Library:OnUnload(function()
    CrashFloodActive = false
    if Con.MainConnection then
        Con.MainConnection:Disconnect()
    end
    if Con.FlingDoorsConnection then
        Con.FlingDoorsConnection:Disconnect()
    end
    if Con.BadgeAddedConnection then
        Con.BadgeAddedConnection:Disconnect()
    end
    for _, Door in ipairs(UnanchoredParts) do
        if Door and Door.Parent then
            local bp = Door:FindFirstChild("DoorBreakVelocity")
            if bp then bp:Destroy() end
        end
    end
    if track then
        track:Stop()
    end
    if clear_teleport_queue then
        pcall(clear_teleport_queue)
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

if Loading and Loading.Destroyed ~= true then
    Loading:SetCurrentStep(2)
    Loading:SetMessage("Setting up lobby features...")
    task.wait(1)
    Loading:SetCurrentStep(3)
    Loading:SetMessage("Building interface...")
    task.wait(1.5)
    Loading:SetCurrentStep(4)
    Loading:SetMessage("Ready.")
    Loading:SetDescription("fun fact: bomb.exe is loading...")
    task.wait(1.5)
    Loading:Continue()
end

Functions.Notify({ Title = "Successfully loaded", Body = "Press RightControl to Close/Open the menu"})
