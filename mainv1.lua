-- // Services //
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- // UI FRAME (Struktur Asli Dipertahankan) //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- Penting untuk memastikan UI selalu di atas
ScreenGui.ResetOnSpawn = false -- Agar UI tidak hilang saat respawn

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"

local UiTitleLabel = Instance.new("TextLabel")
UiTitleLabel.Name = "UiTitleLabel"

local StartAutoTeleportButton = Instance.new("TextButton")
StartAutoTeleportButton.Name = "StartAutoTeleportButton"

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"

local TimerTitleLabel = Instance.new("TextLabel")
TimerTitleLabel.Name = "TimerTitle"

local ApplyTimersButton = Instance.new("TextButton")
ApplyTimersButton.Name = "ApplyTimersButton"

local ManualTeleportFrame = Instance.new("Frame")
ManualTeleportFrame.Name = "ManualTeleportFrame"

local ManualTeleportTitle = Instance.new("TextLabel")
ManualTeleportTitle.Name = "ManualTeleportTitle"

local TeleportLocationSelector = Instance.new("TextButton")
TeleportLocationSelector.Name = "TeleportLocationSelector"

local TeleportDropdownOptionsFrame = Instance.new("ScrollingFrame")
TeleportDropdownOptionsFrame.Name = "TeleportDropdownOptionsFrame"

local TeleportButton = Instance.new("TextButton")
TeleportButton.Name = "TeleportButton"

local LogFrame = Instance.new("Frame")
LogFrame.Name = "LogFrame"

local LogTitle = Instance.new("TextLabel")
LogTitle.Name = "LogTitle"

local LogOutput = Instance.new("TextLabel")
LogOutput.Name = "LogOutput"

-- Tabel untuk menyimpan referensi elemen input timer
local timerInputElements = {}

-- --- Variabel Kontrol dan State ---
local scriptRunning = false
local autoTeleportActive = false
local autoTeleportThread = nil
local isMinimized = false
local originalFrameSize = UDim2.new(0, 320, 0, 580) -- Ukuran UI sedikit disesuaikan
local minimizedFrameSize = UDim2.new(0, 60, 0, 60) -- Ukuran pop-up 'Z' sedikit lebih besar
local minimizedZLabel = Instance.new("TextLabel")

-- Kumpulan elemen yang visibilitasnya akan di-toggle
local elementsToToggleVisibility = {}

-- --- Tabel Konfigurasi Timer ---
local timers = {
    teleport_wait_time = 300,
    teleport_delay_between_points = 5,
    log_clear_interval = 60,
    teleport_y_offset = 5,
    water_refill_duration = 5,
    water_drink_interval = 300,
    water_drink_count = 5,
}

