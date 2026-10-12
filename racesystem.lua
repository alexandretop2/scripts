--[[
    F1 2026 Race System + Integrated Trackside TV Cameras
    Xeno Executor
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

-- ====================== LIMPEZA TOTAL ======================
if localPlayer.PlayerGui:FindFirstChild("F1_RaceSystem") then
    localPlayer.PlayerGui.F1_RaceSystem:Destroy()
end

for _, partName in ipairs({"StartFinish", "S1", "S2"}) do
    local oldPart = workspace:FindFirstChild(partName)
    if oldPart then
        oldPart:Destroy()
    end
end

if workspace:FindFirstChild("TracksideCamerasFolder") then
    workspace.TracksideCamerasFolder:Destroy()
end

-- ====================== ATALHOS TECLADO ======================
local toggleControlKey = Enum.KeyCode.H
local toggleTowerKey = Enum.KeyCode.T
local nextCamKey = Enum.KeyCode.U
local prevCamKey = Enum.KeyCode.Y

local isBindingControl = false
local isBindingTower = false
local isBindingNextCam = false
local isBindingPrevCam = false

-- ====================== BANCO DE DADOS DE PISTAS & CÂMERAS ======================
local trackDatabase = {
    ["Circuito"] = {
        Sectors = {
            {
                Name = "StartFinish",
                Position = Vector3.new(1101.58, 612.78, 2517.97),
                Size = Vector3.new(215.00, 25.00, 5.00),
                CFrame = CFrame.new(1101.578369, 612.781006, 2517.969971, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000)
            },
            {
                Name = "S1",
                Position = Vector3.new(386.31, 614.36, 2968.98),
                Size = Vector3.new(78.00, 25.00, 5.00),
                CFrame = CFrame.new(386.313171, 614.360413, 2968.984375, 0.989811, 0.065964, -0.126184, -0.066493, 0.997787, 0.000023, 0.125907, 0.008368, 0.992007)
            },
            {
                Name = "S2",
                Position = Vector3.new(869.40, 612.83, 1584.54),
                Size = Vector3.new(91.00, 25.00, 5.00),
                CFrame = CFrame.new(869.400085, 612.829590, 1584.544312, 0.043583, 0.000000, 0.999050, 0.000000, 1.000000, 0.000000, -0.999050, 0.000000, 0.043583)
            },
        },
        CamString = "1;1136.20;600.22;2537.88;10|2;1021.97;602.29;3062.94;20|3;718.36;600.21;3245.42;12|4;790.58;600.21;2608.17;15|5;586.09;600.26;2798.64;20|6;354.00;603.36;3032.44;30|7;447.04;602.48;2404.64;20|8;761.48;602.13;1797.45;20|9;743.75;600.22;2192.35;20|10;978.57;600.26;2005.75;20|11;976.06;600.22;1581.84;5|12;568.88;612.23;1481.04;5|13;1060.97;600.21;1459.93;5|14;1237.46;625.12;1937.25;5"
    },
    ["PitRace"] = {
        Sectors = {
            {
                Name = "StartFinish",
                Position = Vector3.new(-2774.37, 612.54, 4492.07),
                Size = Vector3.new(215.00, 25.00, 5.00),
                CFrame = CFrame.new(-2774.366455, 612.542297, 4492.066895, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, 1.000000)
            },
            {
                Name = "S1",
                Position = Vector3.new(-894.22, 612.55, 4185.42),
                Size = Vector3.new(96.00, 25.00, 5.00),
                CFrame = CFrame.new(-894.222900, 612.547913, 4185.418457, 0.000000, 0.000000, 1.000000, 0.000000, 1.000000, 0.000000, -1.000000, 0.000000, 0.000000)
            },
            {
                Name = "S2",
                Position = Vector3.new(-2250.87, 612.54, 3081.36),
                Size = Vector3.new(91.00, 25.00, 5.00),
                CFrame = CFrame.new(-2250.868164, 612.544678, 3081.362549, -1.000000, 0.000000, 0.000000, 0.000000, 1.000000, 0.000000, 0.000000, 0.000000, -1.000000)
            },
        },
        CamString = "1;-2720.93;620.62;4495.40;10|2;-2676.85;603.25;4759.34;10|3;-2304.17;603.04;4806.08;20|4;-2392.47;603.04;5155.21;20|5;-1809.09;603.25;5340.14;10|6;-1389.87;603.25;5344.84;10|7;-954.52;603.25;5297.64;20|8;-767.11;603.05;5064.11;20|9;-732.12;603.25;4712.30;20|10;-722.79;603.05;4178.97;20|11;-1330.13;603.00;4122.72;20|12;-1680.83;635.94;4201.42;50|13;-2204.54;603.25;4140.34;30|14;-2259.02;603.04;3610.54;10|15;-1905.44;603.25;3566.66;20|16;-1808.92;607.44;3206.16;10|17;-2257.59;603.04;3161.96;30|18;-2313.52;603.25;2570.96;10|19;-2673.07;603.25;2644.88;20|20;-2765.36;603.25;2896.43;10|21;-2762.31;603.25;3596.97;20"
    }
}

local currentTrackName = ""
local sectorData = {}
local sectors = {}
local BLOCK_TRANSPARENCY = 0.75
local detectorsVisible = true

-- ====================== SISTEMA DE CÂMERAS ======================
local cameraList = {}
local activeCamIndex = 0
local spectatingPlayer = nil
local autoCamMode = true
local camRenderConn = nil

local function getPlayerPos(p)
    if not p then return nil end
    local folder = workspace:FindFirstChild("Cars")
    if folder then
        for _, car in ipairs(folder:GetChildren()) do
            local stats = car:FindFirstChild("Stats")
            if stats then
                local owner = stats:FindFirstChild("Owner")
                if owner and ((owner:IsA("StringValue") and owner.Value == p.Name) or (owner:IsA("ObjectValue") and owner.Value == p)) then
                    local body = car:FindFirstChild("Body")
                    local main = body and body:FindFirstChild("Main") or car.PrimaryPart
                    if main then return main.Position end
                end
            end
        end
    end
    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        return p.Character.HumanoidRootPart.Position
    end
    return nil
end

local function restoreNormalCamera()
    spectatingPlayer = nil
    activeCamIndex = 0
    if camRenderConn then
        camRenderConn:Disconnect()
        camRenderConn = nil
    end
    Camera.CameraType = Enum.CameraType.Custom
    Camera.FieldOfView = 70
    if localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") then
        Camera.CameraSubject = localPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    if updateTower then updateTower() end
end

local function getClosestCameraIndex(targetPos)
    if #cameraList == 0 or not targetPos then return 0 end
    local closestIndex = 1
    local minDistance = math.huge

    for i, entry in ipairs(cameraList) do
        if entry.part and entry.part.Parent then
            local camPos = entry.part.Position + Vector3.new(0, entry.heightOffset or 0, 0)
            local dist = (camPos - targetPos).Magnitude
            if dist < minDistance then
                minDistance = dist
                closestIndex = i
            end
        end
    end
    return closestIndex
end

local function startCameraSystem(targetPlr, camIdx)
    if not targetPlr then
        restoreNormalCamera()
        return
    end

    spectatingPlayer = targetPlr
    if camIdx then activeCamIndex = camIdx end

    if not camRenderConn then
        Camera.CameraType = Enum.CameraType.Scriptable
        camRenderConn = RunService.RenderStepped:Connect(function()
            if not spectatingPlayer then
                restoreNormalCamera()
                return
            end

            local targetPos = getPlayerPos(spectatingPlayer)
            if not targetPos then return end

            if autoCamMode and activeCamIndex == 0 then
                local closest = getClosestCameraIndex(targetPos)
                if closest ~= 0 then
                    activeCamIndex = closest
                end
            end

            local entry = cameraList[activeCamIndex]
            if not entry or not entry.part or not entry.part.Parent then
                if #cameraList > 0 then
                    activeCamIndex = 1
                    entry = cameraList[1]
                else
                    restoreNormalCamera()
                    return
                end
            end

            local camPos = entry.part.Position + Vector3.new(0, entry.heightOffset or 0, 0)
            Camera.CFrame = CFrame.new(camPos, targetPos)

            local dist = (targetPos - camPos).Magnitude
            local dynamicFOV = math.clamp(70 - (dist * 0.05), 15, 70)
            Camera.FieldOfView = dynamicFOV
        end)
    end
    if updateTower then updateTower() end
end

local function cycleCamera(dir)
    if #cameraList == 0 then return end
    if activeCamIndex == 0 then
        activeCamIndex = 1
    else
        activeCamIndex = activeCamIndex + dir
        if activeCamIndex > #cameraList then activeCamIndex = 1 end
        if activeCamIndex < 1 then activeCamIndex = #cameraList end
    end
    autoCamMode = false
    if spectatingPlayer then
        startCameraSystem(spectatingPlayer, activeCamIndex)
    end
end

local function buildCamerasFromData(camDataString)
    for _, e in ipairs(cameraList) do
        if e.part and e.part.Parent then e.part:Destroy() end
    end
    cameraList = {}

    local camFolder = workspace:FindFirstChild("TracksideCamerasFolder") or Instance.new("Folder")
    camFolder.Name = "TracksideCamerasFolder"
    camFolder.Parent = workspace
    camFolder:ClearAllChildren()

    if not camDataString or camDataString == "" then return end

    for entry in string.gmatch(camDataString, "([^|]+)") do
        local id, x, y, z, offsetHeight = string.match(entry, "([^;]+);([^;]+);([^;]+);([^;]+);([^;]+)")
        if id and x and y and z and offsetHeight then
            local numID = tonumber(id)
            local pos = Vector3.new(tonumber(x), tonumber(y), tonumber(z))

            local part = Instance.new("Part")
            part.Name = "CamPart_" .. numID
            part.Size = Vector3.new(1.2, 1.2, 1.2)
            part.Position = pos
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1 -- TOTALMENTE INVISÍVEL
            part.Parent = camFolder

            table.insert(cameraList, {
                ID = numID,
                name = "Câmera " .. numID,
                part = part,
                heightOffset = tonumber(offsetHeight) or 0
            })
        end
    end
    table.sort(cameraList, function(a, b) return a.ID < b.ID end)
end

-- ====================== ESTADO CORRIDA ======================
local raceActive = false
local totalLaps = 3
local currentRaceLap = 1
local useFullName = false
local towerWidth = 240

local drivers = {}
local lastTrigger = {}

-- ====================== DETECTORES ======================
local function createSectors()
    for _, part in pairs(sectors) do
        if part and part.Parent then part:Destroy() end
    end
    sectors = {}

    if not sectorData or #sectorData == 0 then return end

    for _, data in ipairs(sectorData) do
        local part = Instance.new("Part")
        part.Name = data.Name
        part.Size = data.Size
        part.CFrame = data.CFrame
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = detectorsVisible and BLOCK_TRANSPARENCY or 1
        part.Material = Enum.Material.Neon

        if data.Name == "StartFinish" then
            part.Color = Color3.fromRGB(0, 255, 100)
        elseif data.Name == "S1" then
            part.Color = Color3.fromRGB(0, 170, 255)
        else
            part.Color = Color3.fromRGB(255, 140, 0)
        end

        part.Parent = workspace

        local sb = Instance.new("SelectionBox")
        sb.Adornee = part
        sb.Color3 = part.Color
        sb.LineThickness = 0.04
        sb.Transparency = detectorsVisible and 0.3 or 1
        sb.Visible = detectorsVisible
        sb.Parent = part

        sectors[data.Name] = part
    end
end

local function setDetectorsVisible(visible)
    detectorsVisible = visible
    for _, part in pairs(sectors) do
        if part then
            part.Transparency = visible and BLOCK_TRANSPARENCY or 1
            local sb = part:FindFirstChildOfClass("SelectionBox")
            if sb then
                sb.Visible = visible
                sb.Transparency = visible and 0.3 or 1
            end
        end
    end
end

-- ====================== HELPER FUNCTIONS ======================
local function getName3(plr)
    return string.upper(string.sub(plr.DisplayName or plr.Name, 1, 3))
end

local function getFullName(plr)
    return string.upper(plr.DisplayName or plr.Name)
end

local function isInsidePart(hrpPos, part)
    local relPos = part.CFrame:PointToObjectSpace(hrpPos)
    local halfSize = part.Size / 2
    return math.abs(relPos.X) <= (halfSize.X + 12)
       and math.abs(relPos.Y) <= (halfSize.Y + 25)
       and math.abs(relPos.Z) <= (halfSize.Z + 12)
end

local function getProgress(lap, sector)
    return (lap * 3) + sector
end

-- ====================== GUI SETUP ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "F1_RaceSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local tower = Instance.new("Frame")
tower.Name = "TimingTower"
tower.Size = UDim2.new(0, towerWidth, 0, 125)
tower.Position = UDim2.new(0, 20, 0.18, 0)
tower.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
tower.BackgroundTransparency = 0.1
tower.BorderSizePixel = 0
tower.Visible = false
tower.Parent = screenGui
Instance.new("UICorner", tower).CornerRadius = UDim.new(0, 4)

local towerStroke = Instance.new("UIStroke", tower)
towerStroke.Color = Color3.fromRGB(35, 38, 48)
towerStroke.Thickness = 1

local logoHeader = Instance.new("Frame")
logoHeader.Size = UDim2.new(1, 0, 0, 52)
logoHeader.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
logoHeader.BorderSizePixel = 0
logoHeader.Parent = tower

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 130, 0, 38)
logo.Position = UDim2.new(0.5, -65, 0, 7)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://139559204203363"
logo.ScaleType = Enum.ScaleType.Fit
logo.Parent = logoHeader

local lineDiv1 = Instance.new("Frame")
lineDiv1.Size = UDim2.new(1, 0, 0, 1)
lineDiv1.Position = UDim2.new(0, 0, 1, -1)
lineDiv1.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
lineDiv1.BorderSizePixel = 0
lineDiv1.Parent = logoHeader

local lapHeader = Instance.new("Frame")
lapHeader.Size = UDim2.new(1, 0, 0, 32)
lapHeader.Position = UDim2.new(0, 0, 0, 52)
lapHeader.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
lapHeader.BorderSizePixel = 0
lapHeader.Parent = tower

local lapCounter = Instance.new("TextLabel")
lapCounter.Size = UDim2.new(1, 0, 1, 0)
lapCounter.BackgroundTransparency = 1
lapCounter.Text = "AGUARDANDO LARGADA"
lapCounter.TextColor3 = Color3.fromRGB(160, 165, 180)
lapCounter.Font = Enum.Font.GothamBold
lapCounter.TextSize = 11
lapCounter.RichText = true
lapCounter.TextXAlignment = Enum.TextXAlignment.Center
lapCounter.Parent = lapHeader

local lineDiv2 = Instance.new("Frame")
lineDiv2.Size = UDim2.new(1, 0, 0, 1)
lineDiv2.Position = UDim2.new(0, 0, 1, -1)
lineDiv2.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
lineDiv2.BorderSizePixel = 0
lineDiv2.Parent = lapHeader

local rowsContainer = Instance.new("Frame")
rowsContainer.Size = UDim2.new(1, 0, 1, -85)
rowsContainer.Position = UDim2.new(0, 0, 0, 85)
rowsContainer.BackgroundTransparency = 1
rowsContainer.Parent = tower

local rowsLayout = Instance.new("UIListLayout")
rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowsLayout.Padding = UDim.new(0, 1)
rowsLayout.Parent = rowsContainer

local rows = {}

local function clearRows()
    for _, row in pairs(rows) do
        if row and row.Parent then row:Destroy() end
    end
    rows = {}
end

local function createRow(pos, plr, displayName, gapText, gapColor, finished)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = (spectatingPlayer == plr) and Color3.fromRGB(0, 90, 160) or Color3.fromRGB(15, 17, 23)
    row.BorderSizePixel = 0
    row.LayoutOrder = pos
    row.Parent = rowsContainer

    local posBox = Instance.new("Frame")
    posBox.Size = UDim2.new(0, 24, 1, 0)
    posBox.BackgroundColor3 = pos == 1 and Color3.fromRGB(220, 0, 0) or Color3.fromRGB(22, 25, 34)
    posBox.BorderSizePixel = 0
    posBox.Parent = row

    local posLbl = Instance.new("TextLabel")
    posLbl.Size = UDim2.new(1, 0, 1, 0)
    posLbl.BackgroundTransparency = 1
    posLbl.Text = tostring(pos)
    posLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    posLbl.Font = Enum.Font.GothamBold
    posLbl.TextSize = 12
    posLbl.Parent = posBox

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(0, useFullName and 110 or 50, 1, 0)
    nameLbl.Position = UDim2.new(0, 28, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = displayName
    nameLbl.TextColor3 = (spectatingPlayer == plr) and Color3.fromRGB(0, 230, 255) or Color3.fromRGB(255, 255, 255)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = row

    if finished then
        local flag = Instance.new("ImageLabel")
        flag.Size = UDim2.new(0, 14, 0, 14)
        flag.Position = UDim2.new(1, -16, 0.5, -7)
        flag.BackgroundTransparency = 1
        flag.Image = "rbxassetid://14617884880"
        flag.ScaleType = Enum.ScaleType.Fit
        flag.Parent = row
    end

    local gapLbl = Instance.new("TextLabel")
    gapLbl.Size = UDim2.new(0, 75, 1, 0)
    gapLbl.Position = UDim2.new(1, finished and -32 or -10, 0, 0)
    gapLbl.AnchorPoint = Vector2.new(1, 0)
    gapLbl.BackgroundTransparency = 1
    gapLbl.Text = gapText
    gapLbl.TextColor3 = gapColor
    gapLbl.Font = Enum.Font.Gotham
    gapLbl.TextSize = 11
    gapLbl.TextXAlignment = Enum.TextXAlignment.Right
    gapLbl.Parent = row

    -- BOTÃO DE ESPECTAR / FOCAR CÂMERA NA TABELA
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        if spectatingPlayer == plr then
            restoreNormalCamera()
        else
            startCameraSystem(plr, 1)
        end
        updateTower()
    end)

    table.insert(rows, row)
end

local function updateGaps()
    local list = {}
    for plr, data in pairs(drivers) do
        if data.lap > 0 or data.sector > 0 then
            table.insert(list, {
                player = plr,
                data = data,
                progress = getProgress(data.lap, data.sector)
            })
        end
    end

    table.sort(list, function(a, b)
        if a.progress == b.progress then
            return a.data.lastTime < b.data.lastTime
        end
        return a.progress > b.progress
    end)

    local leaderTime = list[1] and list[1].data.lastTime or 0

    for i, entry in ipairs(list) do
        local data = entry.data
        data.position = i
        
        if i == 1 then
            data.gapText = "Leader"
            data.gapColor = Color3.fromRGB(220, 220, 230)
        else
            local gap = math.max(0, data.lastTime - leaderTime)
            if gap >= 60 then
                data.gapText = string.format("+%d:%05.2f", math.floor(gap / 60), gap % 60)
            else
                data.gapText = string.format("+%.3f", gap)
            end
            data.gapColor = Color3.fromRGB(255, 255, 255)
        end
    end
    return list
end

function updateTower()
    clearRows()
    local list = updateGaps()

    -- Adiciona jogadores que ainda não iniciaram a volta na lista
    for _, plr in ipairs(Players:GetPlayers()) do
        local found = false
        for _, entry in ipairs(list) do
            if entry.player == plr then found = true break end
        end
        if not found then
            table.insert(list, {
                player = plr,
                data = {
                    position = #list + 1,
                    name3 = getName3(plr),
                    fullName = getFullName(plr),
                    gapText = "--",
                    gapColor = Color3.fromRGB(150, 150, 150),
                    finished = false
                }
            })
        end
    end

    for _, entry in ipairs(list) do
        local displayName = useFullName and entry.data.fullName or entry.data.name3
        createRow(entry.data.position, entry.player, displayName, entry.data.gapText, entry.data.gapColor, entry.data.finished)
    end

    local height = 85 + (#list * 27)
    tower.Size = UDim2.new(0, towerWidth, 0, math.max(115, height))

    if raceActive then
        local maxLap = 1
        for _, data in pairs(drivers) do
            if data.lap > maxLap then maxLap = data.lap end
        end
        currentRaceLap = math.min(maxLap, totalLaps)
        lapCounter.Text = "LAP <font color=\"#FFFFFF\">" .. currentRaceLap .. "</font> / " .. totalLaps
        lapCounter.TextSize = 13
    else
        lapCounter.Text = "AGUARDANDO LARGADA"
        lapCounter.TextSize = 11
    end
end

-- ====================== LOGICA RÍGIDA DOS SETORES ======================
local function processSector(plr, sectorName)
    local now = tick()
    local key = plr.UserId .. "_" .. sectorName

    if lastTrigger[key] and (now - lastTrigger[key]) < 2.0 then
        return
    end

    if not drivers[plr] then
        if sectorName ~= "StartFinish" then return end
        drivers[plr] = {
            name3 = getName3(plr),
            fullName = getFullName(plr),
            lap = 1,
            sector = 1,
            s1Passed = false,
            s2Passed = false,
            lastTime = now,
            position = 99,
            gapText = "",
            gapColor = Color3.new(1,1,1),
            finished = false
        }
        lastTrigger[key] = now
        updateTower()
        print("[Race] " .. plr.DisplayName .. " abriu a Volta 1!")
        return
    end

    local data = drivers[plr]
    if data.finished then return end

    if sectorName == "S1" then
        if data.sector == 1 then
            data.sector = 2
            data.s1Passed = true
            data.lastTime = now
            lastTrigger[key] = now
        end
    elseif sectorName == "S2" then
        if data.sector == 2 or data.s1Passed then
            data.sector = 3
            data.s2Passed = true
            data.lastTime = now
            lastTrigger[key] = now
        end
    elseif sectorName == "StartFinish" then
        if data.s2Passed or data.sector == 3 then
            if data.lap >= totalLaps then
                data.finished = true
                data.sector = 3
            else
                data.lap = data.lap + 1
                data.sector = 1
                data.s1Passed = false
                data.s2Passed = false
            end
            data.lastTime = now
            lastTrigger[key] = now
            print("[Race] " .. plr.DisplayName .. " completou e abriu a Volta " .. data.lap)
        end
    end

    updateTower()
end

local function checkAllPlayers()
    if not raceActive then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for name, part in pairs(sectors) do
                    if isInsidePart(hrp.Position, part) then
                        processSector(plr, name)
                    end
                end
            end
        end
    end
end

-- ====================== PAINEL DE CONTROLE DE CORRIDA & CÂMERAS ======================
local control = Instance.new("Frame")
control.Name = "RaceControl"
control.Size = UDim2.new(0, 220, 0, 520)
control.Position = UDim2.new(1, -240, 0, 20)
control.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
control.BackgroundTransparency = 0.15
control.BorderSizePixel = 0
control.Visible = false
control.Parent = screenGui
Instance.new("UICorner", control).CornerRadius = UDim.new(0, 10)

local cStroke = Instance.new("UIStroke", control)
cStroke.Color = Color3.fromRGB(50, 50, 65)
cStroke.Thickness = 1.3

local cTitle = Instance.new("TextLabel")
cTitle.Size = UDim2.new(1, -16, 0, 26)
cTitle.Position = UDim2.new(0, 10, 0, 8)
cTitle.BackgroundTransparency = 1
cTitle.Text = "CONTROLE DA CORRIDA"
cTitle.TextColor3 = Color3.new(1,1,1)
cTitle.Font = Enum.Font.GothamBold
cTitle.TextSize = 13
cTitle.TextXAlignment = Enum.TextXAlignment.Left
cTitle.Parent = control

local trackLbl = Instance.new("TextLabel")
trackLbl.Name = "TrackNameDisplay"
trackLbl.Size = UDim2.new(1, -20, 0, 18)
trackLbl.Position = UDim2.new(0, 10, 0, 32)
trackLbl.BackgroundTransparency = 1
trackLbl.Text = "Pista: ---"
trackLbl.TextColor3 = Color3.fromRGB(0, 220, 150)
trackLbl.Font = Enum.Font.GothamBold
trackLbl.TextSize = 11
trackLbl.TextXAlignment = Enum.TextXAlignment.Left
trackLbl.Parent = control

local lapsLabel = Instance.new("TextLabel")
lapsLabel.Size = UDim2.new(0, 80, 0, 22)
lapsLabel.Position = UDim2.new(0, 12, 0, 54)
lapsLabel.BackgroundTransparency = 1
lapsLabel.Text = "Voltas:"
lapsLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
lapsLabel.Font = Enum.Font.Gotham
lapsLabel.TextSize = 13
lapsLabel.Parent = control

local lapsBox = Instance.new("TextBox")
lapsBox.Size = UDim2.new(0, 50, 0, 24)
lapsBox.Position = UDim2.new(0, 70, 0, 52)
lapsBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
lapsBox.Text = "3"
lapsBox.TextColor3 = Color3.new(1,1,1)
lapsBox.Font = Enum.Font.GothamBold
lapsBox.TextSize = 14
lapsBox.Parent = control
Instance.new("UICorner", lapsBox).CornerRadius = UDim.new(0, 5)

local function makeControlBtn(text, y, color, func)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 26)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = control
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(func)
    return btn
end

makeControlBtn("INICIAR CORRIDA", 82, Color3.fromRGB(0, 140, 70), function()
    local num = tonumber(lapsBox.Text)
    totalLaps = (num and num > 0) and math.floor(num) or 3
    lapsBox.Text = tostring(totalLaps)

    drivers = {}
    lastTrigger = {}
    raceActive = true
    currentRaceLap = 1
    updateTower()
    print("[Race] Corrida iniciada!")
end)

makeControlBtn("PARAR CORRIDA", 112, Color3.fromRGB(180, 120, 20), function()
    raceActive = false
    updateTower()
end)

makeControlBtn("RESETAR / EXCLUIR", 142, Color3.fromRGB(150, 40, 40), function()
    raceActive = false
    drivers = {}
    lastTrigger = {}
    clearRows()
    tower.Size = UDim2.new(0, towerWidth, 0, 115)
    currentRaceLap = 1
    updateTower()
end)

makeControlBtn("Nome: 3 Letras ↔ Completo", 178, Color3.fromRGB(70, 70, 140), function()
    useFullName = not useFullName
    updateTower()
end)

local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(0, 100, 0, 20)
sizeLabel.Position = UDim2.new(0, 12, 0, 210)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Largura tabela:"
sizeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.TextSize = 11
sizeLabel.Parent = control

local sizeBox = Instance.new("TextBox")
sizeBox.Size = UDim2.new(0, 60, 0, 20)
sizeBox.Position = UDim2.new(0, 115, 0, 210)
sizeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
sizeBox.Text = tostring(towerWidth)
sizeBox.TextColor3 = Color3.new(1,1,1)
sizeBox.Font = Enum.Font.GothamBold
sizeBox.TextSize = 12
sizeBox.Parent = control
Instance.new("UICorner", sizeBox).CornerRadius = UDim.new(0, 5)

sizeBox.FocusLost:Connect(function()
    local num = tonumber(sizeBox.Text)
    if num and num >= 200 and num <= 400 then
        towerWidth = math.floor(num)
        updateTower()
    else
        sizeBox.Text = tostring(towerWidth)
    end
end)

makeControlBtn("Mostrar / Ocultar Detectores", 238, Color3.fromRGB(50, 100, 140), function()
    setDetectorsVisible(not detectorsVisible)
end)

makeControlBtn("🔄 TROCAR DE PISTA", 268, Color3.fromRGB(120, 60, 160), function()
    raceActive = false
    drivers = {}
    lastTrigger = {}
    clearRows()
    restoreNormalCamera()
    tower.Visible = false
    control.Visible = false
    showTrackSelector()
end)

-- CONFIGURAÇÃO DE ATALHOS NO PAINEL DE CONTROLE (INCLUINDO CÂMERAS)
local bindControlBtn = makeControlBtn("Hub: [" .. toggleControlKey.Name .. "]", 304, Color3.fromRGB(40, 90, 120), function() end)
local bindTowerBtn   = makeControlBtn("Tabela: [" .. toggleTowerKey.Name .. "]", 334, Color3.fromRGB(40, 90, 120), function() end)
local bindNextCamBtn = makeControlBtn("Avançar Cam: [" .. nextCamKey.Name .. "]", 364, Color3.fromRGB(200, 100, 20), function() end)
local bindPrevCamBtn = makeControlBtn("Voltar Cam: [" .. prevCamKey.Name .. "]", 394, Color3.fromRGB(200, 100, 20), function() end)

bindControlBtn.MouseButton1Click:Connect(function()
    isBindingControl = true
    bindControlBtn.Text = "Pressione uma tecla..."
    bindControlBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
end)

bindTowerBtn.MouseButton1Click:Connect(function()
    isBindingTower = true
    bindTowerBtn.Text = "Pressione uma tecla..."
    bindTowerBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
end)

bindNextCamBtn.MouseButton1Click:Connect(function()
    isBindingNextCam = true
    bindNextCamBtn.Text = "Pressione uma tecla..."
    bindNextCamBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
end)

bindPrevCamBtn.MouseButton1Click:Connect(function()
    isBindingPrevCam = true
    bindPrevCamBtn.Text = "Pressione uma tecla..."
    bindPrevCamBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
end)

makeControlBtn("❌ DESACTIVAR CÂMERA", 430, Color3.fromRGB(180, 40, 40), function()
    restoreNormalCamera()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if isBindingControl then
            toggleControlKey = input.KeyCode
            isBindingControl = false
            bindControlBtn.Text = "Hub: [" .. toggleControlKey.Name .. "]"
            bindControlBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 120)
            return
        elseif isBindingTower then
            toggleTowerKey = input.KeyCode
            isBindingTower = false
            bindTowerBtn.Text = "Tabela: [" .. toggleTowerKey.Name .. "]"
            bindTowerBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 120)
            return
        elseif isBindingNextCam then
            nextCamKey = input.KeyCode
            isBindingNextCam = false
            bindNextCamBtn.Text = "Avançar Cam: [" .. nextCamKey.Name .. "]"
            bindNextCamBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 20)
            return
        elseif isBindingPrevCam then
            prevCamKey = input.KeyCode
            isBindingPrevCam = false
            bindPrevCamBtn.Text = "Voltar Cam: [" .. prevCamKey.Name .. "]"
            bindPrevCamBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 20)
            return
        end

        if gameProcessed then return end

        if input.KeyCode == toggleControlKey then
            control.Visible = not control.Visible
        elseif input.KeyCode == toggleTowerKey then
            tower.Visible = not tower.Visible
        elseif input.KeyCode == nextCamKey then
            cycleCamera(1)
        elseif input.KeyCode == prevCamKey then
            cycleCamera(-1)
        end
    end
