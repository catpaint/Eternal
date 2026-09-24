local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "catpaint",
    Icon = "rbxassetid://10723404392",
    Author = "Boss 67",
    Folder = "catpaint",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    Acrylic = true
})

local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local NPCTab = Window:Tab({ Title = "NPCs", Icon = "users" })
local ButtonTab = Window:Tab({ Title = "Button", Icon = "mouse-pointer" })
local PerformanceTab = Window:Tab({ Title = "Performance", Icon = "cpu" })
local ConfigTab = Window:Tab({ Title = "Config", Icon = "save" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
local UITab = Window:Tab({ Title = "UI Settings", Icon = "sliders" })

local Settings = {
    AimEnabled = false,
    AimLock = false,
    TargetType = "Players",
    AimMode = "Legit",
    AimPart = "Head",
    AimSmoothness = 25,
    AimFOV = 180,
    AimDistance = 1000,
    Wallcheck = false,
    ShowFOV = false,
    FOVThickness = 1.5,
    FOVTransparency = 0.15,
    FOVFilled = false,
    ESP = false,
    Names = false,
    Distance = false,
    Health = false,
    HealthStyle = "Bar",
    Box = false,
    Corners = false,
    Chams = false,
    Tracers = false,
    Footsteps = false,
    SelfESP = false,
    SelfBox = false,
    SelfChams = false,
    NPCESP = false,
    NPCName = false,
    NPCDistance = false,
    NPCHealth = false,
    NPCHealthStyle = "Bar",
    NPCBox = false,
    NPCCorners = false,
    NPCChams = false,
    NPCTracer = false,
    ButtonEnabled = false,
    ButtonX = -80,
    ButtonY = -100,
    ButtonSize = 58,
    ButtonTransparency = 0.08,
    Performance = "Balanced",
    PotatoGraphics = false,
    MenuKey = Enum.KeyCode.RightShift,
    Theme = "Dark",
    AccentColor = Color3.fromRGB(114, 137, 218),
    ESPInterval = 0.03,
    AimInterval = 0.01,
    ScanInterval = 1.5,
    NPCInterval = 0.03
}

local COLORS = {
    White = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(235, 235, 245),
    PanelDark = Color3.fromRGB(22, 22, 28),
    Border = Color3.fromRGB(45, 45, 58),
    Accent = Settings.AccentColor,
    ESP = Settings.AccentColor
}

local DEFAULT_ACCENT = Settings.AccentColor
local Camera = Workspace.CurrentCamera
local Connections = {}
local PlayerESP = {}
local NPCESP = {}
local NPCs = {}
local Footsteps = {}
local LastPositions = {}
local Destroyed = false
local LockedTarget = nil
local LockedNPC = nil

local function Connect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Connections, conn)
    return conn
end

local function GetRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function GetHumanoid(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function IsValidNPC(npc)
    if not npc or not npc.Parent then return false end
    local humanoid = GetHumanoid(npc)
    local root = GetRoot(npc)
    if not humanoid or not root or humanoid.Health <= 0 then return false end
    if npc == LocalPlayer.Character then return false end
    return true
end

local function ScanNPCs()
    table.clear(NPCs)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
            if IsValidNPC(obj) then
                table.insert(NPCs, obj)
            end
        end
    end
end

local function GetScreenBox(character)
    if not character or not Camera then return nil end
    local root = GetRoot(character)
    local head = character:FindFirstChild("Head")
    if not root or not head then return nil end
    local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
    local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.8, 0))
    if top.Z <= 0 or bottom.Z <= 0 then return nil end
    local height = math.abs(bottom.Y - top.Y)
    if height < 2 then return nil end
    local width = math.clamp(height * 0.48, 8, 220)
    return bottom.X - width / 2, top.Y, width, height
end

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "meowdlc_ESPGui"
ESPGui.IgnoreGuiInset = true
ESPGui.ResetOnSpawn = false
ESPGui.DisplayOrder = 50
ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ESPGui.Parent = PlayerGui

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "meowdlc_FOVGui"
FOVGui.IgnoreGuiInset = true
FOVGui.ResetOnSpawn = false
FOVGui.DisplayOrder = 40
FOVGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
FOVGui.Parent = PlayerGui

local FOVFrame = Instance.new("Frame")
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Visible = false
FOVFrame.Parent = FOVGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Settings.AccentColor
FOVStroke.Parent = FOVFrame

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame

local function UpdateFOV()
    if not Settings.ShowFOV then
        FOVFrame.Visible = false
        return
    end
    FOVFrame.Visible = true
    local diameter = Settings.AimFOV * 2
    FOVFrame.Size = UDim2.fromOffset(diameter, diameter)
    FOVFrame.Position = UDim2.fromOffset(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVStroke.Thickness = Settings.FOVThickness
    FOVStroke.Transparency = Settings.FOVTransparency
    FOVStroke.Color = Settings.AccentColor
end

local function SetTracer(tracer, start, finish)
    local delta = finish - start
    local length = delta.Magnitude
    tracer.Size = UDim2.fromOffset(1.25, length)
    tracer.Position = UDim2.fromOffset(start.X, start.Y)
    tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X)) - 90
end

local function CreateHealthBar(gui)
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Parent = gui

    local bg = Instance.new("Frame")
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    bg.BorderSizePixel = 0
    bg.Parent = holder

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    fill.BorderSizePixel = 0
    fill.Parent = bg

    return { Holder = holder, Background = bg, Fill = fill }
end

local function UpdateHealthBar(hb, health, maxHealth, x, y, w, h, style)
    if not hb or not hb.Holder then return end
    hb.Holder.Visible = true
    health = math.clamp(health, 0, maxHealth)
    local pct = maxHealth > 0 and (health / maxHealth) or 0

    if style == "Bar" then
        hb.Holder.Position = UDim2.fromOffset(x - 6, y)
        hb.Holder.Size = UDim2.fromOffset(3, h)
        hb.Background.Size = UDim2.fromScale(1, 1)
        hb.Background.Position = UDim2.fromScale(0, 0)
        local fh = h * pct
        hb.Fill.Size = UDim2.fromOffset(3, fh)
        hb.Fill.Position = UDim2.fromOffset(0, h - fh)
        hb.Fill.BackgroundColor3 = Color3.fromRGB(46, 204, 113):Lerp(Color3.fromRGB(231, 76, 60), 1 - pct)
    else
        hb.Holder.Position = UDim2.fromOffset(x, y - 5)
        hb.Holder.Size = UDim2.fromOffset(w, 3)
        hb.Background.Size = UDim2.fromScale(1, 1)
        hb.Background.Position = UDim2.fromScale(0, 0)
        local fw = w * pct
        hb.Fill.Size = UDim2.fromOffset(fw, 3)
        hb.Fill.Position = UDim2.fromScale(0, 0)
        hb.Fill.BackgroundColor3 = Color3.fromRGB(46, 204, 113):Lerp(Color3.fromRGB(231, 76, 60), 1 - pct)
    end
