--[[
    ⚡ CONTROL HUB - Rayfield Edition
    Nitro | Pulo | Pneu | Ajustes
    + Partículas NitroFire + cores hex + suporte a controle
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
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
    local dragging, dragStart, startPos, moved
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
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
                moved = true
                guiObject.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- ScreenGui só para os botões flutuantes
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
    local particles = getNitroParticles()
    for _, pe in ipairs(particles) do
        pe.Enabled = enabled
        if enabled then
            applyNitroColors()
        end
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
    stopBoost()
    local root = getVehicleRoot()
    if not root then
        return false
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
    local count = setNitroParticlesEnabled(true)
    isBoosting = true
    boostConn = RunService.Heartbeat:Connect(function()
        if not isBoosting then stopBoost() return end
        local r = getVehicleRoot()
        if not r or not activeForce then stopBoost() return end
        activeForce.Force = r.CFrame.LookVector * BOOST_FORCE
    end)
    return true, count
end

local function applyJump()
    local root = getVehicleRoot()
    if not root then
        return false
    end
    root:ApplyImpulse(Vector3.new(0, JUMP_FORCE * 80, 0))
    return true
end

local function applyWheelMaterial()
    local car = getCarModel()
    if not car then
        return 0
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
    return count, mat.Name
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
   LoadingTitle = "Control Hub",
   LoadingSubtitle = "Nitro | Pulo | Pneu | Ajustes",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "ControlHub",
      FileName = "Config"
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

-- ==================== TAB NITRO ====================
local NitroTab = Window:CreateTab("⚡ Nitro", 4483362458)

NitroTab:CreateSection("Força do Nitro")

NitroTab:CreateInput({
   Name = "Força do Nitro (100 - 1M)",
   CurrentValue = tostring(BOOST_FORCE),
   PlaceholderText = "25000",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local v = tonumber(Text)
      if v then
         BOOST_FORCE = math.clamp(v, 100, 1000000)
         Rayfield:Notify({
            Title = "Nitro",
            Content = "Força definida: " .. BOOST_FORCE,
            Duration = 2
         })
      end
   end,
})

NitroTab:CreateSection("Cores das Partículas")

NitroTab:CreateInput({
   Name = "Cor Nitro 1 (#RRGGBB)",
   CurrentValue = nitroColor1Hex,
   PlaceholderText = "#FF5500",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      if not Text:match("^#") then Text = "#" .. Text end
      local c = hexToColor3(Text)
      if c then
         nitroColor1Hex = Text:upper()
         applyNitroColors()
         Rayfield:Notify({
            Title = "Cor 1",
            Content = "Aplicada: " .. nitroColor1Hex,
            Duration = 2
         })
      else
         Rayfield:Notify({
            Title = "Erro",
            Content = "Hex inválido. Use #RRGGBB",
            Duration = 3
         })
      end
   end,
})

NitroTab:CreateInput({
   Name = "Cor Nitro 2 (#RRGGBB)",
   CurrentValue = nitroColor2Hex,
   PlaceholderText = "#FFAA00",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      if not Text:match("^#") then Text = "#" .. Text end
      local c = hexToColor3(Text)
      if c then
         nitroColor2Hex = Text:upper()
         applyNitroColors()
         Rayfield:Notify({
            Title = "Cor 2",
            Content = "Aplicada: " .. nitroColor2Hex,
            Duration = 2
         })
      else
         Rayfield:Notify({
            Title = "Erro",
            Content = "Hex inválido. Use #RRGGBB",
            Duration = 3
         })
      end
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
         Rayfield:Notify({
            Title = "Botão Nitro",
            Content = "Removido",
            Duration = 2
         })
      else
         createFloatingButton("FloatingNitro", "⚡", Color3.fromRGB(230, 120, 0), function(state)
            if state then
               local ok, count = startBoost()
               if not ok then
                  Rayfield:Notify({
                     Title = "Nitro",
                     Content = "Entre no veículo!",
                     Duration = 3
                  })
               end
            else
               stopBoost()
            end
         end, true)
         nitroBtnExists = true
         Rayfield:Notify({
            Title = "Botão Nitro",
            Content = "Criado (arraste para mover)",
            Duration = 2
         })
      end
   end,
})

NitroTab:CreateButton({
   Name = "⌨️ Definir Tecla do Nitro",
   Callback = function()
      Rayfield:Notify({
         Title = "Aguardando tecla...",
         Content = "Pressione a tecla ou botão do controle",
         Duration = 4
      })
      isBindingKey = true
      bindingType = "nitro"
   end,
})

-- ==================== TAB PULO ====================
local JumpTab = Window:CreateTab("🦘 Pulo", 4483362458)

JumpTab:CreateSection("Poder do Pulo")

JumpTab:CreateInput({
   Name = "Poder do Pulo (0 - 5000)",
   CurrentValue = tostring(JUMP_FORCE),
   PlaceholderText = "2000",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local v = tonumber(Text)
      if v then
         JUMP_FORCE = math.clamp(v, 0, 5000)
         Rayfield:Notify({
            Title = "Pulo",
            Content = "Força definida: " .. JUMP_FORCE,
            Duration = 2
         })
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
         Rayfield:Notify({
            Title = "Botão Pulo",
            Content = "Removido",
            Duration = 2
         })
      else
         createFloatingButton("FloatingJump", "🦘", Color3.fromRGB(0, 150, 220), function()
            local ok = applyJump()
            if not ok then
               Rayfield:Notify({
                  Title = "Pulo",
                  Content = "Entre no veículo!",
                  Duration = 3
               })
            else
               Rayfield:Notify({
                  Title = "Pulo",
                  Content = "Aplicado!",
                  Duration = 1.5
               })
            end
         end, false)
         jumpBtnExists = true
         Rayfield:Notify({
            Title = "Botão Pulo",
            Content = "Criado (arraste para mover)",
            Duration = 2
         })
      end
   end,
})

JumpTab:CreateButton({
   Name = "⌨️ Definir Tecla do Pulo",
   Callback = function()
      Rayfield:Notify({
         Title = "Aguardando tecla...",
         Content = "Pressione a tecla ou botão do controle",
         Duration = 4
      })
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
   Callback = function(Option)
      local selected = Option[1] or Option
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
         Rayfield:Notify({
            Title = "Pneu",
            Content = "Material " .. matName .. " aplicado em " .. count .. " roda(s)!",
            Duration = 3
         })
      else
         Rayfield:Notify({
            Title = "Pneu",
            Content = "Entre no veículo ou não encontrei FR/FL/RR/RL → Wheel",
            Duration = 4
         })
      end
   end,
})

PneuTab:CreateParagraph({
   Title = "Como funciona",
   Content = "Procura: FR / FL / RR / RL → Wheel\nEntre no veículo e clique Aplicar."
})

-- ==================== TAB AJUSTES ====================
local SettingsTab = Window:CreateTab("⚙️ Ajustes", 4483362458)

SettingsTab:CreateSection("Tecla do Menu")

SettingsTab:CreateButton({
   Name = "⌨️ Definir Tecla do Menu",
   Callback = function()
      Rayfield:Notify({
         Title = "Aguardando tecla...",
         Content = "Pressione a tecla ou botão do controle",
         Duration = 4
      })
      isBindingKey = true
      bindingType = "menu"
   end,
})

SettingsTab:CreateParagraph({
   Title = "Informações",
   Content = "• Nitro: força + partículas NitroFire do jogo\n  (Body → Exhaust → ExhaustPart → NitroFire)\n\n• Cores: digite #RRGGBB (ex: #00FFFF)\n\n• Pneu: FR/FL/RR/RL → Wheel\n\n• Tecla padrão do menu: J\n• Suporte a teclado + controle"
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
            Rayfield:Notify({
               Title = "Tecla definida",
               Content = "Nitro: " .. nitroKey.Name,
               Duration = 3
            })
        elseif bindingType == "jump" then
            jumpKey = input.KeyCode
            Rayfield:Notify({
               Title = "Tecla definida",
               Content = "Pulo: " .. jumpKey.Name,
               Duration = 3
            })
        elseif bindingType == "menu" then
            menuKey = input.KeyCode
            Rayfield:Notify({
               Title = "Tecla definida",
               Content = "Menu: " .. menuKey.Name,
               Duration = 3
            })
        end
        isBindingKey = false
        bindingType = nil
        return
    end

    if gameProcessed then return end

    if input.KeyCode == menuKey then
        -- Rayfield já tem toggle próprio, mas mantemos a tecla se quiser
        -- (o Rayfield abre/fecha com a tecla dele normalmente)
    end

    if input.KeyCode == nitroKey then
        local ok = startBoost()
        if not ok then
            Rayfield:Notify({
               Title = "Nitro",
               Content = "Entre no veículo!",
               Duration = 2
            })
        end
    end

    if input.KeyCode == jumpKey then
        local ok = applyJump()
        if not ok then
            Rayfield:Notify({
               Title = "Pulo",
               Content = "Entre no veículo!",
               Duration = 2
            })
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == nitroKey then
        stopBoost()
    end
end)

Rayfield:Notify({
   Title = "Control Hub",
   Content = "Carregado com sucesso! ⚡",
   Duration = 4
})
