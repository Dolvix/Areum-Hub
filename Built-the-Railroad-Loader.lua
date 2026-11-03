-- =========================================================================
-- AREUM HUB LOADER (Built the Railroad Loader - Mobile & PC Optimized)
-- =========================================================================
print("[ Loader Version: 2.405.1 | Supports UI Library Versions From 2.000.0 ]")

local env = getfenv(0)

if env.AreumHubExecuted == true then
    warn("[Areum Hub] Hub is already running!")
    return
end
env.AreumHubExecuted = true

local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- =========================================================================
-- CONFIGURATION MANAGER (Crash-Proof Mobile JSON Workspace Saving)
-- =========================================================================
local CONFIG_FILE = "AreumHub_Config.json"

local ConfigManager = {
    Data = {
        CurrentTheme = "Violet",
        ToggleKey = "LeftControl",
        AutoFarm = false,
        RainbowHighlight = false,
        TrainTp = false,
        CollectLoot = false,
        AutoFix = false,
        MobileButton = false,
    }
}

function ConfigManager:Load()
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" then
            if isfile(CONFIG_FILE) then
                local success, content = pcall(readfile, CONFIG_FILE)
                if success and type(content) == "string" then
                    local successDecode, decoded = pcall(function()
                        return HttpService:JSONDecode(content)
                    end)
                    if successDecode and type(decoded) == "table" then
                        print("[Areum Hub] Configuration loaded successfully from workspace.")
                        for k, v in pairs(decoded) do
                            ConfigManager.Data[k] = v
                        end
                    end
                end
            end
        end
    end)
end

function ConfigManager:Save()
    pcall(function()
        if type(writefile) == "function" then
            local successEncode, encoded = pcall(function()
                return HttpService:JSONEncode(self.Data)
            end)
            if successEncode and type(encoded) == "string" then
                writefile(CONFIG_FILE, encoded)
            end
        end
    end)
end

-- Load config data safely on startup
ConfigManager:Load()

-- Environment Configuration Defaults (Synced with ConfigManager data)
env.AUTO_FARM = ConfigManager.Data.AutoFarm
env.RAINBOW_HIGHLIGHT = ConfigManager.Data.RainbowHighlight
env.SCRIPT_ACTIVE = true
env.UI_TOGGLE_KEY = Enum.KeyCode[ConfigManager.Data.ToggleKey] or Enum.KeyCode.LeftControl
env.STOP_KEY = Enum.KeyCode.F1
env.CURRENT_THEME = ConfigManager.Data.CurrentTheme
env.TRAIN_TP = ConfigManager.Data.TrainTp
env.COLLECT_LOOT = ConfigManager.Data.CollectLoot
env.AUTO_FIX = ConfigManager.Data.AutoFix
env.MOBILE_BUTTON = ConfigManager.Data.MobileButton

local UIModuleLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Areum-UI-Library.lua"

-- Mobile Floating Button Management
local mobileButtonGui = nil

local function setupMobileButton(enabled)
    if enabled then
        if mobileButtonGui then return end
        
        local coreGui = nil
        pcall(function() coreGui = game:GetService("CoreGui") end)
        local parentTarget = coreGui or player:WaitForChild("PlayerGui")
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "AreumHub_MobileButton"
        screenGui.ResetOnSpawn = false
        
        pcall(function()
            if syn and syn.protect_gui then
                syn.protect_gui(screenGui)
                screenGui.Parent = coreGui
            elseif protectgui then
                protectgui(screenGui)
                screenGui.Parent = coreGui
            else
                screenGui.Parent = parentTarget
            end
        end)
        if not screenGui.Parent then
            screenGui.Parent = parentTarget
        end
        
        local btn = Instance.new("ImageButton")
        btn.Name = "ToggleBtn"
        btn.Size = UDim2.new(0, 45, 0, 45)
        btn.Position = UDim2.new(0, 30, 0, 200)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.BorderColor3 = Color3.fromRGB(60, 60, 80)
        btn.BorderSizePixel = 1
        btn.Image = "rbxassetid://18397244060" -- Config tab icon
        btn.ImageColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
        -- Draggable functionality for mobile convenience
        local dragging, dragInput, dragStart, startPos
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = btn.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        btn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        -- Tap / Click to toggle menu visibility
        btn.MouseButton1Click:Connect(function()
            if env.AreumUI then
                pcall(function()
                    env.AreumUI:Toggle()
                end)
            end
        end)
        
        mobileButtonGui = screenGui
    else
        if mobileButtonGui then
            mobileButtonGui:Destroy()
            mobileButtonGui = nil
        end
    end
