-- Mobile Aimbot LocalScript
-- Place this in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Settings
local settings = {
	enabled = true,
	lockMode = "Hold", -- "Hold" or "Toggle"
	buttonSize = 45,
	fov = 90,
	smoothness = 0.2
}

local isLocked = false
local currentTarget = nil
local connection = nil

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileAimbotGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create Shoot Button
local shootButton = Instance.new("ImageButton")
shootButton.Name = "ShootButton"
shootButton.Size = UDim2.new(0, settings.buttonSize, 0, settings.buttonSize)
shootButton.Position = UDim2.new(0.85, 0, 0.7, 0)
shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
shootButton.BorderSizePixel = 0
shootButton.Image = ""
shootButton.Parent = screenGui

-- Add corner to shoot button
local shootCorner = Instance.new("UICorner")
shootCorner.CornerRadius = UDim.new(1, 0)
shootCorner.Parent = shootButton

-- Add stroke to shoot button
local shootStroke = Instance.new("UIStroke")
shootStroke.Color = Color3.fromRGB(255, 255, 255)
shootStroke.Thickness = 3
shootStroke.Parent = shootButton

-- Create Settings Button (small gear icon)
local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Size = UDim2.new(0, 40, 0, 40)
settingsButton.Position = UDim2.new(0.05, 0, 0.05, 0)
settingsButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
settingsButton.BorderSizePixel = 0
settingsButton.Text = "⚙️"
settingsButton.TextSize = 24
settingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsButton.Parent = screenGui

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0.2, 0)
settingsCorner.Parent = settingsButton

-- Create Settings GUI
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Size = UDim2.new(0, 300, 0, 400)
settingsFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
settingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = screenGui

local settingsFrameCorner = Instance.new("UICorner")
settingsFrameCorner.CornerRadius = UDim.new(0.05, 0)
settingsFrameCorner.Parent = settingsFrame

-- Settings Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "Aimbot Settings"
titleLabel.TextSize = 20
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = settingsFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0.05, 0)
titleCorner.Parent = titleLabel

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextSize = 20
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = settingsFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0.2, 0)
closeCorner.Parent = closeButton

-- Enable/Disable Toggle
local enableLabel = Instance.new("TextLabel")
enableLabel.Size = UDim2.new(0.6, 0, 0, 40)
enableLabel.Position = UDim2.new(0.05, 0, 0, 70)
enableLabel.BackgroundTransparency = 1
enableLabel.Text = "Enabled"
enableLabel.TextSize = 16
enableLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
enableLabel.Font = Enum.Font.Gotham
enableLabel.TextXAlignment = Enum.TextXAlignment.Left
enableLabel.Parent = settingsFrame

local enableToggle = Instance.new("TextButton")
enableToggle.Size = UDim2.new(0, 60, 0, 30)
enableToggle.Position = UDim2.new(0.7, 0, 0, 75)
enableToggle.BackgroundColor3 = Color3.fromRGB(75, 255, 75)
enableToggle.BorderSizePixel = 0
enableToggle.Text = "ON"
enableToggle.TextSize = 14
enableToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
enableToggle.Font = Enum.Font.GothamBold
enableToggle.Parent = settingsFrame

local enableCorner = Instance.new("UICorner")
enableCorner.CornerRadius = UDim.new(0.3, 0)
enableCorner.Parent = enableToggle

-- Lock Mode (Hold/Toggle)
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0.6, 0, 0, 40)
modeLabel.Position = UDim2.new(0.05, 0, 0, 120)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "Lock Mode"
modeLabel.TextSize = 16
modeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = settingsFrame

local modeToggle = Instance.new("TextButton")
modeToggle.Size = UDim2.new(0, 60, 0, 30)
modeToggle.Position = UDim2.new(0.7, 0, 0, 125)
modeToggle.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
modeToggle.BorderSizePixel = 0
modeToggle.Text = settings.lockMode
modeToggle.TextSize = 12
modeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
modeToggle.Font = Enum.Font.GothamBold
modeToggle.Parent = settingsFrame

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0.3, 0)
modeCorner.Parent = modeToggle

-- Button Size Slider
local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(0.6, 0, 0, 40)
sizeLabel.Position = UDim2.new(0.05, 0, 0, 170)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Button Size: " .. settings.buttonSize
sizeLabel.TextSize = 16
sizeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.Parent = settingsFrame

local sizeSliderBg = Instance.new("Frame")
sizeSliderBg.Size = UDim2.new(0.9, 0, 0, 8)
sizeSliderBg.Position = UDim2.new(0.05, 0, 0, 215)
sizeSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sizeSliderBg.BorderSizePixel = 0
sizeSliderBg.Parent = settingsFrame

local sizeSliderBgCorner = Instance.new("UICorner")
sizeSliderBgCorner.CornerRadius = UDim.new(1, 0)
sizeSliderBgCorner.Parent = sizeSliderBg

local sizeSlider = Instance.new("Frame")
sizeSlider.Size = UDim2.new((settings.buttonSize - 30) / 70, 0, 1, 0)
sizeSlider.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
sizeSlider.BorderSizePixel = 0
sizeSlider.Parent = sizeSliderBg

local sizeSliderCorner = Instance.new("UICorner")
sizeSliderCorner.CornerRadius = UDim.new(1, 0)
sizeSliderCorner.Parent = sizeSlider

-- FOV Slider
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0.6, 0, 0, 40)
fovLabel.Position = UDim2.new(0.05, 0, 0, 240)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV: " .. settings.fov
fovLabel.TextSize = 16
fovLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fovLabel.Font = Enum.Font.Gotham
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Parent = settingsFrame

