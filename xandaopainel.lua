--[[
    ⚡ CONTROL HUB  —  Vehicle Nitro + Jump
    Fixed: Shift nitro, mobile buttons, value ranges
]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- 0. CLEANUP
-- ─────────────────────────────────────────────
pcall(function()
    local old = playerGui:FindFirstChild("CustomControlHub")
    if old then old:Destroy() end
end)

-- ─────────────────────────────────────────────
-- 1. CONFIG
-- ─────────────────────────────────────────────
local menuKey        = Enum.KeyCode.J
local isMenuOpen     = true
local isBindingKey   = false
local BOOST_FORCE    = 25000
local JUMP_FORCE     = 2000
local isBoosting     = false
local boostConnection = nil
local activeForce    = nil
local activeAttachment = nil

local isMobile = UserInputService.TouchEnabled

-- ─────────────────────────────────────────────
-- Drag helper
-- ─────────────────────────────────────────────
local function makeDraggable(guiObject)
    local dragging, dragStart, startPos

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = guiObject.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
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
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- ─────────────────────────────────────────────
-- MAIN PANEL
-- ─────────────────────────────────────────────
local mainFrame = Instance.new("Frame")
mainFrame.Name             = "MainFrame"
mainFrame.Size             = UDim2.new(0, 380, 0, 320)
mainFrame.Position         = UDim2.new(0.5, -190, 0.5, -160)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
mainFrame.BorderSizePixel  = 0
mainFrame.Visible          = true
mainFrame.Parent           = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color        = Color3.fromRGB(50, 50, 70)
mainStroke.Thickness    = 1
mainStroke.Transparency = 0.35
mainStroke.Parent       = mainFrame

makeDraggable(mainFrame)

-- Header
local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
header.BorderSizePixel  = 0
header.Parent           = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

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
    btn.AutoButtonColor  = false
    btn.Parent           = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local tabVehicle  = createTab("🚗  Veículo", 0)
local tabSettings = createTab("⚙️  Ajustes", 120)

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
    p.Size                  = UDim2.new(1, -24, 0, 210)
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
local function createInputRow(parent, labelText, defaultVal, y)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 52)
    row.Position         = UDim2.new(0, 0, 0, y)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    row.BorderSizePixel  = 0
    row.Parent           = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

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
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    return box, valueLabel
end

local jumpBox, jumpValLabel   = createInputRow(pageVehicle, "Poder do Pulo (0 - 5000)", JUMP_FORCE, 0)
local nitroBox, nitroValLabel = createInputRow(pageVehicle, "Força do Nitro (100 - 1M)", BOOST_FORCE, 60)

local jumpActionBtn = Instance.new("TextButton")
jumpActionBtn.Size             = UDim2.new(1, 0, 0, 40)
jumpActionBtn.Position         = UDim2.new(0, 0, 0, 128)
jumpActionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
jumpActionBtn.BorderSizePixel  = 0
jumpActionBtn.Text             = "🦘  PULAR AGORA"
jumpActionBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
jumpActionBtn.Font             = Enum.Font.GothamBold
jumpActionBtn.TextSize         = 13
jumpActionBtn.AutoButtonColor  = true
jumpActionBtn.Parent           = pageVehicle
Instance.new("UICorner", jumpActionBtn).CornerRadius = UDim.new(0, 8)

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
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size                  = UDim2.new(1, 0, 0, 18)
statusLabel.Position              = UDim2.new(0, 0, 0, 212)
statusLabel.BackgroundTransparency = 1
statusLabel.Text                  = "Status: Pronto"
statusLabel.TextColor3            = Color3.fromRGB(100, 200, 120)
statusLabel.Font                  = Enum.Font.Gotham
statusLabel.TextSize              = 11
statusLabel.Parent                = pageVehicle

