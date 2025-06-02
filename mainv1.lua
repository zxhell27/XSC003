-- Dijalankan melalui LocalScript (misal di StarterPlayerScripts)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Fungsi untuk teleport menggunakan CFrame
local function teleportTo(part)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    if part and rootPart then
        rootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0) -- +3 agar tidak terjebak dalam tanah
    end
end

-- Daftar lokasi sesuai dokumen
local lokasi = {
    workspace["Search_And_Rescue%"].Helicopter_Spawn_Clickers.Basecamp,
    workspace["Camp_Main_Tents%"].Camp1,
    workspace:GetChildren()[264],
    workspace["Camp_Main_Tents%"].Camp2,
    workspace:GetChildren()[731],
    workspace["Camp_Main_Tents%"].Camp3,
    workspace:GetChildren()[550],
    workspace["Camp_Main_Tents%"].Camp4,
    workspace["Checkpoint *camp 4*"],
    workspace["Checkpoints%"]["South Pole"].SpawnLocation
}

-- Fungsi minum air (per 7 menit)
local function minumAir()
    local char = player.Character or player.CharacterAdded:Wait()
    local bottle = char:FindFirstChild("Water Bottle")
    if bottle and bottle:FindFirstChild("RemoteEvent") then
        bottle.RemoteEvent:FireServer()
    end
end

-- Eksekusi utama
coroutine.wrap(function()
    wait(5)
    teleportTo(lokasi[1])

    while true do
        wait(5)
        teleportTo(lokasi[2])
        wait(300)
        teleportTo(lokasi[3])
        wait(5)
        teleportTo(lokasi[4])
        wait(300)
        teleportTo(lokasi[5])
        wait(5)
        teleportTo(lokasi[6])
        wait(300)
        teleportTo(lokasi[7])
        wait(5)
        teleportTo(lokasi[8])
        wait(300)
        teleportTo(lokasi[9])
        wait(300)
        teleportTo(lokasi[10])

        wait(420) -- 7 menit
        minumAir()

        -- ulangi dari Camp1 (lokasi[2])
    end
end)()
