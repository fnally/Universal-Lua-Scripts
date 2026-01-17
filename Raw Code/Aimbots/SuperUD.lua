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
	AimbotType = "Memory" -- NEW: Memory or Silent
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

local function SendNotification(TitleArg, DescriptionArg, DurationArg)
	if Environment.Settings.SendNotifications then
		StarterGui:SetCore("SendNotification", {
			Title = TitleArg,
			Text = DescriptionArg,
			Duration = DurationArg
		})
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
	
	-- NEW: Aimbot Type Dropdown
	local AimbotTypeLabel = Instance.new("TextLabel")
	local AimbotTypeBtn = Instance.new("TextButton")
	local AimbotTypeDropdown = Instance.new("Frame")
	local MemoryOption = Instance.new("TextButton")
	local SilentOption = Instance.new("TextButton")
	
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
	MainFrame.Size = UDim2.new(0, 220, 0, 290) -- Increased height
	MainFrame.Active = true
	MainFrame.Draggable = true
	
	Title.Name = "Title"
	Title.Parent = MainFrame
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 0, 0, 0)
	Title.Size = UDim2.new(1, 0, 0, 25)
	Title.Font = Enum.Font.Code
	Title.Text = "aimbot"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTransparency = 0.3
	Title.Text = "  aimbot"
	
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
	
	-- NEW: Aimbot Type Label
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
	
	-- NEW: Aimbot Type Button
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
	
	-- NEW: Dropdown Frame
	AimbotTypeDropdown.Name = "AimbotTypeDropdown"
	AimbotTypeDropdown.Parent = MainFrame
	AimbotTypeDropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	AimbotTypeDropdown.BorderColor3 = Color3.fromRGB(60, 60, 60)
	AimbotTypeDropdown.Position = UDim2.new(0, 10, 0, 107)
	AimbotTypeDropdown.Size = UDim2.new(0, 90, 0, 44)
	AimbotTypeDropdown.Visible = false
	AimbotTypeDropdown.ZIndex = 3
	
	-- NEW: Memory Option
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
	
	-- NEW: Silent Option
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
	
	-- FOV Slider functionality
	local dragging = false
	local function updateFOV(input)
		local pos = math.clamp((input.Position.X - FOVSlider.AbsolutePosition.X) / FOVSlider.AbsoluteSize.X, 0, 1)
		local fovValue = math.floor(15 + (pos * 70)) -- 15 to 85
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
	
	-- Set initial FOV slider position
	local initialPos = (Environment.FOVSettings.Amount - 15) / 70
	FOVFill.Size = UDim2.new(initialPos, 0, 1, 0)
	FOVValueLabel.Text = tostring(Environment.FOVSettings.Amount)
	
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
			if Animation then Animation:Cancel() end
			Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
		end
		SaveSettings()
	end)
	
	-- NEW: Aimbot Type Dropdown Toggle
	AimbotTypeBtn.MouseButton1Click:Connect(function()
		AimbotTypeDropdown.Visible = not AimbotTypeDropdown.Visible
	end)
	
	-- NEW: Memory Option Click
	MemoryOption.MouseButton1Click:Connect(function()
		Environment.Settings.AimbotType = "Memory"
		AimbotTypeBtn.Text = "Memory"
		AimbotTypeDropdown.Visible = false
		SaveSettings()
	end)
	
	-- NEW: Silent Option Click
	SilentOption.MouseButton1Click:Connect(function()
		Environment.Settings.AimbotType = "Silent"
		AimbotTypeBtn.Text = "Silent"
		AimbotTypeDropdown.Visible = false
		SaveSettings()
	end)
	
	-- Change Aimbot Bind
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
	
	-- Change Menu Bind
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
	if Environment.Settings.Enabled then
		EnabledBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		EnabledBtn.Text = "disabled"
		EnabledBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
	end
	
	return ScreenGui, MainFrame
end

--// Functions

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

-- NEW: Silent Aim Function
local function GetSilentTarget()
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
					return v
				end
			end
		end
	end
	return nil
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
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
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

		if Running and Environment.Settings.Enabled then
			-- NEW: Check aimbot type
			if Environment.Settings.AimbotType == "Memory" then
				-- Original Memory/Lock-on behavior
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
				-- NEW: Silent aim behavior - just get target within FOV
				local SilentTarget = GetSilentTarget()
				
				if SilentTarget then
					Environment.Locked = SilentTarget
					Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.LockedColor)
					
					-- Silent aim instantly snaps to target (you can modify this behavior)
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, SilentTarget.Character[Environment.Settings.LockPart].Position)
				else
					Environment.Locked = nil
					Environment.FOVCircle.Color = GetColor(Environment.FOVSettings.Color)
				end
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
		AimbotType = "Memory"
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