-- --- Definisi Titik Teleportasi (Ekspedisi Antartika) ---
local teleportLocations = {
    ["Camp 1 Main Tent"] = CFrame.new(-3694.08691, 225.826172, 277.052979, 0.710165381, 0, 0.704034865, 0, 1, 0, -0.704034865, 0, 0.710165381),
    ["Camp 1 Checkpoint"] = CFrame.new(-3719.18188, 223.203995, 235.391006, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp1"] = CFrame.new(-3718.26001, 228.797501, 264.399994, 1.41859055e-05, 0.998563945, -0.0535728931, 1, -1.43051147e-05, 3.81842256e-07, -3.81842256e-07, -0.0535728931, -0.998564005),
    ["Camp 2 Main Tent"] = CFrame.new(1774.76111, 102.314171, -179.4328, -0.790706277, 0, -0.612195849, 0, 1, 0, 0.612195849, 0, -0.790706277),
    ["Camp 2 Checkpoint"] = CFrame.new(1790.31799, 103.665001, -137.858994, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp2"] = CFrame.new(1800.04199, 105.285774, -163.363998, 7.74860382e-06, 0.142248183, 0.989830971, 1, -7.62939453e-06, -6.67572021e-06, 6.67572021e-06, 0.989830971, -0.142248154),
    ["Camp 3 Main Tent"] = CFrame.new(5853.9834, 325.546478, -0.24318853, 0.494506121, -0, -0.869174123, 0, 1, -0, 0.869174123, 0, 0.494506121),
    ["Camp 3 Checkpoint"] = CFrame.new(5892.38916, 319.35498, -19.0779991, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp3"] = CFrame.new(5884.9502, 321.003143, 6.29623318, 2.13384628e-05, 0.635085583, -0.772441745, 1, -2.13384628e-05, 1.0073185e-05, -1.0073185e-05, -0.772441745, -0.635085583),
    ["Camp 4 Main Tent"] = CFrame.new(8999.26465, 593.866089, 59.4377747, -0.999371052, 0, 0.035472773, 0, 1, 0, -0.035472773, 0, -0.999371052),
    ["Camp 4 Checkpoint"] = CFrame.new(8992.36328, 594.10498, 103.060997, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp4"] = CFrame.new(9000.68652, 597.380127, 85.107872, 2.74181366e-06, -0.18581143, 0.982585371, 1, 2.74181366e-06, -2.2649765e-06, -2.2649765e-06, 0.982585371, 0.18581146),
    ["South Pole Checkpoint"] = CFrame.new(10995.2461, 545.255127, 114.804474, 0.819186032, 0.573527873, 3.9935112e-06, -3.9935112e-06, 1.2755394e-05, -1, -0.573527873, 0.819186091, 1.2755394e-05),
}

local hasRefilledWaterAtCurrentCamp = false
local lastRefillCamp = nil
local waterDrinkTimer = 0
local waterDrinkCounter = 0

-- // Parent UI ke player //
local function setupCoreGuiParenting()
    local coreGuiService = game:GetService("CoreGui")
    if not ScreenGui.Parent or ScreenGui.Parent ~= coreGuiService then
        ScreenGui.Parent = coreGuiService
    end
    if not Frame.Parent or Frame.Parent ~= ScreenGui then
        Frame.Parent = ScreenGui
    end
    UiTitleLabel.Parent = Frame
    StartAutoTeleportButton.Parent = Frame
    StatusLabel.Parent = Frame
    MinimizeButton.Parent = Frame
    TimerTitleLabel.Parent = Frame
    ApplyTimersButton.Parent = Frame
    minimizedZLabel.Parent = Frame
    ManualTeleportFrame.Parent = Frame
    ManualTeleportTitle.Parent = ManualTeleportFrame
    TeleportLocationSelector.Parent = ManualTeleportFrame
    TeleportDropdownOptionsFrame.Parent = Frame
    TeleportButton.Parent = ManualTeleportFrame
    LogFrame.Parent = Frame
    LogTitle.Parent = LogFrame
    LogOutput.Parent = LogFrame
end

setupCoreGuiParenting()

-- // Desain UI //

-- --- Frame Utama ---
Frame.Size = originalFrameSize
Frame.Position = UDim2.new(0.5, -Frame.Size.X.Offset/2, 0.5, -Frame.Size.Y.Offset/2)
Frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28) -- Latar belakang lebih gelap
Frame.Active = true
Frame.Draggable = true
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
Frame.ClipsDescendants = false
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12) -- Sudut lebih membulat
UICorner.Parent = Frame

-- --- Nama UI Label ("ANTARCTIC TELEPORT") ---
UiTitleLabel.Size = UDim2.new(1, -20, 0, 40)
UiTitleLabel.Position = UDim2.new(0, 10, 0, 10)
UiTitleLabel.Font = Enum.Font.SourceSansSemibold
UiTitleLabel.Text = "ANTARCTIC TELEPORT"
UiTitleLabel.TextColor3 = Color3.fromRGB(255, 45, 45) -- Merah lebih terang
UiTitleLabel.TextScaled = false
UiTitleLabel.TextSize = 26
UiTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
UiTitleLabel.BackgroundTransparency = 1
UiTitleLabel.ZIndex = 2
UiTitleLabel.TextStrokeTransparency = 0.6
UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(60,0,0)

local yOffsetForTitle = 60

-- --- Tombol Start/Stop Auto Teleport ---
StartAutoTeleportButton.Size = UDim2.new(1, -40, 0, 40)
StartAutoTeleportButton.Position = UDim2.new(0, 20, 0, yOffsetForTitle)
StartAutoTeleportButton.Text = "START AUTO TELEPORT"
StartAutoTeleportButton.Font = Enum.Font.SourceSansBold
StartAutoTeleportButton.TextSize = 18
StartAutoTeleportButton.TextColor3 = Color3.fromRGB(230, 230, 230)
StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(70, 30, 30) -- Merah lebih gelap
StartAutoTeleportButton.BorderSizePixel = 1
StartAutoTeleportButton.BorderColor3 = Color3.fromRGB(255, 80, 80)
StartAutoTeleportButton.ZIndex = 2
local StartButtonCorner = Instance.new("UICorner")
StartButtonCorner.CornerRadius = UDim.new(0, 8)
StartButtonCorner.Parent = StartAutoTeleportButton

-- --- Status Label ---
StatusLabel.Size = UDim2.new(1, -40, 0, 50)
StatusLabel.Position = UDim2.new(0, 20, 0, yOffsetForTitle + 50)
StatusLabel.Text = "STATUS: STANDBY"
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 15
StatusLabel.TextColor3 = Color3.fromRGB(210, 210, 230)
StatusLabel.BackgroundColor3 = Color3.fromRGB(30, 32, 40) -- Latar lebih gelap
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextPadding = UDim.new(0,10)
StatusLabel.BorderSizePixel = 1
StatusLabel.BorderColor3 = Color3.fromRGB(50,52,60)
StatusLabel.ZIndex = 2
local StatusLabelCorner = Instance.new("UICorner")
StatusLabelCorner.CornerRadius = UDim.new(0, 6)
StatusLabelCorner.Parent = StatusLabel

local yOffsetForTimers = yOffsetForTitle + 110

-- --- Konfigurasi Timer UI ---
TimerTitleLabel.Size = UDim2.new(1, -40, 0, 25)
TimerTitleLabel.Position = UDim2.new(0, 20, 0, yOffsetForTimers)
TimerTitleLabel.Text = "// AUTO TELEPORT SETTINGS"
TimerTitleLabel.Font = Enum.Font.Code
TimerTitleLabel.TextSize = 15
TimerTitleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
TimerTitleLabel.BackgroundTransparency = 1
TimerTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TimerTitleLabel.ZIndex = 2

local function createTimerInput(name, yPos, labelText, initialValue)
    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Parent = Frame
    label.Size = UDim2.new(0.55, -25, 0, 22)
    label.Position = UDim2.new(0, 20, 0, yPos + yOffsetForTimers)
    label.Text = labelText .. ":"
    label.Font = Enum.Font.SourceSans
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(190, 190, 210)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    timerInputElements[name .. "Label"] = label

    local input = Instance.new("TextBox")
    input.Name = name .. "Input"
    input.Parent = Frame
    input.Size = UDim2.new(0.45, -25, 0, 22)
    input.Position = UDim2.new(0.55, 5, 0, yPos + yOffsetForTimers)
    input.Text = tostring(initialValue)
    input.PlaceholderText = "detik"
    input.Font = Enum.Font.SourceSansSemibold
    input.TextSize = 13
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.BackgroundColor3 = Color3.fromRGB(35, 37, 45)
    input.ClearTextOnFocus = false
    input.BorderColor3 = Color3.fromRGB(110, 110, 130)
    input.BorderSizePixel = 1
    input.ZIndex = 2
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 4)
    InputCorner.Parent = input
    timerInputElements[name .. "Input"] = input
    return input
end

local currentYConfig = 35
timerInputElements.teleportWaitTimeInput = createTimerInput("TeleportWaitTime", currentYConfig, "Wait Time (Auto)", timers.teleport_wait_time)
currentYConfig = currentYConfig + 28
timerInputElements.teleportDelayBetweenPointsInput = createTimerInput("TeleportDelayBetweenPoints", currentYConfig, "Delay Antar Point", timers.teleport_delay_between_points)
currentYConfig = currentYConfig + 28
timerInputElements.waterRefillDurationInput = createTimerInput("WaterRefillDuration", currentYConfig, "Durasi Isi Air", timers.water_refill_duration)
currentYConfig = currentYConfig + 28
timerInputElements.waterDrinkIntervalInput = createTimerInput("WaterDrinkInterval", currentYConfig, "Interval Minum Air", timers.water_drink_interval)
currentYConfig = currentYConfig + 28
timerInputElements.waterDrinkCountInput = createTimerInput("WaterDrinkCount", currentYConfig, "Jumlah Minum Air", timers.water_drink_count)
currentYConfig = currentYConfig + 38

ApplyTimersButton.Size = UDim2.new(1, -40, 0, 35)
ApplyTimersButton.Position = UDim2.new(0, 20, 0, currentYConfig + yOffsetForTimers)
ApplyTimersButton.Text = "APPLY SETTINGS"
ApplyTimersButton.Font = Enum.Font.SourceSansBold
ApplyTimersButton.TextSize = 16
ApplyTimersButton.TextColor3 = Color3.fromRGB(230, 230, 230)
ApplyTimersButton.BackgroundColor3 = Color3.fromRGB(40, 90, 40) -- Hijau lebih gelap
ApplyTimersButton.BorderColor3 = Color3.fromRGB(100, 255, 100)
ApplyTimersButton.BorderSizePixel = 1
ApplyTimersButton.ZIndex = 2
local ApplyButtonCorner = Instance.new("UICorner")
ApplyButtonCorner.CornerRadius = UDim.new(0, 8)
ApplyButtonCorner.Parent = ApplyTimersButton

local yOffsetForManualTeleport = currentYConfig + yOffsetForTimers + 45

-- --- Manual Teleport Section ---
ManualTeleportFrame.Size = UDim2.new(1, -40, 0, 130) -- Sedikit lebih tinggi
ManualTeleportFrame.Position = UDim2.new(0, 20, 0, yOffsetForManualTeleport)
ManualTeleportFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
ManualTeleportFrame.BorderSizePixel = 1
ManualTeleportFrame.BorderColor3 = Color3.fromRGB(110, 110, 130)
ManualTeleportFrame.ClipsDescendants = false
ManualTeleportFrame.ZIndex = 2
local ManualFrameCorner = Instance.new("UICorner")
ManualFrameCorner.CornerRadius = UDim.new(0, 8)
ManualFrameCorner.Parent = ManualTeleportFrame

ManualTeleportTitle.Size = UDim2.new(1, -20, 0, 22)
ManualTeleportTitle.Position = UDim2.new(0, 10, 0, 10)
ManualTeleportTitle.Text = "// MANUAL TELEPORT"
ManualTeleportTitle.Font = Enum.Font.Code
ManualTeleportTitle.TextSize = 15
ManualTeleportTitle.TextColor3 = Color3.fromRGB(100, 220, 255)
ManualTeleportTitle.BackgroundTransparency = 1
ManualTeleportTitle.TextXAlignment = Enum.TextXAlignment.Left
ManualTeleportTitle.ZIndex = 2

TeleportLocationSelector.Size = UDim2.new(1, -20, 0, 35)
TeleportLocationSelector.Position = UDim2.new(0, 10, 0, 40)
TeleportLocationSelector.Text = "Pilih Lokasi..."
TeleportLocationSelector.Font = Enum.Font.SourceSansSemibold
TeleportLocationSelector.TextSize = 15
TeleportLocationSelector.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportLocationSelector.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
TeleportLocationSelector.BorderSizePixel = 1
TeleportLocationSelector.BorderColor3 = Color3.fromRGB(120, 120, 140)
TeleportLocationSelector.ZIndex = 3 -- Di atas elemen lain di ManualTeleportFrame
TeleportLocationSelector.TextXAlignment = Enum.TextXAlignment.Left
TeleportLocationSelector.TextWrapped = true
TeleportLocationSelector.TextPadding = UDim.new(0,8)
local SelectorCorner = Instance.new("UICorner")
SelectorCorner.CornerRadius = UDim.new(0, 6)
SelectorCorner.Parent = TeleportLocationSelector

TeleportDropdownOptionsFrame.Parent = Frame
TeleportDropdownOptionsFrame.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
TeleportDropdownOptionsFrame.BorderSizePixel = 1
TeleportDropdownOptionsFrame.BorderColor3 = Color3.fromRGB(120, 120, 140)
TeleportDropdownOptionsFrame.ZIndex = 10 -- Paling atas saat visible
TeleportDropdownOptionsFrame.Visible = false
TeleportDropdownOptionsFrame.ScrollBarThickness = 8
TeleportDropdownOptionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local DropdownOptionsCorner = Instance.new("UICorner")
DropdownOptionsCorner.CornerRadius = UDim.new(0, 6)
DropdownOptionsCorner.Parent = TeleportDropdownOptionsFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = TeleportDropdownOptionsFrame
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout.Padding = UDim.new(0, 3)

TeleportButton.Size = UDim2.new(1, -20, 0, 35)
TeleportButton.Position = UDim2.new(0, 10, 0, 85)
TeleportButton.Text = "TELEPORT"
TeleportButton.Font = Enum.Font.SourceSansBold
TeleportButton.TextSize = 16
TeleportButton.TextColor3 = Color3.fromRGB(230, 230, 230)
TeleportButton.BackgroundColor3 = Color3.fromRGB(30, 90, 90)
TeleportButton.BorderColor3 = Color3.fromRGB(70, 255, 255)
TeleportButton.BorderSizePixel = 1
TeleportButton.ZIndex = 2
local TeleportButtonCorner = Instance.new("UICorner")
TeleportButtonCorner.CornerRadius = UDim.new(0, 8)
TeleportButtonCorner.Parent = TeleportButton

local yOffsetForLog = yOffsetForManualTeleport + 145

-- --- Log Section ---
LogFrame.Size = UDim2.new(1, -40, 0, 105) -- Sedikit lebih tinggi
LogFrame.Position = UDim2.new(0, 20, 0, yOffsetForLog)
LogFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 35)
LogFrame.BorderSizePixel = 1
LogFrame.BorderColor3 = Color3.fromRGB(110, 110, 130)
LogFrame.ZIndex = 2
local LogFrameCorner = Instance.new("UICorner")
LogFrameCorner.CornerRadius = UDim.new(0, 8)
LogFrameCorner.Parent = LogFrame

