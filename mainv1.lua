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
local stopUpdateQi = false -- Not used in this expedition script, but retained from mainv2
local pauseUpdateQiTemporarily = false -- Not used in this expedition script, but retained from mainv2
local mainCycleThread = nil
local aptitudeMineThread = nil -- Not used in this expedition script, but retained from mainv2
local updateQiThread = nil -- Not used in this expedition script, but retained from mainv2
local waterDrinkThread = nil -- New thread for drinking water

local isMinimized = false
local originalFrameSize = UDim2.new(0, 260, 0, 420) -- Initial UI size, smaller
local minimizedFrameSize = UDim2.new(0, 50, 0, 50) -- 'Z' pop-up size
local minimizedZLabel = Instance.new("TextLabel") -- Special label for 'Z' pop-up

-- Collection of elements whose visibility will be toggled
local elementsToToggleVisibility = {} -- Will be populated after all UI elements are created

-- --- Timer Configuration Table ---
local timers = {
    -- Timers from mainv2 (retained, but not used in this expedition logic)
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

    -- New timers for expedition
    initialWaitBeforeTeleport = 5, -- Wait 5 seconds before first teleport
    teleportWait = 5,             -- Wait 5 seconds after each teleport
    longWaitBeforeCheckpoint = 300, -- Wait 5 minutes (300 seconds) before each checkpoint
    waterDrinkInterval = 420,     -- Drink water every 7 minutes (420 seconds)
    cycleRestartDelay = 2,        -- Small delay before restarting the expedition cycle
}

-- // Parent UI to player //
local function setupCoreGuiParenting()
    local coreGuiService = game:GetService("CoreGui")
    if not ScreenGui.Parent or ScreenGui.Parent ~= coreGuiService then
        ScreenGui.Parent = coreGuiService
    end
    if not Frame.Parent or Frame.Parent ~= ScreenGui then
        Frame.Parent = ScreenGui
    end
    -- Ensure all UI elements are parented here
    UiTitleLabel.Parent = Frame
    StartButton.Parent = Frame
    StatusLabel.Parent = Frame
    MinimizeButton.Parent = Frame
    TimerTitleLabel.Parent = Frame
    ApplyTimersButton.Parent = Frame
    minimizedZLabel.Parent = Frame -- Parent the Z label to the Frame
end

-- Call setupCoreGuiParenting at the beginning
setupCoreGuiParenting()

-- // UI Design //

-- --- Main Frame ---
Frame.Size = originalFrameSize
Frame.Position = UDim2.new(0.5, -Frame.Size.X.Offset/2, 0.5, -Frame.Size.Y.Offset/2) -- Center of screen
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Dark bluish background
Frame.Active = true
Frame.Draggable = true
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Initially red, will be animated
Frame.ClipsDescendants = true -- Important for element entry/exit animations

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10) -- More rounded corners
UICorner.Parent = Frame

-- --- UI Name Label ("ROBLOX EXPEDITION") ---
UiTitleLabel.Size = UDim2.new(1, -20, 0, 35) -- Slightly smaller
UiTitleLabel.Position = UDim2.new(0, 10, 0, 10)
UiTitleLabel.Font = Enum.Font.SourceSansSemibold
UiTitleLabel.Text = "ROBLOX EXPEDITION" -- Changed for expedition
UiTitleLabel.TextColor3 = Color3.fromRGB(255, 25, 25)
UiTitleLabel.TextScaled = false
UiTitleLabel.TextSize = 24 -- Medium font size
UiTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
UiTitleLabel.BackgroundTransparency = 1
UiTitleLabel.ZIndex = 2
UiTitleLabel.TextStrokeTransparency = 0.5
UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)

-- Position of other elements adjusted for new layout
local yOffsetForTitle = 50 -- Distance from top of frame to next element (adjusted)

