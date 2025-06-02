-- // === FUNGSI TELEPORT === //
local function teleportTo(part)
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 5)

    if not part then
        updateStatus("ERR_NO_DEST_PART")
        warn("Teleport error: part tujuan tidak ditemukan.")
        return false
    end

    if not root then
        updateStatus("ERR_NO_HRP")
        warn("Teleport error: HumanoidRootPart tidak ditemukan.")
        return false
    end

    pcall(function()
        root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    end)

    updateStatus("TELEPORT_OK")
    return true
end

-- // === TOMBOL TEST TELEPORT === //
local teleportButton = Instance.new("TextButton")
teleportButton.Name = "TeleportButton"
teleportButton.Parent = Frame
teleportButton.Size = UDim2.new(1, -40, 0, 30)
teleportButton.Position = UDim2.new(0, 20, 0, currentYConfig + yOffsetForTimers + 50)
teleportButton.Text = "TELEPORT TEST"
teleportButton.Font = Enum.Font.SourceSansBold
teleportButton.TextSize = 14
teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportButton.BackgroundColor3 = Color3.fromRGB(80, 80, 20)
teleportButton.BorderColor3 = Color3.fromRGB(255, 255, 80)
teleportButton.ZIndex = 2

local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 5)
teleportCorner.Parent = teleportButton

table.insert(elementsToToggleVisibility, teleportButton)

-- === OBJEK TUJUAN UNTUK TELEPORT TEST === --
-- Ganti sesuai target di dokumen ekspedisi
local testTeleportTarget = workspace:FindFirstChild("Camp_Main_Tents%") and workspace["Camp_Main_Tents%"]:FindFirstChild("Camp1")

-- === AKSI SAAT DITEKAN === --
teleportButton.MouseButton1Click:Connect(function()
    if teleportTo(testTeleportTarget) then
        updateStatus("TELEPORT_OK")
    else
        updateStatus("TELEPORT_FAIL")
    end
end)
