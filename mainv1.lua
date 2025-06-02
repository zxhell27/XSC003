
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

local TeleportLocationSelector = Instance.new("TextButton") -- Changed from TextBox to TextButton for dropdown trigger
TeleportLocationSelector.Name = "TeleportLocationSelector"

local TeleportDropdownOptionsFrame = Instance.new("ScrollingFrame") -- Frame for dropdown options
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
local originalFrameSize = UDim2.new(0, 300, 0, 550) -- Ukuran UI disesuaikan
local minimizedFrameSize = UDim2.new(0, 50, 0, 50) -- Ukuran pop-up 'Z'
local minimizedZLabel = Instance.new("TextLabel") -- Label khusus untuk pop-up 'Z'

-- Kumpulan elemen yang visibilitasnya akan di-toggle
local elementsToToggleVisibility = {} -- Akan diisi setelah semua elemen UI dibuat

-- --- Tabel Konfigurasi Timer ---
local timers = {
    teleport_wait_time = 300, -- Default 5 menit (300 detik)
    teleport_delay_between_points = 5, -- Delay antar teleportasi dalam rute auto
    log_clear_interval = 60, -- Interval untuk membersihkan log (detik)
    teleport_y_offset = 5, -- Offset Y untuk mencegah clipping saat teleportasi
}