-- --- Start/Stop Button ---
StartButton.Size = UDim2.new(1, -40, 0, 35) -- Smaller
StartButton.Position = UDim2.new(0, 20, 0, yOffsetForTitle)
StartButton.Text = "START EXPEDITION" -- Changed
StartButton.Font = Enum.Font.SourceSansBold
StartButton.TextSize = 16 -- Medium font size
StartButton.TextColor3 = Color3.fromRGB(220, 220, 220)
StartButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20) -- Dark red
StartButton.BorderSizePixel = 1
StartButton.BorderColor3 = Color3.fromRGB(255, 50, 50)
StartButton.ZIndex = 2

local StartButtonCorner = Instance.new("UICorner")
StartButtonCorner.CornerRadius = UDim.new(0, 5)
StartButtonCorner.Parent = StartButton

-- --- Status Label ---
StatusLabel.Size = UDim2.new(1, -40, 0, 45) -- Smaller
StatusLabel.Position = UDim2.new(0, 20, 0, yOffsetForTitle + 45)
StatusLabel.Text = "STATUS: STANDBY"
StatusLabel.Font = Enum.Font.SourceSansLight
StatusLabel.TextSize = 14 -- Medium font size
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 220) -- Bluish white
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30) -- Dark
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.BorderSizePixel = 0
StatusLabel.ZIndex = 2

local StatusLabelCorner = Instance.new("UICorner")
StatusLabelCorner.CornerRadius = UDim.new(0, 5)
StatusLabelCorner.Parent = StatusLabel

local yOffsetForTimers = yOffsetForTitle + 100 -- Adjusted

-- --- Timer Configuration UI ---
TimerTitleLabel.Size = UDim2.new(1, -40, 0, 20) -- Smaller
TimerTitleLabel.Position = UDim2.new(0, 20, 0, yOffsetForTimers)
TimerTitleLabel.Text = "// EXPEDITION TIMER CONFIGURATION" -- Changed
TimerTitleLabel.Font = Enum.Font.Code
TimerTitleLabel.TextSize = 14 -- Medium font size
TimerTitleLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- Bright red
TimerTitleLabel.BackgroundTransparency = 1
TimerTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TimerTitleLabel.ZIndex = 2

local function createTimerInput(name, yPos, labelText, initialValue)
    local label = Instance.new("TextLabel")
    label.Name = name .. "Label"
    label.Parent = Frame
    label.Size = UDim2.new(0.55, -25, 0, 20) -- Smaller
    label.Position = UDim2.new(0, 20, 0, yPos + yOffsetForTimers)
    label.Text = labelText .. ":"
    label.Font = Enum.Font.SourceSans
    label.TextSize = 12 -- Medium font size
    label.TextColor3 = Color3.fromRGB(180, 180, 200)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 2
    timerInputElements[name .. "Label"] = label

    local input = Instance.new("TextBox")
    input.Name = name .. "Input"
    input.Parent = Frame
    input.Size = UDim2.new(0.45, -25, 0, 20) -- Smaller
    input.Position = UDim2.new(0.55, 5, 0, yPos + yOffsetForTimers)
    input.Text = tostring(initialValue)
    input.PlaceholderText = "sec"
    input.Font = Enum.Font.SourceSansSemibold
    input.TextSize = 12 -- Medium font size
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

local currentYConfig = 30 -- Distance from TimerTitleLabel (adjusted)
-- Initialize timer input values from the timers table (only those relevant for expedition)
timerInputElements.initialWaitInput = createTimerInput("InitialWait", currentYConfig, "INITIAL_WAIT", timers.initialWaitBeforeTeleport)
currentYConfig = currentYConfig + 25
timerInputElements.teleportWaitInput = createTimerInput("TeleportWait", currentYConfig, "TELEPORT_DELAY", timers.teleportWait)
currentYConfig = currentYConfig + 25
timerInputElements.longWaitInput = createTimerInput("LongWait", currentYConfig, "CHECKPOINT_WAIT", timers.longWaitBeforeCheckpoint)
currentYConfig = currentYConfig + 25
timerInputElements.waterDrinkInput = createTimerInput("WaterDrink", currentYConfig, "WATER_DRINK_INTERVAL", timers.waterDrinkInterval)
currentYConfig = currentYConfig + 35 -- Adjusted

