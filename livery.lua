--[[
	⚡ LIVERY & TIRE STUDIO PRO (v3.4)
	Fix A-Chassis: Suporte a 'Wheel' Invisível com Mesh 'Tire' Interna
	Destruição de GUI Antiga • Auto-conversão de IDs • Animações UI
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. DESTRUIR GUI ANTIGA SE EXISTIR
local oldGui = playerGui:FindFirstChild("LiveryGUI_Pro")
if oldGui then
	oldGui:Destroy()
end

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
		{ Name = "Sem Decal", Decals = {}, Colors = {} },
		{ Name = "#50 2023", Decals = { Body = D({ [1] = "rbxassetid://140326714061095", [2] = "rbxassetid://110677527162804", [3] = "rbxassetid://77854762433621" }) }, Colors = { Body = Color3.fromRGB(255, 0, 0) } },
		{ Name = "#50 2022", Decals = { Body = D({ [1] = "rbxassetid://103090740061479", [2] = "rbxassetid://139490989781460", [3] = "rbxassetid://120216683354391" }) }, Colors = { Body = Color3.fromRGB(255, 0, 0) } },
		{ Name = "#83 2025", Decals = { Body = D({ [1] = "rbxassetid://111040511086744", [2] = "rbxassetid://133159924698187", [3] = "rbxassetid://80957363966883" }) }, Colors = { Body = Color3.fromRGB(255, 255, 0) } },
	},

	["Porsche 963"] = {
		{ Name = "Sem Decal", Decals = {}, Colors = {} },
		{ Name = "PENSKE", Decals = {
			Body = D({ [1] = "rbxassetid://97376148413901", [2] = "rbxassetid://136015482622425", [3] = "rbxassetid://92376148413901" }),
			Body2 = D({ [1] = "rbxassetid://116239954694493", [2] = "rbxassetid://130785882062097", [3] = "rbxassetid://132953677031751" }),
			BlackTrim = D({ [2] = "rbxassetid://120671490417314", [3] = "rbxassetid://102793001865316" })
		}, Colors = { Body = Color3.fromRGB(180,0,0), Body2 = Color3.fromRGB(255,255,255), BlackTrim = Color3.fromRGB(20,20,20) }}
	},

	["Mercedes-AMG"] = {
		{ Name = "Sem Decal", Decals = {}, Colors = {} },
		{ Name = "Verstappen", Decals = { Body = D({ [1] = "rbxassetid://131808554679427", [2] = "rbxassetid://114281521031058", [3] = "rbxassetid://83152891843483" }) }, Colors = { Body = Color3.fromRGB(0, 0, 100) } },
	},

	["Nissan GTR R35"] = {
		{ Name = "Sem Decal", Decals = {}, Colors = {} },
		{ Name = "#23", Decals = { Body = D({ [1] = "rbxassetid://90166247493480", [2] = "rbxassetid://108840573040409", [3] = "rbxassetid://134210963502108" }) }, Colors = { Body = Color3.fromRGB(85, 0, 0) } },
	},

	["Formula 2019"] = {
		{ Name = "Sem Decal", Decals = {}, Colors = {} },
		{ Name = "Hamilton", Decals = { Body = D({ [1] = "rbxassetid://91627508278365", [2] = "rbxassetid://113207528595123", [3] = "rbxassetid://98458253015274", [6] = "rbxassetid://91627508278365" }) }, Colors = { Body = Color3.fromRGB(117, 117, 117) } },
		{ Name = "W11", Decals = { Body = D({ [1] = "rbxassetid://88472765027782", [2] = "rbxassetid://118378348607428", [3] = "rbxassetid://108271742883272" }) }, Colors = { Body = Color3.fromRGB(0, 0, 0) } },
		{ Name = "Verstappen", Decals = { Body = D({ [1] = "rbxassetid://122653234892723", [2] = "rbxassetid://92975938094145", [3] = "rbxassetid://78914381724629" }) }, Colors = { Body = Color3.fromRGB(0, 0, 40) } },
	},

	["Brabham"] = {
		{ Name = "Sem Decal", Decals = {}, Colors = {} },
		{ Name = "#12", Decals = { Body = D({ [1] = "rbxassetid://80986530120176", [2] = "rbxassetid://135484337113900", [3] = "rbxassetid://92542640479980", [4] = "rbxassetid://122014159784272" }) }, Colors = { Body = Color3.fromRGB(0, 56, 22) } },
		{ Name = "GoodYear", Decals = { Body = D({ [1] = "rbxassetid://115172559609442", [2] = "rbxassetid://114399968763283", [3] = "rbxassetid://124154800333366", [4] = "rbxassetid://102962414054085", [5] = "rbxassetid://113462327011074" }) }, Colors = { Body = Color3.fromRGB(0, 32, 96) } },
		{ Name = "#83 2025", Decals = { Body = D({ [1] = "rbxassetid://111040511086744", [2] = "rbxassetid://133159924698187", [3] = "rbxassetid://80957363966883" }) }, Colors = { Body = Color3.fromRGB(255, 255, 0) } },
	}
}

