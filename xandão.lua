local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==============================================================================
-- 0. LIMPEZA AUTOMÁTICA DE INSTÂNCIAS ANTERIORES
-- ==============================================================================
if playerGui:FindFirstChild("CustomControlHub") then
	playerGui.CustomControlHub:Destroy()
end

-- ==============================================================================
-- 1. CONFIGURAÇÕES INICIAIS
-- ==============================================================================
local menuKey = Enum.KeyCode.J
local isMenuOpen = true
local isBindingKey = false

local BOOST_FORCE = 25000
local JUMP_FORCE = 8000

local isShiftPressed = false
local boostConnection = nil
local activeVectorForce = nil
local activeAttachment = nil

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Função de Arrastar (Drag) Universal (PC e Mobile)
local function makeDraggable(guiObject)
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	guiObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	guiObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- ==============================================================================
-- 2. CRIAÇÃO DA INTERFACE VISUAL (GUI)
-- ==============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomControlHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- A. TELA DE CARREGAMENTO (2 SEGUNDOS EXATOS)
--------------------------------------------------------------------------------
local loadingFrame = Instance.new("Frame")
loadingFrame.Name = "LoadingFrame"
loadingFrame.Size = UDim2.new(0, 280, 0, 130)
loadingFrame.Position = UDim2.new(0.5, -140, 0.5, -65)
loadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
loadingFrame.BorderSizePixel = 0
loadingFrame.Parent = screenGui

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 10)
loadCorner.Parent = loadingFrame

local loadTitle = Instance.new("TextLabel")
loadTitle.Size = UDim2.new(1, 0, 0, 35)
loadTitle.Position = UDim2.new(0, 0, 0, 15)
loadTitle.Text = "🚀 CARREGANDO PAINEL..."
loadTitle.TextColor3 = Color3.fromRGB(240, 240, 250)
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 13
loadTitle.BackgroundTransparency = 1
loadTitle.Parent = loadingFrame

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0, 220, 0, 8)
barBg.Position = UDim2.new(0.5, -110, 0, 70)
barBg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
barBg.BorderSizePixel = 0
barBg.Parent = loadingFrame

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(0, 4)
barBgCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(0, 4)
barFillCorner.Parent = barFill

--------------------------------------------------------------------------------
-- B. PAINEL PRINCIPAL (ARRASTÁVEL)
--------------------------------------------------------------------------------
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 290)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -145)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Torna o painel principal arrastável
makeDraggable(mainFrame)

-- Barra Superior (Header)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 200, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Text = "⚡ CONTROL HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.BackgroundTransparency = 1
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BackgroundTransparency = 1
closeBtn.Parent = header

-- Abas
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 35)
tabBar.Position = UDim2.new(0, 10, 0, 48)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local function createTabButton(name, xPos)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 110, 1, 0)
	btn.Position = UDim2.new(0, xPos, 0, 0)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(200, 200, 210)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
	btn.BorderSizePixel = 0
	btn.Parent = tabBar

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	return btn
end

local tabBtnVehicle = createTabButton("🚗 Veículo", 0)
local tabBtnSettings = createTabButton("⚙️ Ajustes", 120)

local pagesFolder = Instance.new("Folder")
pagesFolder.Name = "Pages"
pagesFolder.Parent = mainFrame

local function createPage(name)
	local page = Instance.new("Frame")
	page.Name = name
	page.Size = UDim2.new(1, -20, 0, 190)
	page.Position = UDim2.new(0, 10, 0, 90)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = pagesFolder
	return page
end

local pageVehicle = createPage("VehiclePage")
local pageSettings = createPage("SettingsPage")

pageVehicle.Visible = true
tabBtnVehicle.BackgroundColor3 = Color3.fromRGB(0, 140, 230)
tabBtnVehicle.TextColor3 = Color3.fromRGB(255, 255, 255)

--------------------------------------------------------------------------------
-- C. CONTEÚDO DA ABA VEÍCULO
--------------------------------------------------------------------------------
local function createInputRow(parent, labelText, defaultValue, yPos)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.Position = UDim2.new(0, 0, 0, yPos)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	container.BorderSizePixel = 0
	container.Parent = parent

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = container

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1
	label.Parent = container

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 110, 0, 26)
	box.Position = UDim2.new(1, -120, 0.5, -13)
	box.Text = tostring(defaultValue)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.BackgroundColor3 = Color3.fromRGB(42, 42, 54)
	box.BorderSizePixel = 0
	box.Font = Enum.Font.GothamBold
	box.TextSize = 12
	box.Parent = container

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 4)
	bCorner.Parent = box

	return box
end

local jumpBox = createInputRow(pageVehicle, "Poder do Pulo:", JUMP_FORCE, 0)
local nitroBox = createInputRow(pageVehicle, "Força do Nitro:", BOOST_FORCE, 48)