end

local function NewLine(parent)
    local line = Instance.new("Frame")
    line.BackgroundTransparency = 0
    line.BorderSizePixel = 0
    line.Parent = parent
    return line
end

local function UpdateCorners(corners, x, y, w, h)
    local len = math.clamp(math.floor(w / 4), 4, 12)
    local th = 1.25
    if #corners < 8 then return end
    -- Top-left horizontal
    corners[1].Position = UDim2.fromOffset(x, y)
    corners[1].Size = UDim2.fromOffset(len, th)
    -- Top-left vertical
    corners[2].Position = UDim2.fromOffset(x, y)
    corners[2].Size = UDim2.fromOffset(th, len)
    -- Top-right horizontal
    corners[3].Position = UDim2.fromOffset(x + w - len, y)
    corners[3].Size = UDim2.fromOffset(len, th)
    -- Top-right vertical
    corners[4].Position = UDim2.fromOffset(x + w - th, y)
    corners[4].Size = UDim2.fromOffset(th, len)
    -- Bottom-left horizontal
    corners[5].Position = UDim2.fromOffset(x, y + h - th)
    corners[5].Size = UDim2.fromOffset(len, th)
    -- Bottom-left vertical
    corners[6].Position = UDim2.fromOffset(x, y + h - len)
    corners[6].Size = UDim2.fromOffset(th, len)
    -- Bottom-right horizontal
    corners[7].Position = UDim2.fromOffset(x + w - len, y + h - th)
    corners[7].Size = UDim2.fromOffset(len, th)
    -- Bottom-right vertical
    corners[8].Position = UDim2.fromOffset(x + w - th, y + h - len)
    corners[8].Size = UDim2.fromOffset(th, len)
end

local function IsEnemy(player)
    if player == LocalPlayer then return false end
    return true
end

local function DestroyPlayerESP(player)
    local data = PlayerESP[player]
    if not data then return end
    if data.Gui then data.Gui:Destroy() end
    if data.Highlight then data.Highlight:Destroy() end
    PlayerESP[player] = nil
end

local function CreatePlayerESP(player)
    DestroyPlayerESP(player)
    if player == LocalPlayer then return end

    local gui = Instance.new("Frame")
    gui.Name = "ESPBox_" .. player.Name
    gui.BackgroundTransparency = 1
    gui.BorderSizePixel = 0
    gui.Size = UDim2.fromScale(1, 1)
    gui.Parent = ESPGui

    local data = { Gui = gui }

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.25
    stroke.Color = Settings.AccentColor
    stroke.Parent = box

    data.Box = box
    data.BoxStroke = stroke
    data.Corners = {}
    for i = 1, 8 do
        data.Corners[i] = NewLine(gui)
    end

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextSize = 10
    name.TextColor3 = COLORS.White
    name.TextStrokeTransparency = 0.35
    name.Parent = gui
    data.Name = name

    local distance = Instance.new("TextLabel")
    distance.BackgroundTransparency = 1
    distance.Font = Enum.Font.GothamMedium
    distance.TextSize = 9
    distance.TextColor3 = Color3.fromRGB(205, 205, 210)
    distance.TextStrokeTransparency = 0.4
    distance.Parent = gui
    data.Distance = distance

    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.BackgroundColor3 = Settings.AccentColor
    tracer.Parent = gui
    data.Tracer = tracer

    data.HealthBar = CreateHealthBar(gui)

    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_Player_" .. player.Name
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Settings.AccentColor
    highlight.OutlineColor = COLORS.White
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0.05
    highlight.Enabled = Settings.Chams
    highlight.Parent = ESPGui
    data.Highlight = highlight

    PlayerESP[player] = data
end

local function UpdatePlayerESP()
    if not Settings.ESP then
        for player in pairs(PlayerESP) do
            DestroyPlayerESP(player)
        end
        return
    end

    Camera = Workspace.CurrentCamera
    if not Camera then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local root = character and GetRoot(character)
            if character and root and IsEnemy(player) then
                if not PlayerESP[player] then
                    CreatePlayerESP(player)
                end
            else
                DestroyPlayerESP(player)
            end
        end
    end

    for player, data in pairs(PlayerESP) do
        local character = player.Character
        local root = character and GetRoot(character)
        if not character or not root or not IsEnemy(player) then
            DestroyPlayerESP(player)
            continue
        end

        local x, y, w, h = GetScreenBox(character)
        if not x then
            data.Gui.Visible = false
            if data.Highlight then data.Highlight.Enabled = false end
            continue
        end

        data.Gui.Visible = true
        data.Box.Visible = Settings.Box
        data.Box.Position = UDim2.fromOffset(x, y)
        data.Box.Size = UDim2.fromOffset(w, h)
        data.BoxStroke.Color = Settings.AccentColor

        for _, line in ipairs(data.Corners) do
            line.Visible = Settings.Corners
            line.BackgroundColor3 = Settings.AccentColor
        end
        if Settings.Corners then
            UpdateCorners(data.Corners, x, y, w, h)
        end

        data.Name.Visible = Settings.Names
        data.Name.Text = player.Name
        data.Name.Position = UDim2.fromOffset(x, y - 17)
        data.Name.Size = UDim2.fromOffset(w, 14)

        local humanoid = GetHumanoid(character)
        if Settings.Health and humanoid then
            UpdateHealthBar(data.HealthBar, humanoid.Health, humanoid.MaxHealth, x, y, w, h, Settings.HealthStyle)
        else
            data.HealthBar.Holder.Visible = false
        end

        data.Distance.Visible = Settings.Distance
        if Settings.Distance then
            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            data.Distance.Text = math.floor(dist) .. " studs"
            data.Distance.Position = UDim2.fromOffset(x, y + h + (Settings.Health and Settings.HealthStyle == "Bar" and 10 or 3))
            data.Distance.Size = UDim2.fromOffset(w, 12)
        end

        data.Tracer.Visible = Settings.Tracers
        data.Tracer.BackgroundColor3 = Settings.AccentColor
        if Settings.Tracers then
            local viewport = Camera.ViewportSize
            local start = Vector2.new(viewport.X / 2, viewport.Y)
            local finish = Vector2.new(x + w / 2, y + h)
            SetTracer(data.Tracer, start, finish)
        end

        data.Highlight.Enabled = Settings.Chams
        data.Highlight.Adornee = character
        data.Highlight.FillColor = Settings.AccentColor
        data.Highlight.OutlineColor = COLORS.White
    end