end)

-- ====================== SELEÇÃO DE PISTAS ======================
function loadTrack(name)
    if trackDatabase[name] then
        currentTrackName = name
        sectorData = trackDatabase[name].Sectors
        createSectors()
        
        buildCamerasFromData(trackDatabase[name].CamString)
        
        control:FindFirstChild("TrackNameDisplay").Text = "Pista: " .. string.upper(name)
        tower.Visible = true
        control.Visible = true
        updateTower()
        print("[Race System] Pista e Câmeras carregadas:", name)
    end
end

function showTrackSelector()
    local selectorFrame = Instance.new("Frame")
    selectorFrame.Name = "TrackSelector"
    selectorFrame.Size = UDim2.new(0, 320, 0, 260)
    selectorFrame.Position = UDim2.new(0.5, -160, 0.5, -130)
    selectorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    selectorFrame.BorderSizePixel = 0
    selectorFrame.Parent = screenGui
    Instance.new("UICorner", selectorFrame).CornerRadius = UDim.new(0, 10)

    local sStroke = Instance.new("UIStroke", selectorFrame)
    sStroke.Color = Color3.fromRGB(0, 170, 255)
    sStroke.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "SELECIONE A PISTA"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = selectorFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -55)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.Active = true
    scroll.Parent = selectorFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.Name
    layout.Padding = UDim.new(0, 6)
    layout.Parent = scroll

    for trackName, _ in pairs(trackDatabase) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        btn.Text = trackName
        btn.TextColor3 = Color3.fromRGB(220, 220, 230)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            selectorFrame:Destroy()
            loadTrack(trackName)
        end)
    end

    task.spawn(function()
        task.wait(0.1)
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
end

-- ====================== DRAGGABLE ======================
local function makeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(tower)
makeDraggable(control)

-- ====================== LOOPS ======================
RunService.Heartbeat:Connect(function()
    checkAllPlayers()
end)

task.spawn(function()
    while true do
        if raceActive then
            updateTower()
        end
        task.wait(0.5)
    end
end)

localPlayer.CharacterAdded:Connect(function(char)
    character = char
    root = char:WaitForChild("HumanoidRootPart")
end)

showTrackSelector()