-- --- Definisi Titik Teleportasi (Ekspedisi Antartika) ---
-- Menggunakan struktur tabel untuk memudahkan pengelolaan dan penambahan
-- Nama harus unik dan mudah dibaca di UI
-- CFrame: x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22
local teleportLocations = {
    -- Camp 1
    ["Camp 1 Main Tent"] = CFrame.new(-3694.08691, 225.826172, 277.052979, 0.710165381, 0, 0.704034865, 0, 1, 0, -0.704034865, 0, 0.710165381),
    ["Camp 1 Checkpoint"] = CFrame.new(-3719.18188, 223.203995, 235.391006, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    -- Camp 2
    ["Camp 2 Main Tent"] = CFrame.new(1774.76111, 102.314171, -179.4328, -0.790706277, 0, -0.612195849, 0, 1, 0, 0.612195849, 0, -0.790706277),
    ["Camp 2 Checkpoint"] = CFrame.new(1790.31799, 103.665001, -137.858994, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    -- Camp 3
    ["Camp 3 Main Tent"] = CFrame.new(5853.9834, 325.546478, -0.24318853, 0.494506121, -0, -0.869174123, 0, 1, -0, 0.869174123, 0, 0.494506121),
    ["Camp 3 Checkpoint"] = CFrame.new(5892.38916, 319.35498, -19.0779991, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    -- Camp 4
    ["Camp 4 Main Tent"] = CFrame.new(8999.26465, 593.866089, 59.4377747, -0.999371052, 0, 0.035472773, 0, 1, 0, -0.035472773, 0, -0.999371052),
    ["Camp 4 Checkpoint"] = CFrame.new(8992.36328, 594.10498, 103.060997, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    -- South Pole
    ["South Pole Checkpoint"] = CFrame.new(10995.2461, 545.255127, 114.804474, 0.819186032, 0.573527873, 3.9935112e-06, -3.9935112e-06, 1.2755394e-05, -1, -0.573527873, 0.819186091, 1.2755394e-05),
}

-- // Parent UI ke player //
local function setupCoreGuiParenting()
    local coreGuiService = game:GetService("CoreGui")
    if not ScreenGui.Parent or ScreenGui.Parent ~= coreGuiService then
        ScreenGui.Parent = coreGuiService
    end
    if not Frame.Parent or Frame.Parent ~= ScreenGui then
        Frame.Parent = ScreenGui
    end
    -- Pastikan semua elemen UI diparenting di sini
    UiTitleLabel.Parent = Frame
    StartAutoTeleportButton.Parent = Frame
    StatusLabel.Parent = Frame
    MinimizeButton.Parent = Frame
    TimerTitleLabel.Parent = Frame
    ApplyTimersButton.Parent = Frame
    minimizedZLabel.Parent = Frame -- Parentkan label Z ke Frame
    ManualTeleportFrame.Parent = Frame
    ManualTeleportTitle.Parent = ManualTeleportFrame
    TeleportLocationSelector.Parent = ManualTeleportFrame -- Changed parent
    TeleportDropdownOptionsFrame.Parent = Frame -- Explicitly parent to Frame for dropdown visibility
    TeleportButton.Parent = ManualTeleportFrame
    LogFrame.Parent = Frame
    LogTitle.Parent = LogFrame
    LogOutput.Parent = LogFrame
end

-- Panggil setupCoreGuiParenting di awal
setupCoreGuiParenting()

-- // Desain UI //

-- --- Frame Utama ---
Frame.Size = originalFrameSize
Frame.Position = UDim2.new(0.5, -Frame.Size.X.Offset/2, 0.5, -Frame.Size.Y.Offset/2) -- Tengah layar
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Latar belakang gelap kebiruan
Frame.Active = true
Frame.Draggable = true
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Awalnya merah, akan dianimasikan
Frame.ClipsDescendants = false -- Changed to false to allow dropdown to extend outside
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10) -- Sudut lebih membulat
UICorner.Parent = Frame

-- --- Nama UI Label ("ANTARCTIC TELEPORT") ---
UiTitleLabel.Size = UDim2.new(1, -20, 0, 35) -- Lebih kecil sedikit
UiTitleLabel.Position = UDim2.new(0, 10, 0, 10)
UiTitleLabel.Font = Enum.Font.SourceSansSemibold
UiTitleLabel.Text = "ANTARCTIC TELEPORT"
UiTitleLabel.TextColor3 = Color3.fromRGB(255, 25, 25)
UiTitleLabel.TextScaled = false
UiTitleLabel.TextSize = 24 -- Ukuran font sedang
UiTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
UiTitleLabel.BackgroundTransparency = 1
UiTitleLabel.ZIndex = 2
UiTitleLabel.TextStrokeTransparency = 0.5
UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)

local yOffsetForTitle = 50 -- Jarak dari atas frame ke elemen berikutnya

-- --- Tombol Start/Stop Auto Teleport ---
StartAutoTeleportButton.Size = UDim2.new(1, -40, 0, 35)
StartAutoTeleportButton.Position = UDim2.new(0, 20, 0, yOffsetForTitle)
StartAutoTeleportButton.Text = "START AUTO TELEPORT"
StartAutoTeleportButton.Font = Enum.Font.SourceSansBold
StartAutoTeleportButton.TextSize = 16
StartAutoTeleportButton.TextColor3 = Color3.fromRGB(220, 220, 220)
StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
StartAutoTeleportButton.BorderSizePixel = 1
StartAutoTeleportButton.BorderColor3 = Color3.fromRGB(255, 50, 50)
StartAutoTeleportButton.ZIndex = 2

local StartButtonCorner = Instance.new("UICorner")
StartButtonCorner.CornerRadius = UDim.new(0, 5)
StartButtonCorner.Parent = StartAutoTeleportButton

-- --- Status Label ---
StatusLabel.Size = UDim2.new(1, -40, 0, 45)
StatusLabel.Position = UDim2.new(0, 20, 0, yOffsetForTitle + 45)
StatusLabel.Text = "STATUS: STANDBY"
StatusLabel.Font = Enum.Font.SourceSansLight
StatusLabel.TextSize = 14
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BorderSizePixel = 0
StatusLabel.ZIndex = 2

local StatusLabelCorner = Instance.new("UICorner")
StatusLabelCorner.CornerRadius = UDim.new(0, 5)
StatusLabelCorner.Parent = StatusLabel

local yOffsetForTimers = yOffsetForTitle + 100

-- --- Konfigurasi Timer UI ---
TimerTitleLabel.Size = UDim2.new(1, -40, 0, 20)
TimerTitleLabel.Position = UDim2.new(0, 20, 0, yOffsetForTimers)
TimerTitleLabel.Text = "// AUTO TELEPORT SETTINGS"
TimerTitleLabel.Font = Enum.Font.Code
TimerTitleLabel.TextSize = 14
TimerTitleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
TimerTitleLabel.BackgroundTransparency = 1
TimerTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TimerTitleLabel.ZIndex = 2

local function createTimerInput(name, yPos, labelText, initialValue)
    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Parent = Frame
    label.Size = UDim2.new(0.55, -25, 0, 20)
    label.Position = UDim2.new(0, 20, 0, yPos + yOffsetForTimers)
    label.Text = labelText .. ":"
    label.Font = Enum.Font.SourceSans
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(180, 180, 200)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    timerInputElements[name .. "Label"] = label

    local input = Instance.new("TextBox")
    input.Name = name .. "Input"
    input.Parent = Frame
    input.Size = UDim2.new(0.45, -25, 0, 20)
    input.Position = UDim2.new(0.55, 5, 0, yPos + yOffsetForTimers)
    input.Text = tostring(initialValue)
    input.PlaceholderText = "seconds"
    input.Font = Enum.Font.SourceSansSemibold
    input.TextSize = 12
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    input.ClearTextOnFocus = false
    input.BorderColor3 = Color3.fromRGB(100, 100, 120)
    input.BorderSizePixel = 1
    input.ZIndex = 2
    timerInputElements[name .. "Input"] = input

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 3)
    InputCorner.Parent = input

    return input
end

local currentYConfig = 30
timerInputElements.teleportWaitTimeInput = createTimerInput("TeleportWaitTime", currentYConfig, "Wait Time (Auto)", timers.teleport_wait_time)
currentYConfig = currentYConfig + 25
timerInputElements.teleportDelayBetweenPointsInput = createTimerInput("TeleportDelayBetweenPoints", currentYConfig, "Delay Between Points", timers.teleport_delay_between_points)
currentYConfig = currentYConfig + 35

ApplyTimersButton.Size = UDim2.new(1, -40, 0, 30)
ApplyTimersButton.Position = UDim2.new(0, 20, 0, currentYConfig + yOffsetForTimers)
ApplyTimersButton.Text = "APPLY SETTINGS"
ApplyTimersButton.Font = Enum.Font.SourceSansBold
ApplyTimersButton.TextSize = 14
ApplyTimersButton.TextColor3 = Color3.fromRGB(220, 220, 220)
ApplyTimersButton.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
ApplyTimersButton.BorderColor3 = Color3.fromRGB(80, 255, 80)
ApplyTimersButton.BorderSizePixel = 1
ApplyTimersButton.ZIndex = 2

local ApplyButtonCorner = Instance.new("UICorner")
ApplyButtonCorner.CornerRadius = UDim.new(0, 5)
ApplyButtonCorner.Parent = ApplyTimersButton

local yOffsetForManualTeleport = currentYConfig + yOffsetForTimers + 40

-- --- Manual Teleport Section ---
ManualTeleportFrame.Size = UDim2.new(1, -40, 0, 120)
ManualTeleportFrame.Position = UDim2.new(0, 20, 0, yOffsetForManualTeleport)
ManualTeleportFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ManualTeleportFrame.BorderSizePixel = 1
ManualTeleportFrame.BorderColor3 = Color3.fromRGB(100, 100, 120)
ManualTeleportFrame.ClipsDescendants = false -- Changed to false to allow dropdown to extend outside
ManualTeleportFrame.ZIndex = 2

local ManualFrameCorner = Instance.new("UICorner")
ManualFrameCorner.CornerRadius = UDim.new(0, 5)
ManualFrameCorner.Parent = ManualTeleportFrame

ManualTeleportTitle.Size = UDim2.new(1, -20, 0, 20)
ManualTeleportTitle.Position = UDim2.new(0, 10, 0, 10)
ManualTeleportTitle.Text = "// MANUAL TELEPORT"
ManualTeleportTitle.Font = Enum.Font.Code
ManualTeleportTitle.TextSize = 14
ManualTeleportTitle.TextColor3 = Color3.fromRGB(80, 200, 255) -- Biru terang
ManualTeleportTitle.BackgroundTransparency = 1
ManualTeleportTitle.TextXAlignment = Enum.TextXAlignment.Left
ManualTeleportTitle.ZIndex = 2

-- Teleport Location Selector (Trigger for Dropdown)
TeleportLocationSelector.Size = UDim2.new(1, -20, 0, 30)
TeleportLocationSelector.Position = UDim2.new(0, 10, 0, 40)
TeleportLocationSelector.Text = "Select Location..."
TeleportLocationSelector.Font = Enum.Font.SourceSansSemibold
TeleportLocationSelector.TextSize = 14
TeleportLocationSelector.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportLocationSelector.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TeleportLocationSelector.BorderSizePixel = 1
TeleportLocationSelector.BorderColor3 = Color3.fromRGB(100, 100, 120)
TeleportLocationSelector.ZIndex = 2
TeleportLocationSelector.TextXAlignment = Enum.TextXAlignment.Left
TeleportLocationSelector.TextWrapped = true

local SelectorCorner = Instance.new("UICorner")
SelectorCorner.CornerRadius = UDim.new(0, 3)
SelectorCorner.Parent = TeleportLocationSelector

-- Dropdown Options Frame (ScrollingFrame)
-- Parented to Frame to avoid clipping issues with ManualTeleportFrame's ClipsDescendants
TeleportDropdownOptionsFrame.Parent = Frame
TeleportDropdownOptionsFrame.Size = UDim2.new(0, ManualTeleportFrame.Size.X.Offset - 20, 0, 100) -- Initial size, will expand
TeleportDropdownOptionsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TeleportDropdownOptionsFrame.BorderSizePixel = 1
TeleportDropdownOptionsFrame.BorderColor3 = Color3.fromRGB(100, 100, 120)
TeleportDropdownOptionsFrame.ZIndex = 5 -- Higher ZIndex to appear above all
TeleportDropdownOptionsFrame.Visible = false -- Hidden by default
TeleportDropdownOptionsFrame.ScrollBarThickness = 6
TeleportDropdownOptionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Automatically adjust canvas height

local DropdownOptionsCorner = Instance.new("UICorner")
DropdownOptionsCorner.CornerRadius = UDim.new(0, 3)
DropdownOptionsCorner.Parent = TeleportDropdownOptionsFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = TeleportDropdownOptionsFrame
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout.Padding = UDim.new(0, 2)

TeleportButton.Size = UDim2.new(1, -20, 0, 30)
TeleportButton.Position = UDim2.new(0, 10, 0, 80) -- Adjusted position for button (initial)
TeleportButton.Text = "TELEPORT"
TeleportButton.Font = Enum.Font.SourceSansBold
TeleportButton.TextSize = 14
TeleportButton.TextColor3 = Color3.fromRGB(220, 220, 220)
TeleportButton.BackgroundColor3 = Color3.fromRGB(20, 80, 80) -- Teal gelap
TeleportButton.BorderColor3 = Color3.fromRGB(50, 255, 255)
TeleportButton.BorderSizePixel = 1
TeleportButton.ZIndex = 2

local TeleportButtonCorner = Instance.new("UICorner")
TeleportButtonCorner.CornerRadius = UDim.new(0, 5)
TeleportButtonCorner.Parent = TeleportButton

local yOffsetForLog = yOffsetForManualTeleport + 130

-- --- Log Section ---
LogFrame.Size = UDim2.new(1, -40, 0, 100)
LogFrame.Position = UDim2.new(0, 20, 0, yOffsetForLog)
LogFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
LogFrame.BorderSizePixel = 1
LogFrame.BorderColor3 = Color3.fromRGB(100, 100, 120)
LogFrame.ZIndex = 2

local LogFrameCorner = Instance.new("UICorner")
LogFrameCorner.CornerRadius = UDim.new(0, 5)
LogFrameCorner.Parent = LogFrame

LogTitle.Size = UDim2.new(1, -20, 0, 20)
LogTitle.Position = UDim2.new(0, 10, 0, 10)
LogTitle.Text = "// STATUS LOG"
LogTitle.Font = Enum.Font.Code
LogTitle.TextSize = 14
LogTitle.TextColor3 = Color3.fromRGB(255, 200, 80) -- Oranye terang
LogTitle.BackgroundTransparency = 1
LogTitle.TextXAlignment = Enum.TextXAlignment.Left
LogTitle.ZIndex = 2

LogOutput.Size = UDim2.new(1, -20, 0, 60)
LogOutput.Position = UDim2.new(0, 10, 0, 35)
LogOutput.Text = "Log: System Ready."
LogOutput.Font = Enum.Font.SourceSansLight
LogOutput.TextSize = 11
LogOutput.TextColor3 = Color3.fromRGB(200, 200, 200)
LogOutput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
LogOutput.TextWrapped = true
LogOutput.TextXAlignment = Enum.TextXAlignment.Left
LogOutput.TextYAlignment = Enum.TextYAlignment.Top
LogOutput.BorderSizePixel = 0
LogOutput.ZIndex = 2

local LogOutputCorner = Instance.new("UICorner")
LogOutputCorner.CornerRadius = UDim.new(0, 3)
LogOutputCorner.Parent = LogOutput

-- --- Tombol Minimize ---
MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Position = UDim2.new(1, -35, 0, 10)
MinimizeButton.Text = "_" -- Simbol minimize
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.TextSize = 20
MinimizeButton.TextColor3 = Color3.fromRGB(180, 180, 180)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MinimizeButton.BorderColor3 = Color3.fromRGB(100,100,120)
MinimizeButton.BorderSizePixel = 1
MinimizeButton.ZIndex = 3

local MinimizeButtonCorner = Instance.new("UICorner")
MinimizeButtonCorner.CornerRadius = UDim.new(0, 3)
MinimizeButtonCorner.Parent = MinimizeButton

-- --- Pop-up 'Z' (Baru) ---
minimizedZLabel.Size = UDim2.new(1, 0, 1, 0) -- Akan mengisi seluruh Frame saat minimized
minimizedZLabel.Position = UDim2.new(0,0,0,0)
minimizedZLabel.Text = "Z"
minimizedZLabel.Font = Enum.Font.SourceSansBold
minimizedZLabel.TextScaled = false
minimizedZLabel.TextSize = 40 -- Ukuran besar agar memenuhi pop-up kecil
minimizedZLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Merah
minimizedZLabel.TextXAlignment = Enum.TextXAlignment.Center
minimizedZLabel.TextYAlignment = Enum.TextYAlignment.Center
minimizedZLabel.BackgroundTransparency = 1
minimizedZLabel.ZIndex = 4 -- Pastikan di atas semua
minimizedZLabel.Visible = false -- Awalnya sembunyi

-- Kumpulan elemen yang visibilitasnya akan di-toggle
elementsToToggleVisibility = {
    UiTitleLabel, StartAutoTeleportButton, StatusLabel, TimerTitleLabel, ApplyTimersButton,
    timerInputElements.teleportWaitTimeLabel, timerInputElements.teleportWaitTimeInput,
    timerInputElements.teleportDelayBetweenPointsLabel, timerInputElements.teleportDelayBetweenPointsInput,
    ManualTeleportFrame, LogFrame, MinimizeButton -- Include MinimizeButton here to hide it during 'Z' mode
}

-- // Fungsi Bantu UI //
local function updateStatus(text)
    if StatusLabel and StatusLabel.Parent then StatusLabel.Text = "STATUS: " .. string.upper(text) end
    print("Status: " .. text) -- Untuk debug di output executor
end

local function appendLog(text)
    if LogOutput and LogOutput.Parent then
        local currentText = LogOutput.Text
        local newText = text .. "\n" .. currentText
        -- Batasi panjang log agar tidak terlalu panjang
        if #newText > 500 then
            newText = newText:sub(1, 500) .. "..."
        end
        LogOutput.Text = newText
    end
    print("Log: " .. text) -- Untuk debug di output executor
end

local function clearLog()
    if LogOutput and LogOutput.Parent then
        LogOutput.Text = "Log: Cleared."
    end
    appendLog("Log cleared.")
end

-- // Fungsi Animasi UI //
local function animateFrame(targetSize, targetPosition, callback)
    local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local properties = {Size = targetSize, Position = targetPosition}
    local tween = TweenService:Create(Frame, info, properties)
    tween:Play()
    if callback then
        tween.Completed:Wait()
        callback()
    end
end

-- // Fungsi Minimize/Maximize UI //
local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        -- Simpan posisi original Frame sebelum diubah
        local originalFramePosition = Frame.Position

        -- Sembunyikan semua elemen kecuali Frame dan 'Z' label
        for _, element in ipairs(elementsToToggleVisibility) do
            if element and element.Parent then element.Visible = false end
        end
        minimizedZLabel.Visible = true -- Tampilkan 'Z'

        -- Hitung posisi target pop-up di pojok kanan bawah
        local targetX = 1 - (minimizedFrameSize.X.Offset / ScreenGui.AbsoluteSize.X) - 0.02 -- Sedikit dari kanan
        local targetY = 1 - (minimizedFrameSize.Y.Offset / ScreenGui.AbsoluteSize.Y) - 0.02 -- Sedikit dari bawah
        local targetPosition = UDim2.new(targetX, 0, targetY, 0)

        animateFrame(minimizedFrameSize, targetPosition)
        Frame.Draggable = false -- Matikan draggable saat diminimize untuk mencegah pergeseran
    else
        -- Tampilkan tombol minimize sebelum animasi maximize dimulai
        for _, element in ipairs(elementsToToggleVisibility) do
            if element == MinimizeButton and element.Parent then element.Visible = true end
        end

        minimizedZLabel.Visible = false -- Sembunyikan 'Z'
        MinimizeButton.Text = "_" -- Kembali ke simbol minimize

        -- Posisikan kembali ke tengah layar (gunakan originalFrameSize untuk posisi yang benar)
        local targetPosition = UDim2.new(0.5, -originalFrameSize.X.Offset/2, 0.5, -originalFrameSize.Y.Offset/2)
        animateFrame(originalFrameSize, targetPosition, function()
            -- Tampilkan semua elemen setelah animasi ukuran selesai
            for _, element in ipairs(elementsToToggleVisibility) do
                if element and element.Parent then element.Visible = true end
            end
            Frame.Draggable = true -- Aktifkan kembali draggable setelah maximize
        end)
    end
end

MinimizeButton.MouseButton1Click:Connect(toggleMinimize)

-- // Fungsi tunggu //
local function waitSeconds(sec)
    if sec <= 0 then task.wait() return end
    local startTime = tick()
    repeat
        task.wait()
    until not scriptRunning or tick() - startTime >= sec
end

-- Fungsi Teleportasi dengan penanganan error dan offset Y
local function teleportPlayer(cframeTarget, locationName)
    local success, err = pcall(function()
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Disable collisions briefly to prevent clipping
                LocalPlayer.Character.Archivable = true
                local originalCanCollide = {}
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        originalCanCollide[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end

                -- Adjust CFrame with Y offset
                LocalPlayer.Character.HumanoidRootPart.CFrame = cframeTarget + Vector3.new(0, timers.teleport_y_offset, 0)

                -- Re-enable collisions
                for part, canCollide in pairs(originalCanCollide) do
                    if part and part.Parent then -- Check if part still exists
                        part.CanCollide = canCollide
                    end
                end
                LocalPlayer.Character.Archivable = false
            end
            appendLog("Teleported to: " .. locationName)
            updateStatus("Teleported to: " .. locationName)
        else
            error("Player character or HumanoidRootPart not found.")
        end
    end)
    if not success then
        appendLog("Teleport Error to " .. locationName .. ": " .. tostring(err))
        updateStatus("TELEPORT_FAILED")
        return false
    end
    return true
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

    while autoTeleportActive do
        local locationName = locations[currentPointIndex]
        local cframeTarget = teleportLocations[locationName]

        if cframeTarget then
            updateStatus("Auto-teleporting to: " .. locationName)
            appendLog("Starting auto-teleport to: " .. locationName)

            if not teleportPlayer(cframeTarget, locationName) then
                appendLog("Auto-teleport failed for " .. locationName .. ". Retrying in 5 seconds...")
                task.wait(5) -- Tunggu sebentar sebelum mencoba lagi atau melanjutkan
                -- Anda bisa menambahkan logika retry di sini jika diperlukan
            end

            appendLog("Waiting for " .. timers.teleport_wait_time .. " seconds at " .. locationName)
            local remainingTime = timers.teleport_wait_time
            while remainingTime > 0 and autoTeleportActive do
                updateStatus(string.format("Auto-teleport: %s (%d s left)", locationName, math.floor(remainingTime)))
                task.wait(1)
                remainingTime = remainingTime - 1
            end
            if not autoTeleportActive then break end -- Berhenti jika auto-teleport dinonaktifkan

            currentPointIndex = currentPointIndex + 1
            if currentPointIndex > #locations then
                currentPointIndex = 1 -- Kembali ke awal jika sudah mencapai akhir
                appendLog("Auto-teleport cycle complete. Restarting cycle.")
            end

            if autoTeleportActive then
                appendLog("Delaying " .. timers.teleport_delay_between_points .. " seconds before next teleport.")
                waitSeconds(timers.teleport_delay_between_points)
            end
        else
            appendLog("Error: CFrame not found for location: " .. locationName)
            updateStatus("ERROR: LOCATION_NOT_FOUND")
            task.wait(5) -- Tunggu sebentar jika ada error konfigurasi
        end
    end
    updateStatus("AUTO_TELEPORT_STOPPED")
    appendLog("Auto-teleport sequence halted.")
end

-- // Tombol Start/Stop Auto Teleport //
StartAutoTeleportButton.MouseButton1Click:Connect(function()
    scriptRunning = true -- Pastikan scriptRunning aktif saat UI digunakan
    autoTeleportActive = not autoTeleportActive
    if autoTeleportActive then
        StartAutoTeleportButton.Text = "STOP AUTO TELEPORT"
        StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        StartAutoTeleportButton.TextColor3 = Color3.fromRGB(255,255,255)
        updateStatus("AUTO_TELEPORT_ACTIVE")
        appendLog("Auto teleport sequence started.")
        if not autoTeleportThread or coroutine.status(autoTeleportThread) == "dead" then
            autoTeleportThread = task.spawn(autoTeleportCycle)
        end
    else
        StartAutoTeleportButton.Text = "START AUTO TELEPORT"
        StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        StartAutoTeleportButton.TextColor3 = Color3.fromRGB(220,220,220)
        updateStatus("HALT_REQUESTED")
        appendLog("Auto teleport sequence halt requested.")
    end
end)

-- // Tombol Apply Timers //
ApplyTimersButton.MouseButton1Click:Connect(function()
    local function applyTextInput(inputElement, timerKey, labelElement)
        local success = false; if not inputElement then return false end
        local value = tonumber(inputElement.Text)
        if value and value >= 0 then timers[timerKey] = value
            if labelElement then pcall(function() labelElement.TextColor3 = Color3.fromRGB(80,255,80) end) end; success = true
        else if labelElement then pcall(function() labelElement.TextColor3 = Color3.fromRGB(255,80,80) end) end
        end
        return success
    end
    local allTimersValid = true
    allTimersValid = applyTextInput(timerInputElements.teleportWaitTimeInput, "teleport_wait_time", timerInputElements.TeleportWaitTimeLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.teleportDelayBetweenPointsInput, "teleport_delay_between_points", timerInputElements.TeleportDelayBetweenPointsLabel) and allTimersValid

    local originalStatus = StatusLabel.Text:gsub("STATUS: ", "")
    if allTimersValid then updateStatus("SETTINGS_APPLIED") else updateStatus("ERR_INVALID_INPUT") end
    appendLog("Attempted to apply settings. Valid: " .. tostring(allTimersValid))
    task.wait(2)
    if timerInputElements.TeleportWaitTimeLabel then pcall(function() timerInputElements.TeleportWaitTimeLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.TeleportDelayBetweenPointsLabel then pcall(function() timerInputElements.TeleportDelayBetweenPointsLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    updateStatus(originalStatus)
end)

-- // Manual Teleport Logic (Dropdown) //
local function populateDropdownOptions()
    -- Clear existing options
    for _, child in ipairs(TeleportDropdownOptionsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Define the order of locations for the dropdown
    local orderedLocations = {
        "Camp 1 Main Tent", "Camp 1 Checkpoint",
        "Camp 2 Main Tent", "Camp 2 Checkpoint",
        "Camp 3 Main Tent", "Camp 3 Checkpoint",
        "Camp 4 Main Tent", "Camp 4 Checkpoint",
        "South Pole Checkpoint"
    }

    local optionHeight = 25
    for i, locationName in ipairs(orderedLocations) do -- Iterate through orderedLocations
        -- Ensure the location actually exists in teleportLocations before creating an option
        if teleportLocations[locationName] then
            local optionButton = Instance.new("TextButton")
            optionButton.Name = "Option_" .. i
            optionButton.Parent = TeleportDropdownOptionsFrame
            optionButton.Size = UDim2.new(1, 0, 0, optionHeight)
            optionButton.Text = locationName
            optionButton.Font = Enum.Font.SourceSans
            optionButton.TextSize = 12
            optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
            optionButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            optionButton.BorderSizePixel = 0
            optionButton.TextXAlignment = Enum.TextXAlignment.Left
            optionButton.TextWrapped = true

            -- Hover effect
            optionButton.MouseEnter:Connect(function()
                optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            end)
            optionButton.MouseLeave:Connect(function()
                optionButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            end)

            optionButton.MouseButton1Click:Connect(function()
                TeleportLocationSelector.Text = locationName
                TeleportDropdownOptionsFrame.Visible = false
                -- Reset button position after selection
                TeleportButton.Position = UDim2.new(0, 10, 0, 80)
            end)
        end
    end
    -- Adjust the height of the dropdown options frame based on content
    TeleportDropdownOptionsFrame.CanvasSize = UDim2.new(0, 0, 0, #orderedLocations * (optionHeight + UIListLayout.Padding.Offset))
    TeleportDropdownOptionsFrame.Size = UDim2.new(1, 0, 0, math.min(150, TeleportDropdownOptionsFrame.CanvasSize.Y.Offset)) -- Adjusted width to fill parent
end

TeleportLocationSelector.MouseButton1Click:Connect(function()
    if TeleportDropdownOptionsFrame.Visible then
        TeleportDropdownOptionsFrame.Visible = false
        -- Reset button position when closing dropdown
        TeleportButton.Position = UDim2.new(0, 10, 0, 80)
    else
        populateDropdownOptions()
        -- Calculate position relative to the selector's absolute position
        local selectorAbsolutePos = TeleportLocationSelector.AbsolutePosition
        local frameAbsolutePos = Frame.AbsolutePosition
        local relativeX = selectorAbsolutePos.X - frameAbsolutePos.X
        local relativeY = selectorAbsolutePos.Y - frameAbsolutePos.Y + TeleportLocationSelector.Size.Y.Offset + 5 -- 5 for padding
        TeleportDropdownOptionsFrame.Position = UDim2.new(0, relativeX, 0, relativeY)
        TeleportDropdownOptionsFrame.Visible = true
        -- Move the Teleport button down to make space for the dropdown
        TeleportButton.Position = UDim2.new(0, 10, 0, 80 + TeleportDropdownOptionsFrame.Size.Y.Offset + 5)
    end
end)

-- Hide dropdown if user clicks outside
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not gameProcessed then
        local mousePos = UserInputService:GetMouseLocation()
        local dropdownBounds = TeleportDropdownOptionsFrame.AbsolutePosition + TeleportDropdownOptionsFrame.AbsoluteSize
        local selectorBounds = TeleportLocationSelector.AbsolutePosition + TeleportLocationSelector.AbsoluteSize

        local isClickInsideDropdown = mousePos.X >= TeleportDropdownOptionsFrame.AbsolutePosition.X and
                                     mousePos.X <= dropdownBounds.X and
                                     mousePos.Y >= TeleportDropdownOptionsFrame.AbsolutePosition.Y and
                                     mousePos.Y <= dropdownBounds.Y

        local isClickInsideSelector = mousePos.X >= TeleportLocationSelector.AbsolutePosition.X and
                                     mousePos.X <= selectorBounds.X and
                                     mousePos.Y >= TeleportLocationSelector.AbsolutePosition.Y and
                                     mousePos.Y <= selectorBounds.Y

        if TeleportDropdownOptionsFrame.Visible and not isClickInsideDropdown and not isClickInsideSelector then
            TeleportDropdownOptionsFrame.Visible = false
            TeleportButton.Position = UDim2.new(0, 10, 0, 80) -- Reset button position
        end
    end
end)


TeleportButton.MouseButton1Click:Connect(function()
    scriptRunning = true -- Pastikan scriptRunning aktif saat UI digunakan
    local selectedLocation = TeleportLocationSelector.Text
    local cframe = teleportLocations[selectedLocation]
    if cframe then
        teleportPlayer(cframe, selectedLocation)
    else
        appendLog("Manual Teleport Error: Location '" .. selectedLocation .. "' not found or not selected.")
        updateStatus("MANUAL_TP_ERROR")
    end
end)

-- // Log Clearing Loop //
task.spawn(function()
    while true do
        task.wait(timers.log_clear_interval)
        clearLog()
    end
end)

-- --- ANIMASI UI ---
-- Menggunakan task.spawn() untuk memastikan animasi berjalan di thread terpisah.

task.spawn(function() -- Animasi Latar Belakang Frame (Glitchy Border)
    if not Frame or not Frame.Parent then return end
    local baseColor = Color3.fromRGB(15, 15, 20)
    local glitchColor1 = Color3.fromRGB(25, 20, 30)
    local glitchColor2 = Color3.fromRGB(10, 10, 15)
    local borderBase = Color3.fromRGB(255,0,0)
    local borderGlitch = Color3.fromRGB(0,255,255)
    local borderThicknessBase = 2
    -- Characters for border glitch (will be simulated visually, not actual text on border)
    local glitchCharsBorder = {"Z", "X", "H", "E", "L", "L", "1", "0", "!", "@", "#", "$"} 

    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Hanya beranimasi saat tidak diminimize
            local r = math.random()
            if r < 0.15 then -- Glitch intens (lebih sering)
                Frame.BackgroundColor3 = glitchColor1
                Frame.BorderColor3 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255)) -- Warna acak
                Frame.BorderSizePixel = math.random(3, 7) -- Ketebalan acak
                -- Simulate glitching effect on the frame itself
                Frame.BackgroundTransparency = math.random() * 0.4 -- Make background slightly transparent
                Frame.Position = Frame.Position + UDim2.fromOffset(math.random(-1,1), math.random(-1,1)) -- Slight random movement
                task.wait(0.05)
                Frame.BackgroundColor3 = glitchColor2
                Frame.BorderColor3 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
                Frame.BorderSizePixel = math.random(1, 5)
                Frame.BackgroundTransparency = 0 -- Reset transparency
                Frame.Position = UDim2.new(0.5, -Frame.Size.X.Offset/2, 0.5, -Frame.Size.Y.Offset/2) -- Reset position
                task.wait(0.05)
            elseif r < 0.4 then -- Glitch ringan (lebih sering)
                Frame.BackgroundColor3 = Color3.Lerp(baseColor, glitchColor1, math.random())
                Frame.BorderColor3 = Color3.Lerp(borderBase, borderGlitch, math.random()*0.8)
                Frame.BorderSizePixel = math.random(2, 4)
                Frame.BackgroundTransparency = 0
                task.wait(0.1)
            else
                Frame.BackgroundColor3 = baseColor
                Frame.BorderColor3 = borderBase
                Frame.BorderSizePixel = borderThicknessBase
                Frame.BackgroundTransparency = 0
            end
            -- Animasi border utama (HSV shift) yang lebih halus saat tidak glitch intens
            local h,s,v = Color3.toHSV(Frame.BorderColor3)
            Frame.BorderColor3 = Color3.fromHSV((h + 0.005)%1, s, v)
        else -- Jika diminimize, pastikan warna kembali normal untuk 'Z'
            Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
            Frame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Atau warna solid apa pun yang Anda inginkan untuk pop-up
            Frame.BorderSizePixel = borderThicknessBase
            Frame.BackgroundTransparency = 0
            Frame.Position = UDim2.new(0.5, -Frame.Size.X.Offset/2, 0.5, -Frame.Size.Y.Offset/2) -- Ensure position is reset
        end
        task.wait(0.05)
    end
end)

task.spawn(function() -- Animasi UiTitleLabel (Glitch Text Transition dan RGB Normal)
    if not UiTitleLabel or not UiTitleLabel.Parent then return end
    local originalText1 = "ANTARCTIC TELEPORT"
    local originalText2 = "ZEDLIST X ZXHELL"
    local currentTargetText = originalText1
    local glitchChars = {"@", "#", "$", "%", "&", "*", "!", "?", "/", "\\", "|", "_", "1", "0"}
    local baseColor = Color3.fromRGB(255, 25, 25)
    local originalPos = UiTitleLabel.Position
    local transitionTime = 1.5 -- Waktu transisi glitch
    local displayTime = 5 -- Waktu menampilkan teks normal

    local function applyGlitch(text)
        local newText = ""
        for i = 1, #text do
            if math.random() < 0.7 then -- Probabilitas glitch karakter
                newText = newText .. glitchChars[math.random(#glitchChars)]
            else
                newText = newText .. text:sub(i,i)
            end
        end
        return newText
    end

    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then
            -- Glitch transition
            local startTime = tick()
            while tick() - startTime < transitionTime do
                local progress = (tick() - startTime) / transitionTime
                local mixedText = ""
                local textToGlitch = (currentTargetText == originalText1) and originalText2 or originalText1

                for i = 1, math.max(#currentTargetText, #textToGlitch) do
                    local char1 = currentTargetText:sub(i,i)
                    local char2 = textToGlitch:sub(i,i)

                    if math.random() < progress then -- Semakin lama, semakin banyak karakter target
                        mixedText = mixedText .. (char2 ~= "" and char2 or glitchChars[math.random(#glitchChars)])
                    else
                        mixedText = mixedText .. (char1 ~= "" and char1 or glitchChars[math.random(#glitchChars)])
                    end
                end
                UiTitleLabel.Text = applyGlitch(mixedText)
                UiTitleLabel.TextColor3 = Color3.fromHSV(math.random(), 1, 1)
                UiTitleLabel.Position = originalPos + UDim2.fromOffset(math.random(-2,2), math.random(-2,2))
                UiTitleLabel.Rotation = math.random(-1,1) * 0.5
                task.wait(0.05)
            end

            -- Display target text normally with RGB animation
            UiTitleLabel.Text = currentTargetText
            local hue = (tick()*0.1) % 1 -- RGB animation for normal text
            local r_rgb, g_rgb, b_rgb = Color3.fromHSV(hue, 1, 1).R, Color3.fromHSV(hue, 1, 1).G, Color3.fromHSV(hue, 1, 1).B
            r_rgb = math.min(1, r_rgb + 0.6) -- Dominasi merah
            g_rgb = g_rgb * 0.4
            b_rgb = b_rgb * 0.4
            UiTitleLabel.TextColor3 = Color3.new(r_rgb, g_rgb, b_rgb)
            UiTitleLabel.TextStrokeTransparency = 0.5
            UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)
            UiTitleLabel.Position = originalPos
            UiTitleLabel.Rotation = 0

            -- Wait for display time
            task.wait(displayTime)

            -- Switch target text for next cycle
            if currentTargetText == originalText1 then
                currentTargetText = originalText2
            else
                currentTargetText = originalText1
            end
        else
            -- If minimized, ensure it shows originalText1 without glitch, no RGB animation
            UiTitleLabel.Text = originalText1
            UiTitleLabel.TextColor3 = baseColor
            UiTitleLabel.TextStrokeTransparency = 0.5
            UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)
            UiTitleLabel.Position = originalPos
            UiTitleLabel.Rotation = 0
            task.wait(0.05)
        end
    end
end)


task.spawn(function() -- Animasi Tombol (Subtle Pulse)
    local buttonsToAnimate = {StartAutoTeleportButton, ApplyTimersButton, MinimizeButton, TeleportButton, TeleportLocationSelector}
    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Hanya beranimasi saat tidak diminimize
            for _, btn in ipairs(buttonsToAnimate) do
                if btn and btn.Parent then
                    local originalBorder = btn.BorderColor3

                    -- Efek hover/pulse sederhana pada border
                    if btn.Name == "StartAutoTeleportButton" and autoTeleportActive then
                        btn.BorderColor3 = Color3.fromRGB(255,100,100) -- Merah lebih terang saat running
                    else
                        local h,s,v = Color3.toHSV(originalBorder)
                        btn.BorderColor3 = Color3.fromHSV(h,s, math.sin(tick()*2)*0.1 + 0.9) -- Pulse V
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function() -- Animasi Pop-up 'Z' (RGB Pulse)
    while ScreenGui and ScreenGui.Parent do
        if isMinimized and minimizedZLabel.Visible then
            local hue = (tick() * 0.2) % 1 -- Animasi warna RGB
            minimizedZLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
        end
        task.wait(0.05)
    end
end)
-- --- END ANIMASI UI ---

-- BindToClose
game:BindToClose(function()
    if scriptRunning then warn("Game ditutup, menghentikan skrip..."); scriptRunning = false; autoTeleportActive = false; task.wait(0.5) end
    if ScreenGui and ScreenGui.Parent then pcall(function() ScreenGui:Destroy() end) end
    print("Pembersihan skrip selesai.")
end)

-- Inisialisasi
print("Skrip Teleportasi Ekspedisi Antartika Telah Dimuat.")
task.wait(1)
if StatusLabel and StatusLabel.Parent and StatusLabel.Text == "" then StatusLabel.Text = "STATUS: STANDBY" end

