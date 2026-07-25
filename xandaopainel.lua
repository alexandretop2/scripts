--[[
    ⚡ CONTROL HUB
    Nitro | Pulo | Pneu | Ajustes
]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    local old = playerGui:FindFirstChild("CustomControlHub")
    if old then old:Destroy() end
end)

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

local MATERIALS = {
    Enum.Material.Plastic,
    Enum.Material.SmoothPlastic,
    Enum.Material.Neon,
    Enum.Material.ForceField,
    Enum.Material.Glass,
    Enum.Material.Metal,
    Enum.Material.DiamondPlate,
    Enum.Material.CorrodedMetal,
    Enum.Material.Foil,
    Enum.Material.Wood,
    Enum.Material.WoodPlanks,
    Enum.Material.Marble,
    Enum.Material.Slate,
    Enum.Material.Concrete,
    Enum.Material.Granite,
    Enum.Material.Brick,
    Enum.Material.Pebble,
    Enum.Material.Cobblestone,
    Enum.Material.Rock,
    Enum.Material.Sandstone,
    Enum.Material.Basalt,
    Enum.Material.CrackedLava,
    Enum.Material.Limestone,
    Enum.Material.Pavement,
    Enum.Material.Grass,
    Enum.Material.LeafyGrass,
    Enum.Material.Sand,
    Enum.Material.Fabric,
    Enum.Material.Ice,
    Enum.Material.Glacier,
    Enum.Material.Snow,
    Enum.Material.Mud,
    Enum.Material.Ground,
    Enum.Material.Asphalt,
    Enum.Material.Salt,
    Enum.Material.Cardboard,
    Enum.Material.Carpet,
    Enum.Material.CeramicTiles,
    Enum.Material.ClayRoofTiles,
    Enum.Material.Plaster,
    Enum.Material.Rubber,
    Enum.Material.RoofShingles,
}
local materialIndex = 1

local function makeDraggable(guiObject)
    local dragging, dragStart, startPos, moved

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            moved     = false
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
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                moved = true
                guiObject.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "CustomControlHub"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name             = "MainFrame"
mainFrame.Size             = UDim2.new(0, 420, 0, 360)
mainFrame.Position         = UDim2.new(0.5, -210, 0.5, -180)
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

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 34)
tabBar.Position = UDim2.new(0, 8, 0, 50)
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
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local tabNitro    = createTab("⚡ Nitro", 0, 95)
local tabJump     = createTab("🦘 Pulo", 100, 95)
local tabPneu     = createTab("🛞 Pneu", 200, 95)
local tabSettings = createTab("⚙️ Ajustes", 300, 100)

local function setActiveTab(active, ...)
    active.BackgroundColor3 = Color3.fromRGB(0, 140, 230)
    active.TextColor3 = Color3.fromRGB(255, 255, 255)
    for _, t in ipairs({...}) do
        t.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        t.TextColor3 = Color3.fromRGB(170, 170, 185)
    end
end
setActiveTab(tabNitro, tabJump, tabPneu, tabSettings)

local pages = Instance.new("Folder")
pages.Name = "Pages"
pages.Parent = mainFrame

local function createPage(name)
    local p = Instance.new("Frame")
    p.Name = name
    p.Size = UDim2.new(1, -20, 0, 250)
    p.Position = UDim2.new(0, 10, 0, 95)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = pages
    return p
end

local pageNitro    = createPage("NitroPage")
local pageJump     = createPage("JumpPage")
local pagePneu     = createPage("PneuPage")
local pageSettings = createPage("SettingsPage")
pageNitro.Visible = true

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

-- NITRO
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

-- JUMP
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

-- PNEU
createSection(pagePneu, "🛞  MATERIAL DO PNEU", 0)

local selectorRow = Instance.new("Frame")
selectorRow.Size = UDim2.new(1, 0, 0, 50)
selectorRow.Position = UDim2.new(0, 0, 0, 40)
selectorRow.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
selectorRow.BorderSizePixel = 0
selectorRow.Parent = pagePneu
Instance.new("UICorner", selectorRow).CornerRadius = UDim.new(0, 10)

