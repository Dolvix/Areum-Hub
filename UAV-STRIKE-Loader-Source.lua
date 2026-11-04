-- =========================================================================
-- AREUM HUB LOADER (UAV STRIKE Loader - Mobile & PC Optimized)
-- =========================================================================
local Lversion = "2.289.4"
print(`[ Loader Version: v{Lversion} | Supports UI Library Versions From 2.000.0 ]`)

local env = getfenv(0)

if env.AreumHubExecuted == true then
    warn("[Areum Hub] Hub is already running!")
    return
end
env.AreumHubExecuted = true

local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

-- =========================================================================
-- CONFIGURATION MANAGER (Crash-Proof Mobile JSON Workspace Saving)
-- =========================================================================
local CONFIG_FILE = "AreumHub_UAV_STRIKE.json"

local ConfigManager = {
    Data = {
        CurrentTheme = "Violet",
        ToggleKey = "LeftControl",
        MobileButton = false,
        FetchVersions = false,
        PlayerEsp = false,
        DronesEsp = false,
        TankEsp = false,
        ShowName = false,
        Traces  = false,
        Fullbright = false,
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
env.SCRIPT_ACTIVE = true
env.UI_TOGGLE_KEY = Enum.KeyCode[ConfigManager.Data.ToggleKey] or Enum.KeyCode.LeftControl
env.STOP_KEY = Enum.KeyCode.F1

-- Configs
env.CURRENT_THEME = ConfigManager.Data.CurrentTheme
env.MOBILE_BUTTON = ConfigManager.Data.MobileButton
env.FETCHVERSIONS = ConfigManager.Data.FetchVersions

-- Visuals
env.PLAYERESP = ConfigManager.Data.PlayerEsp
env.DRONESESP = ConfigManager.Data.DronesEsp
env.TANKESP = ConfigManager.Data.TankEsp
env.SHOWNAME = ConfigManager.Data.ShowName
env.TRACES = ConfigManager.Data.Traces
env.FULLBRIGHT = ConfigManager.Data.Fullbright

local useless_local = false
local update_shown = false

local UIModuleLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Areum-UI-Library.lua"
local DataLibraryLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/refs/heads/main/Areum-Data-Configs.lua"
local LoaderLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/UAV-STRIKE-Loader-Source.lua"

-- Mobile Floating Button Management
local mobileButtonGui = nil
local onupdate = nil
local TpFunc = nil

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

        local MainTab = Window:CreateTab(" Main", "rbxassetid://8772194322")
        local RemoteTab = Window:CreateTab("Remotes", "rbxassetid://7246622296")
        local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://136474990712998")
        local TeleportsTab = Window:CreateTab("Teleports", "rbxassetid://10629411698")
        local ConfigTab = Window:CreateTab(" Settings", "rbxassetid://18397244060")

        -- Main Tab Controls ------------------------------------------------------------------
        MainTab:CreateSection("Test Tab1 ://")
       
        -- Remote Tab Controls ------------------------------------------------------------------
        RemoteTab:CreateSection("Test Tab2 ://")

        -- Visual Tab Controls ------------------------------------------------------------------
        VisualsTab:CreateSection("Esp Options ://")

        VisualsTab:CreateToggle({
            Name = "Player ESP",
            Default = env.PLAYERESP,
            Callback = function(state)
                env.PLAYERESP = state
                ConfigManager.Data.PlayerEsp = state
                ConfigManager:Save()
            end
        })

        VisualsTab:CreateToggle({
            Name = "Drones ESP",
            Default = env.DRONESESP,
            Callback = function(state)
                env.DRONESESP = state
                ConfigManager.Data.DronesEsp = state
                ConfigManager:Save()
            end
        })

        VisualsTab:CreateToggle({
            Name = "SPAAG ESP",
            Default = env.TANKESP,
            Callback = function(state)
                env.TANKESP = state
                ConfigManager.Data.TankEsp = state
                ConfigManager:Save()
            end
        })

        VisualsTab:CreateSection("Esp Configs ://")

        VisualsTab:CreateToggle({
            Name = "Show Player's Name",
            Default = env.SHOWNAME,
            Callback = function(state)
                env.SHOWNAME = state
                ConfigManager.Data.ShowName = state
                ConfigManager:Save()
            end
        })

        VisualsTab:CreateToggle({
            Name = "Traces",
            Default = env.TRACES,
            Callback = function(state)
                env.TRACES = state
                ConfigManager.Data.Traces = state
                ConfigManager:Save()
            end
        })

        VisualsTab:CreateSection("Visuals ://")

        VisualsTab:CreateToggle({
            Name = "Fullbright",
            Default = env.FULLBRIGHT,
            Callback = function(state)
                env.FULLBRIGHT = state
                ConfigManager.Data.Fullbright = state
                ConfigManager:Save()
            end
        })

        -- Teleports Tab Controls ------------------------------------------------------------------
        TeleportsTab:CreateSection("Teleport Options ://")
        TeleportsTab:CreateDropdown({
            Name = "Teleport To Location",
            Items = {"Bunker", "Military B", "Sea", "Coal P/P", "Oil Storage", "SPAAG", "Town"},
            Default = "Bunker",
            Callback = function(location)
                TpFunc(location)
            end
        })



        -- Config Tab Controls ------------------------------------------------------------------
        ConfigTab:CreateSection("Themes ://")
        ConfigTab:CreateDropdown({
            Name = "Theme",
            Items = {"Violet", "Xmas", "Ocean", "Crimson", "Light"},
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
                        loadstring(game:HttpGet(LoaderLink))()
                    end)
                end)
            end
        })

        ConfigTab:CreateSection("Mobile Options ://")

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

        ConfigTab:CreateSection("Debug Library ://")

        ConfigTab:CreateToggle({
            Name = "Fetch Versions with GitHub",
            Default = env.FETCHVERSIONS,
            Callback = function(state)
                env.FETCHVERSIONS = state
                ConfigManager.Data.FetchVersions = state
                ConfigManager:Save()
            end
        })

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

        onupdate = function(newver: string)
            if update_shown then return end

            update_shown = true
            local UpdateTab = Window:CreateTab("Update!", "rbxassetid://4869184613")

            UpdateTab:CreateSection("Update News ://")

            UpdateTab:CreateToggle({
                Name = `New Version Detected | v.{newver}`,
                Default = useless_local,
                Callback = function(state)
                    useless_local = state
                end
            })

            UpdateTab:CreateButton({
                Name = "Load into New Version | v."..newver,
                Callback = function()
                    if typeof(env.CloseAreumHub) == "function" then
                        task.delay(1,function()
                            local result, err = pcall(function()
                                local AreumUI = loadstring(game:HttpGet(LoaderLink))()
                            end)

                            if err then 
                                warn("[Areum Hub]: Error Received While loading |"..err)
                            end
                        end)
                        env.CloseAreumHub()
                    end
                end
            })

        end

    end)
    
    if not success then
        warn("[Areum Hub] Failed to load UI module: " .. tostring(err))
    end
