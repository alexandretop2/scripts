local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Função principal para aplicar os novos gráficos vibrantes
local function AplicarGraficosVivos()
    -- 1. Remove os efeitos anteriores do Lighting
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") then
            obj:Destroy()
        end
    end

    -- 2. Configurações gerais de iluminação (iluminação mais quente e viva)
    Lighting.Ambient = Color3.fromRGB(35, 30, 25)
    Lighting.Brightness = 2.4
    Lighting.ColorShift_Bottom = Color3.fromRGB(15, 15, 15)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 230, 195)
    Lighting.EnvironmentDiffuseScale = 1
    Lighting.EnvironmentSpecularScale = 1
    Lighting.GlobalShadows = true
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 75, 70)
    Lighting.ShadowSoftness = 0.15
    Lighting.GeographicLatitude = 45
    Lighting.ExposureCompensation = 0.1
    Lighting.FogColor = Color3.fromRGB(180, 200, 220)
    Lighting.FogEnd = 100000

    -- Sky (Céu limpo padrão)
    local Sky = Instance.new("Sky")
    Sky.Name = "CustomSky"
    Sky.Parent = Lighting

    -- Atmosphere (Névoa suave e natural)
    local Atmosphere = Instance.new("Atmosphere")
    Atmosphere.Density = 0.25
    Atmosphere.Offset = 0.25
    Atmosphere.Color = Color3.fromRGB(190, 180, 160)
    Atmosphere.Decay = Color3.fromRGB(110, 100, 90)
    Atmosphere.Glare = 0.5
    Atmosphere.Haze = 1.2
    Atmosphere.Parent = Lighting

    -- Bloom (Glow suave nas partes iluminadas)
    local Bloom = Instance.new("BloomEffect")
    Bloom.Intensity = 0.4
    Bloom.Size = 24
    Bloom.Threshold = 1.8
    Bloom.Parent = Lighting

    -- Color Correction (Cores mais vívidas e contraste limpo)
    local Color = Instance.new("ColorCorrectionEffect")
    Color.Brightness = 0.05
    Color.Contrast = 0.18
    Color.Saturation = 0.25 -- Saturação positiva para cores vivas
    Color.TintColor = Color3.fromRGB(255, 250, 242)
    Color.Parent = Lighting

    -- Sun Rays (Raios de sol visíveis)
    local Sun = Instance.new("SunRaysEffect")
    Sun.Intensity = 0.12
    Sun.Spread = 0.6
    Sun.Parent = Lighting
end

-- =========================================================
-- CRIAÇÃO DA INTERFACE (GUI)
-- =========================================================

-- Destrói interface antiga se já existir
if PlayerGui:FindFirstChild("GraphicSettingsGui") then
    PlayerGui.GraphicSettingsGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GraphicSettingsGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Painel Principal
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 320, 0, 190)
Frame.Position = UDim2.new(0.5, -160, 0.5, -95)
Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 15, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "Configurações Gráficas"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

-- Botão de Fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Frame

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- Descrição
local Desc = Instance.new("TextLabel")
Desc.Size = UDim2.new(1, -30, 0, 35)
Desc.Position = UDim2.new(0, 15, 0, 45)
Desc.BackgroundTransparency = 1
Desc.Text = "Aplique os novos visuais vibrantes para remover o tom cinza da iluminação."
Desc.TextColor3 = Color3.fromRGB(170, 170, 180)
Desc.TextSize = 13
Desc.Font = Enum.Font.Gotham
Desc.TextWrapped = true
Desc.TextXAlignment = Enum.TextXAlignment.Left
Desc.Parent = Frame

-- Botão de Aplicar
local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size = UDim2.new(1, -30, 0, 45)
ApplyBtn.Position = UDim2.new(0, 15, 0, 120)
ApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
ApplyBtn.Text = "Ativar Gráficos Vivos"
ApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyBtn.TextSize = 15
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ApplyBtn

-- Ação ao Clicar no Botão
ApplyBtn.MouseButton1Click:Connect(function()
    AplicarGraficosVivos()
    ApplyBtn.Text = "Gráficos Aplicados!"
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
    task.wait(1.5)
    ApplyBtn.Text = "Ativar Gráficos Vivos"
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
end)
