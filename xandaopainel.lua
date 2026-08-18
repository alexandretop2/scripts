--[[
    ⚡ CONTROL HUB - Rayfield Edition (v3)
    Nitro | Pulo | Pneu | Gravidade | Configs | Ajustes
    + Partículas NitroFire + cores hex + suporte a controle + configs salvas
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Limpa UI antiga se existir
pcall(function()
    local old = playerGui:FindFirstChild("CustomControlHub")
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

local MATERIALS = {
    Enum.Material.Plastic, Enum.Material.SmoothPlastic, Enum.Material.Neon,
    Enum.Material.ForceField, Enum.Material.Glass, Enum.Material.Metal,
    Enum.Material.DiamondPlate, Enum.Material.CorrodedMetal, Enum.Material.Foil,
    Enum.Material.Wood, Enum.Material.WoodPlanks, Enum.Material.Marble,
    Enum.Material.Slate, Enum.Material.Concrete, Enum.Material.Granite,
    Enum.Material.Brick, Enum.Material.Pebble, Enum.Material.Cobblestone,
    Enum.Material.Rock, Enum.Material.Sandstone, Enum.Material.Basalt,
    Enum.Material.CrackedLava, Enum.Material.Limestone, Enum.Material.Pavement,
    Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Sand,
    Enum.Material.Fabric, Enum.Material.Ice, Enum.Material.Glacier,
    Enum.Material.Snow, Enum.Material.Mud, Enum.Material.Ground,
    Enum.Material.Asphalt, Enum.Material.Salt, Enum.Material.Cardboard,
    Enum.Material.Carpet, Enum.Material.CeramicTiles, Enum.Material.ClayRoofTiles,
    Enum.Material.Plaster, Enum.Material.Rubber, Enum.Material.RoofShingles,
}
local materialIndex = 1
local originalWheelMaterials = {}

local ORIGINAL_GRAVITY = workspace.Gravity
local currentGravity = workspace.Gravity
local menuScale = 1

-- ─────────────────────────────────────────────
-- SISTEMA DE CONFIGS
-- ─────────────────────────────────────────────
local CONFIG_FOLDER = "ControlHub/Configs"
local configs = {}
local selectedConfigName = nil

local function ensureFolder()
    pcall(function()
        if not isfolder("ControlHub") then makefolder("ControlHub") end
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    end)
end

local function getConfigPath(name)
    return CONFIG_FOLDER .. "/" .. name .. ".json"
end

local function timeAgo(timestamp)
    local diff = os.time() - (timestamp or os.time())
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
        return listfiles(CONFIG_FOLDER)
    end)
    if not ok or not files then return end
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name then
            local success, content = pcall(readfile, path)
            if success and content then
                local decodeOk, data = pcall(function()
                    return HttpService:JSONDecode(content)
                end)
                if decodeOk and data then
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
        delfile(getConfigPath(name))
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
        nitroColor1 = nitroColor1Hex,
        nitroColor2 = nitroColor2Hex,
        nitroEnabled = nitroEnabled,
        jumpEnabled = jumpEnabled,
        nitroEffect = nitroEffectEnabled,
        materialIndex = materialIndex,
        menuScale = menuScale,
        nitroKey = nitroKey.Name,
        jumpKey = jumpKey.Name,
        menuKey = menuKey.Name,
    }
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

local function applySettings(data)
    if not data then return end
    BOOST_FORCE = data.nitroForce or BOOST_FORCE
    JUMP_FORCE = data.jumpForce or JUMP_FORCE
    currentGravity = data.gravity or currentGravity
    workspace.Gravity = currentGravity
    nitroColor1Hex = data.nitroColor1 or nitroColor1Hex
    nitroColor2Hex = data.nitroColor2 or nitroColor2Hex
    nitroEnabled = data.nitroEnabled ~= false
    jumpEnabled = data.jumpEnabled ~= false
    nitroEffectEnabled = data.nitroEffect ~= false
    materialIndex = data.materialIndex or materialIndex
    menuScale = data.menuScale or 1
    pcall(function()
        if data.nitroKey then nitroKey = Enum.KeyCode[data.nitroKey] or nitroKey end
        if data.jumpKey then jumpKey = Enum.KeyCode[data.jumpKey] or jumpKey end
        if data.menuKey then menuKey = Enum.KeyCode[data.menuKey] or menuKey end
    end)
    applyNitroColors()
end

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
floatingGui.Name = "CustomControlHub"
floatingGui.ResetOnSpawn = false
floatingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
floatingGui.IgnoreGuiInset = true
floatingGui.Parent = playerGui

-- ─────────────────────────────────────────────
-- VEHICLE / PARTICLES
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

local function applyWheelMaterial()
    local wheels = getWheels()
    if #wheels == 0 then return 0 end
    local mat = MATERIALS[materialIndex]
    for _, w in ipairs(wheels) do
        if not originalWheelMaterials[w] then
            originalWheelMaterials[w] = w.Material
        end
        w.Material = mat
    end
    return #wheels, mat.Name
end

local function restoreWheelMaterials()
    local count = 0
    for wheel, mat in pairs(originalWheelMaterials) do
        if wheel and wheel.Parent then
            wheel.Material = mat
            count = count + 1
        end
    end
    originalWheelMaterials = {}
    return count
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
-- RAYFIELD UI
-- ─────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "⚡ CONTROL HUB",
   Icon = 0,
   LoadingTitle = "Control Hub",
   LoadingSubtitle = "Nitro | Pulo | Pneu | Gravidade | Configs",
   ShowText = "Control Hub",
   Theme = "Default",
   ToggleUIKeybind = "J",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "ControlHub",
      FileName = "AutoConfig"
   },
   Discord = { Enabled = false },
   KeySystem = false,
})

