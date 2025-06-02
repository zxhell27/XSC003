-- MainScript.lua
-- Gabungan UI dan Logika dengan UI pop-up 'Z' merah RGB, dan fungsi Teleportasi.
-- Alur utama difokuskan hanya pada urutan teleportasi dari dokumen yang diberikan.

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
local stopUpdateQi = false -- Mungkin tidak relevan jika hanya teleportasi, tapi dipertahankan untuk kompatibilitas UI
local pauseUpdateQiTemporarily = false -- Mungkin tidak relevan jika hanya teleportasi, tapi dipertahankan untuk kompatibilitas UI
local mainCycleThread = nil
local aptitudeMineThread = nil -- Mungkin tidak relevan jika hanya teleportasi, tapi dipertahankan untuk kompatibilitas UI
local updateQiThread = nil -- Mungkin tidak relevan jika hanya teleportasi, tapi dipertahankan untuk kompatibilitas UI

local isMinimized = false
local originalFrameSize = UDim2.new(0, 260, 0, 420) -- Ukuran awal UI lebih kecil
local minimizedFrameSize = UDim2.new(0, 50, 0, 50) -- Ukuran pop-up 'Z'
local minimizedZLabel = Instance.new("TextLabel") -- Label khusus untuk pop-up 'Z'

-- Kumpulan elemen yang visibilitasnya akan di-toggle
local elementsToToggleVisibility = {} -- Akan diisi setelah semua elemen UI dibuat

-- --- Tabel Konfigurasi Timer ---
local timers = {
    -- Timer yang relevan untuk alur teleportasi
    wait_after_camp_teleport = 5 * 60, -- 5 menit (diambil dari dokumen alur)
    genericShortDelay = 0.5, -- Jeda singkat setelah teleportasi checkpoint

    -- Timer lain dari mainv2.lua yang mungkin tidak digunakan dalam alur teleportasi saja,
    -- tetapi dipertahankan untuk konsistensi UI konfigurasi timer.
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
    reincarnateDelay = 0.5,
    buyItemDelay = 0.25,
    changeMapDelay = 0.5,
    fireserver_generic_delay = 0.25
}