local leftArrow = Instance.new("TextButton")
leftArrow.Size = UDim2.new(0, 44, 0, 36)
leftArrow.Position = UDim2.new(0, 8, 0.5, -18)
leftArrow.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
leftArrow.BorderSizePixel = 0
leftArrow.Text = "◀"
leftArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
leftArrow.Font = Enum.Font.GothamBold
leftArrow.TextSize = 16
leftArrow.AutoButtonColor = true
leftArrow.Parent = selectorRow
Instance.new("UICorner", leftArrow).CornerRadius = UDim.new(0, 8)

local rightArrow = Instance.new("TextButton")
rightArrow.Size = UDim2.new(0, 44, 0, 36)
rightArrow.Position = UDim2.new(1, -52, 0.5, -18)
rightArrow.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
rightArrow.BorderSizePixel = 0
rightArrow.Text = "▶"
rightArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
rightArrow.Font = Enum.Font.GothamBold
rightArrow.TextSize = 16
rightArrow.AutoButtonColor = true
rightArrow.Parent = selectorRow
Instance.new("UICorner", rightArrow).CornerRadius = UDim.new(0, 8)

local materialLabel = Instance.new("TextLabel")
materialLabel.Size = UDim2.new(1, -120, 1, 0)
materialLabel.Position = UDim2.new(0, 60, 0, 0)
materialLabel.BackgroundTransparency = 1
materialLabel.Text = MATERIALS[materialIndex].Name
materialLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
materialLabel.Font = Enum.Font.GothamBold
materialLabel.TextSize = 15
materialLabel.Parent = selectorRow

local applyBtn = createActionBtn(pagePneu, "✅  Aplicar Material nas Rodas", 105, Color3.fromRGB(0, 160, 100))

local pneuStatus = Instance.new("TextLabel")
pneuStatus.Size = UDim2.new(1, 0, 0, 40)
pneuStatus.Position = UDim2.new(0, 0, 0, 155)
pneuStatus.BackgroundTransparency = 1
pneuStatus.Text = "Procura: FR / FL / RR / RL → Wheel\nEntre no veículo e clique Aplicar."
pneuStatus.TextColor3 = Color3.fromRGB(130, 130, 150)
pneuStatus.Font = Enum.Font.Gotham
pneuStatus.TextSize = 11
pneuStatus.TextXAlignment = Enum.TextXAlignment.Left
pneuStatus.TextYAlignment = Enum.TextYAlignment.Top
pneuStatus.Parent = pagePneu

local pneuInfo = Instance.new("TextLabel")
pneuInfo.Size = UDim2.new(1, 0, 0, 30)
pneuInfo.Position = UDim2.new(0, 0, 0, 210)
pneuInfo.BackgroundTransparency = 1
pneuInfo.Text = "Total de materiais: " .. #MATERIALS
pneuInfo.TextColor3 = Color3.fromRGB(100, 100, 120)
pneuInfo.Font = Enum.Font.Gotham
pneuInfo.TextSize = 11
pneuInfo.Parent = pagePneu

-- SETTINGS
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
infoLabel.Size = UDim2.new(1, 0, 0, 140)
infoLabel.Position = UDim2.new(0, 0, 0, 65)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "• Nitro e Pulo: precisa estar sentado no veículo.\n\n• Pneu: muda o Material das partes\n  Wheel dentro de FR / FL / RR / RL.\n\n• Crie botões arrastáveis e defina teclas.\n\n• Tecla padrão do menu: J"
infoLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = pageSettings

-- MOBILE TOGGLE
local mobileToggle = Instance.new("TextButton")
mobileToggle.Name = "MobileToggle"
mobileToggle.Size = UDim2.new(0, 48, 0, 48)
mobileToggle.Position = UDim2.new(0, 15, 0.45, 0)
mobileToggle.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
mobileToggle.Text = "⚙️"
mobileToggle.TextSize = 20
mobileToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
mobileToggle.Font = Enum.Font.GothamBold
mobileToggle.AutoButtonColor = true
mobileToggle.ZIndex = 50
mobileToggle.Parent = screenGui
Instance.new("UICorner", mobileToggle).CornerRadius = UDim.new(0, 12)

local mtStroke = Instance.new("UIStroke")
mtStroke.Color = Color3.fromRGB(0, 140, 230)
mtStroke.Thickness = 1.5
mtStroke.Transparency = 0.4
mtStroke.Parent = mobileToggle

