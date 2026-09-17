--[[
    ═══════════════════════════════════════════════════════════════════════════════
    LuxuryXHUB — ESP MENU & AUTOFARM PRO — v2.1.0 (Bug-Free Release)
    SIDEBAR TABS • NESTED CARD ARCHITECTURE • STRICT DARK THEME
    ═══════════════════════════════════════════════════════════════════════════════
]]

--==================================================
-- [1] COMPONENT: AppConfig
--==================================================
local AppConfig = {
    Name = "LuxuryXHUB",
    Version = "2.1.0",

    ESPFillTransparency = 0.45,
    ESPOutlineTransparency = 0.1,
    ESPNameSize = 13,
    ESPDistanceSize = 11,

    ESPPalette = {
        Color3.fromRGB( 80, 200, 255), Color3.fromRGB(140, 100, 255),
        Color3.fromRGB(  0, 235, 130), Color3.fromRGB(255, 130,  60),
        Color3.fromRGB(255,  80, 180), Color3.fromRGB( 60, 220, 180),
        Color3.fromRGB(200, 255,  70), Color3.fromRGB(255, 200,  60),
        Color3.fromRGB( 80, 160, 255), Color3.fromRGB(220,  90, 255),
        Color3.fromRGB(255, 100, 100), Color3.fromRGB( 60, 255, 220),
    },
    ESPRareColor = Color3.fromRGB(255, 215, 0),

    TPHeight = 3,
    MovementSpeed = 500,
    HomeDepositWait = 1.3,
    AntiStuckThreshold = 2.2,

    BestEggName = "cherub",
    AutoEggHoldTime = 2.5,
    AutoFarmHoldTime = 2.0,
    AutoEggDelay = 0.4,
    EggCooldownSeconds = 12,

    RareKeywords = {
        "cherub", "huge", "exclusive", "secret", "titan",
        "mythic", "golden", "diamond", "dark", "rainbow", "celestial"
    },
    AlertDuration = 6.5,
    MaxAlerts = 3,
    AlertDedupeSeconds = 3,

    PCWidth = 760,
    PCHeight = 480,
    MobileWidth = 620,
    MobileHeight = 400,
    AnimationTime = 0.18,

    Radius2XL = 16, RadiusXL = 12, RadiusLG = 8, RadiusMD = 6, RadiusSM = 4,

    TextTitle = 14,
    TextHeader = 11,
    TextBody = 11,
    TextCaption = 9,
    TextMicro = 8,

    PadXS = 4, PadSM = 6, PadMD = 8, PadLG = 12, PadXL = 16,

    SidebarWidth = 160,
    SidebarItemHeight = 40,

    MaxHistoryLogs = 50,

    BgColor = Color3.fromHex("#171717"),
    BgTransparency = 0.02,
    OuterCardBg = Color3.fromHex("#1F1F1F"),
    OuterCardTransparency = 0.02,
    NestedCardBg = Color3.fromHex("#242424"),
    NestedCardTransparency = 0.02,
    RecessedBg = Color3.fromHex("#1A1A1A"),
    CardBorder = Color3.fromHex("#2C2C2C"),
    BorderInner = Color3.fromHex("#333333"),
    BorderTransparency = 0.35,

    AccentGreen = Color3.fromRGB(0, 230, 118),
    AccentBlue = Color3.fromRGB(0, 150, 255),
    AccentGold = Color3.fromRGB(255, 215, 0),
    AccentRed = Color3.fromRGB(255, 61, 87),

    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(163, 163, 163),
    TextMuted = Color3.fromRGB(110, 110, 110),
}

--==================================================
-- [2] COMPONENT: ServiceManager
--==================================================
local ServiceManager = {}
ServiceManager.Players = game:GetService("Players")
ServiceManager.TweenService = game:GetService("TweenService")
ServiceManager.RunService = game:GetService("RunService")
ServiceManager.UserInputService = game:GetService("UserInputService")
ServiceManager.TeleportService = game:GetService("TeleportService")
ServiceManager.GuiService = game:GetService("GuiService")
ServiceManager.CoreGui = game:GetService("CoreGui")
ServiceManager.Workspace = game:GetService("Workspace")
ServiceManager.ReplicatedStorage = game:GetService("ReplicatedStorage")
ServiceManager.LocalPlayer = ServiceManager.Players.LocalPlayer

ServiceManager.VirtualInputManager = nil
pcall(function() ServiceManager.VirtualInputManager = game:GetService("VirtualInputManager") end)
ServiceManager.VirtualUser = nil
pcall(function() ServiceManager.VirtualUser = game:GetService("VirtualUser") end)

local function getTargetParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return ServiceManager.LocalPlayer:WaitForChild("PlayerGui")
end
ServiceManager.TargetParent = getTargetParent()

ServiceManager.QueueOnTeleport = (syn and syn.queue_on_teleport)
    or (queue_on_teleport)
    or (Fluxus and Fluxus.queue_on_teleport)

ServiceManager.RenderedEggsFolder = ServiceManager.Workspace:WaitForChild("RenderedEggs", 8)