-- ==================== DESIGN THEME ====================
local Theme = {
	Background = Color3.fromRGB(15, 16, 20),
	Header = Color3.fromRGB(22, 24, 30),
	Card = Color3.fromRGB(25, 27, 35),
	CardHover = Color3.fromRGB(35, 38, 50),
	InputBg = Color3.fromRGB(18, 20, 26),
	Accent = Color3.fromRGB(235, 45, 60),
	AccentGlow = Color3.fromRGB(255, 80, 95),
	TextMain = Color3.fromRGB(240, 240, 245),
	TextMuted = Color3.fromRGB(130, 135, 150),
	Border = Color3.fromRGB(40, 44, 58)
}

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function parseAssetId(input)
	local clean = tostring(input):gsub("%s+", "")
	if clean == "" then return nil end
	local id = clean:match("%d+")
	if id then
		return "rbxassetid://" .. id
	end
	return nil
end

-- ==================== GUI ROOT ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiveryGUI_Pro"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

-- Toggle Ball
local ToggleBall = Instance.new("TextButton")
ToggleBall.Name = "ToggleBall"
ToggleBall.Size = UDim2.new(0, 50, 0, 50)
ToggleBall.Position = UDim2.new(1, -70, 0.5, -25)
ToggleBall.BackgroundColor3 = Theme.Accent
ToggleBall.Text = "⚡"
ToggleBall.TextColor3 = Theme.TextMain
ToggleBall.TextSize = 22
ToggleBall.Font = Enum.Font.FredokaOne
ToggleBall.AutoButtonColor = false
ToggleBall.Parent = ScreenGui
addCorner(ToggleBall, 25)
addStroke(ToggleBall, Theme.AccentGlow, 1.5)

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

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 440, 0, 560)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -280)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 14)
addStroke(MainFrame, Theme.Border, 1.2)

-- Header Bar
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Theme.Header
Header.BorderSizePixel = 0
Header.Parent = MainFrame
addCorner(Header, 14)

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 15)
HeaderFix.Position = UDim2.new(0, 0, 1, -15)
HeaderFix.BackgroundColor3 = Theme.Header
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "LIVERY <font color=\"#EB2D3C\">STUDIO</font>"
Title.RichText = true
Title.TextColor3 = Theme.TextMain
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.TextMuted
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
addCorner(CloseBtn, 8)

CloseBtn.MouseEnter:Connect(function()
	TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.new(1,1,1)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
	TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 38, 48), TextColor3 = Theme.TextMuted}):Play()
end)

do
	local dragging, dragStart, startPos
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)
	Header.InputEnded:Connect(function(input)
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

-- Navigation Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 36)
TabBar.Position = UDim2.new(0, 12, 0, 60)
TabBar.BackgroundColor3 = Theme.Header
TabBar.Parent = MainFrame
addCorner(TabBar, 8)
addStroke(TabBar, Theme.Border, 1)