LogTitle.Size = UDim2.new(1, -20, 0, 22)
LogTitle.Position = UDim2.new(0, 10, 0, 10)
LogTitle.Text = "// STATUS LOG"
LogTitle.Font = Enum.Font.Code
LogTitle.TextSize = 15
LogTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
LogTitle.BackgroundTransparency = 1
LogTitle.TextXAlignment = Enum.TextXAlignment.Left
LogTitle.ZIndex = 2

LogOutput.Size = UDim2.new(1, -20, 0, 65)
LogOutput.Position = UDim2.new(0, 10, 0, 35)
LogOutput.Text = "Log: Sistem Siap."
LogOutput.Font = Enum.Font.SourceSansLight
LogOutput.TextSize = 12
LogOutput.TextColor3 = Color3.fromRGB(210, 210, 210)
LogOutput.BackgroundColor3 = Color3.fromRGB(35, 37, 45)
LogOutput.TextWrapped = true
LogOutput.TextXAlignment = Enum.TextXAlignment.Left
LogOutput.TextYAlignment = Enum.TextYAlignment.Top
LogOutput.TextPadding = UDim.new(0,5)
LogOutput.BorderSizePixel = 0
LogOutput.ZIndex = 2
local LogOutputCorner = Instance.new("UICorner")
LogOutputCorner.CornerRadius = UDim.new(0, 6)
LogOutputCorner.Parent = LogOutput

