-- LocalScript - Executável via Xeno (Client-Side)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Deletar interface antiga se já existir
local oldGui = CoreGui:FindFirstChild("CarSoundManagerGui") or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CarSoundManagerGui")
if oldGui then
    oldGui:Destroy()
end

-- Estados e Tabelas Globais
local CustomIDs = {}       -- IDs customizados
local CustomVolumes = {}   -- Volumes customizados (0 - 10)
local OffStates = {}       -- Controla se o som está em OFF
local Connections = {}     -- Conexões de escuta dos sons
local CurrentCarModel = nil
local ToggleKey = Enum.KeyCode.F -- Tecla padrão para PC
local ListeningForKey = false

-- Buscar o carro do jogador
local function GetPlayerCar()
    local carsFolder = workspace:FindFirstChild("Cars")
    if not carsFolder then return nil end

    for _, car in ipairs(carsFolder:GetChildren()) do
        if car:IsA("Model") then
            local stats = car:FindFirstChild("Stats")
            if stats then
                local ownerVal = stats:FindFirstChild("Owner")
                if ownerVal and tostring(ownerVal.Value) == LocalPlayer.Name then
                    return car
                end
            end
        end
    end
    return nil
end

-- Limpar conexões antigas
local function ClearConnections()
    for _, conn in pairs(Connections) do
        if conn and conn.Disconnect then conn:Disconnect() end
    end
    Connections = {}
end

-- Aplicação com suporte a Volume e ID (Sem auto-play/prévia)
local function ApplySoundOverride(soundObj)
    if not soundObj then return end
    
    local key = soundObj:GetFullName()
    
    if Connections[key] then
        Connections[key]:Disconnect()
        Connections[key] = nil
    end

    if OffStates[key] then
        soundObj.SoundId = "rbxassetid://0"
        soundObj:Stop()
    else
        if CustomIDs[key] then
            soundObj.SoundId = "rbxassetid://" .. CustomIDs[key]
        end
        if CustomVolumes[key] then
            soundObj.Volume = CustomVolumes[key]
        end
    end

    local connId = soundObj:GetPropertyChangedSignal("SoundId"):Connect(function()
        if OffStates[key] and soundObj.SoundId ~= "rbxassetid://0" then
            soundObj.SoundId = "rbxassetid://0"
            soundObj:Stop()
        elseif CustomIDs[key] and soundObj.SoundId ~= "rbxassetid://" .. CustomIDs[key] then
            soundObj.SoundId = "rbxassetid://" .. CustomIDs[key]
        end
    end)

    local connVol = soundObj:GetPropertyChangedSignal("Volume"):Connect(function()
        if not OffStates[key] and CustomVolumes[key] and soundObj.Volume ~= CustomVolumes[key] then
            soundObj.Volume = CustomVolumes[key]
        end
    end)

    Connections[key] = {
        Disconnect = function()
            connId:Disconnect()
            connVol:Disconnect()
        end
    }
end

-- Pausar TODOS os sons secundários ao sair do carro
local function StopSecondarySounds()
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if playerScripts then
        local soundsFolder = playerScripts:FindFirstChild("Sounds")
        if soundsFolder then
            for _, obj in ipairs(soundsFolder:GetChildren()) do
                if obj:IsA("Sound") then
                    obj:Stop()
                end
            end
        end
    end
end

-- Interface Principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarSoundManagerGui"
screenGui.ResetOnSpawn = false

pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 360, 0, 360)
mainFrame.Position = UDim2.new(0.5, -180, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "🔊 GERENCIADOR DE SONS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Abas
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0.92, 0, 0, 30)
tabFrame.Position = UDim2.new(0.04, 0, 0.1, 0)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local primaryTabBtn = Instance.new("TextButton")
primaryTabBtn.Size = UDim2.new(0.48, 0, 1, 0)
primaryTabBtn.Position = UDim2.new(0, 0, 0, 0)
primaryTabBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
primaryTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
primaryTabBtn.Text = "Primários (Carro)"
primaryTabBtn.TextSize = 11
primaryTabBtn.Font = Enum.Font.SourceSansBold
primaryTabBtn.Parent = tabFrame

local pTabCorner = Instance.new("UICorner")
pTabCorner.CornerRadius = UDim.new(0, 6)
pTabCorner.Parent = primaryTabBtn

local secondaryTabBtn = Instance.new("TextButton")
secondaryTabBtn.Size = UDim2.new(0.48, 0, 1, 0)
secondaryTabBtn.Position = UDim2.new(0.52, 0, 0, 0)
secondaryTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
secondaryTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
secondaryTabBtn.Text = "Secundários (Outros)"
secondaryTabBtn.TextSize = 11
secondaryTabBtn.Font = Enum.Font.SourceSansBold
secondaryTabBtn.Parent = tabFrame