--==================================================
-- [3] COMPONENT: StateStore
--==================================================
local StateStore = {
    mainESPActive = false,
    autoBestEggActive = false, autoBestEggThread = nil,
    autoFarmActive = false, autoFarmThread = nil,
    autoRebirthActive = false, autoRebirthThread = nil,
    missingRebirthEggs = {},
    antiAFKActive = true,
    movementActive = false,
    isMobileMode = false,
    isMinimized = false,
    listeningForKey = false,

    movementMode = "AutoFarm",
    currentSearchQuery = "",
    sortMode = "Name",
    tpKeybind = Enum.KeyCode.T,

    autoFarmEggs = {},
    autoFarmProcessed = setmetatable({}, { __mode = "k" }),
    eggCooldowns = setmetatable({}, { __mode = "k" }),
    eggData = setmetatable({}, { __mode = "k" }),

    farmHistory = {},
    onHistoryUpdated = nil,

    totalEggsCollected = 0,

    movementHumanoid = nil,
    noclipConnection = nil,
    antiAFKConnection = nil,

    recentAlerts = {},
    _connections = {},
    _sliderCounter = 0,
    windowMode = "PC",
    screenGui = nil,
}

function StateStore.track(conn)
    if not conn then return conn end
    table.insert(StateStore._connections, conn)
    return conn
end

function StateStore.addHistoryRecord(eggName)
    local isRare = false
    local lower = eggName:lower()
    for _, kw in ipairs(AppConfig.RareKeywords) do
        if string.find(lower, kw, 1, true) then isRare = true break end
    end

    table.insert(StateStore.farmHistory, 1, {
        name = eggName, isRare = isRare
    })
    if #StateStore.farmHistory > AppConfig.MaxHistoryLogs then
        table.remove(StateStore.farmHistory)
    end

    StateStore.totalEggsCollected = StateStore.totalEggsCollected + 1
    if StateStore.onHistoryUpdated then StateStore.onHistoryUpdated() end
end

function StateStore.shouldAlert(eggName)
    local now = os.clock()
    local last = StateStore.recentAlerts[eggName]
    if last and (now - last) < AppConfig.AlertDedupeSeconds then return false end
    StateStore.recentAlerts[eggName] = now
    return true
end

function StateStore.reset()
    StateStore.mainESPActive = false
    StateStore.autoBestEggActive = false
    StateStore.autoFarmActive = false
    StateStore.autoRebirthActive = false
    StateStore.movementActive = false
    StateStore.isMinimized = false
    StateStore.listeningForKey = false
    StateStore.autoBestEggThread = nil
    StateStore.autoFarmThread = nil
    StateStore.autoRebirthThread = nil
    StateStore.movementHumanoid = nil
    StateStore.onHistoryUpdated = nil
    StateStore.screenGui = nil
    table.clear(StateStore.autoFarmEggs)
    table.clear(StateStore.farmHistory)
    table.clear(StateStore.recentAlerts)
    table.clear(StateStore.missingRebirthEggs)
end

--==================================================
-- [4] COMPONENT: Utils
--==================================================
local Utils = {}

function Utils.getCharacter() return ServiceManager.LocalPlayer.Character end
function Utils.getRootPart()
    local char = Utils.getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end
function Utils.getHumanoid()
    local char = Utils.getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Utils.tween(object, properties, duration, style, direction)
    if not object or not object.Parent then return end
    local info = TweenInfo.new(
        duration or AppConfig.AnimationTime,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local tw = ServiceManager.TweenService:Create(object, info, properties)
    tw:Play()
    return tw
end

function Utils.getTargetCFrame(target)
    if not target or not target.Parent then return nil end
    if target:IsA("Model") then
        if target.PrimaryPart then return target.PrimaryPart.CFrame end
        local base = target:FindFirstChildWhichIsA("BasePart")
        if base then return base.CFrame end
        return target:GetPivot()
    elseif target:IsA("BasePart") then
        return target.CFrame
    end
    return nil
end

function Utils.getTargetPosition(target)
    local cf = Utils.getTargetCFrame(target)
    return cf and cf.Position or nil
end

function Utils.getDistanceToTarget(target)
    local root = Utils.getRootPart()
    local targetPos = Utils.getTargetPosition(target)
    if not root or not targetPos then return math.huge end
    return (root.Position - targetPos).Magnitude
end

function Utils.isValidEgg(egg)
    return egg
        and egg.Parent == ServiceManager.RenderedEggsFolder
        and (egg:IsA("Model") or egg:IsA("BasePart"))
end

function Utils.isRareEgg(eggName)
    local lower = eggName:lower()
    for _, kw in ipairs(AppConfig.RareKeywords) do
        if string.find(lower, kw, 1, true) then return true end
    end
    return false
end

function Utils.getEggImage(eggName)
    local playerGui = ServiceManager.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return "" end
    local main = playerGui:FindFirstChild("Main")
    local index = main and main:FindFirstChild("Index")
    local holders = index and index:FindFirstChild("Holders")
    local eggsHolder = holders and holders:FindFirstChild("EggsHolder")
    if not eggsHolder then return "" end
    local eggFrame = eggsHolder:FindFirstChild(eggName)
    if not eggFrame then return "" end
    local imageLabel = eggFrame:FindFirstChild("ImageLabel")
    if imageLabel and imageLabel:IsA("ImageLabel") then return imageLabel.Image or "" end
    return ""
end

function Utils.isKnownEggName(name)
    if not name or type(name) ~= "string" or #name < 2 then return false end
    local lower = name:lower()
    if string.find(lower, "egg", 1, true) then return true end
    local playerGui = ServiceManager.LocalPlayer:FindFirstChild("PlayerGui")
    local main = playerGui and playerGui:FindFirstChild("Main")
    local index = main and main:FindFirstChild("Index")
    local holders = index and index:FindFirstChild("Holders")
    local eggsHolder = holders and holders:FindFirstChild("EggsHolder")
    if eggsHolder and eggsHolder:FindFirstChild(name) then return true end
    local folder = ServiceManager.RenderedEggsFolder
    if folder and folder:FindFirstChild(name) then return true end
    return false
end

function Utils.resetVelocity(root)
    if not root then return end
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end)
end

