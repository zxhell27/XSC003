-- MainScript.lua
-- Gabungan UI dan Logika dengan UI pop-up 'Z' merah RGB
-- Diadaptasi untuk skrip ekspedisi client-side

-- // UI FRAME (Struktur Asli Dipertahankan) //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CyberpunkUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- Penting untuk memastikan UI selalu di atas

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"

local UiTitleLabel = Instance.new("TextLabel")
UiTitleLabel.Name = "UiTitleLabel"

local StartButton = Instance.new("TextButton")
StartButton.Name = "StartButton"

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"

local TimerTitleLabel = Instance.new("TextLabel")
TimerTitleLabel.Name = "TimerTitle"

local ApplyTimersButton = Instance.new("TextButton")
ApplyTimersButton.Name = "ApplyTimersButton"

-- Tabel untuk menyimpan referensi elemen input timer
local timerInputElements = {}

-- --- Variabel Kontrol dan State ---
local scriptRunning = false
local stopUpdateQi = false -- Tidak digunakan dalam skrip ekspedisi ini, tapi dipertahankan dari mainv2
local pauseUpdateQiTemporarily = false -- Tidak digunakan dalam skrip ekspedisi ini, tapi dipertahankan dari mainv2
local mainCycleThread = nil
local aptitudeMineThread = nil -- Tidak digunakan dalam skrip ekspedisi ini, tapi dipertahankan dari mainv2
local updateQiThread = nil -- Tidak digunakan dalam skrip ekspedisi ini, tapi dipertahankan dari mainv2
local waterDrinkThread = nil -- Thread baru untuk minum air

local isMinimized = false
local originalFrameSize = UDim2.new(0, 260, 0, 420) -- Ukuran awal UI lebih kecil
local minimizedFrameSize = UDim2.new(0, 50, 0, 50) -- Ukuran pop-up 'Z'
local minimizedZLabel = Instance.new("TextLabel") -- Label khusus untuk pop-up 'Z'

-- Kumpulan elemen yang visibilitasnya akan di-toggle
local elementsToToggleVisibility = {} -- Akan diisi setelah semua elemen UI dibuat

-- --- Tabel Konfigurasi Timer ---
local timers = {
    -- Timers dari mainv2 (dipertahankan, tapi tidak digunakan dalam logika ekspedisi ini)
    wait_1m30s_after_first_items = 90,
    alur_wait_40s_hide_qi = 40,
    comprehend_duration = 20,
    post_comprehend_qi_duration = 60,
    user_script_wait1_before_items1 = 15,
    user_script_wait2_after_items1 = 10,
    user_script_wait3_before_items2 = 0.01,
    user_script_wait4_before_forbidden = 0.01,
    update_qi_interval = 1,
    aptitude_mine_interval = 0.1,
    genericShortDelay = 0.5,
    reincarnateDelay = 0.5,
    buyItemDelay = 0.25,
    changeMapDelay = 0.5,
    fireserver_generic_delay = 0.25,

    -- Timers baru untuk ekspedisi
    initialWaitBeforeTeleport = 5, -- Tunggu 5 detik sebelum teleport pertama
    teleportWait = 5,             -- Tunggu 5 detik setelah setiap teleport
    longWaitBeforeCheckpoint = 300, -- Tunggu 5 menit (300 detik) sebelum setiap checkpoint
    waterDrinkInterval = 420,     -- Minum air setiap 7 menit (420 detik)
    cycleRestartDelay = 2,        -- Penundaan kecil sebelum mengulang siklus ekspedisi
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
    StartButton.Parent = Frame
    StatusLabel.Parent = Frame
    MinimizeButton.Parent = Frame
    TimerTitleLabel.Parent = Frame
    ApplyTimersButton.Parent = Frame
    minimizedZLabel.Parent = Frame -- Parentkan label Z ke Frame
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
Frame.ClipsDescendants = true -- Penting untuk animasi masuk/keluar elemen

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10) -- Sudut lebih membulat
UICorner.Parent = Frame

