return function(Window)
	local LCH = {
		"7/8/2026",
		"[SCRIPT]",
		"<font color='rgb(0, 255, 0)'>+ Added Always On Top toggle in Settings tab.</font>",
		"<font color='rgb(0, 255, 0)'>+ Changed the Info tab.</font>",
		"<font color='rgb(0, 255, 0)'>+ Added 5 new themes: Anoled, Cipher, Synthwave, Cyber, SirMeme.</font>",
		"[DOORS]",
		"<font color='rgb(0, 255, 0)'>+ New notification instead of the main one (LolhaxV3) in DOORS LOBBY.</font>",
		"<font color='rgb(0, 255, 0)'>+ Added twerk animation (Lobby).</font>",
		"<font color='rgb(0, 255, 0)'>+ Changed locations of some toggles/buttons (Lobby).</font>",
		"<font color='rgb(0, 255, 0)'>+ New notification instead of the main one (LolhaxV3) in DOORS (Lolhax V3 still available).</font>",
		"<font color='rgb(0, 255, 0)'>+ Added twerk animation (Doors).</font>",
		"<font color='rgb(0, 255, 0)'>+ Made Anti Mandrake more consistent (FE).</font>",
		"<font color='rgb(0, 255, 0)'>+ Added Infinite Crucifix (less consistent).</font>",
		"<font color='rgb(0, 255, 0)'>+ Break Door Animations (FE).</font>",
		"<font color='rgb(0, 255, 0)'>+ Added notify when ladder spawns.</font>",
		"<font color='rgb(0, 255, 0)'>+ Added option to choose mstudio45 notification position.</font>",
		"<font color='rgb(0, 255, 0)'>+ Fixed mstudio45 notification volume.</font>",
		"<font color='rgb(0, 255, 0)'>+ Added a useless button.</font>",
		"<font color='rgb(0, 255, 0)'>+ Trigger Figure.</font>",
		"<font color='rgb(0, 255, 0)'>+ Dropdown for selecting which players to kill (Trigger Figure).</font>",
		"<font color='rgb(0, 255, 0)'>+ Minecart Teleport (bad at high ping).</font>",
		"<font color='rgb(0, 255, 0)'>+ Fixed errors appearing on unload (might still have issues).</font>",

	}
    local Games = {
		"🟢 DOORS",
		"🔴 Universal",
	}
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

	local Library = mstudio45.Interface.Library
	local SaveManager = mstudio45.Interface.SaveManager
	local ThemeManager = mstudio45.Interface.ThemeManager

	local Toggles = Library.Toggles
	local Options = Library.Options

	local LocalPlayer = Services.Players.LocalPlayer
	local InfoTab = Window:AddTab("Info", "user")

	local User = InfoTab:AddLeftGroupbox("User", "user")

	local ImageSize = Enum.ThumbnailSize.Size420x420
	local ImageType = Enum.ThumbnailType.HeadShot

	local Content = Services.Players:GetUserThumbnailAsync(LocalPlayer.UserId, ImageType, ImageSize)

	User:AddImage("UserIcon", {
		Image = Content
	})

	local Hour = os.date("*t").hour
	local Greeting
	if Hour >= 5 and Hour < 12 then
		Greeting = "Good Morning"
	elseif Hour >= 12 and Hour < 17 then
		Greeting = "Good Afternoon"
	elseif Hour >= 17 and Hour < 21 then
		Greeting = "Good Evening"
	else
		Greeting = "Good Night"
	end
	User:AddLabel(Greeting .. ", " .. LocalPlayer.Name .. ", ty for using this script you executed: " .. (mstudio45.TotalExecutions and tostring(mstudio45.TotalExecutions) or "N/A") .. " times.", true)
	User:AddDivider()
	User:AddButton("Copy Discord Invite", function()
		toclipboard("https://dsc.gg/mstudio45")
		Library:Notify("Discord invite copied.")
	end)
	local Changelog = InfoTab:AddRightGroupbox("Changelog", "pen-line")
	for Index, Change in pairs(LCH) do
		Changelog:AddLabel(Change, true)
	end

	local GameList = {
		[2440500124] = "Doors",
	}
	local CurrentGame = GameList[game.GameId] or "Universal (" .. game.GameId .. ")"

	local function advancedHash(str)
		local hash = 0
		for i = 1, #str do
			hash = (hash * 31 + str:byte(i)) % 4294967296
		end
		local out = {}
		for i = 1, 16 do
			hash = (hash * 1664525 + 1013904223) % 4294967296
			out[i] = string.char((hash % 26) + 65)
		end
		return table.concat(out)
	end

	local function generateHashedId()
		local id = game:GetService("RbxAnalyticsService"):GetClientId()
		local h = advancedHash(id)
		return string.format("%s-%s-%s-%s", h:sub(1,4), h:sub(5,8), h:sub(9,12), h:sub(13,16))
	end

	local MyHWID = generateHashedId()

	local function fetchHWIDTable()
		local ok, Result = pcall(function()
			return loadstring(game:HttpGet("https://pastefy.app/RGZAbBBb/raw?t=" .. tick()))()
		end)
		if ok and type(Result) == "table" then
			return Result
		end
		return nil
	end

	local function formatTimeLeft(seconds)
		local Days = math.floor(seconds / 86400)
		local Hours = math.floor((seconds % 86400) / 3600)
		local Minutes = math.floor((seconds % 3600) / 60)
		local Secs = math.floor(seconds % 60)

		if Days > 0 then
			return Days .. "d " .. Hours .. "h " .. Minutes .. "m " .. Secs .. "s"
		elseif Hours > 0 then
			return Hours .. "h " .. Minutes .. "m " .. Secs .. "s"
		elseif Minutes > 0 then
			return Minutes .. "m " .. Secs .. "s"
		else
			return Secs .. "s"
		end
	end

	local function getSubscriptionText(HWIDTable)
		local Expiry = HWIDTable and HWIDTable[MyHWID]
		local ExpiryStr = tostring(Expiry or "N/A"):gsub("^%s+", ""):gsub("%s+$", "")
		local ExpiryLower = ExpiryStr:lower()

		if ExpiryLower == "lifetime" or ExpiryLower == "true" then
			return "<font color='rgb(0, 255, 0)'>Active (Lifetime)</font>"
		elseif ExpiryLower == "n/a" or ExpiryLower == "nil" or ExpiryLower == "unknown" then
			return "<font color='rgb(255, 0, 0)'>Unknown</font>"
		else
			local year, month, day, hour, minute = ExpiryStr:match("(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+)")
			if year then
				local expiryUnix = os.time({
					year = tonumber(year),
					month = tonumber(month),
					day = tonumber(day),
					hour = tonumber(hour),
					min = tonumber(minute),
					sec = 0
				})
				local now = os.time() + (2 * 3600)
				if expiryUnix > now then
					local TimeLeft = expiryUnix - now
					return "<font color='rgb(0, 255, 0)'>Active (" .. formatTimeLeft(TimeLeft) .. " left)</font>"
				else
					return "<font color='rgb(255, 0, 0)'>Expired</font>"
				end
			else
				return "<font color='rgb(255, 0, 0)'>Unknown</font>"
			end
		end
	end

	local InfoStuff = InfoTab:AddRightTabbox("idk how to call this :content:")
	local SupportInfo = InfoStuff:AddTab("", "folder")
	local HwidInfo = InfoStuff:AddTab("", "settings")

    for Index, GameStatuses in pairs(Games) do
		SupportInfo:AddLabel(GameStatuses, true)
	end
    SupportInfo:AddDivider()
	SupportInfo:AddLabel("Game: " .. CurrentGame, true)

	local HWIDTable = fetchHWIDTable()
	HwidInfo:AddLabel("HWID: " .. MyHWID, true)
	HwidInfo:AddButton("Copy Hwid", function()
		toclipboard(MyHWID, true)
		Library:Notify("Hwid Copied.")
	end)
	HwidInfo:AddDivider()
	local SubscriptionLabel = HwidInfo:AddLabel("Subscription: " .. getSubscriptionText(HWIDTable), true)

	spawn(function()
		while true do
			task.wait(1)
			HWIDTable = fetchHWIDTable()
			SubscriptionLabel:SetText("Subscription: " .. getSubscriptionText(HWIDTable), true)
		end
	end)
end
