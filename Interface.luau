--[[
	Abysall Interface Module - Self-Contained Version
	=================================================
	All external dependencies use multiple fallback CDN mirrors.
	Abysall-owned modules (InfoTab, SettingsTab) are inlined directly.
	
	Usage:
		local Interface = loadstring(game:HttpGet("YOUR_HOSTED_URL/Interface.luau"))()
]]

-- ============================================================
-- 1. CDN MIRROR CONFIGURATION
-- ============================================================
-- Multiple fallback mirrors for the Obsidian UI Library.
-- The first available mirror will be used automatically.
local CDN_MIRRORS = {
	"https://cdn.jsdelivr.net/gh/NightForRoblox/Obsidian@main/",
	"https://cdn.jsdelivr.net/gh/deividcomsono/Obsidian@main/",
	"https://raw.githubusercontent.com/NightForRoblox/Obsidian/refs/heads/main/",
	"https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/",
	"https://gitcdn.xyz/repo/NightForRoblox/Obsidian/main/",
}

-- Helper: try to fetch from multiple mirrors until one works
local function FetchWithFallback(path)
	for _, base in ipairs(CDN_MIRRORS) do
		local url = base .. path
		local success, result = pcall(function()
			return loadstring(game:HttpGet(url, true))()
		end)
		if success and result then
			return result
		end
	end
	error("[Abysall] Failed to load '" .. path .. "' from all CDN mirrors. Check your executor's HTTP capabilities.")
end

-- ============================================================
-- 2. LOAD OBSIDIAN UI LIBRARY (with fallback)
-- ============================================================
local Library = FetchWithFallback("Library.lua")
local SaveManager = FetchWithFallback("addons/SaveManager.lua")
local ThemeManager = FetchWithFallback("addons/ThemeManager.lua")

-- ============================================================
-- 3. INLINED: InfoTab Module
-- ============================================================
local ApplyInfoTab = function(Window)
	local LatestChangelog = {
		"11/7/2026",
		"+ Added Entity ESP Selection",
		"+ Added Item Notifier",
		"+ Added Remove Surge",
		"+ Added Death Farm",
		"+ Fixed Some Broken Features (Bypass Eyes, etc)",
	}

	local function CloneReference(Object)
		if Abysall and Abysall.Environment.cloneref then
			return Abysall.Environment.cloneref(Object)
		else
			return Object
		end
	end

	local Services = setmetatable({}, {
		__index = function(self, Name)
			return CloneReference(game:GetService(Name))
		end
	})

	local LocalPlayer = Services.Players.LocalPlayer
	local InfoTab = Window:AddTab("Info", "user")

	local User = InfoTab:AddLeftGroupbox("User Info")
	local ImageSize = Enum.ThumbnailSize.Size420x420
	local ImageType = Enum.ThumbnailType.HeadShot
	local Content = Services.Players:GetUserThumbnailAsync(LocalPlayer.UserId, ImageType, ImageSize)

	User:AddImage("UserIcon", {
		Image = Content
	})
	User:AddLabel("ID: " .. LocalPlayer.Name, true)
	User:AddLabel("Total Executions: " .. (Abysall.TotalExecutions and Abysall.TotalExecutions or "N/A"), true)

	local Changelog = InfoTab:AddRightGroupbox("Changelog")
	for Index, Change in pairs(LatestChangelog) do
		Changelog:AddLabel(Change, true)
	end

	local Name, Version = Abysall.Environment.identifyexecutor()
	local Executor = InfoTab:AddRightGroupbox("Executor Info")
	Executor:AddLabel("Name: " .. Name, true)
	Executor:AddLabel("Version: " .. (Version and Version or "N/A"), true)
	Executor:AddDivider()
	Executor:AddLabel("Test Result: ", true)

	for Index, Result in pairs(Abysall.Environment.Results) do
		-- fix for veloshitty 💔
		Result = Result:gsub("<", "(")
		Result = Result:gsub(">", ")")
		Executor:AddLabel(Result, true)
	end

	local Community = InfoTab:AddLeftGroupbox("Community")
	Community:AddButton("Copy Discord Invite", function()
		setclipboard("https://dsc.gg/abysallhub")
		Library:Notify("Discord invite copied.")
	end)
end

