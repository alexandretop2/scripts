--[[
    ═══════════════════════════════════════════
    ⚡ PAINEL DO XANDÃO
    Nitro • Pulo • Gravidade • Aderência • FOV • Configs
    ───────────────────────────────────────────
    Desenvolvido por: Xandão
    Versão: 1.2 | Público
    ═══════════════════════════════════════════
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    local old = playerGui:FindFirstChild("PainelXandao")
    if old then old:Destroy() end
end)

-- ─────────────────────────────────────────────
-- 1. SETUP
-- ─────────────────────────────────────────────
local menuKey = Enum.KeyCode.J
local nitroKey = Enum.KeyCode.LeftShift
local jumpKey = Enum.KeyCode.LeftControl
local isBindingKey = false
local bindingType = nil

local BOOST_FORCE = 1000
local JUMP_FORCE = 50
local isBoosting = false
local boostConn = nil
local activeForce = nil
local activeAtt = nil

local nitroEnabled = true
local jumpEnabled = false
local nitroEffectEnabled = true
local nitroBtnExists = false
local jumpBtnExists = false
local nitroColor1Hex = "#FF5500"
local nitroColor2Hex = "#FFAA00"

local ORIGINAL_GRAVITY = workspace.Gravity
local currentGravity = workspace.Gravity
local gravityLockConn = nil

local currentFriction = 1.0
local adhesionEnabled = true
local adhesionConn = nil
local originalWheelPhys = {}

local ORIGINAL_FOV = 70
pcall(function()
    if workspace.CurrentCamera then
        ORIGINAL_FOV = workspace.CurrentCamera.FieldOfView
    end
end)
local currentFOV = ORIGINAL_FOV
local fovConn = nil

local menuScale = 1
local importCodeText = ""

local ADHESION_PRESETS = {
    ["Drift"] = 0.35,
    ["Corrida"] = 1.4,
    ["Sem Aderência"] = 0.05,
}

local function hexToColor3(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", ""):gsub("%s", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r, g, b)
end

local function makeDraggable(guiObject)
    local dragging, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
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
                guiObject.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

local floatingGui = Instance.new("ScreenGui")
floatingGui.Name = "PainelXandao"
floatingGui.ResetOnSpawn = false
floatingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floatingGui.IgnoreGuiInset = true
floatingGui.Parent = playerGui

-- ─────────────────────────────────────────────
-- 2. VEÍCULO
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

local function getCarModel()
    local root = getVehicleRoot()
    if not root then return nil end
    local current = root
    for _ = 1, 10 do
        if not current then break end
        if current:IsA("Model") then
            if current:FindFirstChild("Body") or current:FindFirstChild("FR")
            or current:FindFirstChild("FL") then
                return current
            end
        end
        current = current.Parent
    end
    return root:FindFirstAncestorOfClass("Model") or root.Parent
end

local function getWheels()
    local car = getCarModel()
    if not car then return {} end
    local wheels = {}
    local names = {"FR", "FL", "RR", "RL"}
    for _, name in ipairs(names) do
        local wheelModel = car:FindFirstChild(name, true)
        if wheelModel then
            local wheelPart = wheelModel:FindFirstChild("Wheel", true)
            if wheelPart and wheelPart:IsA("BasePart") then
                table.insert(wheels, wheelPart)
            elseif wheelModel:IsA("BasePart") then
                table.insert(wheels, wheelModel)
            end
        end
    end
    if #wheels == 0 then
        for _, desc in ipairs(car:GetDescendants()) do
            if desc.Name == "Wheel" and desc:IsA("BasePart") then
                table.insert(wheels, desc)
            end
        end
    end
    return wheels
end

local function getNitroParticles()
    local car = getCarModel()
    if not car then return {} end
    local list = {}
    local body = car:FindFirstChild("Body") or car
    for _, desc in ipairs(body:GetDescendants()) do
        if desc.Name == "NitroFire" and desc:IsA("ParticleEmitter") then
            table.insert(list, desc)
        end
    end
    if #list == 0 then
        for _, desc in ipairs(car:GetDescendants()) do
            if desc.Name == "NitroFire" and desc:IsA("ParticleEmitter") then
                table.insert(list, desc)
            end
        end
    end
    return list
end

-- ─────────────────────────────────────────────
-- 3. SISTEMAS
-- ─────────────────────────────────────────────
local function applyNitroColors()
    local c1 = hexToColor3(nitroColor1Hex) or Color3.fromRGB(255, 85, 0)
    local c2 = hexToColor3(nitroColor2Hex) or Color3.fromRGB(255, 170, 0)
    local seq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2),
    })
    for _, pe in ipairs(getNitroParticles()) do
        pe.Color = seq
    end
