-- MainScript.lua - Gabungan UI dan Logika Teleportasi Otomatis
-- Dibuat berdasarkan referensi mainv2.lua dan script Roblox via executor
-- Disesuaikan untuk game "Ekspedisi Antartika"

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
local mainCycleThread = nil -- Thread utama untuk siklus teleportasi

local isMinimized = false
local originalFrameSize = UDim2.new(0, 260, 0, 250) -- Ukuran UI disesuaikan karena timer input berkurang
local minimizedFrameSize = UDim2.new(0, 50, 0, 50) -- Ukuran pop-up 'Z'
local minimizedZLabel = Instance.new("TextLabel") -- Label khusus untuk pop-up 'Z'

-- Kumpulan elemen yang visibilitasnya akan di-toggle
local elementsToToggleVisibility = {} -- Akan diisi setelah semua elemen UI dibuat

-- --- Tabel Konfigurasi Timer ---
local timers = {
    wait_after_teleport = 300, -- Default 5 menit (300 detik)
    genericShortDelay = 0.5,
}

-- --- Konfigurasi Teleportasi untuk "Ekspedisi Antartika" ---
-- PENTING: Path dan CFrame ini adalah CONTOH. Anda mungkin perlu
-- menggunakan alat seperti Dex Explorer di game untuk menemukan
-- path dan koordinat CFrame yang akurat dari lokasi di "Ekspedisi Antartika".
local teleportSequence = {
    {
        name = "Base Camp",
        path = "Workspace.Antarctica.BaseCamp.SpawnLocation", -- Contoh path
        cframe = CFrame.new(0, 100, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), -- Contoh CFrame
        waitAfter = 300 -- 5 menit
    },
    {
        name = "Ice Cave Entrance",
        path = "Workspace.Antarctica.IceCave.Entrance", -- Contoh path
        cframe = CFrame.new(1000, 50, 500, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        waitAfter = 300 -- 5 menit
    },
    {
        name = "Research Outpost",
        path = "Workspace.Structures.ResearchOutpost.MainBuilding", -- Contoh path
        cframe = CFrame.new(2500, 200, 1000, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        waitAfter = 300 -- 5 menit
    },
    {
        name = "Glacier Peak Summit",
        path = "Workspace.Mountains.GlacierPeak.Summit", -- Contoh path
        cframe = CFrame.new(4000, 500, 1500, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        waitAfter = 300 -- 5 menit
    },
    {
        name = "Penguin Colony",
        path = "Workspace.Wildlife.PenguinColony.Center", -- Contoh path
        cframe = CFrame.new(5000, 50, 2000, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        waitAfter = 300 -- 5 menit
    },
    {
        name = "Ancient Ruin",
        path = "Workspace.Ruins.AncientRuin.Entrance", -- Contoh path
        cframe = CFrame.new(6500, 75, 2500, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        waitAfter = 300 -- 5 menit
    },
    -- Anda bisa menambahkan lebih banyak lokasi di sini sesuai kebutuhan game
}


-- // Parent UI ke player //
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local function setupCoreGuiParenting()
    if not ScreenGui.Parent or ScreenGui.Parent ~= CoreGui then
        ScreenGui.Parent = CoreGui
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
TimerTitleLabel.Text = "// TIMER CONFIGURATION_SEQ"
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
-- Inisialisasi nilai input timer dari tabel timers
timerInputElements.waitAfterTeleportInput = createTimerInput("WaitAfterTeleport", currentYConfig, "WAIT_AFTER_TELEPORT", timers.wait_after_teleport)
currentYConfig = currentYConfig + 25 -- Jarak antar input (disesuaikan)

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
    timerInputElements.WaitAfterTeleportLabel, timerInputElements.WaitAfterTeleportInput,
    MinimizeButton -- Include MinimizeButton here to hide it during 'Z' mode
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
        -- Perbarui status setiap detik saat menunggu
        local remainingTime = math.floor(sec - (tick() - startTime))
        if remainingTime >= 0 then
            updateStatus(string.format("WAITING: %ds", remainingTime))
        end
    until not scriptRunning or tick() - startTime >= sec
end

-- // Fungsi untuk mencari objek/part secara otomatis //
-- Ini adalah fungsi penting untuk mengatasi ketidakmungkinan path yang tepat
local function findObject(baseObject, path)
    local parts = string.split(path, ".")
    local currentObject = baseObject

    for i, partName in ipairs(parts) do
        -- Handle wildcard '%'
        if string.find(partName, "%%") then
            local actualPartName = string.gsub(partName, "%%", "")
            local found = false
            for _, child in ipairs(currentObject:GetChildren()) do
                if string.find(child.Name, actualPartName) then
                    currentObject = child
                    found = true
                    break
                end
            end
            if not found then return nil end -- Tidak ditemukan objek dengan wildcard
        else
            currentObject = currentObject:FindFirstChild(partName)
        end

        if not currentObject then
            return nil -- Objek tidak ditemukan di sepanjang path
        end
    end
    return currentObject
end

-- // Fungsi Teleportasi //
-- targetInstance bisa berupa BasePart atau Model. targetCFrameFallback digunakan jika targetInstance tidak valid.
local function teleportPlayer(targetInstance, targetCFrameFallback)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        warn("HumanoidRootPart tidak ditemukan atau karakter tidak ada.")
        return false
    end
    local hrp = character.HumanoidRootPart

    -- Pastikan HumanoidRootPart tidak di-anchored atau di-locked
    hrp.Anchored = false
    hrp.CanCollide = false -- Agar tidak tersangkut

    local actualCFrame = targetCFrameFallback -- Default ke CFrame fallback

    if targetInstance then
        if targetInstance:IsA("BasePart") then
            actualCFrame = targetInstance.CFrame
        elseif targetInstance:IsA("Model") and targetInstance.PrimaryPart then
            actualCFrame = targetInstance.PrimaryPart.CFrame
        else
            warn("Target instance ditemukan tetapi bukan BasePart atau Model dengan PrimaryPart: " .. targetInstance.Name .. ". Menggunakan CFrame fallback.")
        end
    end

    hrp.CFrame = actualCFrame
    task.wait(timers.genericShortDelay) -- Beri sedikit waktu untuk fisika
    hrp.CanCollide = true
    return true
end

-- // Fungsi utama siklus teleportasi //
local function runTeleportCycle()
    for i, step in ipairs(teleportSequence) do
        if not scriptRunning then break end

        updateStatus("TELEPORTING KE: " .. step.name)
        print("Mencoba teleportasi ke: " .. step.name)

        local targetInstance = nil
        if step.path then
            -- Coba cari objek dengan fungsi findObject
            targetInstance = findObject(game.Workspace, step.path)
            if targetInstance then
                print("Objek target ditemukan melalui path: " .. targetInstance.Name)
                -- Jika ada childIndex, coba ambil child spesifik (hanya berlaku jika targetInstance adalah Model)
                if step.childIndex and targetInstance:IsA("Model") and #targetInstance:GetChildren() >= step.childIndex then
                    local specificChild = targetInstance:GetChildren()[step.childIndex]
                    if specificChild:IsA("BasePart") or specificChild:IsA("Model") then
                        targetInstance = specificChild -- Gunakan child spesifik jika itu BasePart atau Model
                        print("Objek target spesifik ditemukan melalui indeks anak: " .. targetInstance.Name)
                    else
                        warn("Anak pada indeks " .. step.childIndex .. " bukan BasePart atau Model. Menggunakan CFrame dari induk.")
                    end
                end
            else
                warn("Tidak dapat menemukan objek target melalui path: " .. step.path .. ". Menggunakan CFrame fallback.")
            end
        end

        local success = teleportPlayer(targetInstance, step.cframe) -- Lewati targetInstance dan CFrame fallback

        if not success then
            updateStatus("TELEPORT GAGAL: " .. step.name)
            warn("Teleportasi gagal untuk: " .. step.name)
            scriptRunning = false -- Hentikan skrip jika teleportasi gagal
            break
        end

        updateStatus("TIBA DI: " .. step.name)
        waitSeconds(step.waitAfter or timers.wait_after_teleport) -- Gunakan waitAfter spesifik atau default
    end

    if scriptRunning then
        updateStatus("SIKLUS SELESAI. MEMULAI ULANG...")
        task.wait(timers.genericShortDelay)
    end
end

-- Tombol Start
StartButton.MouseButton1Click:Connect(function()
    scriptRunning = not scriptRunning
    if scriptRunning then
        StartButton.Text = "SYSTEM_ACTIVE"
        StartButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30) -- Merah menyala
        StartButton.TextColor3 = Color3.fromRGB(255,255,255)
        updateStatus("INIT_SEQUENCE")
        if not mainCycleThread or coroutine.status(mainCycleThread) == "dead" then
            mainCycleThread = task.spawn(function()
                while scriptRunning do
                    runTeleportCycle()
                    if not scriptRunning then break end
                    updateStatus("SIKLUS_REINIT")
                    task.wait(1)
                end
                updateStatus("SYSTEM_HALTED")
                StartButton.Text = "START SEQUENCE"
                StartButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
                StartButton.TextColor3 = Color3.fromRGB(220,220,220)
            end)
        end
    else
        updateStatus("PERMINTAAN_HENTI")
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
    allTimersValid = applyTextInput(timerInputElements.waitAfterTeleportInput, "wait_after_teleport", timerInputElements.WaitAfterTeleportLabel) and allTimersValid
    local originalStatus = StatusLabel.Text:gsub("STATUS: ", "")
    if allTimersValid then updateStatus("KONFIGURASI_TIMER_DITERAPKAN") else updateStatus("ERR_INPUT_TIMER_TIDAK_VALID") end
    task.wait(2)
    if timerInputElements.WaitAfterTeleportLabel then pcall(function() timerInputElements.WaitAfterTeleportLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
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
print("Skrip Otomatisasi Teleportasi (Versi UI Canggih) Telah Dimuat.")
task.wait(1)
if StatusLabel and StatusLabel.Parent and StatusLabel.Text == "" then StatusLabel.Text = "STATUS: STANDBY" end

