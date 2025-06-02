--!strict

-- Ini adalah skrip konseptual untuk pembelajaran di Roblox Studio.
-- Skrip ini TIDAK dimaksudkan untuk digunakan dengan eksploitasi atau perangkat lunak pihak ketiga.
-- Selalu kembangkan game Anda sesuai dengan Ketentuan Layanan Roblox.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService") -- Digunakan untuk mendeteksi apakah skrip berjalan di Studio atau game
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Fungsi untuk melakukan teleportasi ke suatu bagian (Part)
local function TeleportToPart(targetPart: Part)
    if targetPart and HumanoidRootPart then
        -- Pastikan karakter tidak jatuh melalui lantai setelah teleportasi
        -- Tambahkan offset Y sedikit di atas bagian target
        HumanoidRootPart.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, HumanoidRootPart.Size.Y / 2, 0))
        print("Teleportasi ke: " .. targetPart.Name)
    else
        warn("Gagal teleportasi: Bagian target atau HumanoidRootPart tidak ditemukan.")
    end
end

-- Fungsi untuk mensimulasikan tindakan minum air
local function DrinkWater()
    -- Dalam game sungguhan, ini akan memicu RemoteEvent ke server
    -- untuk memperbarui status air pemain.
    -- Contoh:
    local waterBottleRemoteEvent = Character:WaitForChild("Water Bottle", 10)
    if waterBottleRemoteEvent then
        local remoteEvent = waterBottleRemoteEvent:WaitForChild("RemoteEvent", 10)
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireServer()
            print("Pemain minum air.")
        else
            warn("RemoteEvent 'Water Bottle' tidak ditemukan atau bukan RemoteEvent.")
        end
    else
        warn("Objek 'Water Bottle' tidak ditemukan di karakter.")
    end
end

-- Definisi jalur teleportasi
-- Catatan: Menggunakan GetChildren()[index] tidak disarankan karena indeks dapat berubah.
-- Lebih baik menggunakan nama bagian jika memungkinkan atau PathfindingService untuk navigasi yang kompleks.
local teleportPath = {
    -- {target = path_ke_bagian, delay = waktu_tunggu_sebelum_teleport}
    {target = workspace:WaitForChild("Search_And_Rescue%"):WaitForChild("Helicopter_Spawn_Clickers"):WaitForChild("Basecamp"), delay = 5},
    {target = workspace:WaitForChild("Camp_Main_Tents%"):WaitForChild("Camp1"), delay = 5},
    -- Untuk checkpoint yang menggunakan indeks, Anda perlu memastikan indeksnya stabil atau cari cara lain untuk mereferensikannya.
    -- Ini adalah contoh yang kurang ideal dan mungkin perlu disesuaikan di lingkungan Anda.
    {target = workspace:GetChildren()[264], delay = 300}, -- 5 menit = 300 detik
    {target = workspace:WaitForChild("Camp_Main_Tents%"):WaitForChild("Camp2"), delay = 5},
    {target = workspace:GetChildren()[731], delay = 300},
    {target = workspace:WaitForChild("Camp_Main_Tents%"):WaitForChild("Camp3"), delay = 5},
    {target = workspace:GetChildren()[550], delay = 300},
    {target = workspace:WaitForChild("Camp_Main_Tents%"):WaitForChild("Camp4"), delay = 5},
    -- Pastikan nama bagian "Checkpoint *camp 4*" adalah nama yang tepat di workspace Anda.
    -- Karakter khusus seperti '*' mungkin tidak ideal dalam nama objek Roblox.
    {target = workspace:WaitForChild("Checkpoint camp 4"), delay = 300}, -- Asumsi nama bagian adalah "Checkpoint camp 4"
    {target = workspace:WaitForChild("Checkpoints%"):WaitForChild("South Pole"):WaitForChild("SpawnLocation"), delay = 300}
}

-- Fungsi utama untuk menjalankan alur teleportasi
local function StartExpedition()
    print("Ekspedisi dimulai!")

    local currentStep = 1
    local waterTimer = 0
    local WATER_INTERVAL = 7 * 60 -- 7 menit dalam detik

    while true do
        -- Pastikan karakter masih ada dan HumanoidRootPart valid
        if not Character or not HumanoidRootPart or not HumanoidRootPart.Parent then
            warn("Karakter atau HumanoidRootPart tidak valid, menghentikan ekspedisi.")
            break
        end

        local step = teleportPath[currentStep]
        if step then
            TeleportToPart(step.target)
            print("Menunggu " .. step.delay .. " detik sebelum langkah berikutnya...")
            -- Tunggu untuk durasi langkah saat ini
            local remainingTime = step.delay
            while remainingTime > 0 do
                local deltaTime = task.wait(1) -- Tunggu 1 detik setiap iterasi
                remainingTime -= deltaTime
                waterTimer += deltaTime

                -- Periksa apakah sudah waktunya minum air
                if waterTimer >= WATER_INTERVAL then
                    DrinkWater()
                    waterTimer = 0 -- Reset timer air
                end
            end
        else
            -- Jika semua langkah selesai, ulangi dari langkah kedua (Camp1)
            print("Semua langkah teleportasi selesai. Mengulang dari Camp1.")
            currentStep = 2 -- Ulangi dari nomor 2 sesuai alur
            waterTimer = 0 -- Reset timer air saat mengulang jalur
        end

        currentStep = currentStep + 1
        if currentStep > #teleportPath then
            currentStep = 2 -- Ulangi dari langkah kedua (Camp1)
        end
    end
end

-- Mulai ekspedisi setelah karakter dimuat sepenuhnya
-- Gunakan Player.CharacterAdded:Connect() untuk memastikan skrip berjalan setiap kali karakter muncul
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    -- Jika Anda ingin ekspedisi dimulai setiap kali karakter muncul, panggil StartExpedition di sini.
    -- Untuk skenario pembelajaran, mungkin lebih baik memicu ini secara manual atau hanya sekali.
end)

-- Panggil fungsi ekspedisi setelah skrip dimuat dan karakter siap
-- Ini akan memastikan bahwa skrip berjalan saat game dimulai atau saat pemain pertama kali muncul.
task.spawn(StartExpedition) -- Gunakan task.spawn untuk menjalankan fungsi secara asinkron