-- ─────────────────────────────────────────────
-- SETTINGS PAGE
-- ─────────────────────────────────────────────
local keybindRow = Instance.new("Frame")
keybindRow.Size             = UDim2.new(1, 0, 0, 50)
keybindRow.Position         = UDim2.new(0, 0, 0, 0)
keybindRow.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
keybindRow.BorderSizePixel  = 0
keybindRow.Parent           = pageSettings
Instance.new("UICorner", keybindRow).CornerRadius = UDim.new(0, 8)

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
Instance.new("UICorner", keybindBtn).CornerRadius = UDim.new(0, 6)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size                  = UDim2.new(1, 0, 0, 100)
infoLabel.Position              = UDim2.new(0, 0, 0, 65)
infoLabel.BackgroundTransparency = 1
infoLabel.Text                  = "• Segure Left Shift (ou botão ⚡)\n  para Nitro (precisa estar sentado no veículo).\n\n• Clique em “Pular Agora” ou 🦘 para pular.\n\n• Tecla padrão do menu: J\n• Arraste o painel pelo header."
infoLabel.TextColor3            = Color3.fromRGB(130, 130, 150)
infoLabel.Font                  = Enum.Font.Gotham
infoLabel.TextSize              = 11
infoLabel.TextXAlignment        = Enum.TextXAlignment.Left
infoLabel.TextYAlignment        = Enum.TextYAlignment.Top
infoLabel.Parent                = pageSettings

-- ─────────────────────────────────────────────
-- MOBILE CONTROLS (sempre visíveis)
-- ─────────────────────────────────────────────
local mobileFrame = Instance.new("Frame")
mobileFrame.Name                  = "MobileControls"
mobileFrame.Size                  = UDim2.new(0, 140, 0, 70)
mobileFrame.Position              = UDim2.new(1, -160, 1, -100)
mobileFrame.BackgroundTransparency = 1
mobileFrame.Visible               = true
mobileFrame.Parent                = screenGui

local mobileJumpBtn = Instance.new("TextButton")
mobileJumpBtn.Name             = "MobileJump"
mobileJumpBtn.Size             = UDim2.new(0, 58, 0, 58)
mobileJumpBtn.Position         = UDim2.new(0, 0, 0, 0)
mobileJumpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
mobileJumpBtn.Text             = "🦘"
mobileJumpBtn.TextSize         = 24
mobileJumpBtn.AutoButtonColor  = true
mobileJumpBtn.Parent           = mobileFrame
Instance.new("UICorner", mobileJumpBtn).CornerRadius = UDim.new(1, 0)

local mobileNitroBtn = Instance.new("TextButton")
mobileNitroBtn.Name             = "MobileNitro"
mobileNitroBtn.Size             = UDim2.new(0, 58, 0, 58)
mobileNitroBtn.Position         = UDim2.new(0, 70, 0, 0)
mobileNitroBtn.BackgroundColor3 = Color3.fromRGB(230, 120, 0)
mobileNitroBtn.Text             = "⚡"
mobileNitroBtn.TextSize         = 24
mobileNitroBtn.AutoButtonColor  = true
mobileNitroBtn.Parent           = mobileFrame
Instance.new("UICorner", mobileNitroBtn).CornerRadius = UDim.new(1, 0)

local mobileToggle = Instance.new("TextButton")
mobileToggle.Name             = "MobileToggle"
mobileToggle.Size             = UDim2.new(0, 44, 0, 44)
mobileToggle.Position         = UDim2.new(0, 12, 0.5, -100)
mobileToggle.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
mobileToggle.Text             = "⚙️"
mobileToggle.TextSize         = 18
mobileToggle.AutoButtonColor  = true
mobileToggle.Parent           = screenGui
Instance.new("UICorner", mobileToggle).CornerRadius = UDim.new(0, 10)

-- ─────────────────────────────────────────────
-- 3. VEHICLE LOGIC (melhorado)
-- ─────────────────────────────────────────────
local function getVehicleRoot()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local seat = hum.SeatPart
    if not seat then return nil end
    -- aceita VehicleSeat ou qualquer Seat
    if not (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then return nil end
    return seat.AssemblyRootPart or seat
end

local function stopBoost()
    isBoosting = false
    if boostConnection then
        boostConnection:Disconnect()
        boostConnection = nil
    end
    if activeForce then
        pcall(function() activeForce:Destroy() end)
        activeForce = nil
    end
    if activeAttachment then
        pcall(function() activeAttachment:Destroy() end)
        activeAttachment = nil
    end
    statusLabel.Text = "Status: Pronto"
    statusLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
    mobileNitroBtn.BackgroundColor3 = Color3.fromRGB(230, 120, 0)
end

local function startBoost()
    stopBoost()

    local root = getVehicleRoot()
    if not root then
        statusLabel.Text = "Status: Entre no veículo primeiro!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 120, 80)
        return
    end

    -- limpa forces antigas
    for _, c in ipairs(root:GetChildren()) do
        if c.Name == "HubBoostForce" or c.Name == "HubBoostAtt" then
            pcall(function() c:Destroy() end)
        end
    end

    activeAttachment = Instance.new("Attachment")
    activeAttachment.Name   = "HubBoostAtt"
    activeAttachment.Parent = root

    -- VectorForce é o mais confiável
    activeForce = Instance.new("VectorForce")
    activeForce.Name        = "HubBoostForce"
    activeForce.Attachment0 = activeAttachment
    activeForce.RelativeTo  = Enum.ActuatorRelativeTo.World
    activeForce.Force       = root.CFrame.LookVector * BOOST_FORCE
    activeForce.ApplyAtCenterOfMass = true
    activeForce.Parent      = root

    isBoosting = true
    statusLabel.Text = "Status: NITRO ATIVO ⚡"
    statusLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
    mobileNitroBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 0)

    boostConnection = RunService.Heartbeat:Connect(function()
        if not isBoosting then
            stopBoost()
            return
        end
        local r = getVehicleRoot()
        if not r or not activeForce then
            stopBoost()
            return
        end
        activeForce.Force = r.CFrame.LookVector * BOOST_FORCE
    end)