end

-- Load Universal UI Module asynchronously
task.spawn(function()
    local success, err = pcall(function()
        local AreumUI = loadstring(game:HttpGet(UIModuleLink))()
        
        local Window = AreumUI:CreateWindow({
            Title = "Areum Hub",
            Theme = env.CURRENT_THEME,
            ToggleKey = env.UI_TOGGLE_KEY
        })
        env.AreumUI = Window

        local MainTab = Window:CreateTab("Main", "rbxassetid://140076833387955")
        local ConfigTab = Window:CreateTab("Config", "rbxassetid://18397244060")

        -- Main Tab Controls
        MainTab:CreateSection("Auto Progress Options //")
        MainTab:CreateToggle({
            Name = "Farm Money",
            Default = env.AUTO_FARM,
            Callback = function(state)
                env.AUTO_FARM = state
                ConfigManager.Data.AutoFarm = state
                ConfigManager:Save()
            end
        })

        MainTab:CreateToggle({
            Name = "Auto Ride Train",
            Default = env.TRAIN_TP,
            Callback = function(state)
                env.TRAIN_TP = state
                ConfigManager.Data.TrainTp = state
                ConfigManager:Save()
            end
        })

        MainTab:CreateToggle({
            Name = "Auto Collect Loot",
            Default = env.COLLECT_LOOT,
            Callback = function(state)
                env.COLLECT_LOOT = state
                ConfigManager.Data.CollectLoot = state
                ConfigManager:Save()
            end
        })

        MainTab:CreateToggle({
            Name = "Auto Fix Bridge",
            Default = env.AUTO_FIX,
            Callback = function(state)
                env.AUTO_FIX = state
                ConfigManager.Data.AutoFix = state
                ConfigManager:Save()
            end
        })

        -- Config Tab Controls
        ConfigTab:CreateSection("Themes | Visuals Options //")
        ConfigTab:CreateDropdown({
            Name = "Theme",
            Items = {"Violet", "Blue", "Crimson"},
            Default = env.CURRENT_THEME,
            Callback = function(selectedTheme)
                env.CURRENT_THEME = selectedTheme
                ConfigManager.Data.CurrentTheme = selectedTheme
                ConfigManager:Save()
                
                if typeof(env.CloseAreumHub) == "function" then
                    env.CloseAreumHub()
                end
                
                task.spawn(function()
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Built-the-Railroad-Loader.lua"))()
                    end)
                end)
            end
        })

        ConfigTab:CreateToggle({
            Name = "Rainbow Visuals",
            Default = env.RAINBOW_HIGHLIGHT,
            Callback = function(state)
                env.RAINBOW_HIGHLIGHT = state
                ConfigManager.Data.RainbowHighlight = state
                ConfigManager:Save()
            end
        })

        ConfigTab:CreateSection("Mobile / Layout Options //")
        ConfigTab:CreateToggle({
            Name = "Mobile Button",
            Default = env.MOBILE_BUTTON,
            Callback = function(state)
                env.MOBILE_BUTTON = state
                ConfigManager.Data.MobileButton = state
                ConfigManager:Save()
                setupMobileButton(state)
            end
        })

        ConfigTab:CreateSection("Debug Library")
        ConfigTab:CreateButton({
            Name = "Kill Loader (F1)",
            Callback = function()
                if typeof(env.CloseAreumHub) == "function" then
                    env.CloseAreumHub()
                end
            end
        })

        if env.MOBILE_BUTTON then
            setupMobileButton(true)
        end
    end)
    
    if not success then
        warn("[Areum Hub] Failed to load UI module: " .. tostring(err))
    end
end)