local nitroKeyBtn, jumpKeyBtn, menuKeyBtn
local configDropdown, configInfoLabel
local configNameInput

local function refreshConfigList()
    loadAllConfigs()
    local names = {}
    for name in pairs(configs) do
        table.insert(names, name)
    end
    table.sort(names)
    if #names == 0 then names = {"(nenhuma config)"} end
    if configDropdown then
        pcall(function()
            configDropdown:Refresh(names)
        end)
    end
    return names
end

local function updateConfigInfo(name)
    if not configInfoLabel then return end
    local data = configs[name]
    if not data then
        pcall(function()
            configInfoLabel:Set({
                Title = "Nenhuma config selecionada",
                Content = "Salve ou selecione uma config"
            })
        end)
        return
    end
    local text = string.format(
        "Criada: %s\nNitro: %s\nPulo: %s\nGravidade: %s\nCores: %s / %s",
        timeAgo(data.created),
        tostring(data.nitroForce or "?"),
        tostring(data.jumpForce or "?"),
        tostring(data.gravity or "?"),
        data.nitroColor1 or "?",
        data.nitroColor2 or "?"
    )
    pcall(function()
        configInfoLabel:Set({
            Title = name,
            Content = text
        })
    end)
end

-- ==================== TAB NITRO ====================
local NitroTab = Window:CreateTab("⚡ Nitro", 4483362458)

NitroTab:CreateSection("Sistema")

NitroTab:CreateToggle({
   Name = "Ativar Sistema de Nitro",
   CurrentValue = true,
   Flag = "NitroSystem",
   Callback = function(Value)
      nitroEnabled = Value
      if not Value then stopBoost() end
      Rayfield:Notify({ Title = "Nitro", Content = Value and "Sistema ativado" or "Sistema desativado", Duration = 2 })
   end,
})

NitroTab:CreateToggle({
   Name = "Efeito de Partículas (NitroFire)",
   CurrentValue = true,
   Flag = "NitroEffect",
   Callback = function(Value)
      nitroEffectEnabled = Value
      if not Value then setNitroParticlesEnabled(false) end
      Rayfield:Notify({ Title = "Efeito Nitro", Content = Value and "Partículas ativadas" or "Partículas desativadas", Duration = 2 })
   end,
})

NitroTab:CreateSection("Força do Nitro")

NitroTab:CreateInput({
   Name = "Força do Nitro (100 - 1M)",
   CurrentValue = tostring(BOOST_FORCE),
   PlaceholderText = "25000",
   RemoveTextAfterFocusLost = false,
   Flag = "NitroForce",
   Callback = function(Text)
      local v = tonumber(Text)
      if v then
         BOOST_FORCE = math.clamp(v, 100, 1000000)
         Rayfield:Notify({ Title = "Nitro", Content = "Força: " .. BOOST_FORCE, Duration = 2 })
      end
   end,
})