end

local function applyJump()
    local root = getVehicleRoot()
    if not root then
        statusLabel.Text = "Status: Entre no veículo primeiro!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 120, 80)
        return
    end

    -- ApplyImpulse direto (multiplicador para ficar bom)
    root:ApplyImpulse(Vector3.new(0, JUMP_FORCE * 80, 0))

    statusLabel.Text = "Status: Pulo aplicado!"
    statusLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
    task.delay(1, function()
        if not isBoosting then
            statusLabel.Text = "Status: Pronto"
            statusLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
        end
    end)
end

-- ─────────────────────────────────────────────
-- 4. CONNECTIONS
-- ─────────────────────────────────────────────
jumpBox.FocusLost:Connect(function()
    local v = tonumber(jumpBox.Text)
    if v then
        JUMP_FORCE = math.clamp(v, 0, 5000)
        jumpBox.Text = tostring(JUMP_FORCE)
        jumpValLabel.Text = tostring(JUMP_FORCE)
    else
        jumpBox.Text = tostring(JUMP_FORCE)
    end
end)

nitroBox.FocusLost:Connect(function()
    local v = tonumber(nitroBox.Text)
    if v then
        BOOST_FORCE = math.clamp(v, 100, 1000000)
        nitroBox.Text = tostring(BOOST_FORCE)
        nitroValLabel.Text = tostring(BOOST_FORCE)
    else
        nitroBox.Text = tostring(BOOST_FORCE)
    end
end)

resetBtn.MouseButton1Click:Connect(function()
    JUMP_FORCE  = 2000
    BOOST_FORCE = 25000
    jumpBox.Text  = "2000"
    nitroBox.Text = "25000"
    jumpValLabel.Text  = "2000"
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

-- PC jump button
jumpActionBtn.MouseButton1Click:Connect(applyJump)

-- Mobile Jump (funciona com toque)
mobileJumpBtn.Activated:Connect(applyJump)
mobileJumpBtn.MouseButton1Click:Connect(applyJump)

-- Mobile Nitro (segurar)
local function onNitroDown()
    startBoost()
end
local function onNitroUp()
    stopBoost()
end

mobileNitroBtn.MouseButton1Down:Connect(onNitroDown)
mobileNitroBtn.MouseButton1Up:Connect(onNitroUp)
mobileNitroBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        onNitroDown()
    end
end)
mobileNitroBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        onNitroUp()
    end
end)

-- Close / Toggle
closeBtn.MouseButton1Click:Connect(function()
    isMenuOpen = false
    mainFrame.Visible = false
end)

mobileToggle.Activated:Connect(function()
    isMenuOpen = not isMenuOpen
    mainFrame.Visible = isMenuOpen
end)
mobileToggle.MouseButton1Click:Connect(function()
    isMenuOpen = not isMenuOpen
    mainFrame.Visible = isMenuOpen
end)

-- Keybind
keybindBtn.MouseButton1Click:Connect(function()
    isBindingKey = true
    keybindBtn.Text = "..."
    keybindBtn.BackgroundColor3 = Color3.fromRGB(200, 110, 0)
end)

-- Keyboard
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

    -- Shift = nitro
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        startBoost()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        stopBoost()
    end
end)

-- Garante visibilidade
mainFrame.Visible = true
isMenuOpen = true