end

local function RefreshPlayerESP()
    for player in pairs(PlayerESP) do
        DestroyPlayerESP(player)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreatePlayerESP(player)
        end
    end
end

local function DestroyNPCESP(npc)
    local data = NPCESP[npc]
    if not data then return end
    if data.Gui then data.Gui:Destroy() end
    if data.Highlight then data.Highlight:Destroy() end
    NPCESP[npc] = nil
end

local function CreateNPCESP(npc)
    if NPCESP[npc] or not IsValidNPC(npc) then return end
    local gui = Instance.new("Frame")
    gui.Name = "ESPBox_" .. npc.Name
    gui.BackgroundTransparency = 1
    gui.BorderSizePixel = 0
    gui.Size = UDim2.fromScale(1, 1)
    gui.Parent = ESPGui

    local data = { Gui = gui }
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.25
    stroke.Color = Settings.AccentColor
    stroke.Parent = box
    data.Box = box
    data.BoxStroke = stroke

    data.Corners = {}
    for i = 1, 8 do
        data.Corners[i] = NewLine(gui)
    end

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextSize = 10
    name.TextColor3 = COLORS.White
    name.TextStrokeTransparency = 0.35
    name.Parent = gui
    data.Name = name

    local distance = Instance.new("TextLabel")
    distance.BackgroundTransparency = 1
    distance.Font = Enum.Font.GothamMedium
    distance.TextSize = 9
    distance.TextColor3 = Color3.fromRGB(205, 205, 210)
    distance.TextStrokeTransparency = 0.4
    distance.Parent = gui
    data.Distance = distance

    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.BackgroundColor3 = Settings.AccentColor
    tracer.Parent = gui
    data.Tracer = tracer

    data.HealthBar = CreateHealthBar(gui)

    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_NPC_" .. npc.Name
    highlight.Adornee = npc
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Settings.AccentColor
    highlight.OutlineColor = COLORS.White
    highlight.FillTransparency = 0.78
    highlight.OutlineTransparency = 0.08
    highlight.Enabled = Settings.NPCChams
    highlight.Parent = ESPGui
    data.Highlight = highlight

    NPCESP[npc] = data
end

local function UpdateNPCESP()
    if not Settings.NPCESP then
        for npc in pairs(NPCESP) do
            DestroyNPCESP(npc)
        end
        return
    end

    Camera = Workspace.CurrentCamera
    if not Camera then return end

    for _, npc in ipairs(NPCs) do
        if npc and npc.Parent and IsValidNPC(npc) then
            CreateNPCESP(npc)
        end
    end

    for npc, data in pairs(NPCESP) do
        if not npc or not npc.Parent or not IsValidNPC(npc) then
            DestroyNPCESP(npc)
            continue
        end

        local x, y, w, h = GetScreenBox(npc)
        if not x then
            data.Gui.Visible = false
            continue
        end

        data.Gui.Visible = true
        data.Box.Visible = Settings.NPCBox
        data.Box.Position = UDim2.fromOffset(x, y)
        data.Box.Size = UDim2.fromOffset(w, h)
        data.BoxStroke.Color = Settings.AccentColor

        for _, line in ipairs(data.Corners) do
            line.Visible = Settings.NPCCorners
            line.BackgroundColor3 = Settings.AccentColor
        end
        if Settings.NPCCorners then
            UpdateCorners(data.Corners, x, y, w, h)
        end

        data.Name.Visible = Settings.NPCName
        data.Name.Text = npc.Name
        data.Name.Position = UDim2.fromOffset(x, y - 17)
        data.Name.Size = UDim2.fromOffset(w, 14)

        local humanoid = GetHumanoid(npc)
        if Settings.NPCHealth and humanoid then
            UpdateHealthBar(data.HealthBar, humanoid.Health, humanoid.MaxHealth, x, y, w, h, Settings.NPCHealthStyle)
        else
            data.HealthBar.Holder.Visible = false
        end

        data.Distance.Visible = Settings.NPCDistance
        if Settings.NPCDistance then
            local root = GetRoot(npc)
            if root then
                local distance = (Camera.CFrame.Position - root.Position).Magnitude
                data.Distance.Text = math.floor(distance) .. " studs"
                data.Distance.Position = UDim2.fromOffset(x, y + h + (Settings.NPCHealth and Settings.NPCHealthStyle == "Bar" and 10 or 3))
                data.Distance.Size = UDim2.fromOffset(w, 12)
            end
        end

        data.Tracer.Visible = Settings.NPCTracer
        data.Tracer.BackgroundColor3 = Settings.AccentColor
        if Settings.NPCTracer then
            local viewport = Camera.ViewportSize
            local start = Vector2.new(viewport.X / 2, viewport.Y)
            local finish = Vector2.new(x + w / 2, y + h)
            SetTracer(data.Tracer, start, finish)
        end

        data.Highlight.Enabled = Settings.NPCChams
        data.Highlight.FillColor = Settings.AccentColor
        data.Highlight.OutlineColor = COLORS.White
    end
end

local SelfESPData = {}

local function DestroySelfESP()
    local data = SelfESPData
    if type(data) == "table" then
        if data.Gui then pcall(function() data.Gui:Destroy() end) end
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
    end
    SelfESPData = {}
end

