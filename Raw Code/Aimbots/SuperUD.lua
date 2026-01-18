--// Preventing Multiple Processes

pcall(function()
	getgenv().Aimbot.Functions:Exit()
end)

--// Environment

getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

--// Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Camera = game:GetService("Workspace").CurrentCamera

--// Variables

local LocalPlayer = Players.LocalPlayer
local Title = "HydraWare Lua"
local FileNames = {"Aimbot", "Configuration.json", "Drawing.json"}
local Typing, Running, Animation, RequiredDistance, ServiceConnections = false, false, nil, 2000, {}
local WaitingForInput = false
local MenuToggleBind = Enum.KeyCode.RightAlt
local MenuOpen = true

--// Support Functions

local mousemoverel = mousemoverel or (Input and Input.MouseMove)
local queueonteleport = queue_on_teleport or syn.queue_on_teleport

--// Script Settings

Environment.Settings = {
	SendNotifications = true,
	SaveSettings = false,
	ReloadOnTeleport = false,
	Enabled = false,
	TeamCheck = false,
	AliveCheck = true,
	WallCheck = false,
	Sensitivity = 0,
	ThirdPerson = false,
	ThirdPersonSensitivity = 3,
	TriggerKey = "MouseButton2",
	Toggle = false,
	LockPart = "Head",
	AimbotType = "Memory",
	SilentAimFOV = 3,
	Chams = false,
	ESPEnabled = false,
	ESPColor = "FF0000"
}

Environment.FOVSettings = {
	Enabled = true,
	Visible = true,
	Amount = 90,
	Color = "255, 255, 255",
	LockedColor = "255, 70, 70",
	Transparency = 0.5,
	Sides = 60,
	Thickness = 1,
	Filled = false
}

Environment.FOVCircle = Drawing.new("Circle")
Environment.Locked = nil
Environment.SilentTarget = nil
Environment.OriginalSizes = {}
Environment.ChamsHighlights = {}
Environment.ESPBoxes = {}

--// Core Functions

local function Encode(Table)
	if Table and type(Table) == "table" then
		local EncodedTable = HttpService:JSONEncode(Table)
		return EncodedTable
	end
end

local function Decode(String)
	if String and type(String) == "string" then
		local DecodedTable = HttpService:JSONDecode(String)
		return DecodedTable
	end
end

local function GetColor(Color)
	local R = tonumber(string.match(Color, "([%d]+)[%s]*,[%s]*[%d]+[%s]*,[%s]*[%d]+"))
	local G = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*([%d]+)[%s]*,[%s]*[%d]+"))
	local B = tonumber(string.match(Color, "[%d]+[%s]*,[%s]*[%d]+[%s]*,[%s]*([%d]+)"))
	return Color3.fromRGB(R, G, B)
end

local function HexToRGB(hex)
	hex = hex:gsub("#", "")
	if #hex == 6 then
		local r = tonumber("0x" .. hex:sub(1, 2))
		local g = tonumber("0x" .. hex:sub(3, 4))
		local b = tonumber("0x" .. hex:sub(5, 6))
		return Color3.fromRGB(r, g, b)
	end
	return Color3.fromRGB(255, 0, 0)
end

local function RainbowColor(offset)
	local hue = (tick() * 0.5 + (offset or 0)) % 1
	return Color3.fromHSV(hue, 1, 1)
end

local function SendNotification(TitleArg, DescriptionArg, DurationArg)
	if Environment.Settings.SendNotifications then
		StarterGui:SetCore("SendNotification", {
			Title = TitleArg,
			Text = DescriptionArg,
			Duration = DurationArg
		})
	end
end

--// Chams Functions (Independent Rainbow Highlight)

local function CreateChams(player)
	if not player or not player.Character then return end
	
	-- Remove existing chams first
	if Environment.ChamsHighlights[player] then
		RemoveChams(player)
	end
	
	-- Wait for character to fully load
	local character = player.Character
	if not character:FindFirstChild("HumanoidRootPart") then
		character:WaitForChild("HumanoidRootPart", 3)
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "ChamsHighlight"
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
	
	Environment.ChamsHighlights[player] = highlight
end

local function RemoveChams(player)
	if Environment.ChamsHighlights[player] then
		Environment.ChamsHighlights[player]:Destroy()
		Environment.ChamsHighlights[player] = nil
	end
end

local function UpdateChams()
	if not Environment.Settings.Chams then
		for player, _ in pairs(Environment.ChamsHighlights) do
			RemoveChams(player)
		end
		return
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if Environment.Settings.TeamCheck and player.Team == LocalPlayer.Team then
				RemoveChams(player)
			else
				CreateChams(player)
			end
		end
	end
end

--// ESP Functions (Box around players with custom color)