-- --- Nama UI Label ("ZXHELL X ZEDLIST") ---
UiTitleLabel.Size = UDim2.new(1, -20, 0, 35) -- Lebih kecil sedikit
UiTitleLabel.Position = UDim2.new(0, 10, 0, 10)
UiTitleLabel.Font = Enum.Font.SourceSansSemibold
UiTitleLabel.Text = "ROBLOX EXPEDITION" -- Diubah untuk ekspedisi
UiTitleLabel.TextColor3 = Color3.fromRGB(255, 25, 25)
UiTitleLabel.TextScaled = false
UiTitleLabel.TextSize = 24 -- Ukuran font sedang
UiTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
UiTitleLabel.BackgroundTransparency = 1
UiTitleLabel.ZIndex = 2
UiTitleLabel.TextStrokeTransparency = 0.5
UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)

-- Posisi elemen lain disesuaikan dengan layout baru
local yOffsetForTitle = 50 -- Jarak dari atas frame ke elemen berikutnya (disesuaikan)

-- --- Tombol Start/Stop ---
StartButton.Size = UDim2.new(1, -40, 0, 35) -- Lebih kecil
StartButton.Position = UDim2.new(0, 20, 0, yOffsetForTitle)
StartButton.Text = "START EXPEDITION" -- Diubah
StartButton.Font = Enum.Font.SourceSansBold
StartButton.TextSize = 16 -- Ukuran font sedang
StartButton.TextColor3 = Color3.fromRGB(220, 220, 220)
StartButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20) -- Merah gelap
StartButton.BorderSizePixel = 1
StartButton.BorderColor3 = Color3.fromRGB(255, 50, 50)
StartButton.ZIndex = 2

local StartButtonCorner = Instance.new("UICorner")
StartButtonCorner.CornerRadius = UDim.new(0, 5)
StartButtonCorner.Parent = StartButton

-- --- Status Label ---
StatusLabel.Size = UDim2.new(1, -40, 0, 45) -- Lebih kecil
StatusLabel.Position = UDim2.new(0, 20, 0, yOffsetForTitle + 45)
StatusLabel.Text = "STATUS: STANDBY"
StatusLabel.Font = Enum.Font.SourceSansLight
StatusLabel.TextSize = 14 -- Ukuran font sedang
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 220) -- Putih kebiruan
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30) -- Gelap
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BorderSizePixel = 0
StatusLabel.ZIndex = 2

local StatusLabelCorner = Instance.new("UICorner")
StatusLabelCorner.CornerRadius = UDim.new(0, 5)
StatusLabelCorner.Parent = StatusLabel

local yOffsetForTimers = yOffsetForTitle + 100 -- Disesuaikan

-- --- Konfigurasi Timer UI ---
TimerTitleLabel.Size = UDim2.new(1, -40, 0, 20) -- Lebih kecil
TimerTitleLabel.Position = UDim2.new(0, 20, 0, yOffsetForTimers)
TimerTitleLabel.Text = "// EXPEDITION TIMER CONFIGURATION" -- Diubah
TimerTitleLabel.Font = Enum.Font.Code
TimerTitleLabel.TextSize = 14 -- Ukuran font sedang
TimerTitleLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- Merah terang
TimerTitleLabel.BackgroundTransparency = 1
TimerTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TimerTitleLabel.ZIndex = 2

local function createTimerInput(name, yPos, labelText, initialValue)
    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Parent = Frame
    label.Size = UDim2.new(0.55, -25, 0, 20) -- Lebih kecil
    label.Position = UDim2.new(0, 20, 0, yPos + yOffsetForTimers)
    label.Text = labelText .. ":"
    label.Font = Enum.Font.SourceSans
    label.TextSize = 12 -- Ukuran font sedang
    label.TextColor3 = Color3.fromRGB(180, 180, 200)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    timerInputElements[name .. "Label"] = label

    local input = Instance.new("TextBox")
    input.Name = name .. "Input"
    input.Parent = Frame
    input.Size = UDim2.new(0.45, -25, 0, 20) -- Lebih kecil
    input.Position = UDim2.new(0.55, 5, 0, yPos + yOffsetForTimers)
    input.Text = tostring(initialValue)
    input.PlaceholderText = "sec"
    input.Font = Enum.Font.SourceSansSemibold
    input.TextSize = 12 -- Ukuran font sedang
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