--==================================================
-- [5] COMPONENT: StabilityComponent
--==================================================
local StabilityComponent = {}

function StabilityComponent.setupAntiAFK(enable)
    StateStore.antiAFKActive = enable
    if StateStore.antiAFKConnection then
        pcall(function() StateStore.antiAFKConnection:Disconnect() end)
        StateStore.antiAFKConnection = nil
    end
    if enable then
        StateStore.antiAFKConnection = ServiceManager.LocalPlayer.Idled:Connect(function()
            if not StateStore.antiAFKActive then return end
            pcall(function()
                if ServiceManager.VirtualUser then
                    ServiceManager.VirtualUser:CaptureController()
                    ServiceManager.VirtualUser:ClickButton2(Vector2.zero)
                elseif ServiceManager.VirtualInputManager then
                    ServiceManager.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Unknown, false, game)
                    task.wait(0.05)
                    ServiceManager.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Unknown, false, game)
                end
            end)
        end)
    end
end

function StabilityComponent.setupAutoRejoin()
    local function queueScript()
        if ServiceManager.QueueOnTeleport then
            pcall(function()
                ServiceManager.QueueOnTeleport([[
                    task.wait(3)
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/ThiAez/EggsESP/main/loader.lua"))()
                    end)
                ]])
            end)
        end
    end

    pcall(function()
        StateStore.track(ServiceManager.GuiService.ErrorMessageChanged:Connect(function(msg)
            if msg and #msg > 0 then
                queueScript()
                task.wait(2.5)
                pcall(function()
                    if #ServiceManager.Players:GetPlayers() <= 1 then
                        ServiceManager.TeleportService:Teleport(game.PlaceId, ServiceManager.LocalPlayer)
                    else
                        ServiceManager.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, ServiceManager.LocalPlayer)
                    end
                end)
            end
        end))
    end)

    task.spawn(function()
        pcall(function()
            local promptOverlay = ServiceManager.CoreGui:WaitForChild("RobloxPromptGui", 8)
                and ServiceManager.CoreGui.RobloxPromptGui:WaitForChild("promptOverlay", 8)
            if promptOverlay then
                StateStore.track(promptOverlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" then
                        queueScript()
                        task.wait(2)
                        pcall(function()
                            ServiceManager.TeleportService:Teleport(game.PlaceId, ServiceManager.LocalPlayer)
                        end)
                    end
                end))
            end
        end)
    end)
end

--==================================================
-- [6] COMPONENT: InteractionComponent
--==================================================
local InteractionComponent = {}

function InteractionComponent.holdEKey(duration)
    duration = duration or 1.5
    local vim = ServiceManager.VirtualInputManager
    local vu = ServiceManager.VirtualUser
    if vim then pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
    elseif vu then pcall(function() vu:SetKeyDown("e") end) end
    task.wait(duration)
    if vim then pcall(function() vim:SendKeyEvent(false, Enum.KeyCode.E, false, game) end) end
    if vu then pcall(function() vu:SetKeyUp("e") end) end
end

function InteractionComponent.trigger(targetObject, fallbackDuration)
    if not targetObject then return false end
    local prompt = targetObject:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled and fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.2)
        return true
    end
    InteractionComponent.holdEKey(fallbackDuration)
    return true
end

--==================================================
-- [7] COMPONENT: MovementComponent
--==================================================
local MovementComponent = {}

