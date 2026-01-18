--// Mobile Aimbot Script (Based on Exunys Aimbot V2)
--// Place in StarterPlayer > StarterPlayerScripts

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

--// Variables
local LocalPlayer = Players.LocalPlayer
local Typing, Running, Animation, RequiredDistance = false, false, nil, 2000

--// Environment
getgenv().MobileAimbot = {}
local Environment = getgenv().MobileAimbot

--// Settings
Environment.Settings = {
	Enabled = true,
	TeamCheck = false,
	AliveCheck = true,
	WallCheck = false,
	Sensitivity = 0.15,
	LockPart = "Head",
	LockMode = "Hold", -- "Hold" or "Toggle"
	ButtonSize = 45
}

Environment.FOVSettings = {
	Enabled = true,
	Amount = 90
}

Environment.Locked = nil

--// Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAimbotGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// Create Shoot Button
local shootButton = Instance.new("ImageButton")
shootButton.Name = "ShootButton"
shootButton.Size = UDim2.new(0, Environment.Settings.ButtonSize, 0, Environment.Settings.ButtonSize)
shootButton.Position = UDim2.new(0.85, 0, 0.7, 0)
shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
shootButton.BorderSizePixel = 0
shootButton.Image = ""
shootButton.Parent = screenGui

local shootCorner = Instance.new("UICorner")
shootCorner.CornerRadius = UDim.new(1, 0)
shootCorner.Parent = shootButton

local shootStroke = Instance.new("UIStroke")
shootStroke.Color = Color3.fromRGB(255, 255, 255)
shootStroke.Thickness = 3
shootStroke.Parent = shootButton

--// Create Menu Button
local menuButton = Instance.new("TextButton")
menuButton.Name = "MenuButton"
menuButton.Size = UDim2.new(0, 50, 0, 50)
menuButton.Position = UDim2.new(0.05, 0, 0.05, 0)
menuButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
menuButton.BorderSizePixel = 0
menuButton.Text = ""
menuButton.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0.1, 0)
menuCorner.Parent = menuButton

-- Add three horizontal lines to menu button
for i = 0, 2 do
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0.6, 0, 0, 3)
	line.Position = UDim2.new(0.2, 0, 0.3 + (i * 0.2), 0)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BorderSizePixel = 0
	line.Parent = menuButton
	
	local lineCorner = Instance.new("UICorner")
	lineCorner.CornerRadius = UDim.new(1, 0)
	lineCorner.Parent = line
end

--// Create Settings Frame (Dark theme like the image)
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Size = UDim2.new(0, 280, 0, 420)
settingsFrame.Position = UDim2.new(0.5, -140, 0.5, -210)
settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = screenGui

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0.03, 0)
settingsCorner.Parent = settingsFrame

--// Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = settingsFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0.03, 0)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "aimbot"
titleLabel.TextSize = 18
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.Font = Enum.Font.Code
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -40, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeButton.BorderSizePixel = 0
closeButton.Text = "×"
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = settingsFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.2, 0)
closeCorner.Parent = closeButton

--// Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -60)
contentFrame.Position = UDim2.new(0, 10, 0, 50)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = settingsFrame