local currentYConfig = 30 -- Jarak dari TimerTitleLabel (disesuaikan)
-- Inisialisasi nilai input timer dari tabel timers (hanya yang relevan untuk ekspedisi)
timerInputElements.initialWaitInput = createTimerInput("InitialWait", currentYConfig, "INITIAL_WAIT", timers.initialWaitBeforeTeleport)
currentYConfig = currentYConfig + 25
timerInputElements.teleportWaitInput = createTimerInput("TeleportWait", currentYConfig, "TELEPORT_DELAY", timers.teleportWait)
currentYConfig = currentYConfig + 25
timerInputElements.longWaitInput = createTimerInput("LongWait", currentYConfig, "CHECKPOINT_WAIT", timers.longWaitBeforeCheckpoint)
currentYConfig = currentYConfig + 25
timerInputElements.waterDrinkInput = createTimerInput("WaterDrink", currentYConfig, "WATER_DRINK_INTERVAL", timers.waterDrinkInterval)
currentYConfig = currentYConfig + 35 -- Disesuaikan

ApplyTimersButton.Size = UDim2.new(1, -40, 0, 30) -- Lebih kecil
ApplyTimersButton.Position = UDim2.new(0, 20, 0, currentYConfig + yOffsetForTimers)
ApplyTimersButton.Text = "APPLY_TIMERS"
ApplyTimersButton.Font = Enum.Font.SourceSansBold
ApplyTimersButton.TextSize = 14 -- Ukuran font sedang
ApplyTimersButton.TextColor3 = Color3.fromRGB(220, 220, 220)
ApplyTimersButton.BackgroundColor3 = Color3.fromRGB(30, 80, 30) -- Hijau gelap
ApplyTimersButton.BorderColor3 = Color3.fromRGB(80, 255, 80)
ApplyTimersButton.BorderSizePixel = 1
ApplyTimersButton.ZIndex = 2

local ApplyButtonCorner = Instance.new("UICorner")
ApplyButtonCorner.CornerRadius = UDim.new(0, 5)
ApplyButtonCorner.Parent = ApplyTimersButton

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
    UiTitleLabel, StartButton, StatusLabel, TimerTitleLabel, ApplyTimersButton,
    timerInputElements.initialWaitLabel, timerInputElements.initialWaitInput,
    timerInputElements.teleportWaitLabel, timerInputElements.teleportWaitInput,
    timerInputElements.longWaitLabel, timerInputElements.longWaitInput,
    timerInputElements.waterDrinkLabel, timerInputElements.waterDrinkInput,
    MinimizeButton -- Sertakan MinimizeButton di sini untuk menyembunyikannya saat mode 'Z'
}

-- // Fungsi Bantu UI //
local function updateStatus(text)
    if StatusLabel and StatusLabel.Parent then StatusLabel.Text = "STATUS: " .. string.upper(text) end
end

-- // Fungsi Animasi UI //
local TweenService = game:GetService("TweenService")
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

-- Fungsi fireRemoteEnhanced (dipertahankan dari mainv2, meskipun tidak digunakan untuk ekspedisi)
local function fireRemoteEnhanced(remoteName, pathType, ...)
    local argsToUnpack = table.pack(...)
    local remoteEventFolder
    local success = false
    local errMessage = "Unknown error"
    local pcallSuccess, pcallResult = pcall(function()
        if pathType == "AreaEvents" then
            remoteEventFolder = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents", 9e9):WaitForChild("AreaEvents", 9e9)
        else
            remoteEventFolder = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents", 9e9)
        end
        local remote = remoteEventFolder:WaitForChild(remoteName, 9e9)
        remote:FireServer(table.unpack(argsToUnpack, 1, argsToUnpack.n))
    end)
    if pcallSuccess then success = true
    else
        errMessage = tostring(pcallResult)
        if StatusLabel and StatusLabel.Parent then StatusLabel.Text = "STATUS: ERR_FIRE_" .. string.upper(remoteName) end
        warn("Error firing " .. remoteName .. ": " .. errMessage)
        success = false
    end
    return success
end

-- // Fungsi bantu untuk ekspedisi //
local function teleportTo(targetPart)
    if not scriptRunning then return false end
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)

    if not humanoidRootPart then
        warn("HumanoidRootPart tidak ditemukan untuk teleportasi.")
        updateStatus("ERR: NO_HRP_FOR_TP")
        return false
    end

    if targetPart and targetPart:IsA("BasePart") then
        updateStatus("TELEPORTING TO: " .. targetPart.Name)
        pcall(function()
            humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0) -- Tambah sedikit offset Y agar tidak terjebak
        end)
        waitSeconds(timers.teleportWait)
        return true
    else
        warn("Target teleportasi tidak valid atau tidak ditemukan: " .. tostring(targetPart))
        updateStatus("ERR: INVALID_TP_TARGET")
        return false
    end
