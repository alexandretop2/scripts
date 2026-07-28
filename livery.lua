--[[
    ⚡ LIVERY GUI - Body Paint (Driving Empire Style)
    Draggable • Mobile ball • Pre-made + Custom with Part + Face selectors
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================== LIVERY DATA ====================
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
	s.Color = color or Color3.fromRGB(50, 50, 60)
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

-- ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiveryGUI_Pro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

-- Toggle Ball
local ToggleBall = Instance.new("TextButton")
ToggleBall.Name = "ToggleBall"
ToggleBall.Size = UDim2.new(0, 52, 0, 52)
ToggleBall.Position = UDim2.new(1, -72, 0.5, -26)
ToggleBall.BackgroundColor3 = Color3.fromRGB(190, 25, 25)
ToggleBall.Text = "⚡"
ToggleBall.TextColor3 = Color3.new(1, 1, 1)
ToggleBall.TextScaled = true
ToggleBall.Font = Enum.Font.GothamBold
ToggleBall.AutoButtonColor = false
ToggleBall.Parent = ScreenGui
createCorner(ToggleBall, 26)
createStroke(ToggleBall, Color3.fromRGB(255, 70, 70), 1.5)

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

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 540)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
createCorner(MainFrame, 12)
createStroke(MainFrame, Color3.fromRGB(40, 40, 50), 1.2)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 46)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
createCorner(TitleBar, 12)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 16)
TitleFix.Position = UDim2.new(0, 0, 1, -16)
TitleFix.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡  LIVERY"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -39, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 35, 35)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
createCorner(CloseBtn, 7)

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

-- Tabs
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 36)
TabContainer.Position = UDim2.new(0, 10, 0, 54)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local function makeTab(name, x)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.5, -5, 1, 0)
	btn.Position = UDim2.new(x, 0, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(160, 160, 175)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamSemibold
	btn.Parent = TabContainer
	createCorner(btn, 7)
	return btn
end

local TabLiveries = makeTab("LIVERIES", 0)
local TabCustom = makeTab("CUSTOM", 0.5)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -100)
Content.Position = UDim2.new(0, 10, 0, 98)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ==================== LIVERIES TAB ====================
local LiveriesFrame = Instance.new("Frame")
LiveriesFrame.Size = UDim2.new(1, 0, 1, 0)
LiveriesFrame.BackgroundTransparency = 1
LiveriesFrame.Parent = Content

local CarList = Instance.new("ScrollingFrame")
CarList.Size = UDim2.new(0.48, -5, 1, 0)
CarList.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
CarList.BorderSizePixel = 0
CarList.ScrollBarThickness = 3
CarList.ScrollBarImageColor3 = Color3.fromRGB(180, 40, 40)
CarList.AutomaticCanvasSize = Enum.AutomaticSize.Y
CarList.CanvasSize = UDim2.new(0, 0, 0, 0)
CarList.Parent = LiveriesFrame
createCorner(CarList, 9)

local LiveryList = Instance.new("ScrollingFrame")
LiveryList.Size = UDim2.new(0.48, -5, 1, 0)
LiveryList.Position = UDim2.new(0.52, 0, 0, 0)
LiveryList.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
LiveryList.BorderSizePixel = 0
LiveryList.ScrollBarThickness = 3
LiveryList.ScrollBarImageColor3 = Color3.fromRGB(180, 40, 40)
LiveryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
LiveryList.CanvasSize = UDim2.new(0, 0, 0, 0)
LiveryList.Parent = LiveriesFrame
createCorner(LiveryList, 9)

Instance.new("UIListLayout", CarList).Padding = UDim.new(0, 5)
Instance.new("UIListLayout", LiveryList).Padding = UDim.new(0, 5)

local pad1 = Instance.new("UIPadding", CarList)
pad1.PaddingTop = UDim.new(0, 6)
pad1.PaddingLeft = UDim.new(0, 6)
pad1.PaddingRight = UDim.new(0, 6)

local pad2 = Instance.new("UIPadding", LiveryList)
pad2.PaddingTop = UDim.new(0, 6)
pad2.PaddingLeft = UDim.new(0, 6)
pad2.PaddingRight = UDim.new(0, 6)

