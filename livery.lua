--[[
    ⚡ LIVERY GUI - Body Paint (Pro Edition)
    Draggable • Mobile toggle ball • Pre-made + Custom liveries
    Style inspired by Driving Empire / modern car games
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================== LIVERY DATA (unchanged) ====================
local function D(t)
	return {
		Top = t[1], Left = t[2], Right = t[3],
		Front = t[4], Back = t[5], Bottom = t[6] or t[1]
	}
end

local LiveryData = {
	CarOrder = {"Ferrari 499P", "Porsche 963", "Mercedes-AMG", "Nissan GTR R35", "Formula 2019", "Brabham"},

	["Ferrari 499P"] = {
		{ Name = "Sem", Decals = {}, Colors = {} },
		{ Name = "#50 2023", Decals = { Body = D({ [1] = "rbxassetid://140326714061095", [2] = "rbxassetid://110677527162804", [3] = "rbxassetid://77854762433621" }) }, Colors = { Body = Color3.fromRGB(255, 0, 0) } },
		{ Name = "#50 2022", Decals = { Body = D({ [1] = "rbxassetid://103090740061479", [2] = "rbxassetid://139490989781460", [3] = "rbxassetid://120216683354391" }) }, Colors = { Body = Color3.fromRGB(255, 0, 0) } },
		{ Name = "#83 2025", Decals = { Body = D({ [1] = "rbxassetid://111040511086744", [2] = "rbxassetid://133159924698187", [3] = "rbxassetid://80957363966883" }) }, Colors = { Body = Color3.fromRGB(255, 255, 0) } },
	},

	["Porsche 963"] = {
		{ Name = "Sem", Decals = {}, Colors = {} },
		{ Name = "PENSKE", Decals = {
			Body = D({ [1] = "rbxassetid://97376148413901", [2] = "rbxassetid://136015482622425", [3] = "rbxassetid://92376148413901" }),
			Body2 = D({ [1] = "rbxassetid://116239954694493", [2] = "rbxassetid://130785882062097", [3] = "rbxassetid://132953677031751" }),
			BlackTrim = D({ [2] = "rbxassetid://120671490417314", [3] = "rbxassetid://102793001865316" })
		}, Colors = { Body = Color3.fromRGB(180,0,0), Body2 = Color3.fromRGB(255,255,255), BlackTrim = Color3.fromRGB(20,20,20) }}
	},

	["Mercedes-AMG"] = {
		{ Name = "Sem", Decals = {}, Colors = {} },
		{ Name = "Verstappen", Decals = { Body = D({ [1] = "rbxassetid://131808554679427", [2] = "rbxassetid://114281521031058", [3] = "rbxassetid://83152891843483" }) }, Colors = { Body = Color3.fromRGB(0, 0, 100) } },
	},

	["Nissan GTR R35"] = {
		{ Name = "Sem", Decals = {}, Colors = {} },
		{ Name = "#23", Decals = { Body = D({ [1] = "rbxassetid://90166247493480", [2] = "rbxassetid://108840573040409", [3] = "rbxassetid://134210963502108" }) }, Colors = { Body = Color3.fromRGB(85, 0, 0) } },
	},

	["Formula 2019"] = {
		{ Name = "Sem", Decals = {}, Colors = {} },
		{ Name = "Hamilton", Decals = { Body = D({ [1] = "rbxassetid://91627508278365", [2] = "rbxassetid://113207528595123", [3] = "rbxassetid://98458253015274", [6] = "rbxassetid://91627508278365" }) }, Colors = { Body = Color3.fromRGB(117, 117, 117) } },
		{ Name = "W11", Decals = { Body = D({ [1] = "rbxassetid://88472765027782", [2] = "rbxassetid://118378348607428", [3] = "rbxassetid://108271742883272" }) }, Colors = { Body = Color3.fromRGB(0, 0, 0) } },
		{ Name = "Verstappen", Decals = { Body = D({ [1] = "rbxassetid://122653234892723", [2] = "rbxassetid://92975938094145", [3] = "rbxassetid://78914381724629" }) }, Colors = { Body = Color3.fromRGB(0, 0, 40) } },
	},

	["Brabham"] = {
		{ Name = "Sem", Decals = {}, Colors = {} },
		{ Name = "#12", Decals = { Body = D({ [1] = "rbxassetid://80986530120176", [2] = "rbxassetid://135484337113900", [3] = "rbxassetid://92542640479980", [4] = "rbxassetid://122014159784272" }) }, Colors = { Body = Color3.fromRGB(0, 56, 22) } },
		{ Name = "GoodYear", Decals = { Body = D({ [1] = "rbxassetid://115172559609442", [2] = "rbxassetid://114399968763283", [3] = "rbxassetid://124154800333366", [4] = "rbxassetid://102962414054085", [5] = "rbxassetid://113462327011074" }) }, Colors = { Body = Color3.fromRGB(0, 32, 96) } },
		{ Name = "#83 2025", Decals = { Body = D({ [1] = "rbxassetid://111040511086744", [2] = "rbxassetid://133159924698187", [3] = "rbxassetid://80957363966883" }) }, Colors = { Body = Color3.fromRGB(255, 255, 0) } },
	}
}

-- ==================== HELPERS ====================
local function createCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function createStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(60, 60, 60)
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function tween(obj, props, time, style)
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- ==================== GUI ROOT ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiveryGUI_Pro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

-- ==================== FLOATING TOGGLE BALL (Mobile + Desktop) ====================
local ToggleBall = Instance.new("TextButton")
ToggleBall.Name = "ToggleBall"
ToggleBall.Size = UDim2.new(0, 58, 0, 58)
ToggleBall.Position = UDim2.new(1, -78, 0.5, -29)
ToggleBall.BackgroundColor3 = Color3.fromRGB(180, 20, 20)
ToggleBall.Text = "⚡"
ToggleBall.TextColor3 = Color3.new(1, 1, 1)
ToggleBall.TextScaled = true
ToggleBall.Font = Enum.Font.GothamBold
ToggleBall.AutoButtonColor = false
ToggleBall.Parent = ScreenGui
createCorner(ToggleBall, 29)
createStroke(ToggleBall, Color3.fromRGB(255, 80, 80), 2)

-- make the ball draggable too
do
	local dragging, dragStart, startPos
	ToggleBall.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = ToggleBall.Position
		end
	end)
	ToggleBall.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			ToggleBall.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ==================== MAIN PANEL ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 560)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -280)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