--// Helper function to create setting rows
local yOffset = 0
local function createSettingRow(labelText, settingType, defaultValue)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.Position = UDim2.new(0, 0, 0, yOffset)
	row.BackgroundTransparency = 1
	row.Parent = contentFrame
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(180, 180, 180)
	label.Font = Enum.Font.Code
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row
	
	yOffset = yOffset + 50
	
	if settingType == "toggle" then
		local toggleButton = Instance.new("TextButton")
		toggleButton.Size = UDim2.new(0, 70, 0, 28)
		toggleButton.Position = UDim2.new(1, -75, 0.5, -14)
		toggleButton.BackgroundColor3 = defaultValue and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(50, 50, 50)
		toggleButton.BorderSizePixel = 0
		toggleButton.Text = defaultValue and "enabled" or "disabled"
		toggleButton.TextSize = 12
		toggleButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		toggleButton.Font = Enum.Font.Code
		toggleButton.Parent = row
		
		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0.15, 0)
		toggleCorner.Parent = toggleButton
		
		return toggleButton
	elseif settingType == "button" then
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 70, 0, 28)
		button.Position = UDim2.new(1, -75, 0.5, -14)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.BorderSizePixel = 0
		button.Text = defaultValue
		button.TextSize = 12
		button.TextColor3 = Color3.fromRGB(200, 200, 200)
		button.Font = Enum.Font.Code
		button.Parent = row
		
		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0.15, 0)
		buttonCorner.Parent = button
		
		return button
	elseif settingType == "slider" then
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Size = UDim2.new(0, 30, 0, 28)
		valueLabel.Position = UDim2.new(1, -35, 0.5, -14)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = tostring(defaultValue)
		valueLabel.TextSize = 13
		valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		valueLabel.Font = Enum.Font.Code
		valueLabel.TextXAlignment = Enum.TextXAlignment.Right
		valueLabel.Parent = row
		
		yOffset = yOffset + 20
		
		local sliderBg = Instance.new("Frame")
		sliderBg.Size = UDim2.new(1, -10, 0, 6)
		sliderBg.Position = UDim2.new(0, 5, 0, yOffset - 30)
		sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		sliderBg.BorderSizePixel = 0
		sliderBg.Parent = contentFrame
		
		local sliderCorner = Instance.new("UICorner")
		sliderCorner.CornerRadius = UDim.new(1, 0)
		sliderCorner.Parent = sliderBg
		
		local sliderFill = Instance.new("Frame")
		sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
		sliderFill.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		sliderFill.BorderSizePixel = 0
		sliderFill.Parent = sliderBg
		
		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = sliderFill
		
		return {slider = sliderBg, fill = sliderFill, label = valueLabel}
	end
end

--// Create Settings (matching the image layout)
local disabledToggle = createSettingRow("disabled", "toggle", not Environment.Settings.Enabled)
yOffset = yOffset + 5

local aimbotTypeButton = createSettingRow("aimbot type", "button", "Memory")
yOffset = yOffset + 5

local lockModeButton = createSettingRow("lock mode", "button", Environment.Settings.LockMode)
yOffset = yOffset + 5

local buttonSizeSlider = createSettingRow("button size", "slider", Environment.Settings.ButtonSize)
yOffset = yOffset + 5

local fovSlider = createSettingRow("fov", "slider", Environment.Settings.FOVSettings.Amount)

--// Core Functions
local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000

		for _, v in pairs(Players:GetPlayers()) do
			if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
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
	elseif Environment.Locked then
		if not Environment.Locked.Character or not Environment.Locked.Character:FindFirstChild(Environment.Settings.LockPart) then
			Environment.Locked = nil
			if Animation then Animation:Cancel() end
		else
			local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
			local Distance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Vector.X, Vector.Y)).Magnitude
			
			if Distance > RequiredDistance then
				Environment.Locked = nil
				if Animation then Animation:Cancel() end
			end
		end
	end
end

--// Draggable Shoot Button
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

shootButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = shootButton.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

shootButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		shootButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

--// Draggable Menu Button
local menuDragging, menuDragInput, menuDragStart, menuStartPos = false, nil, nil, nil

menuButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		menuDragging = true
		menuDragStart = input.Position
		menuStartPos = menuButton.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				menuDragging = false
			end
		end)
	end
end)

menuButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
		menuDragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if menuDragging and input == menuDragInput then
		local delta = input.Position - menuDragStart
		menuButton.Position = UDim2.new(menuStartPos.X.Scale, menuStartPos.X.Offset + delta.X, menuStartPos.Y.Scale, menuStartPos.Y.Offset + delta.Y)
	end
end)