-- ==================== CUSTOM TAB ====================
local CustomFrame = Instance.new("Frame")
CustomFrame.Size = UDim2.new(1, 0, 1, 0)
CustomFrame.BackgroundTransparency = 1
CustomFrame.Visible = false
CustomFrame.Parent = Content

-- Part names that the script will look for
local partNames = {"Body", "Paint", "Paint1", "Paint2", "Paint3", "Paint4", "BodyPaint"}
local partIndex = 1
local selectedPartName = partNames[1]

local faces = {"Top", "Bottom", "Left", "Right", "Front", "Back"}
local faceIndex = 1
local selectedFace = faces[1]

-- ===== Onde será aplicado =====
local PartLabel = Instance.new("TextLabel")
PartLabel.Size = UDim2.new(1, 0, 0, 18)
PartLabel.Position = UDim2.new(0, 0, 0, 0)
PartLabel.BackgroundTransparency = 1
PartLabel.Text = "Onde será aplicado:"
PartLabel.TextColor3 = Color3.fromRGB(150, 150, 165)
PartLabel.TextXAlignment = Enum.TextXAlignment.Left
PartLabel.TextScaled = true
PartLabel.Font = Enum.Font.GothamSemibold
PartLabel.Parent = CustomFrame

local PartSelector = Instance.new("Frame")
PartSelector.Size = UDim2.new(1, 0, 0, 34)
PartSelector.Position = UDim2.new(0, 0, 0, 20)
PartSelector.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
PartSelector.Parent = CustomFrame
createCorner(PartSelector, 8)

local PartLeft = Instance.new("TextButton")
PartLeft.Size = UDim2.new(0, 38, 1, 0)
PartLeft.BackgroundTransparency = 1
PartLeft.Text = "◀"
PartLeft.TextColor3 = Color3.fromRGB(220, 220, 230)
PartLeft.TextScaled = true
PartLeft.Font = Enum.Font.GothamBold
PartLeft.Parent = PartSelector

local PartNameLabel = Instance.new("TextLabel")
PartNameLabel.Size = UDim2.new(1, -76, 1, 0)
PartNameLabel.Position = UDim2.new(0, 38, 0, 0)
PartNameLabel.BackgroundTransparency = 1
PartNameLabel.Text = selectedPartName
PartNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PartNameLabel.TextScaled = true
PartNameLabel.Font = Enum.Font.GothamBold
PartNameLabel.Parent = PartSelector

local PartRight = Instance.new("TextButton")
PartRight.Size = UDim2.new(0, 38, 1, 0)
PartRight.Position = UDim2.new(1, -38, 0, 0)
PartRight.BackgroundTransparency = 1
PartRight.Text = "▶"
PartRight.TextColor3 = Color3.fromRGB(220, 220, 230)
PartRight.TextScaled = true
PartRight.Font = Enum.Font.GothamBold
PartRight.Parent = PartSelector

PartLeft.MouseButton1Click:Connect(function()
	partIndex = partIndex - 1
	if partIndex < 1 then partIndex = #partNames end
	selectedPartName = partNames[partIndex]
	PartNameLabel.Text = selectedPartName
end)

PartRight.MouseButton1Click:Connect(function()
	partIndex = partIndex + 1
	if partIndex > #partNames then partIndex = 1 end
	selectedPartName = partNames[partIndex]
	PartNameLabel.Text = selectedPartName
end)

-- ===== Face do decal =====
local FaceTitle = Instance.new("TextLabel")
FaceTitle.Size = UDim2.new(1, 0, 0, 18)
FaceTitle.Position = UDim2.new(0, 0, 0, 60)
FaceTitle.BackgroundTransparency = 1
FaceTitle.Text = "Face do decal:"
FaceTitle.TextColor3 = Color3.fromRGB(150, 150, 165)
FaceTitle.TextXAlignment = Enum.TextXAlignment.Left
FaceTitle.TextScaled = true
FaceTitle.Font = Enum.Font.GothamSemibold
FaceTitle.Parent = CustomFrame

