--[[
    ⚡ CONTROL HUB
    Nitro e Pulo separados + botões arrastáveis + keybinds
]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
-- CLEANUP
-- ─────────────────────────────────────────────
pcall(function()
    local old = playerGui:FindFirstChild("CustomControlHub")
    if old then old:Destroy() end
end)

-- ─────────────────────────────────────────────
-- CONFIG
-- ─────────────────────────────────────────────
local menuKey      = Enum.KeyCode.J
local nitroKey     = Enum.KeyCode.LeftShift
local jumpKey      = Enum.KeyCode.Space

local isMenuOpen   = true
local isBindingKey = false
local bindingType  = nil

local BOOST_FORCE  = 25000
local JUMP_FORCE   = 2000

local isBoosting   = false
local boostConn    = nil
local activeForce  = nil
local activeAtt    = nil

local nitroBtnExists = false
local jumpBtnExists  = false

-- ─────────────────────────────────────────────
-- DRAG HELPER
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
-- SCREEN GUI
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
mainFrame.Size             = UDim2.new(0, 400, 0, 340)
mainFrame.Position         = UDim2.new(0.5, -200, 0.5, -170)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
mainFrame.BorderSizePixel  = 0
mainFrame.Visible          = true
mainFrame.Parent           = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 60)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

makeDraggable(mainFrame)

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 220, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ CONTROL HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(160, 160, 175)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 15
closeBtn.Parent = header

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 34)
tabBar.Position = UDim2.new(0, 10, 0, 50)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local function createTab(text, x, w)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w or 90, 1, 0)
    btn.Position = UDim2.new(0, x, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(170, 170, 185)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local tabNitro    = createTab("⚡ Nitro", 0, 100)
local tabJump     = createTab("🦘 Pulo", 110, 100)
local tabSettings = createTab("⚙️ Ajustes", 220, 100)

local function setActiveTab(active, ...)
    local others = {...}
    active.BackgroundColor3 = Color3.fromRGB(0, 140, 230)
    active.TextColor3 = Color3.fromRGB(255, 255, 255)
    for _, t in ipairs(others) do
        t.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        t.TextColor3 = Color3.fromRGB(170, 170, 185)
    end
end
setActiveTab(tabNitro, tabJump, tabSettings)

-- Pages
local pages = Instance.new("Folder")
pages.Name = "Pages"
pages.Parent = mainFrame

local function createPage(name)
    local p = Instance.new("Frame")
    p.Name = name
    p.Size = UDim2.new(1, -20, 0, 230)
    p.Position = UDim2.new(0, 10, 0, 95)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = pages
    return p
end

local pageNitro    = createPage("NitroPage")
local pageJump     = createPage("JumpPage")
local pageSettings = createPage("SettingsPage")
pageNitro.Visible = true

-- ─────────────────────────────────────────────
-- HELPERS UI
-- ─────────────────────────────────────────────
local function createSection(parent, title, y)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.Position = UDim2.new(0, 0, 0, y)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(0, 180, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
end

local function createPowerRow(parent, labelText, defaultVal, y)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 48)
    row.Position = UDim2.new(0, 0, 0, y)
    row.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    row.BorderSizePixel = 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 215)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.55, 0, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultVal)
    valueLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -24, 0, 20)
    box.Position = UDim2.new(0, 12, 0, 24)
    box.BackgroundColor3 = Color3.fromRGB(34, 34, 46)
    box.BorderSizePixel = 0
    box.Text = tostring(defaultVal)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    return box, valueLabel
end