ApplyTimersButton.Size = UDim2.new(1, -40, 0, 30) -- Smaller
ApplyTimersButton.Position = UDim2.new(0, 20, 0, currentYConfig + yOffsetForTimers)
ApplyTimersButton.Text = "APPLY_TIMERS"
ApplyTimersButton.Font = Enum.Font.SourceSansBold
ApplyTimersButton.TextSize = 14 -- Medium font size
ApplyTimersButton.TextColor3 = Color3.fromRGB(220, 220, 220)
ApplyTimersButton.BackgroundColor3 = Color3.fromRGB(30, 80, 30) -- Dark green
ApplyTimersButton.BorderColor3 = Color3.fromRGB(80, 255, 80)
ApplyTimersButton.BorderSizePixel = 1
ApplyTimersButton.ZIndex = 2

local ApplyButtonCorner = Instance.new("UICorner")
ApplyButtonCorner.CornerRadius = UDim.new(0, 5)
ApplyButtonCorner.Parent = ApplyTimersButton

-- --- Minimize Button ---
MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Position = UDim2.new(1, -35, 0, 10)
MinimizeButton.Text = "_" -- Minimize symbol
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

-- --- 'Z' Pop-up (New) ---
minimizedZLabel.Size = UDim2.new(1, 0, 1, 0) -- Will fill the entire Frame when minimized
minimizedZLabel.Position = UDim2.new(0,0,0,0)
minimizedZLabel.Text = "Z"
minimizedZLabel.Font = Enum.Font.SourceSansBold
minimizedZLabel.TextScaled = false
minimizedZLabel.TextSize = 40 -- Large size to fill small pop-up
minimizedZLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red
minimizedZLabel.TextXAlignment = Enum.TextXAlignment.Center
minimizedZLabel.TextYAlignment = Enum.TextYAlignment.Center
minimizedZLabel.BackgroundTransparency = 1
minimizedZLabel.ZIndex = 4 -- Ensure it's on top of everything
minimizedZLabel.Visible = false -- Initially hidden

-- Collection of elements whose visibility will be toggled
elementsToToggleVisibility = {
    UiTitleLabel, StartButton, StatusLabel, TimerTitleLabel, ApplyTimersButton,
    timerInputElements.initialWaitLabel, timerInputElements.initialWaitInput,
    timerInputElements.teleportWaitLabel, timerInputElements.teleportWaitInput,
    timerInputElements.longWaitLabel, timerInputElements.longWaitInput,
    timerInputElements.waterDrinkLabel, timerInputElements.waterDrinkInput,
    MinimizeButton -- Include MinimizeButton here to hide it during 'Z' mode
}

-- // UI Helper Functions //
local function updateStatus(text)
    if StatusLabel and StatusLabel.Parent then StatusLabel.Text = "STATUS: " .. string.upper(text) end
end

-- // UI Animation Functions //
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

-- // Minimize/Maximize UI Function //
local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        -- Save original Frame position before changing
        local originalFramePosition = Frame.Position

        -- Hide all elements except Frame and 'Z' label
        for _, element in ipairs(elementsToToggleVisibility) do
            if element and element.Parent then element.Visible = false end
        end
        minimizedZLabel.Visible = true -- Show 'Z'

        -- Calculate target pop-up position in bottom right corner
        local targetX = 1 - (minimizedFrameSize.X.Offset / ScreenGui.AbsoluteSize.X) - 0.02 -- Slightly from right
        local targetY = 1 - (minimizedFrameSize.Y.Offset / ScreenGui.AbsoluteSize.Y) - 0.02 -- Slightly from bottom
        local targetPosition = UDim2.new(targetX, 0, targetY, 0)

        animateFrame(minimizedFrameSize, targetPosition)
        Frame.Draggable = false -- Disable draggable when minimized to prevent shifting
    else
        -- Show minimize button before maximize animation starts
        for _, element in ipairs(elementsToToggleVisibility) do
            if element == MinimizeButton and element.Parent then element.Visible = true end
        end

        minimizedZLabel.Visible = false -- Hide 'Z'
        MinimizeButton.Text = "_" -- Revert to minimize symbol

        -- Reposition to center of screen (use originalFrameSize for correct position)
        local targetPosition = UDim2.new(0.5, -originalFrameSize.X.Offset/2, 0.5, -originalFrameSize.Y.Offset/2)
        animateFrame(originalFrameSize, targetPosition, function()
            -- Show all elements after size animation completes
            for _, element in ipairs(elementsToToggleVisibility) do
                if element and element.Parent then element.Visible = true end
            end
            Frame.Draggable = true -- Re-enable draggable after maximize
        end)
    end