end

local function drinkWater()
    if not scriptRunning then return false end
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if not character then return false end -- Karakter mungkin belum dimuat atau hilang

    updateStatus("DRINKING WATER...")
    local waterBottle = character:FindFirstChild("Water Bottle")
    if waterBottle then
        local remoteEvent = waterBottle:FindFirstChild("RemoteEvent")
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            local success, err = pcall(function()
                remoteEvent:FireServer()
            end)
            if not success then
                warn("Gagal memanggil RemoteEvent Water Bottle: " .. err)
                updateStatus("ERR: WATER_FIRE_FAIL")
            end
            return success
        else
            warn("RemoteEvent tidak ditemukan di Water Bottle.")
            updateStatus("ERR: NO_WATER_RE")
            return false
        end
    else
        warn("Water Bottle tidak ditemukan di karakter.")
        updateStatus("ERR: NO_WATER_BOTTLE")
        return false
    end
end

-- // Fungsi utama ekspedisi //
local function runExpeditionCycle()
    updateStatus("STARTING EXPEDITION...")

    -- Langkah 1: Teleport ke Basecamp (hanya sekali di awal eksekusi skrip penuh)
    -- Ini akan dieksekusi di luar loop utama runExpeditionCycle, saat mainCycleThread pertama kali berjalan.
    -- Jadi, kita akan memulai loop dari "nomor 2" di dalam while true do.

    -- --- Siklus Ekspesisi Berulang (Dimulai dari "nomor 2" dari Alur Script) ---
    while scriptRunning do
        -- Tunggu 5 detik kemudian teleport ke ini:
        -- workspace["Search_And_Rescue%"].Helicopter_Spawn_Clickers.Basecamp
        -- Ini adalah teleport awal, jadi kita akan melakukannya di luar loop utama ekspedisi
        -- dan hanya sekali saat skrip dimulai.

        -- Langkah 2: Tunggu 5 detik kemudian teleport ke Camp1
        if not scriptRunning then break end
        updateStatus("WAIT 5S, TP TO CAMP1...")
        waitSeconds(timers.teleportWait)
        local camp1Part = workspace:FindFirstChild("Camp_Main_Tents%") and workspace["Camp_Main_Tents%"]:FindFirstChild("Camp1")
        if not teleportTo(camp1Part) then break end

        -- Langkah 3: Tunggu 5 menit kemudian teleport ke cek poin ini: workspace:GetChildren()[264]
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT_264...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpoint264 = workspace:FindFirstChild("Checkpoint_264") -- ASUMSI NAMA PART
        if not teleportTo(checkpoint264) then break end

        -- Langkah 4: Jika sudah cek poin maka tunggu 5 detik kemudian teleport kesini: Camp2
        if not scriptRunning then break end
        updateStatus("CHECKPOINT_264 REACHED, TP TO CAMP2...")
        waitSeconds(timers.teleportWait)
        local camp2Part = workspace:FindFirstChild("Camp_Main_Tents%") and workspace["Camp_Main_Tents%"]:FindFirstChild("Camp2")
        if not teleportTo(camp2Part) then break end

        -- Langkah 5: Tunggu 5 menit kemudian teleport ke cek poin ini: workspace:GetChildren()[731]
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT_731...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpoint731 = workspace:FindFirstChild("Checkpoint_731") -- ASUMSI NAMA PART
        if not teleportTo(checkpoint731) then break end

        -- Langkah 6: Jika sudah cek poin maka tunggu 5 detik kemudian teleport kesini: Camp3
        if not scriptRunning then break end
        updateStatus("CHECKPOINT_731 REACHED, TP TO CAMP3...")
        waitSeconds(timers.teleportWait)
        local camp3Part = workspace:FindFirstChild("Camp_Main_Tents%") and workspace["Camp_Main_Tents%"]:FindFirstChild("Camp3")
        if not teleportTo(camp3Part) then break end

        -- Langkah 7: Tunggu 5 menit kemudian teleport ke cek poin ini: workspace:GetChildren()[550]
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT_550...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpoint550 = workspace:FindFirstChild("Checkpoint_550") -- ASUMSI NAMA PART
        if not teleportTo(checkpoint550) then break end

        -- Langkah 8: Jika sudah cek poin maka tunggu 5 detik kemudian teleport kesini: Camp4
        if not scriptRunning then break end
        updateStatus("CHECKPOINT_550 REACHED, TP TO CAMP4...")
        waitSeconds(timers.teleportWait)
        local camp4Part = workspace:FindFirstChild("Camp_Main_Tents%") and workspace["Camp_Main_Tents%"]:FindFirstChild("Camp4")
        if not teleportTo(camp4Part) then break end

        -- Langkah 9: Tunggu 5 menit kemudian teleport ke cek poin ini: workspace.Checkpoint *camp 4*
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT_CAMP4...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpointCamp4 = workspace:FindFirstChild("CheckpointCamp4") -- ASUMSI NAMA PART
        if not teleportTo(checkpointCamp4) then break end

        -- Langkah 10: Tunggu 5 menit kemudian teleport ke cek poin ini: workspace["Checkpoints%"]["South Pole"].SpawnLocation
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO SOUTH_POLE_SPAWN...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local southPoleSpawn = workspace:FindFirstChild("Checkpoints%") and workspace["Checkpoints%"]:FindFirstChild("South Pole") and workspace["Checkpoints%"]["South Pole"]:FindFirstChild("SpawnLocation")
        if not teleportTo(southPoleSpawn) then break end

        -- Langkah 11: Minum air setiap 7 menit (ditangani oleh waterDrinkThread terpisah)
        -- Langkah ini tidak perlu diulang di sini karena sudah ada thread khusus.

        updateStatus("EXPEDITION CYCLE COMPLETE. RESTARTING...")
        waitSeconds(timers.cycleRestartDelay) -- Penundaan sebelum mengulang siklus
    end