end

local function setNitroParticlesEnabled(enabled)
    if not nitroEffectEnabled then enabled = false end
    local particles = getNitroParticles()
    for _, pe in ipairs(particles) do
        pe.Enabled = enabled
        if enabled then applyNitroColors() end
    end
    return #particles
end

local function stopBoost()
    isBoosting = false
    if boostConn then boostConn:Disconnect() boostConn = nil end
    if activeForce then pcall(function() activeForce:Destroy() end) activeForce = nil end
    if activeAtt then pcall(function() activeAtt:Destroy() end) activeAtt = nil end
    setNitroParticlesEnabled(false)
end

local function startBoost()
    if not nitroEnabled then return false end
    stopBoost()
    local root = getVehicleRoot()
    if not root then return false end
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
    setNitroParticlesEnabled(true)
    isBoosting = true
    boostConn = RunService.Heartbeat:Connect(function()
        if not isBoosting or not nitroEnabled then stopBoost() return end
        local r = getVehicleRoot()
        if not r or not activeForce then stopBoost() return end
        activeForce.Force = r.CFrame.LookVector * BOOST_FORCE
    end)
    return true
end

local function applyJump()
    if not jumpEnabled then return false end
    local root = getVehicleRoot()
    if not root then return false end
    root:ApplyImpulse(Vector3.new(0, JUMP_FORCE * 80, 0))
    return true
end

local function startGravityLock()
    if gravityLockConn then return end
    gravityLockConn = RunService.Heartbeat:Connect(function()
        if workspace.Gravity ~= currentGravity then
            workspace.Gravity = currentGravity
        end
    end)
end

local function applyFrictionToWheels(friction)
    local wheels = getWheels()
    if #wheels == 0 then return 0 end
    friction = math.clamp(tonumber(friction) or 1, 0, 4)
    for _, w in ipairs(wheels) do
        if not originalWheelPhys[w] then
            pcall(function()
                if w.CustomPhysicalProperties then
                    originalWheelPhys[w] = w.CustomPhysicalProperties
                else
                    originalWheelPhys[w] = PhysicalProperties.new(w.Material)
                end
            end)
        end
        pcall(function()
            local old = originalWheelPhys[w]
            local density, elasticity, frictionWeight, elasticityWeight = 0.7, 0.5, 2, 1
            if old then
                density = old.Density
                elasticity = old.Elasticity
                frictionWeight = math.max(old.FrictionWeight or 1, 2)
                elasticityWeight = old.ElasticityWeight or 1
            end
            w.CustomPhysicalProperties = PhysicalProperties.new(
                density, friction, elasticity, frictionWeight, elasticityWeight
            )
        end)
    end
    return #wheels
end

local function restoreWheelPhysics()
    local count = 0
    for wheel, phys in pairs(originalWheelPhys) do
        if wheel and wheel.Parent then
            pcall(function() wheel.CustomPhysicalProperties = phys end)
            count = count + 1
        end
    end
    originalWheelPhys = {}
    return count
end

local function startAdhesionLock()
    if adhesionConn then return end
    adhesionConn = RunService.Heartbeat:Connect(function()
        if not adhesionEnabled then return end
        for _, w in ipairs(getWheels()) do
            pcall(function()
                local props = w.CustomPhysicalProperties
                if not props or math.abs(props.Friction - currentFriction) > 0.01 then
                    applyFrictionToWheels(currentFriction)
                end
            end)
        end
    end)
end

local function stopAdhesionLock()
    if adhesionConn then
        adhesionConn:Disconnect()
        adhesionConn = nil
    end
end

local function applyFOV(value)
    currentFOV = math.clamp(tonumber(value) or 70, 1, 120)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = currentFOV end
    end)
end

local function startFOVLock()
    if fovConn then return end
    fovConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam and math.abs(cam.FieldOfView - currentFOV) > 0.1 then
                cam.FieldOfView = currentFOV
            end
        end)
    end)
