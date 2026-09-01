-- // Drift Counter - Sistema realista de pontuação
-- CTRL = mostrar/esconder | Arraste para mover

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- ===================== CONFIG =====================
local MIN_SPEED = 25
local MIN_ANGLE = 20
local RESET_TIME = 4
local MAX_MULTIPLIER = 10
local POINTS_PER_LEVEL = 1500

-- Rotação do Texto
local MAX_TILT_ANGLE = 2     -- Inclinação máxima do texto (graus)
local MAX_GAIN_RATE = 500     -- Taxa de ganho por segundo para atingir inclinação máxima

-- ===================== DATA =====================
local DriftScore = 0
local BestScore = 0
local Multiplier = 1
local ChainTimer = 0
local InChain = false
local LastAngle = 0
local GuiVisible = true
local lastBonusTime = 0
local currentGainRate = 0

-- ===================== REMOVER GUI ANTIGA =====================
local old = Player:FindFirstChild("PlayerGui") and Player.PlayerGui:FindFirstChild("DriftCounter")
if old then old:Destroy() end

-- ===================== CRIAR GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DriftCounter"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local Canvas = Instance.new("CanvasGroup")
Canvas.Name = "BRIFT"
Canvas.Size = UDim2.new(1, 0, 1, 0)
Canvas.Position = UDim2.new(0, 0, 0, 0)
Canvas.BackgroundTransparency = 1
Canvas.GroupTransparency = 0
Canvas.Parent = ScreenGui

-- ===================== POINTS =====================
local PointsLabel = Instance.new("TextLabel")
PointsLabel.Name = "Points"
PointsLabel.AnchorPoint = Vector2.new(0, 0.5)
PointsLabel.Position = UDim2.new(0.04, 0, 0.12, 0)
PointsLabel.Size = UDim2.new(0, 320, 0, 55)
PointsLabel.BackgroundTransparency = 1
PointsLabel.Text = "0"
PointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PointsLabel.TextSize = 42
PointsLabel.Font = Enum.Font.GothamBold
PointsLabel.TextXAlignment = Enum.TextXAlignment.Left
PointsLabel.TextYAlignment = Enum.TextYAlignment.Center
PointsLabel.Rotation = 0
PointsLabel.Parent = Canvas

-- ===================== MULTI =====================
local MultiLabel = Instance.new("TextLabel")
MultiLabel.Name = "Multi"
MultiLabel.Position = UDim2.new(0.075, 0, 0.065, 0)
MultiLabel.Size = UDim2.new(0, 120, 0, 28)
MultiLabel.BackgroundTransparency = 1
MultiLabel.Text = "1x"
MultiLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
MultiLabel.TextSize = 22
MultiLabel.Font = Enum.Font.GothamBold
MultiLabel.TextXAlignment = Enum.TextXAlignment.Left
MultiLabel.Parent = Canvas

-- ===================== DRAG =====================
local dragging = false
local dragStart, startPos

Canvas.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Canvas.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Canvas.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

Canvas.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ===================== DETECTOR DE PNEUS =====================
local function GetPlayerCar()
	local carsFolder = Workspace:FindFirstChild("Cars")
	if not carsFolder then return nil end

	for _, car in ipairs(carsFolder:GetChildren()) do
		local stats = car:FindFirstChild("Stats")
		if stats then
			local owner = stats:FindFirstChild("Owner")
			if owner and owner.Value == Player.Name then
				return car
			end
		end
	end
	return nil
end

local function CheckTiremarks(car)
	if not car then return false end

	-- Checa se qualquer uma das rodas principais está soltando fumaça/marcas
	local wheels = {"RR", "RL", "FR", "FL"}
	for _, wheelName in ipairs(wheels) do
		local wheelModel = car:FindFirstChild(wheelName)
		if wheelModel then
			local axel = wheelModel:FindFirstChild("Axel")
			if axel then
				local trail = axel:FindFirstChild("Tiremarks")
				if trail and trail:IsA("Trail") and trail.Enabled then
					return true
				end
			end
		end
	end
	return false
end