end

MinimizeButton.MouseButton1Click:Connect(toggleMinimize)

-- // Wait Function //
local function waitSeconds(sec)
    if sec <= 0 then task.wait() return end
    local startTime = tick()
    repeat
        task.wait()
    until not scriptRunning or tick() - startTime >= sec
end

-- fireRemoteEnhanced Function (retained from mainv2, not used for this expedition)
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

-- // Function to find part from path string //
-- This will parse strings like 'workspace["Folder%"].Part' or 'workspace.Folder.Part'
local function findPartFromPathString(pathString)
    local currentInstance = game:GetService("Workspace")
    -- Remove "workspace" prefix if present, and handle leading/trailing spaces/dots
    local cleanPath = pathString:gsub("^%s*workspace%s*%.?%s*", ""):gsub("%s*$", "")

    -- Split path into components, handle dot and bracket notation
    local pathComponents = {}
    local cursor = 1
    while cursor <= #cleanPath do
        local char = cleanPath:sub(cursor, cursor)
        if char == '[' then
            -- Handle bracket access, e.g., ["Name%"]
            local closingQuote = cleanPath:find('"', cursor + 2) -- Find closing quote after ["
            local closingBracket = cleanPath:find(']', closingQuote + 1) -- Find closing bracket after quote
            if closingQuote and closingBracket then
                local nameStart = cursor + 2 -- Skip ['"
                local nameEnd = closingQuote - 1 -- Before "]
                local name = cleanPath:sub(nameStart, nameEnd)
                table.insert(pathComponents, name)
                cursor = closingBracket + 1 -- Skip "]
            else
                warn("Malformed path string (unclosed bracket or quote): " .. pathString)
                return nil
            end
        elseif char == '.' then
            -- Skip dot
            cursor = cursor + 1
        else
            -- Handle regular name (alphanumeric, underscore)
            local nextSpecialChar = cleanPath:find('[%.%[]', cursor)
            local name
            if nextSpecialChar then
                name = cleanPath:sub(cursor, nextSpecialChar - 1)
                cursor = nextSpecialChar
            else
                name = cleanPath:sub(cursor)
                cursor = #cleanPath + 1
            end
            table.insert(pathComponents, name)
        end
    end

    for _, name in ipairs(pathComponents) do
        if currentInstance then
            currentInstance = currentInstance:FindFirstChild(name)
        else
            return nil -- Path broken, part not found
        end
    end
    return currentInstance
end

-- // Helper function for expedition //
local function teleportTo(targetPart)
    if not scriptRunning then return false end
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if not character then
        -- Wait until character is loaded if not already present
        character = player.CharacterAdded:Wait()
    end

    if not character then
        warn("Character not found after waiting.")
        updateStatus("ERR: NO_CHARACTER_FOR_TP")
        return false
    end

    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)

    if not humanoidRootPart then
        warn("HumanoidRootPart not found for teleportation.")
        updateStatus("ERR: NO_HRP_FOR_TP")
        return false
    end

    if targetPart and targetPart:IsA("BasePart") then
        updateStatus("TELEPORTING TO: " .. targetPart.Name)
        local success, err = pcall(function()
            -- Common teleportation method: setting CFrame of HumanoidRootPart
            humanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0) -- Add a small Y offset to prevent getting stuck
            -- Optional: Set Velocity to Vector3.new(0,0,0) to prevent movement after teleport
            if character:FindFirstChildOfClass("Humanoid") then
                character:FindFirstChildOfClass("Humanoid").WalkSpeed = 0 -- Stop movement temporarily
                character:FindFirstChildOfClass("Humanoid").JumpPower = 0
            end
        end)
        if not success then
            warn("Failed to teleport: " .. err)
            updateStatus("ERR: TP_FAILED")
            return false
        end
        waitSeconds(timers.teleportWait)
        -- Restore speed after teleport
        if character:FindFirstChildOfClass("Humanoid") then
            character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 -- Default Roblox speed
            character:FindFirstChildOfClass("Humanoid").JumpPower = 50 -- Default Roblox JumpPower
        end
        return true
    else
        warn("Invalid or not found teleport target: " .. tostring(targetPart))
        updateStatus("ERR: INVALID_TP_TARGET")
        return false
    end