local function makeTab(name, x, widthScale)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(widthScale, -4, 1, -6)
	btn.Position = UDim2.new(x, 2, 0, 3)
	btn.BackgroundColor3 = Theme.Background
	btn.BackgroundTransparency = 1
	btn.Text = name
	btn.TextColor3 = Theme.TextMuted
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.Parent = TabBar
	addCorner(btn, 6)
	return btn
end

local TabLiveries = makeTab("LIVERIES", 0, 0.333)
local TabCustom = makeTab("CUSTOM DECAL", 0.333, 0.333)
local TabTires = makeTab("PNEUS 🛞", 0.666, 0.334)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -112)
Content.Position = UDim2.new(0, 12, 0, 104)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ==================== LIVERIES TAB ====================
local LiveriesFrame = Instance.new("Frame")
LiveriesFrame.Size = UDim2.new(1, 0, 1, 0)
LiveriesFrame.BackgroundTransparency = 1
LiveriesFrame.Parent = Content

local CarList = Instance.new("ScrollingFrame")
CarList.Size = UDim2.new(0.48, -4, 1, 0)
CarList.BackgroundColor3 = Theme.Card
CarList.BorderSizePixel = 0
CarList.ScrollBarThickness = 2
CarList.ScrollBarImageColor3 = Theme.Accent
CarList.AutomaticCanvasSize = Enum.AutomaticSize.Y
CarList.CanvasSize = UDim2.new(0,0,0,0)
CarList.Parent = LiveriesFrame
addCorner(CarList, 8)
addStroke(CarList, Theme.Border, 1)

local LiveryList = Instance.new("ScrollingFrame")
LiveryList.Size = UDim2.new(0.52, -4, 1, 0)
LiveryList.Position = UDim2.new(0.48, 8, 0, 0)
LiveryList.BackgroundColor3 = Theme.Card
LiveryList.BorderSizePixel = 0
LiveryList.ScrollBarThickness = 2
LiveryList.ScrollBarImageColor3 = Theme.Accent
LiveryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
LiveryList.CanvasSize = UDim2.new(0,0,0,0)
LiveryList.Parent = LiveriesFrame
addCorner(LiveryList, 8)
addStroke(LiveryList, Theme.Border, 1)

local function applyListPadding(list)
	local layout = Instance.new("UIListLayout", list)
	layout.Padding = UDim.new(0, 6)
	local pad = Instance.new("UIPadding", list)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
end

applyListPadding(CarList)
applyListPadding(LiveryList)

-- ==================== CUSTOM TAB ====================
local CustomFrame = Instance.new("Frame")
CustomFrame.Size = UDim2.new(1, 0, 1, 0)
CustomFrame.BackgroundTransparency = 1
CustomFrame.Visible = false
CustomFrame.Parent = Content

local partNames = {"Body", "Paint", "Paint1", "Paint2", "Paint3", "Paint4", "BodyPaint"}
local partIndex = 1
local selectedPartName = partNames[1]

local faces = {"Left", "Right", "Top", "Bottom", "Front", "Back"}
local faceIndex = 1
local selectedFace = faces[1]