-- ===================== FUNÇÕES =====================
local function UpdateUI(dt)
	PointsLabel.Text = tostring(math.floor(DriftScore))
	
	Multiplier = math.clamp(math.floor(DriftScore / POINTS_PER_LEVEL) + 1, 1, MAX_MULTIPLIER)
	MultiLabel.Text = Multiplier .. "x"

	-- Rotação dinâmica
	local targetTilt = 0
	if InChain and currentGainRate > 0 then
		local gainRatio = math.clamp(currentGainRate / MAX_GAIN_RATE, 0, 1)
		targetTilt = -gainRatio * MAX_TILT_ANGLE
	end
	
	PointsLabel.Rotation = math.lerp(PointsLabel.Rotation, targetTilt, math.clamp(dt * 10, 0, 1))

	-- Cores
	if Multiplier >= 10 then
		PointsLabel.TextColor3 = Color3.fromRGB(255, 0, 100)
	elseif Multiplier >= 8 then
		PointsLabel.TextColor3 = Color3.fromRGB(255, 80, 255)
	elseif Multiplier >= 6 then
		PointsLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
	elseif Multiplier >= 4 then
		PointsLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	elseif Multiplier >= 2 then
		PointsLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
	else
		PointsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function ResetCombo()
	if DriftScore > BestScore then BestScore = DriftScore end
	DriftScore = 0
	Multiplier = 1
	InChain = false
	ChainTimer = 0
	currentGainRate = 0
	PointsLabel.Rotation = 0
	UpdateUI(0)
end

-- ===================== TOGGLE CTRL =====================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		GuiVisible = not GuiVisible
		Canvas.GroupTransparency = GuiVisible and 0 or 1
	end
end)

-- ===================== MAIN LOOP =====================
RunService.RenderStepped:Connect(function(dt)
	local Character = Player.Character
	if not Character then return end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	local Seat = Humanoid.SeatPart
	if not Seat then
		if InChain then
			ChainTimer -= dt
			currentGainRate = 0
			if ChainTimer <= 0 then ResetCombo() end
		end
		UpdateUI(dt)
		return
	end

	local Car = GetPlayerCar() or Seat:FindFirstAncestorOfClass("Model")
	if not Car then return end

	local Root = Car.PrimaryPart or Seat
	local Velocity = Root.AssemblyLinearVelocity
	local FlatVelocity = Vector3.new(Velocity.X, 0, Velocity.Z)
	local Speed = FlatVelocity.Magnitude

	local Angle = 0
	if Speed > 5 then
		local Forward = Seat.CFrame.LookVector
		local VelocityDir = FlatVelocity.Unit
		local Dot = math.clamp(Forward:Dot(VelocityDir), -1, 1)
		Angle = math.deg(math.acos(Dot))
	end

	-- ===== TRANSIÇÃO (BÔNUS) =====
	local angleChange = math.abs(Angle - LastAngle)
	if angleChange > 40 and Speed > 45 and (tick() - lastBonusTime) > 0.8 then
		DriftScore += 250
		lastBonusTime = tick()
	end
	LastAngle = Angle

	-- ===== DETECÇÃO DE DRIFT (FÍSICA OU MARCA DE PNEU) =====
	local physicsDrift = Speed >= MIN_SPEED and Angle >= MIN_ANGLE
	local trailDrift = CheckTiremarks(Car) and Speed >= 15 -- Exige velocidade mínima de 15 para não pontuar parado fritando pneu

	local IsDrifting = physicsDrift or trailDrift

	if IsDrifting then
		InChain = true
		ChainTimer = RESET_TIME

		-- Caso esteja detectando apenas pela fumaça em ângulo baixo, considera o ângulo mínimo para cálculo
		local effectiveAngle = math.max(Angle, MIN_ANGLE)

		local angleScore = effectiveAngle * 1.8
		local speedScore = Speed * 0.4
		local highAngleBonus = 0

		if effectiveAngle >= 45 then
			highAngleBonus = (effectiveAngle - 45) * 1.2
		end
		if effectiveAngle >= 60 then
			highAngleBonus = highAngleBonus + (effectiveAngle - 60) * 1.8
		end

		local PointsPerSecond = (angleScore + speedScore + highAngleBonus)
		currentGainRate = PointsPerSecond * Multiplier
		DriftScore += currentGainRate * dt
	else
		currentGainRate = 0
		if InChain then
			ChainTimer -= dt
			if ChainTimer <= 0 then ResetCombo() end
		end
	end

	UpdateUI(dt)
end)

print("✅ Sistema atualizado com detecção via Tiremarks do Workspace.Cars")