function MovementComponent.setNoclip(enabled)
    if StateStore.noclipConnection then
        pcall(function() StateStore.noclipConnection:Disconnect() end)
        StateStore.noclipConnection = nil
    end
    local character = Utils.getCharacter()
    if not character then return end
    if enabled then
        StateStore.noclipConnection = ServiceManager.RunService.Stepped:Connect(function()
            local char = Utils.getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
                and not part:IsA("Accessory") and not part.Parent:IsA("Accessory") then
                part.CanCollide = true
            end
        end
    end
end

function MovementComponent.stop()
    StateStore.movementActive = false
    if StateStore.movementHumanoid and StateStore.movementHumanoid.Parent then
        StateStore.movementHumanoid.AutoRotate = true
    end
    StateStore.movementHumanoid = nil
    MovementComponent.setNoclip(false)
    Utils.resetVelocity(Utils.getRootPart())
end

function MovementComponent.teleportTo(target)
    local root = Utils.getRootPart()
    if not root then return false end
    local targetCFrame = Utils.getTargetCFrame(target)
    if not targetCFrame then return false end
    Utils.resetVelocity(root)
    root.CFrame = targetCFrame * CFrame.new(0, AppConfig.TPHeight, 0)
    Utils.resetVelocity(root)
    return true
end

function MovementComponent.moveTo(target)
    if StateStore.movementMode == "Teleport" then
        return MovementComponent.teleportTo(target)
    end
    if StateStore.movementActive then return false end

    local root = Utils.getRootPart()
    local humanoid = Utils.getHumanoid()
    local targetCFrame = Utils.getTargetCFrame(target)
    if not root or not humanoid or not targetCFrame or humanoid.Health <= 0 then return false end

    local destination = targetCFrame.Position + Vector3.new(0, AppConfig.TPHeight, 0)
    local startDistance = (root.Position - destination).Magnitude

    if startDistance <= 2.8 then
        Utils.resetVelocity(root)
        root.CFrame = targetCFrame * CFrame.new(0, AppConfig.TPHeight, 0)
        return true
    end

    StateStore.movementActive = true
    StateStore.movementHumanoid = humanoid
    local oldAutoRotate = humanoid.AutoRotate
    local success = false
    local startTime = os.clock()
    local maxTime = math.max(3.5, (startDistance / AppConfig.MovementSpeed) + 2.5)
    local lastCheckPos = root.Position
    local lastCheckTime = os.clock()

    MovementComponent.setNoclip(true)
    humanoid.AutoRotate = false

    while StateStore.movementActive and (os.clock() - startTime <= maxTime) do
        if not target or not target.Parent or humanoid.Health <= 0 then break end
        if Utils.getRootPart() ~= root then break end

        local curTargetCF = Utils.getTargetCFrame(target)
        if curTargetCF then
            destination = curTargetCF.Position + Vector3.new(0, AppConfig.TPHeight, 0)
        end

        local offset = destination - root.Position
        local distance = offset.Magnitude

        if distance <= 2.8 then
            Utils.resetVelocity(root)
            root.CFrame = (curTargetCF or targetCFrame) * CFrame.new(0, AppConfig.TPHeight, 0)
            success = true
            break
        end

        if os.clock() - lastCheckTime >= AppConfig.AntiStuckThreshold then
            if (root.Position - lastCheckPos).Magnitude < 1.2 then
                root.CFrame = root.CFrame * CFrame.new(0, 4, 0)
                MovementComponent.setNoclip(true)
                Utils.resetVelocity(root)
            end
            lastCheckPos = root.Position
            lastCheckTime = os.clock()
        end

        local dt = ServiceManager.RunService.Heartbeat:Wait()
        local step = math.min(distance, AppConfig.MovementSpeed * dt)
        Utils.resetVelocity(root)
        local newPos = root.Position + (offset.Unit * step)
        if (destination - newPos).Magnitude > 0.08 then
            root.CFrame = CFrame.lookAt(newPos, destination)
        else
            root.CFrame = (curTargetCF or targetCFrame) * CFrame.new(0, AppConfig.TPHeight, 0)
            success = true
            break
        end
    end

    StateStore.movementActive = false
    if humanoid and humanoid.Parent then humanoid.AutoRotate = oldAutoRotate end
    StateStore.movementHumanoid = nil
    MovementComponent.setNoclip(false)
    Utils.resetVelocity(root)
    return success
end

--==================================================
-- [8] COMPONENT: PlotComponent
--==================================================
local PlotComponent = {}

function PlotComponent.isOwner(plot)
    if not plot then return false end
    local lp = ServiceManager.LocalPlayer
    local dataFolder = plot:FindFirstChild("Data")
    if dataFolder then
        local ownerVal = dataFolder:FindFirstChild("Owner") or dataFolder:FindFirstChild("Player")
        if ownerVal then
            if ownerVal:IsA("StringValue") and (ownerVal.Value == lp.Name or ownerVal.Value == lp.DisplayName) then return true
            elseif ownerVal:IsA("ObjectValue") and ownerVal.Value == lp then return true
            elseif ownerVal:IsA("IntValue") and ownerVal.Value == lp.UserId then return true
            elseif tostring(ownerVal.Value) == lp.Name or tostring(ownerVal.Value) == tostring(lp.UserId) then return true end
        end
    end
    local direct = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
    if direct then
        if direct:IsA("StringValue") and (direct.Value == lp.Name or direct.Value == lp.DisplayName) then return true
        elseif direct:IsA("ObjectValue") and direct.Value == lp then return true
        elseif direct:IsA("IntValue") and direct.Value == lp.UserId then return true
        elseif tostring(direct.Value) == lp.Name then return true end
    end
    local attr = plot:GetAttribute("Owner") or plot:GetAttribute("Player")
    if attr and (attr == lp.Name or attr == lp.DisplayName) then return true end
    local attrId = plot:GetAttribute("OwnerId") or plot:GetAttribute("UserId")
    if attrId and (attrId == lp.UserId or tostring(attrId) == tostring(lp.UserId)) then return true end
    if plot.Name == lp.Name or plot.Name == tostring(lp.UserId) then return true end
    local sign = plot:FindFirstChild("Sign", true) or plot:FindFirstChild("PlotSign", true)
    if sign then
        for _, obj in ipairs(sign:GetDescendants()) do
            if obj:IsA("TextLabel") and (obj.Text:find(lp.Name) or obj.Text:find(lp.DisplayName)) then return true end
        end
    end
    return false
end

function PlotComponent.findHomePlot()
    local ws = ServiceManager.Workspace
    local folders = {
        ws:FindFirstChild("Plots"), ws:FindFirstChild("PlayerPlots"),
        ws:FindFirstChild("Bases"), ws:FindFirstChild("Islands"),
        ws:FindFirstChild("Tycoons")
    }
    for _, folder in ipairs(folders) do
        if folder then
            for _, plot in ipairs(folder:GetChildren()) do
                if PlotComponent.isOwner(plot) then return plot end
            end
        end
    end
    for _, child in ipairs(ws:GetChildren()) do
        if child:IsA("Model") and (child.Name:find("Plot") or child.Name:find("Base")) then
            if PlotComponent.isOwner(child) then return child end
        end
    end
    return nil
end

function PlotComponent.teleportAndDeposit()
    local plot = PlotComponent.findHomePlot()
    if not plot then return false end
    MovementComponent.stop()
    Utils.resetVelocity(Utils.getRootPart())
    local depositPoint = plot:FindFirstChild("Deposit", true)
        or plot:FindFirstChild("EggDeposit", true)
        or plot:FindFirstChild("Clear", true)
        or plot:FindFirstChild("Spawn", true)
        or plot:FindFirstChild("Base", true)
        or plot:FindFirstChild("Center", true)
        or plot.PrimaryPart
        or plot:FindFirstChildWhichIsA("BasePart")
        or plot
    local arrived = MovementComponent.moveTo(depositPoint)
    Utils.resetVelocity(Utils.getRootPart())
    if arrived then
        task.wait(0.25)
        InteractionComponent.trigger(depositPoint, AppConfig.HomeDepositWait)
    end
    return arrived
end

--==================================================
-- [9] COMPONENT: ESPComponent
--==================================================
local ESPComponent = {}

function ESPComponent.getColor(eggName)
    local lower = eggName:lower()
    for _, kw in ipairs(AppConfig.RareKeywords) do
        if string.find(lower, kw, 1, true) then return AppConfig.ESPRareColor end
    end
    local hash = 0
    for i = 1, #eggName do hash = hash + string.byte(eggName, i) * (i + 1) end
    local palette = AppConfig.ESPPalette
    return palette[(hash % #palette) + 1]
end

function ESPComponent.createBillboard(egg)
    local data = StateStore.eggData[egg]
    if not data or (data.NameBillboard and data.NameBillboard.Parent) then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggESP_Info"
    billboard.Size = UDim2.new(0, 180, 0, 42)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 2500
    billboard.Enabled = false
    billboard.Parent = egg

    local eggColor = ESPComponent.getColor(egg.Name)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "EggName"
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = egg.Name
    nameLabel.TextColor3 = eggColor
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextSize = AppConfig.ESPNameSize
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.Size = UDim2.new(1, 0, 0, 16)
    distLabel.Position = UDim2.new(0, 0, 0, 19)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0 studs"
    distLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
    distLabel.TextStrokeTransparency = 0.4
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.TextSize = AppConfig.ESPDistanceSize
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.Parent = billboard
    data.NameBillboard = billboard
end

function ESPComponent.updateBillboard(egg)
    local data = StateStore.eggData[egg]
    if not data or not data.NameBillboard or not data.NameBillboard.Parent then return end
    local billboard = data.NameBillboard
    local nameLabel = billboard:FindFirstChild("EggName")
    local distLabel = billboard:FindFirstChild("Distance")
    if nameLabel then nameLabel.Text = egg.Name end
    if distLabel then
        local d = Utils.getDistanceToTarget(egg)
        distLabel.Text = (d == math.huge) and "?" or string.format("%d studs", math.floor(d + 0.5))
    end
end

function ESPComponent.updateEgg(egg)
    if not Utils.isValidEgg(egg) then return end
    if not StateStore.eggData[egg] then
        StateStore.eggData[egg] = {
            Highlight = nil, NameBillboard = nil,
            CustomColor = ESPComponent.getColor(egg.Name),
            CustomActive = false
        }
    end
    local data = StateStore.eggData[egg]
    local eggColor = ESPComponent.getColor(egg.Name)
    local shouldShow = data.CustomActive or StateStore.mainESPActive
    local color = data.CustomActive and (data.CustomColor or eggColor) or eggColor

    if shouldShow then
        if not data.Highlight or not data.Highlight.Parent then
            local highlight = Instance.new("Highlight")
            highlight.Name = "EggESP_Highlight"
            highlight.Adornee = egg
            highlight.FillTransparency = AppConfig.ESPFillTransparency
            highlight.OutlineTransparency = AppConfig.ESPOutlineTransparency
            highlight.Parent = egg
            data.Highlight = highlight
        end
        data.Highlight.FillColor = color
        data.Highlight.OutlineColor = color
        data.Highlight.Enabled = true
        ESPComponent.createBillboard(egg)
        if data.NameBillboard then
            data.NameBillboard.Enabled = true
            ESPComponent.updateBillboard(egg)
        end
    else
        if data.Highlight then data.Highlight.Enabled = false end
        if data.NameBillboard then data.NameBillboard.Enabled = false end
    end
end

function ESPComponent.updateAll()
    local folder = ServiceManager.RenderedEggsFolder
    if not folder then return end
    for _, egg in ipairs(folder:GetChildren()) do ESPComponent.updateEgg(egg) end
end

function ESPComponent.removeEgg(egg)
    local data = StateStore.eggData[egg]
    if data then
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        if data.NameBillboard then pcall(function() data.NameBillboard:Destroy() end) end
        StateStore.eggData[egg] = nil
    end
    StateStore.autoFarmProcessed[egg] = nil
    StateStore.eggCooldowns[egg] = nil
end

function ESPComponent.bindEggLifecycle(egg)
    if not egg or not egg.Parent then return end
    local conn
    conn = egg.Destroying:Connect(function()
        ESPComponent.removeEgg(egg)
        if conn then pcall(function() conn:Disconnect() end) end
    end)
    StateStore.track(conn)
end

--==================================================
-- [10] COMPONENT: FarmComponent
--==================================================
local FarmComponent = {}

function FarmComponent.getReadyEggs()
    local found = {}
    local folder = ServiceManager.RenderedEggsFolder
    if not folder then return found end
    local now = os.clock()
    for _, egg in ipairs(folder:GetChildren()) do
        if Utils.isValidEgg(egg) and StateStore.autoFarmEggs[egg.Name] then
            local cd = StateStore.eggCooldowns[egg]
            local onCooldown = (cd and now <= cd)
            if not onCooldown and not StateStore.autoFarmProcessed[egg] then
                table.insert(found, egg)
            end
        end
    end
    table.sort(found, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return found
end

function FarmComponent.findBestEgg()
    local folder = ServiceManager.RenderedEggsFolder
    if not folder then return nil end
    local now = os.clock()
    local query = AppConfig.BestEggName:lower()
    for _, egg in ipairs(folder:GetChildren()) do
        local cd = StateStore.eggCooldowns[egg]
        local onCooldown = (cd and now <= cd)
        if not onCooldown and Utils.isValidEgg(egg) and string.find(egg.Name:lower(), query, 1, true) then
            return egg
        end
    end
    return nil
end

function FarmComponent.stopAutoFarm()
    StateStore.autoFarmActive = false
    MovementComponent.stop()
    if StateStore.autoFarmThread then
        pcall(function() task.cancel(StateStore.autoFarmThread) end)
        StateStore.autoFarmThread = nil
    end
    pcall(function()
        if ServiceManager.VirtualInputManager then
            ServiceManager.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

function FarmComponent.startAutoFarm(statusUpdater, stopButtonUpdater)
    FarmComponent.stopAutoFarm()
    StateStore.autoFarmActive = true
    if stopButtonUpdater then stopButtonUpdater(true) end

    StateStore.autoFarmThread = task.spawn(function()
        while StateStore.autoFarmActive do
            local hasAny = false
            for _, v in pairs(StateStore.autoFarmEggs) do if v then hasAny = true break end end
            if not hasAny then
                if statusUpdater then statusUpdater("No eggs selected", AppConfig.TextSecondary) end
                break
            end

            local readyEggs = FarmComponent.getReadyEggs()
            if #readyEggs == 0 then
                if statusUpdater then statusUpdater("Waiting for eggs to spawn / CD...", AppConfig.TextSecondary) end
                task.wait(1.0)
            else
                for _, egg in ipairs(readyEggs) do
                    if not StateStore.autoFarmActive then break end
                    local cd = StateStore.eggCooldowns[egg]
                    local onCooldown = (cd and os.clock() <= cd)
                    if Utils.isValidEgg(egg) and not StateStore.autoFarmProcessed[egg] and not onCooldown then
                        local currentEggName = egg.Name
                        if statusUpdater then statusUpdater("Farming: " .. currentEggName, AppConfig.AccentGreen) end

                        local arrived = MovementComponent.moveTo(egg)
                        if arrived and StateStore.autoFarmActive then
                            task.wait(0.2)
                            if StateStore.autoFarmActive and Utils.isValidEgg(egg) then
                                if statusUpdater then statusUpdater("Collecting " .. currentEggName .. "...", AppConfig.AccentGold) end
                                InteractionComponent.trigger(egg, AppConfig.AutoFarmHoldTime)
                            end
                            StateStore.eggCooldowns[egg] = os.clock() + AppConfig.EggCooldownSeconds
                            task.wait(0.3)
                            if StateStore.autoFarmActive then
                                if statusUpdater then statusUpdater("Returning Home & Depositing...", AppConfig.AccentBlue) end
                                MovementComponent.stop()
                                local homeSuccess = PlotComponent.teleportAndDeposit()
                                if homeSuccess then
                                    StateStore.autoFarmProcessed[egg] = true
                                    StateStore.addHistoryRecord(currentEggName)
                                    if statusUpdater then statusUpdater("Egg Deposited!", AppConfig.AccentGreen) end
                                else
                                    if statusUpdater then statusUpdater("Home Plot Unreachable", AppConfig.AccentRed) end
                                end
                            end
                            task.wait(AppConfig.AutoEggDelay)
                        end
                    end
                end
            end
            task.wait(0.25)
        end
        StateStore.autoFarmThread = nil
        StateStore.autoFarmActive = false
        if stopButtonUpdater then stopButtonUpdater(false) end
        if statusUpdater then statusUpdater("AutoFarm Idle", AppConfig.TextSecondary) end
    end)
end

function FarmComponent.stopAutoBestEgg()
    StateStore.autoBestEggActive = false
    MovementComponent.stop()
    if StateStore.autoBestEggThread then
        pcall(function() task.cancel(StateStore.autoBestEggThread) end)
        StateStore.autoBestEggThread = nil
    end
    pcall(function()
        if ServiceManager.VirtualInputManager then
            ServiceManager.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

function FarmComponent.startAutoBestEgg(statusUpdater)
    FarmComponent.stopAutoBestEgg()
    StateStore.autoBestEggActive = true
    StateStore.autoBestEggThread = task.spawn(function()
        while StateStore.autoBestEggActive do
            local egg = FarmComponent.findBestEgg()
            if egg and egg.Parent then
                local currentEggName = egg.Name
                if statusUpdater then statusUpdater("Moving to " .. currentEggName, AppConfig.AccentGreen) end
                local arrived = MovementComponent.moveTo(egg)
                if arrived and StateStore.autoBestEggActive then
                    task.wait(0.2)
                    if StateStore.autoBestEggActive and egg.Parent then
                        if statusUpdater then statusUpdater("Collecting " .. currentEggName .. "...", AppConfig.AccentGold) end
                        InteractionComponent.trigger(egg, AppConfig.AutoEggHoldTime)
                    end
                    StateStore.eggCooldowns[egg] = os.clock() + AppConfig.EggCooldownSeconds
                    task.wait(0.3)
                    if StateStore.autoBestEggActive then
                        if statusUpdater then statusUpdater("Returning Home & Depositing...", AppConfig.AccentBlue) end
                        MovementComponent.stop()
                        local ok = PlotComponent.teleportAndDeposit()
                        if ok then
                            StateStore.addHistoryRecord(currentEggName)
                            if statusUpdater then statusUpdater("Best Egg Deposited!", AppConfig.AccentGreen) end
                        end
                    end
                    task.wait(AppConfig.AutoEggDelay)
                else
                    task.wait(0.5)
                end
            else
                if statusUpdater then statusUpdater("Searching: [" .. AppConfig.BestEggName .. "]...", AppConfig.TextSecondary) end
                task.wait(1.0)
            end
        end
        StateStore.autoBestEggThread = nil
        StateStore.autoBestEggActive = false
    end)
end

--==================================================
-- [11] COMPONENT: RebirthComponent
--==================================================
local RebirthComponent = {}

function RebirthComponent.getRebirthRemote()
    local rs = ServiceManager.ReplicatedStorage or game:GetService("ReplicatedStorage")
    local remotes = rs:FindFirstChild("Remotes")
    local gameRemotes = remotes and remotes:FindFirstChild("Game")
    local rebirthEvent = gameRemotes and gameRemotes:FindFirstChild("Rebirth")
    if rebirthEvent and rebirthEvent:IsA("RemoteEvent") then return rebirthEvent end
    local fallback = rs:FindFirstChild("Rebirth", true)
    if fallback and fallback:IsA("RemoteEvent") then return fallback end
    return nil
end

function RebirthComponent.fireRebirth()
    local remote = RebirthComponent.getRebirthRemote()
    if remote then
        local ok = pcall(function() remote:FireServer() end)
        return ok
    end
    return false
end

function RebirthComponent.findEggByName(eggName)
    local folder = ServiceManager.RenderedEggsFolder
    if not folder then return nil end
    local query = eggName:lower():match("^%s*(.-)%s*$")
    local now = os.clock()
    for _, egg in ipairs(folder:GetChildren()) do
        local cd = StateStore.eggCooldowns[egg]
        local onCooldown = (cd and now <= cd)
        if not onCooldown and Utils.isValidEgg(egg) then
            local n = egg.Name:lower()
            if n == query or string.find(n, query, 1, true) or string.find(query, n, 1, true) then return egg end
        end
    end
    for _, egg in ipairs(folder:GetChildren()) do
        if Utils.isValidEgg(egg) then
            local n = egg.Name:lower()
            if n == query or string.find(n, query, 1, true) or string.find(query, n, 1, true) then return egg end
        end
    end
    return nil
end

function RebirthComponent.scanMissingEggs()
    local missing = {}
    local seen = {}
    local playerGui = ServiceManager.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return missing end

    local function checkRebirthContainer(container)
        if not container then return end
        for _, item in ipairs(container:GetDescendants()) do
            if item:IsA("TextLabel") then
                local text = item.Text
                if string.find(text, "^%s*0%s*/%s*%d+") or string.find(text, "%s+0%s*/%s*%d+") then
                    local parent = item.Parent
                    local eggCandidate = nil
                    if parent then
                        if Utils.isKnownEggName(parent.Name) then
                            eggCandidate = parent.Name
                        else
                            for _, sib in ipairs(parent:GetChildren()) do
                                if sib:IsA("TextLabel") and sib ~= item then
                                    local st = sib.Text:match("^%s*(.-)%s*$")
                                    if st and #st > 0 and Utils.isKnownEggName(st) then
                                        eggCandidate = st
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if eggCandidate and not seen[eggCandidate:lower()] then
                        seen[eggCandidate:lower()] = true
                        table.insert(missing, eggCandidate)
                    end
                end
            end
        end
    end

    local main = playerGui:FindFirstChild("Main")
    if main then
        for _, child in ipairs(main:GetChildren()) do
            if string.find(child.Name:lower(), "rebirth", 1, true) then checkRebirthContainer(child) end
        end
        local frames = main:FindFirstChild("Frames")
        if frames then
            for _, child in ipairs(frames:GetChildren()) do
                if string.find(child.Name:lower(), "rebirth", 1, true) then checkRebirthContainer(child) end
            end
        end
    end
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and string.find(gui.Name:lower(), "rebirth", 1, true) then
            checkRebirthContainer(gui)
        end
    end

    if #missing == 0 and main then
        local rebirthFrame = main:FindFirstChild("Rebirth", true) or main:FindFirstChild("RebirthFrame", true)
        if rebirthFrame then
            for _, desc in ipairs(rebirthFrame:GetDescendants()) do
                if desc:IsA("Frame") or desc:IsA("ImageLabel") or desc:IsA("TextLabel") then
                    local n = desc.Name
                    if Utils.isKnownEggName(n) and not seen[n:lower()] then
                        local isDone = false
                        for _, child in ipairs(desc:GetDescendants()) do
                            if child:IsA("TextLabel") and string.find(child.Text, "^%s*[1-9]%d*%s*/") then
                                isDone = true break
                            end
                            if child:IsA("ImageLabel") and (string.find(child.Name:lower(), "check", 1, true) or string.find(child.Name:lower(), "done", 1, true)) and child.Visible then
                                isDone = true break
                            end
                        end
                        if not isDone then
                            seen[n:lower()] = true
                            table.insert(missing, n)
                        end
                    end
                end
            end
        end
    end
    StateStore.missingRebirthEggs = missing
    return missing
end

function RebirthComponent.stopAutoRebirth()
    StateStore.autoRebirthActive = false
    MovementComponent.stop()
    if StateStore.autoRebirthThread then
        pcall(function() task.cancel(StateStore.autoRebirthThread) end)
        StateStore.autoRebirthThread = nil
    end
end

function RebirthComponent.startAutoRebirth(statusUpdater, stopButtonUpdater)
    RebirthComponent.stopAutoRebirth()
    StateStore.autoRebirthActive = true
    if stopButtonUpdater then stopButtonUpdater(true) end

    StateStore.autoRebirthThread = task.spawn(function()
        while StateStore.autoRebirthActive do
            if statusUpdater then statusUpdater("Checking Rebirth Status...", AppConfig.AccentGold) end
            RebirthComponent.fireRebirth()
            task.wait(0.6)
            local missing = RebirthComponent.scanMissingEggs()

            if #missing == 0 then
                if statusUpdater then statusUpdater("Requirements Met / Rebirth Fired!", AppConfig.AccentGreen) end
                task.wait(1.2)
                RebirthComponent.fireRebirth()
                task.wait(1.5)
            else
                local missingSummary = table.concat(missing, ", ")
                if statusUpdater then statusUpdater("Rebirth Needs: [" .. missingSummary .. "]", AppConfig.AccentBlue) end
                for _, eggName in ipairs(missing) do
                    if not StateStore.autoRebirthActive then break end
                    local targetEgg = RebirthComponent.findEggByName(eggName)
                    if targetEgg then
                        if statusUpdater then statusUpdater("Moving to [" .. eggName .. "]...", AppConfig.AccentGreen) end
                        local arrived = MovementComponent.moveTo(targetEgg)
                        if arrived and StateStore.autoRebirthActive then
                            task.wait(0.2)
                            if StateStore.autoRebirthActive and targetEgg.Parent then
                                if statusUpdater then statusUpdater("Collecting [" .. eggName .. "]...", AppConfig.AccentGold) end
                                InteractionComponent.trigger(targetEgg, AppConfig.AutoEggHoldTime)
                            end
                            StateStore.eggCooldowns[targetEgg] = os.clock() + AppConfig.EggCooldownSeconds
                            task.wait(0.3)
                            if StateStore.autoRebirthActive then
                                if statusUpdater then statusUpdater("Returning Home & Depositing...", AppConfig.AccentBlue) end
                                MovementComponent.stop()
                                local ok = PlotComponent.teleportAndDeposit()
                                if ok then
                                    StateStore.addHistoryRecord(eggName)
                                    if statusUpdater then statusUpdater("[" .. eggName .. "] Deposited!", AppConfig.AccentGreen) end
                                end
                            end
                            task.wait(AppConfig.AutoEggDelay)
                        end
                    else
                        if statusUpdater then statusUpdater("Waiting for [" .. eggName .. "] to spawn...", AppConfig.TextSecondary) end
                        task.wait(1.2)
                    end
                end
            end
            task.wait(0.5)
        end
        StateStore.autoRebirthThread = nil
        StateStore.autoRebirthActive = false
        if stopButtonUpdater then stopButtonUpdater(false) end
        if statusUpdater then statusUpdater("AutoRebirth Idle", AppConfig.TextSecondary) end
    end)
end