local function createActionBtn(parent, text, y, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = color or Color3.fromRGB(0, 140, 220)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = true
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

-- ─────────────────────────────────────────────
-- NITRO PAGE
-- ─────────────────────────────────────────────
createSection(pageNitro, "⚡  NITRO", 0)

local nitroBox, nitroValLabel = createPowerRow(pageNitro, "Força do Nitro (100 - 1M)", BOOST_FORCE, 30)

local createNitroBtn = createActionBtn(pageNitro, "📌  Criar Botão de Nitro (arrastável)", 90, Color3.fromRGB(230, 120, 0))
local bindNitroBtn   = createActionBtn(pageNitro, "⌨️  Definir Tecla do Nitro  [" .. nitroKey.Name .. "]", 135, Color3.fromRGB(50, 50, 70))

local nitroStatus = Instance.new("TextLabel")
nitroStatus.Size = UDim2.new(1, 0, 0, 20)
nitroStatus.Position = UDim2.new(0, 0, 0, 185)
nitroStatus.BackgroundTransparency = 1
nitroStatus.Text = "Status: Pronto"
nitroStatus.TextColor3 = Color3.fromRGB(100, 200, 120)
nitroStatus.Font = Enum.Font.Gotham
nitroStatus.TextSize = 11
nitroStatus.Parent = pageNitro

-- ─────────────────────────────────────────────
-- JUMP PAGE
-- ─────────────────────────────────────────────
createSection(pageJump, "🦘  PULO", 0)

local jumpBox, jumpValLabel = createPowerRow(pageJump, "Poder do Pulo (0 - 5000)", JUMP_FORCE, 30)

local createJumpBtn = createActionBtn(pageJump, "📌  Criar Botão de Pulo (arrastável)", 90, Color3.fromRGB(0, 150, 220))
local bindJumpBtn   = createActionBtn(pageJump, "⌨️  Definir Tecla do Pulo  [" .. jumpKey.Name .. "]", 135, Color3.fromRGB(50, 50, 70))

local jumpStatus = Instance.new("TextLabel")
jumpStatus.Size = UDim2.new(1, 0, 0, 20)
jumpStatus.Position = UDim2.new(0, 0, 0, 185)
jumpStatus.BackgroundTransparency = 1
jumpStatus.Text = "Status: Pronto"
jumpStatus.TextColor3 = Color3.fromRGB(100, 200, 120)
jumpStatus.Font = Enum.Font.Gotham
jumpStatus.TextSize = 11
jumpStatus.Parent = pageJump

-- ─────────────────────────────────────────────
-- SETTINGS PAGE
-- ─────────────────────────────────────────────
local keybindRow = Instance.new("Frame")
keybindRow.Size = UDim2.new(1, 0, 0, 50)
keybindRow.Position = UDim2.new(0, 0, 0, 0)
keybindRow.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
keybindRow.BorderSizePixel = 0
keybindRow.Parent = pageSettings
Instance.new("UICorner", keybindRow).CornerRadius = UDim.new(0, 8)

local kbLabel = Instance.new("TextLabel")
kbLabel.Size = UDim2.new(0.55, 0, 1, 0)
kbLabel.Position = UDim2.new(0, 14, 0, 0)
kbLabel.BackgroundTransparency = 1
kbLabel.Text = "Tecla do Menu"
kbLabel.TextColor3 = Color3.fromRGB(200, 200, 215)
kbLabel.Font = Enum.Font.Gotham
kbLabel.TextSize = 12
kbLabel.TextXAlignment = Enum.TextXAlignment.Left
kbLabel.Parent = keybindRow

local menuKeyBtn = Instance.new("TextButton")
menuKeyBtn.Size = UDim2.new(0, 110, 0, 30)
menuKeyBtn.Position = UDim2.new(1, -124, 0.5, -15)
menuKeyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
menuKeyBtn.BorderSizePixel = 0
menuKeyBtn.Text = menuKey.Name
menuKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuKeyBtn.Font = Enum.Font.GothamBold
menuKeyBtn.TextSize = 12
menuKeyBtn.Parent = keybindRow
Instance.new("UICorner", menuKeyBtn).CornerRadius = UDim.new(0, 6)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 120)
infoLabel.Position = UDim2.new(0, 0, 0, 65)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "• Nitro e Pulo funcionam apenas\n  quando você estiver sentado no veículo.\n\n• Crie botões arrastáveis e posicione\n  onde quiser na tela.\n\n• Defina teclas personalizadas para\n  Nitro e Pulo.\n\n• Tecla padrão do menu: J"
infoLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = pageSettings