local function CreateESP(player)
	if not player then return end
	
	-- Remove existing ESP first
	if Environment.ESPBoxes[player] then
		RemoveESP(player)
	end
	
	-- Wait for character
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	
	local char = player.Character
	if not char then return end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		hrp = char:WaitForChild("HumanoidRootPart", 3)
	end
	if not hrp then return end
	
	-- Create ESP box using Drawing library
	local box = {
		TopLeft = Drawing.new("Line"),
		TopRight = Drawing.new("Line"),
		BottomLeft = Drawing.new("Line"),
		BottomRight = Drawing.new("Line"),
		LeftSide = Drawing.new("Line"),
		RightSide = Drawing.new("Line"),
		TopSide = Drawing.new("Line"),
		BottomSide = Drawing.new("Line"),
		Name = Drawing.new("Text")
	}
	
	local espColor = HexToRGB(Environment.Settings.ESPColor)
	
	for _, line in pairs(box) do
		if line.ClassName == "Line" then
			line.Visible = false
			line.Color = espColor
			line.Thickness = 2
			line.Transparency = 1
		elseif line.ClassName == "Text" then
			line.Visible = false
			line.Color = espColor
			line.Size = 16
			line.Center = true
			line.Outline = true
			line.Font = 2
			line.Transparency = 1
		end
	end
	
	Environment.ESPBoxes[player] = box
end

local function RemoveESP(player)
	if Environment.ESPBoxes[player] then
		for _, drawing in pairs(Environment.ESPBoxes[player]) do
			drawing:Remove()
		end
		Environment.ESPBoxes[player] = nil
	end
end

local function UpdateESPBoxes()
	if not Environment.Settings.ESPEnabled then
		for player, _ in pairs(Environment.ESPBoxes) do
			RemoveESP(player)
		end
		return
	end
	
	for player, box in pairs(Environment.ESPBoxes) do
		if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			for _, drawing in pairs(box) do
				drawing.Visible = false
			end
			continue
		end
		
		local char = player.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		
		if not hrp or not head then continue end
		
		local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
		
		if not onScreen then
			for _, drawing in pairs(box) do
				drawing.Visible = false
			end
			continue
		end
		
		-- Calculate box dimensions
		local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
		local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
		
		local height = math.abs(headPos.Y - legPos.Y)
		local width = height / 2
		
		local x = hrpPos.X - width / 2
		local y = headPos.Y
		
		local espColor = HexToRGB(Environment.Settings.ESPColor)
		
		-- Update box lines
		box.TopLeft.From = Vector2.new(x, y)
		box.TopLeft.To = Vector2.new(x, y + height / 4)
		box.TopLeft.Visible = true
		box.TopLeft.Color = espColor
		
		box.TopRight.From = Vector2.new(x + width, y)
		box.TopRight.To = Vector2.new(x + width, y + height / 4)
		box.TopRight.Visible = true
		box.TopRight.Color = espColor
		
		box.BottomLeft.From = Vector2.new(x, y + height)
		box.BottomLeft.To = Vector2.new(x, y + height - height / 4)
		box.BottomLeft.Visible = true
		box.BottomLeft.Color = espColor
		
		box.BottomRight.From = Vector2.new(x + width, y + height)
		box.BottomRight.To = Vector2.new(x + width, y + height - height / 4)
		box.BottomRight.Visible = true
		box.BottomRight.Color = espColor
		
		box.LeftSide.From = Vector2.new(x, y)
		box.LeftSide.To = Vector2.new(x + width / 4, y)
		box.LeftSide.Visible = true
		box.LeftSide.Color = espColor
		
		box.RightSide.From = Vector2.new(x + width, y)
		box.RightSide.To = Vector2.new(x + width - width / 4, y)
		box.RightSide.Visible = true
		box.RightSide.Color = espColor
		
		box.TopSide.From = Vector2.new(x, y + height)
		box.TopSide.To = Vector2.new(x + width / 4, y + height)
		box.TopSide.Visible = true
		box.TopSide.Color = espColor
		
		box.BottomSide.From = Vector2.new(x + width, y + height)
		box.BottomSide.To = Vector2.new(x + width - width / 4, y + height)
		box.BottomSide.Visible = true
		box.BottomSide.Color = espColor
		
		-- Update name
		box.Name.Position = Vector2.new(x + width / 2, y - 20)
		box.Name.Text = player.Name
		box.Name.Visible = true
		box.Name.Color = espColor
	end
end

--// Create ESP for all players
local function InitializeESP()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			CreateESP(player)
		end
	end
end

--// GUI Creation

