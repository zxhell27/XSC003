-- Skrip Lokal untuk mengelola teleportasi pemain lokal dalam ekspedisi.
-- Skrip ini harus ditempatkan di StarterPlayerScripts.

-- Mendapatkan layanan dan objek yang diperlukan
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Digunakan untuk RemoteEvent jika ada

local Player = Players.LocalPlayer -- Mendapatkan pemain lokal
local Character = Player.Character or Player.CharacterAdded:Wait() -- Mendapatkan karakter pemain, menunggu jika belum dimuat
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") -- Mendapatkan HumanoidRootPart karakter

-- Fungsi untuk melakukan teleportasi pemain ke CFrame bagian target
local function teleportPlayer(targetPart)
    -- Memastikan HumanoidRootPart dan bagian target ada dan merupakan BasePart
    if HumanoidRootPart and targetPart and targetPart:IsA("BasePart") then
        HumanoidRootPart.CFrame = targetPart.CFrame
        print("Teleported ke: " .. targetPart.Name)
    else
        warn("Target tidak valid untuk teleportasi atau HumanoidRootPart tidak ditemukan.")
    end
end

-- Fungsi untuk mengelola tindakan minum air
local function drinkWater()
    local waterBottle = Character:FindFirstChild("Water Bottle") -- Mencari objek 'Water Bottle' di karakter
    if waterBottle then
        local remoteEvent = waterBottle:FindFirstChild("RemoteEvent") -- Mencari 'RemoteEvent' di dalam 'Water Bottle'
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireServer() -- Memanggil RemoteEvent untuk memberi tahu server bahwa pemain minum air
            print("Minum air!")
        else
            warn("RemoteEvent tidak ditemukan di Water Bottle.")
        end
    else
        warn("Water Bottle tidak ditemukan di karakter.")
    end
end

-- Fungsi utama yang menjalankan urutan ekspedisi
local function startExpedition()
    print("Memulai ekspedisi...")

    -- Teleportasi awal ke Basecamp Helikopter
    task.wait(5) -- Tunggu 5 detik
    local basecampPart = workspace:FindFirstChild("Search_And_Rescue%") -- Cari folder/model utama
    if basecampPart then
        local helicopterSpawn = basecampPart:FindFirstChild("Helicopter_Spawn_Clickers") -- Cari sub-folder/model
        if helicopterSpawn then
            teleportPlayer(helicopterSpawn:FindFirstChild("Basecamp")) -- Teleportasi ke bagian 'Basecamp'
        else
            warn("Helicopter_Spawn_Clickers tidak ditemukan di Search_And_Rescue%.")
        end
    else
        warn("Search_And_Rescue% tidak ditemukan di workspace.")
    end

    -- Teleportasi ke Camp1
    task.wait(5) -- Tunggu 5 detik
    local campMainTents = workspace:FindFirstChild("Camp_Main_Tents%") -- Cari folder/model utama
    if campMainTents then
        teleportPlayer(campMainTents:FindFirstChild("Camp1")) -- Teleportasi ke bagian 'Camp1'
    else
        warn("Camp_Main_Tents% tidak ditemukan di workspace.")
    end

    -- Teleportasi ke Checkpoint pertama (indeks 264)
    task.wait(5 * 60) -- Tunggu 5 menit
    -- PERHATIAN: Menggunakan indeks GetChildren() tidak disarankan karena urutan dapat berubah.
    -- Disarankan untuk mengganti ini dengan nama bagian yang spesifik, mis. workspace.Checkpoint264
    if #workspace:GetChildren() >= 264 then
        teleportPlayer(workspace:GetChildren()[264])
    else
        warn("Checkpoint dengan indeks 264 tidak ditemukan.")
    end

    -- Teleportasi ke Camp2
    task.wait(5) -- Tunggu 5 detik
    if campMainTents then
        teleportPlayer(campMainTents:FindFirstChild("Camp2"))
    else
        warn("Camp_Main_Tents% tidak ditemukan di workspace.")
    end

    -- Teleportasi ke Checkpoint kedua (indeks 731)
    task.wait(5 * 60) -- Tunggu 5 menit
    if #workspace:GetChildren() >= 731 then
        teleportPlayer(workspace:GetChildren()[731])
    else
        warn("Checkpoint dengan indeks 731 tidak ditemukan.")
    end

    -- Teleportasi ke Camp3
    task.wait(5) -- Tunggu 5 detik
    if campMainTents then
        teleportPlayer(campMainTents:FindFirstChild("Camp3"))
    else
        warn("Camp_Main_Tents% tidak ditemukan di workspace.")
    end

    -- Teleportasi ke Checkpoint ketiga (indeks 550)
    task.wait(5 * 60) -- Tunggu 5 menit
    if #workspace:GetChildren() >= 550 then
        teleportPlayer(workspace:GetChildren()[550])
    else
        warn("Checkpoint dengan indeks 550 tidak ditemukan.")
    end

    -- Teleportasi ke Camp4
    task.wait(5) -- Tunggu 5 detik
    if campMainTents then
        teleportPlayer(campMainTents:FindFirstChild("Camp4"))
    else
        warn("Camp_Main_Tents% tidak ditemukan di workspace.")
    end

    -- Teleportasi ke Checkpoint Camp 4
    task.wait(5 * 60) -- Tunggu 5 menit
    -- PERHATIAN: "workspace.Checkpoint *camp 4*" adalah sintaks yang tidak valid.
    -- Asumsikan ada bagian bernama "Checkpoint_Camp4" atau sejenisnya.
    local checkpointCamp4 = workspace:FindFirstChild("Checkpoint_Camp4") -- Ganti dengan nama bagian yang sebenarnya
    if checkpointCamp4 then
        teleportPlayer(checkpointCamp4)
    else
        warn("Checkpoint Camp 4 tidak ditemukan (pastikan namanya benar).")
    end

    -- Teleportasi ke South Pole SpawnLocation
    task.wait(5 * 60) -- Tunggu 5 menit
    local checkpointsFolder = workspace:FindFirstChild("Checkpoints%")
    if checkpointsFolder then
        local southPoleFolder = checkpointsFolder:FindFirstChild("South Pole")
        if southPoleFolder then
            teleportPlayer(southPoleFolder:FindFirstChild("SpawnLocation"))
        else
            warn("Folder 'South Pole' tidak ditemukan di 'Checkpoints%'.")
        end
    else
        warn("Folder 'Checkpoints%' tidak ditemukan di workspace.")
    end

    -- Loop untuk minum air setiap 7 menit
    -- Menggunakan 'spawn' agar ini berjalan secara paralel dengan urutan teleportasi
    spawn(function()
        while true do
            task.wait(7 * 60) -- Tunggu 7 menit
            drinkWater()
        end
    end)

    -- Jika Anda ingin mengulang seluruh urutan ekspedisi dari awal (nomor 2),
    -- Anda dapat meng-uncomment baris di bawah ini.
    -- while true do
    --     task.wait(10) -- Tunggu sebentar sebelum mengulang
    --     startExpedition()
    -- end
end

-- Memulai ekspedisi ketika karakter pemain dimuat dan ditambahkan ke workspace
-- Ini menangani kasus ketika pemain pertama kali bergabung atau respawn
Character.AncestryChanged:Connect(function()
    if Character.Parent == workspace and HumanoidRootPart.Parent == Character then
        startExpedition()
    end
end)

-- Jika karakter sudah dimuat saat skrip berjalan (misalnya, saat pengujian di Studio)
if Character.Parent == workspace and HumanoidRootPart.Parent == Character then
    startExpedition()
end