NitroTab:CreateSection("Cores das Partículas")

NitroTab:CreateColorPicker({
   Name = "Cor Nitro 1 (preview)",
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

NitroTab:CreateColorPicker({
   Name = "Cor Nitro 2 (preview)",
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

NitroTab:CreateSection("Botões e Teclas")

NitroTab:CreateButton({
   Name = "📌 Criar / Remover Botão de Nitro",
   Callback = function()
      if nitroBtnExists then
         local old = floatingGui:FindFirstChild("FloatingNitro")
         if old then old:Destroy() end
         nitroBtnExists = false
         Rayfield:Notify({ Title = "Botão Nitro", Content = "Removido", Duration = 2 })
      else
         createFloatingButton("FloatingNitro", "⚡", Color3.fromRGB(230, 120, 0), function(state)
            if state then
               local ok = startBoost()
               if not ok then
                  Rayfield:Notify({ Title = "Nitro", Content = "Entre no veículo ou sistema desativado!", Duration = 3 })
               end
            else
               stopBoost()
            end
         end, true)
         nitroBtnExists = true
         Rayfield:Notify({ Title = "Botão Nitro", Content = "Criado (arraste para mover)", Duration = 2 })
      end
   end,
})

nitroKeyBtn = NitroTab:CreateButton({
   Name = "⌨️ Tecla Nitro: [" .. nitroKey.Name .. "]",
   Callback = function()
      Rayfield:Notify({ Title = "Aguardando tecla...", Content = "Pressione a tecla ou botão do controle", Duration = 4 })
      isBindingKey = true
      bindingType = "nitro"
   end,
})

-- ==================== TAB PULO ====================
local JumpTab = Window:CreateTab("🦘 Pulo", 4483362458)

JumpTab:CreateSection("Sistema")

JumpTab:CreateToggle({
   Name = "Ativar Sistema de Pulo",
   CurrentValue = true,
   Flag = "JumpSystem",
   Callback = function(Value)
      jumpEnabled = Value
      Rayfield:Notify({ Title = "Pulo", Content = Value and "Sistema ativado" or "Sistema desativado", Duration = 2 })
   end,
})

JumpTab:CreateSection("Poder do Pulo")

JumpTab:CreateInput({
   Name = "Poder do Pulo (0 - 5000)",
   CurrentValue = tostring(JUMP_FORCE),
   PlaceholderText = "2000",
   RemoveTextAfterFocusLost = false,
   Flag = "JumpForce",
   Callback = function(Text)
      local v = tonumber(Text)
      if v then
         JUMP_FORCE = math.clamp(v, 0, 5000)
         Rayfield:Notify({ Title = "Pulo", Content = "Força: " .. JUMP_FORCE, Duration = 2 })
      end
   end,
})

JumpTab:CreateSection("Botões e Teclas")

JumpTab:CreateButton({
   Name = "📌 Criar / Remover Botão de Pulo",
   Callback = function()
      if jumpBtnExists then
         local old = floatingGui:FindFirstChild("FloatingJump")
         if old then old:Destroy() end
         jumpBtnExists = false
         Rayfield:Notify({ Title = "Botão Pulo", Content = "Removido", Duration = 2 })
      else
         createFloatingButton("FloatingJump", "🦘", Color3.fromRGB(0, 150, 220), function()
            local ok = applyJump()
            if not ok then
               Rayfield:Notify({ Title = "Pulo", Content = "Entre no veículo ou sistema desativado!", Duration = 3 })
            else
               Rayfield:Notify({ Title = "Pulo", Content = "Aplicado!", Duration = 1.5 })
            end
         end, false)
         jumpBtnExists = true
         Rayfield:Notify({ Title = "Botão Pulo", Content = "Criado (arraste para mover)", Duration = 2 })
      end
   end,
})

jumpKeyBtn = JumpTab:CreateButton({
   Name = "⌨️ Tecla Pulo: [" .. jumpKey.Name .. "]",
   Callback = function()
      Rayfield:Notify({ Title = "Aguardando tecla...", Content = "Pressione a tecla ou botão do controle", Duration = 4 })
      isBindingKey = true
      bindingType = "jump"
   end,
})

-- ==================== TAB PNEU ====================
local PneuTab = Window:CreateTab("🛞 Pneu", 4483362458)

PneuTab:CreateSection("Material do Pneu")

local materialOptions = {}
for _, mat in ipairs(MATERIALS) do
   table.insert(materialOptions, mat.Name)
end

PneuTab:CreateDropdown({
   Name = "Escolher Material",
   Options = materialOptions,
   CurrentOption = {MATERIALS[materialIndex].Name},
   MultipleOptions = false,
   Flag = "WheelMaterial",
   Callback = function(Option)
      local selected = type(Option) == "table" and Option[1] or Option
      for i, mat in ipairs(MATERIALS) do
         if mat.Name == selected then
            materialIndex = i
            break
         end
      end
   end,
})

PneuTab:CreateButton({
   Name = "✅ Aplicar Material nas Rodas",
   Callback = function()
      local count, matName = applyWheelMaterial()
      if count > 0 then
         Rayfield:Notify({ Title = "Pneu", Content = "Material " .. matName .. " aplicado em " .. count .. " roda(s)!", Duration = 3 })
      else
         Rayfield:Notify({ Title = "Pneu", Content = "Entre no veículo ou não encontrei FR/FL/RR/RL → Wheel", Duration = 4 })
      end
   end,
})

PneuTab:CreateButton({
   Name = "↩️ Voltar Material Original",
   Callback = function()
      local count = restoreWheelMaterials()
      if count > 0 then
         Rayfield:Notify({ Title = "Pneu", Content = "Material original restaurado em " .. count .. " roda(s)!", Duration = 3 })
      else
         Rayfield:Notify({ Title = "Pneu", Content = "Nenhum material original salvo ainda. Aplique um material primeiro.", Duration = 4 })
      end
   end,
})

PneuTab:CreateParagraph({
   Title = "Como funciona",
   Content = "Procura: FR / FL / RR / RL → Wheel\nEntre no veículo e clique Aplicar.\nO botão \"Voltar Original\" restaura o material que as rodas tinham antes."
})

-- ==================== TAB GRAVIDADE ====================
local GravityTab = Window:CreateTab("🌍 Gravidade", 4483362458)

GravityTab:CreateSection("Controle de Gravidade")

GravityTab:CreateSlider({
   Name = "Gravidade",
   Range = {0, 500},
   Increment = 1,
   Suffix = "",
   CurrentValue = math.clamp(ORIGINAL_GRAVITY, 0, 500),
   Flag = "Gravity",
   Callback = function(Value)
      currentGravity = Value
      workspace.Gravity = Value
   end,
})

GravityTab:CreateButton({
   Name = "↩️ Resetar Gravidade (Original do Jogo)",
   Callback = function()
      workspace.Gravity = ORIGINAL_GRAVITY
      currentGravity = ORIGINAL_GRAVITY
      Rayfield:Notify({ Title = "Gravidade", Content = "Restaurada para " .. tostring(ORIGINAL_GRAVITY), Duration = 3 })
   end,
})

GravityTab:CreateParagraph({
   Title = "Info",
   Content = "Gravidade original do jogo: " .. tostring(ORIGINAL_GRAVITY) .. "\nMínimo: 0 | Máximo: 500"
})

-- ==================== TAB CONFIGS ====================
local ConfigsTab = Window:CreateTab("💾 Configs", 4483362458)

ConfigsTab:CreateSection("Salvar Nova Config")

configNameInput = ConfigsTab:CreateInput({
   Name = "Nome da Config",
   CurrentValue = "",
   PlaceholderText = "Ex: MinhaSetup",
   RemoveTextAfterFocusLost = false,
   Flag = "ConfigNameInput",
   Callback = function(Text) end,
})

ConfigsTab:CreateButton({
   Name = "💾 Salvar Config Atual",
   Callback = function()
      local name = ""
      pcall(function() name = tostring(configNameInput.CurrentValue or "") end)
      name = name:gsub("%s+", "")
      if name == "" or name == "(nenhuma config)" then
         Rayfield:Notify({ Title = "Erro", Content = "Digite um nome válido para a config", Duration = 3 })
         return
      end
      local data = getCurrentSettings()
      data.name = name
      data.created = os.time()
      if saveConfigToFile(name, data) then
         configs[name] = data
         selectedConfigName = name
         refreshConfigList()
         updateConfigInfo(name)
         Rayfield:Notify({ Title = "Config", Content = "Salva: " .. name, Duration = 3 })
      else
         Rayfield:Notify({ Title = "Erro", Content = "Não foi possível salvar (executor sem writefile?)", Duration = 4 })
      end
   end,
})

ConfigsTab:CreateSection("Configs Salvas")

loadAllConfigs()
local initialNames = {}
for name in pairs(configs) do table.insert(initialNames, name) end
table.sort(initialNames)
if #initialNames == 0 then initialNames = {"(nenhuma config)"} end

configDropdown = ConfigsTab:CreateDropdown({
   Name = "Selecionar Config",
   Options = initialNames,
   CurrentOption = {initialNames[1]},
   MultipleOptions = false,
   Flag = "SelectedConfig",
   Callback = function(Option)
      local name = type(Option) == "table" and Option[1] or Option
      if name and name ~= "(nenhuma config)" then
         selectedConfigName = name
         updateConfigInfo(name)
      else
         selectedConfigName = nil
         updateConfigInfo(nil)
      end
   end,
})

configInfoLabel = ConfigsTab:CreateParagraph({
   Title = "Nenhuma config selecionada",
   Content = "Salve ou selecione uma config"
})

ConfigsTab:CreateSection("Ações")

ConfigsTab:CreateButton({
   Name = "📂 Carregar Config",
   Callback = function()
      if not selectedConfigName or not configs[selectedConfigName] then
         Rayfield:Notify({ Title = "Erro", Content = "Selecione uma config válida", Duration = 3 })
         return
      end
      applySettings(configs[selectedConfigName])
      Rayfield:Notify({ Title = "Config", Content = "Carregada: " .. selectedConfigName, Duration = 3 })
   end,
})

ConfigsTab:CreateButton({
   Name = "🔄 Substituir pela Atual",
   Callback = function()
      if not selectedConfigName or selectedConfigName == "(nenhuma config)" then
         Rayfield:Notify({ Title = "Erro", Content = "Selecione uma config para substituir", Duration = 3 })
         return
      end
      local data = getCurrentSettings()
      data.name = selectedConfigName
      data.created = configs[selectedConfigName] and configs[selectedConfigName].created or os.time()
      if saveConfigToFile(selectedConfigName, data) then
         configs[selectedConfigName] = data
         updateConfigInfo(selectedConfigName)
         Rayfield:Notify({ Title = "Config", Content = "Substituída: " .. selectedConfigName, Duration = 3 })
      else
         Rayfield:Notify({ Title = "Erro", Content = "Falha ao substituir", Duration = 3 })
      end
   end,
})

ConfigsTab:CreateButton({
   Name = "✏️ Renomear Config",
   Callback = function()
      if not selectedConfigName or not configs[selectedConfigName] then
         Rayfield:Notify({ Title = "Erro", Content = "Selecione uma config para renomear", Duration = 3 })
         return
      end
      local newName = ""
      pcall(function() newName = tostring(configNameInput.CurrentValue or "") end)
      newName = newName:gsub("%s+", "")
      if newName == "" or newName == selectedConfigName then
         Rayfield:Notify({ Title = "Erro", Content = "Digite um nome novo no campo acima", Duration = 3 })
         return
      end
      local data = configs[selectedConfigName]
      data.name = newName
      if saveConfigToFile(newName, data) then
         deleteConfigFile(selectedConfigName)
         configs[newName] = data
         selectedConfigName = newName
         refreshConfigList()
         updateConfigInfo(newName)
         Rayfield:Notify({ Title = "Config", Content = "Renomeada para: " .. newName, Duration = 3 })
      else
         Rayfield:Notify({ Title = "Erro", Content = "Falha ao renomear", Duration = 3 })
      end
   end,
})

ConfigsTab:CreateButton({
   Name = "🗑️ Apagar Config",
   Callback = function()
      if not selectedConfigName or not configs[selectedConfigName] then
         Rayfield:Notify({ Title = "Erro", Content = "Selecione uma config para apagar", Duration = 3 })
         return
      end
      local name = selectedConfigName
      deleteConfigFile(name)
      selectedConfigName = nil
      refreshConfigList()
      updateConfigInfo(nil)
      Rayfield:Notify({ Title = "Config", Content = "Apagada: " .. name, Duration = 3 })
   end,
})

ConfigsTab:CreateButton({
   Name = "🔄 Atualizar Lista",
   Callback = function()
      refreshConfigList()
      Rayfield:Notify({ Title = "Configs", Content = "Lista atualizada", Duration = 2 })
   end,
})

-- ==================== TAB AJUSTES ====================
local SettingsTab = Window:CreateTab("⚙️ Ajustes", 4483362458)

SettingsTab:CreateSection("Tecla do Menu (Rayfield)")

SettingsTab:CreateParagraph({
   Title = "ToggleUIKeybind",
   Content = "A tecla padrão para abrir/fechar o menu é: J\n(definida no ToggleUIKeybind do Rayfield)"
})

menuKeyBtn = SettingsTab:CreateButton({
   Name = "⌨️ Tecla Menu Extra: [" .. menuKey.Name .. "]",
   Callback = function()
      Rayfield:Notify({ Title = "Aguardando tecla...", Content = "Pressione a tecla ou botão do controle", Duration = 4 })
      isBindingKey = true
      bindingType = "menu"
   end,
})

SettingsTab:CreateSection("Tamanho do Menu")

SettingsTab:CreateSlider({
   Name = "Escala do Menu",
   Range = {0.5, 2},
   Increment = 0.05,
   Suffix = "x",
   CurrentValue = 1,
   Flag = "MenuScale",
   Callback = function(Value)
      menuScale = Value
      pcall(function()
         local main = nil
         for _, gui in ipairs({game:GetService("CoreGui"), playerGui}) do
            local rf = gui:FindFirstChild("Rayfield") or gui:FindFirstChild("RayfieldLibrary")
            if rf then
               main = rf:FindFirstChild("Main", true)
               if main then break end
            end
         end
         if main and main:IsA("GuiObject") then
            main.Size = UDim2.new(0, math.floor(500 * Value), 0, math.floor(350 * Value))
         end
      end)
   end,
})

SettingsTab:CreateParagraph({
   Title = "Informações",
   Content = "• Nitro: força + partículas NitroFire\n• Cores: use o seletor de cor (preview)\n• Pneu: FR/FL/RR/RL → Wheel\n• Tecla padrão do menu: J\n• Suporte a teclado + controle\n• Configs são salvas na pasta ControlHub/Configs"
})

-- ─────────────────────────────────────────────
-- INPUT CONNECTIONS
-- ─────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if isBindingKey and (input.UserInputType == Enum.UserInputType.Keyboard
        or input.UserInputType == Enum.UserInputType.Gamepad1
        or input.UserInputType == Enum.UserInputType.Gamepad2) then

        if bindingType == "nitro" then
            nitroKey = input.KeyCode
            pcall(function() nitroKeyBtn:Set("⌨️ Tecla Nitro: [" .. nitroKey.Name .. "]") end)
            Rayfield:Notify({ Title = "Tecla definida", Content = "Nitro: " .. nitroKey.Name, Duration = 3 })
        elseif bindingType == "jump" then
            jumpKey = input.KeyCode
            pcall(function() jumpKeyBtn:Set("⌨️ Tecla Pulo: [" .. jumpKey.Name .. "]") end)
            Rayfield:Notify({ Title = "Tecla definida", Content = "Pulo: " .. jumpKey.Name, Duration = 3 })
        elseif bindingType == "menu" then
            menuKey = input.KeyCode
            pcall(function() menuKeyBtn:Set("⌨️ Tecla Menu Extra: [" .. menuKey.Name .. "]") end)
            Rayfield:Notify({ Title = "Tecla definida", Content = "Menu Extra: " .. menuKey.Name, Duration = 3 })
        end
        isBindingKey = false
        bindingType = nil
        return
    end

    if gameProcessed then return end

    if input.KeyCode == nitroKey and nitroEnabled then
        local ok = startBoost()
        if not ok then
            Rayfield:Notify({ Title = "Nitro", Content = "Entre no veículo!", Duration = 2 })
        end
    end

    if input.KeyCode == jumpKey and jumpEnabled then
        local ok = applyJump()
        if not ok then
            Rayfield:Notify({ Title = "Pulo", Content = "Entre no veículo!", Duration = 2 })
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == nitroKey then
        stopBoost()
    end
end)

task.spawn(function()
    task.wait(0.5)
    refreshConfigList()
end)

Rayfield:Notify({
   Title = "Control Hub",
   Content = "Carregado com sucesso! ⚡  |  Tecla do menu: J",
   Duration = 4
})