local sTabCorner = Instance.new("UICorner")
sTabCorner.CornerRadius = UDim.new(0, 6)
sTabCorner.Parent = secondaryTabBtn

local descLabel = Instance.new("TextLabel")
descLabel.Size = UDim2.new(0.92, 0, 0, 20)
descLabel.Position = UDim2.new(0.04, 0, 0.19, 0)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Sons principais localizados no bloco 'Engine' do carro."
descLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
descLabel.TextSize = 10
descLabel.Font = Enum.Font.SourceSansItalic
descLabel.Parent = mainFrame

-- Lists
local primaryScroll = Instance.new("ScrollingFrame")
primaryScroll.Size = UDim2.new(0.92, 0, 0, 210)
primaryScroll.Position = UDim2.new(0.04, 0, 0.26, 0)
primaryScroll.BackgroundTransparency = 1
primaryScroll.BorderSizePixel = 0
primaryScroll.ScrollBarThickness = 4
primaryScroll.Visible = true
primaryScroll.Parent = mainFrame

local pLayout = Instance.new("UIListLayout")
pLayout.SortOrder = Enum.SortOrder.LayoutOrder
pLayout.Padding = UDim.new(0, 6)
pLayout.Parent = primaryScroll

local secondaryScroll = Instance.new("ScrollingFrame")
secondaryScroll.Size = UDim2.new(0.92, 0, 0, 210)
secondaryScroll.Position = UDim2.new(0.04, 0, 0.26, 0)
secondaryScroll.BackgroundTransparency = 1
secondaryScroll.BorderSizePixel = 0
secondaryScroll.ScrollBarThickness = 4
secondaryScroll.Visible = false
secondaryScroll.Parent = mainFrame

local sLayout = Instance.new("UIListLayout")
sLayout.SortOrder = Enum.SortOrder.LayoutOrder
sLayout.Padding = UDim.new(0, 6)
sLayout.Parent = secondaryScroll

primaryTabBtn.MouseButton1Click:Connect(function()
    primaryScroll.Visible = true
    secondaryScroll.Visible = false
    primaryTabBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    secondaryTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    descLabel.Text = "Sons principais localizados no bloco 'Engine' do carro."
end)

secondaryTabBtn.MouseButton1Click:Connect(function()
    primaryScroll.Visible = false
    secondaryScroll.Visible = true
    secondaryTabBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    primaryTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    descLabel.Text = "Sons secundários do jogo (ex: PlayerScripts.Sounds)."
end)

-- Linha de Configuração do Som
local function CreateRow(soundObj, parentScroll)
    local soundKey = soundObj:GetFullName()

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 40)
    row.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    row.BorderSizePixel = 0
    row.Parent = parentScroll

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.24, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0.02, 0, 0.25, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = soundObj.Name
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local idBox = Instance.new("TextBox")
    idBox.Size = UDim2.new(0.32, 0, 0.65, 0)
    idBox.Position = UDim2.new(0.27, 0, 0.175, 0)
    idBox.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    idBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    idBox.PlaceholderText = "ID Áudio"
    idBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
    idBox.Text = CustomIDs[soundKey] or soundObj.SoundId:gsub("%D", "")
    idBox.TextSize = 10
    idBox.Font = Enum.Font.SourceSans
    idBox.ClearTextOnFocus = false
    idBox.Parent = row

    local idCorner = Instance.new("UICorner")
    idCorner.CornerRadius = UDim.new(0, 4)
    idCorner.Parent = idBox

    local volBox = Instance.new("TextBox")
    volBox.Size = UDim2.new(0.15, 0, 0.65, 0)
    volBox.Position = UDim2.new(0.60, 0, 0.175, 0)
    volBox.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    volBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    volBox.PlaceholderText = "Vol(0-10)"
    volBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
    volBox.Text = tostring(CustomVolumes[soundKey] or math.clamp(soundObj.Volume, 0, 10))
    volBox.TextSize = 10
    volBox.Font = Enum.Font.SourceSans
    volBox.ClearTextOnFocus = false
    volBox.Parent = row

    local volCorner = Instance.new("UICorner")
    volCorner.CornerRadius = UDim.new(0, 4)
    volCorner.Parent = volBox

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0.10, 0, 0.65, 0)
    applyBtn.Position = UDim2.new(0.76, 0, 0.175, 0)
    applyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Text = "OK"
    applyBtn.TextSize = 10
    applyBtn.Font = Enum.Font.SourceSansBold
    applyBtn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = applyBtn

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.11, 0, 0.65, 0)
    toggleBtn.Position = UDim2.new(0.87, 0, 0.175, 0)
    
    if OffStates[soundKey] then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        toggleBtn.Text = "OFF"
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        toggleBtn.Text = "ON"
    end
    
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 10
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.Parent = row

    local togCorner = Instance.new("UICorner")
    togCorner.CornerRadius = UDim.new(0, 4)
    togCorner.Parent = toggleBtn

    applyBtn.MouseButton1Click:Connect(function()
        local cleanId = idBox.Text:gsub("%D", "")
        local volVal = tonumber(volBox.Text)

        if cleanId ~= "" then
            CustomIDs[soundKey] = cleanId
        end

        if volVal then
            volVal = math.clamp(volVal, 0, 10)
            CustomVolumes[soundKey] = volVal
            volBox.Text = tostring(volVal)
        end

        ApplySoundOverride(soundObj)

        applyBtn.Text = "✓"
        task.wait(0.8)
        applyBtn.Text = "OK"
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        if not OffStates[soundKey] then
            OffStates[soundKey] = true
            toggleBtn.Text = "OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        else
            OffStates[soundKey] = false
            toggleBtn.Text = "ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        end
        ApplySoundOverride(soundObj)
    end)
