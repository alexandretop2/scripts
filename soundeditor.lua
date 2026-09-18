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
local CustomIDs = {}       -- IDs customizados gravados pelo usuário
local OffStates = {}       -- Controla quais sons estão OFF
local Connections = {}     -- Guardador de conexões GetPropertyChangedSignal
local CurrentCarModel = nil

-- Função para buscar o carro pertencente ao jogador
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

-- Limpar conexões antigas ao trocar de carro
local function ClearConnections()
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
    Connections = {}
end

-- Forçar aplicação e interceptação de scripts que tentam restaurar o som
local function ApplySoundOverride(soundObj, targetId)
    if not soundObj then return end
    
    local key = soundObj:GetFullName()
    if Connections[key] then
        Connections[key]:Disconnect()
        Connections[key] = nil
    end

    soundObj.SoundId = targetId
    if targetId == "rbxassetid://0" then
        soundObj:Stop()
    else
        soundObj:Play()
    end

    -- Hook: Monitora se o script do carro alterar o SoundId de volta
    Connections[key] = soundObj:GetPropertyChangedSignal("SoundId"):Connect(function()
        if OffStates[key] and soundObj.SoundId ~= "rbxassetid://0" then
            soundObj.SoundId = "rbxassetid://0"
            soundObj:Stop()
        elseif CustomIDs[key] and soundObj.SoundId ~= "rbxassetid://" .. CustomIDs[key] then
            soundObj.SoundId = "rbxassetid://" .. CustomIDs[key]
        end
    end)
end

-- Criar a UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarSoundManagerGui"
screenGui.ResetOnSpawn = false

pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 360)
mainFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "🔊 GERENCIADOR DE SONS"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Botões de Abas
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0.9, 0, 0, 30)
tabFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
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

-- Descrição da Aba
local descLabel = Instance.new("TextLabel")
descLabel.Size = UDim2.new(0.9, 0, 0, 20)
descLabel.Position = UDim2.new(0.05, 0, 0.19, 0)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Sons principais localizados no bloco 'Engine' do carro."
descLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
descLabel.TextSize = 10
descLabel.Font = Enum.Font.SourceSansItalic
descLabel.Parent = mainFrame

-- Containers Scrolling
local primaryScroll = Instance.new("ScrollingFrame")
primaryScroll.Size = UDim2.new(0.9, 0, 0, 210)
primaryScroll.Position = UDim2.new(0.05, 0, 0.26, 0)
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
secondaryScroll.Size = UDim2.new(0.9, 0, 0, 210)
secondaryScroll.Position = UDim2.new(0.05, 0, 0.26, 0)
secondaryScroll.BackgroundTransparency = 1
secondaryScroll.BorderSizePixel = 0
secondaryScroll.ScrollBarThickness = 4
secondaryScroll.Visible = false
secondaryScroll.Parent = mainFrame

local sLayout = Instance.new("UIListLayout")
sLayout.SortOrder = Enum.SortOrder.LayoutOrder
sLayout.Padding = UDim.new(0, 6)
sLayout.Parent = secondaryScroll

-- Alternar entre Abas
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

-- Criar Linha de Item
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
    nameLabel.Size = UDim2.new(0.28, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0.03, 0, 0.25, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = soundObj.Name
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.38, 0, 0.65, 0)
    textBox.Position = UDim2.new(0.31, 0, 0.175, 0)
    textBox.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "ID do som"
    textBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
    textBox.Text = CustomIDs[soundKey] or soundObj.SoundId:gsub("%D", "")
    textBox.TextSize = 11
    textBox.Font = Enum.Font.SourceSans
    textBox.ClearTextOnFocus = false
    textBox.Parent = row

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 4)
    tbCorner.Parent = textBox

    local applyBtn = Instance.new("TextButton")
    applyBtn.Size = UDim2.new(0.12, 0, 0.65, 0)
    applyBtn.Position = UDim2.new(0.70, 0, 0.175, 0)
    applyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Text = "OK"
    applyBtn.TextSize = 11
    applyBtn.Font = Enum.Font.SourceSansBold
    applyBtn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = applyBtn

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.14, 0, 0.65, 0)
    toggleBtn.Position = UDim2.new(0.83, 0, 0.175, 0)
    
    if OffStates[soundKey] then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        toggleBtn.Text = "OFF"
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        toggleBtn.Text = "ON"
    end
    
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 11
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.Parent = row

    local togCorner = Instance.new("UICorner")
    togCorner.CornerRadius = UDim.new(0, 4)
    togCorner.Parent = toggleBtn

    -- Lógica OK
    applyBtn.MouseButton1Click:Connect(function()
        local cleanId = textBox.Text:gsub("%D", "")
        if cleanId ~= "" then
            CustomIDs[soundKey] = cleanId
            if not OffStates[soundKey] then
                ApplySoundOverride(soundObj, "rbxassetid://" .. cleanId)
            end
            applyBtn.Text = "✓"
            task.wait(1)
            applyBtn.Text = "OK"
        end
    end)

    -- Lógica ON/OFF
    toggleBtn.MouseButton1Click:Connect(function()
        if not OffStates[soundKey] then
            OffStates[soundKey] = true
            toggleBtn.Text = "OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            ApplySoundOverride(soundObj, "rbxassetid://0")
        else
            OffStates[soundKey] = false
            toggleBtn.Text = "ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            
            local cleanId = textBox.Text:gsub("%D", "")
            if cleanId ~= "" and cleanId ~= "0" then
                ApplySoundOverride(soundObj, "rbxassetid://" .. cleanId)
            else
                ApplySoundOverride(soundObj, soundObj.SoundId)
            end
        end
    end)
end

-- Recarregar Sons do Carro / PlayerScripts
local function ReloadAllSounds()
    local car = GetPlayerCar()
    if not car then return end

    if CurrentCarModel ~= car then
        CurrentCarModel = car
        ClearConnections()
        CustomIDs = {}
        OffStates = {}
    end

    -- Limpa lista das abas
    for _, child in ipairs(primaryScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, child in ipairs(secondaryScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- 1. Sons PRIMÁRIOS (Tudo dentro do bloco Engine)
    local engineBlock = car:FindFirstChild("Engine", true)
    if engineBlock then
        for _, obj in ipairs(engineBlock:GetChildren()) do
            if obj:IsA("Sound") then
                CreateRow(obj, primaryScroll)
            end
        end
    end

    -- 2. Sons SECUNDÁRIOS (Sons do PlayerScripts/Sounds)
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

-- Conectar evento ao sentar
local function SetupSeatedListener()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    humanoid.Seated:Connect(function(isSeated, seat)
        if isSeated and seat and seat:IsA("VehicleSeat") then
            task.wait(0.3)
            ReloadAllSounds()
        end
    end)
end

if LocalPlayer.Character then SetupSeatedListener() end
LocalPlayer.CharacterAdded:Connect(SetupSeatedListener)

ReloadAllSounds()

-- Rodapé
local footerLabel = Instance.new("TextLabel")
footerLabel.Size = UDim2.new(1, 0, 0, 20)
footerLabel.Position = UDim2.new(0, 0, 0.92, 0)
footerLabel.BackgroundTransparency = 1
footerLabel.Text = "Atalho PC: Tecla [F]"
footerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
footerLabel.TextSize = 10
footerLabel.Font = Enum.Font.SourceSans
footerLabel.Parent = mainFrame

-- Botão Flutuante Mobile
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

local function ToggleGui()
    mainFrame.Visible = not mainFrame.Visible
end

mobileBtn.MouseButton1Click:Connect(ToggleGui)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        ToggleGui()
    end
end)