--// Main Loop
RunService.RenderStepped:Connect(function()
	if Running and Environment.Settings.Enabled and Environment.Locked then
		GetClosestPlayer()
		
		if Environment.Locked and Environment.Locked.Character and Environment.Locked.Character:FindFirstChild(Environment.Settings.LockPart) then
			if Environment.Settings.Sensitivity > 0 then
				Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
				})
				Animation:Play()
			else
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
			end
		end
	end
end)

--// Shoot Button Logic
shootButton.MouseButton1Down:Connect(function()
	if Environment.Settings.LockMode == "Hold" then
		Running = true
		GetClosestPlayer()
		shootButton.BackgroundColor3 = Environment.Locked and Color3.fromRGB(75, 255, 75) or Color3.fromRGB(255, 75, 75)
	elseif Environment.Settings.LockMode == "Toggle" then
		Running = not Running
		if Running then
			GetClosestPlayer()
			shootButton.BackgroundColor3 = Color3.fromRGB(75, 255, 75)
		else
			Environment.Locked = nil
			if Animation then Animation:Cancel() end
			shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
		end
	end
end)

shootButton.MouseButton1Up:Connect(function()
	if Environment.Settings.LockMode == "Hold" then
		Running = false
		Environment.Locked = nil
		if Animation then Animation:Cancel() end
		shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
	end
end)

--// Menu Button Click (after dragging check)
menuButton.MouseButton1Click:Connect(function()
	if not menuDragging then
		settingsFrame.Visible = not settingsFrame.Visible
	end
end)

closeButton.MouseButton1Click:Connect(function()
	settingsFrame.Visible = false
end)

--// Settings Interactions
disabledToggle.MouseButton1Click:Connect(function()
	Environment.Settings.Enabled = not Environment.Settings.Enabled
	disabledToggle.Text = Environment.Settings.Enabled and "enabled" or "disabled"
	disabledToggle.BackgroundColor3 = Environment.Settings.Enabled and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(50, 50, 50)
	
	if not Environment.Settings.Enabled then
		Running = false
		Environment.Locked = nil
		if Animation then Animation:Cancel() end
		shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
	end
end)

lockModeButton.MouseButton1Click:Connect(function()
	Environment.Settings.LockMode = Environment.Settings.LockMode == "Hold" and "Toggle" or "Hold"
	lockModeButton.Text = Environment.Settings.LockMode
	Running = false
	Environment.Locked = nil
	if Animation then Animation:Cancel() end
	shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
end)

--// Button Size Slider
local buttonSizeDragging = false
buttonSizeSlider.slider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		buttonSizeDragging = true
	end
end)

buttonSizeSlider.slider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		buttonSizeDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if buttonSizeDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local relativePos = math.clamp((input.Position.X - buttonSizeSlider.slider.AbsolutePosition.X) / buttonSizeSlider.slider.AbsoluteSize.X, 0, 1)
		Environment.Settings.ButtonSize = math.floor(30 + (relativePos * 70))
		buttonSizeSlider.fill.Size = UDim2.new(relativePos, 0, 1, 0)
		buttonSizeSlider.label.Text = tostring(Environment.Settings.ButtonSize)
		shootButton.Size = UDim2.new(0, Environment.Settings.ButtonSize, 0, Environment.Settings.ButtonSize)
	end
end)

--// FOV Slider
local fovDragging = false
fovSlider.slider.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		fovDragging = true
	end
end)

fovSlider.slider.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		fovDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if fovDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
		local relativePos = math.clamp((input.Position.X - fovSlider.slider.AbsolutePosition.X) / fovSlider.slider.AbsoluteSize.X, 0, 1)
		Environment.FOVSettings.Amount = math.floor(30 + (relativePos * 150))
		fovSlider.fill.Size = UDim2.new(relativePos, 0, 1, 0)
		fovSlider.label.Text = tostring(Environment.FOVSettings.Amount)
	end
end)

print("Mobile Aimbot Loaded!")