end

local function createFloatingButton(name, text, color, callback, isHold)
    local old = floatingGui:FindFirstChild(name)
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
    btn.Parent = floatingGui
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
-- 4. CONFIGS (código)
-- ─────────────────────────────────────────────
local ui = {}
local nitroKeyBtn, jumpKeyBtn, menuKeyBtn
local exportCodeBox

local function getCurrentSettings()
    return {
        nitroForce = BOOST_FORCE,
        jumpForce = JUMP_FORCE,
        gravity = currentGravity,
        friction = currentFriction,
        adhesionEnabled = adhesionEnabled,
        fov = currentFOV,
        nitroColor1 = nitroColor1Hex,
        nitroColor2 = nitroColor2Hex,
        nitroEnabled = nitroEnabled,
        jumpEnabled = jumpEnabled,
        nitroEffect = nitroEffectEnabled,
        menuScale = menuScale,
        nitroKey = nitroKey.Name,
        jumpKey = jumpKey.Name,
        menuKey = menuKey.Name,
    }
end

local function applySettings(data)
    if type(data) ~= "table" then return false end
    BOOST_FORCE = tonumber(data.nitroForce) or BOOST_FORCE
    JUMP_FORCE = tonumber(data.jumpForce) or JUMP_FORCE
    currentGravity = tonumber(data.gravity) or currentGravity
    workspace.Gravity = currentGravity
    currentFriction = math.clamp(tonumber(data.friction) or currentFriction, 0, 4)
    adhesionEnabled = data.adhesionEnabled ~= false
    if data.fov then applyFOV(data.fov) end
    nitroColor1Hex = data.nitroColor1 or nitroColor1Hex
    nitroColor2Hex = data.nitroColor2 or nitroColor2Hex
    nitroEnabled = data.nitroEnabled ~= false
    jumpEnabled = data.jumpEnabled == true
    nitroEffectEnabled = data.nitroEffect ~= false
    menuScale = tonumber(data.menuScale) or 1
    pcall(function()
        if data.nitroKey and Enum.KeyCode[data.nitroKey] then nitroKey = Enum.KeyCode[data.nitroKey] end
        if data.jumpKey and Enum.KeyCode[data.jumpKey] then jumpKey = Enum.KeyCode[data.jumpKey] end
        if data.menuKey and Enum.KeyCode[data.menuKey] then menuKey = Enum.KeyCode[data.menuKey] end
    end)
    applyNitroColors()
    if adhesionEnabled then
        applyFrictionToWheels(currentFriction)
        startAdhesionLock()
    else
        stopAdhesionLock()
    end
    pcall(function()
        if ui.nitroToggle then ui.nitroToggle:Set(nitroEnabled) end
        if ui.nitroEffectToggle then ui.nitroEffectToggle:Set(nitroEffectEnabled) end
        if ui.nitroForceInput then ui.nitroForceInput:Set(tostring(BOOST_FORCE)) end
        if ui.nitroColor1 then
            local c = hexToColor3(nitroColor1Hex)
            if c then ui.nitroColor1:Set(c) end
        end
        if ui.nitroColor2 then
            local c = hexToColor3(nitroColor2Hex)
            if c then ui.nitroColor2:Set(c) end
        end
        if ui.jumpToggle then ui.jumpToggle:Set(jumpEnabled) end
        if ui.jumpForceInput then ui.jumpForceInput:Set(tostring(JUMP_FORCE)) end
        if ui.gravitySlider then ui.gravitySlider:Set(currentGravity) end
        if ui.frictionSlider then ui.frictionSlider:Set(currentFriction) end
        if ui.adhesionToggle then ui.adhesionToggle:Set(adhesionEnabled) end
        if ui.fovSlider then ui.fovSlider:Set(currentFOV) end
        if ui.menuScaleSlider then ui.menuScaleSlider:Set(menuScale) end
        if nitroKeyBtn then nitroKeyBtn:Set("⌨️ Tecla Nitro: [" .. nitroKey.Name .. "]") end
        if jumpKeyBtn then jumpKeyBtn:Set("⌨️ Tecla Pulo: [" .. jumpKey.Name .. "]") end
        if menuKeyBtn then menuKeyBtn:Set("⌨️ Tecla Menu: [" .. menuKey.Name .. "]") end
    end)
    pcall(function()
        for _, g in ipairs({game:GetService("CoreGui"), playerGui}) do
            local rf = g:FindFirstChild("Rayfield") or g:FindFirstChild("RayfieldLibrary")
            if rf then
                local main = rf:FindFirstChild("Main", true)
                if main and main:IsA("GuiObject") then
                    main.Size = UDim2.new(0, math.floor(500 * menuScale), 0, math.floor(350 * menuScale))
                    break
                end
            end
        end
    end)
    return true