local function CreateSelfESP()
    DestroySelfESP()
    if not Settings.SelfESP then return end
    local character = LocalPlayer.Character
    if not character then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_Self_" .. LocalPlayer.Name
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillColor = Settings.AccentColor
    highlight.OutlineColor = COLORS.White
    highlight.FillTransparency = 0.88
    highlight.OutlineTransparency = 0.05
    highlight.Enabled = Settings.SelfChams
    highlight.Parent = ESPGui
    SelfESPData.Highlight = highlight

    if Settings.SelfBox then
        local gui = Instance.new("Frame")
        gui.Name = "ESPBox_Self_" .. LocalPlayer.Name
        gui.BackgroundTransparency = 1
        gui.Size = UDim2.fromScale(1, 1)
        gui.Parent = ESPGui

        local box = Instance.new("Frame")
        box.BackgroundTransparency = 1
        box.BorderSizePixel = 0
        box.Parent = gui

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.25
        stroke.Color = Settings.AccentColor
        stroke.Parent = box

        SelfESPData.Gui = gui
        SelfESPData.Box = box
        SelfESPData.Stroke = stroke
    end
end

local function GetSelfScreenBox(character)
    if not character or not Camera then return nil end
    local root = GetRoot(character)
    local head = character:FindFirstChild("Head")
    if not root or not head then return nil end
    local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.55, 0))
    local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.8, 0))
    if top.Z <= 0 or bottom.Z <= 0 then return nil end
    local height = math.abs(bottom.Y - top.Y)
    if height < 2 then return nil end
    local width = math.clamp(height * 0.48, 8, 220)
    return bottom.X - width / 2, top.Y, width, height
end

local function UpdateSelfESP()
    if not Settings.SelfESP then return end
    if type(SelfESPData) ~= "table" then
        SelfESPData = {}
        CreateSelfESP()
        return
    end

    local character = LocalPlayer.Character
    if not character then return end

    local highlight = SelfESPData.Highlight
    if highlight and highlight.Parent then
        highlight.Adornee = character
        highlight.Enabled = Settings.SelfChams
        highlight.FillColor = Settings.AccentColor
        highlight.OutlineColor = COLORS.White
    elseif Settings.SelfChams then
        CreateSelfESP()
        return
    end

    local box = SelfESPData.Box
    local gui = SelfESPData.Gui
    local stroke = SelfESPData.Stroke

    if Settings.SelfBox and (not box or not gui or not stroke or not box.Parent or not gui.Parent or not stroke.Parent) then
        CreateSelfESP()
        return
    end

    if box and gui and stroke and box.Parent and gui.Parent and stroke.Parent then
        local x, y, w, h = GetSelfScreenBox(character)
        if x then
            gui.Visible = true
            box.Visible = true
            box.Position = UDim2.fromOffset(x, y)
            box.Size = UDim2.fromOffset(w, h)
            stroke.Color = Settings.AccentColor
        else
            gui.Visible = false
        end
    end
end

local function CreateFootstep(player)
    local character = player.Character
    local root = GetRoot(character)
    if not root then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    local result = Workspace:Raycast(root.Position, Vector3.new(0, -10, 0), params)
    if not result then return end

    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Shape = Enum.PartType.Cylinder
    part.Material = Enum.Material.Neon
    part.Color = Settings.AccentColor
    part.Transparency = 0.2
    part.Size = Vector3.new(0.035, 0.7, 0.7)
    part.CFrame = CFrame.new(result.Position + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, 0, math.rad(90))
    part.Parent = Workspace

    Footsteps[#Footsteps + 1] = part
    task.delay(2, function()
        if part.Parent then part:Destroy() end
    end)
end

local PotatoState = {
    Saved = false,
    Materials = {},
    CastShadows = {},
    Effects = {},
    GlobalShadows = nil,
    FogEnd = nil,
    Brightness = nil,
    EnvironmentDiffuseScale = nil,
    EnvironmentSpecularScale = nil
}

local function ApplyPotatoGraphics()
    if PotatoState.Saved then return end
    PotatoState.Saved = true
    PotatoState.GlobalShadows = Lighting.GlobalShadows
    PotatoState.FogEnd = Lighting.FogEnd
    PotatoState.Brightness = Lighting.Brightness
    PotatoState.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
    PotatoState.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.Brightness = 2
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("BasePart") then
            PotatoState.Materials[object] = object.Material
            PotatoState.CastShadows[object] = object.CastShadow
            object.Material = Enum.Material.SmoothPlastic
            object.CastShadow = false
        elseif object:IsA("ParticleEmitter") or object:IsA("Decal") or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Beam") or object:IsA("Trail") then
            PotatoState.Effects[object] = object.Enabled
            object.Enabled = false
        end
    end
end

local function RestoreGraphics()
    if not PotatoState.Saved then return end
    Lighting.GlobalShadows = PotatoState.GlobalShadows
    Lighting.FogEnd = PotatoState.FogEnd
    Lighting.Brightness = PotatoState.Brightness
    Lighting.EnvironmentDiffuseScale = PotatoState.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale = PotatoState.EnvironmentSpecularScale

    for object, material in pairs(PotatoState.Materials) do
        if object and object.Parent and object:IsA("BasePart") then
            object.Material = material
            object.CastShadow = PotatoState.CastShadows[object] ~= false
        end
    end

    for object, enabled in pairs(PotatoState.Effects) do
        if object and object.Parent then
            object.Enabled = enabled
        end
    end

    PotatoState.Materials = {}
    PotatoState.CastShadows = {}
    PotatoState.Effects = {}
    PotatoState.Saved = false
end

local ButtonGui = Instance.new("ScreenGui")
ButtonGui.Name = "meowdlc_AimButtonGui"
ButtonGui.IgnoreGuiInset = true
ButtonGui.ResetOnSpawn = false
ButtonGui.DisplayOrder = 100
ButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ButtonGui.Parent = PlayerGui

local AimButton = Instance.new("TextButton")
AimButton.AnchorPoint = Vector2.new(1, 1)
AimButton.BackgroundColor3 = COLORS.PanelDark
AimButton.BackgroundTransparency = Settings.ButtonTransparency
AimButton.BorderSizePixel = 0
AimButton.Text = "Aim"
AimButton.TextSize = 11
AimButton.TextColor3 = COLORS.Text
AimButton.Font = Enum.Font.GothamBold
AimButton.AutoButtonColor = false
AimButton.Active = true
AimButton.Visible = false
AimButton.Parent = ButtonGui

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 15)
ButtonCorner.Parent = AimButton

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Thickness = 1
ButtonStroke.Color = COLORS.Border
ButtonStroke.Transparency = 0.15
ButtonStroke.Parent = AimButton

