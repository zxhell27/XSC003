-- // Services //
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService") 

-- // UI FRAME (Struktur Asli Dipertahankan) //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn = false

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

local LogFrame = Instance.new("Frame")
LogFrame.Name = "LogFrame"

local LogTitle = Instance.new("TextLabel")
LogTitle.Name = "LogTitle"

local LogOutput = Instance.new("TextLabel")
LogOutput.Name = "LogOutput"

-- Tabel untuk menyimpan referensi elemen input timer
local timerInputElements = {}

-- --- Variabel Kontrol dan State ---
local scriptRunning = true
local autoTeleportActive = false
local autoTeleportThread = nil
local isMinimized = false
local originalFrameHeight = 370 -- Adjusted height: removed one timer input (25px)
local originalFrameWidth = 300
originalFrameSize = UDim2.new(0, originalFrameWidth, 0, originalFrameHeight)
local minimizedFrameSize = UDim2.new(0, 50, 0, 50)
local minimizedElement 

-- Kumpulan elemen yang visibilitasnya akan di-toggle
local elementsToToggleVisibility = {}

-- --- Tabel Konfigurasi Timer ---
local timers = {
    teleport_delay_between_points = 5,
    log_clear_interval = 60,
    teleport_y_offset = 8, 
    water_refill_duration = 2, 
    -- water_drink_interval is now handled specifically by the special sequence (60s)
    water_drink_count = 5, 
    -- jump_at_checkpoint_interval is not used in this specific script
    -- camp_water_refill_interval is not used as refill is tied to drinking at Camp 4
}

