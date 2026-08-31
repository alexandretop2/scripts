--[[
    ═══════════════════════════════════════════
    ⚡ PAINEL DO XANDÃO
    Nitro • Pulo • Gravidade • Aderência • Configs
    ───────────────────────────────────────────
    Desenvolvido por: @alexandretop2
    Versão: 1.1 | Público
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
-- VARIÁVEIS
-- ─────────────────────────────────────────────
local menuKey = Enum.KeyCode.J
local nitroKey = Enum.KeyCode.LeftShift
local jumpKey = Enum.KeyCode.Space
local isBindingKey = false
local bindingType = nil

local BOOST_FORCE = 25000
local JUMP_FORCE = 2000
local isBoosting = false
local boostConn = nil
local activeForce = nil
local activeAtt = nil

local nitroEnabled = true
local jumpEnabled = true
local nitroEffectEnabled = true
local nitroBtnExists = false
local jumpBtnExists = false
local nitroColor1Hex = "#FF5500"
local nitroColor2Hex = "#FFAA00"

local ORIGINAL_GRAVITY = workspace.Gravity
local currentGravity = workspace.Gravity
local gravityLockConn = nil

-- Aderência (friction)
local currentFriction = 1.0
local adhesionEnabled = true
local adhesionConn = nil
local originalWheelPhys = {}

local menuScale = 1

local CONFIG_FOLDER = "PainelXandao/Configs"
local configs = {}
local selectedConfigName = nil
local configNameText = ""

local ADHESION_PRESETS = {
    ["Drift"] = 0.35,
    ["Corrida"] = 1.4,
    ["Sem Aderência"] = 0.05,
}

-- ─────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────
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
-- VEÍCULO / PARTÍCULAS
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
-- RODAS (CDT)
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- ADERÊNCIA (Friction forçada)
-- ─────────────────────────────────────────────
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
            local density = 0.7
            local elasticity = 0.5
            local frictionWeight = 2
            local elasticityWeight = 1
            if old then
                density = old.Density
                elasticity = old.Elasticity
                frictionWeight = math.max(old.FrictionWeight or 1, 2)
                elasticityWeight = old.ElasticityWeight or 1
            end
            w.CustomPhysicalProperties = PhysicalProperties.new(
                density,
                friction,
                elasticity,
                frictionWeight,
                elasticityWeight
            )
        end)
    end
    return #wheels
end

local function restoreWheelPhysics()
    local count = 0
    for wheel, phys in pairs(originalWheelPhys) do
        if wheel and wheel.Parent then
            pcall(function()
                wheel.CustomPhysicalProperties = phys
            end)
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
        local wheels = getWheels()
        for _, w in ipairs(wheels) do
            pcall(function()
                local props = w.CustomPhysicalProperties
                if not props or math.abs(props.Friction - currentFriction) > 0.01 then
                    applyFrictionToWheels(currentFriction)
                    return
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

-- ─────────────────────────────────────────────
-- GRAVIDADE (sempre travada)
-- ─────────────────────────────────────────────
local function startGravityLock()
    if gravityLockConn then return end
    gravityLockConn = RunService.Heartbeat:Connect(function()
        if workspace.Gravity ~= currentGravity then
            workspace.Gravity = currentGravity
        end
    end)
end

-- ─────────────────────────────────────────────
-- SISTEMA DE CONFIGS
-- ─────────────────────────────────────────────
local function ensureFolder()
    pcall(function()
        if isfolder and not isfolder("PainelXandao") then makefolder("PainelXandao") end
        if isfolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    end)
end

local function getConfigPath(name)
    return CONFIG_FOLDER .. "/" .. name .. ".json"
end

local function timeAgo(timestamp)
    local diff = os.time() - (tonumber(timestamp) or os.time())
    if diff < 60 then return "agora"
    elseif diff < 3600 then return math.floor(diff / 60) .. " min atrás"
    elseif diff < 86400 then return math.floor(diff / 3600) .. " h atrás"
    else return math.floor(diff / 86400) .. " dias atrás"
    end
end

local function loadAllConfigs()
    configs = {}
    ensureFolder()
    local ok, files = pcall(function()
        if listfiles then return listfiles(CONFIG_FOLDER) end
        return {}
    end)
    if not ok or type(files) ~= "table" then return end
    for _, path in ipairs(files) do
        local name = tostring(path):match("([^/\\]+)%.json$")
        if name then
            local success, content = pcall(function()
                return readfile(path)
            end)
            if success and content and content ~= "" then
                local decodeOk, data = pcall(function()
                    return HttpService:JSONDecode(content)
                end)
                if decodeOk and type(data) == "table" then
                    configs[name] = data
                end
            end
        end
    end
end

local function saveConfigToFile(name, data)
    ensureFolder()
    local ok = pcall(function()
        writefile(getConfigPath(name), HttpService:JSONEncode(data))
    end)
    return ok
end

local function deleteConfigFile(name)
    pcall(function()
        if delfile then delfile(getConfigPath(name)) end
    end)
    configs[name] = nil
end

local function getCurrentSettings()
    return {
        name = "",
        created = os.time(),
        nitroForce = BOOST_FORCE,
        jumpForce = JUMP_FORCE,
        gravity = currentGravity,
        friction = currentFriction,
        adhesionEnabled = adhesionEnabled,
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

local ui = {}
local nitroKeyBtn, jumpKeyBtn, menuKeyBtn
local configDropdown, configInfoLabel

local function applySettings(data)
    if type(data) ~= "table" then return false end
    BOOST_FORCE = tonumber(data.nitroForce) or BOOST_FORCE
    JUMP_FORCE = tonumber(data.jumpForce) or JUMP_FORCE
    currentGravity = tonumber(data.gravity) or currentGravity
    workspace.Gravity = currentGravity
    currentFriction = math.clamp(tonumber(data.friction) or currentFriction, 0, 4)
    adhesionEnabled = data.adhesionEnabled ~= false
    nitroColor1Hex = data.nitroColor1 or nitroColor1Hex
    nitroColor2Hex = data.nitroColor2 or nitroColor2Hex
    nitroEnabled = data.nitroEnabled ~= false
    jumpEnabled = data.jumpEnabled ~= false
    nitroEffectEnabled = data.nitroEffect ~= false
    menuScale = tonumber(data.menuScale) or 1
    pcall(function()
        if data.nitroKey and Enum.KeyCode[data.nitroKey] then
            nitroKey = Enum.KeyCode[data.nitroKey]
        end
        if data.jumpKey and Enum.KeyCode[data.jumpKey] then
            jumpKey = Enum.KeyCode[data.jumpKey]
        end
        if data.menuKey and Enum.KeyCode[data.menuKey] then
            menuKey = Enum.KeyCode[data.menuKey]
        end
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

local function getConfigNames()
    local names = {}
    for name in pairs(configs) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- ─────────────────────────────────────────────
-- RAYFIELD UI
-- ─────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ Painel do Xandão",
   Icon = 0,
   LoadingTitle = "Painel do Xandão",
   LoadingSubtitle = "by @alexandretop2",
   ShowText = "Xandão",
   Theme = "Default",
   ToggleUIKeybind = "J",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "PainelXandao",
      FileName = "AutoConfig"
   },
   Discord = { Enabled = false },
   KeySystem = false,
})

local function updateConfigInfo(name)
    if not configInfoLabel then return end
    local data = name and configs[name]
    if not data then
        pcall(function()
            configInfoLabel:Set({
                Title = "Nenhuma config selecionada",
                Content = "Salve ou selecione uma config na lista"
            })
        end)
        return
    end
    local text = string.format(
        "Criada: %s\nNitro: %s  |  Pulo: %s\nGravidade: %s  |  Aderência: %s\nCores: %s / %s\nTeclas: %s | %s",
        timeAgo(data.created),
        tostring(data.nitroForce or "?"),
        tostring(data.jumpForce or "?"),
        tostring(data.gravity or "?"),
        tostring(data.friction or "?"),
        tostring(data.nitroColor1 or "?"),
        tostring(data.nitroColor2 or "?"),
        tostring(data.nitroKey or "?"),
        tostring(data.jumpKey or "?")
    )
    pcall(function()
        configInfoLabel:Set({
            Title = tostring(name),
            Content = text
        })
    end)
end

local function refreshConfigList(preferName)
    loadAllConfigs()
    local names = getConfigNames()
    if #names == 0 then
        names = {"(nenhuma config)"}
        selectedConfigName = nil
    else
        if preferName and configs[preferName] then
            selectedConfigName = preferName
        elseif selectedConfigName and configs[selectedConfigName] then
        else
            selectedConfigName = names[1]
        end
    end
    if configDropdown then
        pcall(function()
            configDropdown:Refresh(names)
            if selectedConfigName and configs[selectedConfigName] then
                configDropdown:Set({selectedConfigName})
            end
        end)
    end
    updateConfigInfo(selectedConfigName)
    return names
end

-- ==================== TAB NITRO ====================
local NitroTab = Window:CreateTab("⚡ Nitro", 4483362458)

NitroTab:CreateSection("Sistema")
ui.nitroToggle = NitroTab:CreateToggle({
   Name = "Ativar Nitro",
   CurrentValue = true,
   Flag = "NitroSystem",
   Callback = function(Value)
      nitroEnabled = Value
      if not Value then stopBoost() end
   end,
})
ui.nitroEffectToggle = NitroTab:CreateToggle({
   Name = "Efeito de Partículas (NitroFire)",
   CurrentValue = true,
   Flag = "NitroEffect",
   Callback = function(Value)
      nitroEffectEnabled = Value
      if not Value then setNitroParticlesEnabled(false) end
   end,
})

NitroTab:CreateSection("Força")
ui.nitroForceInput = NitroTab:CreateInput({
   Name = "Força do Nitro",
   CurrentValue = tostring(BOOST_FORCE),
   PlaceholderText = "25000",
   RemoveTextAfterFocusLost = false,
   Flag = "NitroForce",
   Callback = function(Text)
      local v = tonumber(Text)
      if v then BOOST_FORCE = math.max(v, 0) end
   end,
})

NitroTab:CreateSection("Cores das Partículas")
ui.nitroColor1 = NitroTab:CreateColorPicker({
   Name = "Cor Primária",
   Color = hexToColor3(nitroColor1Hex) or Color3.fromRGB(255, 85, 0),
   Flag = "NitroColor1",
   Callback = function(Value)
      local r = math.floor(Value.R * 255)
      local g = math.floor(Value.G * 255)
      local b = math.floor(Value.B * 255)
      nitroColor1Hex = string.format("#%02X%02X%02X", r, g, b)
      applyNitroColors()
   end,
})
ui.nitroColor2 = NitroTab:CreateColorPicker({
   Name = "Cor Secundária",
   Color = hexToColor3(nitroColor2Hex) or Color3.fromRGB(255, 170, 0),
   Flag = "NitroColor2",
   Callback = function(Value)
      local r = math.floor(Value.R * 255)
      local g = math.floor(Value.G * 255)
      local b = math.floor(Value.B * 255)
      nitroColor2Hex = string.format("#%02X%02X%02X", r, g, b)
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
   Callback = function()
      isBindingKey = true
      bindingType = "nitro"
   end,
})

NitroTab:CreateSection("Como usar?")
NitroTab:CreateParagraph({
   Title = "Nitro",
   Content = "1. Entre no veículo\n2. Ajuste a força se quiser\n3. Segure a tecla (padrão: LeftShift) ou o botão flutuante\n4. Solte para parar\n\nPartículas só funcionam se o carro tiver NitroFire."
})

-- ==================== TAB PULO ====================
local JumpTab = Window:CreateTab("🦘 Pulo", 4483362458)

JumpTab:CreateSection("Sistema")
ui.jumpToggle = JumpTab:CreateToggle({
   Name = "Ativar Pulo",
   CurrentValue = true,
   Flag = "JumpSystem",
   Callback = function(Value)
      jumpEnabled = Value
   end,
})

JumpTab:CreateSection("Força")
ui.jumpForceInput = JumpTab:CreateInput({
   Name = "Poder do Pulo",
   CurrentValue = tostring(JUMP_FORCE),
   PlaceholderText = "2000",
   RemoveTextAfterFocusLost = false,
   Flag = "JumpForce",
   Callback = function(Text)
      local v = tonumber(Text)
      if v then JUMP_FORCE = math.max(v, 0) end
   end,
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
         createFloatingButton("FloatingJump", "🦘", Color3.fromRGB(0, 150, 220), function()
            applyJump()
         end, false)
         jumpBtnExists = true
      end
   end,
})
jumpKeyBtn = JumpTab:CreateButton({
   Name = "⌨️ Tecla Pulo: [" .. jumpKey.Name .. "]",
   Callback = function()
      isBindingKey = true
      bindingType = "jump"
   end,
})

JumpTab:CreateSection("Como usar?")
JumpTab:CreateParagraph({
   Title = "Pulo",
   Content = "1. Entre no veículo\n2. Ajuste a força se quiser\n3. Pressione a tecla (padrão: Space) ou o botão flutuante\n4. O carro recebe um impulso para cima"
})

-- ==================== TAB GRAVIDADE ====================
local GravityTab = Window:CreateTab("🌍 Gravidade", 4483362458)

GravityTab:CreateSection("Controle")
ui.gravitySlider = GravityTab:CreateSlider({
   Name = "Valor da Gravidade",
   Range = {0, 1000},
   Increment = 1,
   Suffix = "",
   CurrentValue = math.clamp(ORIGINAL_GRAVITY, 0, 1000),
   Flag = "Gravity",
   Callback = function(Value)
      currentGravity = Value
      workspace.Gravity = Value
   end,
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
   Content = "A gravidade fica sempre travada (anti-reset).\nArraste o slider e o valor é forçado a cada frame.\n\nOriginal do jogo: " .. tostring(ORIGINAL_GRAVITY) .. "\nRange: 0 a 1000"
})

-- ==================== TAB ADERÊNCIA ====================
local AdhesionTab = Window:CreateTab("🛞 Aderência", 4483362458)

AdhesionTab:CreateSection("Sistema")
ui.adhesionToggle = AdhesionTab:CreateToggle({
   Name = "Ativar Controle de Aderência",
   CurrentValue = true,
   Flag = "AdhesionEnabled",
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
   Name = "Aderência (Friction)",
   Range = {0, 4},
   Increment = 0.05,
   Suffix = "",
   CurrentValue = 1,
   Flag = "Friction",
   Callback = function(Value)
      currentFriction = Value
      if adhesionEnabled then
         applyFrictionToWheels(currentFriction)
      end
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
   Name = "↩️ Restaurar Física Original das Rodas",
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
   Content = "1. Entre no veículo\n2. Ative o controle de aderência\n3. Use o slider (0 a 4) ou um preset\n\nO valor é forçado a cada frame (anti freio de mão / anti-reset).\n\nPresets:\n• Corrida = 1.4 (muito grip)\n• Drift = 0.35 (escorrega fácil)\n• Sem Aderência = 0.05 (quase gelo)\n\nTambém eleva FrictionWeight para a roda dominar o contato."
})

-- ==================== TAB CONFIGS ====================
local ConfigsTab = Window:CreateTab("💾 Configs", 4483362458)

ConfigsTab:CreateSection("Salvar")
ConfigsTab:CreateInput({
   Name = "Nome da Config",
   CurrentValue = "",
   PlaceholderText = "Ex: SetupDrift",
   RemoveTextAfterFocusLost = false,
   Flag = "ConfigNameInput",
   Callback = function(Text)
      configNameText = tostring(Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
   end,
})
ConfigsTab:CreateButton({
   Name = "💾 Salvar Config Atual",
   Callback = function()
      local name = configNameText
      if name == "" or name == "(nenhuma config)" then return end
      name = name:gsub("[/\\:*?\"<>|]", "")
      if name == "" then return end
      local data = getCurrentSettings()
      data.name = name
      data.created = os.time()
      local ok = saveConfigToFile(name, data)
      if ok then
         configs[name] = data
         selectedConfigName = name
         refreshConfigList(name)
      end
   end,
})

ConfigsTab:CreateSection("Configs Salvas")
loadAllConfigs()
local initialNames = getConfigNames()
if #initialNames == 0 then
    initialNames = {"(nenhuma config)"}
else
    selectedConfigName = initialNames[1]
end

configDropdown = ConfigsTab:CreateDropdown({
   Name = "Selecionar Config",
   Options = initialNames,
   CurrentOption = {initialNames[1]},
   MultipleOptions = false,
   Flag = "SelectedConfig",
   Callback = function(Option)
      local name
      if type(Option) == "table" then
         name = Option[1] or Option.Name or Option.Value
      else
         name = Option
      end
      name = tostring(name or "")
      if name ~= "" and name ~= "(nenhuma config)" and configs[name] then
         selectedConfigName = name
         updateConfigInfo(name)
      elseif name == "(nenhuma config)" then
         selectedConfigName = nil
         updateConfigInfo(nil)
      end
   end,
})

configInfoLabel = ConfigsTab:CreateParagraph({
   Title = selectedConfigName or "Nenhuma config selecionada",
   Content = selectedConfigName and "Carregando..." or "Salve ou selecione uma config"
})

task.defer(function()
    updateConfigInfo(selectedConfigName)
end)

ConfigsTab:CreateSection("Ações")
ConfigsTab:CreateButton({
   Name = "📂 Carregar Config",
   Callback = function()
      if not selectedConfigName or not configs[selectedConfigName] then
         local names = getConfigNames()
         if #names > 0 then selectedConfigName = names[1] end
      end
      if not selectedConfigName or not configs[selectedConfigName] then return end
      applySettings(configs[selectedConfigName])
   end,
})
ConfigsTab:CreateButton({
   Name = "🔄 Substituir pela Atual",
   Callback = function()
      if not selectedConfigName or selectedConfigName == "(nenhuma config)" or not configs[selectedConfigName] then return end
      local data = getCurrentSettings()
      data.name = selectedConfigName
      data.created = configs[selectedConfigName].created or os.time()
      if saveConfigToFile(selectedConfigName, data) then
         configs[selectedConfigName] = data
         updateConfigInfo(selectedConfigName)
      end
   end,
})
ConfigsTab:CreateButton({
   Name = "✏️ Renomear Config",
   Callback = function()
      if not selectedConfigName or not configs[selectedConfigName] then return end
      local newName = configNameText:gsub("[/\\:*?\"<>|]", "")
      if newName == "" or newName == selectedConfigName then return end
      local data = configs[selectedConfigName]
      data.name = newName
      if saveConfigToFile(newName, data) then
         deleteConfigFile(selectedConfigName)
         configs[newName] = data
         selectedConfigName = newName
         refreshConfigList(newName)
      end
   end,
})
ConfigsTab:CreateButton({
   Name = "🗑️ Apagar Config",
   Callback = function()
      if not selectedConfigName or not configs[selectedConfigName] then return end
      deleteConfigFile(selectedConfigName)
      selectedConfigName = nil
      refreshConfigList()
   end,
})
ConfigsTab:CreateButton({
   Name = "🔄 Atualizar Lista",
   Callback = function()
      refreshConfigList()
   end,
})

ConfigsTab:CreateSection("Como usar?")
ConfigsTab:CreateParagraph({
   Title = "Configs",
   Content = "Salve setups (nitro, pulo, gravidade, aderência, teclas).\nUse Carregar para aplicar.\nPrecisa de writefile/readfile no executor."
})

-- ==================== TAB AJUSTES ====================
local SettingsTab = Window:CreateTab("⚙️ Ajustes", 4483362458)

SettingsTab:CreateSection("Teclas")
SettingsTab:CreateParagraph({
   Title = "Menu Principal",
   Content = "Tecla padrão para abrir/fechar: J"
})
menuKeyBtn = SettingsTab:CreateButton({
   Name = "⌨️ Tecla Menu Extra: [" .. menuKey.Name .. "]",
   Callback = function()
      isBindingKey = true
      bindingType = "menu"
   end,
})

SettingsTab:CreateSection("Interface")
ui.menuScaleSlider = SettingsTab:CreateSlider({
   Name = "Escala do Menu",
   Range = {0.5, 2},
   Increment = 0.05,
   Suffix = "x",
   CurrentValue = 1,
   Flag = "MenuScale",
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
SettingsTab:CreateParagraph({
   Title = "Ajustes",
   Content = "Altere a tecla extra do menu e o tamanho da interface.\nA tecla J (Rayfield) continua funcionando."
})

-- ==================== TAB CRÉDITOS ====================
local CreditsTab = Window:CreateTab("👑 Créditos", 4483362458)

CreditsTab:CreateSection("Desenvolvedor")
CreditsTab:CreateParagraph({
   Title = "Painel do Xandão",
   Content = "Desenvolvido por @alexandretop2\n\nVersão 1.1 — Uso público\nObrigado por utilizar!"
})

CreditsTab:CreateSection("Recursos")
CreditsTab:CreateParagraph({
   Title = "O que o painel oferece",
   Content = "• Nitro com força e cores personalizáveis\n• Sistema de pulo configurável\n• Gravidade sempre travada (anti-reset)\n• Aderência (friction) com presets e trava\n• Sistema de configs salvas\n• Botões flutuantes e teclas customizáveis"
})

CreditsTab:CreateSection("Contato")
CreditsTab:CreateParagraph({
   Title = "Créditos",
   Content = "Criado e mantido por:\n@alexandretop2\n\nNão remova os créditos.\nDivulgue com respeito."
})

-- ─────────────────────────────────────────────
-- INPUT
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
    if input.KeyCode == nitroKey and nitroEnabled then
        startBoost()
    end
    if input.KeyCode == jumpKey and jumpEnabled then
        applyJump()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == nitroKey then
        stopBoost()
    end
end)

-- Inicia travas
startGravityLock()
startAdhesionLock()

task.spawn(function()
    task.wait(0.8)
    refreshConfigList()
end)