end

-- // Loop Latar Belakang (dipertahankan dari mainv2, tapi tidak digunakan untuk ekspedisi) //
local function increaseAptitudeMineLoop_enhanced()
    while scriptRunning do
        fireRemoteEnhanced("IncreaseAptitude", "Base", {})
        task.wait(timers.aptitude_mine_interval)
        if not scriptRunning then break end
        fireRemoteEnhanced("Mine", "Base", {})
        task.wait()
    end
end
local function updateQiLoop_enhanced()
    while scriptRunning do
        if not stopUpdateQi and not pauseUpdateQiTemporarily then fireRemoteEnhanced("UpdateQi", "Base", {}) end
        task.wait(timers.update_qi_interval)
    end
end

-- Tombol Start
StartButton.MouseButton1Click:Connect(function()
    scriptRunning = not scriptRunning
    if scriptRunning then
        StartButton.Text = "EXPEDITION_ACTIVE" -- Diubah
        StartButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30) -- Merah menyala
        StartButton.TextColor3 = Color3.fromRGB(255,255,255)
        updateStatus("INIT EXPEDITION...")

        -- Teleport awal ke Basecamp (Langkah 1 dari alur)
        local basecampPart = workspace:FindFirstChild("Search_And_Rescue%") and workspace["Search_And_Rescue%"]:FindFirstChild("Helicopter_Spawn_Clickers") and workspace["Search_And_Rescue%"]["Helicopter_Spawn_Clickers"]:FindFirstChild("Basecamp")
        if basecampPart then
            updateStatus("INITIAL TP TO BASECAMP...")
            teleportTo(basecampPart)
            waitSeconds(timers.teleportWait) -- Tunggu 5 detik setelah teleport awal
        else
            warn("Basecamp part tidak ditemukan. Pastikan 'Search_And_Rescue%' dan 'Helicopter_Spawn_Clickers.Basecamp' ada.")
            updateStatus("ERR: BASECAMP_NOT_FOUND")
            scriptRunning = false
            StartButton.Text = "START EXPEDITION"
            StartButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
            StartButton.TextColor3 = Color3.fromRGB(220,220,220)
            return
        end

        stopUpdateQi = false; pauseUpdateQiTemporarily = false
        -- Thread yang tidak digunakan untuk ekspedisi ini (dipertahankan dari mainv2)
        if not aptitudeMineThread or coroutine.status(aptitudeMineThread) == "dead" then aptitudeMineThread = task.spawn(increaseAptitudeMineLoop_enhanced) end
        if not updateQiThread or coroutine.status(updateQiThread) == "dead" then updateQiThread = task.spawn(updateQiLoop_enhanced) end

        -- Thread utama ekspedisi
        if not mainCycleThread or coroutine.status(mainCycleThread) == "dead" then
            mainCycleThread = task.spawn(function()
                runExpeditionCycle() -- Panggil fungsi ekspedisi utama
                updateStatus("EXPEDITION_HALTED")
                StartButton.Text = "START EXPEDITION"
                StartButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
                StartButton.TextColor3 = Color3.fromRGB(220,220,220)
            end)
        end

        -- Thread untuk minum air
        if not waterDrinkThread or coroutine.status(waterDrinkThread) == "dead" then waterDrinkThread = task.spawn(waterDrinkLoop) end

    else
        updateStatus("HALT_REQUESTED")
        -- Hentikan semua thread saat skrip dihentikan
        if mainCycleThread and coroutine.status(mainCycleThread) ~= "dead" then task.cancel(mainCycleThread); mainCycleThread = nil end
        if aptitudeMineThread and coroutine.status(aptitudeMineThread) ~= "dead" then task.cancel(aptitudeMineThread); aptitudeMineThread = nil end
        if updateQiThread and coroutine.status(updateQiThread) ~= "dead" then task.cancel(updateQiThread); updateQiThread = nil end
        if waterDrinkThread and coroutine.status(waterDrinkThread) ~= "dead" then task.cancel(waterDrinkThread); waterDrinkThread = nil end
    end