end

local function generateConfigCode()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(getCurrentSettings())
    end)
    if ok and encoded then return encoded end
    return ""
end

local function loadConfigFromCode(code)
    if type(code) ~= "string" then return false end
    code = code:gsub("^%s+", ""):gsub("%s+$", "")
    if code == "" then return false end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(code)
    end)
    if not ok or type(data) ~= "table" then return false end
    return applySettings(data)
end

-- ─────────────────────────────────────────────
-- 5. UI
-- ─────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ Painel do Xandão",
   Icon = 0,
   LoadingTitle = "Painel do Xandão",
   LoadingSubtitle = "by Xandão",
   ShowText = "Xandão",
   Theme = "Default",
   ToggleUIKeybind = "J",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false,
})

-- NITRO
local NitroTab = Window:CreateTab("⚡ Nitro", 4483362458)
NitroTab:CreateSection("Sistema")
ui.nitroToggle = NitroTab:CreateToggle({
   Name = "Ativar Nitro", CurrentValue = true, Flag = "NitroSystem",
   Callback = function(Value) nitroEnabled = Value if not Value then stopBoost() end end,
})
ui.nitroEffectToggle = NitroTab:CreateToggle({
   Name = "Efeito de Partículas (NitroFire)", CurrentValue = true, Flag = "NitroEffect",
   Callback = function(Value) nitroEffectEnabled = Value if not Value then setNitroParticlesEnabled(false) end end,
})
NitroTab:CreateSection("Força")
ui.nitroForceInput = NitroTab:CreateInput({
   Name = "Força do Nitro", CurrentValue = tostring(BOOST_FORCE), PlaceholderText = "1000",
   RemoveTextAfterFocusLost = false, Flag = "NitroForce",
   Callback = function(Text) local v = tonumber(Text) if v then BOOST_FORCE = math.max(v, 0) end end,
})
NitroTab:CreateSection("Cores")
ui.nitroColor1 = NitroTab:CreateColorPicker({
   Name = "Cor Primária", Color = hexToColor3(nitroColor1Hex) or Color3.fromRGB(255, 85, 0), Flag = "NitroColor1",
   Callback = function(Value)
      nitroColor1Hex = string.format("#%02X%02X%02X", math.floor(Value.R*255), math.floor(Value.G*255), math.floor(Value.B*255))
      applyNitroColors()
   end,
})
ui.nitroColor2 = NitroTab:CreateColorPicker({
   Name = "Cor Secundária", Color = hexToColor3(nitroColor2Hex) or Color3.fromRGB(255, 170, 0), Flag = "NitroColor2",
   Callback = function(Value)
      nitroColor2Hex = string.format("#%02X%02X%02X", math.floor(Value.R*255), math.floor(Value.G*255), math.floor(Value.B*255))
      applyNitroColors()
   end,
})
NitroTab:CreateSection("Controles")
NitroTab:CreateButton({
   Name = "📌 Criar / Remover Botão Flutuante",
   Callback = function()
      if nitroBtnExists then
         local old = floatingGui:FindFirstChild("FloatingNitro")
         if old then old:Destroy() end
         nitroBtnExists = false
      else
         createFloatingButton("FloatingNitro", "⚡", Color3.fromRGB(230, 120, 0), function(state)
            if state then startBoost() else stopBoost() end
         end, true)
         nitroBtnExists = true
      end
   end,
})
nitroKeyBtn = NitroTab:CreateButton({
   Name = "⌨️ Tecla Nitro: [" .. nitroKey.Name .. "]",
   Callback = function() isBindingKey = true bindingType = "nitro" end,
})
NitroTab:CreateSection("Como usar?")
NitroTab:CreateParagraph({
   Title = "Nitro",
   Content = "1. Entre no veículo\n2. Ajuste a força\n3. Segure LeftShift ou o botão flutuante\n4. Solte para parar",
})