local FaceSelector = Instance.new("Frame")
FaceSelector.Size = UDim2.new(1, 0, 0, 34)
FaceSelector.Position = UDim2.new(0, 0, 0, 80)
FaceSelector.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
FaceSelector.Parent = CustomFrame
createCorner(FaceSelector, 8)

local FaceLeft = Instance.new("TextButton")
FaceLeft.Size = UDim2.new(0, 38, 1, 0)
FaceLeft.BackgroundTransparency = 1
FaceLeft.Text = "◀"
FaceLeft.TextColor3 = Color3.fromRGB(220, 220, 230)
FaceLeft.TextScaled = true
FaceLeft.Font = Enum.Font.GothamBold
FaceLeft.Parent = FaceSelector

local FaceLabel = Instance.new("TextLabel")
FaceLabel.Size = UDim2.new(1, -76, 1, 0)
FaceLabel.Position = UDim2.new(0, 38, 0, 0)
FaceLabel.BackgroundTransparency = 1
FaceLabel.Text = selectedFace:upper()
FaceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FaceLabel.TextScaled = true
FaceLabel.Font = Enum.Font.GothamBold
FaceLabel.Parent = FaceSelector

local FaceRight = Instance.new("TextButton")
FaceRight.Size = UDim2.new(0, 38, 1, 0)
FaceRight.Position = UDim2.new(1, -38, 0, 0)
FaceRight.BackgroundTransparency = 1
FaceRight.Text = "▶"
FaceRight.TextColor3 = Color3.fromRGB(220, 220, 230)
FaceRight.TextScaled = true
FaceRight.Font = Enum.Font.GothamBold
FaceRight.Parent = FaceSelector

FaceLeft.MouseButton1Click:Connect(function()
	faceIndex = faceIndex - 1
	if faceIndex < 1 then faceIndex = #faces end
	selectedFace = faces[faceIndex]
	FaceLabel.Text = selectedFace:upper()
end)

FaceRight.MouseButton1Click:Connect(function()
	faceIndex = faceIndex + 1
	if faceIndex > #faces then faceIndex = 1 end
	selectedFace = faces[faceIndex]
	FaceLabel.Text = selectedFace:upper()
end)

-- ID Box
local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(1, 0, 0, 36)
IdBox.Position = UDim2.new(0, 0, 0, 122)
IdBox.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
IdBox.Text = ""
IdBox.PlaceholderText = "Decal ID (ex: 123456789)"
IdBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
IdBox.TextColor3 = Color3.new(1, 1, 1)
IdBox.TextScaled = true
IdBox.Font = Enum.Font.Gotham
IdBox.ClearTextOnFocus = false
IdBox.Parent = CustomFrame
createCorner(IdBox, 8)
createStroke(IdBox, Color3.fromRGB(50, 50, 60), 1)

-- Apply Button
local ApplyCustomBtn = Instance.new("TextButton")
ApplyCustomBtn.Size = UDim2.new(1, 0, 0, 36)
ApplyCustomBtn.Position = UDim2.new(0, 0, 0, 166)
ApplyCustomBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
ApplyCustomBtn.Text = "APPLY DECAL"
ApplyCustomBtn.TextColor3 = Color3.new(1, 1, 1)
ApplyCustomBtn.TextScaled = true
ApplyCustomBtn.Font = Enum.Font.GothamBold
ApplyCustomBtn.Parent = CustomFrame
createCorner(ApplyCustomBtn, 8)

-- Clear All
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(1, 0, 0, 32)
ClearBtn.Position = UDim2.new(0, 0, 0, 208)
ClearBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
ClearBtn.Text = "CLEAR ALL"
ClearBtn.TextColor3 = Color3.fromRGB(210, 210, 220)
ClearBtn.TextScaled = true
ClearBtn.Font = Enum.Font.GothamSemibold
ClearBtn.Parent = CustomFrame
createCorner(ClearBtn, 8)

-- Your Decals label
local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, 0, 0, 20)
ListTitle.Position = UDim2.new(0, 0, 0, 248)
ListTitle.BackgroundTransparency = 1
ListTitle.Text = "YOUR DECALS"
ListTitle.TextColor3 = Color3.fromRGB(140, 140, 155)
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.TextScaled = true
ListTitle.Font = Enum.Font.GothamSemibold
ListTitle.Parent = CustomFrame