local function createSelector(parent, yPos, titleText, initialVal, onLeft, onRight)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 14)
	lbl.Position = UDim2.new(0, 0, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = titleText:upper()
	lbl.TextColor3 = Theme.TextMuted
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextSize = 11
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = parent

	local box = Instance.new("Frame")
	box.Size = UDim2.new(1, 0, 0, 36)
	box.Position = UDim2.new(0, 0, 0, yPos + 18)
	box.BackgroundColor3 = Theme.Card
	box.Parent = parent
	addCorner(box, 8)
	addStroke(box, Theme.Border, 1)

	local btnL = Instance.new("TextButton")
	btnL.Size = UDim2.new(0, 36, 1, 0)
	btnL.BackgroundTransparency = 1
	btnL.Text = "‹"
	btnL.TextColor3 = Theme.TextMain
	btnL.TextSize = 20
	btnL.Font = Enum.Font.GothamBold
	btnL.Parent = box

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(1, -72, 1, 0)
	valLbl.Position = UDim2.new(0, 36, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = tostring(initialVal):upper()
	valLbl.TextColor3 = Theme.TextMain
	valLbl.TextSize = 13
	valLbl.Font = Enum.Font.GothamBold
	valLbl.Parent = box

	local btnR = Instance.new("TextButton")
	btnR.Size = UDim2.new(0, 36, 1, 0)
	btnR.Position = UDim2.new(1, -36, 0, 0)
	btnR.BackgroundTransparency = 1
	btnR.Text = "›"
	btnR.TextColor3 = Theme.TextMain
	btnR.TextSize = 20
	btnR.Font = Enum.Font.GothamBold
	btnR.Parent = box

	btnL.MouseButton1Click:Connect(function() onLeft(valLbl) end)
	btnR.MouseButton1Click:Connect(function() onRight(valLbl) end)
end

createSelector(CustomFrame, 0, "Peça Alvo:", selectedPartName, function(lbl)
	partIndex = partIndex - 1
	if partIndex < 1 then partIndex = #partNames end
	selectedPartName = partNames[partIndex]
	lbl.Text = selectedPartName:upper()
end, function(lbl)
	partIndex = partIndex + 1
	if partIndex > #partNames then partIndex = 1 end
	selectedPartName = partNames[partIndex]
	lbl.Text = selectedPartName:upper()
end)

createSelector(CustomFrame, 60, "Face de Aplicação:", selectedFace, function(lbl)
	faceIndex = faceIndex - 1
	if faceIndex < 1 then faceIndex = #faces end
	selectedFace = faces[faceIndex]
	lbl.Text = selectedFace:upper()
end, function(lbl)
	faceIndex = faceIndex + 1
	if faceIndex > #faces then faceIndex = 1 end
	selectedFace = faces[faceIndex]
	lbl.Text = selectedFace:upper()
end)

local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(1, 0, 0, 38)
IdBox.Position = UDim2.new(0, 0, 0, 122)
IdBox.BackgroundColor3 = Theme.InputBg
IdBox.Text = ""
IdBox.PlaceholderText = "Cole o ID ou URL do Decal..."
IdBox.PlaceholderColor3 = Theme.TextMuted
IdBox.TextColor3 = Theme.TextMain
IdBox.TextSize = 12
IdBox.Font = Enum.Font.Gotham
IdBox.ClearTextOnFocus = false
IdBox.Parent = CustomFrame
addCorner(IdBox, 8)
local idBoxStroke = addStroke(IdBox, Theme.Border, 1)

IdBox.Focused:Connect(function()
	TweenService:Create(idBoxStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
end)
IdBox.FocusLost:Connect(function()
	TweenService:Create(idBoxStroke, TweenInfo.new(0.2), {Color = Theme.Border}):Play()
end)

local ApplyCustomBtn = Instance.new("TextButton")
ApplyCustomBtn.Size = UDim2.new(1, 0, 0, 36)
ApplyCustomBtn.Position = UDim2.new(0, 0, 0, 168)
ApplyCustomBtn.BackgroundColor3 = Theme.Accent
ApplyCustomBtn.Text = "APLICAR DECAL"
ApplyCustomBtn.TextColor3 = Color3.new(1, 1, 1)
ApplyCustomBtn.TextSize = 13
ApplyCustomBtn.Font = Enum.Font.GothamBold
ApplyCustomBtn.AutoButtonColor = false
ApplyCustomBtn.Parent = CustomFrame
addCorner(ApplyCustomBtn, 8)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(1, 0, 0, 30)
ClearBtn.Position = UDim2.new(0, 0, 0, 210)
ClearBtn.BackgroundColor3 = Theme.Card
ClearBtn.Text = "LIMPAR DECALS DO CARRO"
ClearBtn.TextColor3 = Theme.TextMuted
ClearBtn.TextSize = 11
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.AutoButtonColor = false
ClearBtn.Parent = CustomFrame
addCorner(ClearBtn, 8)
addStroke(ClearBtn, Theme.Border, 1)

local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, 0, 0, 14)
ListTitle.Position = UDim2.new(0, 0, 0, 248)
ListTitle.BackgroundTransparency = 1
ListTitle.Text = "DECALS ATIVOS:"
ListTitle.TextColor3 = Theme.TextMuted
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.TextSize = 11
ListTitle.Font = Enum.Font.GothamBold
ListTitle.Parent = CustomFrame

local DecalList = Instance.new("ScrollingFrame")
DecalList.Size = UDim2.new(1, 0, 1, -268)
DecalList.Position = UDim2.new(0, 0, 0, 268)
DecalList.BackgroundColor3 = Theme.Card
DecalList.BorderSizePixel = 0
DecalList.ScrollBarThickness = 2
DecalList.ScrollBarImageColor3 = Theme.Accent
DecalList.AutomaticCanvasSize = Enum.AutomaticSize.Y
DecalList.CanvasSize = UDim2.new(0, 0, 0, 0)
DecalList.Parent = CustomFrame
addCorner(DecalList, 8)
addStroke(DecalList, Theme.Border, 1)

applyListPadding(DecalList)

-- ==================== TIRES TAB ====================
local TiresFrame = Instance.new("Frame")
TiresFrame.Size = UDim2.new(1, 0, 1, 0)
TiresFrame.BackgroundTransparency = 1
TiresFrame.Visible = false
TiresFrame.Parent = Content

local TireInfoTitle = Instance.new("TextLabel")
TireInfoTitle.Size = UDim2.new(1, 0, 0, 14)
TireInfoTitle.Position = UDim2.new(0, 0, 0, 0)
TireInfoTitle.BackgroundTransparency = 1
TireInfoTitle.Text = "POSIÇÃO FIXA DA TEXTURA: LEFT FACE"
TireInfoTitle.TextColor3 = Theme.Accent
TireInfoTitle.TextXAlignment = Enum.TextXAlignment.Left
TireInfoTitle.TextSize = 11
TireInfoTitle.Font = Enum.Font.GothamBold
TireInfoTitle.Parent = TiresFrame

local TireIdBox = Instance.new("TextBox")
TireIdBox.Size = UDim2.new(1, 0, 0, 38)
TireIdBox.Position = UDim2.new(0, 0, 0, 24)
TireIdBox.BackgroundColor3 = Theme.InputBg
TireIdBox.Text = ""
TireIdBox.PlaceholderText = "Cole o ID ou URL da Textura do Pneu..."
TireIdBox.PlaceholderColor3 = Theme.TextMuted
TireIdBox.TextColor3 = Theme.TextMain
TireIdBox.TextSize = 12
TireIdBox.Font = Enum.Font.Gotham
TireIdBox.ClearTextOnFocus = false
TireIdBox.Parent = TiresFrame
addCorner(TireIdBox, 8)
local tireIdStroke = addStroke(TireIdBox, Theme.Border, 1)

TireIdBox.Focused:Connect(function()
	TweenService:Create(tireIdStroke, TweenInfo.new(0.2), {Color = Theme.Accent}):Play()
end)
TireIdBox.FocusLost:Connect(function()
	TweenService:Create(tireIdStroke, TweenInfo.new(0.2), {Color = Theme.Border}):Play()
end)

local ApplyTireBtn = Instance.new("TextButton")
ApplyTireBtn.Size = UDim2.new(1, 0, 0, 38)
ApplyTireBtn.Position = UDim2.new(0, 0, 0, 70)
ApplyTireBtn.BackgroundColor3 = Theme.Accent
ApplyTireBtn.Text = "APLICAR NOS PNEUS"
ApplyTireBtn.TextColor3 = Color3.new(1, 1, 1)
ApplyTireBtn.TextSize = 13
ApplyTireBtn.Font = Enum.Font.GothamBold
ApplyTireBtn.AutoButtonColor = false
ApplyTireBtn.Parent = TiresFrame
addCorner(ApplyTireBtn, 8)

local ClearTiresBtn = Instance.new("TextButton")
ClearTiresBtn.Size = UDim2.new(1, 0, 0, 32)
ClearTiresBtn.Position = UDim2.new(0, 0, 0, 116)
ClearTiresBtn.BackgroundColor3 = Theme.Card
ClearTiresBtn.Text = "REMOVER TEXTURA DOS PNEUS"
ClearTiresBtn.TextColor3 = Theme.TextMuted
ClearTiresBtn.TextSize = 11
ClearTiresBtn.Font = Enum.Font.GothamBold
ClearTiresBtn.AutoButtonColor = false
ClearTiresBtn.Parent = TiresFrame
addCorner(ClearTiresBtn, 8)
addStroke(ClearTiresBtn, Theme.Border, 1)

local TireStatus = Instance.new("TextLabel")
TireStatus.Size = UDim2.new(1, 0, 0, 80)
TireStatus.Position = UDim2.new(0, 0, 0, 158)
TireStatus.BackgroundColor3 = Theme.Card
TireStatus.Text = "ℹ️ Estrutura tratada:\nRL, RR, FR, FL ➔ Wheel (Part Invisível) ➔ Tire (Mesh 3D)\n\n• O script injeta a textura diretamente na Mesh visível do Pneu."
TireStatus.TextColor3 = Theme.TextMuted
TireStatus.TextSize = 11
TireStatus.Font = Enum.Font.Gotham
TireStatus.TextWrapped = true
TireStatus.Parent = TiresFrame
addCorner(TireStatus, 8)
addStroke(TireStatus, Theme.Border, 1)

-- ==================== LOGIC ====================
local customDecals = {}

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

-- Mapeia as 4 rodas no A-Chassis
local function getCarWheelModels(car)
	local wheelModels = {}
	local wheelNames = {"RL", "RR", "FR", "FL"}
	for _, name in ipairs(wheelNames) do
		local wModel = car:FindFirstChild(name, true)
		if wModel then
			table.insert(wheelModels, wModel)
		end
	end
	return wheelModels
end

local function applyTireTexture()
	local car = getCurrentCar()
	if not car then
		warn("❌ Entre em um carro antes de aplicar!")
		return
	end

	local wheelModels = getCarWheelModels(car)
	if #wheelModels == 0 then
		warn("❌ Nenhuma roda encontrada na estrutura RL/RR/FR/FL!")
		return
	end

	local assetId = parseAssetId(TireIdBox.Text)
	if not assetId then
		warn("❌ Digite um ID de decal/imagem válido!")
		return
	end

	local appliedCount = 0

	for _, wheelModel in ipairs(wheelModels) do
		-- Varre todos os descendentes do Model da Roda para encontrar partes visíveis e meshes
		for _, desc in ipairs(wheelModel:GetDescendants()) do
			-- Se for uma MeshPart visível (como a 'Tire' MeshPart)
			if desc:IsA("MeshPart") then
				desc.TextureID = assetId
				appliedCount = appliedCount + 1
			
			-- Se for uma SpecialMesh/FileMesh inserida na roda
			elseif desc:IsA("SpecialMesh") or desc:IsA("FileMesh") then
				desc.TextureId = assetId
				appliedCount = appliedCount + 1

			-- Se for uma Part visível (não a Wheel transparente do A-Chassis)
			elseif desc:IsA("BasePart") and desc.Transparency < 1 then
				-- Limpa decals antigas
				for _, child in ipairs(desc:GetChildren()) do
					if (child:IsA("Decal") or child:IsA("Texture")) and child.Name == "TireTexture" then
						child:Destroy()
					end
				end

				local decal = Instance.new("Decal")
				decal.Name = "TireTexture"
				decal.Texture = assetId
				decal.Face = Enum.NormalId.Left
				decal.Parent = desc
			end
		end
	end

	TireIdBox.Text = ""
	print("✅ Textura de pneu injetada em " .. appliedCount .. " elementos gráficos das rodas!")
end

local function clearTireTextures()
	local car = getCurrentCar()
	if not car then return end
	local wheelModels = getCarWheelModels(car)
	for _, wheelModel in ipairs(wheelModels) do
		for _, desc in ipairs(wheelModel:GetDescendants()) do
			if desc:IsA("MeshPart") then
				desc.TextureID = ""
			elseif desc:IsA("SpecialMesh") or desc:IsA("FileMesh") then
				desc.TextureId = ""
			elseif desc:IsA("BasePart") then
				for _, child in ipairs(desc:GetChildren()) do
					if (child:IsA("Decal") or child:IsA("Texture")) and child.Name == "TireTexture" then
						child:Destroy()
					end
				end
			end
		end
	end
	print("✅ Texturas dos pneus removidas com sucesso!")
end

local function refreshDecalList()
	for _, child in pairs(DecalList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for i, data in ipairs(customDecals) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, 0, 0, 42)
		item.BackgroundColor3 = Theme.Background
		item.LayoutOrder = i
		item.Parent = DecalList
		addCorner(item, 6)
		addStroke(item, Theme.Border, 1)

		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, -40, 1, 0)
		info.Position = UDim2.new(0, 8, 0, 0)
		info.BackgroundTransparency = 1
		info.Text = string.format("<font color=\"#EB2D3C\"><b>%s</b></font> | Face: %s\n<font color=\"#848796\">%s</font>", data.partName, data.face, data.id)
		info.RichText = true
		info.TextColor3 = Theme.TextMain
		info.TextXAlignment = Enum.TextXAlignment.Left
		info.TextSize = 11
		info.Font = Enum.Font.Gotham
		info.Parent = item

		local delBtn = Instance.new("TextButton")
		delBtn.Size = UDim2.new(0, 26, 0, 26)
		delBtn.Position = UDim2.new(1, -30, 0.5, -13)
		delBtn.BackgroundColor3 = Theme.Accent
		delBtn.Text = "✕"
		delBtn.TextColor3 = Color3.new(1, 1, 1)
		delBtn.TextSize = 11
		delBtn.Font = Enum.Font.GothamBold
		delBtn.AutoButtonColor = false
		delBtn.Parent = item
		addCorner(delBtn, 6)

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
		warn("❌ Entre em um carro antes de aplicar!")
		return
	end

	local part = car:FindFirstChild(selectedPartName, true)
	if not part or not part:IsA("BasePart") then
		warn("❌ Peça '" .. selectedPartName .. "' não encontrada no veículo!")
		return
	end

	local assetId = parseAssetId(IdBox.Text)
	if not assetId then
		warn("❌ Insira um ID válido!")
		return
	end

	for i = #customDecals, 1, -1 do
		if customDecals[i].partName == selectedPartName and customDecals[i].face == selectedFace then
			if customDecals[i].instance and customDecals[i].instance.Parent then
				customDecals[i].instance:Destroy()
			end
			table.remove(customDecals, i)
		end
	end

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Decal") and child.Face == Enum.NormalId[selectedFace] then
			child:Destroy()
		end
	end

	local decal = Instance.new("Decal")
	decal.Texture = assetId
	decal.Face = Enum.NormalId[selectedFace]
	decal.Parent = part

	table.insert(customDecals, {
		partName = selectedPartName,
		face = selectedFace,
		id = assetId,
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
	if not car then return end

	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Decal") then
					child:Destroy()
				end
			end
		end
	end

	local fallbackNames = {"Body", "Paint", "Paint1", "Paint2", "Paint3", "Paint4", "BodyPaint", "Body2", "Chassis"}

	for partName, faceTable in pairs(livery.Decals or {}) do
		local part = car:FindFirstChild(partName, true)
		if not part then
			for _, name in ipairs(fallbackNames) do
				part = car:FindFirstChild(name, true)
				if part and part:IsA("BasePart") then break end
			end
		end

		if part and part:IsA("BasePart") then
			for face, tex in pairs(faceTable) do
				local assetId = parseAssetId(tex)
				if assetId then
					local decal = Instance.new("Decal")
					decal.Texture = assetId
					decal.Face = Enum.NormalId[face] or Enum.NormalId.Front
					decal.Parent = part
				end
			end
		end
	end

	for partName, color in pairs(livery.Colors or {}) do
		local part = car:FindFirstChild(partName, true)
		if not part then
			for _, name in ipairs(fallbackNames) do
				part = car:FindFirstChild(name, true)
				if part and part:IsA("BasePart") then break end
			end
		end
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end

	customDecals = {}
	refreshDecalList()
end

-- Render Car List & Liveries
for _, carName in ipairs(LiveryData.CarOrder) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Theme.Background
	btn.Text = carName
	btn.TextColor3 = Theme.TextMain
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.Parent = CarList
	addCorner(btn, 6)
	addStroke(btn, Theme.Border, 1)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.CardHover}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		for _, v in pairs(LiveryList:GetChildren()) do
			if v:IsA("TextButton") then v:Destroy() end
		end

		local liveries = LiveryData[carName] or {}
		for _, livery in ipairs(liveries) do
			local lBtn = Instance.new("TextButton")
			lBtn.Size = UDim2.new(1, 0, 0, 30)
			lBtn.BackgroundColor3 = Theme.Background
			lBtn.Text = livery.Name
			lBtn.TextColor3 = Theme.TextMain
			lBtn.TextSize = 11
			lBtn.Font = Enum.Font.Gotham
			lBtn.AutoButtonColor = false
			lBtn.Parent = LiveryList
			addCorner(lBtn, 6)
			addStroke(lBtn, Theme.Border, 1)

			lBtn.MouseEnter:Connect(function()
				TweenService:Create(lBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.CardHover}):Play()
			end)
			lBtn.MouseLeave:Connect(function()
				TweenService:Create(lBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play()
			end)

			lBtn.MouseButton1Click:Connect(function()
				local car = getCurrentCar()
				if car then
					applyLivery(car, livery)
				else
					warn("❌ Você precisa estar sentado no carro!")
				end
			end)
		end
	end)
end

-- Navigation Handler
local function setTab(tabIdx)
	local tabs = {TabLiveries, TabCustom, TabTires}
	local frames = {LiveriesFrame, CustomFrame, TiresFrame}

	for i, tab in ipairs(tabs) do
		if i == tabIdx then
			TweenService:Create(tab, TweenInfo.new(0.2), {
				BackgroundColor3 = Theme.Accent,
				TextColor3 = Color3.new(1,1,1),
				BackgroundTransparency = 0
			}):Play()
			frames[i].Visible = true
		else
			TweenService:Create(tab, TweenInfo.new(0.2), {
				BackgroundColor3 = Theme.Background,
				TextColor3 = Theme.TextMuted,
				BackgroundTransparency = 1
			}):Play()
			frames[i].Visible = false
		end
	end
end

TabLiveries.MouseButton1Click:Connect(function() setTab(1) end)
TabCustom.MouseButton1Click:Connect(function() setTab(2) end)
TabTires.MouseButton1Click:Connect(function() setTab(3) end)
setTab(1)

-- Connect Actions
ApplyCustomBtn.MouseButton1Click:Connect(applyCustomDecal)
ClearBtn.MouseButton1Click:Connect(clearAllDecals)
ApplyTireBtn.MouseButton1Click:Connect(applyTireTexture)
ClearTiresBtn.MouseButton1Click:Connect(clearTireTextures)

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

print("⚡ Livery & Tire Studio PRO v3.4 carregado com sucesso!")