-- PULO
local JumpTab = Window:CreateTab("🦘 Pulo", 4483362458)
JumpTab:CreateSection("Sistema")
ui.jumpToggle = JumpTab:CreateToggle({
   Name = "Ativar Pulo", CurrentValue = false, Flag = "JumpSystem",
   Callback = function(Value) jumpEnabled = Value end,
})
JumpTab:CreateSection("Força")
ui.jumpForceInput = JumpTab:CreateInput({
   Name = "Poder do Pulo", CurrentValue = tostring(JUMP_FORCE), PlaceholderText = "50",
   RemoveTextAfterFocusLost = false, Flag = "JumpForce",
   Callback = function(Text) local v = tonumber(Text) if v then JUMP_FORCE = math.max(v, 0) end end,
})
JumpTab:CreateSection("Controles")
JumpTab:CreateButton({
   Name = "📌 Criar / Remover Botão Flutuante",
   Callback = function()
      if jumpBtnExists then
         local old = floatingGui:FindFirstChild("FloatingJump")
         if old then old:Destroy() end
         jumpBtnExists = false
      else
         createFloatingButton("FloatingJump", "🦘", Color3.fromRGB(0, 150, 220), function() applyJump() end, false)
         jumpBtnExists = true
      end
   end,
})
jumpKeyBtn = JumpTab:CreateButton({
   Name = "⌨️ Tecla Pulo: [" .. jumpKey.Name .. "]",
   Callback = function() isBindingKey = true bindingType = "jump" end,
})
JumpTab:CreateSection("Como usar?")
JumpTab:CreateParagraph({
   Title = "Pulo",
   Content = "Começa desativado (Space = freio de mão).\nTecla padrão: LeftControl\n1. Ative o pulo\n2. Ajuste a força\n3. Use a tecla ou o botão",
})

-- GRAVIDADE
local GravityTab = Window:CreateTab("🌍 Gravidade", 4483362458)
GravityTab:CreateSection("Controle")
ui.gravitySlider = GravityTab:CreateSlider({
   Name = "Valor da Gravidade", Range = {0, 1000}, Increment = 1, Suffix = "",
   CurrentValue = math.clamp(ORIGINAL_GRAVITY, 0, 1000), Flag = "Gravity",
   Callback = function(Value) currentGravity = Value workspace.Gravity = Value end,
})
GravityTab:CreateButton({
   Name = "↩️ Restaurar Gravidade Original",
   Callback = function()
      currentGravity = ORIGINAL_GRAVITY
      workspace.Gravity = ORIGINAL_GRAVITY
      if ui.gravitySlider then ui.gravitySlider:Set(math.clamp(ORIGINAL_GRAVITY, 0, 1000)) end
   end,
})
GravityTab:CreateSection("Como usar?")
GravityTab:CreateParagraph({
   Title = "Gravidade",
   Content = "Sempre travada (anti-reset).\nOriginal: " .. tostring(ORIGINAL_GRAVITY) .. " | Range: 0–1000",
})