-- ─────────────────────────────────────────────
-- MOBILE TOGGLE
-- ─────────────────────────────────────────────
local mobileToggle = Instance.new("TextButton")
mobileToggle.Name = "MobileToggle"
mobileToggle.Size = UDim2.new(0, 44, 0, 44)
mobileToggle.Position = UDim2.new(0, 12, 0.5, -100)
mobileToggle.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
mobileToggle.Text = "⚙️"
mobileToggle.TextSize = 18
mobileToggle.AutoButtonColor = true
mobileToggle.Parent = screenGui
Instance.new("UICorner", mobileToggle).CornerRadius = UDim.new(0, 10)

makeDraggable(mobileToggle)   -- ← adiciona essa linha

-- ─────────────────────────────────────────────
-- VEHICLE HELPERS
-- ─────────────────────────────────────────────
local function getVehicleRoot()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    local seat = hum.SeatPart
    if not (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then return nil end
    return seat.AssemblyRootPart or seat
end

local function stopBoost()
    isBoosting = false
    if boostConn then
        boostConn:Disconnect()
        boostConn = nil
    end
    if activeForce then pcall(function() activeForce:Destroy() end) activeForce = nil end
    if activeAtt then pcall(function() activeAtt:Destroy() end) activeAtt = nil end
    nitroStatus.Text = "Status: Pronto"
    nitroStatus.TextColor3 = Color3.fromRGB(100, 200, 120)
end

local function startBoost()
    stopBoost()
    local root = getVehicleRoot()
    if not root then
        nitroStatus.Text = "Status: Entre no veículo!"
        nitroStatus.TextColor3 = Color3.fromRGB(255, 120, 80)
        return
    end

    for _, c in ipairs(root:GetChildren()) do
        if c.Name == "HubBoostForce" or c.Name == "HubBoostAtt" then
            pcall(function() c:Destroy() end)
        end
    end

    activeAtt = Instance.new("Attachment")
    activeAtt.Name = "HubBoostAtt"
    activeAtt.Parent = root

    activeForce = Instance.new("VectorForce")
    activeForce.Name = "HubBoostForce"
    activeForce.Attachment0 = activeAtt
    activeForce.RelativeTo = Enum.ActuatorRelativeTo.World
    activeForce.Force = root.CFrame.LookVector * BOOST_FORCE
    activeForce.ApplyAtCenterOfMass = true
    activeForce.Parent = root

    isBoosting = true
    nitroStatus.Text = "Status: NITRO ATIVO ⚡"
    nitroStatus.TextColor3 = Color3.fromRGB(255, 180, 50)

    boostConn = RunService.Heartbeat:Connect(function()
        if not isBoosting then stopBoost() return end
        local r = getVehicleRoot()
        if not r or not activeForce then stopBoost() return end
        activeForce.Force = r.CFrame.LookVector * BOOST_FORCE
    end)
end

local function applyJump()
    local root = getVehicleRoot()
    if not root then
        jumpStatus.Text = "Status: Entre no veículo!"
        jumpStatus.TextColor3 = Color3.fromRGB(255, 120, 80)
        return
    end
    root:ApplyImpulse(Vector3.new(0, JUMP_FORCE * 80, 0))
    jumpStatus.Text = "Status: Pulo aplicado!"
    jumpStatus.TextColor3 = Color3.fromRGB(80, 180, 255)
    task.delay(1, function()
        jumpStatus.Text = "Status: Pronto"
        jumpStatus.TextColor3 = Color3.fromRGB(100, 200, 120)
    end)
end

-- ─────────────────────────────────────────────
-- CREATE FLOATING BUTTONS
-- ─────────────────────────────────────────────
local function createFloatingButton(name, text, color, callback, isHold)
    local old = screenGui:FindFirstChild(name)
    if old then old:Destroy() end

    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = UDim2.new(0.85, 0, 0.7, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextSize = 24
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = screenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.6
    stroke.Parent = btn

    makeDraggable(btn)

    if isHold then
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                callback(true)
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                callback(false)
            end
        end)
        btn.MouseButton1Down:Connect(function() callback(true) end)
        btn.MouseButton1Up:Connect(function() callback(false) end)
    else
        btn.Activated:Connect(function() callback() end)
        btn.MouseButton1Click:Connect(function() callback() end)
    end

    return btn
end

-- ─────────────────────────────────────────────
-- CONNECTIONS
-- ─────────────────────────────────────────────

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

-- Create floating buttons
createNitroBtn.MouseButton1Click:Connect(function()
    if nitroBtnExists then
        local old = screenGui:FindFirstChild("FloatingNitro")
        if old then old:Destroy() end
        nitroBtnExists = false
        createNitroBtn.Text = "📌  Criar Botão de Nitro (arrastável)"
        return
    end
    createFloatingButton("FloatingNitro", "⚡", Color3.fromRGB(230, 120, 0), function(state)
        if state then startBoost() else stopBoost() end
    end, true)
    nitroBtnExists = true
    createNitroBtn.Text = "🗑️  Remover Botão de Nitro"
end)

createJumpBtn.MouseButton1Click:Connect(function()
    if jumpBtnExists then
        local old = screenGui:FindFirstChild("FloatingJump")
        if old then old:Destroy() end
        jumpBtnExists = false
        createJumpBtn.Text = "📌  Criar Botão de Pulo (arrastável)"
        return
    end
    createFloatingButton("FloatingJump", "🦘", Color3.fromRGB(0, 150, 220), function()
        applyJump()
    end, false)
    jumpBtnExists = true
    createJumpBtn.Text = "🗑️  Remover Botão de Pulo"
end)

-- Keybinds
local function startBinding(tipo, btn)
    isBindingKey = true
    bindingType = tipo
    btn.Text = "Pressione uma tecla..."
    btn.BackgroundColor3 = Color3.fromRGB(200, 110, 0)
end

bindNitroBtn.MouseButton1Click:Connect(function()
    startBinding("nitro", bindNitroBtn)
end)

bindJumpBtn.MouseButton1Click:Connect(function()
    startBinding("jump", bindJumpBtn)
end)

menuKeyBtn.MouseButton1Click:Connect(function()
    startBinding("menu", menuKeyBtn)
end)

-- Tabs
tabNitro.MouseButton1Click:Connect(function()
    pageNitro.Visible = true
    pageJump.Visible = false
    pageSettings.Visible = false
    setActiveTab(tabNitro, tabJump, tabSettings)
end)

tabJump.MouseButton1Click:Connect(function()
    pageNitro.Visible = false
    pageJump.Visible = true
    pageSettings.Visible = false
    setActiveTab(tabJump, tabNitro, tabSettings)
end)

tabSettings.MouseButton1Click:Connect(function()
    pageNitro.Visible = false
    pageJump.Visible = false
    pageSettings.Visible = true
    setActiveTab(tabSettings, tabNitro, tabJump)
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

-- Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBindingKey and input.UserInputType == Enum.UserInputType.Keyboard then
        if bindingType == "nitro" then
            nitroKey = input.KeyCode
            bindNitroBtn.Text = "⌨️  Definir Tecla do Nitro  [" .. nitroKey.Name .. "]"
            bindNitroBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        elseif bindingType == "jump" then
            jumpKey = input.KeyCode
            bindJumpBtn.Text = "⌨️  Definir Tecla do Pulo  [" .. jumpKey.Name .. "]"
            bindJumpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        elseif bindingType == "menu" then
            menuKey = input.KeyCode
            menuKeyBtn.Text = menuKey.Name
            menuKeyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        end
        isBindingKey = false
        bindingType = nil
        return
    end

    if gameProcessed then return end

    if input.KeyCode == menuKey then
        isMenuOpen = not isMenuOpen
        mainFrame.Visible = isMenuOpen
    end

    if input.KeyCode == nitroKey then
        startBoost()
    end

    if input.KeyCode == jumpKey then
        applyJump()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == nitroKey then
        stopBoost()
    end
end)

mainFrame.Visible = true
isMenuOpen = true