createCorner(MainFrame, 14)
createStroke(MainFrame, Color3.fromRGB(45, 45, 55), 1.5)

-- Title bar (drag handle)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 52)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
createCorner(TitleBar, 14)

-- fix bottom corners of title
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 20)
TitleFix.Position = UDim2.new(0, 0, 1, -20)
TitleFix.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡  LIVERY SELECTOR"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -18)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
createCorner(CloseBtn, 8)

-- Dragging the whole panel by the title bar
do
	local dragging, dragStart, startPos
	TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)
	TitleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ==================== TABS ====================
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -24, 0, 42)
TabContainer.Position = UDim2.new(0, 12, 0, 62)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local function makeTab(name, posX)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.5, -6, 1, 0)
	btn.Position = UDim2.new(posX, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(180, 180, 190)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamSemibold
	btn.Parent = TabContainer
	createCorner(btn, 8)
	return btn
end

local TabLiveries = makeTab("LIVERIES", 0)
local TabCustom = makeTab("CUSTOM", 0.5)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -120)
Content.Position = UDim2.new(0, 12, 0, 112)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ==================== LIVERIES TAB ====================
local LiveriesFrame = Instance.new("Frame")
LiveriesFrame.Size = UDim2.new(1, 0, 1, 0)
LiveriesFrame.BackgroundTransparency = 1
LiveriesFrame.Parent = Content

local CarList = Instance.new("ScrollingFrame")
CarList.Size = UDim2.new(0.48, -6, 1, 0)
CarList.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
CarList.BorderSizePixel = 0
CarList.ScrollBarThickness = 4
CarList.ScrollBarImageColor3 = Color3.fromRGB(180, 40, 40)
CarList.CanvasSize = UDim2.new(0, 0, 0, 0)
CarList.AutomaticCanvasSize = Enum.AutomaticSize.Y
CarList.Parent = LiveriesFrame
createCorner(CarList, 10)

local LiveryList = Instance.new("ScrollingFrame")
LiveryList.Size = UDim2.new(0.48, -6, 1, 0)
LiveryList.Position = UDim2.new(0.52, 0, 0, 0)
LiveryList.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
LiveryList.BorderSizePixel = 0
LiveryList.ScrollBarThickness = 4
LiveryList.ScrollBarImageColor3 = Color3.fromRGB(180, 40, 40)
LiveryList.CanvasSize = UDim2.new(0, 0, 0, 0)
LiveryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
LiveryList.Parent = LiveriesFrame
createCorner(LiveryList, 10)

Instance.new("UIListLayout", CarList).Padding = UDim.new(0, 6)
Instance.new("UIListLayout", LiveryList).Padding = UDim.new(0, 6)
Instance.new("UIPadding", CarList).PaddingTop = UDim.new(0, 8)
Instance.new("UIPadding", CarList).PaddingLeft = UDim.new(0, 8)
Instance.new("UIPadding", CarList).PaddingRight = UDim.new(0, 8)
Instance.new("UIPadding", LiveryList).PaddingTop = UDim.new(0, 8)
Instance.new("UIPadding", LiveryList).PaddingLeft = UDim.new(0, 8)
Instance.new("UIPadding", LiveryList).PaddingRight = UDim.new(0, 8)