end)

-- In-Game Stuff

local DronesFolder = workspace.Drones

local ActivePlayerEsps = {}
local ActiveDroneEsps = {}
-- {"Bunker", "Military B", "Coal P/P", "Oil Storage", "SPAAG", "Town"}
local TpPositions = {
    ["Bunker"] = CFrame.new(-271.4104, -28.2847118, -2093.34888, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Military B"] = CFrame.new(-1436.64355, 3.79980755, -1331.41272, 0.0318882465, 6.29213872e-08, -0.999491453, -3.47737341e-08, 1, 6.18439628e-08, 0.999491453, 3.27839551e-08, 0.0318882465),
    ["Coal P/P"] = CFrame.new(533.928833, 2.67540526, -2236.35571, 0.047317028, -7.86532297e-08, -0.99887991, 1.52991653e-09, 1, -7.8668954e-08, 0.99887991, 2.19417817e-09, 0.047317028),
    ["Oil Storage"] = CFrame.new(-430.949951, 2.69993806, -3238.0498, 1, 4.59972433e-08, -5.4533289e-14, -4.59972433e-08, 1, -4.18167474e-08, 5.26098364e-14, 4.18167474e-08, 1),
    ["Sea"] = CFrame.new(-122.399597, 2.80006003, -384.100037, 1, 5.40566703e-08, 3.0156172e-14, -5.40566703e-08, 1, 3.04135064e-08, -2.85121183e-14, -3.04135064e-08, 1),
    ["SPAAG"] = CFrame.new(400.650085, 2.70006013, -1126.84985, 1, -4.32258389e-08, -4.16284811e-14, 4.32258389e-08, 1, 1.00085291e-08, 4.1195854e-14, -1.00085291e-08, 1),
    ["Town"] = CFrame.new(-329.234802, 2.70006013, -2236.25977, 1, -1.55894997e-09, -4.34150506e-15, 1.55894997e-09, 1, -8.44678283e-08, 4.4731865e-15, 8.44678283e-08, 1),
}

-- Other Loops

local function InitESP(player: Player)
    local onChar = player.CharacterAdded:Connect(function(character)

        local highlight = Instance.new("Highlight")
        highlight.Parent = character

        highlight.FillColor = Color3.fromRGB(22, 137, 172)
        highlight.FillTransparency = 0.75
        highlight.OutlineColor = Color3.fromRGB(28, 184, 231)
        highlight.OutlineTransparency = 0

        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        highlight.Enabled = false

        ActivePlayerEsps[player.Name] = highlight

    end)

    local onRem = player.CharacterRemoving:Connect(function(character)
        ActivePlayerEsps[player.Name] = nil
    end)

    Players.PlayerRemoving:Connect(function(player)
        if ActivePlayerEsps[player.Name] then
            onChar:Disconnect()
            onRem:Disconnect()
        end
    end)

end

local function InitDrone(drone: Model)
    local highlight = Instance.new("Highlight")
    highlight.Parent = drone
    highlight.FillColor = Color3.fromRGB(167, 0, 0)
    highlight.FillTransparency = 0.75
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0

    highlight.Enabled = false
    
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    ActiveDroneEsps[drone] = highlight

end

task.spawn(function()

    while task.wait(10) do
        if env.FETCHVERSIONS then
            local GitHub_Version = loadstring(game:HttpGet(DataLibraryLink))()
            if GitHub_Version.Loaders.UAV_StrikeLoader.Lversion ~= Lversion then
                onupdate(GitHub_Version.Loaders.UAV_StrikeLoader.Lversion)
            end
        end
    end
    
end)

task.spawn(function()

    local connectionA0, connectionA1 = nil, nil

    connectionA0 = Players.PlayerAdded:Connect(function()
        if not env.SCRIPT_ACTIVE then connectionA0:Disconnect() return end
        InitESP(player)
    end)

    connectionA1 = Players.PlayerRemoving:Connect(function(player)
        if not env.SCRIPT_ACTIVE then connectionA1:Disconnect() return end
        if ActivePlayerEsps[player.Name] then
            ActivePlayerEsps[player.Name] = nil
        end
    end)
end)

task.spawn(function()
    
    local connectionB0, connectionB1 = nil, nil

    connectionB0 = DronesFolder.ChildAdded:Connect(function(drone: Model)
        if not env.SCRIPT_ACTIVE then connectionB0:Disconnect() return end
        InitDrone(drone)
    end)

    connectionB1 = DronesFolder.ChildRemoved:Connect(function(drone)
        if not env.SCRIPT_ACTIVE then connectionB1:Disconnect() return end
        ActiveDroneEsps[drone] = nil
    end)

end)

task.spawn(function()
    
    TpFunc = function(location)
        
        local characater = player.Character or player.CharacterAdded:Wait()
        local hrp = characater:WaitForChild("HumanoidRootPart")

        if hrp and characater and env.SCRIPT_ACTIVE then
            hrp.CFrame = TpPositions[location]
        end
    end

end)

-- Main Loop
task.spawn(function()
    while env.SCRIPT_ACTIVE and task.wait(0.01) do

        -- FULLBRIGHT -- FULLBRIGHT -- FULLBRIGHT -- FULLBRIGHT -- FULLBRIGHT 

        if env.FULLBRIGHT and env.SCRIPT_ACTIVE then
            Lighting.Ambient = Color3.fromRGB(255,255,255) 
            Lighting.Brightness  = 5 
            Lighting.GlobalShadows = false 
            Lighting.ClockTime = 12 

            Lighting.Atmosphere.Density = 0 
            Lighting.Atmosphere.Offset = 0 

        elseif not env.FULLBRIGHT and env.SCRIPT_ACTIVE then
            Lighting.Ambient = Color3.fromRGB(169, 169, 169) 
            Lighting.GlobalShadows = true

            Lighting.Atmosphere.Density = 0.2
            Lighting.Atmosphere.Offset = 0.25

        end

        -- PLAYER ESP -- PLAYER ESP -- PLAYER ESP  -- PLAYER ESP -- PLAYER ESP 

        for _, esp in pairs(ActivePlayerEsps) do
            esp.Enabled = (env.PLAYERESP and env.SCRIPT_ACTIVE)
        end

        -- DRONES ESP -- DRONES ESP -- DRONES ESP  -- DRONES ESP -- DRONES ESP 

        for _, esp in pairs(ActiveDroneEsps) do
            esp.Enabled = (env.DRONESESP and env.SCRIPT_ACTIVE)
        end


    end
end)

-- Cleanup Routine
local function closeScriptRoutine()
    env.SCRIPT_ACTIVE = false
    env.AreumHubExecuted = false
    env.MOBILE_BUTTON = false
    env.FETCHVERSIONS = false

    -- Visuals
    env.PLAYERESP = false
    env.DRONESESP = false
    env.TANKESP = false
    env.SHOWNAME = false
    env.TRACES = false
    env.FULLBRIGHT = false

    for _, esp in pairs(ActivePlayerEsps) do
        esp.Enabled = false
        esp = nil
    end

    for _, esp in pairs(ActiveDroneEsps) do
        esp.Enabled = false
        esp = nil
    end

    Lighting.Ambient = Color3.fromRGB(169, 169, 169) 
    Lighting.GlobalShadows = true
    Lighting.Atmosphere.Density = 0.2
    Lighting.Atmosphere.Offset = 0.25
    
    setupMobileButton(false)
    
    if env.AreumUI then
        pcall(function() env.AreumUI:Destroy() end)
    end

end
env.CloseAreumHub = closeScriptRoutine

-- Termination Keybind Listener (F1)
local stopInputConn
stopInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == env.STOP_KEY then
        closeScriptRoutine()
        if stopInputConn then stopInputConn:Disconnect() end
    end
end)