end

local function drinkWater()
    if not scriptRunning then return false end
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if not character then return false end -- Character might not be loaded or lost

    updateStatus("DRINKING WATER...")
    local waterBottle = character:FindFirstChild("Water Bottle")
    if waterBottle then
        local remoteEvent = waterBottle:FindFirstChild("RemoteEvent")
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            local success, err = pcall(function()
                remoteEvent:FireServer()
            end)
            if not success then
                warn("Failed to call Water Bottle RemoteEvent: " .. err)
                updateStatus("ERR: WATER_FIRE_FAIL")
            end
            return success
        else
            warn("RemoteEvent not found in Water Bottle.")
            updateStatus("ERR: NO_WATER_RE")
            return false
        end
    else
        warn("Water Bottle not found in character.")
        updateStatus("ERR: NO_WATER_BOTTLE")
        return false
    end
end

-- // Main expedition function //
local function runExpeditionCycle()
    updateStatus("STARTING EXPEDITION...")

    -- --- Repeating Expedition Cycle (Starts from "number 2" of the Script Flow) ---
    while scriptRunning do
        -- Step 2: Wait 5 seconds then teleport to Camp1
        -- Script Flow: Wait 5 seconds then teleport to here: workspace["Camp_Main_Tents%"].Camp1
        if not scriptRunning then break end
        updateStatus("WAIT 5S, TP TO CAMP1...")
        waitSeconds(timers.teleportWait)
        local camp1Part = findPartFromPathString('workspace["Camp_Main_Tents%"].Camp1')
        if not teleportTo(camp1Part) then break end

        -- Step 3: Wait 5 minutes then teleport to this checkpoint: Checkpoint Camp 1
        -- Script Flow: Wait 5 minutes then teleport to this checkpoint: workspace:GetChildren()[264]
        -- Using the more specific path from the bottom of the script flow: workspace["Checkpoints%"]["Camp 1"].SpawnLocation
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT CAMP1...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpointCamp1 = findPartFromPathString('workspace["Checkpoints%"]["Camp 1"].SpawnLocation')
        if not teleportTo(checkpointCamp1) then break end

        -- Step 4: If checkpoint reached then wait 5 seconds then teleport here: Camp2
        -- Script Flow: If checkpoint reached then wait 5 seconds then teleport here: workspace["Camp_Main_Tents%"].Camp2
        if not scriptRunning then break end
        updateStatus("CHECKPOINT CAMP1 REACHED, TP TO CAMP2...")
        waitSeconds(timers.teleportWait)
        local camp2Part = findPartFromPathString('workspace["Camp_Main_Tents%"].Camp2')
        if not teleportTo(camp2Part) then break end

        -- Step 5: Wait 5 minutes then teleport to this checkpoint: Checkpoint Camp 2
        -- Script Flow: Wait 5 minutes then teleport to this checkpoint: workspace:GetChildren()[731]
        -- Using the more specific path from the bottom of the script flow: workspace["Checkpoints%"]["Camp 2"].SpawnLocation
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT CAMP2...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpointCamp2 = findPartFromPathString('workspace["Checkpoints%"]["Camp 2"].SpawnLocation')
        if not teleportTo(checkpointCamp2) then break end

        -- Step 6: If checkpoint reached then wait 5 seconds then teleport here: Camp3
        -- Script Flow: If checkpoint reached then wait 5 seconds then teleport here: workspace["Camp_Main_Tents%"].Camp3
        if not scriptRunning then break end
        updateStatus("CHECKPOINT CAMP2 REACHED, TP TO CAMP3...")
        waitSeconds(timers.teleportWait)
        local camp3Part = findPartFromPathString('workspace["Camp_Main_Tents%"].Camp3')
        if not teleportTo(camp3Part) then break end

        -- Step 7: Wait 5 minutes then teleport to this checkpoint: Checkpoint Camp 3
        -- Script Flow: Wait 5 minutes then teleport to this checkpoint: workspace:GetChildren()[550]
        -- Using the more specific path from the bottom of the script flow: workspace["Checkpoints%"]["Camp 3"].SpawnLocation
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT CAMP3...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpointCamp3 = findPartFromPathString('workspace["Checkpoints%"]["Camp 3"].SpawnLocation')
        if not teleportTo(checkpointCamp3) then break end

        -- Step 8: If checkpoint reached then wait 5 seconds then teleport here: Camp4
        -- Script Flow: If checkpoint reached then wait 5 seconds then teleport here: workspace["Camp_Main_Tents%"].Camp4
        if not scriptRunning then break end
        updateStatus("CHECKPOINT CAMP3 REACHED, TP TO CAMP4...")
        waitSeconds(timers.teleportWait)
        local camp4Part = findPartFromPathString('workspace["Camp_Main_Tents%"].Camp4')
        if not teleportTo(camp4Part) then break end

        -- Step 9: Wait 5 minutes then teleport to this checkpoint: Checkpoint Camp 4
        -- Script Flow: Wait 5 minutes then teleport to this checkpoint: workspace.Checkpoint *camp 4*
        -- Using the more specific path from the bottom of the script flow: workspace["Checkpoints%"]["Camp 4"].SpawnLocation
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO CHECKPOINT CAMP4...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local checkpointCamp4 = findPartFromPathString('workspace["Checkpoints%"]["Camp 4"].SpawnLocation')
        if not teleportTo(checkpointCamp4) then break end

        -- Step 10: Wait 5 minutes then teleport to this checkpoint: South Pole SpawnLocation
        -- Script Flow: Wait 5 minutes then teleport to this checkpoint: workspace["Checkpoints%"]["South Pole"].SpawnLocation
        if not scriptRunning then break end
        updateStatus("WAIT 5M, TP TO SOUTH_POLE_SPAWN...")
        waitSeconds(timers.longWaitBeforeCheckpoint)
        local southPoleSpawn = findPartFromPathString('workspace["Checkpoints%"]["South Pole"].SpawnLocation')
        if not teleportTo(southPoleSpawn) then break end

        -- Step 11: Drink water every 7 minutes (handled by separate waterDrinkThread)
        -- This step does not need to be repeated here as there is a dedicated thread.

        updateStatus("EXPEDITION CYCLE COMPLETE. RESTARTING...")
        waitSeconds(timers.cycleRestartDelay) -- Delay before restarting the cycle
    end