-- Decals List
local DecalList = Instance.new("ScrollingFrame")
DecalList.Size = UDim2.new(1, 0, 1, -274)
DecalList.Position = UDim2.new(0, 0, 0, 272)
DecalList.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
DecalList.BorderSizePixel = 0
DecalList.ScrollBarThickness = 3
DecalList.ScrollBarImageColor3 = Color3.fromRGB(180, 40, 40)
DecalList.AutomaticCanvasSize = Enum.AutomaticSize.Y
DecalList.CanvasSize = UDim2.new(0, 0, 0, 0)
DecalList.Parent = CustomFrame
createCorner(DecalList, 9)

local listLayout = Instance.new("UIListLayout", DecalList)
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local listPad = Instance.new("UIPadding", DecalList)
listPad.PaddingTop = UDim.new(0, 6)
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
listPad.PaddingBottom = UDim.new(0, 6)

-- ==================== LOGIC ====================
local customDecals = {} -- {partName, face, id, instance}

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

local function findPartByName(car, name)
	return car:FindFirstChild(name, true)
end

local function refreshDecalList()
	for _, child in pairs(DecalList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, data in ipairs(customDecals) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, 0, 0, 48)
		item.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
		item.LayoutOrder = i
		item.Parent = DecalList
		createCorner(item, 7)

		local partTxt = Instance.new("TextLabel")
		partTxt.Size = UDim2.new(1, -42, 0, 16)
		partTxt.Position = UDim2.new(0, 8, 0, 3)
		partTxt.BackgroundTransparency = 1
		partTxt.Text = data.partName
		partTxt.TextColor3 = Color3.fromRGB(255, 200, 100)
		partTxt.TextXAlignment = Enum.TextXAlignment.Left
		partTxt.TextScaled = true
		partTxt.Font = Enum.Font.GothamSemibold
		partTxt.Parent = item

		local faceTxt = Instance.new("TextLabel")
		faceTxt.Size = UDim2.new(1, -42, 0, 14)
		faceTxt.Position = UDim2.new(0, 8, 0, 18)
		faceTxt.BackgroundTransparency = 1
		faceTxt.Text = "Face: " .. data.face
		faceTxt.TextColor3 = Color3.fromRGB(200, 200, 210)
		faceTxt.TextXAlignment = Enum.TextXAlignment.Left
		faceTxt.TextScaled = true
		faceTxt.Font = Enum.Font.Gotham
		faceTxt.Parent = item

		local idTxt = Instance.new("TextLabel")
		idTxt.Size = UDim2.new(1, -42, 0, 12)
		idTxt.Position = UDim2.new(0, 8, 0, 32)
		idTxt.BackgroundTransparency = 1
		idTxt.Text = data.id
		idTxt.TextColor3 = Color3.fromRGB(120, 120, 135)
		idTxt.TextXAlignment = Enum.TextXAlignment.Left
		idTxt.TextScaled = true
		idTxt.Font = Enum.Font.Gotham
		idTxt.Parent = item

		local delBtn = Instance.new("TextButton")
		delBtn.Size = UDim2.new(0, 28, 0, 28)
		delBtn.Position = UDim2.new(1, -34, 0.5, -14)
		delBtn.BackgroundColor3 = Color3.fromRGB(160, 35, 35)
		delBtn.Text = "X"
		delBtn.TextColor3 = Color3.new(1, 1, 1)
		delBtn.TextScaled = true
		delBtn.Font = Enum.Font.GothamBold
		delBtn.Parent = item
		createCorner(delBtn, 6)

		delBtn.MouseButton1Click:Connect(function()
			if data.instance and data.instance.Parent then
				data.instance:Destroy()
			end
			table.remove(customDecals, i)
			refreshDecalList()
		end)
	end
end