local ButtonStatus = Instance.new("Frame")
ButtonStatus.AnchorPoint = Vector2.new(0.5, 0)
ButtonStatus.Position = UDim2.new(0.5, 0, 0, 7)
ButtonStatus.Size = UDim2.fromOffset(6, 6)
ButtonStatus.BorderSizePixel = 0
ButtonStatus.Parent = AimButton

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(1, 0)
StatusCorner.Parent = ButtonStatus

local function UpdateButton()
    AimButton.Size = UDim2.fromOffset(Settings.ButtonSize, Settings.ButtonSize)
    AimButton.Position = UDim2.new(1, Settings.ButtonX, 1, Settings.ButtonY)
    AimButton.BackgroundTransparency = Settings.ButtonTransparency
    AimButton.Visible = Settings.ButtonEnabled

    if Settings.AimEnabled then
        AimButton.Text = "On"
        AimButton.BackgroundColor3 = Settings.AccentColor
        AimButton.TextColor3 = COLORS.White
        ButtonStatus.BackgroundColor3 = COLORS.White
    else
        AimButton.Text = "Aim"
        AimButton.BackgroundColor3 = Settings.AccentColor:Lerp(COLORS.PanelDark, 0.78)
        AimButton.TextColor3 = COLORS.Text
        ButtonStatus.BackgroundColor3 = Settings.AccentColor
    end
    ButtonStroke.Color = Settings.AccentColor
end

Connect(AimButton.MouseButton1Click, function()
    Settings.AimEnabled = not Settings.AimEnabled
    LockedTarget = nil
    LockedNPC = nil
    UpdateButton()
end)

local ToggleControls = {}

local function MakeToggle(tab, options)
    local control = tab:Toggle(options)
    if control then
        table.insert(ToggleControls, { Control = control, Default = options.Default == true })
    end
    return control
end

CombatTab:Section({ Title = "Aim Settings" })
MakeToggle(CombatTab, { Title = "Aim Enabled", Desc = "Toggles automated target tracking", Default = false, Callback = function(value)
    Settings.AimEnabled = value
    LockedTarget = nil
    LockedNPC = nil
    UpdateButton()
end })
MakeToggle(CombatTab, { Title = "Aim Lock", Desc = "Locks camera directly onto target", Default = false, Callback = function(value)
    Settings.AimLock = value
    LockedTarget = nil
    LockedNPC = nil
end })
CombatTab:Dropdown({ Title = "Target Type", Values = { "Players", "NPCs" }, Value = "Players", Callback = function(value)
    Settings.TargetType = value
    LockedTarget = nil
    LockedNPC = nil
end })
CombatTab:Dropdown({ Title = "Aim Mode", Values = { "Closest", "Legit", "Rage" }, Value = "Legit", Callback = function(value)
    Settings.AimMode = value
end })
CombatTab:Dropdown({ Title = "Aim Part", Values = { "Head", "UpperTorso", "HumanoidRootPart" }, Value = "Head", Callback = function(value)
    Settings.AimPart = value
    LockedTarget = nil
    LockedNPC = nil
end })
CombatTab:Slider({ Title = "Aim Smoothness", Value = { Min = 1, Max = 100, Default = 25 }, Step = 1, Callback = function(value)
    Settings.AimSmoothness = value
end })
CombatTab:Slider({ Title = "FOV Radius", Value = { Min = 20, Max = 600, Default = 180 }, Step = 1, Callback = function(value)
    Settings.AimFOV = value
    UpdateFOV()
end })
CombatTab:Slider({ Title = "Aim Distance", Value = { Min = 100, Max = 3000, Default = 1000 }, Step = 10, Callback = function(value)
    Settings.AimDistance = value
end })
MakeToggle(CombatTab, { Title = "Wallcheck", Default = false, Callback = function(value)
    Settings.Wallcheck = value
end })

CombatTab:Section({ Title = "FOV Customization" })
MakeToggle(CombatTab, { Title = "Show FOV", Default = false, Callback = function(value)
    Settings.ShowFOV = value
    UpdateFOV()
end })
CombatTab:Slider({ Title = "FOV Thickness", Value = { Min = 1, Max = 5, Default = 1.5 }, Step = 0.5, Callback = function(value)
    Settings.FOVThickness = value
    UpdateFOV()
end })
CombatTab:Slider({ Title = "FOV Transparency", Value = { Min = 0, Max = 100, Default = 15 }, Step = 1, Callback = function(value)
    Settings.FOVTransparency = value / 100
    UpdateFOV()
end })
MakeToggle(CombatTab, { Title = "FOV Filled", Default = false, Callback = function(value)
    Settings.FOVFilled = value
    UpdateFOV()
end })

VisualTab:Section({ Title = "Player Visuals" })
MakeToggle(VisualTab, { Title = "Player ESP", Default = false, Callback = function(value)
    Settings.ESP = value
    RefreshPlayerESP()
end })
MakeToggle(VisualTab, { Title = "Names", Default = false, Callback = function(value)
    Settings.Names = value
    RefreshPlayerESP()
end })
MakeToggle(VisualTab, { Title = "Distance", Default = false, Callback = function(value)
    Settings.Distance = value
    RefreshPlayerESP()
end })
MakeToggle(VisualTab, { Title = "Health", Default = false, Callback = function(value)
    Settings.Health = value
    RefreshPlayerESP()
end })
VisualTab:Dropdown({ Title = "Health Style", Values = { "Bar", "Text" }, Value = "Bar", Callback = function(value)
    Settings.HealthStyle = value
end })
MakeToggle(VisualTab, { Title = "Box", Default = false, Callback = function(value)
    Settings.Box = value
    RefreshPlayerESP()
end })
MakeToggle(VisualTab, { Title = "Corners", Default = false, Callback = function(value)
    Settings.Corners = value
    RefreshPlayerESP()
end })
MakeToggle(VisualTab, { Title = "Chams", Default = false, Callback = function(value)
    Settings.Chams = value
    RefreshPlayerESP()
end })
MakeToggle(VisualTab, { Title = "Tracers", Default = false, Callback = function(value)
    Settings.Tracers = value
    RefreshPlayerESP()
end })
MakeToggle(VisualTab, { Title = "Footsteps", Default = false, Callback = function(value)
    Settings.Footsteps = value
end })