end

-- // Background Loops (retained from mainv2, but not used for this expedition) //
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

-- Thread for drinking water (separated to run in parallel)
local function waterDrinkLoop()
    while scriptRunning do
        drinkWater()
        waitSeconds(timers.waterDrinkInterval)
    end
end

-- Start Button
StartButton.MouseButton1Click:Connect(function()
    scriptRunning = not scriptRunning
    if scriptRunning then
        StartButton.Text = "EXPEDITION_ACTIVE" -- Changed
        StartButton.BackgroundColor3 = Color3.fromRGB(200, 30, 30) -- Bright red
        StartButton.TextColor3 = Color3.fromRGB(255,255,255)
        updateStatus("INIT EXPEDITION...")

        -- Removed initial teleport to Basecamp as requested.
        -- The runExpeditionCycle now directly starts with the Camp1 teleport.

        stopUpdateQi = false; pauseUpdateQiTemporarily = false
        -- Threads not used for this expedition (retained from mainv2)
        if not aptitudeMineThread or coroutine.status(aptitudeMineThread) == "dead" then aptitudeMineThread = task.spawn(increaseAptitudeMineLoop_enhanced) end
        if not updateQiThread or coroutine.status(updateQiThread) == "dead" then updateQiThread = task.spawn(updateQiLoop_enhanced) end

        -- Main expedition thread
        if not mainCycleThread or coroutine.status(mainCycleThread) == "dead" then
            mainCycleThread = task.spawn(function()
                runExpeditionCycle() -- Call the main expedition function
                updateStatus("EXPEDITION_HALTED")
                StartButton.Text = "START EXPEDITION"
                StartButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
                StartButton.TextColor3 = Color3.fromRGB(220,220,220)
            end)
        end

        -- Thread for drinking water
        if not waterDrinkThread or coroutine.status(waterDrinkThread) == "dead" then waterDrinkThread = task.spawn(waterDrinkLoop) end

    else
        updateStatus("HALT_REQUESTED")
        -- Stop all threads when the script is halted
        if mainCycleThread and coroutine.status(mainCycleThread) ~= "dead" then task.cancel(mainCycleThread); mainCycleThread = nil end
        if aptitudeMineThread and coroutine.status(aptitudeMineThread) ~= "dead" then task.cancel(aptitudeMineThread); aptitudeMineThread = nil end
        if updateQiThread and coroutine.status(updateQiThread) ~= "dead" then task.cancel(updateQiThread); updateQiThread = nil end
        if waterDrinkThread and coroutine.status(waterDrinkThread) ~= "dead" then task.cancel(waterDrinkThread); waterDrinkThread = nil end
    end
end)