local function applyCustomDecal()
	local car = getCurrentCar()
	if not car then
		warn("❌ Sente em um carro primeiro!")
		return
	end

	local part = findPartByName(car, selectedPartName)
	if not part or not part:IsA("BasePart") then
		warn("❌ Parte '" .. selectedPartName .. "' não encontrada no carro")
		return
	end

	local raw = tostring(IdBox.Text):gsub("%s+", "")
	if raw == "" then
		warn("❌ Digite um ID válido")
		return
	end

	local id = raw
	if not id:find("rbxassetid://") then
		id = "rbxassetid://" .. id
	end

	-- remove existing on same part + face
	for i = #customDecals, 1, -1 do
		if customDecals[i].partName == selectedPartName and customDecals[i].face == selectedFace then
			if customDecals[i].instance and customDecals[i].instance.Parent then
				customDecals[i].instance:Destroy()
			end
			table.remove(customDecals, i)
		end
	end

	-- also clear leftover decal on that face of the part
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Decal") and child.Face == Enum.NormalId[selectedFace] then
			child:Destroy()
		end
	end

	local decal = Instance.new("Decal")
	decal.Texture = id
	decal.Face = Enum.NormalId[selectedFace]
	decal.Parent = part

	table.insert(customDecals, {
		partName = selectedPartName,
		face = selectedFace,
		id = id,
		instance = decal
	})

	IdBox.Text = ""
	refreshDecalList()
end

local function clearAllDecals()
	local car = getCurrentCar()
	if car then
		for _, part in ipairs(car:GetDescendants()) do
			if part:IsA("BasePart") then
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("Decal") then
						child:Destroy()
					end
				end
			end
		end
	end
	customDecals = {}
	refreshDecalList()
end

local function applyLivery(car, livery)
	if not car then return false end

	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Decal") then child:Destroy() end
			end
		end
	end

	for partName, faceTable in pairs(livery.Decals or {}) do
		local part = car:FindFirstChild(partName, true)
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

	for partName, color in pairs(livery.Colors or {}) do
		local part = car:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end

	customDecals = {}
	refreshDecalList()
	return true
end

-- Populate cars
for _, carName in ipairs(LiveryData.CarOrder) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	btn.Text = carName
	btn.TextColor3 = Color3.fromRGB(230, 230, 240)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamSemibold
	btn.Parent = CarList
	createCorner(btn, 7)

	btn.MouseButton1Click:Connect(function()
		for _, v in pairs(LiveryList:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end

		local liveries = LiveryData[carName] or {}
		for _, livery in ipairs(liveries) do
			local lBtn = Instance.new("TextButton")
			lBtn.Size = UDim2.new(1, 0, 0, 34)
			lBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
			lBtn.Text = livery.Name
			lBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
			lBtn.TextScaled = true
			lBtn.Font = Enum.Font.Gotham
			lBtn.Parent = LiveryList
			createCorner(lBtn, 7)

			lBtn.MouseButton1Click:Connect(function()
				local car = getCurrentCar()
				if car then
					applyLivery(car, livery)
				else
					warn("❌ Você precisa estar sentado em um carro!")
				end
			end)
		end
	end)
end

-- Tabs
local function setTab(isLiveries)
	TabLiveries.BackgroundColor3 = isLiveries and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(32, 32, 40)
	TabLiveries.TextColor3 = isLiveries and Color3.new(1,1,1) or Color3.fromRGB(160, 160, 175)
	TabCustom.BackgroundColor3 = (not isLiveries) and Color3.fromRGB(180, 30, 30) or Color3.fromRGB(32, 32, 40)
	TabCustom.TextColor3 = (not isLiveries) and Color3.new(1,1,1) or Color3.fromRGB(160, 160, 175)

	LiveriesFrame.Visible = isLiveries
	CustomFrame.Visible = not isLiveries
end

TabLiveries.MouseButton1Click:Connect(function() setTab(true) end)
TabCustom.MouseButton1Click:Connect(function() setTab(false) end)
setTab(true)

-- Buttons
ApplyCustomBtn.MouseButton1Click:Connect(applyCustomDecal)
ClearBtn.MouseButton1Click:Connect(clearAllDecals)

-- Toggle
local function togglePanel()
	MainFrame.Visible = not MainFrame.Visible
end

ToggleBall.MouseButton1Click:Connect(togglePanel)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		togglePanel()
	end
end)

print("🎉 Livery GUI Pro loaded!  •  Right Shift or ⚡ ball")