VisualTab:Section({ Title = "Self Visuals" })
MakeToggle(VisualTab, { Title = "Self ESP", Default = false, Callback = function(value)
    Settings.SelfESP = value
    if value then CreateSelfESP() else DestroySelfESP() end
end })
MakeToggle(VisualTab, { Title = "Self Box", Default = false, Callback = function(value)
    Settings.SelfBox = value
    if Settings.SelfESP then CreateSelfESP() end
end })
MakeToggle(VisualTab, { Title = "Self Chams", Default = false, Callback = function(value)
    Settings.SelfChams = value
    if Settings.SelfESP then CreateSelfESP() end
end })

NPCTab:Section({ Title = "NPC & Enemy Visuals" })
MakeToggle(NPCTab, { Title = "NPC Target", Default = false, Callback = function(value)
    Settings.TargetType = "NPCs"
    Settings.AimEnabled = value
    LockedNPC = nil
    UpdateButton()
end })
MakeToggle(NPCTab, { Title = "NPC ESP", Default = false, Callback = function(value)
    Settings.NPCESP = value
    UpdateNPCESP()
end })
MakeToggle(NPCTab, { Title = "NPC Names", Default = false, Callback = function(value)
    Settings.NPCName = value
end })
MakeToggle(NPCTab, { Title = "NPC Distance", Default = false, Callback = function(value)
    Settings.NPCDistance = value
end })
MakeToggle(NPCTab, { Title = "NPC Health", Default = false, Callback = function(value)
    Settings.NPCHealth = value
end })
NPCTab:Dropdown({ Title = "NPC Health Style", Values = { "Bar", "Text" }, Value = "Bar", Callback = function(value)
    Settings.NPCHealthStyle = value
end })
MakeToggle(NPCTab, { Title = "NPC Box", Default = false, Callback = function(value)
    Settings.NPCBox = value
end })
MakeToggle(NPCTab, { Title = "NPC Corners", Default = false, Callback = function(value)
    Settings.NPCCorners = value
end })
MakeToggle(NPCTab, { Title = "NPC Chams", Default = false, Callback = function(value)
    Settings.NPCChams = value
end })
MakeToggle(NPCTab, { Title = "NPC Tracers", Default = false, Callback = function(value)
    Settings.NPCTracer = value
end })
NPCTab:Button({ Title = "Scan NPCs", Callback = function()
    ScanNPCs()
    UpdateNPCESP()
end })

ButtonTab:Section({ Title = "Floating Button Customization" })
MakeToggle(ButtonTab, { Title = "Button Enabled", Default = false, Callback = function(value)
    Settings.ButtonEnabled = value
    UpdateButton()
end })
ButtonTab:Slider({ Title = "Button X Offset", Value = { Min = -600, Max = 100, Default = -80 }, Step = 1, Callback = function(value)
    Settings.ButtonX = value
    UpdateButton()
end })
ButtonTab:Slider({ Title = "Button Y Offset", Value = { Min = -600, Max = 100, Default = -100 }, Step = 1, Callback = function(value)
    Settings.ButtonY = value
    UpdateButton()
end })
ButtonTab:Slider({ Title = "Button Size", Value = { Min = 35, Max = 100, Default = 58 }, Step = 1, Callback = function(value)
    Settings.ButtonSize = value
    UpdateButton()
end })
ButtonTab:Slider({ Title = "Button Transparency", Value = { Min = 0, Max = 90, Default = 8 }, Step = 1, Callback = function(value)
    Settings.ButtonTransparency = value / 100
    UpdateButton()
end })

PerformanceTab:Section({ Title = "Performance Optimizer" })
PerformanceTab:Dropdown({ Title = "Performance Mode", Values = { "Low", "Balanced", "Ultra" }, Value = "Balanced", Callback = function(value)
    Settings.Performance = value
end })
PerformanceTab:Paragraph({ Title = "Low", Desc = "Minimal optimizations, best visual quality retained." })
PerformanceTab:Paragraph({ Title = "Balanced", Desc = "Standard optimizations for steady gameplay." })
PerformanceTab:Paragraph({ Title = "Ultra", Desc = "Maximum performance boost, strips heavy rendering." })
MakeToggle(PerformanceTab, { Title = "Potato Graphics", Default = false, Callback = function(value)
    Settings.PotatoGraphics = value
    if value then ApplyPotatoGraphics() else RestoreGraphics() end
end })

local ConfigManager = Window.ConfigManager
local ConfigName = "Default"
local ConfigInput
local ConfigDropdown

local function EncodeConfigValue(value)
    local valueType = typeof(value)
    if valueType == "Color3" then
        return { __type = "Color3", R = value.R, G = value.G, B = value.B }
    end
    if valueType == "EnumItem" then
        return { __type = "Enum", EnumType = tostring(value.EnumType), Name = value.Name }
    end
    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do
            local encoded = EncodeConfigValue(item)
            if encoded ~= nil then result[key] = encoded end
        end
        return result
    end
    if type(value) == "string" or type(value) == "number" or type(value) == "boolean" or value == nil then
        return value
    end
    return nil
end

local function DecodeConfigValue(value)
    if type(value) ~= "table" then return value end
    if value.__type == "Color3" then
        return Color3.new(tonumber(value.R) or 1, tonumber(value.G) or 1, tonumber(value.B) or 1)
    end
    if value.__type == "Enum" then
        if value.EnumType == "KeyCode" and Enum.KeyCode[value.Name] then
            return Enum.KeyCode[value.Name]
        end
        return nil
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = DecodeConfigValue(item)
    end
    return result
end

local function SanitizeConfigName(name)
    name = tostring(name or "Default")
    name = name:gsub("[<>:\"/\\|%?%*]", "_")
    if name == "" then name = "Default" end
    return name:sub(1, 32)
end

local function NotifyConfig(title, content, icon)
    WindUI:Notify({ Title = title, Content = content, Icon = icon, Duration = 3 })
end

local function RefreshConfigDropdown()
    if not ConfigDropdown or not ConfigManager then return end
    local configs = ConfigManager:AllConfigs()
    if #configs == 0 then configs = { "Default" } end
    pcall(function() ConfigDropdown:Refresh(configs) end)
end

local function ApplyLoadedConfig(data)
    if type(data) ~= "table" then return false end
    local loaded = data.Settings
    if type(loaded) ~= "table" then return false end
    loaded = DecodeConfigValue(loaded)
    for key, value in pairs(loaded) do
        if Settings[key] ~= nil and value ~= nil then
            Settings[key] = value
        end
    end
    if Settings.PotatoGraphics then ApplyPotatoGraphics() else RestoreGraphics() end
    UpdateFOV()
    UpdateButton()
    RefreshPlayerESP()
    UpdatePlayerESP()
    UpdateNPCESP()
    UpdateSelfESP()
    pcall(function()
        if Settings.Theme then WindUI:SetTheme(Settings.Theme) end
    end)
    return true
