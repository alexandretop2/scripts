-- ============== CONFIGURAÇÃO ==============
local Scripts = {
    {Name = "Painel de Livery", Url = "https://raw.githubusercontent.com/alexandretop2/scripts/refs/heads/main/livery.lua"},
    {Name = "FreeCam", Url = "https://raw.githubusercontent.com/alexandretop2/scripts/refs/heads/main/freecam.lua"},
    {Name = "Painel de Funcionalidades",    Url = "https://raw.githubusercontent.com/alexandretop2/scripts/main/xandaopainel.lua"},
    -- Adicione quantos quiser aqui
}

-- ============== INTERFACE ==============
local CoreGui = game:GetService("CoreGui")

-- Remove painel antigo se existir
pcall(function()
    CoreGui:FindFirstChild("MeuPainelScripts"):Destroy()
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeuPainelScripts"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 400)
Main.Position = UDim2.new(0.5, -140, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.BorderSizePixel = 0
Title.Text = "Meus Scripts"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 30, 0, 30)
Close.Position = UDim2.new(1, -35, 0, 5)
Close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 16
Close.Parent = Title

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = Close

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -20, 1, -60)
Scrolling.Position = UDim2.new(0, 10, 0, 50)
Scrolling.BackgroundTransparency = 1
Scrolling.BorderSizePixel = 0
Scrolling.ScrollBarThickness = 4
Scrolling.CanvasSize = UDim2.new(0, 0, 0, #Scripts * 45)
Scrolling.Parent = Main

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 8)
ListLayout.Parent = Scrolling

for _, scriptData in ipairs(Scripts) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 38)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Button.BorderSizePixel = 0
    Button.Text = scriptData.Name
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 15
    Button.Parent = Scrolling

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button

    Button.MouseButton1Click:Connect(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet(scriptData.Url))()
        end)
        
        if success then
            -- Fecha o painel assim que o script executar com sucesso
            ScreenGui:Destroy()
        else
            Button.Text = "Erro!"
            Button.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
            warn("Erro ao carregar " .. scriptData.Name .. ":", err)
            task.wait(2)
            Button.Text = scriptData.Name
            Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        end
    end)
end