-- ============================================================
-- 4. INLINED: SettingsTab Module
-- ============================================================
local ApplySettingsTab = function(Window)
	local function CloneReference(Object)
		if Abysall and Abysall.Environment.cloneref then
			return Abysall.Environment.cloneref(Object)
		else
			return Object
		end
	end

	local Services = setmetatable({}, {
		__index = function(self, Name)
			return CloneReference(game:GetService(Name))
		end
	})

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

	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = false,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})

	MenuGroup:AddDropdown("UILibrary", {
		Text = "UI Style",
		Values = { "Obsidian", "Linoria" },
		Default = (Abysall.UILibrary == "Linoria" and 2 or 1),
		Callback = function(Value)
			if Abysall.Environment.writefile and Abysall.Environment.readfile then
				if not Abysall.Environment.isfile("Abysall/UserData.json") then
					local Data = { TotalExecutions = 0, UILibrary = "Obsidian" }
					Abysall.Environment.writefile("Abysall/UserData.json", Services.HttpService:JSONEncode(Data))
				end
				local UserData = Abysall.Environment.readfile("Abysall/UserData.json")
				local Decoded = Services.HttpService:JSONDecode(UserData)
				Decoded.UILibrary = Value
				if not Decoded.UILibrary then
					Decoded.UILibrary = "Obsidian"
				end
				Abysall.TotalExecutions = Decoded.TotalExecutions
				Abysall.UILibrary = Decoded.UILibrary
				Abysall.Environment.writefile("Abysall/UserData.json", Services.HttpService:JSONEncode(Decoded))
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
		setclipboard("https://dsc.gg/abysallhub")
		Library:Notify("Discord invite copied.")
	end)

	MenuGroup:AddButton("Unload", function()
		Library:Unload()
	end)

	Library.ToggleKeybind = Options.MenuKeybind

	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({ "UILibrary" })
	ThemeManager:SetFolder("Abysall")
	SaveManager:SetFolder("Abysall/" .. Abysall.SavePath)
	SaveManager:BuildConfigSection(SettingsTab)
	ThemeManager:ApplyToTab(SettingsTab)
	SaveManager:LoadAutoloadConfig()
end

-- ============================================================
-- 5. ASSEMBLE INTERFACE TABLE
-- ============================================================
local Interface = {
	Library = Library,
	SaveManager = SaveManager,
	ThemeManager = ThemeManager,
	ApplyInfoTab = ApplyInfoTab,
	ApplySettingsTab = ApplySettingsTab,
}

-- ============================================================
-- 6. BUILT-IN THEMES (18 presets)
-- ============================================================
Interface.ThemeManager.BuiltInThemes = {
	-- Default 已改为「奶蓝」配色：柔和奶白底 + 淡雅蓝调
	["Default"]     = { 1,  { FontColor = "2a3b4c", MainColor = "e8f0f8", AccentColor = "5ba3d9", BackgroundColor = "f4f9fd", OutlineColor = "c5dcef" } },
	["CreamBlue"]   = { 19, { FontColor = "2a3b4c", MainColor = "e8f0f8", AccentColor = "5ba3d9", BackgroundColor = "f4f9fd", OutlineColor = "c5dcef" } }, -- 奶蓝（独立预设）
	["BBot"]        = { 2,  { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
	["Fatality"]    = { 3,  { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
	["Jester"]      = { 4,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
	["Mint"]        = { 5,  { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
	["Tokyo Night"] = { 6,  { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
	["Ubuntu"]      = { 7,  { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" } },
	["Quartz"]      = { 8,  { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
	["Nord"]        = { 9,  { FontColor = "eceff4", MainColor = "3b4252", AccentColor = "88c0d0", BackgroundColor = "2e3440", OutlineColor = "4c566a" } },
	["Dracula"]     = { 10, { FontColor = "f8f8f2", MainColor = "44475a", AccentColor = "ff79c6", BackgroundColor = "282a36", OutlineColor = "6272a4" } },
	["Monokai"]     = { 11, { FontColor = "f8f8f2", MainColor = "272822", AccentColor = "f92672", BackgroundColor = "1e1f1c", OutlineColor = "49483e" } },
	["Gruvbox"]     = { 12, { FontColor = "ebdbb2", MainColor = "3c3836", AccentColor = "fb4934", BackgroundColor = "282828", OutlineColor = "504945" } },
	["Solarized"]   = { 13, { FontColor = "839496", MainColor = "073642", AccentColor = "cb4b16", BackgroundColor = "002b36", OutlineColor = "586e75" } },
	["Catppuccin"]  = { 14, { FontColor = "d9e0ee", MainColor = "302d41", AccentColor = "f5c2e7", BackgroundColor = "1e1e2e", OutlineColor = "575268" } },
	["One Dark"]    = { 15, { FontColor = "abb2bf", MainColor = "282c34", AccentColor = "c678dd", BackgroundColor = "21252b", OutlineColor = "5c6370" } },
	["Cyberpunk"]   = { 16, { FontColor = "f9f9f9", MainColor = "262335", AccentColor = "00ff9f", BackgroundColor = "1a1a2e", OutlineColor = "413c5e" } },
	["Oceanic Next"]= { 17, { FontColor = "d8dee9", MainColor = "1b2b34", AccentColor = "6699cc", BackgroundColor = "16232a", OutlineColor = "343d46" } },
	["Material"]    = { 18, { FontColor = "eeffff", MainColor = "212121", AccentColor = "82aaff", BackgroundColor = "151515", OutlineColor = "424242" } },
}

return Interface