local function CreateGUI()
	local ScreenGui = Instance.new("ScreenGui")
	local MainFrame = Instance.new("Frame")
	local Title = Instance.new("TextLabel")
	local Line = Instance.new("Frame")
	local EnabledBtn = Instance.new("TextButton")
	local ChangeBindBtn = Instance.new("TextButton")
	local ChangeMenuBindBtn = Instance.new("TextButton")
	local BindLabel = Instance.new("TextLabel")
	local MenuBindLabel = Instance.new("TextLabel")
	local FOVLabel = Instance.new("TextLabel")
	local FOVSlider = Instance.new("TextButton")
	local FOVFill = Instance.new("Frame")
	local FOVValueLabel = Instance.new("TextLabel")
	
	local AimbotTypeLabel = Instance.new("TextLabel")
	local AimbotTypeBtn = Instance.new("TextButton")
	local AimbotTypeDropdown = Instance.new("Frame")
	local MemoryOption = Instance.new("TextButton")
	local SilentOption = Instance.new("TextButton")
	
	local SilentFOVLabel = Instance.new("TextLabel")
	local SilentFOVSlider = Instance.new("TextButton")
	local SilentFOVFill = Instance.new("Frame")
	local SilentFOVValueLabel = Instance.new("TextLabel")
	
	-- NEW: Chams Button
	local ChamsBtn = Instance.new("TextButton")
	
	-- NEW: ESP Section
	local ESPBtn = Instance.new("TextButton")
	local ESPColorLabel = Instance.new("TextLabel")
	local ESPColorInput = Instance.new("TextBox")
	
	ScreenGui.Name = "AimbotGUI"
	ScreenGui.Parent = game.CoreGui
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.ResetOnSpawn = false
	
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
	MainFrame.BorderSizePixel = 1
	MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
	MainFrame.Size = UDim2.new(0, 220, 0, 450)
	MainFrame.Active = true
	MainFrame.Draggable = true
	
	Title.Name = "Title"
	Title.Parent = MainFrame
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 0, 0, 0)
	Title.Size = UDim2.new(1, 0, 0, 25)
	Title.Font = Enum.Font.Code
	Title.Text = "  aimbot"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTransparency = 0.3
	
	Line.Name = "Line"
	Line.Parent = MainFrame
	Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	Line.BorderSizePixel = 0
	Line.Position = UDim2.new(0, 0, 0, 25)
	Line.Size = UDim2.new(1, 0, 0, 1)
	
	EnabledBtn.Name = "EnabledBtn"
	EnabledBtn.Parent = MainFrame
	EnabledBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	EnabledBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
	EnabledBtn.Position = UDim2.new(0, 10, 0, 35)
	EnabledBtn.Size = UDim2.new(0, 90, 0, 22)
	EnabledBtn.Font = Enum.Font.Code
	EnabledBtn.Text = "enabled"
	EnabledBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	EnabledBtn.TextSize = 13
	
	AimbotTypeLabel.Name = "AimbotTypeLabel"
	AimbotTypeLabel.Parent = MainFrame
	AimbotTypeLabel.BackgroundTransparency = 1
	AimbotTypeLabel.Position = UDim2.new(0, 10, 0, 62)
	AimbotTypeLabel.Size = UDim2.new(1, -20, 0, 20)
	AimbotTypeLabel.Font = Enum.Font.Code
	AimbotTypeLabel.Text = "aimbot type"
	AimbotTypeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	AimbotTypeLabel.TextSize = 12
	AimbotTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	AimbotTypeBtn.Name = "AimbotTypeBtn"
	AimbotTypeBtn.Parent = MainFrame
	AimbotTypeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	AimbotTypeBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
	AimbotTypeBtn.Position = UDim2.new(0, 10, 0, 85)
	AimbotTypeBtn.Size = UDim2.new(0, 90, 0, 22)
	AimbotTypeBtn.Font = Enum.Font.Code
	AimbotTypeBtn.Text = "Memory"
	AimbotTypeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	AimbotTypeBtn.TextSize = 13
	AimbotTypeBtn.ZIndex = 2
	
	AimbotTypeDropdown.Name = "AimbotTypeDropdown"
	AimbotTypeDropdown.Parent = MainFrame
	AimbotTypeDropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	AimbotTypeDropdown.BorderColor3 = Color3.fromRGB(60, 60, 60)
	AimbotTypeDropdown.Position = UDim2.new(0, 10, 0, 107)
	AimbotTypeDropdown.Size = UDim2.new(0, 90, 0, 44)
	AimbotTypeDropdown.Visible = false
	AimbotTypeDropdown.ZIndex = 3
	
	MemoryOption.Name = "MemoryOption"
	MemoryOption.Parent = AimbotTypeDropdown
	MemoryOption.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	MemoryOption.BorderColor3 = Color3.fromRGB(60, 60, 60)
	MemoryOption.BorderSizePixel = 0
	MemoryOption.Position = UDim2.new(0, 0, 0, 0)
	MemoryOption.Size = UDim2.new(1, 0, 0, 22)
	MemoryOption.Font = Enum.Font.Code
	MemoryOption.Text = "Memory"
	MemoryOption.TextColor3 = Color3.fromRGB(255, 255, 255)
	MemoryOption.TextSize = 12
	MemoryOption.ZIndex = 4
	
	SilentOption.Name = "SilentOption"
	SilentOption.Parent = AimbotTypeDropdown
	SilentOption.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	SilentOption.BorderColor3 = Color3.fromRGB(60, 60, 60)
	SilentOption.BorderSizePixel = 0
	SilentOption.Position = UDim2.new(0, 0, 0, 22)
	SilentOption.Size = UDim2.new(1, 0, 0, 22)
	SilentOption.Font = Enum.Font.Code
	SilentOption.Text = "Silent"
	SilentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
	SilentOption.TextSize = 12
	SilentOption.ZIndex = 4
	
	ChangeBindBtn.Name = "ChangeBindBtn"
	ChangeBindBtn.Parent = MainFrame
	ChangeBindBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	ChangeBindBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
	ChangeBindBtn.Position = UDim2.new(0, 10, 0, 118)
	ChangeBindBtn.Size = UDim2.new(0, 90, 0, 22)
	ChangeBindBtn.Font = Enum.Font.Code
	ChangeBindBtn.Text = "change bind"
	ChangeBindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ChangeBindBtn.TextSize = 13
	
	ChangeMenuBindBtn.Name = "ChangeMenuBindBtn"
	ChangeMenuBindBtn.Parent = MainFrame
	ChangeMenuBindBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	ChangeMenuBindBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
	ChangeMenuBindBtn.Position = UDim2.new(0, 10, 0, 170)
	ChangeMenuBindBtn.Size = UDim2.new(0, 90, 0, 22)
	ChangeMenuBindBtn.Font = Enum.Font.Code
	ChangeMenuBindBtn.Text = "menu bind"
	ChangeMenuBindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ChangeMenuBindBtn.TextSize = 13
	
	BindLabel.Name = "BindLabel"
	BindLabel.Parent = MainFrame
	BindLabel.BackgroundTransparency = 1
	BindLabel.Position = UDim2.new(0, 10, 0, 143)
	BindLabel.Size = UDim2.new(1, -20, 0, 20)
	BindLabel.Font = Enum.Font.Code
	BindLabel.Text = "bind: MouseButton2"
	BindLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	BindLabel.TextSize = 12
	BindLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	MenuBindLabel.Name = "MenuBindLabel"
	MenuBindLabel.Parent = MainFrame
	MenuBindLabel.BackgroundTransparency = 1
	MenuBindLabel.Position = UDim2.new(0, 10, 0, 195)
	MenuBindLabel.Size = UDim2.new(1, -20, 0, 20)
	MenuBindLabel.Font = Enum.Font.Code
	MenuBindLabel.Text = "menu: RightAlt"
	MenuBindLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	MenuBindLabel.TextSize = 12
	MenuBindLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	FOVLabel.Name = "FOVLabel"
	FOVLabel.Parent = MainFrame
	FOVLabel.BackgroundTransparency = 1
	FOVLabel.Position = UDim2.new(0, 10, 0, 220)
	FOVLabel.Size = UDim2.new(1, -20, 0, 20)
	FOVLabel.Font = Enum.Font.Code
	FOVLabel.Text = "fov"
	FOVLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	FOVLabel.TextSize = 12
	FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	FOVSlider.Name = "FOVSlider"
	FOVSlider.Parent = MainFrame
	FOVSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	FOVSlider.BorderColor3 = Color3.fromRGB(60, 60, 60)
	FOVSlider.Position = UDim2.new(0, 10, 0, 245)
	FOVSlider.Size = UDim2.new(0, 150, 0, 20)
	FOVSlider.AutoButtonColor = false
	FOVSlider.Text = ""
	
	FOVFill.Name = "FOVFill"
	FOVFill.Parent = FOVSlider
	FOVFill.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	FOVFill.BorderSizePixel = 0
	FOVFill.Size = UDim2.new(0.857, 0, 1, 0)
	
	FOVValueLabel.Name = "FOVValueLabel"
	FOVValueLabel.Parent = MainFrame
	FOVValueLabel.BackgroundTransparency = 1
	FOVValueLabel.Position = UDim2.new(0, 165, 0, 245)
	FOVValueLabel.Size = UDim2.new(0, 45, 0, 20)
	FOVValueLabel.Font = Enum.Font.Code
	FOVValueLabel.Text = "90"
	FOVValueLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	FOVValueLabel.TextSize = 12
	
	SilentFOVLabel.Name = "SilentFOVLabel"
	SilentFOVLabel.Parent = MainFrame
	SilentFOVLabel.BackgroundTransparency = 1
	SilentFOVLabel.Position = UDim2.new(0, 10, 0, 270)
	SilentFOVLabel.Size = UDim2.new(1, -20, 0, 20)
	SilentFOVLabel.Font = Enum.Font.Code
	SilentFOVLabel.Text = "silent hitbox"
	SilentFOVLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	SilentFOVLabel.TextSize = 12
	SilentFOVLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	SilentFOVSlider.Name = "SilentFOVSlider"
	SilentFOVSlider.Parent = MainFrame
	SilentFOVSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	SilentFOVSlider.BorderColor3 = Color3.fromRGB(60, 60, 60)
	SilentFOVSlider.Position = UDim2.new(0, 10, 0, 295)
	SilentFOVSlider.Size = UDim2.new(0, 150, 0, 20)
	SilentFOVSlider.AutoButtonColor = false
	SilentFOVSlider.Text = ""
	
	SilentFOVFill.Name = "SilentFOVFill"
	SilentFOVFill.Parent = SilentFOVSlider
	SilentFOVFill.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	SilentFOVFill.BorderSizePixel = 0
	SilentFOVFill.Size = UDim2.new(0.2, 0, 1, 0)
	
	SilentFOVValueLabel.Name = "SilentFOVValueLabel"
	SilentFOVValueLabel.Parent = MainFrame
	SilentFOVValueLabel.BackgroundTransparency = 1
	SilentFOVValueLabel.Position = UDim2.new(0, 165, 0, 295)
	SilentFOVValueLabel.Size = UDim2.new(0, 45, 0, 20)
	SilentFOVValueLabel.Font = Enum.Font.Code
	SilentFOVValueLabel.Text = "3"
	SilentFOVValueLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	SilentFOVValueLabel.TextSize = 12
	
	-- NEW: Chams Button
	ChamsBtn.Name = "ChamsBtn"
	ChamsBtn.Parent = MainFrame
	ChamsBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	ChamsBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
	ChamsBtn.Position = UDim2.new(0, 10, 0, 325)
	ChamsBtn.Size = UDim2.new(0, 90, 0, 22)
	ChamsBtn.Font = Enum.Font.Code
	ChamsBtn.Text = "chams"
	ChamsBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
	ChamsBtn.TextSize = 13
	
	-- NEW: ESP Button
	ESPBtn.Name = "ESPBtn"
	ESPBtn.Parent = MainFrame
	ESPBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	ESPBtn.BorderColor3 = Color3.fromRGB(60, 60, 60)
	ESPBtn.Position = UDim2.new(0, 10, 0, 357)
	ESPBtn.Size = UDim2.new(0, 90, 0, 22)
	ESPBtn.Font = Enum.Font.Code
	ESPBtn.Text = "esp"
	ESPBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
	ESPBtn.TextSize = 13
	
	-- NEW: ESP Color Label
	ESPColorLabel.Name = "ESPColorLabel"
	ESPColorLabel.Parent = MainFrame
	ESPColorLabel.BackgroundTransparency = 1
	ESPColorLabel.Position = UDim2.new(0, 10, 0, 387)
	ESPColorLabel.Size = UDim2.new(1, -20, 0, 20)
	ESPColorLabel.Font = Enum.Font.Code
	ESPColorLabel.Text = "esp color (hex)"
	ESPColorLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	ESPColorLabel.TextSize = 12
	ESPColorLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	-- NEW: ESP Color Input
	ESPColorInput.Name = "ESPColorInput"
	ESPColorInput.Parent = MainFrame
	ESPColorInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	ESPColorInput.BorderColor3 = Color3.fromRGB(60, 60, 60)
	ESPColorInput.Position = UDim2.new(0, 10, 0, 412)
	ESPColorInput.Size = UDim2.new(0, 90, 0, 22)
	ESPColorInput.Font = Enum.Font.Code
	ESPColorInput.Text = "FF0000"
	ESPColorInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	ESPColorInput.TextSize = 13
	ESPColorInput.PlaceholderText = "FF0000"
	ESPColorInput.ClearTextOnFocus = false
	
	-- Slider functionality
	local dragging = false
	local function updateFOV(input)
		local pos = math.clamp((input.Position.X - FOVSlider.AbsolutePosition.X) / FOVSlider.AbsoluteSize.X, 0, 1)
		local fovValue = math.floor(15 + (pos * 285))
		Environment.FOVSettings.Amount = fovValue
		FOVFill.Size = UDim2.new(pos, 0, 1, 0)
		FOVValueLabel.Text = tostring(fovValue)
	end
	
	FOVSlider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFOV(input)
		end
	end)
	
	FOVSlider.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFOV(input)
		end
	end)
	
	local silentDragging = false
	local function updateSilentFOV(input)
		local pos = math.clamp((input.Position.X - SilentFOVSlider.AbsolutePosition.X) / SilentFOVSlider.AbsoluteSize.X, 0, 1)
		local silentValue = math.floor(1 + (pos * 9))
		Environment.Settings.SilentAimFOV = silentValue
		SilentFOVFill.Size = UDim2.new(pos, 0, 1, 0)
		SilentFOVValueLabel.Text = tostring(silentValue)
	end
	
	SilentFOVSlider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			silentDragging = true
			updateSilentFOV(input)
		end
	end)
	
	SilentFOVSlider.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			silentDragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if silentDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSilentFOV(input)
		end
	end)
	
	-- Set initial slider positions
	local initialPos = (Environment.FOVSettings.Amount - 15) / 285
	FOVFill.Size = UDim2.new(initialPos, 0, 1, 0)
	FOVValueLabel.Text = tostring(Environment.FOVSettings.Amount)
	
	local initialSilentPos = (Environment.Settings.SilentAimFOV - 1) / 9
	SilentFOVFill.Size = UDim2.new(initialSilentPos, 0, 1, 0)
	SilentFOVValueLabel.Text = tostring(Environment.Settings.SilentAimFOV)
	
	-- Toggle Enabled
	EnabledBtn.MouseButton1Click:Connect(function()
		Environment.Settings.Enabled = not Environment.Settings.Enabled
		if Environment.Settings.Enabled then
			EnabledBtn.Text = "enabled"
			EnabledBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			EnabledBtn.Text = "disabled"
			EnabledBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
			Running = false
			Environment.Locked = nil
			Environment.SilentTarget = nil
			if Animation then Animation:Cancel() end
			Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
		end
		SaveSettings()
	end)
	
	-- Aimbot Type Dropdown
	AimbotTypeBtn.MouseButton1Click:Connect(function()
		AimbotTypeDropdown.Visible = not AimbotTypeDropdown.Visible
	end)
	
	MemoryOption.MouseButton1Click:Connect(function()
		Environment.Settings.AimbotType = "Memory"
		AimbotTypeBtn.Text = "Memory"
		AimbotTypeDropdown.Visible = false
		Environment.SilentTarget = nil
		SaveSettings()
	end)
	
	SilentOption.MouseButton1Click:Connect(function()
		Environment.Settings.AimbotType = "Silent"
		AimbotTypeBtn.Text = "Silent"
		AimbotTypeDropdown.Visible = false
		Environment.Locked = nil
		if Animation then Animation:Cancel() end
		SaveSettings()
	end)
	
	-- Chams Toggle
	ChamsBtn.MouseButton1Click:Connect(function()
		Environment.Settings.Chams = not Environment.Settings.Chams
		if Environment.Settings.Chams then
			ChamsBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
		else
			ChamsBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
		UpdateChams()
		SaveSettings()
	end)
	
	-- ESP Toggle
	ESPBtn.MouseButton1Click:Connect(function()
		Environment.Settings.ESPEnabled = not Environment.Settings.ESPEnabled
		if Environment.Settings.ESPEnabled then
			ESPBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
			InitializeESP()
		else
			ESPBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
		SaveSettings()
	end)
	
	-- ESP Color Input
	ESPColorInput.FocusLost:Connect(function()
		local text = ESPColorInput.Text:gsub("#", ""):upper()
		if #text == 6 and text:match("^[0-9A-F]+$") then
			Environment.Settings.ESPColor = text
			ESPColorInput.Text = text
			SaveSettings()
		else
			ESPColorInput.Text = Environment.Settings.ESPColor
		end
	end)
	
	-- Change Bind functions
	ChangeBindBtn.MouseButton1Click:Connect(function()
		if not WaitingForInput then
			WaitingForInput = true
			ChangeBindBtn.Text = "..."
			
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, processed)
				if not processed and input.UserInputType ~= Enum.UserInputType.MouseMovement and WaitingForInput then
					WaitingForInput = false
					
					if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
						Environment.Settings.TriggerKey = input.KeyCode.Name
						BindLabel.Text = "bind: " .. input.KeyCode.Name
					elseif input.UserInputType then
						Environment.Settings.TriggerKey = input.UserInputType.Name
						BindLabel.Text = "bind: " .. input.UserInputType.Name
					end
					
					ChangeBindBtn.Text = "change bind"
					SaveSettings()
					connection:Disconnect()
				end
			end)
		end
	end)
	
	ChangeMenuBindBtn.MouseButton1Click:Connect(function()
		if not WaitingForInput then
			WaitingForInput = true
			ChangeMenuBindBtn.Text = "..."
			
			local connection
			connection = UserInputService.InputBegan:Connect(function(input, processed)
				if not processed and input.UserInputType ~= Enum.UserInputType.MouseMovement and input.KeyCode ~= Enum.KeyCode.Unknown and WaitingForInput then
					WaitingForInput = false
					MenuToggleBind = input.KeyCode
					MenuBindLabel.Text = "menu: " .. input.KeyCode.Name
					ChangeMenuBindBtn.Text = "menu bind"
					connection:Disconnect()
				end
			end)
		end
	end)
	
	-- Update UI
	BindLabel.Text = "bind: " .. Environment.Settings.TriggerKey
	AimbotTypeBtn.Text = Environment.Settings.AimbotType
	ESPColorInput.Text = Environment.Settings.ESPColor
	
	if Environment.Settings.Enabled then
		EnabledBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		EnabledBtn.Text = "disabled"
		EnabledBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
	end
	
	if Environment.Settings.Chams then
		ChamsBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		ChamsBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
	end
	
	if Environment.Settings.ESPEnabled then
		ESPBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		ESPBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
	end
	
	return ScreenGui, MainFrame