local jumpActionBtn = Instance.new("TextButton")
jumpActionBtn.Size = UDim2.new(1, 0, 0, 38)
jumpActionBtn.Position = UDim2.new(0, 0, 0, 98)
jumpActionBtn.Text = "🦘 PULAR AGORA"
jumpActionBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 220)
jumpActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpActionBtn.Font = Enum.Font.GothamBold
jumpActionBtn.TextSize = 13
jumpActionBtn.BorderSizePixel = 0
jumpActionBtn.Parent = pageVehicle

local jBtnCorner = Instance.new("UICorner")
jBtnCorner.CornerRadius = UDim.new(0, 6)
jBtnCorner.Parent = jumpActionBtn

--------------------------------------------------------------------------------
-- D. CONTEÚDO DA ABA CONFIGURAÇÕES
--------------------------------------------------------------------------------
local keybindContainer = Instance.new("Frame")
keybindContainer.Size = UDim2.new(1, 0, 0, 45)
keybindContainer.Position = UDim2.new(0, 0, 0, 0)
keybindContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
keybindContainer.BorderSizePixel = 0
keybindContainer.Parent = pageSettings

local kbCorner = Instance.new("UICorner")
kbCorner.CornerRadius = UDim.new(0, 6)
kbCorner.Parent = keybindContainer

local kbLabel = Instance.new("TextLabel")
kbLabel.Size = UDim2.new(0, 200, 1, 0)
kbLabel.Position = UDim2.new(0, 12, 0, 0)
kbLabel.Text = "Tecla Menu (PC):"
kbLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
kbLabel.Font = Enum.Font.Gotham
kbLabel.TextSize = 12
kbLabel.TextXAlignment = Enum.TextXAlignment.Left
kbLabel.BackgroundTransparency = 1
kbLabel.Parent = keybindContainer

local keybindBtn = Instance.new("TextButton")
keybindBtn.Size = UDim2.new(0, 110, 0, 28)
keybindBtn.Position = UDim2.new(1, -120, 0.5, -14)
keybindBtn.Text = menuKey.Name
keybindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
keybindBtn.Font = Enum.Font.GothamBold
keybindBtn.TextSize = 12
keybindBtn.BorderSizePixel = 0
keybindBtn.Parent = keybindContainer

local kbcCorner = Instance.new("UICorner")
kbcCorner.CornerRadius = UDim.new(0, 4)
kbcCorner.Parent = keybindBtn

--------------------------------------------------------------------------------
-- E. BOTÕES MOBILE
--------------------------------------------------------------------------------
local mobileFrame = Instance.new("Frame")
mobileFrame.Name = "MobileControls"
mobileFrame.Size = UDim2.new(0, 130, 0, 60)
mobileFrame.Position = UDim2.new(0.8, 0, 0.65, 0)
mobileFrame.BackgroundTransparency = 1
mobileFrame.Visible = isMobile
mobileFrame.Parent = screenGui

local mobileJumpBtn = Instance.new("TextButton")
mobileJumpBtn.Size = UDim2.new(0, 52, 0, 52)
mobileJumpBtn.Position = UDim2.new(0, 0, 0, 0)
mobileJumpBtn.Text = "🦘"
mobileJumpBtn.TextSize = 20
mobileJumpBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 230)
mobileJumpBtn.Parent = mobileFrame

local mjCorner = Instance.new("UICorner")
mjCorner.CornerRadius = UDim.new(1, 0)
mjCorner.Parent = mobileJumpBtn

local mobileNitroBtn = Instance.new("TextButton")
mobileNitroBtn.Size = UDim2.new(0, 52, 0, 52)
mobileNitroBtn.Position = UDim2.new(0, 60, 0, 0)
mobileNitroBtn.Text = "⚡"
mobileNitroBtn.TextSize = 20
mobileNitroBtn.BackgroundColor3 = Color3.fromRGB(230, 120, 0)
mobileNitroBtn.Parent = mobileFrame

local mnCorner = Instance.new("UICorner")
mnCorner.CornerRadius = UDim.new(1, 0)
mnCorner.Parent = mobileNitroBtn

local mobileToggleMenu = Instance.new("TextButton")
mobileToggleMenu.Size = UDim2.new(0, 38, 0, 38)
mobileToggleMenu.Position = UDim2.new(0.02, 0, 0.2, 0)
mobileToggleMenu.Text = "⚙️"
mobileToggleMenu.TextSize = 16
mobileToggleMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mobileToggleMenu.Visible = isMobile
mobileToggleMenu.Parent = screenGui

local mtCorner = Instance.new("UICorner")
mtCorner.CornerRadius = UDim.new(0, 8)
mtCorner.Parent = mobileToggleMenu

-- ==============================================================================
-- 3. LÓGICA DO VEÍCULO
-- ==============================================================================
local function stopBoost()
	if boostConnection then boostConnection:Disconnect() boostConnection = nil end
	if activeVectorForce then activeVectorForce:Destroy() activeVectorForce = nil end
	if activeAttachment then activeAttachment:Destroy() activeAttachment = nil end