-- ADERÊNCIA
local AdhesionTab = Window:CreateTab("🛞 Aderência", 4483362458)
AdhesionTab:CreateSection("Sistema")
ui.adhesionToggle = AdhesionTab:CreateToggle({
   Name = "Ativar Controle de Aderência", CurrentValue = true, Flag = "AdhesionEnabled",
   Callback = function(Value)
      adhesionEnabled = Value
      if Value then
         applyFrictionToWheels(currentFriction)
         startAdhesionLock()
      else
         stopAdhesionLock()
         restoreWheelPhysics()
      end
   end,
})
AdhesionTab:CreateSection("Friction (0 - 4)")
ui.frictionSlider = AdhesionTab:CreateSlider({
   Name = "Aderência (Friction)", Range = {0, 4}, Increment = 0.05, Suffix = "",
   CurrentValue = 1, Flag = "Friction",
   Callback = function(Value)
      currentFriction = Value
      if adhesionEnabled then applyFrictionToWheels(currentFriction) end
   end,
})
AdhesionTab:CreateSection("Presets")
AdhesionTab:CreateButton({
   Name = "🏎️ Corrida (alta aderência)",
   Callback = function()
      currentFriction = ADHESION_PRESETS["Corrida"]
      if ui.frictionSlider then ui.frictionSlider:Set(currentFriction) end
      if adhesionEnabled then applyFrictionToWheels(currentFriction) end
   end,
})
AdhesionTab:CreateButton({
   Name = "🌀 Drift (média-baixa)",
   Callback = function()
      currentFriction = ADHESION_PRESETS["Drift"]
      if ui.frictionSlider then ui.frictionSlider:Set(currentFriction) end
      if adhesionEnabled then applyFrictionToWheels(currentFriction) end
   end,
})
AdhesionTab:CreateButton({
   Name = "🧊 Sem Aderência",
   Callback = function()
      currentFriction = ADHESION_PRESETS["Sem Aderência"]
      if ui.frictionSlider then ui.frictionSlider:Set(currentFriction) end
      if adhesionEnabled then applyFrictionToWheels(currentFriction) end
   end,
})
AdhesionTab:CreateButton({
   Name = "↩️ Restaurar Física Original",
   Callback = function()
      stopAdhesionLock()
      restoreWheelPhysics()
      adhesionEnabled = false
      if ui.adhesionToggle then ui.adhesionToggle:Set(false) end
   end,
})
AdhesionTab:CreateSection("Como usar?")
AdhesionTab:CreateParagraph({
   Title = "Aderência (CDT)",
   Content = "1. Entre no veículo\n2. Ative o controle\n3. Slider ou preset\n\nCorrida 1.4 | Drift 0.35 | Sem aderência 0.05\nForçado a cada frame (anti freio de mão).",
})

-- FOV
local FOVTab = Window:CreateTab("📷 FOV", 4483362458)
FOVTab:CreateSection("Campo de Visão")
ui.fovSlider = FOVTab:CreateSlider({
   Name = "FOV", Range = {50, 120}, Increment = 1, Suffix = "°",
   CurrentValue = math.clamp(ORIGINAL_FOV, 50, 120), Flag = "FOV",
   Callback = function(Value) applyFOV(Value) end,
})
FOVTab:CreateButton({
   Name = "↩️ Restaurar FOV Original",
   Callback = function()
      applyFOV(ORIGINAL_FOV)
      if ui.fovSlider then ui.fovSlider:Set(math.clamp(ORIGINAL_FOV, 1, 120)) end
   end,
})
FOVTab:CreateSection("Como usar?")
FOVTab:CreateParagraph({
   Title = "FOV",
   Content = "Campo de visão da câmera.\nMínimo: 1° | Máximo: 120° | Padrão: ~70°\nValor travado para o jogo não resetar.",
})

-- CONFIGS
local ConfigsTab = Window:CreateTab("💾 Configs", 4483362458)
ConfigsTab:CreateSection("Gerar e copiar")
ConfigsTab:CreateButton({
   Name = "⚙️ Gerar Código da Config Atual",
   Callback = function()
      local code = generateConfigCode()
      if exportCodeBox and code ~= "" then
         pcall(function() exportCodeBox:Set(code) end)
      end
   end,
})
exportCodeBox = ConfigsTab:CreateInput({
   Name = "Código gerado",
   CurrentValue = "",
   PlaceholderText = "Clique em Gerar Código...",
   RemoveTextAfterFocusLost = false,
   Flag = "ExportCode",
   Callback = function() end,
})
ConfigsTab:CreateButton({
   Name = "📋 Copiar Código",
   Callback = function()
      local code = generateConfigCode()
      if code ~= "" then
         pcall(function() if setclipboard then setclipboard(code) end end)
         pcall(function() if exportCodeBox then exportCodeBox:Set(code) end end)
      end
   end,
})
ConfigsTab:CreateSection("Carregar")
ConfigsTab:CreateInput({
   Name = "Colar código aqui",
   CurrentValue = "",
   PlaceholderText = "Cole o código do amigo...",
   RemoveTextAfterFocusLost = false,
   Flag = "ImportCode",
   Callback = function(Text)
      importCodeText = tostring(Text or "")
   end,
})
ConfigsTab:CreateButton({
   Name = "📂 Carregar Config",
   Callback = function()
      local code = importCodeText
      if code == "" then
         pcall(function()
            if Rayfield.Flags and Rayfield.Flags["ImportCode"] then
               local f = Rayfield.Flags["ImportCode"]
               code = tostring(f.CurrentValue or f.Value or "")
            end
         end)
      end
      if code ~= "" then
         loadConfigFromCode(code)
      end
   end,
})
ConfigsTab:CreateSection("Como usar?")
ConfigsTab:CreateParagraph({
   Title = "Configs por código",
   Content = "Compartilhar:\n1. Ajuste o painel\n2. Gerar Código\n3. Copiar Código\n4. Envie pro amigo\n\nCarregar:\n1. Cole o código\n2. Carregar Config\n3. A interface atualiza sozinha",
})

