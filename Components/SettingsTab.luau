return function(Window)
	local function CloneReference(Object)
		if Eternal and Eternal.Environment.cloneref then
			return Eternal.Environment.cloneref(Object)
		else
			return Object
		end
	end
	
	local Services = setmetatable({}, {
		__index = function(self, Name)
			return CloneReference(game:GetService(Name))
		end
	})

	local Library = Eternal.Interface.Library
	local SaveManager = Eternal.Interface.SaveManager
	local ThemeManager = Eternal.Interface.ThemeManager
	
	local Toggles = Library.Toggles
	local Options = Library.Options
	
	local SettingsTab = Window:AddTab("Settings", "settings")
	local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")
	
	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})

	MenuGroup:AddToggle("WatermarkVisible", {
		Text = "Show Watermark",
		Default = true,
		Callback = function(Value)
			Library:SetWatermarkVisibility(Value)
		end,
	})
	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = false,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})

	MenuGroup:AddDropdown("UILibrary", {
		Text = "UI Style",
		Values = {
			"Obsidian",
			"Linoria"
		},
		Default = (Eternal.UILibrary == "Linoria" and 2 or 1),
		Callback = function(Value)
			if Eternal.Environment.writefile and Eternal.Environment.readfile then
				if not Eternal.Environment.isfile("Eternal/UserData.json") then
					local Data = {
						TotalExecutions = 0,
						UILibrary = "Obsidian"
					}
					Eternal.Environment.writefile("Eternal/UserData.json", Services.HttpService:JSONEncode(Data))
				end

				local UserData = Eternal.Environment.readfile("Eternal/UserData.json")
				local Decoded = Services.HttpService:JSONDecode(UserData)
				Decoded.UILibrary = Value

				if not Decoded.UILibrary then
					Decoded.UILibrary = "Obsidian"
				end

				Eternal.TotalExecutions = Decoded.TotalExecutions
				Eternal.UILibrary = Decoded.UILibrary

				Eternal.Environment.writefile("Eternal/UserData.json", Services.HttpService:JSONEncode(Decoded))
			end
		end
	})
	
	MenuGroup:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
		Default = "100%",
	
		Text = "DPI Scale",
	
		Callback = function(Value)
			Value = Value:gsub("%%", "")
			local DPI = tonumber(Value)
	
			Library:SetDPIScale(DPI)
		end,
	})
	MenuGroup:AddDivider()
	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
	
	MenuGroup:AddButton("Copy Discord Invite", function()
		toclipboard("https://dsc.gg/PB9AHh6sub")
		Library:Notify("Discord invite copied.")
	end)
	
	MenuGroup:AddButton("Unload", function()
		Library:Unload()
	end)
	
	Library.ToggleKeybind = Options.MenuKeybind
	
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({"UILibrary"})
	ThemeManager:SetFolder("Eternal")
	SaveManager:SetFolder("Eternal/" .. Eternal.SavePath)
	SaveManager:BuildConfigSection(SettingsTab)
	ThemeManager:ApplyToTab(SettingsTab)
	SaveManager:LoadAutoloadConfig()
end