end)

-- Tombol Apply Timers
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
    -- Hanya terapkan timer yang relevan dengan ekspedisi
    allTimersValid = applyTextInput(timerInputElements.initialWaitInput, "initialWaitBeforeTeleport", timerInputElements.InitialWaitLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.teleportWaitInput, "teleportWait", timerInputElements.TeleportWaitLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.longWaitInput, "longWaitBeforeCheckpoint", timerInputElements.LongWaitLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.waterDrinkInput, "waterDrinkInterval", timerInputElements.WaterDrinkLabel) and allTimersValid

    local originalStatus = StatusLabel.Text:gsub("STATUS: ", "")
    if allTimersValid then updateStatus("TIMER_CONFIG_APPLIED") else updateStatus("ERR_TIMER_INPUT_INVALID") end
    task.wait(2)
    -- Kembalikan warna label setelah 2 detik
    if timerInputElements.initialWaitLabel then pcall(function() timerInputElements.initialWaitLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.teleportWaitLabel then pcall(function() timerInputElements.teleportWaitLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.longWaitLabel then pcall(function() timerInputElements.longWaitLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.waterDrinkLabel then pcall(function() timerInputElements.waterDrinkLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    updateStatus(originalStatus)
end)

-- --- ANIMASI UI ---
-- Menggunakan task.spawn() untuk memastikan animasi berjalan di thread terpisah.
-- task.spawn() umumnya lebih andal dan direkomendasikan daripada spawn() lama.

task.spawn(function() -- Animasi Latar Belakang Frame (Glitchy Background)
    if not Frame or not Frame.Parent then return end
    local baseColor = Color3.fromRGB(15, 15, 20)
    local glitchColor1 = Color3.fromRGB(25, 20, 30)
    local glitchColor2 = Color3.fromRGB(10, 10, 15)
    local borderBase = Color3.fromRGB(255,0,0)
    local borderGlitch = Color3.fromRGB(0,255,255)

    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Hanya beranimasi saat tidak diminimize
            local r = math.random()
            if r < 0.05 then -- Glitch intens
                Frame.BackgroundColor3 = glitchColor1
                Frame.BorderColor3 = borderGlitch
                task.wait(0.05)
                Frame.BackgroundColor3 = glitchColor2
                task.wait(0.05)
            elseif r < 0.2 then -- Glitch ringan
                Frame.BackgroundColor3 = Color3.Lerp(baseColor, glitchColor1, math.random())
                Frame.BorderColor3 = Color3.Lerp(borderBase, borderGlitch, math.random()*0.5)
                task.wait(0.1)
            else
                Frame.BackgroundColor3 = baseColor
                Frame.BorderColor3 = borderBase
            end
            -- Animasi border utama (HSV shift)
            local h,s,v = Color3.toHSV(Frame.BorderColor3)
            Frame.BorderColor3 = Color3.fromHSV((h + 0.005)%1, s, v)
        else -- Jika diminimize, pastikan warna kembali normal untuk 'Z'
            Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
            Frame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Atau warna solid apa pun yang Anda inginkan untuk pop-up
        end
        task.wait(0.05)
    end
end)

task.spawn(function() -- Animasi UiTitleLabel (ZXHELL Glitch)
    if not UiTitleLabel or not UiTitleLabel.Parent then return end
    local originalText = UiTitleLabel.Text
    local glitchChars = {"@", "#", "$", "%", "&", "*", "!", "?", "/", "\\", "|", "_"}
    local baseColor = Color3.fromRGB(255, 25, 25)
    local originalPos = UiTitleLabel.Position

    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Hanya beranimasi saat tidak diminimize
            local r = math.random()
            local isGlitchingText = false

            if r < 0.02 then -- Glitch Text Parah & Posisi
                isGlitchingText = true
                local newText = ""
                for i = 1, #originalText do
                    if math.random() < 0.7 then
                        newText = newText .. glitchChars[math.random(#glitchChars)]
                    else
                        newText = newText .. originalText:sub(i,i)
                    end
                end
                UiTitleLabel.Text = newText
                UiTitleLabel.TextColor3 = Color3.fromRGB(math.random(200,255), math.random(0,50), math.random(0,50))
                UiTitleLabel.Position = originalPos + UDim2.fromOffset(math.random(-2,2), math.random(-2,2))
                UiTitleLabel.Rotation = math.random(-1,1) * 0.5
                task.wait(0.07)
            elseif r < 0.1 then -- Glitch Warna & Stroke
                UiTitleLabel.TextColor3 = Color3.fromHSV(math.random(), 1, 1)
                UiTitleLabel.TextStrokeColor3 = Color3.fromHSV(math.random(), 0.8, 1)
                UiTitleLabel.TextStrokeTransparency = math.random() * 0.3
                UiTitleLabel.Rotation = math.random(-1,1) * 0.2
                task.wait(0.1)
            else -- Kembali normal atau animasi warna halus
                UiTitleLabel.Text = originalText
                UiTitleLabel.TextStrokeTransparency = 0.5
                UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)
                UiTitleLabel.Position = originalPos
                UiTitleLabel.Rotation = 0
            end

            -- Animasi warna RGB halus jika tidak sedang glitch parah
            if not isGlitchingText then
                local hue = (tick()*0.1) % 1
                local r_rgb, g_rgb, b_rgb = Color3.fromHSV(hue, 1, 1).R, Color3.fromHSV(hue, 1, 1).G, Color3.fromHSV(hue, 1, 1).B
                r_rgb = math.min(1, r_rgb + 0.6) -- Dominasi merah
                g_rgb = g_rgb * 0.4
                b_rgb = b_rgb * 0.4
                UiTitleLabel.TextColor3 = Color3.new(r_rgb, g_rgb, b_rgb)
            end
        end
        task.wait(0.05)
    end
end)

task.spawn(function() -- Animasi Tombol (Subtle Pulse)
    local buttonsToAnimate = {StartButton, ApplyTimersButton, MinimizeButton}
    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Hanya beranimasi saat tidak diminimize
            for _, btn in ipairs(buttonsToAnimate) do
                if btn and btn.Parent then
                    local originalBorder = btn.BorderColor3

                    -- Efek hover/pulse sederhana pada border
                    if btn.Name == "StartButton" and scriptRunning then
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
    if scriptRunning then warn("Game ditutup, menghentikan skrip..."); scriptRunning = false; task.wait(0.5) end
    if ScreenGui and ScreenGui.Parent then pcall(function() ScreenGui:Destroy() end) end
    print("Pembersihan skrip selesai.")
end)

-- Inisialisasi
print("Skrip Otomatisasi Ekspesisi Telah Dimuat.")
task.wait(1)
if StatusLabel and StatusLabel.Parent and StatusLabel.Text == "" then StatusLabel.Text = "STATUS: STANDBY" end