local fovSliderBg = Instance.new("Frame")
fovSliderBg.Size = UDim2.new(0.9, 0, 0, 8)
fovSliderBg.Position = UDim2.new(0.05, 0, 0, 285)
fovSliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fovSliderBg.BorderSizePixel = 0
fovSliderBg.Parent = settingsFrame

local fovSliderBgCorner = Instance.new("UICorner")
fovSliderBgCorner.CornerRadius = UDim.new(1, 0)
fovSliderBgCorner.Parent = fovSliderBg

local fovSlider = Instance.new("Frame")
fovSlider.Size = UDim2.new((settings.fov - 30) / 150, 0, 1, 0)
fovSlider.BackgroundColor3 = Color3.fromRGB(255, 150, 100)
fovSlider.BorderSizePixel = 0
fovSlider.Parent = fovSliderBg

local fovSliderCorner = Instance.new("UICorner")
fovSliderCorner.CornerRadius = UDim.new(1, 0)
fovSliderCorner.Parent = fovSlider

-- Functions
local function getClosestPlayer()
	local closestPlayer = nil
	local shortestDistance = settings.fov
	
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			local character = otherPlayer.Character
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChild("Humanoid")
			
			if humanoidRootPart and humanoid and humanoid.Health > 0 then
				local screenPoint, onScreen = camera:WorldToScreenPoint(humanoidRootPart.Position)
				
				if onScreen then
					local mouseLocation = UserInputService:GetMouseLocation()
					local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude
					
					if distance < shortestDistance then
						closestPlayer = otherPlayer
						shortestDistance = distance
					end
				end
			end
		end
	end
	
	return closestPlayer
end

local function startLockOn()
	if not settings.enabled then return end
	
	currentTarget = getClosestPlayer()
	
	if currentTarget and not connection then
		connection = RunService.RenderStepped:Connect(function()
			if currentTarget and currentTarget.Character then
				local humanoidRootPart = currentTarget.Character:FindFirstChild("HumanoidRootPart")
				local head = currentTarget.Character:FindFirstChild("Head")
				
				if humanoidRootPart and head then
					local targetPos = head.Position
					camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, targetPos), settings.smoothness)
				else
					stopLockOn()
				end
			else
				stopLockOn()
			end
		end)
	end
end

local function stopLockOn()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	currentTarget = nil
end

-- Draggable Shoot Button
local dragging = false
local dragInput, mousePos, framePos

shootButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		mousePos = input.Position
		framePos = shootButton.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

shootButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - mousePos
		shootButton.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
	end
end)

-- Shoot Button Lock Logic
shootButton.MouseButton1Down:Connect(function()
	if settings.lockMode == "Hold" then
		isLocked = true
		startLockOn()
		shootButton.BackgroundColor3 = Color3.fromRGB(75, 255, 75)
	elseif settings.lockMode == "Toggle" then
		isLocked = not isLocked
		if isLocked then
			startLockOn()
			shootButton.BackgroundColor3 = Color3.fromRGB(75, 255, 75)
		else
			stopLockOn()
			shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
		end
	end
end)

shootButton.MouseButton1Up:Connect(function()
	if settings.lockMode == "Hold" then
		isLocked = false
		stopLockOn()
		shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
	end
end)

-- Settings Button
settingsButton.MouseButton1Click:Connect(function()
	settingsFrame.Visible = not settingsFrame.Visible
end)

closeButton.MouseButton1Click:Connect(function()
	settingsFrame.Visible = false
end)

-- Enable Toggle
enableToggle.MouseButton1Click:Connect(function()
	settings.enabled = not settings.enabled
	if settings.enabled then
		enableToggle.Text = "ON"
		enableToggle.BackgroundColor3 = Color3.fromRGB(75, 255, 75)
	else
		enableToggle.Text = "OFF"
		enableToggle.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
		stopLockOn()
	end
end)

-- Mode Toggle
modeToggle.MouseButton1Click:Connect(function()
	if settings.lockMode == "Hold" then
		settings.lockMode = "Toggle"
	else
		settings.lockMode = "Hold"
	end
	modeToggle.Text = settings.lockMode
	stopLockOn()
	isLocked = false
	shootButton.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
end)

-- Size Slider
local sizeDragging = false
sizeSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sizeDragging = true
	end
end)

sizeSliderBg.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sizeDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sizeDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local relativePos = (input.Position.X - sizeSliderBg.AbsolutePosition.X) / sizeSliderBg.AbsoluteSize.X
		relativePos = math.clamp(relativePos, 0, 1)
		
		settings.buttonSize = math.floor(30 + (relativePos * 70))
		sizeSlider.Size = UDim2.new(relativePos, 0, 1, 0)
		sizeLabel.Text = "Button Size: " .. settings.buttonSize
		
		shootButton.Size = UDim2.new(0, settings.buttonSize, 0, settings.buttonSize)
	end
end)

-- FOV Slider
local fovDragging = false
fovSliderBg.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fovDragging = true
	end
end)

fovSliderBg.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fovDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if fovDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local relativePos = (input.Position.X - fovSliderBg.AbsolutePosition.X) / fovSliderBg.AbsoluteSize.X
		relativePos = math.clamp(relativePos, 0, 1)
		
		settings.fov = math.floor(30 + (relativePos * 150))
		fovSlider.Size = UDim2.new(relativePos, 0, 1, 0)
		fovLabel.Text = "FOV: " .. settings.fov
	end
end)

print("Mobile Aimbot Script Loaded!")