-- --- Definisi Titik Teleportasi (Ekspedisi Antartika) ---
local teleportLocations = {
    -- Camp 1
    ["Camp 1 Main Tent"] = CFrame.new(-3694.08691, 225.826172, 277.052979, 0.710165381, 0, 0.704034865, 0, 1, 0, -0.704034865, 0, 0.710165381),
    ["Camp 1 Checkpoint"] = CFrame.new(-3719.18188, 223.203995, 235.391006, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp1"] = CFrame.new(-3718.26001, 228.797501, 264.399994, 1.41859055e-05, 0.998563945, -0.0535728931, 1, -1.43051147e-05, 3.81842256e-07, -3.81842256e-07, -0.0535728931, -0.998564005),
    -- Camp 2
    ["Camp 2 Main Tent"] = CFrame.new(1774.76111, 102.314171, -179.4328, -0.790706277, 0, -0.612195849, 0, 1, 0, 0.612195849, 0, -0.790706277),
    ["Camp 2 Checkpoint"] = CFrame.new(1790.31799, 103.665001, -137.858994, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp2"] = CFrame.new(1800.04199, 105.285774, -163.363998, 7.74860382e-06, 0.142248183, 0.989830971, 1, -7.62939453e-06, -6.67572021e-06, 6.67572021e-06, 0.989830971, -0.142248154),
    -- Camp 3
    ["Camp 3 Main Tent"] = CFrame.new(5853.9834, 325.546478, -0.24318853, 0.494506121, -0, -0.869174123, 0, 1, -0, 0.869174123, 0, 0.494506121),
    ["Camp 3 Checkpoint"] = CFrame.new(5892.38916, 319.35498, -19.0779991, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp3"] = CFrame.new(5884.9502, 321.003143, 6.29623318, 2.13384628e-05, 0.635085583, -0.772441745, 1, -2.13384628e-05, 1.0073185e-05, -1.0073185e-05, -0.772441745, -0.635085583),
    -- Camp 4
    ["Camp 4 Main Tent"] = CFrame.new(8999.26465, 593.866089, 59.4377747, -0.999371052, 0, 0.035472773, 0, 1, 0, -0.035472773, 0, -0.999371052),
    ["Camp 4 Checkpoint"] = CFrame.new(8992.36328, 594.10498, 103.060997, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    ["WaterRefill_Camp4"] = CFrame.new(9000.68652, 597.380127, 85.107872, 2.74181366e-06, -0.18581143, 0.982585371, 1, 2.74181366e-06, -2.2649765e-06, -2.2649765e-06, 0.982585371, 0.18581146),
    -- South Pole
    ["South Pole Checkpoint"] = CFrame.new(10995.2461, 545.255127, 114.804474, 0.819186032, 0.573527873, 3.9935112e-06, -3.9935112e-06, 1.2755394e-05, -1, -0.573527873, 0.819186091, 1.2755394e-05),
    ["South Pole Staging Area"] = CFrame.new(10995.2461, 545.255127, 114.804474 - 50) -- 50 studs before the checkpoint on Z axis
}

local waterDrinkCounter = 0 -- Kept for logging in drinkWater()
local glitchChars = {"@", "#", "$", "%", "&", "*", "!", "?", "/", "\\", "|", "_", "1", "0", "Z", "X", "E"}

local energyHydrationEvent = ReplicatedStorage:WaitForChild("Events", 60):WaitForChild("EnergyHydration", 60)

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
    LogFrame.Parent = Frame
    LogTitle.Parent = LogFrame
    LogOutput.Parent = LogFrame
end
setupCoreGuiParenting()

-- // Desain UI //
Frame.Size = originalFrameSize
Frame.Position = UDim2.new(0.5, -Frame.Size.X.Offset/2, 0.5, -Frame.Size.Y.Offset/2)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.Active = true
Frame.Draggable = true
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
Frame.ClipsDescendants = false
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

UiTitleLabel.Size = UDim2.new(1, -20, 0, 35)
UiTitleLabel.Position = UDim2.new(0, 10, 0, 10)
UiTitleLabel.Font = Enum.Font.SourceSansSemibold
UiTitleLabel.Text = "ANTARCTIC TELEPORT"
UiTitleLabel.TextColor3 = Color3.fromRGB(255, 25, 25)
UiTitleLabel.TextScaled = false
UiTitleLabel.TextSize = 24
UiTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
UiTitleLabel.BackgroundTransparency = 1
UiTitleLabel.ZIndex = 2
UiTitleLabel.TextStrokeTransparency = 0.5
UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)

local yOffsetForTitle = 50

StartAutoTeleportButton.Size = UDim2.new(1, -40, 0, 35)
StartAutoTeleportButton.Position = UDim2.new(0, 20, 0, yOffsetForTitle)
StartAutoTeleportButton.Text = "START SOUTH POLE SEQUENCE" -- Changed button text
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

TimerTitleLabel.Size = UDim2.new(1, -40, 0, 20)
TimerTitleLabel.Position = UDim2.new(0, 20, 0, yOffsetForTimers)
TimerTitleLabel.Text = "// SEQUENCE SETTINGS" -- Changed title
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
timerInputElements.teleportDelayBetweenPointsInput = createTimerInput("TeleportDelayBetweenPoints", currentYConfig, "Delay Between Points", timers.teleport_delay_between_points)
currentYConfig = currentYConfig + 25
timerInputElements.waterRefillDurationInput = createTimerInput("WaterRefillDuration", currentYConfig, "Water Refill Duration", timers.water_refill_duration)
currentYConfig = currentYConfig + 25
-- WaterDrinkInterval input removed
timerInputElements.waterDrinkCountInput = createTimerInput("WaterDrinkCount", currentYConfig, "Water Drink Count", timers.water_drink_count)
currentYConfig = currentYConfig + 35 -- Adjusted offset as one input was removed

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

local yOffsetForLog = currentYConfig + yOffsetForTimers + 40

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
LogTitle.TextColor3 = Color3.fromRGB(255, 200, 80)
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

MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Position = UDim2.new(1, -35, 0, 10)
MinimizeButton.Text = "_"
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

minimizedElement = Instance.new("TextButton")
minimizedElement.Name = "MinimizedElementButton"
minimizedElement.Parent = Frame
minimizedElement.Size = UDim2.new(1, 0, 1, 0)
minimizedElement.Position = UDim2.new(0,0,0,0)
minimizedElement.Text = "Z"
minimizedElement.Font = Enum.Font.SourceSansBold
minimizedElement.TextScaled = false
minimizedElement.TextSize = 38
minimizedElement.TextColor3 = Color3.fromRGB(255, 0, 0)
minimizedElement.TextXAlignment = Enum.TextXAlignment.Center
minimizedElement.TextYAlignment = Enum.TextYAlignment.Center
minimizedElement.BackgroundColor3 = Color3.fromRGB(15,15,20)
minimizedElement.BackgroundTransparency = 0
minimizedElement.BorderColor3 = Color3.fromRGB(255,0,0)
minimizedElement.BorderSizePixel = 2
minimizedElement.ZIndex = 4
minimizedElement.Visible = false
minimizedElement.AutoButtonColor = false

elementsToToggleVisibility = {
    UiTitleLabel, StartAutoTeleportButton, StatusLabel, TimerTitleLabel, ApplyTimersButton,
    timerInputElements.TeleportDelayBetweenPointsLabel, timerInputElements.teleportDelayBetweenPointsInput,
    timerInputElements.WaterRefillDurationLabel, timerInputElements.WaterRefillDurationInput,
    -- timerInputElements.WaterDrinkIntervalLabel, timerInputElements.WaterDrinkIntervalInput, -- Removed
    timerInputElements.WaterDrinkCountLabel, timerInputElements.WaterDrinkCountInput,
    LogFrame, MinimizeButton
}

-- // Fungsi Bantu UI //
local function updateStatus(text)
    if StatusLabel and StatusLabel.Parent then StatusLabel.Text = "STATUS: " .. string.upper(text) end
    print("Status: " .. text)
end

local function appendLog(text)
    if LogOutput and LogOutput.Parent then
        local currentText = LogOutput.Text
        local newText = text .. "\n" .. currentText
        if #newText > 500 then newText = newText:sub(1, 500) .. "..." end
        LogOutput.Text = newText
    end
    print("Log: " .. text)
end

local function clearLog()
    if LogOutput and LogOutput.Parent then LogOutput.Text = "Log: Cleared." end
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
        for _, element in ipairs(elementsToToggleVisibility) do
            if element and element.Parent then element.Visible = false end
        end
        minimizedElement.Visible = true
        local targetX = 1 - (minimizedFrameSize.X.Offset / ScreenGui.AbsoluteSize.X) - 0.02
        local targetY = 1 - (minimizedFrameSize.Y.Offset / ScreenGui.AbsoluteSize.Y) - 0.02
        local targetPosition = UDim2.new(targetX, 0, targetY, 0)
        animateFrame(minimizedFrameSize, targetPosition)
        Frame.Draggable = true 
        MinimizeButton.Visible = false
    else
        minimizedElement.Visible = false
        MinimizeButton.Text = "_"
        local targetPosition = UDim2.new(0.5, -originalFrameSize.X.Offset/2, 0.5, -originalFrameSize.Y.Offset/2)
        animateFrame(originalFrameSize, targetPosition, function()
            for _, element in ipairs(elementsToToggleVisibility) do
                if element and element.Parent then element.Visible = true end
            end
            Frame.Draggable = true
            MinimizeButton.Visible = true
        end)
    end
end
MinimizeButton.MouseButton1Click:Connect(toggleMinimize)
if minimizedElement:IsA("TextButton") then
    minimizedElement.MouseButton1Click:Connect(toggleMinimize)
end

-- // Fungsi tunggu //
local function waitSeconds(sec)
    if sec <= 0 then task.wait() return end
    local startTime = tick()
    repeat
        RunService.Heartbeat:Wait()
    until not scriptRunning or tick() - startTime >= sec
end

-- Fungsi Teleportasi
local function teleportPlayer(cframeTarget, locationName)
    if not scriptRunning then return false end
    local success, err = pcall(function()
        local char = LocalPlayer.Character
        if not char then 
            appendLog("Teleport Error: Character not found for " .. locationName)
            return 
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if not hrp or not humanoid then
            appendLog("Teleport Error: HumanoidRootPart or Humanoid not found for " .. locationName)
            return
        end

        if humanoid:GetState() == Enum.HumanoidStateType.Dead then
            appendLog("Teleport Error: Player is dead, cannot teleport to " .. locationName)
            return
        end

        if humanoid.Sit then
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            task.wait(0.2) 
        end
        
        if hrp.Anchored then
            hrp.Anchored = false
        end

        char.Archivable = true 
        local originalCollisions = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollisions[part] = {CanCollide = part.CanCollide, CanTouch = part.CanTouch, CanQuery = part.CanQuery}
                part.CanCollide = false
                part.CanTouch = false 
                part.CanQuery = false 
            end
        end

        hrp.CFrame = cframeTarget + Vector3.new(0, timers.teleport_y_offset, 0)
        for _ = 1, 3 do RunService.Heartbeat:Wait() end

        for part, collisionProps in pairs(originalCollisions) do
            if part and part.Parent then 
                part.CanCollide = collisionProps.CanCollide
                part.CanTouch = collisionProps.CanTouch
                part.CanQuery = collisionProps.CanQuery
            end
        end
        char.Archivable = false
        
        task.wait(0.1) 
        if hrp and hrp.Parent then
             hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.5, 0) 
        end
        
        appendLog("Teleported to: " .. locationName)
        updateStatus("Teleported to: " .. locationName)
    end)
    if not success then
        appendLog("Teleport PCall Error to " .. locationName .. ": " .. tostring(err))
        updateStatus("TELEPORT_FAILED")
        return false
    end
    return true
end

-- Fungsi untuk mengisi air (modifikasi mungkin tidak diperlukan jika pemanggilan sudah benar)
local function refillWater(currentCampNameKey) 
    if not scriptRunning or not LocalPlayer or not LocalPlayer.Character then
        appendLog("RefillWater: Script not running or player/character missing.")
        return false
    end

    local campNumberMatch = currentCampNameKey:match("Camp (%d)") -- Expects "Camp X"
    if not campNumberMatch then 
        -- Try matching if only number is passed, e.g. "4" for Camp 4
        if tonumber(currentCampNameKey) then
             campNumberMatch = currentCampNameKey
        else
            appendLog("RefillWater: Could not determine camp number from: " .. currentCampNameKey .. " for refill event.")
            return false
        end
    end

    local campIdForEvent = "Camp" .. campNumberMatch 
    local campIdForLogic = "Camp " .. campNumberMatch 
    local waterRefillLocationName = "WaterRefill_Camp" .. campNumberMatch
    local refillCFrame = teleportLocations[waterRefillLocationName]

    if refillCFrame then
        appendLog("RefillWater: Teleporting to water refill point for " .. campIdForLogic .. " (" .. waterRefillLocationName .. ")")
        if teleportPlayer(refillCFrame, "Water Refill " .. campIdForLogic) then
            updateStatus("Refilling water at " .. campIdForLogic .. "...")
            appendLog("RefillWater: At water point. Waiting " .. timers.water_refill_duration .. "s then firing event.")
            
            waitSeconds(timers.water_refill_duration) 
            
            if not scriptRunning then
                appendLog("RefillWater: Script stopped during wait.")
                return false
            end 
            
            if energyHydrationEvent then
                local args = { "FillBottle", campIdForEvent, "Water" }
                local successCall, errCall = pcall(function()
                    energyHydrationEvent:FireServer(unpack(args))
                end)
                if successCall then
                    appendLog("RefillWater: Fired EnergyHydration event for " .. campIdForEvent)
                else
                    appendLog("RefillWater: ERROR Firing EnergyHydration event for " .. campIdForEvent .. ": " .. tostring(errCall))
                end
            else
                appendLog("RefillWater: ERROR - EnergyHydration RemoteEvent not found!")
            end
            
            appendLog("RefillWater: Water refill process attempted for " .. campIdForLogic)
            return true
        else
            appendLog("RefillWater: Failed to teleport to water refill point for " .. campIdForLogic .. ".")
            return false
        end
    else
        appendLog("RefillWater: Water refill location CFrame not defined for " .. waterRefillLocationName .. ".")
        return false
    end
end

-- Fungsi untuk minum air
local function drinkWater()
    if not scriptRunning or not LocalPlayer or not LocalPlayer.Character then return end
    local waterBottle = LocalPlayer.Character:FindFirstChild("Water Bottle")
    if waterBottle then
        local remoteEvent = waterBottle:FindFirstChild("RemoteEvent") 
        if remoteEvent then
            for i = 1, timers.water_drink_count do
                if not scriptRunning then break end
                remoteEvent:FireServer()
                appendLog("Drinking water (" .. i .. "/" .. timers.water_drink_count .. " times)")
                task.wait(0.5) -- Small delay between sips
            end
            appendLog("Finished drinking water.")
            waterDrinkCounter = waterDrinkCounter + 1 -- Increment after a full drinking session
        else appendLog("RemoteEvent for DRINKING not found in Water Bottle.") end
    else appendLog("Water Bottle not found in character for drinking.") end
end

-- // Fungsi Auto Teleport KHUSUS //
local function specialSouthPoleTeleportCycle()
    local baseCampLocationName = "Camp 1 Main Tent"
    local southPoleStagingLocationName = "South Pole Staging Area"
    local southPoleCheckpointLocationName = "South Pole Checkpoint"
    local camp4NameForRefill = "Camp 4" -- Key to pass to refillWater for Camp 4

    local timeToWaitAtStaging = (13 * 60) + 59 -- 13 menit 59 detik
    local drinkWaterInterval = 60 -- 1 menit
    local timeSinceLastDrink = 0

    -- 1. Teleport ke Basecamp (Camp 1 Main Tent)
    updateStatus("Teleporting to Basecamp: " .. baseCampLocationName)
    if not teleportPlayer(teleportLocations[baseCampLocationName], baseCampLocationName) then
        appendLog("SpecialSequence: Failed to teleport to Basecamp. Halting.")
        updateStatus("FAILED_BASECAMP_TELEPORT")
        return
    end
    appendLog("SpecialSequence: Arrived at Basecamp. Delaying before next step...")
    waitSeconds(timers.teleport_delay_between_points)
    if not autoTeleportActive or not scriptRunning then return end

    -- 2. Teleport ke South Pole Staging Area
    updateStatus("Teleporting to: " .. southPoleStagingLocationName)
    if not teleportPlayer(teleportLocations[southPoleStagingLocationName], southPoleStagingLocationName) then
        appendLog("SpecialSequence: Failed to teleport to South Pole Staging Area. Halting.")
        updateStatus("FAILED_STAGING_TELEPORT")
        return
    end
    appendLog("SpecialSequence: Arrived at South Pole Staging Area.")
    
    local currentStagingWaitTime = 0
    timeSinceLastDrink = 0 -- Reset drink timer upon arrival at staging

    appendLog("SpecialSequence: Waiting at Staging Area for " .. timeToWaitAtStaging .. "s. Drinking every " .. drinkWaterInterval .. "s.")

    while currentStagingWaitTime < timeToWaitAtStaging and autoTeleportActive and scriptRunning do
        local loopIterationWait = 1 
        waitSeconds(loopIterationWait) 
        if not autoTeleportActive or not scriptRunning then break end -- Check again after wait

        currentStagingWaitTime = currentStagingWaitTime + loopIterationWait
        timeSinceLastDrink = timeSinceLastDrink + loopIterationWait

        local remainingStagingTime = timeToWaitAtStaging - currentStagingWaitTime
        local nextDrinkIn = drinkWaterInterval - (timeSinceLastDrink % drinkWaterInterval)
        if timeSinceLastDrink >= drinkWaterInterval then nextDrinkIn = 0 end -- If it's time, show 0

        updateStatus(string.format("STAGING: %ds left. Next Drink: %ds", math.floor(remainingStagingTime), math.floor(nextDrinkIn)))

        if timeSinceLastDrink >= drinkWaterInterval then
            appendLog("SpecialSequence: Time to drink water at Staging Area.")
            
            local playerCurrentCFrame = nil
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                playerCurrentCFrame = char.HumanoidRootPart.CFrame
            else
                appendLog("SpecialSequence: Cannot get player CFrame before drinking. Will not be able to return accurately.")
            end

            drinkWater() 
            
            if not autoTeleportActive or not scriptRunning then break end 

            appendLog("SpecialSequence: Attempting to refill water at Camp 4.")
            if refillWater(camp4NameForRefill) then 
                appendLog("SpecialSequence: Water refill at Camp 4 attempted.")
            else
                appendLog("SpecialSequence: Water refill at Camp 4 failed or was skipped.")
            end

            if not autoTeleportActive or not scriptRunning then break end

            if playerCurrentCFrame then
                appendLog("SpecialSequence: Returning to Staging Area after water routine.")
                if not teleportPlayer(playerCurrentCFrame, "Return to " .. southPoleStagingLocationName .. " (after water)") then
                    appendLog("SpecialSequence: Failed to return to Staging Area. Trying direct teleport.")
                    teleportPlayer(teleportLocations[southPoleStagingLocationName], southPoleStagingLocationName .. " (Fallback Return)")
                end
            else
                 appendLog("SpecialSequence: No saved CFrame, attempting direct teleport to Staging Area.")
                 teleportPlayer(teleportLocations[southPoleStagingLocationName], southPoleStagingLocationName .. " (Fallback Return No CFrame)")
            end
            timeSinceLastDrink = 0 
        end
    end

    if not autoTeleportActive or not scriptRunning then
        updateStatus("SEQUENCE_STOPPED_STAGING")
        appendLog("SpecialSequence: Halted during staging wait.")
        return
    end

    -- 3. Teleport ke South Pole Checkpoint
    appendLog("SpecialSequence: Staging wait complete. Teleporting to " .. southPoleCheckpointLocationName)
    updateStatus("Teleporting to: " .. southPoleCheckpointLocationName)
    if teleportPlayer(teleportLocations[southPoleCheckpointLocationName], southPoleCheckpointLocationName) then
        updateStatus("ARRIVED_SOUTH_POLE_CP")
        appendLog("SpecialSequence: Successfully arrived at " .. southPoleCheckpointLocationName .. ". Sequence complete.")
    else
        updateStatus("FAILED_SOUTH_POLE_CP_TELEPORT")
        appendLog("SpecialSequence: Failed to teleport to " .. southPoleCheckpointLocationName)
    end
    
    autoTeleportActive = false 
    StartAutoTeleportButton.Text = "START SOUTH POLE SEQUENCE"
    StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    StartAutoTeleportButton.TextColor3 = Color3.fromRGB(220,220,220)
    updateStatus("SEQUENCE_COMPLETE")
end


-- // Tombol Start/Stop Auto Teleport //
StartAutoTeleportButton.MouseButton1Click:Connect(function()
    if not scriptRunning then return end
    autoTeleportActive = not autoTeleportActive
    if autoTeleportActive then
        StartAutoTeleportButton.Text = "STOP SEQUENCE"
        StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
        StartAutoTeleportButton.TextColor3 = Color3.fromRGB(255,255,255)
        updateStatus("SOUTH_POLE_SEQUENCE_ACTIVE")
        appendLog("South Pole sequence started.")
        if not autoTeleportThread or coroutine.status(autoTeleportThread) == "dead" then
            autoTeleportThread = task.spawn(specialSouthPoleTeleportCycle) -- Memanggil fungsi baru
        end
    else
        StartAutoTeleportButton.Text = "START SOUTH POLE SEQUENCE"
        StartAutoTeleportButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        StartAutoTeleportButton.TextColor3 = Color3.fromRGB(220,220,220)
        updateStatus("HALT_REQUESTED")
        appendLog("South Pole sequence halt requested.")
    end
end)

-- // Tombol Apply Timers //
ApplyTimersButton.MouseButton1Click:Connect(function()
    if not scriptRunning then return end
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
    allTimersValid = applyTextInput(timerInputElements.teleportDelayBetweenPointsInput, "teleport_delay_between_points", timerInputElements.TeleportDelayBetweenPointsLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.waterRefillDurationInput, "water_refill_duration", timerInputElements.WaterRefillDurationLabel) and allTimersValid
    -- WaterDrinkInterval input is removed from UI, so no longer applying it here
    allTimersValid = applyTextInput(timerInputElements.waterDrinkCountInput, "water_drink_count", timerInputElements.WaterDrinkCountLabel) and allTimersValid

    local originalStatus = StatusLabel.Text:gsub("STATUS: ", "")
    if allTimersValid then updateStatus("SETTINGS_APPLIED") else updateStatus("ERR_INVALID_INPUT") end
    appendLog("Attempted to apply settings. Valid: " .. tostring(allTimersValid))
    task.delay(2, function()
        if not scriptRunning then return end
        if timerInputElements.TeleportDelayBetweenPointsLabel then pcall(function() timerInputElements.TeleportDelayBetweenPointsLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
        if timerInputElements.WaterRefillDurationLabel then pcall(function() timerInputElements.WaterRefillDurationLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
        -- WaterDrinkIntervalLabel is removed
        if timerInputElements.WaterDrinkCountLabel then pcall(function() timerInputElements.WaterDrinkCountLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
        updateStatus(originalStatus)
    end)
end)

-- // Log Clearing Loop //
task.spawn(function()
    while scriptRunning do
        task.wait(timers.log_clear_interval)
        if scriptRunning then clearLog() end
    end
end)

-- // Global Water Drink Timer Loop (Dihapus karena logika minum terintegrasi ke siklus khusus) //
--[[
task.spawn(function()
    while scriptRunning do
        waitSeconds(1)
        if not scriptRunning then break end
        -- Logika minum global dipindahkan/dihapus
    end
end)
--]]

-- --- ANIMASI UI (Sama seperti sebelumnya, tidak ada perubahan di sini) ---
task.spawn(function() 
    if not Frame or not Frame.Parent then return end
    local baseColor = Frame.BackgroundColor3
    local borderBase = Frame.BorderColor3
    local borderThicknessBase = Frame.BorderSizePixel
    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if not isMinimized then
            local r = math.random()
            if r < 0.05 then 
                Frame.BackgroundColor3 = Color3.fromRGB(math.random(10,30),math.random(10,30),math.random(15,35))
                Frame.BorderColor3 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
                Frame.BorderSizePixel = math.random(3, 6)
                Frame.Position = Frame.Position + UDim2.fromOffset(math.random(-2,2), math.random(-2,2))
                task.wait(0.03)
                Frame.BackgroundColor3 = Color3.fromRGB(math.random(5,25),math.random(5,25),math.random(10,30))
                Frame.BorderColor3 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
                Frame.BorderSizePixel = math.random(1, 4)
                Frame.Position = UDim2.new(0.5, -Frame.Size.X.Offset/2, 0.5, -Frame.Size.Y.Offset/2) 
                task.wait(0.03)
            elseif r < 0.2 then 
                Frame.BorderColor3 = Color3.Lerp(borderBase, Color3.fromRGB(0,255,255), math.random()*0.7)
                Frame.BorderSizePixel = math.random(borderThicknessBase -1, borderThicknessBase + 1)
                task.wait(0.05)
            end
            Frame.BackgroundColor3 = baseColor
            local h,s,v = Color3.toHSV(Frame.BorderColor3)
            Frame.BorderColor3 = Color3.fromHSV((h + 0.008)%1, 1, 1) 
            Frame.BorderSizePixel = borderThicknessBase
        else 
            task.wait(0.1) 
        end
        task.wait(0.04)
    end
end)

task.spawn(function() 
    if not UiTitleLabel or not UiTitleLabel.Parent then return end
    local originalText1 = "ANTARCTIC TELEPORT"
    local originalText2 = "ZEDLIST X ZXHELL"
    local currentTargetText = originalText1
    local baseColor = Color3.fromRGB(255, 25, 25)
    local originalPos = UiTitleLabel.Position
    local transitionTime = 1.5
    local displayTime = 5
    local function applyGlitchToText(text)
        local newText = ""
        for i = 1, #text do
            if math.random() < 0.7 then newText = newText .. glitchChars[math.random(#glitchChars)]
            else newText = newText .. text:sub(i,i) end
        end
        return newText
    end
    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if not isMinimized then
            local startTime = tick()
            while tick() - startTime < transitionTime and scriptRunning do
                local progress = (tick() - startTime) / transitionTime
                local mixedText = ""
                local textToGlitch = (currentTargetText == originalText1) and originalText2 or originalText1
                for i = 1, math.max(#currentTargetText, #textToGlitch) do
                    local char1 = currentTargetText:sub(i,i)
                    local char2 = textToGlitch:sub(i,i)
                    if math.random() < progress then mixedText = mixedText .. (char2 ~= "" and char2 or glitchChars[math.random(#glitchChars)])
                    else mixedText = mixedText .. (char1 ~= "" and char1 or glitchChars[math.random(#glitchChars)]) end
                end
                UiTitleLabel.Text = applyGlitchToText(mixedText)
                UiTitleLabel.TextColor3 = Color3.fromHSV(math.random(), 1, 1)
                UiTitleLabel.Position = originalPos + UDim2.fromOffset(math.random(-2,2), math.random(-2,2))
                UiTitleLabel.Rotation = math.random(-1,1) * 0.5
                task.wait(0.05)
            end
            if not scriptRunning then break end
            UiTitleLabel.Text = currentTargetText
            local hue = (tick()*0.1) % 1
            local r_rgb, g_rgb, b_rgb = Color3.fromHSV(hue, 1, 1).R, Color3.fromHSV(hue, 1, 1).G, Color3.fromHSV(hue, 1, 1).B
            r_rgb = math.min(1, r_rgb + 0.6); g_rgb = g_rgb * 0.4; b_rgb = b_rgb * 0.4
            UiTitleLabel.TextColor3 = Color3.new(r_rgb, g_rgb, b_rgb)
            UiTitleLabel.TextStrokeTransparency = 0.5
            UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)
            UiTitleLabel.Position = originalPos
            UiTitleLabel.Rotation = 0
            waitSeconds(displayTime)
            if not scriptRunning then break end
            if currentTargetText == originalText1 then currentTargetText = originalText2 else currentTargetText = originalText1 end
        else
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

task.spawn(function() 
    local buttonsToAnimate = {StartAutoTeleportButton, ApplyTimersButton, MinimizeButton} 
    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if not isMinimized then
            for _, btn in ipairs(buttonsToAnimate) do
                if btn and btn.Parent and btn.Visible then
                    local originalBorder = btn.BorderColor3
                    if btn.Name == "StartAutoTeleportButton" and autoTeleportActive then
                        btn.BorderColor3 = Color3.fromRGB(255,100,100)
                    else
                        local h,s,v = Color3.toHSV(originalBorder)
                        btn.BorderColor3 = Color3.fromHSV(h,s, math.sin(tick()*2)*0.1 + 0.9)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function() 
    local originalZText = "Z"
    while ScreenGui and ScreenGui.Parent and scriptRunning do
        if isMinimized and minimizedElement and minimizedElement.Visible then
            local r = math.random()
            if r < 0.3 then 
                minimizedElement.Text = glitchChars[math.random(#glitchChars)]
                minimizedElement.TextColor3 = Color3.fromHSV(math.random(), 1, 1)
                minimizedElement.BorderColor3 = Color3.fromHSV(math.random(), 1, 1)
                minimizedElement.BorderSizePixel = math.random(1,4)
                minimizedElement.Rotation = math.random(-7,7) 
                Frame.BorderSizePixel = math.random(2,5)
                Frame.BorderColor3 = minimizedElement.BorderColor3 
                task.wait(0.03 + math.random()*0.03) 
                minimizedElement.Text = originalZText 
                minimizedElement.TextColor3 = Color3.fromHSV(math.random(), 1, 1)
                minimizedElement.BorderColor3 = Color3.fromHSV(math.random(), 1, 1)
                minimizedElement.BorderSizePixel = math.random(2,3)
                minimizedElement.Rotation = math.random(-4,4)
                Frame.BorderSizePixel = 2 
                Frame.BorderColor3 = minimizedElement.BorderColor3 
                task.wait(0.04 + math.random()*0.03)
            else 
                minimizedElement.Text = originalZText
                local hue = (tick() * 0.3) % 1
                minimizedElement.TextColor3 = Color3.fromHSV(hue, 1, 1)
                minimizedElement.BorderColor3 = Color3.fromHSV((hue + 0.3)%1, 0.8, 1)
                minimizedElement.BorderSizePixel = 2
                minimizedElement.Rotation = 0
                Frame.BorderColor3 = minimizedElement.BorderColor3
                Frame.BorderSizePixel = minimizedElement.BorderSizePixel
            end
        end
        task.wait(0.05)
    end
end)
-- --- END ANIMASI UI ---

-- BindToClose
game:BindToClose(function()
    scriptRunning = false
    autoTeleportActive = false
    if autoTeleportThread and coroutine.status(autoTeleportThread) ~= "dead" then
        appendLog("Waiting for autoTeleportThread to finish...")
        task.wait(1) -- Beri waktu untuk thread selesai
    end
    if ScreenGui and ScreenGui.Parent then
        pcall(function() ScreenGui:Destroy() end)
    end
    print("Pembersihan skrip TeleportUI selesai.")
end)

-- Inisialisasi
appendLog("Skrip Teleportasi KHUSUS Basecamp ke South Pole Dimuat. V7.0 (Specific Sequence).")
task.wait(1)
if StatusLabel and StatusLabel.Parent and StatusLabel.Text == "" then StatusLabel.Text = "STATUS: STANDBY" end