-- --- Tombol Minimize ---
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -40, 0, 10)
MinimizeButton.Text = "_"
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 22
MinimizeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 62, 70)
MinimizeButton.BorderColor3 = Color3.fromRGB(120,120,140)
MinimizeButton.BorderSizePixel = 1
MinimizeButton.ZIndex = 3
local MinimizeButtonCorner = Instance.new("UICorner")
MinimizeButtonCorner.CornerRadius = UDim.new(0, 6)
MinimizeButtonCorner.Parent = MinimizeButton

-- --- Pop-up 'Z' ---
minimizedZLabel.Size = UDim2.new(1, 0, 1, 0)
minimizedZLabel.Position = UDim2.new(0,0,0,0)
minimizedZLabel.Text = "Z"
minimizedZLabel.Font = Enum.Font.SourceSansExtraBold
minimizedZLabel.TextScaled = false
minimizedZLabel.TextSize = 48
minimizedZLabel.TextColor3 = Color3.fromRGB(255, 20, 20)
minimizedZLabel.TextXAlignment = Enum.TextXAlignment.Center
minimizedZLabel.TextYAlignment = Enum.TextYAlignment.Center
minimizedZLabel.BackgroundTransparency = 1
minimizedZLabel.ZIndex = 4
minimizedZLabel.Visible = false

elementsToToggleVisibility = {
    UiTitleLabel, StartAutoTeleportButton, StatusLabel, TimerTitleLabel, ApplyTimersButton,
    timerInputElements.TeleportWaitTimeLabel, timerInputElements.teleportWaitTimeInput,
    timerInputElements.TeleportDelayBetweenPointsLabel, timerInputElements.teleportDelayBetweenPointsInput,
    timerInputElements.WaterRefillDurationLabel, timerInputElements.waterRefillDurationInput,
    timerInputElements.WaterDrinkIntervalLabel, timerInputElements.waterDrinkIntervalInput,
    timerInputElements.WaterDrinkCountLabel, timerInputElements.waterDrinkCountInput,
    ManualTeleportFrame, LogFrame, MinimizeButton
}

-- // Fungsi Bantu UI //
local function updateStatus(text)
    if StatusLabel and StatusLabel.Parent then StatusLabel.Text = "STATUS: " .. string.upper(text) end
    print("Status: " .. text)
end

local function appendLog(text)
    if LogOutput and LogOutput.Parent then
        local currentText = LogOutput.Text
        local newText = os.date("[%H:%M:%S] ") .. text .. "\n" .. currentText
        if #newText > 700 then -- Batas log sedikit lebih panjang
            newText = newText:sub(1, 700) .. "..."
        end
        LogOutput.Text = newText
    end
    print("Log: " .. text)
end

local function clearLog()
    if LogOutput and LogOutput.Parent then
        LogOutput.Text = "Log: Dikosongkan."
    end
    appendLog("Log dikosongkan.")
end

-- // Fungsi Animasi UI //
local function animateFrame(targetSize, targetPosition, callback)
    local info = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out) -- Sedikit lebih lambat, easing beda
    local properties = {Size = targetSize, Position = targetPosition}
    local tween = TweenService:Create(Frame, info, properties)
    tween:Play()
    if callback then
        tween.Completed:Wait()
        callback()
    end
end

-- // Fungsi Minimize/Maximize UI //
local frameClickConnection -- Untuk menyimpan koneksi klik pada frame saat minimized
local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        local originalFramePosition = Frame.Position

        for _, element in ipairs(elementsToToggleVisibility) do
            if element and element.Parent then element.Visible = false end
        end
        minimizedZLabel.Visible = true

        local targetX = 1 - (minimizedFrameSize.X.Offset / ScreenGui.AbsoluteSize.X) - 0.025
        local targetY = 1 - (minimizedFrameSize.Y.Offset / ScreenGui.AbsoluteSize.Y) - 0.025
        local targetPosition = UDim2.new(targetX, 0, targetY, 0)

        animateFrame(minimizedFrameSize, targetPosition)
        Frame.Draggable = false
        
        -- Tambahkan listener klik ke Frame untuk maximize
        if frameClickConnection then frameClickConnection:Disconnect() end -- Hapus listener lama jika ada
        frameClickConnection = Frame.MouseButton1Click:Connect(function()
            if isMinimized then -- Hanya trigger jika sedang minimized
                toggleMinimize() -- Panggil lagi untuk maximize
            end
        end)
    else
        if frameClickConnection then
            frameClickConnection:Disconnect() -- Hapus listener klik pada frame
            frameClickConnection = nil
        end

        for _, element in ipairs(elementsToToggleVisibility) do
            if element == MinimizeButton and element.Parent then element.Visible = true end
        end

        minimizedZLabel.Visible = false
        MinimizeButton.Text = "_"

        local targetPosition = UDim2.new(0.5, -originalFrameSize.X.Offset/2, 0.5, -originalFrameSize.Y.Offset/2)
        animateFrame(originalFrameSize, targetPosition, function()
            for _, element in ipairs(elementsToToggleVisibility) do
                if element and element.Parent then element.Visible = true end
            end
            Frame.Draggable = true
        end)
    end
end

MinimizeButton.MouseButton1Click:Connect(toggleMinimize)

-- // Fungsi tunggu //
local function waitSeconds(sec)
    if sec <= 0 then task.wait() return end
    local startTime = tick()
    repeat
        RunService.Heartbeat:Wait() -- Lebih presisi untuk tunggu singkat
    until not scriptRunning or tick() - startTime >= sec
end

