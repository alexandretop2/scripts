-- LocalScript - Executável via Xeno (Client-Side)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- DELETAR INTERFACE ANTIGA SE JÁ EXISTIR
local oldGui = CoreGui:FindFirstChild("CarSoundManagerGui") or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CarSoundManagerGui")
if oldGui then
    oldGui:Destroy()
end

-- Lista base de sons conhecidos
local BASE_SOUND_NAMES = {"Rev", "Horn", "NitroSound", "Shift", "StartUp", "Supercharger"}
local SOUND_NAMES = {}

-- Tabelas de estado do veículo
local OriginalIDs = {}
local UI_Rows = {}
local CurrentCarModel = nil

-- Limpar listas para um novo carro
local function ClearSoundData()
    OriginalIDs = {}
    SOUND_NAMES = {table.unpack(BASE_SOUND_NAMES)}
    
    for sName, rowData in pairs(UI_Rows) do
        if rowData.Frame then
            rowData.Frame:Destroy()
        end
    end
    UI_Rows = {}
end

-- Função para buscar o carro pertencente ao jogador em workspace.Cars
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

-- Localizar o objeto de som
local function FindSoundObject(soundName)
    if soundName == "Supercharger" then
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if playerScripts then
            local soundsFolder = playerScripts:FindFirstChild("Sounds")
            if soundsFolder then
                local scSound = soundsFolder:FindFirstChild("Supercharger")
                if scSound and scSound:IsA("Sound") then
                    return scSound
                end
            end
        end
    end

    local car = GetPlayerCar()
    if car then
        local soundObj = car:FindFirstChild(soundName, true)
        if soundObj and soundObj:IsA("Sound") then
            return soundObj
        end
    end

    return nil
end

-- Escanear sons adicionais do carro
local function DetectCarSounds(car)
    if not car then return end
    for _, obj in ipairs(car:GetDescendants()) do
        if obj:IsA("Sound") then
            if not table.find(SOUND_NAMES, obj.Name) then
                table.insert(SOUND_NAMES, obj.Name)
            end
        end
    end
end

-- Forçar atualização instantânea do áudio na memória do jogo
local function ForceSoundUpdate(soundObj, newId)
    local wasPlaying = soundObj.IsPlaying
    soundObj:Stop()
    soundObj.SoundId = newId
    task.wait(0.05)
    if wasPlaying or soundObj.Name == "Rev" then
        soundObj:Play()
    end
end

-- Interface Principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarSoundManagerGui"
screenGui.ResetOnSpawn = false