-- --- Tabel Konfigurasi Teleportasi ---
-- Data ini diambil langsung dari file "script Roblox via executor" Anda.
local teleportLocations = {
    -- Camp 1
    ["Camp1"] = {
        path = "workspace[\"Camp_Main_Tents%\"].Camp1:GetChildren()[11]",
        cframe = CFrame.new(-3694.08691, 225.826172, 277.052979, 0.710165381, 0, 0.704034865, 0, 1, 0, -0.704034865, 0, 0.710165381)
    },
    ["CheckpointCamp1"] = {
        path = "workspace[\"Checkpoints%\"][\"Camp 1\"].SpawnLocation",
        cframe = CFrame.new(-3719.18188, 223.203995, 235.391006, 0, 0, 1, 0, 1, -0, -1, 0, 0)
    },
    -- Camp 2
    ["Camp2"] = {
        path = "workspace[\"Camp_Main_Tents%\"].Camp2:GetChildren()[11]",
        cframe = CFrame.new(1774.76111, 102.314171, -179.4328, -0.790706277, 0, -0.612195849, 0, 1, 0, 0.612195849, 0, -0.790706277)
    },
    ["CheckpointCamp2"] = {
        path = "workspace[\"Checkpoints%\"][\"Camp 2\"].SpawnLocation",
        cframe = CFrame.new(1790.31799, 103.665001, -137.858994, 0, 0, 1, 0, 1, -0, -1, 0, 0)
    },
    -- Camp 3
    ["Camp3"] = {
        path = "workspace[\"Camp_Main_Tents%\"][\"Camp3\"]:GetChildren()[13]",
        cframe = CFrame.new(5853.9834, 325.546478, -0.24318853, 0.494506121, -0, -0.869174123, 0, 1, -0, 0.869174123, 0, 0.494506121)
    },
    ["CheckpointCamp3"] = {
        path = "workspace[\"Checkpoints%\"][\"Camp 3\"].SpawnLocation",
        cframe = CFrame.new(5892.38916, 319.35498, -19.0779991, 0, 0, 1, 0, 1, -0, -1, 0, 0)
    },
    -- Camp 4
    ["Camp4"] = {
        path = "workspace[\"Camp_Main_Tents%\"].Camp4.Floor",
        cframe = CFrame.new(8999.26465, 593.866089, 59.4377747, -0.999371052, 0, 0.035472773, 0, 1, 0, -0.035472773, 0, -0.999371052)
    },
    ["CheckpointCamp4"] = {
        path = "workspace[\"Checkpoints%\"][\"Camp 4\"].SpawnLocation",
        cframe = CFrame.new(8992.36328, 594.10498, 103.060997, 0, 0, 1, 0, 1, -0, -1, 0, 0)
    },
    -- South Pole
    ["CheckpointSouthPole"] = {
        path = "workspace[\"Checkpoints%\"][\"South Pole\"].SpawnLocation",
        cframe = CFrame.new(10995.2461, 545.255127, 114.804474, 0.819186032, 0.573527873, 3.9935112e-06, -3.9935112e-06, 1.2755394e-05, -1, -0.573527873, 0.819186091, 1.2755394e-05)
    },
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
UiTitleLabel.Text = "ZXHELL X ZEDLIST"
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
StartButton.Text = "START SEQUENCE"
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
TimerTitleLabel.Text = "// KONFIGURASI_TIMER"
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
    input.PlaceholderText = "detik" -- Diubah ke Bahasa Indonesia
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
-- Inisialisasi nilai input timer dari tabel timers
-- Hanya tampilkan timer yang relevan untuk teleportasi atau yang umum
timerInputElements.waitAfterCampTeleportInput = createTimerInput("WaitAfterCampTeleport", currentYConfig, "Tunggu Setelah Camp", timers.wait_after_camp_teleport)
currentYConfig = currentYConfig + 25
-- Anda bisa menambahkan lebih banyak input timer jika ada durasi spesifik lainnya yang ingin dikonfigurasi pengguna untuk alur teleportasi.
-- Untuk saat ini, saya hanya menampilkan yang paling relevan.
timerInputElements.genericShortDelayInput = createTimerInput("GenericShortDelay", currentYConfig, "Jeda Singkat", timers.genericShortDelay)
currentYConfig = currentYConfig + 35 -- Disesuaikan

ApplyTimersButton.Size = UDim2.new(1, -40, 0, 30) -- Lebih kecil
ApplyTimersButton.Position = UDim2.new(0, 20, 0, currentYConfig + yOffsetForTimers)
ApplyTimersButton.Text = "TERAPKAN_TIMER" -- Diubah ke Bahasa Indonesia
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
    timerInputElements.waitAfterCampTeleportInput, timerInputElements.waitAfterCampTeleportLabel,
    timerInputElements.genericShortDelayInput, timerInputElements.genericShortDelayLabel,
    MinimizeButton -- Sertakan MinimizeButton di sini untuk menyembunyikannya dalam mode 'Z'
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
        -- Sembunyikan semua elemen kecuali Frame dan label 'Z'
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

-- Fungsi fireRemoteEnhanced (dipertahankan untuk kompatibilitas, meskipun mungkin tidak digunakan dalam alur teleportasi saja)
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

-- // Fungsi Teleportasi //
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local function teleportToCFrame(targetCFrame, locationName)
    if not localPlayer or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        updateStatus("Teleport_Gagal: Karakter_Tidak_Ditemukan") -- Diubah ke Bahasa Indonesia
        warn("Teleport gagal: Karakter LocalPlayer atau HumanoidRootPart tidak ditemukan.") -- Diubah ke Bahasa Indonesia
        return false
    end

    local hrp = localPlayer.Character.HumanoidRootPart
    local success = pcall(function()
        hrp.CFrame = targetCFrame
    end)

    if success then
        updateStatus("Teleporting: " .. (locationName or "Lokasi_Tidak_Dikenal")) -- Diubah ke Bahasa Indonesia
        return true
    else
        updateStatus("Teleport_Gagal: " .. (locationName or "Lokasi_Tidak_Dikenal")) -- Diubah ke Bahasa Indonesia
        warn("Error teleportasi ke " .. (locationName or "Lokasi_Tidak_Dikenal") .. ": " .. tostring(pcallResult)) -- Diubah ke Bahasa Indonesia
        return false
    end
end

-- // Fungsi utama alur (Hanya Teleportasi) //
local function runCycle()
    updateStatus("Memulai_Alur_Teleportasi") -- Diubah ke Bahasa Indonesia

    -- Teleport ke Camp 1
    updateStatus("Teleportasi_ke_Camp_1")
    if not teleportToCFrame(teleportLocations.Camp1.cframe, "Camp 1") then scriptRunning = false; return end
    waitSeconds(timers.wait_after_camp_teleport) -- Tunggu 5 menit
    if not scriptRunning then return end

    -- Teleport ke Checkpoint Camp 1
    updateStatus("Teleportasi_ke_Checkpoint_Camp_1")
    if not teleportToCFrame(teleportLocations.CheckpointCamp1.cframe, "Checkpoint Camp 1") then scriptRunning = false; return end
    task.wait(timers.genericShortDelay) -- Jeda singkat setelah teleport
    if not scriptRunning then return end

    -- Teleport ke Camp 2
    updateStatus("Teleportasi_ke_Camp_2")
    if not teleportToCFrame(teleportLocations.Camp2.cframe, "Camp 2") then scriptRunning = false; return end
    waitSeconds(timers.wait_after_camp_teleport) -- Tunggu 5 menit
    if not scriptRunning then return end

    -- Teleport ke Checkpoint Camp 2
    updateStatus("Teleportasi_ke_Checkpoint_Camp_2")
    if not teleportToCFrame(teleportLocations.CheckpointCamp2.cframe, "Checkpoint Camp 2") then scriptRunning = false; return end
    task.wait(timers.genericShortDelay)
    if not scriptRunning then return end

    -- Teleport ke Camp 3
    updateStatus("Teleportasi_ke_Camp_3")
    if not teleportToCFrame(teleportLocations.Camp3.cframe, "Camp 3") then scriptRunning = false; return end
    waitSeconds(timers.wait_after_camp_teleport) -- Tunggu 5 menit
    if not scriptRunning then return end

    -- Teleport ke Checkpoint Camp 3
    updateStatus("Teleportasi_ke_Checkpoint_Camp_3")
    if not teleportToCFrame(teleportLocations.CheckpointCamp3.cframe, "Checkpoint Camp 3") then scriptRunning = false; return end
    task.wait(timers.genericShortDelay)
    if not scriptRunning then return end

    -- Teleport ke Camp 4
    updateStatus("Teleportasi_ke_Camp_4")
    if not teleportToCFrame(teleportLocations.Camp4.cframe, "Camp 4") then scriptRunning = false; return end
    waitSeconds(timers.wait_after_camp_teleport) -- Tunggu 5 menit
    if not scriptRunning then return end

    -- Teleport ke Checkpoint Camp 4
    updateStatus("Teleportasi_ke_Checkpoint_Camp_4")
    if not teleportToCFrame(teleportLocations.CheckpointCamp4.cframe, "Checkpoint Camp 4") then scriptRunning = false; return end
    task.wait(timers.genericShortDelay)
    if not scriptRunning then return end

    -- Teleport ke Checkpoint South Pole
    updateStatus("Teleportasi_ke_Checkpoint_South_Pole")
    waitSeconds(timers.wait_after_camp_teleport) -- Tunggu 5 menit
    if not scriptRunning then return end
    if not teleportToCFrame(teleportLocations.CheckpointSouthPole.cframe, "Checkpoint South Pole") then scriptRunning = false; return end
    task.wait(timers.genericShortDelay)
    if not scriptRunning then return end

    updateStatus("Siklus_Teleportasi_Selesai_Mengulang") -- Diubah ke Bahasa Indonesia
end

-- Loop Latar Belakang (Dipertahankan untuk kompatibilitas, tapi tidak akan melakukan apa-apa jika hanya alur teleportasi)
local function increaseAptitudeMineLoop_enhanced()
    while scriptRunning do
        -- fireRemoteEnhanced("IncreaseAptitude", "Base", {}) -- Dikomentari karena bukan bagian dari alur teleportasi
        task.wait(timers.aptitude_mine_interval)
        -- if not scriptRunning then break end
        -- fireRemoteEnhanced("Mine", "Base", {}) -- Dikomentari karena bukan bagian dari alur teleportasi
        task.wait()
    end
end
local function updateQiLoop_enhanced()
    while scriptRunning do
        -- if not stopUpdateQi and not pauseUpdateQiTemporarily then fireRemoteEnhanced("UpdateQi", "Base", {}) end -- Dikomentari
        task.wait(timers.update_qi_interval)
    end
end

-- Tombol Start
StartButton.MouseButton1Click:Connect(function()
    scriptRunning = not scriptRunning
    if scriptRunning then
        StartButton.Text = "SISTEM_AKTIF" -- Diubah ke Bahasa Indonesia
        StartButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30) -- Merah menyala
        StartButton.TextColor3 = Color3.fromRGB(255,255,255)
        updateStatus("MEMULAI_URUTAN") -- Diubah ke Bahasa Indonesia
        stopUpdateQi = false; pauseUpdateQiTemporarily = false
        -- Loop latar belakang mungkin tidak relevan jika hanya teleportasi, tapi dipertahankan untuk struktur.
        if not aptitudeMineThread or coroutine.status(aptitudeMineThread) == "dead" then aptitudeMineThread = task.spawn(increaseAptitudeMineLoop_enhanced) end
        if not updateQiThread or coroutine.status(updateQiThread) == "dead" then updateQiThread = task.spawn(updateQiLoop_enhanced) end
        if not mainCycleThread or coroutine.status(mainCycleThread) == "dead" then
            mainCycleThread = task.spawn(function()
                while scriptRunning do
                    runCycle()
                    if not scriptRunning then break end
                    updateStatus("SIKLUS_MENGULANG") -- Diubah ke Bahasa Indonesia
                    task.wait(1)
                end
                updateStatus("SISTEM_BERHENTI") -- Diubah ke Bahasa Indonesia
                StartButton.Text = "MULAI_URUTAN" -- Diubah ke Bahasa Indonesia
                StartButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
                StartButton.TextColor3 = Color3.fromRGB(220,220,220)
            end)
        end
    else
        updateStatus("PERMINTAAN_BERHENTI") -- Diubah ke Bahasa Indonesia
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
    -- Hanya terapkan timer yang relevan untuk alur teleportasi
    allTimersValid = applyTextInput(timerInputElements.waitAfterCampTeleportInput, "wait_after_camp_teleport", timerInputElements.waitAfterCampTeleportLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.genericShortDelayInput, "genericShortDelay", timerInputElements.genericShortDelayLabel) and allTimersValid

    local originalStatus = StatusLabel.Text:gsub("STATUS: ", "")
    if allTimersValid then updateStatus("KONFIGURASI_TIMER_DITERAPKAN") else updateStatus("ERR_INPUT_TIMER_TIDAK_VALID") end -- Diubah ke Bahasa Indonesia
    task.wait(2)
    -- Reset warna label
    if timerInputElements.waitAfterCampTeleportLabel then pcall(function() timerInputElements.waitAfterCampTeleportLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.genericShortDelayLabel then pcall(function() timerInputElements.genericShortDelayLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
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
print("Skrip Otomatisasi (Teleportasi Saja) Telah Dimuat.") -- Pesan inisialisasi yang diperbarui
task.wait(1)
if StatusLabel and StatusLabel.Parent and StatusLabel.Text == "" then StatusLabel.Text = "STATUS: SIAGA" end -- Diubah ke Bahasa Indonesia