-- ==================== CUSTOM TAB ====================
local CustomFrame = Instance.new("Frame")
CustomFrame.Size = UDim2.new(1, 0, 1, 0)
CustomFrame.BackgroundTransparency = 1
CustomFrame.Visible = false
CustomFrame.Parent = Content

local FaceLabel = Instance.new("TextLabel")
FaceLabel.Size = UDim2.new(1, 0, 0, 28)
FaceLabel.BackgroundTransparency = 1
FaceLabel.Text = "SELECT FACE"
FaceLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
FaceLabel.TextXAlignment = Enum.TextXAlignment.Left
FaceLabel.TextScaled = true
FaceLabel.Font = Enum.Font.GothamSemibold
FaceLabel.Parent = CustomFrame

local FaceGrid = Instance.new("Frame")
FaceGrid.Size = UDim2.new(1, 0, 0, 110)
FaceGrid.Position = UDim2.new(0, 0, 0, 34)
FaceGrid.BackgroundTransparency = 1
FaceGrid.Parent = CustomFrame

local faces = {"Top", "Bottom", "Left", "Right", "Front", "Back"}
local selectedFace = "Top"
local faceButtons = {}

local function updateFaceButtons()
	for name, btn in pairs(faceButtons) do
		if name == selectedFace then
			btn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
			btn.TextColor3 = Color3.new(1, 1, 1)
		else
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
			btn.TextColor3 = Color3.fromRGB(180, 180, 190)
		end
	end
end

for i, face in ipairs(faces) do
	local row = math.ceil(i / 3)
	local col = (i - 1) % 3
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.32, -4, 0, 46)
	btn.Position = UDim2.new(col * 0.34, 0, (row - 1) * 0.52, 0)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	btn.Text = face
	btn.TextColor3 = Color3.fromRGB(180, 180, 190)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamSemibold
	btn.Parent = FaceGrid
	createCorner(btn, 8)
	faceButtons[face] = btn

	btn.MouseButton1Click:Connect(function()
		selectedFace = face
		updateFaceButtons()
	end)
end
updateFaceButtons()

local IdLabel = Instance.new("TextLabel")
IdLabel.Size = UDim2.new(1, 0, 0, 28)
IdLabel.Position = UDim2.new(0, 0, 0, 156)
IdLabel.BackgroundTransparency = 1
IdLabel.Text = "DECAL / TEXTURE ID"
IdLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
IdLabel.TextXAlignment = Enum.TextXAlignment.Left
IdLabel.TextScaled = true
IdLabel.Font = Enum.Font.GothamSemibold
IdLabel.Parent = CustomFrame

local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(1, 0, 0, 48)
IdBox.Position = UDim2.new(0, 0, 0, 188)
IdBox.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
IdBox.Text = ""
IdBox.PlaceholderText = "rbxassetid://123456789 or just the number"
IdBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
IdBox.TextColor3 = Color3.new(1, 1, 1)
IdBox.TextScaled = true
IdBox.Font = Enum.Font.Gotham
IdBox.ClearTextOnFocus = false
IdBox.Parent = CustomFrame
createCorner(IdBox, 10)
createStroke(IdBox, Color3.fromRGB(55, 55, 65), 1)

local ApplyCustomBtn = Instance.new("TextButton")
ApplyCustomBtn.Size = UDim2.new(1, 0, 0, 52)
ApplyCustomBtn.Position = UDim2.new(0, 0, 0, 252)
ApplyCustomBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
ApplyCustomBtn.Text = "APPLY DECAL TO SELECTED FACE"
ApplyCustomBtn.TextColor3 = Color3.new(1, 1, 1)
ApplyCustomBtn.TextScaled = true
ApplyCustomBtn.Font = Enum.Font.GothamBold
ApplyCustomBtn.Parent = CustomFrame
createCorner(ApplyCustomBtn, 10)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(1, 0, 0, 46)
ClearBtn.Position = UDim2.new(0, 0, 0, 316)
ClearBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
ClearBtn.Text = "CLEAR ALL DECALS"
ClearBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
ClearBtn.TextScaled = true
ClearBtn.Font = Enum.Font.GothamSemibold
ClearBtn.Parent = CustomFrame
createCorner(ClearBtn, 10)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 375)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 120)
StatusLabel.TextScaled = true
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = CustomFrame

-- ==================== CORE FUNCTIONS ====================
local function getCurrentCar()
	local char = player.Character
	if not char then return nil end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	for _, seat in ipairs(workspace:GetDescendants()) do
		if seat:IsA("VehicleSeat") and seat.Occupant == humanoid then
			return seat:FindFirstAncestorOfClass("Model")
		end
	end
	return nil
end

