local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Fungsi teleport
local function teleportTo(part)
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:MoveTo(part.Position)
	end
end

-- Fungsi minum air
local function minumAir()
	local waterBottle = player.Character:FindFirstChild("Water Bottle")
	if waterBottle then
		local remote = waterBottle:FindFirstChild("RemoteEvent")
		if remote then
			remote:FireServer()
		end
	end
end

-- Daftar lokasi
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

-- Eksekusi teleportasi sesuai urutan
local function startExpedition()
	task.wait(5)
	teleportTo(lokasi[1]) -- Basecamp

	while true do
		task.wait(5)
		teleportTo(lokasi[2]) -- Camp1
		task.wait(300)
		teleportTo(lokasi[3]) -- Checkpoint1
		task.wait(5)
		teleportTo(lokasi[4]) -- Camp2
		task.wait(300)
		teleportTo(lokasi[5]) -- Checkpoint2
		task.wait(5)
		teleportTo(lokasi[6]) -- Camp3
		task.wait(300)
		teleportTo(lokasi[7]) -- Checkpoint3
		task.wait(5)
		teleportTo(lokasi[8]) -- Camp4
		task.wait(300)
		teleportTo(lokasi[9]) -- Checkpoint4
		task.wait(300)
		teleportTo(lokasi[10]) -- South Pole

		task.wait(420) -- 7 menit
		minumAir()

		-- Ulangi dari Camp1
	end
end

-- Mulai skrip
startExpedition()
