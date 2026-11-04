-- =========================================================================
-- AREUM HUB LOADER (UAV STRIKE Loader - Mobile & PC Optimized)
-- =========================================================================
local Lversion = "3.296.5"
print(`[ Loader Version: v{Lversion} | Supports UI Library Versions From 3.000.0 ]`)

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
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

local Instances = Instance.new("Folder", workspace)

-- Check Executor Drawing Library Availability Safely
local HasDrawing = (typeof(Drawing) == "table" and rawget(Drawing, "new") ~= nil) or (typeof(Drawing) == "userdata" or typeof(Drawing) == "function")

local ManuallCall01 

-- =========================================================================
-- CONFIGURATION MANAGER (Crash-Proof Mobile JSON Workspace Saving)
-- =========================================================================
local CONFIG_FILE = "AreumHub_UAV_STRIKE.json"

local ConfigManager = {
    Data = {
        CurrentTheme = "Violet",
        ToggleKey = "LeftControl",
        CustomAssetURL = "",
        MobileButton = false,
        FetchVersions = false,

        PlayerEsp = false,
        DronesEsp = false,
        TankEsp = false,
        Traces  = false,
        Fullbright = false,

        WaterWalking = false,
        DodgeDrones = false,
        DodgeDronesDistance = 200,
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

ConfigManager:Load()

-- Environment Configuration Defaults
env.SCRIPT_ACTIVE = true
env.UI_TOGGLE_KEY = Enum.KeyCode[ConfigManager.Data.ToggleKey] or Enum.KeyCode.LeftControl
env.STOP_KEY = Enum.KeyCode.F1

env.CURRENT_THEME = ConfigManager.Data.CurrentTheme
env.MOBILE_BUTTON = ConfigManager.Data.MobileButton
env.FETCHVERSIONS = ConfigManager.Data.FetchVersions

env.DODGEDRONES = ConfigManager.Data.DodgeDrones
env.DODGEDRONESDISTANCE = ConfigManager.Data.DodgeDronesDistance
env.WATERWALKING = ConfigManager.Data.WaterWalking

env.PLAYERESP = ConfigManager.Data.PlayerEsp
env.DRONESESP = ConfigManager.Data.DronesEsp
env.TANKESP = ConfigManager.Data.TankEsp
env.TRACES = ConfigManager.Data.Traces
env.FULLBRIGHT = ConfigManager.Data.Fullbright

local useless_local = false
local update_shown = false

local UIModuleLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Areum-UI-Library.lua"
local DataLibraryLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/refs/heads/main/Areum-Data-Configs.lua"
local LoaderLink = "https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/UAV-STRIKE-Loader-Source.lua"

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
        btn.Image = "rbxassetid://18397244060"
        btn.ImageColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn
        
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
            ToggleKey = env.UI_TOGGLE_KEY,
            CustomBackground = ConfigManager.Data.CustomAssetURL
        })
        env.AreumUI = Window

        local MainTab = Window:CreateTab(" Main", "rbxassetid://8772194322")
        local RemoteTab = Window:CreateTab("Remotes", "rbxassetid://7246622296")
        local VisualsTab = Window:CreateTab("Visuals", "rbxassetid://136474990712998")
        local TeleportsTab = Window:CreateTab("Teleports", "rbxassetid://10629411698")
        local ConfigTab = Window:CreateTab(" Settings", "rbxassetid://18397244060")
        -- Main Tab 
        MainTab:CreateSection("World ://")

        MainTab:CreateToggle({
            Name = "Water Walking",
            Default = env.WATERWALKING,
            Callback = function(state)
                env.WATERWALKING = state
                ConfigManager.Data.WaterWalking = state
                ManuallCall01()
                ConfigManager:Save()
            end
        })

        MainTab:CreateToggle({
            Name = "Auto Dodge Drones",
            Default = env.DODGEDRONES,
            Callback = function(state)
                env.DODGEDRONES = state
                ConfigManager.Data.DodgeDrones = state
                ConfigManager:Save()
            end
        })

        MainTab:CreateSlider({
            Name = "Drones Dodge Distance",
            Min = 10,
            Max = 500,
            Default = ConfigManager.Data.DodgeDronesDistance,
            Callback = function(val)
                env.DODGEDRONESDISTANCE = val
                ConfigManager.Data.DodgeDronesDistance = val
                ConfigManager:Save()
            end
        })

        -- Remote Tab
        RemoteTab:CreateSection("Test Tab2 ://")

        -- Visual Tab 
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

        -- Teleports Tab Controls
        TeleportsTab:CreateSection("Teleport Options ://")
        TeleportsTab:CreateDropdown({
            Name = "Teleport To Location",
            Items = {"Bunker", "Military B", "Sea", "Coal P/P", "Oil Storage", "SPAAG", "Town"},
            Default = "Bunker",
            Callback = function(location)
                TpFunc(location)
            end
        })

        TeleportsTab:CreateButton({
            Name = "Teleport To Safe Zone",
            Callback = function()
                TpFunc("SafeZone")
            end
        })

        -- Config Tab Controls
        ConfigTab:CreateSection("Theme Customization ://")

        ConfigTab:CreateDropdown({
            Name = "Selected Theme",
            Items = {"Violet", "Xmas", "Ocean", "Crimson", "Noise","Sakura","Void"},
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

        ConfigTab:CreateTextBox({
            Name = "Custom Background ID",
            Placeholder = "rbxassetid://...",
            Default = ConfigManager.Data.CustomAssetURL,
            Callback = function(assetId)
                ConfigManager.Data.CustomAssetURL = assetId
                ConfigManager:Save()

                Window:UpdateBackground(assetId)
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

        ConfigTab:CreateSystemButton({
            Name = "Kill Loader [Press F1]",
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

            UpdateTab:CreateInfoBox({
                Name = "New Version Detected",
                Text = `v.{newver}`
            })

            UpdateTab:CreateButton({
                Name = "Load into New Version",
                Callback = function()
                    if typeof(env.CloseAreumHub) == "function" then
                        task.delay(1,function()
                            pcall(function()
                                loadstring(game:HttpGet(LoaderLink))()
                            end)
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

-- In-Game ESP & Tracer Tracking Containers
local DronesFolder = workspace:FindFirstChild("Drones") or workspace

local ActivePlayerEsps = {}
local ActivePlayerTracers = {}
local ActiveDroneEsps = {}
local ActiveDroneTracers = {}

local SafeZone = Instance.new("Part")
SafeZone.Parent = Instances
SafeZone.Anchored = true
SafeZone.CanCollide = true
SafeZone.CastShadow = false
SafeZone.Size = Vector3.new(60,1,60)
SafeZone.Position = Vector3.new(10000,10000,10000)
SafeZone.TopSurface = Enum.SurfaceType.Studs
SafeZone.BottomSurface = Enum.SurfaceType.Studs

local TpPositions = {
    ["Bunker"] = CFrame.new(-271.4104, -28.2847118, -2093.34888, 1, 0, 0, 0, 1, 0, 0, 0, 1),
    ["Military B"] = CFrame.new(-1436.64355, 3.79980755, -1331.41272, 0.0318882465, 6.29213872e-08, -0.999491453, -3.47737341e-08, 1, 6.18439628e-08, 0.999491453, 3.27839551e-08, 0.0318882465),
    ["Coal P/P"] = CFrame.new(533.928833, 2.67540526, -2236.35571, 0.047317028, -7.86532297e-08, -0.99887991, 1.52991653e-09, 1, -7.8668954e-08, 0.99887991, 2.19417817e-09, 0.047317028),
    ["Oil Storage"] = CFrame.new(-430.949951, 2.69993806, -3238.0498, 1, 4.59972433e-08, -5.4533289e-14, -4.59972433e-08, 1, -4.18167474e-08, 5.26098364e-14, 4.18167474e-08, 1),
    ["Sea"] = CFrame.new(-122.399597, 2.80006003, -384.100037, 1, 5.40566703e-08, 3.0156172e-14, -5.40566703e-08, 1, 3.04135064e-08, -2.85121183e-14, -3.04135064e-08, 1),
    ["SPAAG"] = CFrame.new(400.650085, 2.70006013, -1126.84985, 1, -4.32258389e-08, -4.16284811e-14, 4.32258389e-08, 1, 1.00085291e-08, 4.1195854e-14, -1.00085291e-08, 1),
    ["Town"] = CFrame.new(-329.234802, 2.70006013, -2236.25977, 1, -1.55894997e-09, -4.34150506e-15, 1.55894997e-09, 1, -8.44678283e-08, 4.4731865e-15, 8.44678283e-08, 1),
    ["SafeZone"] = SafeZone.CFrame + CFrame.new(0, 3, 0)
}
    
-- Safe Player Setup
local function InitESP(targetPlayer: Player)
    if targetPlayer == player then return end

    local function setupCharacter(character)
        if ActivePlayerEsps[targetPlayer.Name] then
            pcall(function() ActivePlayerEsps[targetPlayer.Name]:Destroy() end)
        end

        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.FillColor = Color3.fromRGB(22, 137, 172)
        highlight.FillTransparency = 0.75
        highlight.OutlineColor = Color3.fromRGB(28, 184, 231)
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false

        ActivePlayerEsps[targetPlayer.Name] = highlight
    end

    if targetPlayer.Character then
        setupCharacter(targetPlayer.Character)
    end

    targetPlayer.CharacterAdded:Connect(function(character)
        setupCharacter(character)
    end)

    if HasDrawing and not ActivePlayerTracers[targetPlayer.Name] then
        pcall(function()
            local tracer = Drawing.new("Line")
            tracer.Visible = false
            tracer.Color = Color3.fromRGB(28, 184, 231)
            tracer.Thickness = 1.5
            tracer.Transparency = 0.8
            ActivePlayerTracers[targetPlayer.Name] = tracer
        end)
    end
end

-- Safe Drone Setup
local function InitDrone(drone: Model)
    if not drone or not drone:IsA("Model") then return end
    if ActiveDroneEsps[drone] then return end

    local highlight = Instance.new("Highlight")
    highlight.Parent = drone
    highlight.FillColor = Color3.fromRGB(167, 0, 0)
    highlight.FillTransparency = 0.75
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    ActiveDroneEsps[drone] = highlight

    if HasDrawing and not ActiveDroneTracers[drone] then
        pcall(function()
            local tracer = Drawing.new("Line")
            tracer.Visible = false
            tracer.Color = Color3.fromRGB(255, 50, 50)
            tracer.Thickness = 1.5
            tracer.Transparency = 0.8
            ActiveDroneTracers[drone] = tracer
        end)
    end
end

-- Initial Tracking Registrations
for _, p in ipairs(Players:GetPlayers()) do
    InitESP(p)
end

Players.PlayerAdded:Connect(function(p)
    InitESP(p)
end)

Players.PlayerRemoving:Connect(function(p)
    if ActivePlayerEsps[p.Name] then
        pcall(function() ActivePlayerEsps[p.Name]:Destroy() end)
        ActivePlayerEsps[p.Name] = nil
    end
    if ActivePlayerTracers[p.Name] then
        pcall(function() ActivePlayerTracers[p.Name]:Remove() end)
        ActivePlayerTracers[p.Name] = nil
    end
end)

if DronesFolder then
    for _, d in ipairs(DronesFolder:GetChildren()) do
        if d:IsA("Model") then
            InitDrone(d)
        end
    end

    DronesFolder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            InitDrone(child)
        end
    end)

    DronesFolder.ChildRemoved:Connect(function(child)
        if ActiveDroneEsps[child] then
            pcall(function() ActiveDroneEsps[child]:Destroy() end)
            ActiveDroneEsps[child] = nil
        end
        if ActiveDroneTracers[child] then
            pcall(function() ActiveDroneTracers[child]:Remove() end)
            ActiveDroneTracers[child] = nil
        end
    end)
end

task.spawn(function()
    for _, water in pairs(workspace.World.Sea.SeaModels:GetChildren()) do
        local p1 = water.Sea
        if p1 then
            local WaterWalkPart = Instance.new("Part")
            WaterWalkPart.Parent = Instances
            WaterWalkPart.CanCollide = false
            WaterWalkPart.Transparency = 1
            WaterWalkPart.Name = "SafeWater"
            WaterWalkPart.Size = p1.Size
            WaterWalkPart.Position = p1.Position + Vector3.new(0,3,0)
            WaterWalkPart.Anchored = true
            WaterWalkPart.CastShadow = false
        end
    end
end)

ManuallCall01 = function ()
    for _, SafeWater in pairs(Instances:GetChildren()) do
        if SafeWater.Name == "SafeWater" then
            SafeWater.CanCollide = (env.SCRIPT_ACTIVE and env.WATERWALKING)
        end
    end
end

-- 15 Seconds Loop
task.spawn(function()
    while task.wait(15) do
        if env.FETCHVERSIONS then
            local success, GitHub_Version = pcall(function()
                return loadstring(game:HttpGet(DataLibraryLink))()
            end)
            if success and GitHub_Version and GitHub_Version.Loaders.UAV_StrikeLoader.Lversion ~= Lversion then
                onupdate(GitHub_Version.Loaders.UAV_StrikeLoader.Lversion)
            end
        end
    end
end)

TpFunc = function(location)
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

     if hrp and character and env.SCRIPT_ACTIVE then
        hrp.CFrame = TpPositions[location]
     end
end

-- Variables for Auto Dodge Drones Timing & State
local lastDodgeTick = 0
local isDodging = false
local returnCFrame = nil

-- Main RenderStepped Loop
RunService.RenderStepped:Connect(function()
    if not env.SCRIPT_ACTIVE then return end

    -- FULLBRIGHT
    if env.FULLBRIGHT then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255) 
        Lighting.Brightness = 5 
        Lighting.GlobalShadows = false 
        Lighting.ClockTime = 12
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Density = 0 
            Lighting.Atmosphere.Offset = 0 
        end
    else
        Lighting.Ambient = Color3.fromRGB(169, 169, 169) 
        Lighting.GlobalShadows = true
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Density = 0.2
            Lighting.Atmosphere.Offset = 0.25
        end
    end

    -- PLAYER ESP HIGHLIGHTS
    for name, esp in pairs(ActivePlayerEsps) do
        local p = Players:FindFirstChild(name)
        local shouldShow = env.PLAYERESP and p and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0
        if esp then
            esp.Enabled = shouldShow
        end
    end

    -- DRONE ESP HIGHLIGHTS
    for drone, esp in pairs(ActiveDroneEsps) do
        local isValid = drone and drone.Parent ~= nil and drone:FindFirstChildWhichIsA("BasePart") ~= nil
        local shouldShow = env.DRONESESP and isValid
        if esp then
            esp.Enabled = shouldShow
        else
            ActiveDroneEsps[drone] = nil
        end
    end

    -- PLAYER TRACERS
    if HasDrawing then
        for name, tracer in pairs(ActivePlayerTracers) do
            local p = Players:FindFirstChild(name)
            local shouldShow = false

            if env.TRACES and p and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChild("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracer.To = Vector2.new(vector.X, vector.Y)
                        tracer.Visible = true
                        shouldShow = true
                    end
                end
            end

            if not shouldShow and tracer then
                tracer.Visible = false
            end
        end

        -- DRONE TRACERS
        for drone, tracer in pairs(ActiveDroneTracers) do
            local shouldShow = false

            if env.TRACES and env.DRONESESP and drone and drone.Parent ~= nil then
                local targetPart = drone.PrimaryPart or drone:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        tracer.To = Vector2.new(vector.X, vector.Y)
                        tracer.Visible = true
                        shouldShow = true
                    end
                end
            end

            if not shouldShow and tracer then
                tracer.Visible = false
            end
        end
    end

    -- Auto Dodge Drones Logic
    if env.DODGEDRONES then
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local currentTime = tick()
            
            -- Check if we are currently holding the safe zone timeout
            if isDodging then
                if currentTime - lastDodgeTick >= 3 then
                    isDodging = false
                    if returnCFrame then
                        hrp.CFrame = returnCFrame
                        returnCFrame = nil
                    end
                end
            else
                -- Cooldown check (0.5s between teleports) and proximity check (within 100 studs)
                if currentTime - lastDodgeTick >= 0.25 then
                    local closestDistance = math.huge
                    
                    for drone, _ in pairs(ActiveDroneEsps) do
                        if drone and drone.Parent ~= nil then
                            local dronePart = drone.PrimaryPart or drone:FindFirstChildWhichIsA("BasePart")
                            if dronePart then
                                local distance = (hrp.Position - dronePart.Position).Magnitude
                                if distance < closestDistance then
                                    closestDistance = distance
                                end
                            end
                        end
                    end
                    
                    if closestDistance <= env.DODGEDRONESDISTANCE then
                        returnCFrame = hrp.CFrame
                        hrp.CFrame = CFrame.new(SafeZone.Position + Vector3.new(0, 5, 0))
                        lastDodgeTick = currentTime
                        isDodging = true
                    end
                end
            end
        end
    end
end)

-- Cleanup Routine
local function closeScriptRoutine()
    env.SCRIPT_ACTIVE = false
    env.AreumHubExecuted = false
    env.MOBILE_BUTTON = false
    env.FETCHVERSIONS = false

    env.DODGEDRONES = false
    env.WATERWALKING = false

    env.PLAYERESP = false
    env.DRONESESP = false
    env.TANKESP = false
    env.TRACES = false
    env.FULLBRIGHT = false

    for _, esp in pairs(ActivePlayerEsps) do
        pcall(function() esp:Destroy() end)
    end
    ActivePlayerEsps = {}

    for _, tracer in pairs(ActivePlayerTracers) do
        pcall(function() tracer:Remove() end)
    end
    ActivePlayerTracers = {}

    for _, esp in pairs(ActiveDroneEsps) do
        pcall(function() esp:Destroy() end)
    end
    ActiveDroneEsps = {}

    for _, tracer in pairs(ActiveDroneTracers) do
        pcall(function() tracer:Remove() end)
    end
    ActiveDroneTracers = {}

    Lighting.Ambient = Color3.fromRGB(169, 169, 169) 
    Lighting.GlobalShadows = true
    if Lighting:FindFirstChild("Atmosphere") then
        Lighting.Atmosphere.Density = 0.2
        Lighting.Atmosphere.Offset = 0.25
    end
    
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