end

-- Recarregar interface ao trocar de carro
local function ReloadAllSounds()
    local car = GetPlayerCar()
    if not car then return end

    if CurrentCarModel ~= car then
        CurrentCarModel = car
        ClearConnections()
        CustomIDs = {}
        CustomVolumes = {}
        OffStates = {}
    end

    for _, child in ipairs(primaryScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, child in ipairs(secondaryScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- 1. PRIMÁRIOS (Engine)
    local engineBlock = car:FindFirstChild("Engine", true)
    if engineBlock then
        for _, obj in ipairs(engineBlock:GetChildren()) do
            if obj:IsA("Sound") then
                CreateRow(obj, primaryScroll)
            end
        end
    end

    -- 2. SECUNDÁRIOS (PlayerScripts.Sounds)
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if playerScripts then
        local soundsFolder = playerScripts:FindFirstChild("Sounds")
        if soundsFolder then
            for _, obj in ipairs(soundsFolder:GetChildren()) do
                if obj:IsA("Sound") then
                    CreateRow(obj, secondaryScroll)
                end
            end
        end
    end

    primaryScroll.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 10)
    secondaryScroll.CanvasSize = UDim2.new(0, 0, 0, sLayout.AbsoluteContentSize.Y + 10)
end

-- Conexão ao sentar e levantar do carro
local function SetupSeatedListener()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    humanoid.Seated:Connect(function(isSeated, seat)
        if isSeated and seat and seat:IsA("VehicleSeat") then
            task.wait(0.3)
            ReloadAllSounds()
        else
            StopSecondarySounds()
        end
    end)
end

if LocalPlayer.Character then SetupSeatedListener() end
LocalPlayer.CharacterAdded:Connect(SetupSeatedListener)

ReloadAllSounds()

-- Rodapé com Botão para Mudar a Tecla de Atalho
local keyBindBtn = Instance.new("TextButton")
keyBindBtn.Size = UDim2.new(0.92, 0, 0, 22)
keyBindBtn.Position = UDim2.new(0.04, 0, 0.91, 0)
keyBindBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
keyBindBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
keyBindBtn.Text = "Atalho PC: [" .. ToggleKey.Name .. "] (Clique para Mudar)"
keyBindBtn.TextSize = 10
keyBindBtn.Font = Enum.Font.SourceSans
keyBindBtn.Parent = mainFrame

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 4)
keyCorner.Parent = keyBindBtn

keyBindBtn.MouseButton1Click:Connect(function()
    if ListeningForKey then return end
    ListeningForKey = true
    keyBindBtn.Text = "Pressione qualquer tecla..."
    keyBindBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
end)

-- Apenas criar o botão flutuante se for dispositivo MÓVEL
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name = "MobileToggle"
    mobileBtn.Size = UDim2.new(0, 45, 0, 45)
    mobileBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
    mobileBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mobileBtn.Text = "🔊"
    mobileBtn.TextSize = 20
    mobileBtn.Active = true
    mobileBtn.Draggable = true
    mobileBtn.Parent = screenGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(1, 0)
    floatCorner.Parent = mobileBtn

    mobileBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
end

-- Detecção de Teclas no Teclado
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Se estiver aguardando para trocar a tecla
    if ListeningForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            ToggleKey = input.KeyCode
            keyBindBtn.Text = "Atalho PC: [" .. ToggleKey.Name .. "] (Clique para Mudar)"
            keyBindBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
            task.wait(0.1)
            ListeningForKey = false
        end
        return
    end

    if gameProcessed then return end

    -- Abrir/Fechar menu com a tecla configurada
    if input.KeyCode == ToggleKey then
        mainFrame.Visible = not mainFrame.Visible
    end
end)