end

--// Aimbot Functions

local function SaveSettings()
	if Environment.Settings.SaveSettings then
		if isfile(Title.."/"..FileNames[1].."/"..FileNames[2]) then
			writefile(Title.."/"..FileNames[1].."/"..FileNames[2], Encode(Environment.Settings))
		end
		if isfile(Title.."/"..FileNames[1].."/"..FileNames[3]) then
			writefile(Title.."/"..FileNames[1].."/"..FileNames[3], Encode(Environment.FOVSettings))
		end
	end
end

local function GetClosestPlayer()
	if not Environment.Locked then
		if Environment.FOVSettings.Enabled then
			RequiredDistance = Environment.FOVSettings.Amount
		else
			RequiredDistance = 2000
		end

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer then
				if v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
					if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
					if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
					if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

					local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
					local Distance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude

					if Distance < RequiredDistance and OnScreen then
						RequiredDistance = Distance
						Environment.Locked = v
					end
				end
			end
		end
	elseif (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).X, Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).Y)).Magnitude > RequiredDistance then
		Environment.Locked = nil
		if Animation then Animation:Cancel() end
		Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
	end
end

local function GetSilentTarget()
	if Environment.FOVSettings.Enabled then
		RequiredDistance = Environment.FOVSettings.Amount
	else
		RequiredDistance = 2000
	end
	
	local closestTarget = nil
	local closestDistance = RequiredDistance
	
	for _, v in next, Players:GetPlayers() do
		if v ~= LocalPlayer then
			if v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
				if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
				if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
				if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

				local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
				local Distance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude

				if Distance < closestDistance and OnScreen then
					closestDistance = Distance
					closestTarget = v
				end
			end
		end
	end
	
	return closestTarget
