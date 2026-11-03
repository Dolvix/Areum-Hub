-- =========================================================================
-- AREUM HUB LOADER (Built the Railroad Loader.)
-- =========================================================================
print("[ Loader Version: 2.376.5 | Supports UI Library Versions From 2.000.0 ]")

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
-- CONFIGURATION MANAGER (JSON Workspace Saving)
-- =========================================================================
local CONFIG_FILE = "AreumHub_Config.json"

local ConfigManager = {
    Data = {
        CurrentTheme = "Violet",
        ToggleKey = "LeftControl",
        AutoFarm = false,
        RainbowHighlight = false,
        TrainTp = false,
        CollectLoot = false
    }
}

function ConfigManager:Load()
    if isfile and isfile(CONFIG_FILE) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and type(decoded) == "table" then
            print("[Areum Hub] Configuration loaded successfully from workspace.")
            for k, v in pairs(decoded) do
                ConfigManager.Data[k] = v
            end
        end
    end
end

function ConfigManager:Save()
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(self.Data)
    end)
    if success and writefile then
        pcall(function()
            writefile(CONFIG_FILE, encoded)
        end)
    end
end

-- Load config data on startup
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

local UIModuleLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Areum-UI-Library.lua"

-- Load Universal UI Module asynchronously
task.spawn(function()
    local success, err = pcall(function()
        local AreumUI = loadstring(game:HttpGet(UIModuleLink))()
        
        -- Initialize Universal Window & Tabs using the modular API
        local Window = AreumUI:CreateWindow({
            Title = "Areum Hub",
            Theme = env.CURRENT_THEME,
            ToggleKey = env.UI_TOGGLE_KEY
        })
        env.AreumUI = Window -- Store reference for cleanup/reloading

        local MainTab = Window:CreateTab("Main", "rbxassetid://140076833387955")
        local ConfigTab = Window:CreateTab("Config", "rbxassetid://18397244060")

        -- Main Tab Controls
        MainTab:CreateSection("Main Functions")
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
            Name = "Teleport to Train on Finish",
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

        -- Config Tab Controls
        ConfigTab:CreateSection("Theme / Visual")
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
                
                -- Re-launch loader to apply new theme cleanly
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

        ConfigTab:CreateSection("Debug Library")
        ConfigTab:CreateButton({
            Name = "Kill Loader (F1)",
            Callback = function()
                if typeof(env.CloseAreumHub) == "function" then
                    env.CloseAreumHub()
                end
            end
        })
    end)
    
    if not success then
        warn("[Areum Hub] Failed to load UI module: " .. tostring(err))
    end
end)

-- Game Automation References
local logs = workspace:WaitForChild("World"):WaitForChild("Yard"):WaitForChild("TimberPile"):WaitForChild("PromptPart")
local prox_collect_logs = logs:WaitForChild("ProximityPrompt")
local loot_fldr = workspace.World.Town.LootSpots

local bridge_newest_position = nil
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local train = workspace.World.Train
local seat = train.Carriage2:FindFirstChild("Seat")

local game_state = game:GetService("ReplicatedStorage").GameState

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
    
    if env.AUTO_FARM and env.SCRIPT_ACTIVE then 
        forceAnchor(false)
    end
    
    -- Fixed timeout window from 0.1 to 2.5 seconds to ensure logs are fully collected
    local startTime = os.clock()
    repeat
            fireproximityprompt(prox_collect_logs)
            hrp.Position = logs.Position + Vector3.new(0, 3, 0)
            task.wait(0.25)
    until getLogAmount() > 0 or not env.AUTO_FARM or not env.SCRIPT_ACTIVE or (os.clock() - startTime) > 2.5
    
    forceAnchor(false)
    task.wait(0.1)
end

-- Main Automation Loop
-- Main Automation Loop
task.spawn(function()
    while env.SCRIPT_ACTIVE and task.wait(0.01) do
        if env.AUTO_FARM and game_state:GetAttribute("Phase") == "Build" then
            local logAmount = getLogAmount()
            if logAmount <= 0 then
                getLogs()
                logAmount = getLogAmount() -- Refresh count after fetching
            end

            if not bridge_newest_position and env.SCRIPT_ACTIVE then
                if hrp then 
                    forceAnchor(false)
                end
                repeat task.wait(0.02) until bridge_newest_position or not env.AUTO_FARM or not env.SCRIPT_ACTIVE
            end

            if env.AUTO_FARM and bridge_newest_position and hrp and env.SCRIPT_ACTIVE and game_state:GetAttribute("Phase") == "Build" and logAmount > 0 then
                forceAnchor(false)
                task.wait()
                hrp.Position = bridge_newest_position + Vector3.new(0,2,0)
                task.wait()
                
                if env.AUTO_FARM and env.SCRIPT_ACTIVE and game_state:GetAttribute("Phase") == "Build" then 
                    forceAnchor(false) 
                end

                -- Optimized: Press E down once instead of spamming keypress/keyrelease every frame
                if typeof(keypress) == "function" and typeof(keyrelease) == "function" then
                    keypress(0x45)
                end

                local startTime = os.clock()
                repeat 
                    task.wait(0.05)
                    local timePassed = os.clock() - startTime
                until getLogAmount() == 0 or not env.AUTO_FARM or not env.SCRIPT_ACTIVE or timePassed > 0.8 or game_state:GetAttribute("Phase") ~= "Build"
                
                -- Release E once building/drop-off is done
                if typeof(keyrelease) == "function" then
                    keyrelease(0x45)
                end
                
                forceAnchor(false)
            end
        else
            if hrp and hrp.Anchored then
                forceAnchor(false)
            end
        end

        if env.TRAIN_TP and game_state:GetAttribute("Phase") == "Ride" then
            if hrp then
                forceAnchor(false)
            end
            hrp.Position = seat.Position + Vector3.new(0, 2, 2)

            character.Humanoid.Jump = true

        end

        if env.COLLECT_LOOT and game_state:GetAttribute("Phase") == "Loot" then
            if hrp then
                forceAnchor(false)
            end
            for _, lootspot in pairs(loot_fldr:GetChildren()) do
                if hrp then
                    hrp.Position = lootspot.Position + Vector3.new(0, 2, 0)
                    task.wait(0.1)
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
    
    pcall(function() keyrelease(0x45) end)
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