do
    local dragging, moved, dragStart, startPos = false, false, nil, nil

    mobileToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = mobileToggle.Position
        end
    end)

    mobileToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and not moved then
                isMenuOpen = not isMenuOpen
                mainFrame.Visible = isMenuOpen
            end
            dragging = false
            moved = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 6 or math.abs(delta.Y) > 6 then
                moved = true
                mobileToggle.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- VEHICLE
local function getVehicleRoot()
    local char = player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return nil end
    local seat = hum.SeatPart
    if not (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then return nil end
    return seat.AssemblyRootPart or seat
end

local function getCarModel()
    local root = getVehicleRoot()
    if not root then return nil end
    local current = root
    for _ = 1, 8 do
        if not current then break end
        if current:IsA("Model") then
            if current:FindFirstChild("FR") or current:FindFirstChild("FL")
            or current:FindFirstChild("RR") or current:FindFirstChild("RL") then
                return current
            end
        end
        current = current.Parent
    end
    return root:FindFirstAncestorOfClass("Model") or root.Parent
end

local function stopBoost()
    isBoosting = false
    if boostConn then boostConn:Disconnect() boostConn = nil end
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

local function applyWheelMaterial()
    local car = getCarModel()
    if not car then
        pneuStatus.Text = "❌ Entre no veículo primeiro!"
        pneuStatus.TextColor3 = Color3.fromRGB(255, 120, 80)
        return
    end

    local mat = MATERIALS[materialIndex]
    local count = 0
    local names = {"FR", "FL", "RR", "RL"}

    for _, name in ipairs(names) do
        local wheelModel = car:FindFirstChild(name, true)
        if wheelModel then
            local wheelPart = wheelModel:FindFirstChild("Wheel", true)
            if wheelPart and wheelPart:IsA("BasePart") then
                wheelPart.Material = mat
                count = count + 1
            elseif wheelModel:IsA("BasePart") then
                wheelModel.Material = mat
                count = count + 1
            end
        end
    end

    if count == 0 then
        for _, desc in ipairs(car:GetDescendants()) do
            if desc.Name == "Wheel" and desc:IsA("BasePart") then
                desc.Material = mat
                count = count + 1
            end
        end
    end

    if count > 0 then
        pneuStatus.Text = "✅ Material " .. mat.Name .. " aplicado em " .. count .. " roda(s)!"
        pneuStatus.TextColor3 = Color3.fromRGB(100, 220, 140)
    else
        pneuStatus.Text = "❌ Não encontrei FR/FL/RR/RL → Wheel\nVerifique a hierarquia do carro."
        pneuStatus.TextColor3 = Color3.fromRGB(255, 120, 80)
    end
end

local function updateMaterialLabel()
    materialLabel.Text = MATERIALS[materialIndex].Name
end

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

-- CONNECTIONS
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

leftArrow.MouseButton1Click:Connect(function()
    materialIndex = materialIndex - 1
    if materialIndex < 1 then materialIndex = #MATERIALS end
    updateMaterialLabel()
end)

rightArrow.MouseButton1Click:Connect(function()
    materialIndex = materialIndex + 1
    if materialIndex > #MATERIALS then materialIndex = 1 end
    updateMaterialLabel()
end)

applyBtn.MouseButton1Click:Connect(applyWheelMaterial)

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

local function hideAllPages()
    pageNitro.Visible = false
    pageJump.Visible = false
    pagePneu.Visible = false
    pageSettings.Visible = false
end

tabNitro.MouseButton1Click:Connect(function()
    hideAllPages()
    pageNitro.Visible = true
    setActiveTab(tabNitro, tabJump, tabPneu, tabSettings)
end)

tabJump.MouseButton1Click:Connect(function()
    hideAllPages()
    pageJump.Visible = true
    setActiveTab(tabJump, tabNitro, tabPneu, tabSettings)
end)

tabPneu.MouseButton1Click:Connect(function()
    hideAllPages()
    pagePneu.Visible = true
    setActiveTab(tabPneu, tabNitro, tabJump, tabSettings)
end)

tabSettings.MouseButton1Click:Connect(function()
    hideAllPages()
    pageSettings.Visible = true
    setActiveTab(tabSettings, tabNitro, tabJump, tabPneu)
end)

closeBtn.MouseButton1Click:Connect(function()
    isMenuOpen = false
    mainFrame.Visible = false
end)

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