pcall(function()
    screenGui.Parent = CoreGui
end)
if not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 310, 0, 340)
mainFrame.Position = UDim2.new(0.5, -155, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = true
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

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.92, 0, 0, 250)
scroll.Position = UDim2.new(0.04, 0, 0.12, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scroll

-- Criar linha para cada som
local function CreateSoundRow(soundName)
    if UI_Rows[soundName] then return end

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(38, 38, 45)
    row.BorderSizePixel = 0
    row.Parent = scroll

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.28, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0.03, 0, 0.25, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = soundName
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.38, 0, 0.65, 0)
    textBox.Position = UDim2.new(0.31, 0, 0.175, 0)
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderText = "ID do som"
    textBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
    textBox.Text = ""
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

    local toggleSoundBtn = Instance.new("TextButton")
    toggleSoundBtn.Size = UDim2.new(0.14, 0, 0.65, 0)
    toggleSoundBtn.Position = UDim2.new(0.83, 0, 0.175, 0)
    toggleSoundBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    toggleSoundBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleSoundBtn.Text = "ON"
    toggleSoundBtn.TextSize = 11
    toggleSoundBtn.Font = Enum.Font.SourceSansBold
    toggleSoundBtn.Parent = row

    local togCorner = Instance.new("UICorner")
    togCorner.CornerRadius = UDim.new(0, 4)
    togCorner.Parent = toggleSoundBtn

    UI_Rows[soundName] = {
        Frame = row,
        TextBox = textBox,
        ToggleBtn = toggleSoundBtn,
        IsDisabled = false
    }

    -- Botão OK / Alterar ID
    applyBtn.MouseButton1Click:Connect(function()
        local soundObj = FindSoundObject(soundName)
        if soundObj then
            local cleanId = textBox.Text:gsub("%D", "")
            if cleanId ~= "" then
                OriginalIDs[soundName] = cleanId
                if not UI_Rows[soundName].IsDisabled then
                    ForceSoundUpdate(soundObj, "rbxassetid://" .. cleanId)
                end
                applyBtn.Text = "✓"
                task.wait(1)
                applyBtn.Text = "OK"
            end
        end
    end)

    -- Botão ON / OFF
    toggleSoundBtn.MouseButton1Click:Connect(function()
        local soundObj = FindSoundObject(soundName)
        if soundObj then
            local rowData = UI_Rows[soundName]
            
            if not rowData.IsDisabled then
                rowData.IsDisabled = true
                ForceSoundUpdate(soundObj, "rbxassetid://0")
                toggleSoundBtn.Text = "OFF"
                toggleSoundBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            else
                rowData.IsDisabled = false
                local targetId = rowData.TextBox.Text:gsub("%D", "")
                if targetId == "" or targetId == "0" then
                    targetId = OriginalIDs[soundName] or "0"
                end
                ForceSoundUpdate(soundObj, "rbxassetid://" .. targetId)
                toggleSoundBtn.Text = "ON"
                toggleSoundBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            end
        end
    end)
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

-- Processar troca ou manutenção de veículo
local function FetchCurrentSoundIDs()
    local car = GetPlayerCar()
    if not car then return end

    -- Verifica se mudou de carro comparando a instância e o nome do modelo
    if CurrentCarModel ~= car then
        CurrentCarModel = car
        ClearSoundData()
    end

    DetectCarSounds(car)

    for _, sName in ipairs(SOUND_NAMES) do
        CreateSoundRow(sName)
    end

    for _, sName in ipairs(SOUND_NAMES) do
        local soundObj = FindSoundObject(sName)
        if soundObj then
            local rawId = soundObj.SoundId:gsub("%D", "")
            
            if rawId ~= "" and rawId ~= "0" then
                OriginalIDs[sName] = rawId
                if UI_Rows[sName] then
                    UI_Rows[sName].TextBox.Text = rawId
                end
            elseif UI_Rows[sName] and OriginalIDs[sName] then
                UI_Rows[sName].TextBox.Text = OriginalIDs[sName]
            end
        end
    end
end

-- Evento ao sentar no banco
local function SetupSeatedListener()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    humanoid.Seated:Connect(function(isSeated, seat)
        if isSeated and seat and seat:IsA("VehicleSeat") then
            task.wait(0.3)
            FetchCurrentSoundIDs()
        end
    end)
end

if LocalPlayer.Character then
    SetupSeatedListener()
end
LocalPlayer.CharacterAdded:Connect(SetupSeatedListener)

FetchCurrentSoundIDs()

-- Rodapé
local footerLabel = Instance.new("TextLabel")
footerLabel.Size = UDim2.new(1, 0, 0, 25)
footerLabel.Position = UDim2.new(0, 0, 0.9, 0)
footerLabel.BackgroundTransparency = 1
footerLabel.Text = "Atalho PC: Tecla [F]"
footerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
footerLabel.TextSize = 10
footerLabel.Font = Enum.Font.SourceSans
footerLabel.Parent = mainFrame

-- Botão Flutuante Mobile
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MobileToggle"
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Text = "🔊"
toggleBtn.TextSize = 20
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.Active = true
toggleBtn.Draggable = true
toggleBtn.Parent = screenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = toggleBtn

local function ToggleGui()
    mainFrame.Visible = not mainFrame.Visible
end

toggleBtn.MouseButton1Click:Connect(ToggleGui)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        ToggleGui()
    end
end)