-- Game Automation References
local logs = workspace:WaitForChild("World"):WaitForChild("Yard"):WaitForChild("TimberPile"):WaitForChild("PromptPart")
local prox_collect_logs = logs:WaitForChild("ProximityPrompt")
local loot_fldr = workspace.World.Town.LootSpots
local repair_jobs_fldr = workspace.RepairJobs
local build_remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Place")

local bridge_newest_position = nil
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local train = workspace.World.Train
local seat = train.Carriage2:FindFirstChild("Seat")

local game_state = game:GetService("ReplicatedStorage").GameState
local device_supported = UserInputService.KeyboardEnabled

-- Rainbow Visual Effects Setup
local function createRainbowVisuals(char)
    local root = char:WaitForChild("HumanoidRootPart")
    
    local attachment0 = root:FindFirstChild("RainbowRootAtt0") or Instance.new("Attachment")
    attachment0.Name = "RainbowRootAtt0"
    attachment0.Position = Vector3.new(0, 1, 0)
    attachment0.Parent = root

    local attachment1 = root:FindFirstChild("RainbowRootAtt1") or Instance.new("Attachment")
    attachment1.Name = "RainbowRootAtt1"
    attachment1.Position = Vector3.new(0, -1, 0)
    attachment1.Parent = root

    local trail = root:FindFirstChild("RainbowTrail") or Instance.new("Trail")
    trail.Name = "RainbowTrail"
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Lifetime = 0.8
    trail.LightEmission = 1
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    trail.Enabled = false
    trail.Parent = root

    local highlight = char:FindFirstChild("RainbowHighlight") or Instance.new("Highlight")
    highlight.Name = "RainbowHighlight"
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Parent = char

    return trail, highlight
end

local trail, highlight = createRainbowVisuals(character)

local charAddedConn
charAddedConn = player.CharacterAdded:Connect(function(newChar)
    if not env.SCRIPT_ACTIVE then 
        charAddedConn:Disconnect() 
        return 
    end
    character = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
    trail, highlight = createRainbowVisuals(newChar)
end)

-- Optimized Rainbow Visual Loop
task.spawn(function()
    local hue = 0
    while env.SCRIPT_ACTIVE and task.wait(0.02) do
        hue = (hue + 1) % 360
        local color = Color3.fromHSV(hue / 360, 1, 1)
        if trail and highlight and trail.Parent and highlight.Parent then
            local activeEffects = env.AUTO_FARM and env.RAINBOW_HIGHLIGHT
            trail.Enabled = activeEffects
            highlight.Enabled = activeEffects
            
            if activeEffects then
                trail.Color = ColorSequence.new(color)
                highlight.FillColor = color
                highlight.OutlineColor = color
            end
        end
    end
end)

-- Bridge Tracking Loop
task.spawn(function()
    while env.SCRIPT_ACTIVE and task.wait(0.05) do
        local wayfinding = workspace.Camera:FindFirstChild("Wayfinding")
        if wayfinding then
            local buildHere = wayfinding:FindFirstChild("BUILD HERE")
            if buildHere then
                bridge_newest_position = buildHere.Position
            end
        end
    end
end)

local function getLogAmount()
    if not character or not character:FindFirstChild("CarryStack") then 
        return 0 
    end
    return #character.CarryStack:GetChildren()
end

local function forceAnchor(state)
    if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.Anchored = state
end

local function getLogs()
    if not hrp or not env.SCRIPT_ACTIVE then return end
    
    forceAnchor(false)
    task.wait()
    hrp.Position = logs.Position + Vector3.new(0, 3, 0)
    task.wait()
    
    local startTime = os.clock()
    repeat
        pcall(function() fireproximityprompt(prox_collect_logs) end)
        hrp.Position = logs.Position + Vector3.new(0, 3, 0)
        task.wait(0.1)
    until getLogAmount() > 0 or not env.AUTO_FARM or not env.SCRIPT_ACTIVE or (os.clock() - startTime) > 2.5
    
    forceAnchor(false)
    task.wait(0.1)
end