end

local function SaveCurrentConfig(name)
    if not ConfigManager then return false, "Config Manager unavailable" end
    name = SanitizeConfigName(name)
    ConfigName = name
    local config = ConfigManager:CreateConfig(name)
    if not config then return false, "Failed to create config" end
    config:Set("Settings", EncodeConfigValue(Settings))
    config:Set("Version", 1)
    config:Set("SavedAt", os.date("%Y-%m-%d %H:%M:%S"))
    local success = config:Save()
    RefreshConfigDropdown()
    return success, success and nil or "Failed to save config"
end

local function LoadNamedConfig(name)
    if not ConfigManager then return false, "Config Manager unavailable" end
    name = SanitizeConfigName(name)
    ConfigName = name
    local config = ConfigManager:CreateConfig(name)
    if not config then return false, "Failed to load config" end
    local data = config:Load()
    if not data then return false, "Config not found" end
    if not ApplyLoadedConfig(data) then return false, "Failed to apply config data" end
    return true, data.SavedAt
end

ConfigTab:Section({ Title = "Configuration Manager" })
ConfigTab:Paragraph({ Title = "Save System", Desc = "Manage and persist your custom settings profiles locally." })

if ConfigManager then
    pcall(function() ConfigManager:Init(Window) end)
    ConfigInput = ConfigTab:Input({ Title = "Config Name", Value = ConfigName, Callback = function(value)
        ConfigName = SanitizeConfigName(value)
    end })

    local initialConfigs = ConfigManager:AllConfigs()
    if #initialConfigs == 0 then initialConfigs = { "Default" } end

    ConfigDropdown = ConfigTab:Dropdown({ Title = "Select Config", Values = initialConfigs, Value = ConfigName, SearchBarEnabled = true, AllowNone = false, Callback = function(value)
        ConfigName = SanitizeConfigName(value)
        pcall(function() ConfigInput:Set(ConfigName) end)
    end })

    ConfigTab:Button({ Title = "Save Config", Icon = "save", Callback = function()
        local success, reason = SaveCurrentConfig(ConfigName)
        if success then
            NotifyConfig("Config Saved", "Successfully saved config: " .. ConfigName, "save")
        else
            NotifyConfig("Error", tostring(reason), "alert-triangle")
        end
    end })

    ConfigTab:Button({ Title = "Load Config", Icon = "folder-open", Callback = function()
        local success, info = LoadNamedConfig(ConfigName)
        if success then
            NotifyConfig("Config Loaded", "Loaded config: " .. ConfigName .. (info and "\nSaved: " .. tostring(info) or ""), "check-circle")
        else
            NotifyConfig("Error", tostring(info), "alert-triangle")
        end
    end })

    ConfigTab:Button({ Title = "Delete Config", Icon = "trash-2", Callback = function()
        local name = SanitizeConfigName(ConfigName)
        local success = pcall(function() ConfigManager:DeleteConfig(name) end)
        if success then
            RefreshConfigDropdown()
            NotifyConfig("Config Deleted", "Deleted config: " .. name, "trash-2")
        else
            NotifyConfig("Error", "Failed to delete config profile", "alert-triangle")
        end
    end })

    ConfigTab:Button({ Title = "Refresh Configs", Icon = "check-circle", Callback = function()
        RefreshConfigDropdown()
        NotifyConfig("Configs", "Refreshed configuration lists", "check-circle")
    end })

    ConfigTab:Paragraph({ Title = "Status", Desc = "Configs are operational and saving locally." })
else
    ConfigTab:Paragraph({ Title = "Config Unavailable", Desc = "Configuration system is not supported on this executor." })
end

MiscTab:Section({ Title = "Miscellaneous" })
MiscTab:Section({ Title = "Utilities" })
MiscTab:Button({ Title = "Respawn Character", Callback = function()
    local character = LocalPlayer.Character
    local humanoid = character and GetHumanoid(character)
    if humanoid then humanoid.Health = 0 end
end })
MiscTab:Button({ Title = "Rejoin Server", Callback = function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end })
MiscTab:Button({ Title = "Reset All Settings", Callback = function()
    Settings.AimEnabled = false
    Settings.AimLock = false
    Settings.TargetType = "Players"
    Settings.AimMode = "Legit"
    Settings.AimPart = "Head"
    Settings.AimSmoothness = 25
    Settings.AimFOV = 180
    Settings.AimDistance = 1000
    Settings.Wallcheck = false
    Settings.ESP = false
    Settings.Names = false
    Settings.Distance = false
    Settings.Health = false
    Settings.Box = false
    Settings.Corners = false
    Settings.Chams = false
    Settings.Tracers = false
    Settings.NPCESP = false
    Settings.NPCName = false
    Settings.NPCDistance = false
    Settings.NPCHealth = false
    Settings.NPCBox = false
    Settings.NPCCorners = false
    Settings.NPCChams = false
    Settings.NPCTracer = false
    Settings.SelfESP = false
    Settings.SelfBox = false
    Settings.SelfChams = false
    Settings.ButtonEnabled = false
    Settings.ShowFOV = false
    Settings.FOVFilled = false
    Settings.PotatoGraphics = false
    LockedTarget = nil
    LockedNPC = nil

    for _, entry in ipairs(ToggleControls) do
        pcall(function() entry.Control:Set(entry.Default) end)
    end

    DestroySelfESP()
    RefreshPlayerESP()
    UpdateNPCESP()
    UpdateButton()
    UpdateFOV()
    WindUI:Notify({ Title = "Settings", Content = "Settings reset to defaults", Duration = 2 })
end })

local DestroyWindUI

MiscTab:Button({ Title = "Unload Hub", Callback = function()
    Destroyed = true
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    for player in pairs(PlayerESP) do DestroyPlayerESP(player) end
    for npc in pairs(NPCESP) do DestroyNPCESP(npc) end
    DestroySelfESP()
    for _, part in ipairs(Footsteps) do
        if part then pcall(function() part:Destroy() end) end
    end
    if Settings.PotatoGraphics then RestoreGraphics() end
    if FOVGui then FOVGui:Destroy() end
    if ESPGui then ESPGui:Destroy() end
    if ButtonGui then ButtonGui:Destroy() end
    DestroyWindUI()
end })