-- Apply Timers Button
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
    -- Only apply timers relevant to the expedition
    allTimersValid = applyTextInput(timerInputElements.initialWaitInput, "initialWaitBeforeTeleport", timerInputElements.InitialWaitLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.teleportWaitInput, "teleportWait", timerInputElements.TeleportWaitLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.longWaitInput, "longWaitBeforeCheckpoint", timerInputElements.LongWaitLabel) and allTimersValid
    allTimersValid = applyTextInput(timerInputElements.waterDrinkInput, "waterDrinkInterval", timerInputElements.WaterDrinkLabel) and allTimersValid

    local originalStatus = StatusLabel.Text:gsub("STATUS: ", "")
    if allTimersValid then updateStatus("TIMER_CONFIG_APPLIED") else updateStatus("ERR_TIMER_INPUT_INVALID") end
    task.wait(2)
    -- Restore label colors after 2 seconds
    if timerInputElements.initialWaitLabel then pcall(function() timerInputElements.initialWaitLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.teleportWaitLabel then pcall(function() timerInputElements.teleportWaitLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.longWaitLabel then pcall(function() timerInputElements.longWaitLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    if timerInputElements.waterDrinkLabel then pcall(function() timerInputElements.waterDrinkLabel.TextColor3 = Color3.fromRGB(180,180,200) end) end
    updateStatus(originalStatus)
end)

-- --- UI ANIMATIONS ---
-- Using task.spawn() to ensure animations run in separate threads.
-- task.spawn() is generally more reliable and recommended than the old spawn().

task.spawn(function() -- Frame Background Animation (Glitchy Background)
    if not Frame or not Frame.Parent then return end
    local baseColor = Color3.fromRGB(15, 15, 20)
    local glitchColor1 = Color3.fromRGB(25, 20, 30)
    local glitchColor2 = Color3.fromRGB(10, 10, 15)
    local borderBase = Color3.fromRGB(255,0,0)
    local borderGlitch = Color3.fromRGB(0,255,255)

    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Only animate when not minimized
            local r = math.random()
            if r < 0.05 then -- Intense glitch
                Frame.BackgroundColor3 = glitchColor1
                Frame.BorderColor3 = borderGlitch
                task.wait(0.05)
                Frame.BackgroundColor3 = glitchColor2
                task.wait(0.05)
            elseif r < 0.2 then -- Light glitch
                Frame.BackgroundColor3 = Color3.Lerp(baseColor, glitchColor1, math.random())
                Frame.BorderColor3 = Color3.Lerp(borderBase, borderGlitch, math.random()*0.5)
                task.wait(0.1)
            else
                Frame.BackgroundColor3 = baseColor
                Frame.BorderColor3 = borderBase
            end
            -- Main border animation (HSV shift)
            local h,s,v = Color3.toHSV(Frame.BorderColor3)
            Frame.BorderColor3 = Color3.fromHSV((h + 0.005)%1, s, v)
        else -- If minimized, ensure colors return to normal for 'Z'
            Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
            Frame.BorderColor3 = Color3.fromRGB(255, 0, 0) -- Or any solid color you want for the pop-up
        end
        task.wait(0.05)
    end
end)

task.spawn(function() -- UiTitleLabel Animation (ZXHELL Glitch)
    if not UiTitleLabel or not UiTitleLabel.Parent then return end
    local originalText = UiTitleLabel.Text
    local glitchChars = {"@", "#", "$", "%", "&", "*", "!", "?", "/", "\\", "|", "_"}
    local baseColor = Color3.fromRGB(255, 25, 25)
    local originalPos = UiTitleLabel.Position

    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Only animate when not minimized
            local r = math.random()
            local isGlitchingText = false

            if r < 0.02 then -- Severe Text & Position Glitch
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
            elseif r < 0.1 then -- Color & Stroke Glitch
                UiTitleLabel.TextColor3 = Color3.fromHSV(math.random(), 1, 1)
                UiTitleLabel.TextStrokeColor3 = Color3.fromHSV(math.random(), 0.8, 1)
                UiTitleLabel.TextStrokeTransparency = math.random() * 0.3
                UiTitleLabel.Rotation = math.random(-1,1) * 0.2
                task.wait(0.1)
            else -- Return to normal or subtle color animation
                UiTitleLabel.Text = originalText
                UiTitleLabel.TextStrokeTransparency = 0.5
                UiTitleLabel.TextStrokeColor3 = Color3.fromRGB(50,0,0)
                UiTitleLabel.Position = originalPos
                UiTitleLabel.Rotation = 0
            end

            -- Subtle RGB color animation if not severely glitching
            if not isGlitchingText then
                local hue = (tick()*0.1) % 1
                local r_rgb, g_rgb, b_rgb = Color3.fromHSV(hue, 1, 1).R, Color3.fromHSV(hue, 1, 1).G, Color3.fromHSV(hue, 1, 1).B
                r_rgb = math.min(1, r_rgb + 0.6) -- Red dominance
                g_rgb = g_rgb * 0.4
                b_rgb = b_rgb * 0.4
                UiTitleLabel.TextColor3 = Color3.new(r_rgb, g_rgb, b_rgb)
            end
        end
        task.wait(0.05)
    end
end)

task.spawn(function() -- Button Animation (Subtle Pulse)
    local buttonsToAnimate = {StartButton, ApplyTimersButton, MinimizeButton}
    while ScreenGui and ScreenGui.Parent do
        if not isMinimized then -- Only animate when not minimized
            for _, btn in ipairs(buttonsToAnimate) do
                if btn and btn.Parent then
                    local originalBorder = btn.BorderColor3

                    -- Simple hover/pulse effect on border
                    if btn.Name == "StartButton" and scriptRunning then
                        btn.BorderColor3 = Color3.fromRGB(255,100,100) -- Brighter red when running
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

task.spawn(function() -- 'Z' Pop-up Animation (RGB Pulse)
    while ScreenGui and ScreenGui.Parent do
        if isMinimized and minimizedZLabel.Visible then
            local hue = (tick() * 0.2) % 1 -- RGB color animation
            minimizedZLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
        end
        task.wait(0.05)
    end
end)
-- --- END UI ANIMATIONS ---

-- BindToClose
game:BindToClose(function()
    if scriptRunning then warn("Game closed, stopping script..."); scriptRunning = false; task.wait(0.5) end
    if ScreenGui and ScreenGui.Parent then pcall(function() ScreenGui:Destroy() end) end
    print("Script cleanup complete.")
end)

-- Initialization
print("Expedition Automation Script Loaded.")
task.wait(1)
if StatusLabel and StatusLabel.Parent and StatusLabel.Text == "" then StatusLabel.Text = "STATUS: STANDBY" end
