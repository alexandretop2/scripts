--[[
    ⚡ CONTROL HUB  —  Vehicle Nitro + Jump
    Fixed loading + polished dark UI
]]

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- 0. CLEANUP
-- ─────────────────────────────────────────────
if playerGui:FindFirstChild("CustomControlHub") then
    playerGui.CustomControlHub:Destroy()
end

-- ─────────────────────────────────────────────
-- 1. CONFIG
-- ─────────────────────────────────────────────
local menuKey        = Enum.KeyCode.J
local isMenuOpen     = true
local isBindingKey   = false
local BOOST_FORCE    = 25000
local JUMP_FORCE     = 8000
local isShiftPressed = false
local boostConnection = nil
local activeVectorForce = nil
local activeAttachment  = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ─────────────────────────────────────────────
-- Drag helper
-- ─────────────────────────────────────────────
local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        guiObject.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ─────────────────────────────────────────────
-- 2. SCREEN GUI
-- ─────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "CustomControlHub"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ─────────────────────────────────────────────
-- LOADING SCREEN (bullet-proof)
-- ─────────────────────────────────────────────
local loadingFrame = Instance.new("Frame")
loadingFrame.Name                   = "LoadingFrame"
loadingFrame.Size                   = UDim2.new(0, 300, 0, 140)
loadingFrame.Position               = UDim2.new(0.5, -150, 0.5, -70)
loadingFrame.BackgroundColor3       = Color3.fromRGB(16, 16, 22)
loadingFrame.BorderSizePixel        = 0
loadingFrame.Parent                 = screenGui

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 14)
loadCorner.Parent = loadingFrame

local loadStroke = Instance.new("UIStroke")
loadStroke.Color        = Color3.fromRGB(0, 160, 255)
loadStroke.Thickness    = 1.5
loadStroke.Transparency = 0.4
loadStroke.Parent       = loadingFrame

local loadTitle = Instance.new("TextLabel")
loadTitle.Size                  = UDim2.new(1, 0, 0, 40)
loadTitle.Position              = UDim2.new(0, 0, 0, 18)
loadTitle.BackgroundTransparency = 1
loadTitle.Text                  = "⚡ CONTROL HUB"
loadTitle.TextColor3            = Color3.fromRGB(255, 255, 255)
loadTitle.Font                  = Enum.Font.GothamBold
loadTitle.TextSize              = 16
loadTitle.Parent                = loadingFrame

local loadSub = Instance.new("TextLabel")
loadSub.Size                  = UDim2.new(1, 0, 0, 20)
loadSub.Position              = UDim2.new(0, 0, 0, 52)
loadSub.BackgroundTransparency = 1
loadSub.Text                  = "Carregando..."
loadSub.TextColor3            = Color3.fromRGB(140, 140, 160)
loadSub.Font                  = Enum.Font.Gotham
loadSub.TextSize              = 12
loadSub.Parent                = loadingFrame

local barBg = Instance.new("Frame")
barBg.Size             = UDim2.new(0, 240, 0, 8)
barBg.Position         = UDim2.new(0.5, -120, 0, 95)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
barBg.BorderSizePixel  = 0
barBg.Parent           = loadingFrame

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(1, 0)
barBgCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size             = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barFill.BorderSizePixel  = 0
barFill.Parent           = barBg

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

-- ─────────────────────────────────────────────
-- MAIN PANEL
-- ─────────────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name             = "MainFrame"
mainFrame.Size             = UDim2.new(0, 380, 0, 310)
mainFrame.Position         = UDim2.new(0.5, -190, 0.5, -155)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel  = 0
mainFrame.Visible          = false
mainFrame.Parent           = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color        = Color3.fromRGB(45, 45, 60)
mainStroke.Thickness    = 1
mainStroke.Transparency = 0.3
mainStroke.Parent       = mainFrame

makeDraggable(mainFrame)

-- Header
local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
header.BorderSizePixel  = 0
header.Parent           = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