DestroyWindUI = function()
    pcall(function() Window:Close() end)
    pcall(function() Window:EditOpenButton({ Enabled = false }) end)
    pcall(function() Window:Destroy() end)
    task.defer(function()
        pcall(function()
            for _, child in ipairs(CoreGui:GetChildren()) do
                local lower = string.lower(child.Name)
                if lower:find("catpaint", 1, true) or lower == "windui" or lower:find("windui", 1, true) then
                    child:Destroy()
                end
            end
        end)
    end)
end

UITab:Section({ Title = "Interface Keybind" })
UITab:Keybind({
    Title = "Toggle Menu Key",
    Desc = "PC: press a key here, then use it to open/close the menu",
    Value = "RightShift",
    Callback = function(key)
        local keyName = tostring(key):gsub("^Enum%.KeyCode%.", "")
        local keyCode = Enum.KeyCode[keyName]
        if keyCode then
            Settings.MenuKey = keyCode
            pcall(function()
                Window:SetToggleKey(keyCode)
            end)
        end
    end
})

pcall(function()
    Window:SetToggleKey(Settings.MenuKey)
end)


UITab:Section({ Title = "Theme Manager" })
local themes = {}
pcall(function()
    for themeName in pairs(WindUI:GetThemes()) do
        table.insert(themes, themeName)
    end
end)
if #themes == 0 then themes = { "Dark", "Light", "AMOLED" } end
table.sort(themes)

UITab:Dropdown({ Title = "Select Theme", Values = themes, Value = Settings.Theme, SearchBarEnabled = true, Callback = function(value)
    Settings.Theme = value
    pcall(function() WindUI:SetTheme(value) end)
    UpdateButton()
    UpdateFOV()
end })

UITab:Colorpicker({ Title = "Accent Color", Default = Settings.AccentColor, Transparency = 0, Callback = function(color, transparency)
    Settings.AccentColor = color
    COLORS.Accent = color
    COLORS.ESP = color
    UpdateButton()
    UpdateFOV()

    for _, data in pairs(PlayerESP) do
        if data.BoxStroke then data.BoxStroke.Color = color end
        if data.Highlight then data.Highlight.FillColor = color end
        if data.Highlight then data.Highlight.OutlineColor = COLORS.White end
        if data.Tracer then data.Tracer.BackgroundColor3 = color end
        if data.Corners then
            for _, line in ipairs(data.Corners) do line.BackgroundColor3 = color end
        end
    end

    for _, data in pairs(NPCESP) do
        if data.BoxStroke then data.BoxStroke.Color = color end
        if data.Highlight then data.Highlight.FillColor = color end
        if data.Tracer then data.Tracer.BackgroundColor3 = color end
    end

    if SelfESPData.Highlight then SelfESPData.Highlight.FillColor = color end
    if SelfESPData.Stroke then SelfESPData.Stroke.Color = color end
end })

UITab:Button({ Title = "Reset Accent Color", Callback = function()
    Settings.AccentColor = DEFAULT_ACCENT
    UpdateButton()
    UpdateFOV()
end })

Connect(Players.PlayerAdded, function(player)
    Connect(player.CharacterAdded, function()
        task.wait(0.25)
        if Destroyed then return end
        CreatePlayerESP(player)
        local root = GetRoot(player.Character)
        if root then LastPositions[player] = root.Position end
    end)
end)

Connect(Players.PlayerRemoving, function(player)
    DestroyPlayerESP(player)
    LastPositions[player] = nil
    if LockedTarget and player.Character and LockedTarget:IsDescendantOf(player.Character) then
        LockedTarget = nil
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreatePlayerESP(player)
        local root = GetRoot(player.Character)
        if root then LastPositions[player] = root.Position end
        Connect(player.CharacterAdded, function()
            task.wait(0.25)
            if not Destroyed then CreatePlayerESP(player) end
        end)
    end
end

Connect(LocalPlayer.CharacterAdded, function()
    task.wait(0.25)
    if not Destroyed then CreateSelfESP() end
end)

Connect(LocalPlayer.CharacterRemoving, function()
    LockedTarget = nil
    LockedNPC = nil
    DestroySelfESP()
end)

local aimAccumulator = 0
local espAccumulator = 0
local npcAccumulator = 0
local scanAccumulator = 0
Connect(RunService.RenderStepped, function(dt)
    if Destroyed then return end
    _G.meowdlcLastDT = dt
    Camera = Workspace.CurrentCamera
    if not Camera then return end

    UpdateFOV()

    aimAccumulator += dt
    if aimAccumulator >= Settings.AimInterval then
        aimAccumulator = 0
    end

    espAccumulator += dt
    if espAccumulator >= Settings.ESPInterval then
        espAccumulator = 0
        if Settings.ESP or Settings.Names or Settings.Health or Settings.Distance or Settings.Box or Settings.Corners or Settings.Chams or Settings.Tracers then
            UpdatePlayerESP()
        end
    end

    if Settings.SelfESP then
        pcall(UpdateSelfESP)
    end

    scanAccumulator += dt
    if scanAccumulator >= Settings.ScanInterval then
        scanAccumulator = 0
        ScanNPCs()
    end

    npcAccumulator += dt
    if npcAccumulator >= Settings.NPCInterval then
        npcAccumulator = 0
        UpdateNPCESP()
    end

    UpdateButton()
end)

local footstepAccumulator = 0
Connect(RunService.Heartbeat, function(dt)
    if Destroyed or not Settings.Footsteps then return end
    footstepAccumulator += dt
    if footstepAccumulator < 0.1 then return end
    footstepAccumulator = 0

    for _, player in ipairs(Players:GetPlayers()) do
        if IsEnemy(player) then
            local root = GetRoot(player.Character)
            if root then
                local old = LastPositions[player]
                if old then
                    local moved = (root.Position - old).Magnitude
                    if moved > 0.35 then
                        CreateFootstep(player)
                    end
                end
                LastPositions[player] = root.Position
            end
        end
    end
end)

UpdateFOV()
UpdateButton()
RefreshPlayerESP()
UpdateNPCESP()
CreateSelfESP()

WindUI:Notify({ Title = "catpaint", Content = "Hub loaded successfully!", Duration = 3 })
print("catpaint loaded successfully!")
print("Config manager and UI initialized.")