end

local function ExpandHitbox(player)
	if not player or not player.Character then return end
	
	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local partId = tostring(part:GetFullName())
			if not Environment.OriginalSizes[partId] then
				Environment.OriginalSizes[partId] = {
					Part = part,
					Size = part.Size,
					Transparency = part.Transparency,
					CanCollide = part.CanCollide,
					Massless = part.Massless
				}
			end
			
			local multiplier = Environment.Settings.SilentAimFOV
			part.Size = Vector3.new(
				Environment.OriginalSizes[partId].Size.X * multiplier,
				Environment.OriginalSizes[partId].Size.Y * multiplier,
				Environment.OriginalSizes[partId].Size.Z * multiplier
			)
			part.Massless = true
			part.CanCollide = false
			part.Transparency = 1 -- Always invisible for silent aim
		end
	end
end

local function RestoreHitbox(player)
	if not player or not player.Character then return end
	
	local character = player.Character
	local keysToRestore = {}
	
	for partId, data in pairs(Environment.OriginalSizes) do
		if data.Part and data.Part:IsDescendantOf(character) then
			table.insert(keysToRestore, partId)
		end
	end
	
	for _, partId in pairs(keysToRestore) do
		local data = Environment.OriginalSizes[partId]
		if data and data.Part and data.Part.Parent then
			data.Part.Size = data.Size
			data.Part.Transparency = data.Transparency
			data.Part.CanCollide = data.CanCollide
			data.Part.Massless = data.Massless
			Environment.OriginalSizes[partId] = nil
		end
	end