end

local function startBoost()
	stopBoost()

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.SeatPart or not humanoid.SeatPart:IsA("VehicleSeat") then
		return
	end

	local seat = humanoid.SeatPart
	local carAssembly = seat.AssemblyRootPart or seat

	for _, child in ipairs(carAssembly:GetChildren()) do
		if child.Name == "BoostForce" or child.Name == "BoostAttachment" then
			child:Destroy()
		end
	end

	activeAttachment = Instance.new("Attachment")
	activeAttachment.Name = "BoostAttachment"
	activeAttachment.Parent = carAssembly

	activeVectorForce = Instance.new("VectorForce")
	activeVectorForce.Name = "BoostForce"
	activeVectorForce.Attachment0 = activeAttachment
	activeVectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	activeVectorForce.Force = carAssembly.CFrame.LookVector * BOOST_FORCE
	activeVectorForce.Parent = carAssembly

	boostConnection = RunService.RenderStepped:Connect(function()
		if not isShiftPressed or not seat.Parent then
			stopBoost()
			return
		end
		if activeVectorForce and carAssembly then
			activeVectorForce.Force = carAssembly.CFrame.LookVector * BOOST_FORCE
		end
	end)
end

local function applyJump()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.SeatPart or not humanoid.SeatPart:IsA("VehicleSeat") then
		return
	end

	local seat = humanoid.SeatPart
	local carAssembly = seat.AssemblyRootPart or seat

	carAssembly:ApplyImpulse(Vector3.new(0, JUMP_FORCE, 0) * carAssembly:GetMass())
end

-- ==============================================================================
-- 4. CONEXÕES
-- ==============================================================================
jumpBox.FocusLost:Connect(function()
	JUMP_FORCE = tonumber(jumpBox.Text) or JUMP_FORCE
	jumpBox.Text = tostring(JUMP_FORCE)
end)

nitroBox.FocusLost:Connect(function()
	BOOST_FORCE = tonumber(nitroBox.Text) or BOOST_FORCE
	nitroBox.Text = tostring(BOOST_FORCE)
end)

tabBtnVehicle.MouseButton1Click:Connect(function()
	pageVehicle.Visible = true
	pageSettings.Visible = false
	tabBtnVehicle.BackgroundColor3 = Color3.fromRGB(0, 140, 230)
	tabBtnVehicle.TextColor3 = Color3.fromRGB(255, 255, 255)
	tabBtnSettings.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
	tabBtnSettings.TextColor3 = Color3.fromRGB(200, 200, 210)
end)

tabBtnSettings.MouseButton1Click:Connect(function()
	pageVehicle.Visible = false
	pageSettings.Visible = true
	tabBtnSettings.BackgroundColor3 = Color3.fromRGB(0, 140, 230)
	tabBtnSettings.TextColor3 = Color3.fromRGB(255, 255, 255)
	tabBtnVehicle.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
	tabBtnVehicle.TextColor3 = Color3.fromRGB(200, 200, 210)
end)

jumpActionBtn.MouseButton1Click:Connect(applyJump)
mobileJumpBtn.MouseButton1Click:Connect(applyJump)

mobileNitroBtn.MouseButtonDown:Connect(function()
	isShiftPressed = true
	startBoost()
end)

mobileNitroBtn.MouseButtonUp:Connect(function()
	isShiftPressed = false
	stopBoost()
end)

closeBtn.MouseButton1Click:Connect(function()
	isMenuOpen = false
	mainFrame.Visible = false
end)

mobileToggleMenu.MouseButton1Click:Connect(function()
	isMenuOpen = not isMenuOpen
	mainFrame.Visible = isMenuOpen
end)

keybindBtn.MouseButton1Click:Connect(function()
	isBindingKey = true
	keybindBtn.Text = "Pressione..."
	keybindBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isBindingKey then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			menuKey = input.KeyCode
			keybindBtn.Text = menuKey.Name
			keybindBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
			isBindingKey = false
		end
		return
	end

	if gameProcessed then return end

	if input.KeyCode == menuKey then
		isMenuOpen = not isMenuOpen
		mainFrame.Visible = isMenuOpen
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftPressed = true
		startBoost()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftPressed = false
		stopBoost()
	end
end)

-- ==============================================================================
-- 5. ANIMAÇÃO DE CARREGAMENTO (EXATAMENTE 2 SEGUNDOS)
-- ==============================================================================
local tweenInfo = TweenInfo.new(2.0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local barTween = TweenService:Create(barFill, tweenInfo, {Size = UDim2.new(1, 0, 1, 0)})

barTween:Play()
barTween.Completed:Connect(function()
	loadingFrame:Destroy()
	mainFrame.Visible = true
end)