-- Fungsi Teleportasi
local function teleportPlayer(cframeTarget, locationName)
    local success, err = pcall(function()
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                LocalPlayer.Character.Archivable = true
                local originalCollisions = {}
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        originalCollisions[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end

                LocalPlayer.Character:SetPrimaryPartCFrame(cframeTarget + Vector3.new(0, timers.teleport_y_offset, 0))
                
                task.wait(0.1) -- Beri sedikit waktu agar teleportasi stabil

                for part, canCollide in pairs(originalCollisions) do
                    if part and part.Parent then
                        part.CanCollide = canCollide
                    end
                end
                LocalPlayer.Character.Archivable = false
                appendLog("Berhasil teleport ke: " .. locationName)
                updateStatus("TELEPORT KE: " .. string.upper(locationName))
            else
                error("Humanoid tidak ditemukan atau mati.")
            end
        else
            error("Karakter pemain atau PrimaryPart tidak ditemukan.")
        end
    end)
    if not success then
        appendLog("Error Teleport ke " .. locationName .. ": " .. tostring(err))
        updateStatus("TELEPORT_GAGAL")
        return false
    end
    return true
end

-- Fungsi untuk mengisi air
local function refillWater(campName)
    if not LocalPlayer or not LocalPlayer.Character then return end

    if lastRefillCamp == campName and hasRefilledWaterAtCurrentCamp then
        appendLog("Air sudah diisi di " .. campName .. ". Dilewati.")
        return
    end

    local waterRefillLocationName = "WaterRefill_" .. campName:match("Camp (%d)")
    if waterRefillLocationName then
        local refillCFrame = teleportLocations[waterRefillLocationName]
        if refillCFrame then
            appendLog("Teleport ke titik isi air di " .. campName .. "...")
            if teleportPlayer(refillCFrame, "Isi Air " .. campName) then
                updateStatus("MENGISI AIR DI " .. string.upper(campName) .. "...")
                appendLog("Mengisi air selama " .. timers.water_refill_duration .. " detik.")
                waitSeconds(timers.water_refill_duration)
                appendLog("Pengisian air selesai di " .. campName .. ".")
                hasRefilledWaterAtCurrentCamp = true
                lastRefillCamp = campName
            else
                appendLog("Gagal teleport ke titik isi air di " .. campName .. ".")
            end
        else
            appendLog("Lokasi isi air tidak terdefinisi untuk " .. campName .. ".")
        end
    else
        appendLog("Tidak dapat menentukan lokasi isi air untuk camp saat ini.")
    end
end

-- Fungsi untuk minum air
local function drinkWater()
    if LocalPlayer and LocalPlayer.Character then
        local waterBottle = LocalPlayer.Character:FindFirstChild("Water Bottle") -- Pastikan nama item ini benar
        if waterBottle then
            local remoteEvent = waterBottle:FindFirstChild("RemoteEvent") -- Pastikan nama RemoteEvent ini benar
            if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                for i = 1, timers.water_drink_count do
                    if not autoTeleportActive and not scriptRunning then break end -- Hentikan jika skrip dihentikan
                    remoteEvent:FireServer()
                    appendLog("Minum air (" .. i .. "/" .. timers.water_drink_count .. "x)")
                    task.wait(0.6) -- Delay antar minum sedikit lebih lama
                end
                appendLog("Selesai minum air.")
                waterDrinkCounter = 0
            else
                appendLog("RemoteEvent 'RemoteEvent' tidak ditemukan di dalam 'Water Bottle'.")
            end
        else
            appendLog("'Water Bottle' tidak ditemukan pada karakter.")
        end
    else
        appendLog("Karakter pemain tidak ditemukan untuk minum air.")
    end
end

-- // Fungsi Auto Teleport //
local function autoTeleportCycle()
    local locations = {
        "Camp 1 Main Tent", "Camp 1 Checkpoint",
        "Camp 2 Main Tent", "Camp 2 Checkpoint",
        "Camp 3 Main Tent", "Camp 3 Checkpoint",
        "Camp 4 Main Tent", "Camp 4 Checkpoint",
        "South Pole Checkpoint"
    }
    local currentPointIndex = 1

    while autoTeleportActive and scriptRunning do
        local locationName = locations[currentPointIndex]
        local cframeTarget = teleportLocations[locationName]

        if locationName:find("Camp") and not locationName:find("Checkpoint") then
            local currentCampNumberStr = locationName:match("Camp (%d)")
            if currentCampNumberStr then
                 local currentCampId = "Camp " .. currentCampNumberStr
                if lastRefillCamp ~= currentCampId then
                    hasRefilledWaterAtCurrentCamp = false
                end
            end
        end

        if cframeTarget then
            updateStatus("AUTO-TP KE: " .. string.upper(locationName))
            appendLog("Memulai auto-teleport ke: " .. locationName)

            if not teleportPlayer(cframeTarget, locationName) then
                appendLog("Auto-teleport gagal untuk " .. locationName .. ". Mencoba lagi dalam 5 detik...")
                waitSeconds(5)
            end
            if not autoTeleportActive then break end

            if locationName:find("Camp") and not locationName:find("Checkpoint") then
                local campNumberStr = locationName:match("Camp (%d)")
                if campNumberStr then
                    refillWater("Camp " .. campNumberStr)
                end
            end
            if not autoTeleportActive then break end

            appendLog("Menunggu " .. timers.teleport_wait_time .. " detik di " .. locationName)
            local remainingTime = timers.teleport_wait_time
            while remainingTime > 0 and autoTeleportActive and scriptRunning do
                updateStatus(string.format("AUTO-TP: %s (%d detik)", string.upper(locationName), math.floor(remainingTime)))
                task.wait(1)
                remainingTime = remainingTime - 1
            end
            if not autoTeleportActive then break end

            currentPointIndex = currentPointIndex + 1
            if currentPointIndex > #locations then
                currentPointIndex = 1
                appendLog("Siklus auto-teleport selesai. Memulai ulang siklus.")
            end

            if autoTeleportActive then
                appendLog("Delay " .. timers.teleport_delay_between_points .. " detik sebelum teleport berikutnya.")
                waitSeconds(timers.teleport_delay_between_points)
            end
        else
            appendLog("Error: CFrame tidak ditemukan untuk lokasi: " .. locationName)
            updateStatus("ERROR: LOKASI_TIDAK_DITEMUKAN")
            waitSeconds(5)
        end
    end
    if scriptRunning then -- Hanya update status jika script masih berjalan
        updateStatus(autoTeleportActive and "AUTO_TELEPORT_BERJALAN" or "AUTO_TELEPORT_BERHENTI")
    end
    appendLog("Urutan auto-teleport dihentikan.")
end

-- // Tombol Start/Stop Auto Teleport //
StartAutoTeleportButton.MouseButton1Click:Connect(function()
    if not scriptRunning then scriptRunning = true end -- Aktifkan jika belum
    autoTeleportActive = not autoTeleportActive
    if autoTeleportActive then
        StartAutoTeleportButton.Text = "STOP AUTO TELEPORT"
        StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(200, 40, 40) -- Merah terang saat aktif
        StartAutoTeleportButton.TextColor3 = Color3.fromRGB(255,255,255)
        updateStatus("AUTO_TELEPORT_AKTIF")
        appendLog("Urutan auto teleport dimulai.")
        if not autoTeleportThread or coroutine.status(autoTeleportThread) == "dead" then
            autoTeleportThread = task.spawn(autoTeleportCycle)
        end
    else
        StartAutoTeleportButton.Text = "START AUTO TELEPORT"
        StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(70, 30, 30) -- Kembali ke warna awal
        StartAutoTeleportButton.TextColor3 = Color3.fromRGB(230,230,230)
        updateStatus("PERMINTAAN_BERHENTI")
        appendLog("Permintaan penghentian auto teleport.")
        -- autoTeleportActive sudah false, loop autoTeleportCycle akan berhenti
    end
end)

-- // Tombol Apply Timers //
ApplyTimersButton.MouseButton1Click:Connect(function()
    local function applyTextInput(inputElement, timerKey, labelElement)
        local success = false; if not inputElement then return false end
        local value = tonumber(inputElement.Text)
        if value and value >= 0 then timers[timerKey] = value
            if labelElement and labelElement.Parent then pcall(function() labelElement.TextColor3 = Color3.fromRGB(100,255,100) end) end; success = true
        else if labelElement and labelElement.Parent then pcall(function() labelElement.TextColor3 = Color3.fromRGB(255,100,100) end) end
        end
        return success
    end
    local allTimersValid = true
    allTimersValid = applyTextInput(timerInputElements.teleportWaitTimeInput, "teleport_wait_time", timerInputElements.TeleportWaitTimeLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.teleportDelayBetweenPointsInput, "teleport_delay_between_points", timerInputElements.TeleportDelayBetweenPointsLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.waterRefillDurationInput, "water_refill_duration", timerInputElements.WaterRefillDurationLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.waterDrinkIntervalInput, "water_drink_interval", timerInputElements.WaterDrinkIntervalLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.waterDrinkCountInput, "water_drink_count", timerInputElements.WaterDrinkCountLabel) and allTimersValid

    local originalStatusText = StatusLabel.Text
    if allTimersValid then updateStatus("PENGATURAN_DITERAPKAN") else updateStatus("ERR_INPUT_TIDAK_VALID") end
    appendLog("Mencoba menerapkan pengaturan. Valid: " .. tostring(allTimersValid))
    task.delay(2, function() -- Gunakan task.delay untuk non-blocking wait
        local defaultColor = Color3.fromRGB(190,190,210)
        if timerInputElements.TeleportWaitTimeLabel and timerInputElements.TeleportWaitTimeLabel.Parent then pcall(function() timerInputElements.TeleportWaitTimeLabel.TextColor3 = defaultColor end) end
        if timerInputElements.TeleportDelayBetweenPointsLabel and timerInputElements.TeleportDelayBetweenPointsLabel.Parent then pcall(function() timerInputElements.TeleportDelayBetweenPointsLabel.TextColor3 = defaultColor end) end
        if timerInputElements.WaterRefillDurationLabel and timerInputElements.WaterRefillDurationLabel.Parent then pcall(function() timerInputElements.WaterRefillDurationLabel.TextColor3 = defaultColor end) end
        if timerInputElements.WaterDrinkIntervalLabel and timerInputElements.WaterDrinkIntervalLabel.Parent then pcall(function() timerInputElements.WaterDrinkIntervalLabel.TextColor3 = defaultColor end) end
        if timerInputElements.WaterDrinkCountLabel and timerInputElements.WaterDrinkCountLabel.Parent then pcall(function() timerInputElements.WaterDrinkCountLabel.TextColor3 = defaultColor end) end
        if StatusLabel and StatusLabel.Parent then StatusLabel.Text = originalStatusText end -- Kembalikan status asli
    end)
end)

-- // Manual Teleport Logic (Dropdown) //
local function populateDropdownOptions()
    for _, child in ipairs(TeleportDropdownOptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local orderedLocations = {
        "Camp 1 Main Tent", "Camp 1 Checkpoint", "WaterRefill_Camp1",
        "Camp 2 Main Tent", "Camp 2 Checkpoint", "WaterRefill_Camp2",
        "Camp 3 Main Tent", "Camp 3 Checkpoint", "WaterRefill_Camp3",
        "Camp 4 Main Tent", "Camp 4 Checkpoint", "WaterRefill_Camp4",
        "South Pole Checkpoint"
    }

    local optionHeight = 28 -- Tinggi opsi sedikit lebih besar
    for i, locationName in ipairs(orderedLocations) do
        if teleportLocations[locationName] then
            local optionButton = Instance.new("TextButton")
            optionButton.Name = "Option_" .. locationName:gsub("%s+", "") -- Nama unik
            optionButton.Parent = TeleportDropdownOptionsFrame
            optionButton.Size = UDim2.new(1, 0, 0, optionHeight)
            optionButton.Text = locationName
            optionButton.Font = Enum.Font.SourceSans
            optionButton.TextSize = 13
            optionButton.TextColor3 = Color3.fromRGB(220, 220, 220)
            optionButton.BackgroundColor3 = Color3.fromRGB(45, 47, 55) -- Warna latar opsi
            optionButton.BorderSizePixel = 0
            optionButton.TextXAlignment = Enum.TextXAlignment.Left
            optionButton.TextWrapped = true
            optionButton.TextPadding = UDim.new(0,8)
            local optCorner = Instance.new("UICorner")
            optCorner.CornerRadius = UDim.new(0,4)
            optCorner.Parent = optionButton

            optionButton.MouseEnter:Connect(function() optionButton.BackgroundColor3 = Color3.fromRGB(60, 62, 70) end)
            optionButton.MouseLeave:Connect(function() optionButton.BackgroundColor3 = Color3.fromRGB(45, 47, 55) end)

            optionButton.MouseButton1Click:Connect(function()
                TeleportLocationSelector.Text = locationName
                TeleportDropdownOptionsFrame.Visible = false
                TeleportButton.Position = UDim2.new(0, 10, 0, 85)
            end)
        end
    end
    local numOptions = #TeleportDropdownOptionsFrame:GetChildren() - 1 -- Kurangi UIListLayout
    TeleportDropdownOptionsFrame.CanvasSize = UDim2.new(0, 0, 0, numOptions * (optionHeight + UIListLayout.Padding.Offset))
    TeleportDropdownOptionsFrame.Size = UDim2.new(0, TeleportLocationSelector.AbsoluteSize.X, 0, math.min(160, TeleportDropdownOptionsFrame.CanvasSize.Y.Offset))
end

TeleportLocationSelector.MouseButton1Click:Connect(function()
    if TeleportDropdownOptionsFrame.Visible then
        TeleportDropdownOptionsFrame.Visible = false
        TeleportButton.Position = UDim2.new(0, 10, 0, 85)
    else
        populateDropdownOptions()
        local selectorAbsPos = TeleportLocationSelector.AbsolutePosition
        local frameAbsPos = Frame.AbsolutePosition
        local dropdownWidth = TeleportLocationSelector.AbsoluteSize.X
        
        TeleportDropdownOptionsFrame.Size = UDim2.new(0, dropdownWidth, 0, math.min(160, TeleportDropdownOptionsFrame.CanvasSize.Y.Offset))
        TeleportDropdownOptionsFrame.Position = UDim2.fromOffset(selectorAbsPos.X - frameAbsPos.X, selectorAbsPos.Y - frameAbsPos.Y + TeleportLocationSelector.AbsoluteSize.Y + 5)
        TeleportDropdownOptionsFrame.Visible = true
        TeleportButton.Position = UDim2.new(0, 10, 0, 85 + TeleportDropdownOptionsFrame.Size.Y.Offset + 10)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if TeleportDropdownOptionsFrame.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
        local mousePos = UserInputService:GetMouseLocation()
        local isOverDropdown = mousePos.X >= TeleportDropdownOptionsFrame.AbsolutePosition.X and
                               mousePos.X <= TeleportDropdownOptionsFrame.AbsolutePosition.X + TeleportDropdownOptionsFrame.AbsoluteSize.X and
                               mousePos.Y >= TeleportDropdownOptionsFrame.AbsolutePosition.Y and
                               mousePos.Y <= TeleportDropdownOptionsFrame.AbsolutePosition.Y + TeleportDropdownOptionsFrame.AbsoluteSize.Y
        local isOverSelector = mousePos.X >= TeleportLocationSelector.AbsolutePosition.X and
                               mousePos.X <= TeleportLocationSelector.AbsolutePosition.X + TeleportLocationSelector.AbsoluteSize.X and
                               mousePos.Y >= TeleportLocationSelector.AbsolutePosition.Y and
                               mousePos.Y <= TeleportLocationSelector.AbsolutePosition.Y + TeleportLocationSelector.AbsoluteSize.Y

        if not isOverDropdown and not isOverSelector then
            TeleportDropdownOptionsFrame.Visible = false
            TeleportButton.Position = UDim2.new(0, 10, 0, 85)
        end
    end
end)

TeleportButton.MouseButton1Click:Connect(function()
    if not scriptRunning then scriptRunning = true end
    local selectedLocation = TeleportLocationSelector.Text
    local cframe = teleportLocations[selectedLocation]
    if cframe then
        teleportPlayer(cframe, selectedLocation)
        if selectedLocation:find("WaterRefill_Camp") then
            local campNumberStr = selectedLocation:match("WaterRefill_Camp(%d)")
            if campNumberStr then
                refillWater("Camp " .. campNumberStr)
            end
        end
    elseif selectedLocation == "Pilih Lokasi..." then
        appendLog("Error Teleport Manual: Lokasi belum dipilih.")
        updateStatus("MANUAL_TP_ERROR: LOKASI BELUM DIPILIH")
    else
        appendLog("Error Teleport Manual: Lokasi '" .. selectedLocation .. "' tidak ditemukan.")
        updateStatus("MANUAL_TP_ERROR: LOKASI TIDAK VALID")
    end
end)

-- // Log Clearing Loop //
task.spawn(function()
    while scriptRunning do
        task.wait(timers.log_clear_interval)
        if scriptRunning then -- Cek lagi sebelum clear
            clearLog()
        end
    end
end)

-- // Water Drink Timer Loop //
task.spawn(function()
    while scriptRunning do
        task.wait(1)
        if autoTeleportActive or scriptRunning then -- Hanya berjalan jika auto-teleport aktif atau skrip utama berjalan
            waterDrinkTimer = waterDrinkTimer + 1
            if waterDrinkTimer >= timers.water_drink_interval then
                waterDrinkCounter = waterDrinkCounter + 1 -- Ini seharusnya direset di drinkWater
                appendLog("Waktunya minum air! (" .. waterDrinkCounter .. "/" .. timers.water_drink_count .. "x)")
                drinkWater()
                waterDrinkTimer = 0
            end
        else
            waterDrinkTimer = 0 -- Reset jika tidak aktif
        end
    end
end)

-- --- ANIMASI UI ---
task.spawn(function() -- Animasi Latar Belakang Frame (Glitchy Border)
    if not Frame or not Frame.Parent then return end
    local baseColor = Frame.BackgroundColor3
    local glitchColors = {
        Color3.fromRGB(40, 20, 30), Color3.fromRGB(10, 10, 15), Color3.fromRGB(255,0,50), Color3.fromRGB(0,50,255)
    }
    local borderBaseColor = Frame.BorderColor3
    local borderGlitchColors = {
        Color3.fromRGB(0,255,255), Color3.fromRGB(255,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(100,100,255)
    }
    local borderThicknessBase = Frame.BorderSizePixel
    local originalPosition = Frame.Position -- Simpan posisi awal untuk reset

    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if Frame and Frame.Parent then
            if not isMinimized then
                local r = math.random()
                if r < 0.08 then -- Glitch intens (lebih jarang)
                    Frame.BackgroundColor3 = glitchColors[math.random(#glitchColors)]
                    Frame.BorderColor3 = borderGlitchColors[math.random(#borderGlitchColors)]
                    Frame.BorderSizePixel = math.random(3, 6)
                    Frame.BackgroundTransparency = math.random() * 0.3
                    Frame.Position = originalPosition + UDim2.fromOffset(math.random(-2,2), math.random(-2,2))
                    task.wait(0.03)
                    Frame.BackgroundColor3 = glitchColors[math.random(#glitchColors)]
                    Frame.BorderColor3 = borderGlitchColors[math.random(#borderGlitchColors)]
                    Frame.BorderSizePixel = math.random(1, 4)
                    Frame.BackgroundTransparency = 0
                    Frame.Position = originalPosition -- Reset posisi
                    task.wait(0.03)
                elseif r < 0.3 then -- Glitch ringan
                    Frame.BackgroundColor3 = baseColor:Lerp(glitchColors[1], math.random())
                    Frame.BorderColor3 = borderBaseColor:Lerp(borderGlitchColors[1], math.random()*0.7)
                    Frame.BorderSizePixel = math.random(borderThicknessBase, borderThicknessBase + 1)
                    Frame.BackgroundTransparency = 0
                    task.wait(0.08)
                else
                    Frame.BackgroundColor3 = baseColor
                    Frame.BorderColor3 = borderBaseColor
                    Frame.BorderSizePixel = borderThicknessBase
                    Frame.BackgroundTransparency = 0
                end
                local h,s,v = Color3.toHSV(Frame.BorderColor3)
                Frame.BorderColor3 = Color3.fromHSV((h + 0.008)%1, s, v) -- HSV shift lebih cepat
            else -- Saat minimized
                Frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
                Frame.BorderColor3 = Color3.fromRGB(255, 20, 20)
                Frame.BorderSizePixel = 2
                Frame.BackgroundTransparency = 0
                -- Posisi sudah diatur oleh toggleMinimize
            end
        end
        task.wait(0.04)
    end
end)

task.spawn(function() -- Animasi UiTitleLabel
    if not UiTitleLabel or not UiTitleLabel.Parent then return end
    local originalText1 = "ANTARCTIC TELEPORT"
    local originalText2 = "ZEDLIST X ZXHELL"
    local currentTargetText = originalText1
    local glitchChars = {"@", "#", "$", "%", "&", "*", "!", "?", "/", "\\", "|", "_", "1", "0", "Z", "X"}
    local baseColor = UiTitleLabel.TextColor3
    local originalPos = UiTitleLabel.Position
    local transitionTime = 1.3
    local displayTime = 4.5

    local function applyGlitch(text)
        local newText = ""
        for i = 1, #text do
            if math.random() < 0.65 then
                newText = newText .. glitchChars[math.random(#glitchChars)]
            else
                newText = newText .. text:sub(i,i)
            end
        end
        return newText
    end

    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if UiTitleLabel and UiTitleLabel.Parent then
            if not isMinimized then
                local startTime = tick()
                while tick() - startTime < transitionTime and not isMinimized do
                    local progress = (tick() - startTime) / transitionTime
                    local mixedText = ""
                    local textToGlitch = (currentTargetText == originalText1) and originalText2 or originalText1

                    for i = 1, math.max(#currentTargetText, #textToGlitch) do
                        local char1 = currentTargetText:sub(i,i)
                        local char2 = textToGlitch:sub(i,i)
                        if math.random() < progress then
                            mixedText = mixedText .. (char2 ~= "" and char2 or glitchChars[math.random(#glitchChars)])
                        else
                            mixedText = mixedText .. (char1 ~= "" and char1 or glitchChars[math.random(#glitchChars)])
                        end
                    end
                    UiTitleLabel.Text = applyGlitch(mixedText)
                    UiTitleLabel.TextColor3 = Color3.fromHSV(math.random(), 0.8, 1) -- Saturation sedikit dikurangi
                    UiTitleLabel.Position = originalPos + UDim2.fromOffset(math.random(-2,2), math.random(-1,1))
                    UiTitleLabel.Rotation = math.random(-10,10) * 0.05 -- Rotasi glitch lebih kecil
                    task.wait(0.04)
                end
                if isMinimized then task.wait(0.05); continue end -- Jika termiminize saat transisi

                UiTitleLabel.Text = currentTargetText
                local hue = (tick()*0.15) % 1
                local r_rgb, g_rgb, b_rgb = Color3.fromHSV(hue, 1, 1).R, Color3.fromHSV(hue, 1, 1).G, Color3.fromHSV(hue, 1, 1).B
                r_rgb = math.min(1, r_rgb + 0.7)
                g_rgb = g_rgb * 0.35
                b_rgb = b_rgb * 0.35
                UiTitleLabel.TextColor3 = Color3.new(r_rgb, g_rgb, b_rgb)
                UiTitleLabel.TextStrokeTransparency = 0.6
                UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(60,0,0)
                UiTitleLabel.Position = originalPos
                UiTitleLabel.Rotation = 0
                
                task.wait(displayTime)
                if isMinimized then task.wait(0.05); continue end

                if currentTargetText == originalText1 then currentTargetText = originalText2 else currentTargetText = originalText1 end
            else
                UiTitleLabel.Text = originalText1
                UiTitleLabel.TextColor3 = baseColor
                UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(60,0,0)
                UiTitleLabel.Position = originalPos
                UiTitleLabel.Rotation = 0
                task.wait(0.05)
            end
        end
    end
end)

task.spawn(function() -- Animasi Tombol (Pulse & Hover)
    local buttonsToAnimate = {StartAutoTeleportButton, ApplyTimersButton, MinimizeButton, TeleportButton, TeleportLocationSelector}
    local originalButtonColors = {}
    for _, btn in ipairs(buttonsToAnimate) do
        if btn and btn.Parent then originalButtonColors[btn] = {bg = btn.BackgroundColor3, border = btn.BorderColor3} end
    end

    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if not isMinimized then
            for _, btn in ipairs(buttonsToAnimate) do
                if btn and btn.Parent and originalButtonColors[btn] then
                    local orig = originalButtonColors[btn]
                    if btn.Name == "StartAutoTeleportButton" and autoTeleportActive then
                        btn.BorderColor3 = Color3.fromRGB(255,120,120)
                        btn.BackgroundColor3 = Color3.fromRGB(220, 50, 50) -- Warna BG lebih terang saat aktif
                    else
                        local h,s,v = Color3.toHSV(orig.border)
                        btn.BorderColor3 = Color3.fromHSV(h,s, math.sin(tick()*2.5)*0.1 + 0.9)
                        -- Efek hover sederhana (jika tidak ada input service yang menangani ini secara eksplisit)
                        -- Untuk Arceus X, MouseEnter/MouseLeave mungkin tidak selalu reliable, jadi pulse cukup
                        if btn.Name ~= "StartAutoTeleportButton" or not autoTeleportActive then
                             btn.BackgroundColor3 = orig.bg -- Kembalikan BG jika tidak aktif
                        end
                    end
                end
            end
        end
        task.wait(0.08)
    end
end)

task.spawn(function() -- Animasi Pop-up 'Z' (RGB Pulse)
    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if minimizedZLabel and minimizedZLabel.Parent then
            if isMinimized and minimizedZLabel.Visible then
                local hue = (tick() * 0.25) % 1
                minimizedZLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
                minimizedZLabel.TextStrokeColor3 = Color3.fromHSV(hue,1,0.5)
                minimizedZLabel.TextStrokeTransparency = 0.3
            else
                 minimizedZLabel.TextStrokeTransparency = 1 -- Sembunyikan stroke jika tidak visible
            end
        end
        task.wait(0.04)
    end
end)
-- --- END ANIMASI UI ---

game:BindToClose(function()
    scriptRunning = false
    autoTeleportActive = false
    warn("Game ditutup, menghentikan skrip...");
    task.wait(0.5) -- Beri waktu untuk loop berhenti
    if ScreenGui and ScreenGui.Parent then pcall(function() ScreenGui:Destroy() end) end
    print("Pembersihan skrip selesai.")
end)

-- Inisialisasi
scriptRunning = true -- Set scriptRunning ke true di awal
print("Skrip Teleportasi Ekspedisi Antartika (Zedlist X Zxhell) Telah Dimuat.")
task.wait(0.5)
if StatusLabel and StatusLabel.Parent and StatusLabel.Text == "" then StatusLabel.Text = "STATUS: STANDBY" end
appendLog("UI berhasil dimuat. Sistem siap.")

-- Pastikan semua elemen UI utama terlihat saat pertama kali dimuat jika tidak minimized
if not isMinimized then
    for _, element in ipairs(elementsToToggleVisibility) do
        if element and element.Parent then element.Visible = true end
    end
    if MinimizeButton and MinimizeButton.Parent then MinimizeButton.Visible = true end
end