end

--// Typing Check

ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// Create, Save & Load Settings

if Environment.Settings.SaveSettings then
	if not isfolder(Title) then
		makefolder(Title)
	end
	if not isfolder(Title.."/"..FileNames[1]) then
		makefolder(Title.."/"..FileNames[1])
	end
	if not isfile(Title.."/"..FileNames[1].."/"..FileNames[2]) then
		writefile(Title.."/"..FileNames[1].."/"..FileNames[2], Encode(Environment.Settings))
	else
		Environment.Settings = Decode(readfile(Title.."/"..FileNames[1].."/"..FileNames[2]))
	end
	if not isfile(Title.."/"..FileNames[1].."/"..FileNames[3]) then
		writefile(Title.."/"..FileNames[1].."/"..FileNames[3], Encode(Environment.FOVSettings))
	else
		Environment.Visuals = Decode(readfile(Title.."/"..FileNames[1].."/"..FileNames[3]))
	end

	coroutine.wrap(function()
		while wait(10) and Environment.Settings.SaveSettings do
			SaveSettings()
		end
	end)()
else
	if isfolder(Title) then
		delfolder(Title)
	end
end

local function Load()
	-- Initialize ESP for existing players
	InitializeESP()
	
	-- Handle new players joining
	ServiceConnections.PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
		if player ~= LocalPlayer then
			CreateESP(player)
		end
	end)
	
	-- Handle players leaving
	ServiceConnections.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		RemoveESP(player)
		RemoveChams(player)
		if Environment.SilentTarget == player then
			RestoreHitbox(player)
			Environment.SilentTarget = nil
		end
	end)
	
	-- Handle character respawns for all current players
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			player.CharacterAdded:Connect(function(character)
				-- Wait a moment for character to fully load
				task.wait(0.5)
				RemoveChams(player)
				RemoveESP(player)
				if Environment.Settings.Chams then
					CreateChams(player)
				end
				if Environment.Settings.ESPEnabled then
					CreateESP(player)
				end
			end)
		end
	end
	
	-- Handle character respawns for new players
	ServiceConnections.PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
		if player ~= LocalPlayer then
			CreateESP(player)
			player.CharacterAdded:Connect(function(character)
				task.wait(0.5)
				RemoveChams(player)
				RemoveESP(player)
				if Environment.Settings.Chams then
					CreateChams(player)
				end
				if Environment.Settings.ESPEnabled then
					CreateESP(player)
				end
			end)
		end
	end)
	
	-- Periodic refresh for Chams and ESP (every 2 seconds)
	ServiceConnections.PeriodicRefreshConnection = RunService.Heartbeat:Connect(function()
		-- Use a counter to only refresh every ~2 seconds
		if not Environment.RefreshCounter then
			Environment.RefreshCounter = 0
		end
		
		Environment.RefreshCounter = Environment.RefreshCounter + 1
		
		-- Refresh every 120 frames (approximately 2 seconds at 60 FPS)
		if Environment.RefreshCounter >= 120 then
			Environment.RefreshCounter = 0
			
			-- Refresh Chams
			if Environment.Settings.Chams then
				for _, player in pairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and player.Character then
						if not Environment.ChamsHighlights[player] or not Environment.ChamsHighlights[player].Parent then
							RemoveChams(player)
							CreateChams(player)
						end
					end
				end
			end
			
			-- Refresh ESP
			if Environment.Settings.ESPEnabled then
				for _, player in pairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and player.Character then
						if not Environment.ESPBoxes[player] then
							CreateESP(player)
						end
					end
				end
			end
		end
	end)
	
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		-- FOV Circle
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			Environment.FOVCircle.Visible = false
		end
		
		-- Update Chams (Rainbow)
		if Environment.Settings.Chams then
			UpdateChams()
			for player, highlight in pairs(Environment.ChamsHighlights) do
				if highlight and highlight.Parent then
					highlight.FillColor = RainbowColor(0)
					highlight.OutlineColor = RainbowColor(0.5)
				end
			end
		end
		
		-- Update ESP
		UpdateESPBoxes()

		-- Aimbot
		if Running and Environment.Settings.Enabled then
			if Environment.Settings.AimbotType == "Memory" then
				GetClosestPlayer()

				if Environment.Locked then
					if Environment.Settings.ThirdPerson then
						Environment.Settings.ThirdPersonSensitivity = math.clamp(Environment.Settings.ThirdPersonSensitivity, 0.1, 5)
						local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
						mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
					else
						if Environment.Settings.Sensitivity > 0 then
							Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
							Animation:Play()
						else
							Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
						end
					end
					Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.LockedColor)
				end
			elseif Environment.Settings.AimbotType == "Silent" then
				local newTarget = GetSilentTarget()
				
				if Environment.SilentTarget and Environment.SilentTarget ~= newTarget then
					RestoreHitbox(Environment.SilentTarget)
				end
				
				Environment.SilentTarget = newTarget
				
				if Environment.SilentTarget then
					ExpandHitbox(Environment.SilentTarget)
					Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.LockedColor)
				else
					Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
				end
			end
		else
			if Environment.SilentTarget then
				RestoreHitbox(Environment.SilentTarget)
				Environment.SilentTarget = nil
			end
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing and not WaitingForInput then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running
						if not Running then
							Environment.Locked = nil
							if Environment.SilentTarget then
								RestoreHitbox(Environment.SilentTarget)
								Environment.SilentTarget = nil
							end
							if Animation then Animation:Cancel() end
							Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
						end
					else
						Running = true
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running
						if not Running then
							Environment.Locked = nil
							if Environment.SilentTarget then
								RestoreHitbox(Environment.SilentTarget)
								Environment.SilentTarget = nil
							end
							if Animation then Animation:Cancel() end
							Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing and not WaitingForInput then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
					if not Environment.Settings.Toggle then
						Running = false
						Environment.Locked = nil
						if Environment.SilentTarget then
							RestoreHitbox(Environment.SilentTarget)
							Environment.SilentTarget = nil
						end
						if Animation then Animation:Cancel() end
						Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if not Environment.Settings.Toggle then
						Running = false
						Environment.Locked = nil
						if Environment.SilentTarget then
							RestoreHitbox(Environment.SilentTarget)
							Environment.SilentTarget = nil
						end
						if Animation then Animation:Cancel() end
						Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
					end
				end
			end)
		end
	end)