-- Main Automation Loop
task.spawn(function()
    while env.SCRIPT_ACTIVE and task.wait(0.01) do
        -- AUTO FIX BRIDGE JOBS
        if env.AUTO_FIX and repair_jobs_fldr and env.SCRIPT_ACTIVE then
            pcall(function()
                for _, job in pairs(repair_jobs_fldr:GetChildren()) do
                    if hrp and env.AUTO_FIX and env.SCRIPT_ACTIVE and job:FindFirstChild("Crack") then
                        forceAnchor(false)
                        if job:FindFirstChild("CardAnchor") then
                            hrp.Position = job.CardAnchor.Position + Vector3.new(0, 2, 0)
                        end
                        task.wait(0.1)
                    end
                end
            end)
        end

        -- AUTO FARM MONEY / LOGS
        if env.AUTO_FARM then
            local currentPhase = game_state:GetAttribute("Phase")
            if not currentPhase or currentPhase == "Build" then
                local logAmount = getLogAmount()
                
                if logAmount <= 0 then
                    getLogs()
                    logAmount = getLogAmount()
                end

                if bridge_newest_position and hrp and logAmount > 0 and env.SCRIPT_ACTIVE then
                    forceAnchor(false)
                    task.wait()
                    hrp.Position = bridge_newest_position + Vector3.new(0, 2, 0)
                    task.wait()
                    
                    if device_supported and typeof(keypress) == "function" then
                        keypress(0x45)
                    end

                    local startTime = os.clock()
                    repeat 
                        task.wait(0.05)
                        if not device_supported then 
                            pcall(function() build_remote:FireServer() end)
                        end
                    until getLogAmount() == 0 or not env.AUTO_FARM or not env.SCRIPT_ACTIVE or (os.clock() - startTime) > 0.8
                    
                    if device_supported and typeof(keyrelease) == "function" then
                        keyrelease(0x45)
                    end
                end
            end
        else
            if hrp and hrp.Anchored then
                forceAnchor(false)
            end
        end

        -- TRAIN RIDE TP
        if env.TRAIN_TP and game_state:GetAttribute("Phase") == "Ride" and env.SCRIPT_ACTIVE then
            if hrp and seat then
                forceAnchor(false)
                hrp.Position = seat.Position + Vector3.new(0, 2, 2)
                if character:FindFirstChild("Humanoid") then
                    character.Humanoid.Jump = true
                end
            end
        end

        -- COLLECT LOOT
        if env.COLLECT_LOOT and game_state:GetAttribute("Phase") == "Loot" and env.SCRIPT_ACTIVE then
            if hrp and loot_fldr then
                forceAnchor(false)
                for _, lootspot in pairs(loot_fldr:GetChildren()) do
                    if hrp and env.SCRIPT_ACTIVE and env.COLLECT_LOOT then
                        hrp.Position = lootspot.Position + Vector3.new(0, 2, 0)
                        task.wait(0.1)
                    else
                        break
                    end
                end
            end
        end
    end
end)

-- Cleanup Routine
local function closeScriptRoutine()
    env.SCRIPT_ACTIVE = false
    env.AUTO_FARM = false
    env.RAINBOW_HIGHLIGHT = false
    env.AreumHubExecuted = false
    env.TRAIN_TP = false
    env.COLLECT_LOOT = false
    env.AUTO_FIX = false
    env.MOBILE_BUTTON = false
    
    setupMobileButton(false)

    if device_supported then
        pcall(function() keyrelease(0x45) end)
    end

    if hrp then forceAnchor(false) end
    if trail then trail:Destroy() end
    if highlight then highlight:Destroy() end
    
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local att0 = root:FindFirstChild("RainbowRootAtt0")
        local att1 = root:FindFirstChild("RainbowRootAtt1")
        if att0 then att0:Destroy() end
        if att1 then att1:Destroy() end
    end
    
    if env.AreumUI then
        pcall(function() env.AreumUI:Destroy() end)
    end
    print("[Areum Hub] Successfully unloaded process.")
end
env.CloseAreumHub = closeScriptRoutine

-- Termination Keybind Listener (F1)
local stopInputConn
stopInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == env.STOP_KEY then
        closeScriptRoutine()
        if stopInputConn then stopInputConn:Disconnect() end
        if charAddedConn then charAddedConn:Disconnect() end
    end
end)