-- fix bottom corners of header so they don't stick out
local headerFix = Instance.new("Frame")
headerFix.Size             = UDim2.new(1, 0, 0, 14)
headerFix.Position         = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
headerFix.BorderSizePixel  = 0
headerFix.Parent           = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size                  = UDim2.new(0, 220, 1, 0)
titleLabel.Position              = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                  = "⚡ CONTROL HUB"
titleLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.TextSize              = 14
titleLabel.TextXAlignment        = Enum.TextXAlignment.Left
titleLabel.Parent                = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size                  = UDim2.new(0, 32, 0, 32)
closeBtn.Position              = UDim2.new(1, -38, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text                  = "✕"
closeBtn.TextColor3            = Color3.fromRGB(160, 160, 175)
closeBtn.Font                  = Enum.Font.GothamBold
closeBtn.TextSize              = 15
closeBtn.Parent                = header

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size                  = UDim2.new(1, -24, 0, 34)
tabBar.Position              = UDim2.new(0, 12, 0, 50)
tabBar.BackgroundTransparency = 1
tabBar.Parent                = mainFrame

local function createTab(text, x)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 110, 1, 0)
    btn.Position         = UDim2.new(0, x, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    btn.BorderSizePixel  = 0
    btn.Text             = text
    btn.TextColor3       = Color3.fromRGB(170, 170, 185)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.Parent           = tabBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    return btn
end

local tabVehicle  = createTab("🚗  Veículo", 0)
local tabSettings = createTab("⚙️  Ajustes", 120)

-- highlight helper
local function setActiveTab(active, inactive)
    active.BackgroundColor3   = Color3.fromRGB(0, 140, 230)
    active.TextColor3         = Color3.fromRGB(255, 255, 255)
    inactive.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    inactive.TextColor3       = Color3.fromRGB(170, 170, 185)
end
setActiveTab(tabVehicle, tabSettings)

-- Pages
local pages = Instance.new("Folder")
pages.Name   = "Pages"
pages.Parent = mainFrame

local function createPage(name)
    local p = Instance.new("Frame")
    p.Name                  = name
    p.Size                  = UDim2.new(1, -24, 0, 200)
    p.Position              = UDim2.new(0, 12, 0, 95)
    p.BackgroundTransparency = 1
    p.Visible               = false
    p.Parent                = pages
    return p
end

local pageVehicle  = createPage("VehiclePage")
local pageSettings = createPage("SettingsPage")
pageVehicle.Visible = true

-- ─────────────────────────────────────────────
-- VEHICLE PAGE
-- ─────────────────────────────────────────────
local function createSliderRow(parent, labelText, defaultVal, y, minV, maxV)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 52)
    row.Position         = UDim2.new(0, 0, 0, y)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    row.BorderSizePixel  = 0
    row.Parent           = parent

    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent = row

    local label = Instance.new("TextLabel")
    label.Size                  = UDim2.new(0.6, 0, 0, 22)
    label.Position              = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text                  = labelText
    label.TextColor3            = Color3.fromRGB(210, 210, 225)
    label.Font                  = Enum.Font.Gotham
    label.TextSize              = 12
    label.TextXAlignment        = Enum.TextXAlignment.Left
    label.Parent                = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size                  = UDim2.new(0.35, 0, 0, 22)
    valueLabel.Position              = UDim2.new(0.62, 0, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text                  = tostring(defaultVal)
    valueLabel.TextColor3            = Color3.fromRGB(0, 180, 255)
    valueLabel.Font                  = Enum.Font.GothamBold
    valueLabel.TextSize              = 13
    valueLabel.TextXAlignment        = Enum.TextXAlignment.Right
    valueLabel.Parent                = row

    -- simple textbox instead of real slider (more reliable)
    local box = Instance.new("TextBox")
    box.Size             = UDim2.new(1, -24, 0, 22)
    box.Position         = UDim2.new(0, 12, 0, 26)
    box.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
    box.BorderSizePixel  = 0
    box.Text             = tostring(defaultVal)
    box.TextColor3       = Color3.fromRGB(255, 255, 255)
    box.Font             = Enum.Font.GothamBold
    box.TextSize         = 12
    box.ClearTextOnFocus = false
    box.Parent           = row

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = box

    return box, valueLabel
end

local jumpBox, jumpValLabel = createSliderRow(pageVehicle, "Poder do Pulo (Jump)", JUMP_FORCE, 0, 1000, 50000)
local nitroBox, nitroValLabel = createSliderRow(pageVehicle, "Força do Nitro (Boost)", BOOST_FORCE, 60, 5000, 100000)

local jumpActionBtn = Instance.new("TextButton")
jumpActionBtn.Size             = UDim2.new(1, 0, 0, 40)
jumpActionBtn.Position         = UDim2.new(0, 0, 0, 128)
jumpActionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
jumpActionBtn.BorderSizePixel  = 0
jumpActionBtn.Text             = "🦘  PULAR AGORA"
jumpActionBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
jumpActionBtn.Font             = Enum.Font.GothamBold
jumpActionBtn.TextSize         = 13
jumpActionBtn.Parent           = pageVehicle

local jabc = Instance.new("UICorner")
jabc.CornerRadius = UDim.new(0, 8)
jabc.Parent = jumpActionBtn

local resetBtn = Instance.new("TextButton")
resetBtn.Size             = UDim2.new(1, 0, 0, 32)
resetBtn.Position         = UDim2.new(0, 0, 0, 176)
resetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
resetBtn.BorderSizePixel  = 0
resetBtn.Text             = "↺  Resetar Valores"
resetBtn.TextColor3       = Color3.fromRGB(180, 180, 195)
resetBtn.Font             = Enum.Font.Gotham
resetBtn.TextSize         = 12
resetBtn.Parent           = pageVehicle

local rbc = Instance.new("UICorner")
rbc.CornerRadius = UDim.new(0, 8)
rbc.Parent = resetBtn

-- ─────────────────────────────────────────────
-- SETTINGS PAGE
-- ─────────────────────────────────────────────
local keybindRow = Instance.new("Frame")
keybindRow.Size             = UDim2.new(1, 0, 0, 50)
keybindRow.Position         = UDim2.new(0, 0, 0, 0)
keybindRow.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
keybindRow.BorderSizePixel  = 0
keybindRow.Parent           = pageSettings

local krc = Instance.new("UICorner")
krc.CornerRadius = UDim.new(0, 8)
krc.Parent = keybindRow

local kbLabel = Instance.new("TextLabel")
kbLabel.Size                  = UDim2.new(0.55, 0, 1, 0)
kbLabel.Position              = UDim2.new(0, 14, 0, 0)
kbLabel.BackgroundTransparency = 1
kbLabel.Text                  = "Tecla do Menu (PC)"
kbLabel.TextColor3            = Color3.fromRGB(210, 210, 225)
kbLabel.Font                  = Enum.Font.Gotham
kbLabel.TextSize              = 12
kbLabel.TextXAlignment        = Enum.TextXAlignment.Left
kbLabel.Parent                = keybindRow

local keybindBtn = Instance.new("TextButton")
keybindBtn.Size             = UDim2.new(0, 100, 0, 30)
keybindBtn.Position         = UDim2.new(1, -114, 0.5, -15)
keybindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
keybindBtn.BorderSizePixel  = 0
keybindBtn.Text             = menuKey.Name
keybindBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
keybindBtn.Font             = Enum.Font.GothamBold
keybindBtn.TextSize         = 12
keybindBtn.Parent           = keybindRow

local kbc = Instance.new("UICorner")
kbc.CornerRadius = UDim.new(0, 6)
kbc.Parent = keybindBtn

local infoLabel = Instance.new("TextLabel")
infoLabel.Size                  = UDim2.new(1, 0, 0, 80)
infoLabel.Position              = UDim2.new(0, 0, 0, 65)
infoLabel.BackgroundTransparency = 1
infoLabel.Text                  = "• Segure Left Shift (ou botão ⚡ no mobile)\n  para ativar o Nitro enquanto estiver no veículo.\n\n• Clique em “Pular Agora” ou no botão 🦘\n  para aplicar impulso vertical."
infoLabel.TextColor3            = Color3.fromRGB(130, 130, 150)
infoLabel.Font                  = Enum.Font.Gotham
infoLabel.TextSize              = 11
infoLabel.TextXAlignment        = Enum.TextXAlignment.Left
infoLabel.TextYAlignment        = Enum.TextYAlignment.Top
infoLabel.Parent                = pageSettings

-- ─────────────────────────────────────────────
-- MOBILE CONTROLS
-- ─────────────────────────────────────────────
local mobileFrame = Instance.new("Frame")
mobileFrame.Name                  = "MobileControls"
mobileFrame.Size                  = UDim2.new(0, 130, 0, 60)
mobileFrame.Position              = UDim2.new(0.78, 0, 0.68, 0)
mobileFrame.BackgroundTransparency = 1
mobileFrame.Visible               = isMobile
mobileFrame.Parent                = screenGui

local mobileJumpBtn = Instance.new("TextButton")
mobileJumpBtn.Size             = UDim2.new(0, 54, 0, 54)
mobileJumpBtn.Position         = UDim2.new(0, 0, 0, 0)
mobileJumpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
mobileJumpBtn.Text             = "🦘"
mobileJumpBtn.TextSize         = 22
mobileJumpBtn.Parent           = mobileFrame

local mjc = Instance.new("UICorner")
mjc.CornerRadius = UDim.new(1, 0)
mjc.Parent = mobileJumpBtn

local mobileNitroBtn = Instance.new("TextButton")
mobileNitroBtn.Size             = UDim2.new(0, 54, 0, 54)
mobileNitroBtn.Position         = UDim2.new(0, 64, 0, 0)
mobileNitroBtn.BackgroundColor3 = Color3.fromRGB(230, 120, 0)
mobileNitroBtn.Text             = "⚡"
mobileNitroBtn.TextSize         = 22
mobileNitroBtn.Parent           = mobileFrame

local mnc = Instance.new("UICorner")
mnc.CornerRadius = UDim.new(1, 0)
mnc.Parent = mobileNitroBtn

local mobileToggle = Instance.new("TextButton")
mobileToggle.Size             = UDim2.new(0, 40, 0, 40)
mobileToggle.Position         = UDim2.new(0.02, 0, 0.18, 0)
mobileToggle.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
mobileToggle.Text             = "⚙️"
mobileToggle.TextSize         = 16
mobileToggle.Visible          = isMobile
mobileToggle.Parent           = screenGui

local mtc = Instance.new("UICorner")
mtc.CornerRadius = UDim.new(0, 10)
mtc.Parent = mobileToggle

-- ─────────────────────────────────────────────
-- 3. VEHICLE LOGIC
-- ─────────────────────────────────────────────
local function stopBoost()
    if boostConnection then
        boostConnection:Disconnect()
        boostConnection = nil
    end
    if activeVectorForce then
        activeVectorForce:Destroy()
        activeVectorForce = nil
    end
    if activeAttachment then
        activeAttachment:Destroy()
        activeAttachment = nil
    end
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
    activeAttachment.Name   = "BoostAttachment"
    activeAttachment.Parent = carAssembly

    activeVectorForce = Instance.new("VectorForce")
    activeVectorForce.Name       = "BoostForce"
    activeVectorForce.Attachment0 = activeAttachment
    activeVectorForce.RelativeTo  = Enum.ActuatorRelativeTo.World
    activeVectorForce.Force       = carAssembly.CFrame.LookVector * BOOST_FORCE
    activeVectorForce.Parent      = carAssembly

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

-- ─────────────────────────────────────────────
-- 4. CONNECTIONS
-- ─────────────────────────────────────────────
jumpBox.FocusLost:Connect(function()
    local v = tonumber(jumpBox.Text)
    if v then
        JUMP_FORCE = math.clamp(v, 1000, 100000)
        jumpBox.Text = tostring(JUMP_FORCE)
        jumpValLabel.Text = tostring(JUMP_FORCE)
    else
        jumpBox.Text = tostring(JUMP_FORCE)
    end
end)

nitroBox.FocusLost:Connect(function()
    local v = tonumber(nitroBox.Text)
    if v then
        BOOST_FORCE = math.clamp(v, 1000, 200000)
        nitroBox.Text = tostring(BOOST_FORCE)
        nitroValLabel.Text = tostring(BOOST_FORCE)
    else
        nitroBox.Text = tostring(BOOST_FORCE)
    end
end)

resetBtn.MouseButton1Click:Connect(function()
    JUMP_FORCE  = 8000
    BOOST_FORCE = 25000
    jumpBox.Text  = "8000"
    nitroBox.Text = "25000"
    jumpValLabel.Text  = "8000"
    nitroValLabel.Text = "25000"
end)

tabVehicle.MouseButton1Click:Connect(function()
    pageVehicle.Visible  = true
    pageSettings.Visible = false
    setActiveTab(tabVehicle, tabSettings)
end)

tabSettings.MouseButton1Click:Connect(function()
    pageVehicle.Visible  = false
    pageSettings.Visible = true
    setActiveTab(tabSettings, tabVehicle)
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

mobileToggle.MouseButton1Click:Connect(function()
    isMenuOpen = not isMenuOpen
    mainFrame.Visible = isMenuOpen
end)

keybindBtn.MouseButton1Click:Connect(function()
    isBindingKey = true
    keybindBtn.Text = "..."
    keybindBtn.BackgroundColor3 = Color3.fromRGB(200, 110, 0)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBindingKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            menuKey = input.KeyCode
            keybindBtn.Text = menuKey.Name
            keybindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
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

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        isShiftPressed = false
        stopBoost()
    end
end)

-- ─────────────────────────────────────────────
-- 5. LOADING — guaranteed exit
-- ─────────────────────────────────────────────
task.spawn(function()
    -- animate bar
    local tween = TweenService:Create(
        barFill,
        TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(1, 0, 1, 0)}
    )
    tween:Play()

    -- hard wait + safety destroy
    task.wait(1.8)

    if loadingFrame and loadingFrame.Parent then
        loadingFrame:Destroy()
    end

    mainFrame.Visible = true
    isMenuOpen = true
end)