end

--// Functions

Environment.Functions = {}

function Environment.Functions:Exit()
	-- Restore all hitboxes
	local processedPlayers = {}
	for partId, data in pairs(Environment.OriginalSizes) do
		if data.Part and data.Part.Parent then
			local character = data.Part:FindFirstAncestorOfClass("Model")
			if character and not processedPlayers[character] then
				local player = Players:GetPlayerFromCharacter(character)
				if player then
					RestoreHitbox(player)
					processedPlayers[character] = true
				end
			end
		end
	end
	
	-- Remove all chams
	for player, _ in pairs(Environment.ChamsHighlights) do
		RemoveChams(player)
	end
	
	-- Remove all ESP
	for player, _ in pairs(Environment.ESPBoxes) do
		RemoveESP(player)
	end
	
	SaveSettings()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end
	if Environment.FOVCircle.Remove then Environment.FOVCircle:Remove() end
	pcall(function()
		game.CoreGui:FindFirstChild("AimbotGUI"):Destroy()
	end)
	getgenv().Aimbot.Functions = nil
	getgenv().Aimbot = nil
end

function Environment.Functions:Restart()
	SaveSettings()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end
	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		SendNotifications = true,
		SaveSettings = true,
		ReloadOnTeleport = true,
		Enabled = true,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0,
		ThirdPerson = false,
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head",
		AimbotType = "Memory",
		SilentAimFOV = 3,
		Chams = false,
		ESPEnabled = false,
		ESPColor = "FF0000"
	}

	Environment.FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 90,
		Color = "255, 255, 255",
		LockedColor = "255, 70, 70",
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	}
end

--// Support Check

if not Drawing or not getgenv then
	SendNotification(Title, "Your exploit does not support this script", 3)
	return
end

--// Load

Load()
local GUI, MenuFrame = CreateGUI()

-- Menu Toggle
ServiceConnections.MenuToggleConnection = UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == MenuToggleBind and not Typing and not WaitingForInput then
		MenuOpen = not MenuOpen
		MenuFrame.Visible = MenuOpen
	end
end)

SendNotification(Title, "Localscript Active Press Right Alt To Continue", 3)