-- AJUSTES
local SettingsTab = Window:CreateTab("⚙️ Ajustes", 4483362458)
SettingsTab:CreateSection("Teclas")
SettingsTab:CreateParagraph({ Title = "Menu", Content = "Abrir/fechar painel: J" })
menuKeyBtn = SettingsTab:CreateButton({
   Name = "⌨️ Tecla Menu Extra: [" .. menuKey.Name .. "]",
   Callback = function() isBindingKey = true bindingType = "menu" end,
})
SettingsTab:CreateSection("Interface")
ui.menuScaleSlider = SettingsTab:CreateSlider({
   Name = "Escala do Menu", Range = {0.5, 2}, Increment = 0.05, Suffix = "x",
   CurrentValue = 1, Flag = "MenuScale",
   Callback = function(Value)
      menuScale = Value
      pcall(function()
         for _, g in ipairs({game:GetService("CoreGui"), playerGui}) do
            local rf = g:FindFirstChild("Rayfield") or g:FindFirstChild("RayfieldLibrary")
            if rf then
               local main = rf:FindFirstChild("Main", true)
               if main and main:IsA("GuiObject") then
                  main.Size = UDim2.new(0, math.floor(500 * Value), 0, math.floor(350 * Value))
                  break
               end
            end
         end
      end)
   end,
})
SettingsTab:CreateSection("Como usar?")
SettingsTab:CreateParagraph({ Title = "Ajustes", Content = "Tecla extra do menu e tamanho da interface." })

-- CRÉDITOS
local CreditsTab = Window:CreateTab("👑 Créditos", 4483362458)
CreditsTab:CreateSection("Desenvolvedor")
CreditsTab:CreateParagraph({
   Title = "Painel do Xandão",
   Content = "Desenvolvido por Xandão\n\nVersão 1.2 — Uso público\nObrigado por utilizar!",
})
CreditsTab:CreateSection("Recursos")
CreditsTab:CreateParagraph({
   Title = "O que tem no painel",
   Content = "• Nitro (força + cores)\n• Pulo (Control, começa off)\n• Gravidade travada\n• Aderência com presets\n• FOV 1°–120°\n• Configs por código (copiar/colar)",
})
CreditsTab:CreateSection("Créditos")
CreditsTab:CreateParagraph({
   Title = "Créditos",
   Content = "Criado por Xandão\nNão remova os créditos.",
})

-- ─────────────────────────────────────────────
-- 6. INPUT + INIT
-- ─────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBindingKey and (input.UserInputType == Enum.UserInputType.Keyboard
        or input.UserInputType == Enum.UserInputType.Gamepad1
        or input.UserInputType == Enum.UserInputType.Gamepad2) then
        if bindingType == "nitro" then
            nitroKey = input.KeyCode
            pcall(function() nitroKeyBtn:Set("⌨️ Tecla Nitro: [" .. nitroKey.Name .. "]") end)
        elseif bindingType == "jump" then
            jumpKey = input.KeyCode
            pcall(function() jumpKeyBtn:Set("⌨️ Tecla Pulo: [" .. jumpKey.Name .. "]") end)
        elseif bindingType == "menu" then
            menuKey = input.KeyCode
            pcall(function() menuKeyBtn:Set("⌨️ Tecla Menu Extra: [" .. menuKey.Name .. "]") end)
        end
        isBindingKey = false
        bindingType = nil
        return
    end
    if gameProcessed then return end
    if input.KeyCode == nitroKey and nitroEnabled then startBoost() end
    if input.KeyCode == jumpKey and jumpEnabled then applyJump() end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == nitroKey then stopBoost() end
end)

startGravityLock()
startAdhesionLock()
startFOVLock()
applyFOV(currentFOV)