local function findBodyPart(car)
	return car:FindFirstChild("Body", true)
		or car:FindFirstChild("BodyPaint", true)
		or car:FindFirstChild("Paint", true)
end

local function applyLivery(car, livery)
	if not car then return false end

	-- remove old decals
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Decal") then
					child:Destroy()
				end
			end
		end
	end

	-- apply new decals
	for partName, faceTable in pairs(livery.Decals or {}) do
		local part = car:FindFirstChild(partName, true) or findBodyPart(car)
		if part and part:IsA("BasePart") then
			for face, tex in pairs(faceTable) do
				if type(tex) == "string" and tex ~= "" then
					local decal = Instance.new("Decal")
					decal.Texture = tex
					decal.Face = Enum.NormalId[face] or Enum.NormalId.Front
					decal.Parent = part
				end
			end
		end
	end

	-- apply colors
	for partName, color in pairs(livery.Colors or {}) do
		local part = car:FindFirstChild(partName, true) or findBodyPart(car)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end

	return true
end

local function applyCustomDecal(face, textureId)
	local car = getCurrentCar()
	if not car then
		StatusLabel.Text = "❌ Sit in a car first!"
		StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	local part = findBodyPart(car)
	if not part then
		StatusLabel.Text = "❌ No Body part found"
		StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	-- clean the id
	local id = tostring(textureId):gsub("%s+", "")
	if id == "" then
		StatusLabel.Text = "❌ Enter a valid ID"
		StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end
	if not id:find("rbxassetid://") then
		id = "rbxassetid://" .. id
	end

	-- remove existing decal on that face
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Decal") and child.Face == Enum.NormalId[face] then
			child:Destroy()
		end
	end

	local decal = Instance.new("Decal")
	decal.Texture = id
	decal.Face = Enum.NormalId[face]
	decal.Parent = part

	StatusLabel.Text = "✅ Applied to " .. face
	StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 120)
end

local function clearAllDecals()
	local car = getCurrentCar()
	if not car then
		StatusLabel.Text = "❌ Sit in a car first!"
		StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end

	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Decal") then
					child:Destroy()
				end
			end
		end
	end

	StatusLabel.Text = "✅ All decals cleared"
	StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 120)
end

-- ==================== POPULATE LIVERIES ====================
for _, carName in ipairs(LiveryData.CarOrder) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	btn.Text = carName
	btn.TextColor3 = Color3.fromRGB(230, 230, 240)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamSemibold
	btn.Parent = CarList
	createCorner(btn, 8)

	btn.MouseButton1Click:Connect(function()
		-- clear previous livery buttons
		for _, v in pairs(LiveryList:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end

		local liveries = LiveryData[carName] or {}
		for _, livery in ipairs(liveries) do
			local lBtn = Instance.new("TextButton")
			lBtn.Size = UDim2.new(1, 0, 0, 40)
			lBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
			lBtn.Text = livery.Name
			lBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
			lBtn.TextScaled = true
			lBtn.Font = Enum.Font.Gotham
			lBtn.Parent = LiveryList
			createCorner(lBtn, 8)

			lBtn.MouseButton1Click:Connect(function()
				local car = getCurrentCar()
				if car then
					if applyLivery(car, livery) then
						print("✅ Livery applied:", livery.Name)
					else
						warn("❌ Failed to apply")
					end
				else
					warn("❌ You need to be sitting in a car!")
				end
			end)
		end
	end)
end

-- ==================== TAB SWITCHING ====================
local function setTab(isLiveries)
	TabLiveries.BackgroundColor3 = isLiveries and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(35, 35, 42)
	TabLiveries.TextColor3 = isLiveries and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 190)
	TabCustom.BackgroundColor3 = (not isLiveries) and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(35, 35, 42)
	TabCustom.TextColor3 = (not isLiveries) and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 190)

	LiveriesFrame.Visible = isLiveries
	CustomFrame.Visible = not isLiveries
end

TabLiveries.MouseButton1Click:Connect(function() setTab(true) end)
TabCustom.MouseButton1Click:Connect(function() setTab(false) end)
setTab(true)

-- ==================== BUTTON CONNECTIONS ====================
ApplyCustomBtn.MouseButton1Click:Connect(function()
	applyCustomDecal(selectedFace, IdBox.Text)
end)

ClearBtn.MouseButton1Click:Connect(clearAllDecals)

-- ==================== TOGGLE LOGIC ====================
local function togglePanel()
	MainFrame.Visible = not MainFrame.Visible
	if MainFrame.Visible then
		tween(MainFrame, {BackgroundTransparency = 0}, 0.2)
	end
end

ToggleBall.MouseButton1Click:Connect(togglePanel)
CloseBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		togglePanel()
	end
end)

print("🎉 Livery GUI Pro loaded!  •  Right Shift or the ⚡ ball to open")
