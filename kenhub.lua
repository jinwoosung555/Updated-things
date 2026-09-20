getgenv().WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

WindUI:AddTheme({
    Name = "Dark",
    Accent = Color3.fromHex("#FFFFFF"),
    Background = Color3.fromHex("#0D0D0D"),
    Outline = Color3.fromHex("#333333"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#555555"),
    Button = Color3.fromHex("#1A1A1A"),
    Icon = Color3.fromHex("#FFFFFF"),
})

getgenv().Window = WindUI:CreateWindow({
    Title = "<font color='#FFFFFF'>kenhub</font>",
    Icon = "kayak",
    Author = "v1.3.2",
    Folder = "MySuperHub",

    Background = "rbxassetid://137688068602405", 
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.65,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
})

Window:EditOpenButton({
    Title = "<font color='#FFFFFF'>kenhub</font>",
    Icon = "kayak",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("#222222"), 
        Color3.fromHex("#FFFFFF")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

getgenv().Players = game:GetService("Players")
getgenv().RunService = game:GetService("RunService")
getgenv().UserInputService = game:GetService("UserInputService")
getgenv().LocalPlayer = Players.LocalPlayer
getgenv().Camera = workspace.CurrentCamera
getgenv().VirtualInputManager = game:GetService("VirtualInputManager")
getgenv().TeleportService = game:GetService("TeleportService")
getgenv().HttpService = game:GetService("HttpService")
getgenv().TweenService = game:GetService("TweenService")
getgenv().ReplicatedStorage = game:GetService("ReplicatedStorage")
getgenv().CollectionService = game:GetService("CollectionService")
getgenv().Debris = game:GetService("Debris")
getgenv().Lighting = game:GetService("Lighting")
getgenv().SoundService = game:GetService("SoundService")
getgenv().Stats = game:GetService("Stats")
getgenv().CoreGui = game:GetService("CoreGui")

getgenv().toggles = {}

getgenv().MasterEnabled = false
getgenv().CombatEnabled = false
getgenv().CamlockEnabled = false
getgenv().CurrentTarget = nil
getgenv().CamlockTarget = nil
getgenv().LOCK_DISTANCE = 80
getgenv().CamLOCK_DISTANCE = 120
getgenv().CamPREDICTION = 0.12
getgenv().CamSMOOTHNESS = 0.18

getgenv().InstantLethalEnabled = false
getgenv().InstantLethalConnection = nil
getgenv().InstantLethalAnimConnection = nil

getgenv().FPS = 0
getgenv().lastUpdate = tick()
getgenv().frameCount = 0
getgenv().Ping = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    
    if now - lastUpdate >= 1 then
        FPS = math.floor(frameCount / (now - lastUpdate))
        frameCount = 0
        lastUpdate = now
    end
end)

task.spawn(function()
    while task.wait(2) do
        local success, pingValue = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if success then
            Ping = pingValue
        end
    end
end)

function GetNearestPlayer()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    local root = char.HumanoidRootPart
    local nearest, dist = nil, LOCK_DISTANCE

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < dist then
                    dist = d
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

function CamFindTarget()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end

    local root = myChar.HumanoidRootPart
    local nearest, bestDist = nil, CamLOCK_DISTANCE

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

local function InstantLethal_DoFlick()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if root and hum then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(x, y + math.pi, z)
        hum.AutoRotate = false
        task.delay(0.4, function() if hum then hum.AutoRotate = true end end)
    end
end

local function InstantLethal_DoJump()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(0, 64, 0) end
end

local function InstantLethal_ConnectLogic()
    if InstantLethalAnimConnection then 
        InstantLethalAnimConnection:Disconnect() 
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    local animId = "rbxassetid://12296113986"
    local Smoothness = 0.22
    
    InstantLethalAnimConnection = hum.AnimationPlayed:Connect(function(anim)
        if InstantLethalEnabled and anim.Animation.AnimationId == animId then
            task.wait(1.72)
            InstantLethal_DoJump()
            InstantLethal_DoFlick()
            local dashData = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
            if char:FindFirstChild("Communicate") then
                char.Communicate:FireServer(unpack(dashData))
            end
            task.wait(Smoothness)
            InstantLethal_DoFlick()
        end
    end)
end

local function StartInstantLethal()
    if InstantLethalConnection then 
        InstantLethalConnection:Disconnect() 
    end
    InstantLethal_ConnectLogic()
    InstantLethalConnection = LocalPlayer.CharacterAdded:Connect(function()
        if InstantLethalEnabled then 
            task.wait(0.5) 
            InstantLethal_ConnectLogic() 
        end
    end)
end

local function StopInstantLethal()
    if InstantLethalAnimConnection then
        InstantLethalAnimConnection:Disconnect()
        InstantLethalAnimConnection = nil
    end
    if InstantLethalConnection then
        InstantLethalConnection:Disconnect()
        InstantLethalConnection = nil
    end
end

getgenv().targetPlayer = nil
getgenv().killEnabled = false
getgenv().orbitEnabled = false
getgenv().nameInput = ""

local function getNearestPlayerAK()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart
    local nearest, minDist = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (root.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

local function tapKey(key, delayTime)
    delayTime = delayTime or 0.05
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(delayTime)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

RunService.RenderStepped:Connect(function()
    if MasterEnabled and CombatEnabled then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end

        if not CurrentTarget or not CurrentTarget.Character or not CurrentTarget.Character:FindFirstChildOfClass("Humanoid") or CurrentTarget.Character.Humanoid.Health <= 0 then
            CurrentTarget = GetNearestPlayer()
            return
        end

        local targetHRP = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end

        char.HumanoidRootPart.CFrame = CFrame.new(
            char.HumanoidRootPart.Position,
            Vector3.new(targetHRP.Position.X, char.HumanoidRootPart.Position.Y, targetHRP.Position.Z)
        )
    end

    if CamlockEnabled then
        if not CamlockTarget or not CamlockTarget.Character or not CamlockTarget.Character:FindFirstChild("HumanoidRootPart") then
            CamlockTarget = CamFindTarget()
            return
        end

        local hrp = CamlockTarget.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local predicted = hrp.Position + (hrp.AssemblyLinearVelocity * CamPREDICTION)
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, predicted)
        Camera.CFrame = currentCF:Lerp(targetCF, CamSMOOTHNESS)
    end
end)

local function GetCharacterData()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if humanoid and root then
            return char, humanoid, root
        end
    end
    return nil
end

local function FireDashQW()
    local char = LocalPlayer.Character
    if char then
        local comm = char:FindFirstChild("Communicate")
        if comm then
            local dashData = {{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}
            pcall(function() comm:FireServer(unpack(dashData)) end)
        end
    end
end

local function DeleteBodyVelocity()
    local function findNilInstance(name, className)
        if type(getnilinstances) ~= "function" then return nil end
        pcall(function()
            for _, inst in ipairs(getnilinstances()) do
                if inst.ClassName == className and inst.Name == name then
                    return inst
                end
            end
        end)
        return nil
    end
    
    pcall(function()
        local bv = findNilInstance("moveme", "BodyVelocity")
        if bv then
            local comm = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Communicate")
            if comm then
                comm:FireServer({Goal = "delete bv", BV = bv})
            end
            bv.Parent = nil
        end
    end)
end

getgenv().LoopDashConfig = {
    Enabled = false,
    loopReworkAnimDetectId = "10503381238",
    LoopDashDelay = 0.28,
    LoopDashJump = 55,
    LoopDashAccuracy = 15,
    LoopDashCancelDelay = 0.4,
    LoopDashMode = "BodyGyro",
    CancelEnabled = true,
    CooldownActive = true,
    NoClipEnabled = true,
    DashRange = 8,
    JumpMode = "Normal",
    JumpDelay = 0.25,
    DashDuration = 1.5,
    CamSmooth = false,
    CooldownAnims = {
        ["10491993682"] = true,
        ["10479335397"] = true,
        ["13380255751"] = true,
    },
    AnimConnection = nil,
    CharacterConnection = nil,
}

getgenv().LoopDashIsNoclipping = false
getgenv().LoopDashIsCooldown = false
getgenv().LoopDashIsExecuting = false
getgenv().LoopDashNoclipConn = nil
getgenv().LoopDashCamSmoothConn = nil
getgenv().LoopDash_wasAttachedByScript = false
getgenv().LoopDash_prevCamType = nil
getgenv().LoopDash_prevCamSubject = nil
getgenv().LoopDash_prevCamCFrame = nil

local function LoopDashGetId(str)
    return tostring(str):match("%d+")
end

local function LoopDashClip()
    LoopDashIsNoclipping = false
    local _, hum = GetCharacterData()
    if hum then hum.AutoRotate = true end
end

local function LoopDashForceCancel()
    LoopDashClip()
    local _, _, hrp = GetCharacterData()
    if hrp then
        for _, obj in pairs(hrp:GetChildren()) do
            if obj:IsA("BodyVelocity") or obj:IsA("LinearVelocity") or obj:IsA("BodyAngularVelocity") or obj:IsA("AlignOrientation") then
                obj:Destroy()
            elseif obj:IsA("Attachment") and obj.Name == "LoopDashAtt" then
                obj:Destroy()
            end
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

local function LoopDashStartCooldown(duration)
    if LoopDashIsCooldown then return end
    LoopDashIsCooldown = true
    task.delay(duration, function()
        LoopDashIsCooldown = false
    end)
end

local function LoopDashGetTorsoTarget()
    local char, _, myRoot = GetCharacterData()
    if not char or not myRoot then return nil end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}

    local parts = workspace:GetPartBoundsInRadius(myRoot.Position, LoopDashConfig.DashRange, params)
    local target = nil
    local dist = LoopDashConfig.DashRange

    for _, part in pairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model:FindFirstChildOfClass("Humanoid") and model ~= char then
            local torso = model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
            if torso then
                local d = (myRoot.Position - torso.Position).Magnitude
                if d < dist then
                    dist = d
                    target = torso
                end
            end
        end
    end
    return target
end

local function LoopDashStartRotation(torso)
    local char, hum, root = GetCharacterData()
    if not root or not hum or not torso or not torso.Parent then
        LoopDashIsExecuting = false
        return
    end

    local startT = os.clock()
    local flipped = false
    local forwardDir = (torso.Position - root.Position).Unit
    local sideVec = Vector3.new(-forwardDir.Z, 0, forwardDir.X)
    local bav = nil
    local ao = nil
    local att0 = nil

    hum.AutoRotate = false

    if LoopDashConfig.LoopDashMode == "BodyGyro" then
        bav = root:FindFirstChild("LoopDashBAV") or Instance.new("BodyAngularVelocity")
        bav.Name = "LoopDashBAV"
        bav.MaxTorque = Vector3.new(0, 1000000, 0)
        bav.P = 15000
        bav.AngularVelocity = Vector3.zero
        bav.Parent = root
    elseif LoopDashConfig.LoopDashMode == "AlignOrientation" then
        ao = root:FindFirstChild("LoopDashAO") or Instance.new("AlignOrientation")
        ao.Name = "LoopDashAO"
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.MaxTorque = 1000000
        ao.Responsiveness = 100

        att0 = root:FindFirstChild("LoopDashAtt") or Instance.new("Attachment", root)
        att0.Name = "LoopDashAtt"
        ao.Attachment0 = att0
        ao.Parent = root
    end

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not torso or not torso.Parent or not root or not root.Parent then
            if bav then bav:Destroy() end
            if ao then ao:Destroy() end
            if att0 then att0:Destroy() end
            LoopDashClip()
            LoopDashIsExecuting = false
            if conn then conn:Disconnect() end
            return
        end

        hum.AutoRotate = false

        local elapsed = os.clock() - startT
        local torsoPos, rootPos = torso.Position, root.Position

        if LoopDashConfig.LoopDashMode == "BodyGyro" then
            local angle = (elapsed / 0.45) * (math.pi / (LoopDashConfig.DashDuration / 1))
            local radius = LoopDashConfig.LoopDashAccuracy * (1 - math.clamp(elapsed / (LoopDashConfig.DashDuration * 0.3), 0, 1))
            local targetLookPos = torsoPos + (sideVec * math.cos(angle) + forwardDir * math.sin(angle)) * radius
            local lookAtCF = CFrame.lookAt(rootPos, Vector3.new(targetLookPos.X, rootPos.Y, targetLookPos.Z))
            local relativeCF = root.CFrame:Inverse() * lookAtCF
            local _, y, _ = relativeCF:ToEulerAnglesXYZ()
            if bav and bav.Parent then
                bav.AngularVelocity = Vector3.new(0, y * 30, 0)
            end
        elseif LoopDashConfig.LoopDashMode == "AlignOrientation" then
            local angle = (elapsed / 0.45) * (math.pi / (LoopDashConfig.DashDuration / 1))
            local radius = LoopDashConfig.LoopDashAccuracy * (1 - math.clamp(elapsed / (LoopDashConfig.DashDuration * 0.3), 0, 1))
            local targetLookPos = torsoPos + (sideVec * math.cos(angle) + forwardDir * math.sin(angle)) * radius
            if ao and ao.Parent then
                ao.CFrame = CFrame.lookAt(rootPos, Vector3.new(targetLookPos.X, rootPos.Y, targetLookPos.Z))
            end
        else
            if elapsed >= LoopDashConfig.LoopDashAccuracy and not flipped then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
                flipped = true
            end
        end

        local distXZ = (Vector2.new(rootPos.X, rootPos.Z) - Vector2.new(torsoPos.X, torsoPos.Z)).Magnitude
        if (LoopDashConfig.CancelEnabled and elapsed > LoopDashConfig.LoopDashCancelDelay and distXZ < 2.2) or elapsed > LoopDashConfig.DashDuration or not LoopDashConfig.Enabled then
            if bav then bav:Destroy() end
            if ao then ao:Destroy() end
            if att0 then att0:Destroy() end
            LoopDashForceCancel()
            LoopDashIsExecuting = false
            conn:Disconnect()
            return
        end
    end)
end

local function LoopDashUpdateCamSmooth(enabled)
    if LoopDashCamSmoothConn then
        LoopDashCamSmoothConn:Disconnect()
        LoopDashCamSmoothConn = nil
    end
    if not enabled then return end

    LoopDashCamSmoothConn = RunService.RenderStepped:Connect(function(dt)
        if not LoopDashIsExecuting then
            if LoopDash_wasAttachedByScript then
                local cam = Workspace.CurrentCamera
                if cam then
                    pcall(function()
                        cam.CameraType = LoopDash_prevCamType or Enum.CameraType.Custom
                        cam.CameraSubject = LoopDash_prevCamSubject or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
                        if LoopDash_prevCamCFrame then cam.CFrame = LoopDash_prevCamCFrame end
                    end)
                end
                LoopDash_wasAttachedByScript = false
            end
            return
        end

        local _, _, root = GetCharacterData()
        local cam = Workspace.CurrentCamera
        if not root or not cam then return end

        local rotatorObj = root:FindFirstChild("LoopDashBAV") or root:FindFirstChild("LoopDashAO")

        if rotatorObj then
            if not LoopDash_wasAttachedByScript then
                LoopDash_prevCamType = cam.CameraType
                LoopDash_prevCamSubject = cam.CameraSubject
                LoopDash_prevCamCFrame = cam.CFrame
                LoopDash_wasAttachedByScript = true
            end
            pcall(function()
                cam.CameraType = Enum.CameraType.Attach
                cam.CameraSubject = root
            end)
        else
            if LoopDash_wasAttachedByScript then
                pcall(function()
                    cam.CameraType = LoopDash_prevCamType or Enum.CameraType.Custom
                    cam.CameraSubject = LoopDash_prevCamSubject or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
                    if LoopDash_prevCamCFrame then cam.CFrame = LoopDash_prevCamCFrame end
                end)
                LoopDash_wasAttachedByScript = false
            end
            local targetPos = Vector3.new(root.Position.X, cam.CFrame.Position.Y, root.Position.Z)
            local targetCF = CFrame.lookAt(cam.CFrame.Position, targetPos)
            local alpha = 1 - math.exp(-0.04 * (dt or (1/60)) * 60)
            cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
        end
    end)
end

local function LoopDashExecute()
    if LoopDashIsExecuting or LoopDashIsCooldown then return end
    if not LoopDashConfig.Enabled then return end

    local char, _, root = GetCharacterData()
    if not root then return end

    local torso = LoopDashGetTorsoTarget()
    if not torso then LoopDashClip() return end

    LoopDashIsExecuting = true

    local preDashConn
    preDashConn = RunService.Heartbeat:Connect(function()
        if not LoopDashIsExecuting or not torso or not torso.Parent or not root or not root.Parent then
            if preDashConn then preDashConn:Disconnect() end
            return
        end
        local _, hum = GetCharacterData()
        if hum then hum.AutoRotate = false end
        root.CFrame = CFrame.lookAt(root.Position, Vector3.new(torso.Position.X, root.Position.Y, torso.Position.Z))
    end)

    task.spawn(function()
        if LoopDashConfig.JumpMode == "Normal" then
            local totalDelay = LoopDashConfig.LoopDashDelay
            task.wait(math.max(0, totalDelay - 0.03))
            if not torso.Parent or not root.Parent then
                if preDashConn then preDashConn:Disconnect() end
                LoopDashIsExecuting = false
                return
            end

            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, LoopDashConfig.LoopDashJump, root.AssemblyLinearVelocity.Z)
            LoopDashIsNoclipping = true

            task.wait(0.03)
            if not torso.Parent or not root.Parent then
                if preDashConn then preDashConn:Disconnect() end
                LoopDashIsExecuting = false
                return
            end

            if preDashConn then preDashConn:Disconnect() end
            FireDashQW()
            LoopDashStartRotation(torso)
        else
            task.spawn(function()
                task.wait(LoopDashConfig.JumpDelay)
                if LoopDashConfig.Enabled and root.Parent then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, LoopDashConfig.LoopDashJump, root.AssemblyLinearVelocity.Z)
                end
            end)

            task.wait(LoopDashConfig.LoopDashDelay)
            if not torso.Parent or not root.Parent then
                if preDashConn then preDashConn:Disconnect() end
                LoopDashIsExecuting = false
                return
            end

            if preDashConn then preDashConn:Disconnect() end
            LoopDashIsNoclipping = true
            FireDashQW()
            LoopDashStartRotation(torso)
        end
    end)
end

local function LoopDashOnAnimationPlayed(anim)
    local animId = LoopDashGetId(anim.Animation.AnimationId)
    if LoopDashConfig.CooldownActive and LoopDashConfig.CooldownAnims[animId] then
        LoopDashStartCooldown(5)
    end

    if not LoopDashConfig.Enabled then return end
    if animId and animId == LoopDashGetId(LoopDashConfig.loopReworkAnimDetectId) then
        LoopDashExecute()
    end
end

local function ConnectLoopDashCharacter()
    if LoopDashConfig.AnimConnection then LoopDashConfig.AnimConnection:Disconnect() end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    LoopDashConfig.AnimConnection = hum.AnimationPlayed:Connect(LoopDashOnAnimationPlayed)

    if LoopDashNoclipConn then LoopDashNoclipConn:Disconnect() end
    LoopDashNoclipConn = RunService.Stepped:Connect(function()
        if not LoopDashConfig.NoClipEnabled or not LoopDashIsNoclipping then return end
        local c = LocalPlayer.Character
        if c then
            for _, part in pairs(c:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local InstantLethalConfig = {
    Enabled = false,
    AnimationId = "rbxassetid://12296113986",
    Connection = nil,
    Smoothness = 0.22,
}

local function DoFlick()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if root and hum then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.pi, 0)
        local x, y, z = Camera.CFrame:ToEulerAnglesYXZ()
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(x, y + math.pi, z)
        hum.AutoRotate = false
        task.delay(0.4, function() if hum then hum.AutoRotate = true end end)
    end
end

local function DoJump()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(0, 64, 0) end
end

local function ConnectInstantLethal()
    if InstantLethalConfig.Connection then InstantLethalConfig.Connection:Disconnect() end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    InstantLethalConfig.Connection = hum.AnimationPlayed:Connect(function(anim)
        if InstantLethalConfig.Enabled and anim.Animation and anim.Animation.AnimationId == InstantLethalConfig.AnimationId then
            task.wait(1.72)
            DoJump()
            DoFlick()
            local char = LocalPlayer.Character
            if char then
                if char:FindFirstChild("Communicate") then
                    char.Communicate:FireServer(unpack({{Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}}))
                end
            end
            task.wait(InstantLethalConfig.Smoothness)
            DoFlick()
        end
    end)
end

local GojoTechConfig = {
    Enabled = false,
    StartYOffset = -10,
    EndYOffset = 10,
    FloatDuration = 0.7,
    QDelay = 0.04,
    GroundStabilizeTime = 0.00001,
    AutoMode = false,
    TargetAnimId = "rbxassetid://10503381238",
    IsTimerReady = true,
    Busy = false,
    AutoConnection = nil,
    TimerConnection = nil,
    PhaseConnection = nil,
    StabilizeConnection = nil,
}

local function GojoFireQ(char)
    local comm = char and char:FindFirstChild("Communicate")
    if comm then pcall(function() comm:FireServer({Dash = Enum.KeyCode.Q}) end) end
end

local function GojoFireDash(char)
    local comm = char and char:FindFirstChild("Communicate")
    if comm then pcall(function() comm:FireServer({Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}) end) end
end

local function GojoZeroFling(hrp)
    if hrp and hrp.Parent then
        local vel = hrp.AssemblyLinearVelocity
        hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function GojoZeroAll(hrp)
    if hrp and hrp.Parent then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
end

local function GojoFindTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local closest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < dist then dist = d closest = hrp end
            end
        end
    end
    return closest
end

local function GojoReturnToStart(hrp, hum, origHipH, startCF)
    if GojoTechConfig.StabilizeConnection then GojoTechConfig.StabilizeConnection:Disconnect() end
    if hum then hum.HipHeight = origHipH end
    if hrp and hrp.Parent then hrp.CFrame = startCF end
    GojoZeroAll(hrp)
    local t = tick()
    GojoTechConfig.StabilizeConnection = RunService.Heartbeat:Connect(function()
        if tick() - t >= GojoTechConfig.GroundStabilizeTime then
            GojoZeroAll(hrp)
            GojoTechConfig.StabilizeConnection:Disconnect()
            GojoTechConfig.StabilizeConnection = nil
            return
        end
        if hrp and hrp.Parent then hrp.CFrame = startCF end
        GojoZeroAll(hrp)
    end)
end

local function GojoStartFloat()
    if GojoTechConfig.Busy then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    GojoTechConfig.Busy = true
    GojoTechConfig.IsTimerReady = false

    local origHipH = hum.HipHeight
    GojoZeroFling(hrp)
    local target = GojoFindTarget()
    if not target then
        GojoTechConfig.Busy = false
        GojoTechConfig.IsTimerReady = true
        return
    end

    local startCF = hrp.CFrame
    GojoFireQ(char)
    task.delay(GojoTechConfig.QDelay, function()
        GojoFireDash(char)
        if GojoTechConfig.PhaseConnection then GojoTechConfig.PhaseConnection:Disconnect() end
        local startTime = tick()
        GojoTechConfig.PhaseConnection = RunService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            if elapsed >= GojoTechConfig.FloatDuration or not GojoTechConfig.Enabled then
                GojoTechConfig.PhaseConnection:Disconnect()
                GojoTechConfig.PhaseConnection = nil
                GojoReturnToStart(hrp, hum, origHipH, startCF)
                GojoTechConfig.Busy = false
                if GojoTechConfig.TimerConnection then GojoTechConfig.TimerConnection:Disconnect() end
                local cd = tick()
                GojoTechConfig.TimerConnection = RunService.Heartbeat:Connect(function()
                    if tick() - cd >= 5 then
                        GojoTechConfig.IsTimerReady = true
                        GojoTechConfig.TimerConnection:Disconnect()
                        GojoTechConfig.TimerConnection = nil
                    end
                end)
                return
            end
            local progress = elapsed / GojoTechConfig.FloatDuration
            local yOff = GojoTechConfig.StartYOffset + (GojoTechConfig.EndYOffset - GojoTechConfig.StartYOffset) * progress
            local tPos = target.Position
            if hrp and hrp.Parent then
                hrp.CFrame = CFrame.lookAt(Vector3.new(tPos.X, tPos.Y + yOff, tPos.Z), tPos)
            end
            GojoZeroFling(hrp)
        end)
    end)
end

local function GojoStartAutoDetect()
    if GojoTechConfig.AutoConnection then GojoTechConfig.AutoConnection:Disconnect() end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    GojoTechConfig.AutoConnection = hum.AnimationPlayed:Connect(function(track)
        if not GojoTechConfig.Enabled or not GojoTechConfig.AutoMode then return end        if track.Animation and tostring(track.Animation.AnimationId) == GojoTechConfig.TargetAnimId then
            if GojoTechConfig.IsTimerReady and not GojoTechConfig.Busy then
                task.spawn(GojoStartFloat)
            end
        end
    end)
end

local function ConnectGojoTech()
    GojoStartAutoDetect()
end

local AutoKyotoConfig = {
    Enabled = false,
    Speed = 8.6,
    AnimationDelay = 1.71,
    ExecutionDelay = 0.6,
    AnimationId = "rbxassetid://12273188754",
    Connection = nil,
    LastExecution = 0,
}

local function KyotoSendKey(down, key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(down, key, false, game)
    end)
end

local function ExecuteKyotoMovement()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    task.wait(AutoKyotoConfig.AnimationDelay)
    root.CFrame = root.CFrame + root.CFrame.LookVector * AutoKyotoConfig.Speed
    KyotoSendKey(true, Enum.KeyCode.D)
    KyotoSendKey(false, Enum.KeyCode.Q)
    KyotoSendKey(true, Enum.KeyCode.Q)
    KyotoSendKey(false, Enum.KeyCode.D)
    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(85), 0)
    pcall(function()
        local moveData = {
            {
                Tool = LocalPlayer:WaitForChild("Backpack"):WaitForChild("Lethal Whirlwind Stream"),
                Goal = "Console Move"
            }
        }
        char:WaitForChild("Communicate"):FireServer(unpack(moveData))
    end)
    cam.CameraType = Enum.CameraType.Custom
end

local function SetupKyotoListener(humanoid)
    if AutoKyotoConfig.Connection then AutoKyotoConfig.Connection:Disconnect() end
    if humanoid then
        AutoKyotoConfig.Connection = humanoid.AnimationPlayed:Connect(function(animTrack)
            if AutoKyotoConfig.Enabled then
                local success, animId = pcall(function()
                    return animTrack and (animTrack.Animation and tostring(animTrack.Animation.AnimationId)) or ""
                end)
                if success and animId == AutoKyotoConfig.AnimationId then
                    task.spawn(ExecuteKyotoMovement)
                end
            end
        end)
    end
end

local function OnKyotoCharacterSpawn(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        SetupKyotoListener(hum)
    end
end

local LethalDashConfig = {
    Enabled = false,
    AnimDetectId = "12296113986",
    WaitTime = 1.6,
    SnapDuration = 0.38,
    JumpPower = 62,
    LockDistance = 15,
    LerpStartAlpha = 0.32,
    LerpEndAlpha = 1,
    SmoothPower = 0.15,
    Connection = nil,
    Busy = false,
    LerpConnection = nil,
    SmoothConnection = nil,
    SmoothEnabled = false,
    LastCamCF = Camera.CFrame,
    Cooldown = 0.4,
}

RunService.RenderStepped:Connect(function()
    if not LethalDashConfig.Enabled or not LethalDashConfig.SmoothEnabled then return end
    local currentCF = Camera.CFrame
    LethalDashConfig.LastCamCF = LethalDashConfig.LastCamCF:Lerp(currentCF, LethalDashConfig.SmoothPower)
    Camera.CFrame = LethalDashConfig.LastCamCF
end)

local function LethalDashFindTarget()
    local liveFolder = Workspace:FindFirstChild("Live")
    if not liveFolder then return nil end

    local _, _, myRoot = GetCharacterData()
    if not myRoot then return nil end

    local closestTarget = nil
    local closestDist = LethalDashConfig.LockDistance

    for _, model in ipairs(liveFolder:GetChildren()) do
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            local targetRoot = model:FindFirstChild("HumanoidRootPart")
            local targetHum = model:FindFirstChildOfClass("Humanoid")
            if targetRoot and targetHum and targetHum.Health > 0 then
                local dist = (targetRoot.Position - myRoot.Position).Magnitude
                if dist <= LethalDashConfig.LockDistance and dist < closestDist then
                    closestDist = dist
                    closestTarget = targetRoot
                end
            end
        end
    end
    return closestTarget
end

local function LethalDashLockOntoTarget(target)
    if LethalDashConfig.LerpConnection then
        LethalDashConfig.LerpConnection:Disconnect()
        LethalDashConfig.LerpConnection = nil
    end

    local _, hum, root = GetCharacterData()
    if not (target and target.Parent and root and hum) then return end

    local startTime = tick()
    LethalDashConfig.LerpConnection = RunService.RenderStepped:Connect(function()
        if not LethalDashConfig.Enabled or (tick() - startTime) >= LethalDashConfig.SnapDuration or not target or not target.Parent or not root or not root.Parent then
            if hum then hum.AutoRotate = true end
            if LethalDashConfig.LerpConnection then
                LethalDashConfig.LerpConnection:Disconnect()
                LethalDashConfig.LerpConnection = nil
            end
            return
        end

        if hum then hum.AutoRotate = false end

        local myPos = root.Position
        local targetPos = target.Position
        local flatTarget = Vector3.new(targetPos.X, myPos.Y, targetPos.Z)
        local targetCF = CFrame.new(myPos, flatTarget)

        local progress = math.clamp((tick() - startTime) / LethalDashConfig.SnapDuration, LethalDashConfig.LerpStartAlpha, LethalDashConfig.LerpEndAlpha)
        local smooth = progress * progress * (3 - 2 * progress)

        root.CFrame = root.CFrame:Lerp(targetCF, smooth)
    end)
end

local function LethalDashExecute()
    if LethalDashConfig.Busy or not LethalDashConfig.Enabled then return end
    LethalDashConfig.Busy = true

    LethalDashConfig.SmoothEnabled = true
    LethalDashConfig.LastCamCF = Camera.CFrame
    task.delay(2, function()
        LethalDashConfig.SmoothEnabled = false
    end)

    task.wait(LethalDashConfig.WaitTime)

    if not LethalDashConfig.Enabled then LethalDashConfig.Busy = false return end

    local _, hum, root = GetCharacterData()
    if hum and root then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait()

        local currentVel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(currentVel.X, LethalDashConfig.JumpPower, currentVel.Z)

        FireDashQW()

        local target = LethalDashFindTarget()
        if target then
            task.delay(0.2, function()
                LethalDashLockOntoTarget(target)
            end)
        end
    end

    task.wait(LethalDashConfig.Cooldown)
    LethalDashConfig.Busy = false
end

local function LethalDashOnAnimation(animTrack)
    if not LethalDashConfig.Enabled then return end
    local success, animId = pcall(function()
        return animTrack and animTrack.Animation and tostring(animTrack.Animation.AnimationId) or ""
    end)
    if success and animId and animId:find(LethalDashConfig.AnimDetectId) then
        task.spawn(LethalDashExecute)
    end
end

local function ConnectLethalDash()
    if LethalDashConfig.Connection then LethalDashConfig.Connection:Disconnect() end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    LethalDashConfig.Connection = hum.AnimationPlayed:Connect(LethalDashOnAnimation)
end

local LixTechConfig = {
    Enabled = false,
    Delay = 0.3,
    AnimDetectIds = {"13379003796", "10503381238"},
    Connection = nil,
    Busy = false,
}

local function LixTechExecute()
    if LixTechConfig.Busy or not LixTechConfig.Enabled then return end
    LixTechConfig.Busy = true
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum and root then
        local originalSettings = {
            WalkSpeed = hum.WalkSpeed,
            JumpPower = hum.JumpPower,
            PlatformStand = hum.PlatformStand,
            AutoRotate = hum.AutoRotate
        }
        
        task.wait(LixTechConfig.Delay)
        
        if not LixTechConfig.Enabled then LixTechConfig.Busy = false return end
        
        FireDashQW()
        
        DeleteBodyVelocity()
        
        task.wait(0.3)
        
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(180), 0)
        end
        
        task.wait(0.4)
        
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(180), 0)
        end
        
        task.wait(0.5)
        if hum then
            hum.WalkSpeed = originalSettings.WalkSpeed or 16
            hum.JumpPower = originalSettings.JumpPower or 50
            hum.PlatformStand = originalSettings.PlatformStand or false
            hum.AutoRotate = originalSettings.AutoRotate or true
        end
    end
    
    LixTechConfig.Busy = false
end

local function LixTechOnAnimation(animTrack)
    if not LixTechConfig.Enabled then return end
    local success, animId = pcall(function()
        return animTrack and animTrack.Animation and tostring(animTrack.Animation.AnimationId) or ""
    end)
    if success and animId then
        for _, id in ipairs(LixTechConfig.AnimDetectIds) do
            if animId:find(id) then
                task.spawn(LixTechExecute)
                break
            end
        end
    end
end

local function ConnectLixTech()
    if LixTechConfig.Connection then LixTechConfig.Connection:Disconnect() end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    LixTechConfig.Connection = hum.AnimationPlayed:Connect(LixTechOnAnimation)
end

local SupaLegitConfig = {
    Enabled = false,
    DashDuration = 0.15,
    FollowOffset = 2.5,
    AngleTilt = 55,
    StickRange = 18,
    AnimDetectIds = {"10503381238", "13379003796"},
    CooldownTime = 4,
    AnimDelay = 0.3,
    Connection = nil,
    CharConnection = nil,
    Busy = false,
    InCooldown = false,
}

local SupaLegitCooldownBillboard = nil

local function SupaLegitShowCooldownIndicator(character, duration)
    if SupaLegitCooldownBillboard then SupaLegitCooldownBillboard:Destroy() end
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 60, 0, 15)
    billboard.Adornee = head
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 0.6, 0)
    txt.Position = UDim2.new(0, 0, 0, -8)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBlack
    txt.TextSize = 10
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.Parent = billboard

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, 0, 0, 3)
    barBg.Position = UDim2.new(0, 0, 1, -3)
    barBg.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
    barBg.BorderSizePixel = 0
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
    barBg.Parent = billboard

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    barFill.BorderSizePixel = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
    barFill.Parent = barBg

    local barGrad = Instance.new("UIGradient")
    barGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    })
    barGrad.Parent = barFill

    SupaLegitCooldownBillboard = billboard
    local start = tick()

    task.spawn(function()
        while tick() - start < duration do
            if not billboard.Parent then break end
            local elapsed = tick() - start
            local perc = 1 - (elapsed / duration)
            barFill.Size = UDim2.new(math.max(perc, 0), 0, 1, 0)
            txt.Text = string.format("%.1f", duration - elapsed)
            task.wait()
        end
        if billboard then billboard:Destroy() end
    end)
end

local function SupaLegitFindClosestTarget()
    local char, _, myRoot = GetCharacterData()
    if not myRoot then return nil end
    
    local closestModel = nil
    local smallestDistance = SupaLegitConfig.StickRange
    
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") and model ~= char then
            local targetRoot = model:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local success, distance = pcall(function()
                    return (myRoot.Position - targetRoot.Position).Magnitude
                end)
                if success and distance and distance < smallestDistance then
                    closestModel = model
                    smallestDistance = distance
                end
            end
        end
    end
    return closestModel
end

local function SupaLegitSendDashAndRemoveVelocity()
    FireDashQW()
    
    pcall(function()
        local function findNilInstanceByNameClass(name, className)
            if type(getnilinstances) ~= "function" then return nil end
            pcall(function()
                for _, inst in ipairs(getnilinstances()) do
                    if inst.ClassName == className and inst.Name == name then
                        return inst
                    end
                end
            end)
            return nil
        end
        
        local bv = findNilInstanceByNameClass("moveme", "BodyVelocity")
        if bv then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Communicate") then
                char.Communicate:FireServer({Goal = "delete bv", BV = bv})
            end
            pcall(function() bv.Parent = nil end)
        end
    end)
end

local function SupaLegitPerformStickDash()
    local char, hum, root = GetCharacterData()
    if not (char and hum and root) then return end
    
    local targetModel = SupaLegitFindClosestTarget()
    if not targetModel then return end
    
    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    local savedSettings = {
        WalkSpeed = hum.WalkSpeed,
        JumpPower = hum.JumpPower,
        PlatformStand = hum.PlatformStand,
        AutoRotate = hum.AutoRotate
    }
    
    local angleTiltRad = math.rad(SupaLegitConfig.AngleTilt)
    
    local heartbeatConnection = RunService.Heartbeat:Connect(function()
        if root then root.AssemblyLinearVelocity = Vector3.zero end
        if hum then hum.WalkSpeed = 0 end
    end)
    
    pcall(SupaLegitSendDashAndRemoveVelocity)
    
    task.wait(0.2)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
    
    if root then
        root.CFrame = root.CFrame * CFrame.Angles(angleTiltRad, 0, 0)
    end
    
    local startTime = tick()
    local followConnection = RunService.Heartbeat:Connect(function()
        if SupaLegitConfig.DashDuration > (tick() - startTime) then
            if targetRoot and targetRoot.Parent and root and root.Parent then
                local dir = (targetRoot.Position - root.Position).Unit
                local newPos = targetRoot.Position - dir * SupaLegitConfig.FollowOffset
                root.CFrame = CFrame.new(newPos) * CFrame.Angles(angleTiltRad, 0, 0)
            end
        end
    end)
    
    task.wait(SupaLegitConfig.DashDuration)
    
    heartbeatConnection:Disconnect()
    followConnection:Disconnect()
    
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        hum.WalkSpeed = savedSettings.WalkSpeed or 16
        hum.JumpPower = savedSettings.JumpPower or 50
        hum.AutoRotate = savedSettings.AutoRotate or true
    end)
end

local function SupaLegitOnAnimation(animTrack)
    if not SupaLegitConfig.Enabled or SupaLegitConfig.Busy or SupaLegitConfig.InCooldown then return end
    
    local success, animId = pcall(function()
        return animTrack and animTrack.Animation and tostring(animTrack.Animation.AnimationId) or ""
    end)
    
    if success and animId then
        for _, id in ipairs(SupaLegitConfig.AnimDetectIds) do
            if animId:find(id) then
                task.delay(SupaLegitConfig.AnimDelay, function()
                    if not SupaLegitConfig.Enabled or SupaLegitConfig.Busy or SupaLegitConfig.InCooldown then return end
                    SupaLegitConfig.InCooldown = true
                    SupaLegitConfig.Busy = true
                    
                    local char = LocalPlayer.Character
                    if char then task.spawn(function() SupaLegitShowCooldownIndicator(char, SupaLegitConfig.CooldownTime) end) end
                    
                    task.spawn(function()
                        SupaLegitPerformStickDash()
                        SupaLegitConfig.Busy = false
                        task.wait(SupaLegitConfig.CooldownTime)
                        SupaLegitConfig.InCooldown = false
                    end)
                end)
                break
            end
        end
    end
end

local function ConnectSupaLegit()
    if SupaLegitConfig.Connection then
        SupaLegitConfig.Connection:Disconnect()
        SupaLegitConfig.Connection = nil
    end
    
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    
    SupaLegitConfig.Connection = hum.AnimationPlayed:Connect(SupaLegitOnAnimation)
end

local K1ngTechConfig = {
    Enabled = false,
    DetectDelay = 0.249,
    StartDelay = 0,
    WaitTime = 0.15,
    VeloPower = 56.7,
    CooldownTime = 3,
    OnCooldown = false,
    Busy = false,
    CooldownGui = nil,
    UppercutAnims = {
        ["rbxassetid://10503381238"] = true,
        ["rbxassetid://13379003796"] = true,
    },
    DetectAnims = {
        ["rbxassetid://10479335397"] = true,
        ["rbxassetid://13380255751"] = true,
    },
    Connection = nil,
    CharConnection = nil,
}

local function K1ngPressDashKey()
    local char = LocalPlayer.Character
    if char then
        local remote = ReplicatedStorage:FindFirstChild("Resources")
        if remote then
            remote = remote:FindFirstChild("Brother")
            if remote then
                remote = remote["#Friend"]
                if remote then
                    remote = remote:FindFirstChild("Communicate")
                    if remote then
                        pcall(function()
                            remote:FireServer({[1] = {Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress"}})
                        end)
                    end
                end
            end
        end
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
    end)
end

local function K1ngPerformJump()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, K1ngTechConfig.VeloPower, root.AssemblyLinearVelocity.Z)
    end
end

local function K1ngPerformFlip()
    local char = LocalPlayer.Character
    if not char or not Camera then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and root then
        hum.AutoRotate = false
        local flippedCF = root.CFrame * CFrame.Angles(0, math.rad(180), 0)
        root.CFrame = flippedCF
        local distance = (Camera.CFrame.Position - flippedCF.Position).Magnitude
        Camera.CFrame = CFrame.new(flippedCF.Position - flippedCF.LookVector * distance + Vector3.new(0, 2), flippedCF.Position)
    end
end

local function K1ngShowCooldownIndicator(duration)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if K1ngTechConfig.CooldownGui then
        K1ngTechConfig.CooldownGui:Destroy()
        K1ngTechConfig.CooldownGui = nil
    end
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 0, 0, 0)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = root
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, 0, 1, 0)
    progress.BorderSizePixel = 0
    progress.Parent = bg
    Instance.new("UICorner", progress).CornerRadius = UDim.new(0, 6)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 100))
    }
    grad.Parent = progress
    K1ngTechConfig.CooldownGui = billboard
    TweenService:Create(billboard, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(4, 0, 0.5, 0)}):Play()
    local start = tick()
    while tick() - start < duration do
        local elapsed = tick() - start
        local percent = elapsed / duration
        progress.Size = UDim2.new(1 - percent, 0, 1, 0)
        RunService.RenderStepped:Wait()
    end
    local hide = TweenService:Create(billboard, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 0)})
    hide:Play()
    hide.Completed:Wait()
    if K1ngTechConfig.CooldownGui then
        K1ngTechConfig.CooldownGui:Destroy()
        K1ngTechConfig.CooldownGui = nil
    end
end

local function K1ngOnAnimationPlayed(animTrack)
    if not K1ngTechConfig.Enabled then return end
    if not animTrack or not animTrack.Animation then return end
    local animId = animTrack.Animation.AnimationId
    if K1ngTechConfig.DetectAnims[animId] then
        if K1ngTechConfig.OnCooldown then return end
        K1ngTechConfig.OnCooldown = true
        task.delay(0.8, function()
            K1ngShowCooldownIndicator(K1ngTechConfig.CooldownTime)
        end)
        task.delay(K1ngTechConfig.CooldownTime + 0.8, function()
            K1ngTechConfig.OnCooldown = false
        end)
        return
    end
    if K1ngTechConfig.UppercutAnims[animId] and not K1ngTechConfig.OnCooldown then
        local triggerTime = tick()
        task.delay(K1ngTechConfig.DetectDelay, function()
            if K1ngTechConfig.Busy or not K1ngTechConfig.Enabled or K1ngTechConfig.OnCooldown or tick() - triggerTime > 0.4 then
                return
            end
            local char = LocalPlayer.Character
            if not char then return end
            local myRoot = char:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            local live = workspace:FindFirstChild("Live")
            if not live then return end
            local target = nil
            local bestDist = 18
            for _, model in ipairs(live:GetChildren()) do
                if model ~= char then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        local d = (hrp.Position - myRoot.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            target = hrp
                        end
                    end
                end
            end
            if not target then return end
            K1ngTechConfig.Busy = true
            task.delay(K1ngTechConfig.StartDelay, function()
                K1ngPressDashKey()
                K1ngPerformJump()
                task.wait(K1ngTechConfig.WaitTime)
                K1ngPerformFlip()
                task.wait(0.08)
                K1ngPerformFlip()
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    TweenService:Create(root, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        CFrame = root.CFrame + (root.CFrame.LookVector * 7)
                    }):Play()
                end
            end)
            task.delay(0.8, function()
                K1ngTechConfig.Busy = false
            end)
        end)
    end
end

local function ConnectK1ngTech()
    if K1ngTechConfig.Connection then
        K1ngTechConfig.Connection:Disconnect()
        K1ngTechConfig.Connection = nil
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    K1ngTechConfig.Connection = hum.AnimationPlayed:Connect(K1ngOnAnimationPlayed)
    if not K1ngTechConfig.CharConnection then
        K1ngTechConfig.CharConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            if K1ngTechConfig.Enabled then
                task.wait(0.5)
                ConnectK1ngTech()
            end
        end)
    end
end

local InstantTwistedV2Config = {
    Enabled = false,
    DashDuration = 0.6,
    Delay = 0.237,
    NoclipEnabled = true,
    TweenBackDist = 6,
    TweenSpeed = 1,
    NoclipRange = 10,
    AimRange = 10,
    Angle1 = 100,
    Angle2 = 160,
    Angle3 = 60,
    Angle4 = 0,
    TwistDelay = 0.1,
    MenuKey = Enum.KeyCode.L,
    Connection = nil,
    CharConnection = nil,
    AnimConnection = nil,
}

local function InstantTwistedV2_applyTwist(root, hum)
    local att = Instance.new("Attachment", root)
    local align = Instance.new("AlignOrientation", root)
    
    align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    align.Attachment0 = att
    align.RigidityEnabled = false
    align.MaxTorque = 1000000
    align.Responsiveness = 60
    
    local forceOff = RunService.Heartbeat:Connect(function()
        hum.AutoRotate = false
    end)
    
    local function setAngle(angle)
        align.CFrame = root.CFrame * CFrame.Angles(0, math.rad(angle), 0)
    end

    setAngle(-InstantTwistedV2Config.Angle1)
    task.wait(InstantTwistedV2Config.TwistDelay)
    if align and align.Parent then setAngle(InstantTwistedV2Config.Angle2) end
    task.wait(InstantTwistedV2Config.TwistDelay)
    if align and align.Parent then setAngle(-InstantTwistedV2Config.Angle3) end
    task.wait(InstantTwistedV2Config.TwistDelay)
    if align and align.Parent then setAngle(InstantTwistedV2Config.Angle4) end
    
    task.wait(InstantTwistedV2Config.DashDuration - (InstantTwistedV2Config.TwistDelay * 3))
    
    forceOff:Disconnect()
    align:Destroy()
    att:Destroy()
    hum.AutoRotate = true
end

local function InstantTwistedV2_getClosestTarget()
    local targetPos, dist = nil, InstantTwistedV2Config.AimRange
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local tHum = p.Character:FindFirstChild("Humanoid")
            if tRoot and tHum and tHum.Health > 0 then
                local d = (root.Position - tRoot.Position).Magnitude
                if d < dist then
                    dist = d
                    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
                    local velocity = tRoot.Velocity
                    local predictionTime = math.clamp(ping, 0, 0.2)
                    targetPos = tRoot.Position + (Vector3.new(velocity.X, 0, velocity.Z) * predictionTime)
                end
            end
        end
    end
    return targetPos
end

local InstantTwistedV2_noclipConnection = nil
local function InstantTwistedV2_setNoclip(state)
    if state and InstantTwistedV2Config.NoclipEnabled then
        if InstantTwistedV2_noclipConnection then InstantTwistedV2_noclipConnection:Disconnect() end
        InstantTwistedV2_noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart
            local params = OverlapParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char}
            local nearbyParts = workspace:GetPartBoundsInRadius(root.Position, InstantTwistedV2Config.NoclipRange, params)
            for _, part in pairs(nearbyParts) do
                if part:FindFirstAncestorOfClass("Model") and part.Parent:FindFirstChild("Humanoid") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if InstantTwistedV2_noclipConnection then InstantTwistedV2_noclipConnection:Disconnect() end
        InstantTwistedV2_noclipConnection = nil
    end
end

local function InstantTwistedV2_executeDash()
    local char = LocalPlayer.Character
    local comms = char and char:FindFirstChild("Communicate")
    if comms then
        comms:FireServer({["Dash"] = Enum.KeyCode.W, ["Key"] = Enum.KeyCode.Q, ["Goal"] = "KeyPress"})
    end
end

local function InstantTwistedV2_onAnimation(track)
    if not InstantTwistedV2Config.Enabled then return end
    if track.Animation.AnimationId == "rbxassetid://13294471966" then
        local targetPos = InstantTwistedV2_getClosestTarget()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if targetPos and hum and root then
            hum.AutoRotate = false
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
        end
        task.spawn(function()
            InstantTwistedV2_setNoclip(true)
            task.wait(InstantTwistedV2Config.Delay)
            InstantTwistedV2_executeDash()
            if hum and root then
                InstantTwistedV2_applyTwist(root, hum)
            end
            task.wait(InstantTwistedV2Config.DashDuration)
            InstantTwistedV2_setNoclip(false)
        end)
    end
end

local function ConnectInstantTwistedV2()
    if InstantTwistedV2Config.AnimConnection then
        InstantTwistedV2Config.AnimConnection:Disconnect()
        InstantTwistedV2Config.AnimConnection = nil
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    InstantTwistedV2Config.AnimConnection = hum.AnimationPlayed:Connect(InstantTwistedV2_onAnimation)
    if not InstantTwistedV2Config.CharConnection then
        InstantTwistedV2Config.CharConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            if InstantTwistedV2Config.Enabled then
                task.wait(0.5)
                ConnectInstantTwistedV2()
            end
        end)
    end
end

local BoomyLethalConfig = {
    Enabled = false,
    WaitDetect = 3.2,
    WaitJump = 0,
    WaitRemote = 1,
    LockDuration = 9.7,
    TargetRadius = 67.7,
    Cooldown = 10,
    Responsiveness = 857,
    InitialDelay = 13,
    ForceJumpUpwardVelocity = 68,
    CancelEnabled = true,
    LoopDashCancelDelay = 0.4,
    LoopDashAccuracy = 15,
    DashDuration = 1.5,
    FlickEnabled = false,
    FlickDelay = 0.2,
    LoopDashMode = "V1",
    Connection = nil,
    CharConnection = nil,
    BlockConnection = nil,
    Debounce = false,
    Blocked = false,
    IsExecuting = false,
    LockCancel = nil,
    CurrentLock = nil,
}

local function BoomyLethal_getCharacter()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart then
            return character, humanoid, rootPart
        end
    end
    return nil, nil, nil
end

local function BoomyLethal_forceCancel()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        for _, object in pairs(rootPart:GetChildren()) do
            if object:IsA("BodyVelocity") or object:IsA("LinearVelocity") or object:IsA("BodyAngularVelocity") or object:IsA("AlignOrientation") then
                object:Destroy()
            elseif object:IsA("Attachment") and object.Name == "BoomyLethalAtt" then
                object:Destroy()
            end
        end
        pcall(function()
            rootPart.AssemblyLinearVelocity = Vector3.zero
        end)
    end
    local character, humanoid = BoomyLethal_getCharacter()
    if humanoid then
        pcall(function()
            humanoid.AutoRotate = true
        end)
    end
end

local function BoomyLethal_fireDash()
    local character = LocalPlayer.Character
    if character then
        local communicate = character:FindFirstChild("Communicate")
        if communicate and (typeof(communicate.FireServer) == "function" or type(communicate.FireServer) == "function") then
            local args = {{
                Dash = Enum.KeyCode.W,
                Key = Enum.KeyCode.Q,
                Goal = "KeyPress"
            }}
            pcall(function()
                communicate:FireServer(unpack(args))
            end)
        end
    end
end

local function BoomyLethal_findBestTarget(radius)
    radius = radius or BoomyLethalConfig.TargetRadius
    local live = Workspace:FindFirstChild("Live")
    if not live then return nil end

    local character, humanoid, rootPart = BoomyLethal_getCharacter()
    if not rootPart then return nil end

    local bestTarget = nil
    local bestDistance = radius

    for _, model in ipairs(live:GetChildren()) do
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            local targetRoot = model:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
                local isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
                if isPlayer or model.Name == "Weakest Dummy" then
                    local distance = (targetRoot.Position - rootPart.Position).Magnitude
                    if distance <= bestDistance then
                        bestTarget = targetRoot
                        bestDistance = distance
                    end
                end
            end
        end
    end
    return bestTarget
end

local function BoomyLethal_startRotation(target, duration)
    if not target or not target.Parent then return nil end

    local character, humanoid, rootPart = BoomyLethal_getCharacter()
    if not rootPart or not humanoid then return nil end

    local startTime = os.clock()
    local flipped = false
    local forwardDirection = (target.Position - rootPart.Position).Unit
    local sideVector = Vector3.new(-forwardDirection.Z, 0, forwardDirection.X)
    local bodyAngularVelocity = nil
    local alignOrientation = nil
    local attachment0 = nil

    local duration = duration or BoomyLethalConfig.DashDuration
    local accuracy = BoomyLethalConfig.LoopDashAccuracy
    local mode = BoomyLethalConfig.LoopDashMode

    humanoid.AutoRotate = false

    if mode == "BodyGyro" then
        bodyAngularVelocity = rootPart:FindFirstChild("BoomyLethalBAV") or Instance.new("BodyAngularVelocity")
        bodyAngularVelocity.Name = "BoomyLethalBAV"
        bodyAngularVelocity.MaxTorque = Vector3.new(0, 1000000, 0)
        bodyAngularVelocity.P = 15000
        bodyAngularVelocity.AngularVelocity = Vector3.zero
        bodyAngularVelocity.Parent = rootPart
    elseif mode == "AlignOrientation" then
        alignOrientation = rootPart:FindFirstChild("BoomyLethalAO") or Instance.new("AlignOrientation")
        alignOrientation.Name = "BoomyLethalAO"
        alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        alignOrientation.MaxTorque = 1000000
        alignOrientation.Responsiveness = 100

        attachment0 = rootPart:FindFirstChild("BoomyLethalAtt") or Instance.new("Attachment", rootPart)
        attachment0.Name = "BoomyLethalAtt"
        alignOrientation.Attachment0 = attachment0
        alignOrientation.Parent = rootPart
    end

    local cancelEnabled = BoomyLethalConfig.CancelEnabled
    local cancelDelay = BoomyLethalConfig.LoopDashCancelDelay

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not target or not target.Parent or not rootPart or not rootPart.Parent then
            if bodyAngularVelocity then bodyAngularVelocity:Destroy() end
            if alignOrientation then alignOrientation:Destroy() end
            if attachment0 then attachment0:Destroy() end
            BoomyLethal_forceCancel()
            BoomyLethalConfig.IsExecuting = false
            if connection then connection:Disconnect() end
            return
        end

        humanoid.AutoRotate = false

        local elapsed = os.clock() - startTime
        local targetPosition = target.Position
        local rootPosition = rootPart.Position

        if mode == "BodyGyro" then
            if not BoomyLethalConfig.FlickEnabled or elapsed >= BoomyLethalConfig.FlickDelay then
                local calculatedElapsed = BoomyLethalConfig.FlickEnabled and (elapsed - BoomyLethalConfig.FlickDelay) or elapsed
                local angle = (calculatedElapsed / 0.45) * (math.pi / (duration / 1))
                local radius = accuracy * (1 - math.clamp(calculatedElapsed / (duration * 0.3), 0, 1))
                local targetLookPosition = targetPosition + (sideVector * math.cos(angle) + forwardDirection * math.sin(angle)) * radius
                local lookAtCFrame = CFrame.lookAt(rootPosition, Vector3.new(targetLookPosition.X, rootPosition.Y, targetLookPosition.Z))
                local relativeCFrame = rootPart.CFrame:Inverse() * lookAtCFrame
                local _, yRotation, _ = relativeCFrame:ToEulerAnglesXYZ()
                if bodyAngularVelocity and bodyAngularVelocity.Parent then
                    bodyAngularVelocity.AngularVelocity = Vector3.new(0, yRotation * 30, 0)
                end
            else
                if bodyAngularVelocity and bodyAngularVelocity.Parent then
                    bodyAngularVelocity.AngularVelocity = Vector3.zero
                end
            end
        elseif mode == "AlignOrientation" then
            if not BoomyLethalConfig.FlickEnabled or elapsed >= BoomyLethalConfig.FlickDelay then
                local calculatedElapsed = BoomyLethalConfig.FlickEnabled and (elapsed - BoomyLethalConfig.FlickDelay) or elapsed
                local angle = (calculatedElapsed / 0.45) * (math.pi / (duration / 1))
                local radius = accuracy * (1 - math.clamp(calculatedElapsed / (duration * 0.3), 0, 1))
                local targetLookPosition = targetPosition + (sideVector * math.cos(angle) + forwardDirection * math.sin(angle)) * radius
                if alignOrientation and alignOrientation.Parent then
                    alignOrientation.CFrame = CFrame.lookAt(rootPosition, Vector3.new(targetLookPosition.X, rootPosition.Y, targetLookPosition.Z))
                end
            end
        else
            if elapsed >= accuracy and not flipped then
                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.pi, 0)
                flipped = true
            end
        end

        local distanceXZ = (Vector2.new(rootPosition.X, rootPosition.Z) - Vector2.new(targetPosition.X, targetPosition.Z)).Magnitude

        if (cancelEnabled and elapsed > cancelDelay and distanceXZ < 2.2) or elapsed > duration or not BoomyLethalConfig.Enabled then
            if bodyAngularVelocity then bodyAngularVelocity:Destroy() end
            if alignOrientation then alignOrientation:Destroy() end
            if attachment0 then attachment0:Destroy() end
            BoomyLethal_forceCancel()
            BoomyLethalConfig.IsExecuting = false
            connection:Disconnect()
            return
        end
    end)

    return function()
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
        if bodyAngularVelocity then bodyAngularVelocity:Destroy() end
        if alignOrientation then alignOrientation:Destroy() end
        if attachment0 then attachment0:Destroy() end
        BoomyLethal_forceCancel()
        BoomyLethalConfig.IsExecuting = false
    end
end

local function BoomyLethal_startHorizontalLockLerp(target, duration, responsiveness)
    if not target or not target.Parent then return nil end

    local character, humanoid, rootPart = BoomyLethal_getCharacter()
    if not rootPart or not humanoid then return nil end

    local response = responsiveness or BoomyLethalConfig.Responsiveness
    response = math.clamp(response, 1, 10000)

    local startTime = tick()
    local connection = nil

    connection = RunService.RenderStepped:Connect(function(deltaTime)
        if not target or not target.Parent then
            if connection then connection:Disconnect() end
            return
        end

        local currentCharacter, currentHumanoid, currentRoot = BoomyLethal_getCharacter()
        if not currentRoot or not currentHumanoid then
            if connection then connection:Disconnect() end
            return
        end

        local targetPosition = Vector3.new(target.Position.X, currentRoot.Position.Y, target.Position.Z)
        local difference = (targetPosition - currentRoot.Position).Magnitude

        if difference >= 0.001 then
            local lookCFrame = CFrame.new(currentRoot.Position, targetPosition)
            local alpha
            if response < 1000 then
                local exponentialFactor = 1 - math.exp(-0.02 * response * deltaTime)
                alpha = math.clamp(exponentialFactor, 0, 1)
            else
                alpha = 1
            end

            if alpha >= 0.999999 then
                pcall(function()
                    currentRoot.CFrame = lookCFrame
                end)
            else
                local lerped = currentRoot.CFrame:Lerp(lookCFrame, alpha)
                local newCFrame = CFrame.new(currentRoot.Position) * CFrame.fromMatrix(Vector3.new(), lerped.RightVector, lerped.UpVector)
                pcall(function()
                    currentRoot.CFrame = newCFrame
                end)
            end
        end

        if tick() - startTime >= duration then
            if connection then connection:Disconnect() end
        end
    end)

    return function()
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
end

local function BoomyLethal_cancelActiveLockAndRestore()
    if BoomyLethalConfig.LockCancel then
        pcall(BoomyLethalConfig.LockCancel)
        BoomyLethalConfig.LockCancel = nil
    end
    if BoomyLethalConfig.CurrentLock then
        pcall(BoomyLethalConfig.CurrentLock)
        BoomyLethalConfig.CurrentLock = nil
    end
    local character, humanoid = BoomyLethal_getCharacter()
    if humanoid then
        pcall(function()
            humanoid.AutoRotate = true
        end)
    end
    BoomyLethalConfig.IsExecuting = false
    BoomyLethal_forceCancel()
end

local function BoomyLethal_runSequence()
    if BoomyLethalConfig.Debounce or not BoomyLethalConfig.Enabled or BoomyLethalConfig.Blocked then return end
    BoomyLethalConfig.Debounce = true
    BoomyLethalConfig.IsExecuting = true

    local waitDetect = BoomyLethalConfig.WaitDetect / 10
    local waitJump = BoomyLethalConfig.WaitJump / 10
    local waitRemote = BoomyLethalConfig.WaitRemote / 10
    local lockDuration = BoomyLethalConfig.LockDuration / 10
    local cooldown = BoomyLethalConfig.Cooldown / 10
    local initialDelay = BoomyLethalConfig.InitialDelay / 10
    local jumpPower = BoomyLethalConfig.ForceJumpUpwardVelocity
    local responsiveness = BoomyLethalConfig.Responsiveness
    local targetRadius = BoomyLethalConfig.TargetRadius

    if responsiveness >= 1000 then
        lockDuration = math.max(lockDuration * 0.5, 0.1)
    end

    local startTime = tick()
    while tick() - startTime < initialDelay do
        if not BoomyLethalConfig.Enabled or BoomyLethalConfig.Blocked then
            BoomyLethalConfig.Debounce = false
            BoomyLethalConfig.IsExecuting = false
            return
        end
        RunService.Heartbeat:Wait()
    end

    local detectStart = tick()
    while tick() - detectStart < waitDetect do
        if not BoomyLethalConfig.Enabled or BoomyLethalConfig.Blocked then
            BoomyLethalConfig.Debounce = false
            BoomyLethalConfig.IsExecuting = false
            return
        end
        RunService.Heartbeat:Wait()
    end

    local character, humanoid, rootPart = BoomyLethal_getCharacter()
    if not humanoid or not rootPart then
        BoomyLethalConfig.Debounce = false
        BoomyLethalConfig.IsExecuting = false
        return
    end

    local oldAutoRotate = nil
    pcall(function()
        oldAutoRotate = humanoid.AutoRotate
    end)

    pcall(function()
        humanoid.AutoRotate = false
    end)

    pcall(function()
        humanoid.Jump = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)

    pcall(function()
        if rootPart and rootPart.Parent then
            local velocity = rootPart.AssemblyLinearVelocity
            rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpPower, velocity.Z)
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, jumpPower, rootPart.Velocity.Z)
        end
    end)

    local jumpStart = tick()
    while tick() - jumpStart < waitJump do
        if not BoomyLethalConfig.Enabled or BoomyLethalConfig.Blocked then
            pcall(function()
                if humanoid and humanoid.Parent and oldAutoRotate ~= nil then
                    humanoid.AutoRotate = oldAutoRotate
                end
            end)
            BoomyLethalConfig.Debounce = false
            BoomyLethalConfig.IsExecuting = false
            return
        end
        RunService.Heartbeat:Wait()
    end

    BoomyLethal_fireDash()

    local remoteStart = tick()
    while tick() - remoteStart < waitRemote do
        if not BoomyLethalConfig.Enabled or BoomyLethalConfig.Blocked then
            pcall(function()
                if humanoid and humanoid.Parent and oldAutoRotate ~= nil then
                    humanoid.AutoRotate = oldAutoRotate
                end
            end)
            BoomyLethalConfig.Debounce = false
            BoomyLethalConfig.IsExecuting = false
            return
        end
        RunService.Heartbeat:Wait()
    end

    local target = BoomyLethal_findBestTarget(targetRadius)
    local lock = nil

    if target and not BoomyLethalConfig.Blocked then
        local rotationDuration = BoomyLethalConfig.DashDuration
        BoomyLethalConfig.CurrentLock = BoomyLethal_startRotation(target, rotationDuration)
        lock = BoomyLethal_startHorizontalLockLerp(target, lockDuration, responsiveness)
        BoomyLethalConfig.LockCancel = lock
    end

    local lockEndTime = tick() + math.max(lockDuration, 1.2)
    task.spawn(function()
        while tick() < lockEndTime and BoomyLethalConfig.Enabled and not BoomyLethalConfig.Blocked do
            pcall(function()
                local currentCharacter, currentHumanoid = BoomyLethal_getCharacter()
                if currentHumanoid and currentHumanoid.Parent then
                    currentHumanoid.AutoRotate = false
                end
            end)
            RunService.Heartbeat:Wait()
        end
        pcall(function()
            local currentCharacter, currentHumanoid = BoomyLethal_getCharacter()
            if currentHumanoid and currentHumanoid.Parent and oldAutoRotate ~= nil then
                currentHumanoid.AutoRotate = oldAutoRotate
            end
        end)
        BoomyLethalConfig.IsExecuting = false
    end)

    task.delay(lockDuration, function()
        if lock then
            pcall(lock)
            BoomyLethalConfig.LockCancel = nil
        end
        if BoomyLethalConfig.CurrentLock then
            pcall(BoomyLethalConfig.CurrentLock)
            BoomyLethalConfig.CurrentLock = nil
        end
        BoomyLethalConfig.IsExecuting = false
    end)

    task.delay(cooldown, function()
        BoomyLethalConfig.Debounce = false
    end)
end

local function BoomyLethal_onAnimation(track)
    if not BoomyLethalConfig.Enabled or BoomyLethalConfig.Debounce or BoomyLethalConfig.Blocked then return end
    if track and track.Animation then
        local id = tostring(track.Animation.AnimationId or "")
        if id == "rbxassetid://12296113986" or id:find("12296113986", 1, true) then
            task.spawn(BoomyLethal_runSequence)
        end
    end
end

local function BoomyLethal_connect()
    if BoomyLethalConfig.Connection then
        BoomyLethalConfig.Connection:Disconnect()
        BoomyLethalConfig.Connection = nil
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    BoomyLethalConfig.Connection = hum.AnimationPlayed:Connect(BoomyLethal_onAnimation)
    if not BoomyLethalConfig.CharConnection then
        BoomyLethalConfig.CharConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            if BoomyLethalConfig.Enabled then
                task.wait(0.5)
                BoomyLethal_connect()
            end
        end)
    end
end

local TwistedConfig = {
    Enabled = false,
    AnimDetectIds = {"13294471966", "134775406437626"},
    Connection = nil,
    Busy = false,
    AutoRotateConnection = nil,
}

local function TwistedExecute()
    if TwistedConfig.Busy or not TwistedConfig.Enabled then return end
    TwistedConfig.Busy = true
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if hum and root then
        if TwistedConfig.AutoRotateConnection then
            TwistedConfig.AutoRotateConnection:Disconnect()
        end
        
        TwistedConfig.AutoRotateConnection = RunService.RenderStepped:Connect(function()
            if TwistedConfig.Enabled and hum then
                hum.AutoRotate = false
            end
        end)
        
        local rotatedCF1 = root.CFrame * CFrame.Angles(0, math.rad(-135), 0)
        local rotatedCF2 = root.CFrame * CFrame.Angles(0, math.rad(0), 0)
        
        task.wait(0.39)
        
        if not TwistedConfig.Enabled then
            if TwistedConfig.AutoRotateConnection then TwistedConfig.AutoRotateConnection:Disconnect() end
            TwistedConfig.Busy = false
            return
        end
        
        FireDashQW()
        
        if root then root.CFrame = rotatedCF1 end
        task.wait(0.125)
        if root then root.CFrame = rotatedCF2 end
        task.wait(0.8)
        
        if TwistedConfig.AutoRotateConnection then
            TwistedConfig.AutoRotateConnection:Disconnect()
            TwistedConfig.AutoRotateConnection = nil
        end
        
        if hum then hum.AutoRotate = true end
    end
    
    TwistedConfig.Busy = false
end

local function TwistedOnAnimation(animTrack)
    if not TwistedConfig.Enabled then return end
    local success, animId = pcall(function()
        return animTrack and animTrack.Animation and tostring(animTrack.Animation.AnimationId) or ""
    end)
    if success and animId then
        for _, id in ipairs(TwistedConfig.AnimDetectIds) do
            if animId:find(id) then
                task.spawn(TwistedExecute)
                break
            end
        end
    end
end

local function ConnectTwisted()
    if TwistedConfig.Connection then TwistedConfig.Connection:Disconnect() end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    TwistedConfig.Connection = hum.AnimationPlayed:Connect(TwistedOnAnimation)
end

local InstantTwistedWiseDirConfig = {
    Enabled = false,
    DashWait = 0.23,
    AfterDash = 0.02,
    TurnTime = 0.025,
    StayLeft = 0.07,
    LockTime = 0.15,
    Predict = 0.22,
    MaxDist = 100,
    TurnDeg = -87,
    AnimConnection = nil,
    CharConnection = nil,
    RotateConn = nil,
    GyroLock = nil,
    DoingTheThing = false,
}

local ITWDAnimIds = {
    "rbxassetid://13294471966",
    "rbxassetid://134775406437626"
}

local function ITWDGetPing()
    local Stats = game:GetService("Stats")
    local ok, pingStat = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]
    end)
    if ok and pingStat then
        return math.floor(pingStat:GetValue())
    end
    return 0
end

local function ITWDAutoConfigByPing(ping)
    if ping <= 60 then
        InstantTwistedWiseDirConfig.DashWait = 0.15
        InstantTwistedWiseDirConfig.Predict  = 0.18
        InstantTwistedWiseDirConfig.LockTime = 0.12
    elseif ping <= 120 then
        InstantTwistedWiseDirConfig.DashWait = 0.2
        InstantTwistedWiseDirConfig.Predict  = 0.22
        InstantTwistedWiseDirConfig.LockTime = 0.15
    elseif ping <= 200 then
        InstantTwistedWiseDirConfig.DashWait = 0.25
        InstantTwistedWiseDirConfig.Predict  = 0.28
        InstantTwistedWiseDirConfig.LockTime = 0.18
    else
        InstantTwistedWiseDirConfig.DashWait = 0.3
        InstantTwistedWiseDirConfig.Predict  = 0.35
        InstantTwistedWiseDirConfig.LockTime = 0.22
    end
end

local function ITWDFindClosest(root)
    local closest  = nil
    local bestDist = math.huge
    local liveFolder = Workspace:FindFirstChild("Live")
    if not liveFolder then return nil end
    for _, obj in ipairs(liveFolder:GetChildren()) do
        local hrp = obj:FindFirstChild("HumanoidRootPart")
        local hum = obj:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health > 0 and obj ~= LocalPlayer.Character then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist < bestDist and dist < InstantTwistedWiseDirConfig.MaxDist then
                bestDist = dist
                closest  = hrp
            end
        end
    end
    return closest
end

local function ITWDMakeTurnGyro(part, targetCF)
    local gyro = Instance.new("BodyGyro")
    gyro.MaxTorque = Vector3.new(0, math.huge, 0)
    gyro.P = 400000
    gyro.D = 800
    gyro.CFrame = targetCF
    gyro.Parent = part
    return gyro
end

local function ITWDTwistedCombo()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp    = char:FindFirstChild("HumanoidRootPart")
    local hum    = char:FindFirstChild("Humanoid")
    local remote = char:FindFirstChild("Communicate")
    if not hrp or not hum or not remote then return end

    InstantTwistedWiseDirConfig.DoingTheThing = true

    InstantTwistedWiseDirConfig.RotateConn = RunService.RenderStepped:Connect(function()
        if InstantTwistedWiseDirConfig.DoingTheThing and hum.AutoRotate then
            hum.AutoRotate = false
        end
    end)

    local originalDir = hrp.CFrame.LookVector

    task.wait(InstantTwistedWiseDirConfig.DashWait)
    remote:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" })

    task.wait(InstantTwistedWiseDirConfig.AfterDash)
    local leftCF   = hrp.CFrame * CFrame.Angles(0, math.rad(InstantTwistedWiseDirConfig.TurnDeg), 0)
    local tempGyro = ITWDMakeTurnGyro(hrp, leftCF)
    task.wait(InstantTwistedWiseDirConfig.TurnTime)
    tempGyro:Destroy()

    task.wait(InstantTwistedWiseDirConfig.StayLeft)

    local target  = ITWDFindClosest(hrp)
    local lockConn = nil
    if target then
        if InstantTwistedWiseDirConfig.GyroLock then
            InstantTwistedWiseDirConfig.GyroLock:Destroy()
        end
        InstantTwistedWiseDirConfig.GyroLock = Instance.new("BodyGyro")
        InstantTwistedWiseDirConfig.GyroLock.MaxTorque = Vector3.new(0, math.huge, 0)
        InstantTwistedWiseDirConfig.GyroLock.P = 600000
        InstantTwistedWiseDirConfig.GyroLock.D = 0
        InstantTwistedWiseDirConfig.GyroLock.Parent = hrp

        lockConn = RunService.Heartbeat:Connect(function()
            if not InstantTwistedWiseDirConfig.GyroLock or not InstantTwistedWiseDirConfig.GyroLock.Parent or not target.Parent then
                if lockConn then lockConn:Disconnect() end
                return
            end
            local newTarget = ITWDFindClosest(hrp)
            if newTarget then target = newTarget end
            local vel       = target.AssemblyLinearVelocity
            local predicted = target.Position + vel * InstantTwistedWiseDirConfig.Predict
            InstantTwistedWiseDirConfig.GyroLock.CFrame = CFrame.lookAt(hrp.Position, predicted)
        end)

        task.delay(InstantTwistedWiseDirConfig.LockTime + 0.15, function()
            if lockConn then lockConn:Disconnect() end
        end)
    end

    task.wait(InstantTwistedWiseDirConfig.LockTime)

    local backCF   = CFrame.lookAt(hrp.Position, hrp.Position + originalDir)
    local backGyro = ITWDMakeTurnGyro(hrp, backCF)
    task.wait(InstantTwistedWiseDirConfig.TurnTime)
    backGyro:Destroy()

    if InstantTwistedWiseDirConfig.GyroLock then
        InstantTwistedWiseDirConfig.GyroLock:Destroy()
        InstantTwistedWiseDirConfig.GyroLock = nil
    end

    task.wait(0.12)
    InstantTwistedWiseDirConfig.DoingTheThing = false

    if InstantTwistedWiseDirConfig.RotateConn then
        InstantTwistedWiseDirConfig.RotateConn:Disconnect()
        InstantTwistedWiseDirConfig.RotateConn = nil
    end
end

local function ConnectInstantTwistedWiseDir()
    if InstantTwistedWiseDirConfig.AnimConnection then
        InstantTwistedWiseDirConfig.AnimConnection:Disconnect()
        InstantTwistedWiseDirConfig.AnimConnection = nil
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum  = char:WaitForChild("Humanoid")

    local ping = ITWDGetPing()
    ITWDAutoConfigByPing(ping)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Instant Twisted Enabled",
    Text = "Ping: " .. ping .. " ms",
    Duration = 3
})

    task.spawn(function()
        while InstantTwistedWiseDirConfig.Enabled do
            local p = ITWDGetPing()
            ITWDAutoConfigByPing(p)
            task.wait(10)
        end
    end)

    InstantTwistedWiseDirConfig.AnimConnection = hum.AnimationPlayed:Connect(function(track)
        if not InstantTwistedWiseDirConfig.Enabled then return end
        local id = track.Animation.AnimationId
        for _, animId in ipairs(ITWDAnimIds) do
            if id == animId then
                task.spawn(ITWDTwistedCombo)
                break
            end
        end
    end)
end

local SideDashNewConfig = {
    Enabled = false,
    TargetDistance = 50,
    SelectedTargetName = nil,
    UseAutoTarget = true,
    isDashing = false,
    debounce = false,
    activeDashId = 0,
    currentAnimConnection = nil,
    currentRotateConnection = nil,
    charConnection = nil,
    velocityHistories = {},
    targetIsDead = false,
}

local SD_REACH = 0
local SD_BASE_SPEED = 120
local SD_CLOSE_SPEED = 130
local SD_CLOSE_DIST = 15
local SD_DURATION = 0.23
local SD_FAR_DURATION = 0.29
local SD_CLOSE_DURATION = 0.23
local SD_POST_LOOK = 0.32
local SD_BASE_PREDICT = 0.155
local SD_SIDE_BOOST = 0.1
local SD_CAMERA_SMOOTH = 0.091
local SD_TOTAL_MAX_DISTANCE = 26
local SD_DASH_DISTANCE = 10
local SD_HARD_SPEED_CAP = 130
local SD_SOFT_BRAKE_MARGIN = 5.5
local SD_SMOOTH_STOP_RATE = 45
local SD_FAR_APPROACH_DIST = 20
local SD_FAR_SIDE_OFFSET = 5.8
local SD_ORBIT_DISTANCE = 26
local SD_ORBIT_FORCE = 2.5
local SD_HOVER_HEIGHT = 3.5
local SD_HOVER_PULL = 18
local SD_MAX_Y_VEL = 13
local SD_GRAVITY_STRENGTH = 28
local SD_SLIDE_MIN_SPEED = 45
local SD_SLIDE_STOP_SPEED = 1.5
local SD_SLIDE_ROTATE_FORCE = 0.98
local SD_SLIDE_SIDE_CURVE = 0.75
local SD_SLIDE_BRAKE = 65
local SD_CLICK_DISTANCE = 28
local SD_CLICK_DELAY = 0.17
local SD_VEL_HISTORY_SIZE = 10
local SD_ACCEL_PREDICT_SCALE = 0.085
local SD_JERK_ANGLE_THRESHOLD = 0.55
local SD_JERK_PREDICT_BOOST = 1.55
local SD_JERK_LERP_BOOST = 18
local SD_ANTI_LOSS_MIN_SPEED = 2.0
local SD_INERTIA_COMP_SCALE = 0.18
local SD_MICRO_CORR_JERK_OFFSET = 0.55
local SD_NEAR_LERP_BOOST = 32
local SD_FAR_LERP_BASE = 9
local SD_TEMPO_DECEL_THRESHOLD = 0.35
local SD_TEMPO_DECEL_PREDICT = 0.6
local SD_BACK_PREDICT_BOOST = 1.4
local SD_SIDE_DASH_ORBIT_BOOST = 1.35
local SD_HOOKDASH_STAB_ALPHA = 0.82
local SD_ANIM_LEFT  = "rbxassetid://10480793962"
local SD_ANIM_RIGHT = "rbxassetid://10480796021"

local function sd_getTarget()
    if not SideDashNewConfig.UseAutoTarget and SideDashNewConfig.SelectedTargetName then
        local plr = Players:FindFirstChild(SideDashNewConfig.SelectedTargetName)
        if plr and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                SideDashNewConfig.targetIsDead = false
                return hrp
            else
                SideDashNewConfig.targetIsDead = true
                return nil
            end
        else
            SideDashNewConfig.targetIsDead = true
            return nil
        end
    end
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest, bestDist = nil, SideDashNewConfig.TargetDistance
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest = hrp
                end
            end
        end
    end
    SideDashNewConfig.targetIsDead = false
    return nearest
end

local function sd_isDisabled(humanoid)
    if not humanoid then return true end
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown or
       state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Dead then
        return true
    end
    if humanoid.Health <= 0 or humanoid.PlatformStand or humanoid.Sit then return true end
    return false
end

local function sd_pushVelocity(hrp, vel)
    if not SideDashNewConfig.velocityHistories[hrp] then
        SideDashNewConfig.velocityHistories[hrp] = {}
    end
    local hist = SideDashNewConfig.velocityHistories[hrp]
    table.insert(hist, { vel = vel, t = tick() })
    while #hist > SD_VEL_HISTORY_SIZE do
        table.remove(hist, 1)
    end
end

local function sd_getAcceleration(hrp)
    local hist = SideDashNewConfig.velocityHistories[hrp]
    if not hist or #hist < 2 then return Vector3.zero end
    local newest = hist[#hist]
    local oldest = hist[1]
    local dt = newest.t - oldest.t
    if dt < 0.001 then return Vector3.zero end
    local dv = newest.vel - oldest.vel
    return Vector3.new(dv.X / dt, 0, dv.Z / dt)
end

local function sd_isJerkDetected(hrp)
    local hist = SideDashNewConfig.velocityHistories[hrp]
    if not hist or #hist < 2 then return false end
    local prev = Vector3.new(hist[#hist-1].vel.X, 0, hist[#hist-1].vel.Z)
    local curr = Vector3.new(hist[#hist].vel.X, 0, hist[#hist].vel.Z)
    if prev.Magnitude < 1 or curr.Magnitude < 1 then return false end
    return prev.Unit:Dot(curr.Unit) < SD_JERK_ANGLE_THRESHOLD
end

local function sd_isDecelDetected(hrp)
    local hist = SideDashNewConfig.velocityHistories[hrp]
    if not hist or #hist < 3 then return false end
    local prev = hist[#hist-2].vel
    local curr = hist[#hist].vel
    local prevM = Vector3.new(prev.X, 0, prev.Z).Magnitude
    local currM = Vector3.new(curr.X, 0, curr.Z).Magnitude
    if prevM < 1 then return false end
    return (currM / prevM) < SD_TEMPO_DECEL_THRESHOLD
end

local function sd_isBackDash(hrp, myHrp)
    local hist = SideDashNewConfig.velocityHistories[hrp]
    if not hist or #hist < 1 then return false end
    local toTarget = hrp.Position - myHrp.Position
    local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
    if flat.Magnitude < 0.1 then return false end
    local vel = hist[#hist].vel
    if vel.Magnitude < 2 then return false end
    return flat.Unit:Dot(vel.Unit) > 0.45
end

local function sd_isSideDash(hrp, myHrp)
    local hist = SideDashNewConfig.velocityHistories[hrp]
    if not hist or #hist < 1 then return false end
    local toTarget = hrp.Position - myHrp.Position
    local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
    if flat.Magnitude < 0.1 then return false end
    local vel = hist[#hist].vel
    if vel.Magnitude < 3 then return false end
    local absDot = math.abs(flat.Unit:Dot(vel.Unit))
    return absDot < 0.35
end

local function sd_predictPosition(hrp, basePredictTime, myHrp)
    local vel = hrp.AssemblyLinearVelocity
    local flatV = Vector3.new(vel.X, 0, vel.Z)
    sd_pushVelocity(hrp, flatV)
    local accel    = sd_getAcceleration(hrp)
    local jerk     = sd_isJerkDetected(hrp)
    local decel    = sd_isDecelDetected(hrp)
    local backDash = myHrp and sd_isBackDash(hrp, myHrp)
    local sideDash = myHrp and sd_isSideDash(hrp, myHrp)
    local predictT = basePredictTime
    if jerk  then predictT = predictT * SD_JERK_PREDICT_BOOST end
    if decel then predictT = predictT * SD_TEMPO_DECEL_PREDICT end
    if backDash then predictT = predictT * SD_BACK_PREDICT_BOOST end
    local predicted =
        hrp.Position
        + flatV * predictT
        + accel * (SD_ACCEL_PREDICT_SCALE * predictT * predictT)
    if flatV.Magnitude < SD_ANTI_LOSS_MIN_SPEED then
        predicted = predicted:Lerp(hrp.Position, 0.7)
    end
    return Vector3.new(predicted.X, hrp.Position.Y, predicted.Z), jerk, sideDash, backDash
end

local function sd_smoothCameraLook(target)
    if not Camera or not target then return end
    local camPos    = Camera.CFrame.Position
    local targetPos = Vector3.new(
        target.Position.X,
        math.min(target.Position.Y, camPos.Y),
        target.Position.Z
    )
    local direction = targetPos - camPos
    if direction.Magnitude <= 0.001 then return end
    local blended = Camera.CFrame.LookVector:Lerp(direction.Unit, SD_CAMERA_SMOOTH)
    Camera.CFrame = CFrame.lookAt(camPos, camPos + blended)
end

local function sd_faceTowardEnemy(hrp, target, goRight)
    local toEnemy = target.Position - hrp.Position
    local flat = Vector3.new(toEnemy.X, 0, toEnemy.Z)
    if flat.Magnitude <= 0.01 then return end
    local forward = flat.Unit
    local right   = Vector3.new(-forward.Z, 0, forward.X)
    local lookDir
    if goRight then
        lookDir = (forward + right * 0.85).Unit
    else
        lookDir = (forward - right * 0.85).Unit
    end
    hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + lookDir)
end

local function sd_getGroundY(hrp, char)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {char}
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(hrp.Position, Vector3.new(0, -15, 0), rp)
    return res and res.Position.Y or nil
end

local function sd_calcSafeYVelocity(hrp, char, currentYVel)
    local groundY = sd_getGroundY(hrp, char)
    if groundY then
        local diff = (groundY + SD_HOVER_HEIGHT) - hrp.Position.Y
        if diff < 0 then
            return math.clamp(diff * SD_HOVER_PULL, -SD_MAX_Y_VEL, 0)
        else
            return math.clamp(diff * 20, 0, SD_MAX_Y_VEL)
        end
    end
    return math.clamp(currentYVel - SD_GRAVITY_STRENGTH * 0.016, -SD_MAX_Y_VEL, 2)
end

local function sd_getDynamicSpeed(dist, progress)
    local alpha =
        dist <= SD_CLOSE_DIST
        and 0
        or math.clamp((dist - SD_CLOSE_DIST) / 10, 0, 1)
    local speed = SD_CLOSE_SPEED + (SD_BASE_SPEED - SD_CLOSE_SPEED) * alpha
    local rampUp = math.clamp(progress / 0.08, 0, 1)
    rampUp = rampUp * rampUp * (3 - 2 * rampUp)
    local slowStart  = 0.82
    local smoothSlow =
        (1 - math.clamp((progress - slowStart) / (1 - slowStart), 0, 1)) ^ 0.72
    speed = speed * rampUp * (0.18 + smoothSlow * 0.82)
    return speed
end

local function sd_softBrakeMultiplier(remainBudget)
    if remainBudget >= SD_SOFT_BRAKE_MARGIN then return 1.0 end
    if remainBudget <= 0 then return 0.0 end
    local t = remainBudget / SD_SOFT_BRAKE_MARGIN
    return t * t
end

local function sd_doClick(char)
    local args = {{ Goal = "LeftClick", Mobile = true }}
    char:WaitForChild("Communicate"):FireServer(unpack(args))
    local releaseArgs = {{ Goal = "LeftClickRelease", Mobile = true }}
    char:WaitForChild("Communicate"):FireServer(unpack(releaseArgs))
end

local function sd_getPingAdaptive()
    local rawMs = 0
    pcall(function()
        rawMs = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    local level = math.clamp((rawMs - 75) / 25, 0, 4)
    return {
        pingSec     = math.clamp(rawMs / 1000, 0, 0.22),
        clickDelay  = SD_CLICK_DELAY * math.max(1 - level * 0.18, 0.25),
        predictMult = 1 + level * 0.18,
        orbitForce  = SD_ORBIT_FORCE * (1 + level * 0.12),
        sideBoost   = SD_SIDE_BOOST * (1 + level * 0.15),
    }
end

local function sd_executeDash(goRight, track)
    if not SideDashNewConfig.Enabled then return end
    if SideDashNewConfig.isDashing or SideDashNewConfig.debounce then return end

    local char = LocalPlayer.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    if sd_isDisabled(hum) then return end

    local target = sd_getTarget()
    if not target then
        if not SideDashNewConfig.UseAutoTarget then
            SideDashNewConfig.UseAutoTarget = true
            SideDashNewConfig.SelectedTargetName = nil
            SideDashNewConfig.targetIsDead = false
            target = sd_getTarget()
        end
        if not target then return end
    end

    if SideDashNewConfig.targetIsDead then
        return
    end

    local startTargetDistance = (
        Vector3.new(target.Position.X, 0, target.Position.Z)
        - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
    ).Magnitude

    if startTargetDistance > SideDashNewConfig.TargetDistance then
        return
    end

    local currentDuration =
        startTargetDistance > 23
        and SD_FAR_DURATION
        or  SD_CLOSE_DURATION

    SideDashNewConfig.activeDashId = SideDashNewConfig.activeDashId + 1
    local dashId = SideDashNewConfig.activeDashId

    SideDashNewConfig.isDashing = true
    SideDashNewConfig.debounce  = true

    hum.AutoRotate = false

    local startPos = hrp.Position

    local att = Instance.new("Attachment")
    att.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0            = att
    lv.RelativeTo             = Enum.ActuatorRelativeTo.World
    lv.MaxForce               = math.huge
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.Parent                 = hrp

    local clicked      = false
    local clickStarted = false

    local function totalDistance()
        return (hrp.Position - startPos).Magnitude
    end

    local function cleanup()
        if dashId ~= SideDashNewConfig.activeDashId then return end
        SideDashNewConfig.activeDashId = SideDashNewConfig.activeDashId + 1
        pcall(function() lv:Destroy()  end)
        pcall(function() att:Destroy() end)
        if hum.Parent then hum.AutoRotate = true end
        SideDashNewConfig.isDashing = false
        task.delay(0.08, function()
            if dashId + 1 == SideDashNewConfig.activeDashId then
                SideDashNewConfig.debounce = false
            end
        end)
    end

    local function shouldCancel()
        if dashId ~= SideDashNewConfig.activeDashId then return true end
        if not char.Parent         then return true end
        if not hrp.Parent          then return true end
        if not hum.Parent          then return true end
        if sd_isDisabled(hum)      then return true end
        if not SideDashNewConfig.Enabled then return true end
        if SideDashNewConfig.targetIsDead then return true end
        return false
    end

    local sideSign = goRight and -1 or 1

    local velocity          = Vector3.zero
    local trackedPrediction = target.Position
    local smoothYVel        = hrp.AssemblyLinearVelocity.Y

    local prevDesiredDir = Vector3.zero

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if shouldCancel() then
            conn:Disconnect()
            cleanup()
            return
        end

        if totalDistance() >= SD_TOTAL_MAX_DISTANCE then
            velocity = velocity:Lerp(Vector3.zero, math.clamp(dt * SD_SMOOTH_STOP_RATE, 0, 1))
            lv.VectorVelocity = Vector3.new(velocity.X, smoothYVel, velocity.Z)
            conn:Disconnect()
            cleanup()
            return
        end

        hum.AutoRotate = false
        sd_smoothCameraLook(target)

        local traveled = (hrp.Position - startPos).Magnitude

        if traveled >= SD_DASH_DISTANCE then
            conn:Disconnect()
            return
        end

        local progress = math.clamp(traveled / SD_DASH_DISTANCE, 0, 1)
        local pa       = sd_getPingAdaptive()

        local rawPredicted, jerk, sideDash, backDash =
            sd_predictPosition(target, SD_BASE_PREDICT * pa.predictMult + pa.pingSec, hrp)

        local distToCurrent = (trackedPrediction - hrp.Position).Magnitude
        local lerpSpeed

        if jerk or sideDash then
            lerpSpeed = SD_JERK_LERP_BOOST
        elseif distToCurrent < 8.0 then
            lerpSpeed = SD_NEAR_LERP_BOOST
        else
            lerpSpeed = SD_FAR_LERP_BASE
        end

        trackedPrediction = trackedPrediction:Lerp(
            rawPredicted,
            math.clamp(dt * lerpSpeed, 0, 1)
        )

        local delta    = trackedPrediction - hrp.Position
        local flat     = Vector3.new(delta.X, 0, delta.Z)
        local dist     = flat.Magnitude

        if dist <= 0.01 then return end

        if dist <= SD_CLICK_DISTANCE and not clickStarted then
            clickStarted = true
            local dynamicClickDelay = dist < 17 and 0.1 or 0.2
            task.delay(dynamicClickDelay, function()
                if clicked then return end
                if shouldCancel() then return end

                local pa2 = sd_getPingAdaptive()
                local latestPredicted, _ = sd_predictPosition(target, SD_BASE_PREDICT * pa2.predictMult + pa2.pingSec, hrp)
                local latestDist = (
                    Vector3.new(latestPredicted.X, 0, latestPredicted.Z)
                    - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
                ).Magnitude

                if latestDist <= SD_CLICK_DISTANCE then
                    clicked = true
                    sd_doClick(char)
                end
            end)
        end

        local dir  = flat.Unit
        local side = Vector3.new(-dir.Z, 0, dir.X) * sideSign

        local microCorr = Vector3.zero
        if jerk then
            microCorr = side * SD_MICRO_CORR_JERK_OFFSET
        end

        local orbitForceMult = 1.0
        if sideDash then
            orbitForceMult = SD_SIDE_DASH_ORBIT_BOOST
        end

        local orbitAlpha =
            dist <= SD_ORBIT_DISTANCE
            and (1 - math.clamp(dist / SD_ORBIT_DISTANCE, 0, 1))
            or  0

        local orbitSide  = side * ((SD_REACH + 2.2) * orbitAlpha * pa.orbitForce * orbitForceMult)
        local offset     = side * (SD_REACH + pa.sideBoost + math.clamp(dist / 11, 0, 1.1)) + orbitSide
        local backOffset = math.clamp(dist * 0.16, 0.7, 2)

        if orbitAlpha > 0.15 then
            backOffset *= (1 - orbitAlpha * 0.85)
        end

        if dist > SD_FAR_APPROACH_DIST then
            local farAlpha  = math.clamp((dist - SD_FAR_APPROACH_DIST) / 8, 0, 1)
            local farOffset = side * (SD_FAR_SIDE_OFFSET * farAlpha)
            backOffset = backOffset * (1 - farAlpha * 0.7)
            offset = offset + farOffset
        end

        local finalXZ = trackedPrediction + offset - dir * backOffset + microCorr
        local final   = Vector3.new(finalXZ.X, hrp.Position.Y, finalXZ.Z)
        local move    = final - hrp.Position
        local moveFlat = Vector3.new(move.X, 0, move.Z)

        if moveFlat.Magnitude > 0.01 then
            local speed = sd_getDynamicSpeed(dist, progress)

            local remain      = SD_DASH_DISTANCE - traveled
            local adaptiveCap = math.clamp((remain ^ 0.94) * 10.8, 86, SD_BASE_SPEED + 18)
            speed = math.min(speed, adaptiveCap)

            local remainBudget = SD_TOTAL_MAX_DISTANCE - totalDistance()
            speed = speed * sd_softBrakeMultiplier(remainBudget)
            speed = math.min(speed, SD_HARD_SPEED_CAP)

            local desiredDir = moveFlat.Unit

            if prevDesiredDir.Magnitude > 0.01 then
                desiredDir = prevDesiredDir:Lerp(desiredDir, SD_HOOKDASH_STAB_ALPHA)
                if desiredDir.Magnitude > 0.001 then
                    desiredDir = desiredDir.Unit
                end
            end
            prevDesiredDir = desiredDir

            local myVel  = hrp.AssemblyLinearVelocity
            local myFlat = Vector3.new(myVel.X, 0, myVel.Z)
            local inertiaComp = Vector3.zero
            if myFlat.Magnitude > 5 then
                local inertiaErr = desiredDir - myFlat.Unit * myFlat:Dot(desiredDir) / (desiredDir.Magnitude * myFlat.Magnitude + 0.001)
                inertiaComp = Vector3.new(inertiaErr.X, 0, inertiaErr.Z) * SD_INERTIA_COMP_SCALE
            end

            local finalDesired = desiredDir + inertiaComp
            if finalDesired.Magnitude > 0.001 then
                finalDesired = finalDesired.Unit
            end

            local desired = finalDesired * speed

            local velLerpAlpha = jerk and (dt * 28) or (dt * (21 - progress * 7))
            velocity = velocity:Lerp(
                Vector3.new(desired.X, 0, desired.Z),
                math.clamp(velLerpAlpha, 0, 1)
            )

            local velMag = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
            if velMag > SD_HARD_SPEED_CAP then
                local scale = SD_HARD_SPEED_CAP / velMag
                velocity = Vector3.new(velocity.X * scale, velocity.Y, velocity.Z * scale)
            end

            local safeY = sd_calcSafeYVelocity(hrp, char, smoothYVel)
            smoothYVel  = smoothYVel + (safeY - smoothYVel) * math.clamp(dt * 14, 0, 1)
            smoothYVel  = math.clamp(smoothYVel, -SD_MAX_Y_VEL, SD_MAX_Y_VEL)

            lv.VectorVelocity = Vector3.new(velocity.X, smoothYVel, velocity.Z)
            sd_faceTowardEnemy(hrp, target, goRight)
        end
    end)

    task.delay(currentDuration, function()
        if conn then conn:Disconnect() end

        local lookEnd  = tick() + SD_POST_LOOK
        local lookConn

        lookConn = RunService.RenderStepped:Connect(function()
            if shouldCancel() or tick() >= lookEnd then
                lookConn:Disconnect()
                return
            end
            sd_smoothCameraLook(target)
        end)

        if not hrp.Parent then
            cleanup()
            return
        end

        local slideDir = Vector3.new(velocity.X, 0, velocity.Z)
        if slideDir.Magnitude > 0.01 then
            slideDir = slideDir.Unit
        else
            cleanup()
            return
        end

        local slideMag = velocity.Magnitude
        local slideVelXZ = Vector3.new(velocity.X, 0, velocity.Z)
        local slowConn

        slowConn = RunService.RenderStepped:Connect(function(dt)
            if shouldCancel() then
                slideVelXZ = slideVelXZ:Lerp(Vector3.zero, math.clamp(dt * SD_SMOOTH_STOP_RATE, 0, 1))
                lv.VectorVelocity = Vector3.new(slideVelXZ.X, smoothYVel, slideVelXZ.Z)
                slowConn:Disconnect()
                cleanup()
                return
            end

            if totalDistance() >= SD_TOTAL_MAX_DISTANCE then
                slideVelXZ = slideVelXZ:Lerp(Vector3.zero, math.clamp(dt * SD_SMOOTH_STOP_RATE, 0, 1))
                lv.VectorVelocity = Vector3.new(slideVelXZ.X, smoothYVel, slideVelXZ.Z)
                if slideVelXZ.Magnitude < 1 then
                    lv.VectorVelocity = Vector3.new(0, smoothYVel, 0)
                    slowConn:Disconnect()
                    cleanup()
                end
                return
            end

            if track and not track.IsPlaying then
                slideVelXZ = slideVelXZ:Lerp(Vector3.zero, math.clamp(dt * SD_SMOOTH_STOP_RATE, 0, 1))
                lv.VectorVelocity = Vector3.new(slideVelXZ.X, smoothYVel, slideVelXZ.Z)
                if slideVelXZ.Magnitude < 1 then
                    lv.VectorVelocity = Vector3.new(0, smoothYVel, 0)
                    slowConn:Disconnect()
                    cleanup()
                end
                return
            end

            hum.AutoRotate = false
            sd_smoothCameraLook(target)

            local pa = sd_getPingAdaptive()
            local predicted, _, sideDash2, _ = sd_predictPosition(target, SD_BASE_PREDICT * pa.predictMult + pa.pingSec, hrp)

            local delta = predicted - hrp.Position
            local flat  = Vector3.new(delta.X, 0, delta.Z)

            if flat.Magnitude > 0.01 then
                local dir  = flat.Unit
                local side = Vector3.new(-dir.Z, 0, dir.X) * sideSign

                local slideRotForce = sideDash2
                    and (SD_SLIDE_ROTATE_FORCE * 14)
                    or  (SD_SLIDE_ROTATE_FORCE * 10)

                local curve = (dir + side * SD_SLIDE_SIDE_CURVE).Unit
                slideDir = slideDir:Lerp(
                    curve,
                    math.clamp(dt * slideRotForce, 0, 1)
                )

                sd_faceTowardEnemy(hrp, target, goRight)
            end

            slideMag = math.max(slideMag - SD_SLIDE_BRAKE * dt, SD_SLIDE_MIN_SPEED)

            local remainBudget2 = SD_TOTAL_MAX_DISTANCE - totalDistance()
            local brakeMult = sd_softBrakeMultiplier(remainBudget2)
            local effectiveMag = math.min(slideMag * brakeMult, SD_HARD_SPEED_CAP)

            local targetVelXZ = Vector3.new(slideDir.X * effectiveMag, 0, slideDir.Z * effectiveMag)
            slideVelXZ = slideVelXZ:Lerp(targetVelXZ, math.clamp(dt * 14, 0, 1))

            if effectiveMag <= SD_SLIDE_STOP_SPEED or slideMag <= SD_SLIDE_STOP_SPEED then
                slideVelXZ = slideVelXZ:Lerp(Vector3.zero, math.clamp(dt * SD_SMOOTH_STOP_RATE, 0, 1))
                lv.VectorVelocity = Vector3.new(slideVelXZ.X, smoothYVel, slideVelXZ.Z)
                if slideVelXZ.Magnitude < 0.8 then
                    lv.VectorVelocity = Vector3.new(0, smoothYVel, 0)
                    slowConn:Disconnect()
                    cleanup()
                end
                return
            end

            local safeY = sd_calcSafeYVelocity(hrp, char, smoothYVel)
            smoothYVel  = smoothYVel + (safeY - smoothYVel) * math.clamp(dt * 14, 0, 1)
            smoothYVel  = math.clamp(smoothYVel, -SD_MAX_Y_VEL, SD_MAX_Y_VEL)

            lv.VectorVelocity = Vector3.new(slideVelXZ.X, smoothYVel, slideVelXZ.Z)
        end)
    end)
end

local function sd_onAnimationPlayed(track)
    local anim = track.Animation
    if not anim then return end
    local id = anim.AnimationId
    if id == SD_ANIM_LEFT then
        sd_executeDash(false, track)
    elseif id == SD_ANIM_RIGHT then
        sd_executeDash(true, track)
    end
end

local function sd_connect(char)
    if SideDashNewConfig.currentAnimConnection then SideDashNewConfig.currentAnimConnection:Disconnect() end
    if SideDashNewConfig.currentRotateConnection then SideDashNewConfig.currentRotateConnection:Disconnect() end

    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end

    SideDashNewConfig.currentRotateConnection =
        hum:GetPropertyChangedSignal("AutoRotate"):Connect(function()
            if SideDashNewConfig.isDashing and hum.AutoRotate then
                hum.AutoRotate = false
            end
        end)

    SideDashNewConfig.currentAnimConnection =
        animator.AnimationPlayed:Connect(function(track)
            if SideDashNewConfig.Enabled then
                sd_onAnimationPlayed(track)
            end
        end)
end

local function sd_disconnect()
    if SideDashNewConfig.currentAnimConnection then
        SideDashNewConfig.currentAnimConnection:Disconnect()
        SideDashNewConfig.currentAnimConnection = nil
    end
    if SideDashNewConfig.currentRotateConnection then
        SideDashNewConfig.currentRotateConnection:Disconnect()
        SideDashNewConfig.currentRotateConnection = nil
    end
    SideDashNewConfig.isDashing = false
    SideDashNewConfig.debounce  = false
    SideDashNewConfig.activeDashId = SideDashNewConfig.activeDashId + 1
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.AutoRotate = true end
    end
end

local AntiShakeConfig = {
    Enabled = false,
    Connection = nil,
    OriginalCFrame = nil,
}

local function StopCameraShake()
    pcall(function()
        local cameraShake = Camera:FindFirstChild("CameraShake")
        if cameraShake then
            cameraShake:Destroy()
        end
        
        for _, v in ipairs(Camera:GetDescendants()) do
            if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                if v.Name:lower():find("shake") or v.Name:lower():find("camera") then
                    pcall(function() v:Disable() end)
                end
            end
        end
    end)
end

local function OnCharacterHit()
    if not AntiShakeConfig.Enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    AntiShakeConfig.OriginalCFrame = Camera.CFrame
    
    task.spawn(function()
        local startTime = tick()
        local duration = 0.3
        
        while tick() - startTime < duration and AntiShakeConfig.Enabled do
            if AntiShakeConfig.OriginalCFrame then
                pcall(function()
                    if Camera.CFrame ~= AntiShakeConfig.OriginalCFrame then
                        Camera.CFrame = AntiShakeConfig.OriginalCFrame
                    end
                end)
            end
            StopCameraShake()
            task.wait()
        end
    end)
end

local function SetupAntiShake()
    if AntiShakeConfig.Connection then
        AntiShakeConfig.Connection:Disconnect()
        AntiShakeConfig.Connection = nil
    end
    
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        local lastHealth = humanoid.Health
        AntiShakeConfig.Connection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if AntiShakeConfig.Enabled then
                local newHealth = humanoid.Health
                if newHealth < lastHealth then
                    OnCharacterHit()
                end
                lastHealth = newHealth
            end
        end)
    end
end

local AutoBlockConfig = {
    Enabled = false,
    M1AfterBlock = false,
    AutoCounter = false,
    BlockSpin = false,
    NormalRange = 15,
}

local DetectIDs = {
    ["10469493270"]=true,["10469630950"]=true,["10469639222"]=true,["10469643643"]=true,
    ["13532562418"]=true,["13532600125"]=true,["13532604085"]=true,["13294471966"]=true,
    ["13491635433"]=true,["13296577783"]=true,["13295919399"]=true,["13295936866"]=true,
    ["13370310513"]=true,["13390230973"]=true,["13378751717"]=true,["13378708199"]=true,
    ["14004222985"]=true,["13997092940"]=true,["14001963401"]=true,["14136436157"]=true,
    ["15271263467"]=true,["15240216931"]=true,["15240176873"]=true,["15162694192"]=true,
    ["16515503507"]=true,["16515520431"]=true,["16515448089"]=true,["16552234590"]=true,
    ["17889458563"]=true,["17889461810"]=true,["17889471098"]=true,["17889290569"]=true,
    ["123005629431309"]=true,["100059874351664"]=true,["104895379416342"]=true,["134775406437626"]=true,["15259161390"]=true
}

local SkillSpecialConfig = {
    ["10479335397"] = {range = 50, delay = 0.79},
    ["13380255751"] = {range = 50, delay = 0.79},
    ["10468665991"] = {range = 50, delay = 0.7},
    ["10466974800"] = {range = 18, delay = 1.29},
    ["12272894215"] = {range = 12, delay = 0.55},
    ["12296882427"] = {range = 12, delay = 0.55},
    ["12509505723"] = {range = 30, delay = 0.7},
    ["12534735382"] = {range = 18, delay = 1.29},
    ["12684390285"] = {range = 50, delay = 1.8},
    ["13294790250"] = {range = 50, delay = 0.55},
    ["13376869471"] = {range = 50, delay = 0.8},
    ["13376962659"] = {range = 70, delay = 2.5},
    ["14046756619"] = {range = 50, delay = 0.5},
    ["15290930205"] = {range = 25, delay = 1.27},
    ["15295895753"] = {range = 20, delay = 0.8},
    ["15295336270"] = {range = 30, delay = 1},
    ["16139108718"] = {range = 60, delay = 0.8},
    ["16515850153"] = {range = 30, delay = 3},
    ["16431491215"] = {range = 25, delay = 1.7},
    ["17799224866"] = {range = 15, delay = 1.25},
    ["17857788598"] = {range = 17, delay = 1.1},
    ["18179181663"] = {range = 10, delay = 0.66},
    ["77509627104305"] = {range = 50, delay = 3},
    ["131820095363270"] = {range = 100, delay = 2},
}

local CounterDetectIDs = {
    ["10479335397"] = true,
    ["13380255751"] = true,
    ["13813955149"] = true
}

local AutoBlockState = {
    detecting = false,
    shortRange = false,
    connection = nil,
    lastDetected = {},
    LastVelocity = {},
    LastPredict = {},
    autoCounter = false,
    spinToggle = false,
}

local CounterTracking = {}
local CounterDetectRange = 35
local CounterUseRange = 15
local PredictThreshold = 35
local PredictCooldown = 0.01

local function AutoBlockAction(distance, delayTime)
    local char = LocalPlayer.Character
    if not char then return end
    
    local comm = char:FindFirstChild("Communicate")
    if not comm then return end
    
    local args1 = {{Goal="KeyPress", Key=Enum.KeyCode.F}}
    comm:FireServer(unpack(args1))
    task.wait(delayTime)
    local args2 = {{Goal="KeyRelease", Key=Enum.KeyCode.F}}
    comm:FireServer(unpack(args2))

    if AutoBlockConfig.M1AfterBlock and distance <= 15 then
        local args3 = {{Goal="LeftClick", Mobile=true}}
        comm:FireServer(unpack(args3))
        task.wait(0.3)
        local args4 = {{Goal="LeftClickRelease", Mobile=true}}
        comm:FireServer(unpack(args4))
    end
end

local function AutoBlockSpamReleases()
    local char = LocalPlayer.Character
    if not char then return end
    
    local comm = char:FindFirstChild("Communicate")
    if not comm then return end
    
    for i = 1, 5 do
        comm:FireServer({{Goal="KeyRelease",Key=Enum.KeyCode.F}})
        comm:FireServer({{Goal="LeftClickRelease",Mobile=true}})
        task.wait(0.01)
    end
end

local function AutoBlockPredictIncoming(model, distance)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local now = tick()
    if AutoBlockState.LastPredict[model] and now - AutoBlockState.LastPredict[model] < PredictCooldown then
        return false
    end

    local lastV = AutoBlockState.LastVelocity[model]
    local currentV = hrp.Velocity.Magnitude
    AutoBlockState.LastVelocity[model] = currentV

    if lastV and (currentV - lastV) >= PredictThreshold then
        AutoBlockState.LastPredict[model] = now
        return true
    end

    local char = LocalPlayer.Character
    if model.PrimaryPart and char and char:FindFirstChild("HumanoidRootPart") then
        local dot = model.PrimaryPart.CFrame.LookVector:Dot(
            (char.HumanoidRootPart.Position - model.PrimaryPart.Position).Unit
        )
        if dot > 0.75 and distance <= 55 then
            AutoBlockState.LastPredict[model] = now
            return true
        end
    end

    return false
end

local function AutoBlockUsePreyPeril()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    local tool = backpack:FindFirstChild("Prey's Peril")
    if not tool then return end

    local args = {{
        Tool = tool,
        Goal = "Console Move"
    }}

    local char = LocalPlayer.Character
    if char then
        local comm = char:FindFirstChild("Communicate")
        if comm then
            comm:FireServer(unpack(args))
        end
    end
end

local function AutoBlockUseSplitSecondCounter()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end

    local tool = backpack:FindFirstChild("Split Second Counter")
    if not tool then return end

    local args = {{
        Tool = tool,
        Goal = "Console Move"
    }}

    local char = LocalPlayer.Character
    if char then
        local comm = char:FindFirstChild("Communicate")
        if comm then
            comm:FireServer(unpack(args))
        end
    end
end

local function AutoBlockPredictCounter(model)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local lastV = AutoBlockState.LastVelocity[model] or 0
    local curV = hrp.Velocity.Magnitude
    AutoBlockState.LastVelocity[model] = curV
    if (curV - lastV) > 30 then
        return true
    end

    local char = LocalPlayer.Character
    if model.PrimaryPart and char and char:FindFirstChild("HumanoidRootPart") then
        local dot = model.PrimaryPart.CFrame.LookVector:Dot(
            (char.HumanoidRootPart.Position - model.PrimaryPart.Position).Unit
        )
        if dot > 0.9 then
            return true
        end
    end

    return false
end

local function AutoBlockStartDetect()
    if AutoBlockState.connection then
        AutoBlockState.connection:Disconnect()
    end
    
    AutoBlockState.connection = RunService.RenderStepped:Connect(function()
        if not AutoBlockConfig.Enabled then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local rootPos = char.HumanoidRootPart.Position
        local liveFolder = Workspace:FindFirstChild("Live")
        if not liveFolder then return end

        for _, model in pairs(liveFolder:GetChildren()) do
            if model:IsA("Model") and model ~= char then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if humanoid and hrp and humanoid:FindFirstChild("Animator") then
                    local distance = (hrp.Position - rootPos).Magnitude
                    local tracks = humanoid.Animator:GetPlayingAnimationTracks()
                    local foundAnim = false
                    
                    for _, track in pairs(tracks) do
                        local animId = track.Animation.AnimationId:match("%d+")
                        if animId then
                            if AutoBlockConfig.AutoCounter
                            and AutoBlockConfig.Enabled
                            and CounterDetectIDs[animId]
                            and distance <= CounterDetectRange then
                                CounterTracking[model] = true
                            end
                            if AutoBlockConfig.AutoCounter
                            and AutoBlockConfig.Enabled
                            and CounterTracking[model]
                            and distance <= CounterUseRange then
                                if AutoBlockPredictCounter(model) or track.TimePosition <= 0.15 then
                                    AutoBlockUsePreyPeril()
                                    task.wait(0.05)
                                    AutoBlockUseSplitSecondCounter()
                                    CounterTracking[model] = nil
                                end
                            end
                            
                            local predicted = AutoBlockPredictIncoming(model, distance)
                            if DetectIDs[animId]
                            and distance <= AutoBlockConfig.NormalRange
                            and (track.TimePosition <= 0.08 or predicted) then
                                AutoBlockAction(distance, 0.2)
                                foundAnim = true
                                break
                            end
                            
                            local cfg = SkillSpecialConfig[animId]
                            if cfg
                            and distance <= cfg.range
                            and (track.TimePosition <= 0.08 or predicted) then
                                AutoBlockAction(distance, cfg.delay)
                                foundAnim = true
                                break
                            end
                        end
                    end

                    if not foundAnim and AutoBlockState.lastDetected[model] then
                        AutoBlockSpamReleases()
                        AutoBlockState.lastDetected[model] = nil
                    elseif foundAnim then
                        AutoBlockState.lastDetected[model] = true
                    end
                end
            end
        end
    end)
end

local function AutoBlockStopDetect()
    if AutoBlockState.connection then
        AutoBlockState.connection:Disconnect()
        AutoBlockState.connection = nil
    end
end

local BlockSpinAnimId = "10470389827"
local BlockSpinConnection = nil

local function IsBlockSpinAnimPlaying()
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid.Animator then return false end
    
    for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId == "rbxassetid://" .. BlockSpinAnimId then
            return true
        end
    end
    return false
end

local function SetupBlockSpin()
    if BlockSpinConnection then
        BlockSpinConnection:Disconnect()
        BlockSpinConnection = nil
    end
    
    BlockSpinConnection = RunService.RenderStepped:Connect(function(dt)
        if not AutoBlockConfig.BlockSpin or not AutoBlockConfig.Enabled then 
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.AutoRotate = true end
            end
            return 
        end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not hum then return end

        if IsBlockSpinAnimPlaying() then
            hum.AutoRotate = false
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, dt * 4 * math.pi, 0)
        else
            hum.AutoRotate = true
        end
    end)
end

local function AutoTechOnCharacterAdded(character)
    task.wait(0.1)

    if LoopDashConfig.Enabled then
        ConnectLoopDashCharacter()
    end

    if InstantLethalConfig.Enabled then
        task.wait(0.5)
        ConnectInstantLethal()
    end

    if GojoTechConfig.Enabled then
        task.wait(0.5)
        ConnectGojoTech()
    end

    if AutoKyotoConfig.Enabled then
        OnKyotoCharacterSpawn(character)
    end

    if LethalDashConfig.Enabled then
        ConnectLethalDash()
    end

    if LixTechConfig.Enabled then
        ConnectLixTech()
    end

    if SupaLegitConfig.Enabled then
        task.wait(0.5)
        ConnectSupaLegit()
    end

    if K1ngTechConfig.Enabled then
        task.wait(0.5)
        ConnectK1ngTech()
    end

    if InstantTwistedV2Config.Enabled then
        task.wait(0.5)
        ConnectInstantTwistedV2()
    end

    if BoomyLethalConfig.Enabled then
        task.wait(0.5)
        BoomyLethal_connect()
    end

    if TwistedConfig.Enabled then
        ConnectTwisted()
    end

    if SideDashNewConfig.Enabled then
        task.wait(0.5)
        sd_connect(character)
    end

    if InstantTwistedWiseDirConfig.Enabled then
        task.wait(0.5)
        ConnectInstantTwistedWiseDir()
    end

    if AntiShakeConfig.Enabled then
        task.wait(0.5)
        SetupAntiShake()
    end

    if AutoBlockConfig.Enabled then
        task.wait(0.5)
        AutoBlockStartDetect()
        if AutoBlockConfig.BlockSpin then
            SetupBlockSpin()
        end
    end
end

LocalPlayer.CharacterAdded:Connect(AutoTechOnCharacterAdded)

task.wait(0.5)
if LocalPlayer.Character then
    AutoTechOnCharacterAdded(LocalPlayer.Character)
end

local AutoTechTab = Window:Tab({
    Title = "Auto Tech",
    Icon = "bot-message-square",
    IconColor = Color3.fromHex("#FFFFFF"),
    Border = true,
})

local LoopDashSection = AutoTechTab:Section({
    Title = "Loop Dash",
    Icon = "zap",
    IconColor = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

LoopDashSection:Toggle({
    Title = "Enable Loop Dash",
    Icon = "cog",
    Value = false,
    Callback = function(state)
        LoopDashConfig.Enabled = state
        if state then
            ConnectLoopDashCharacter()
        else
            if LoopDashConfig.AnimConnection then
                LoopDashConfig.AnimConnection:Disconnect()
                LoopDashConfig.AnimConnection = nil
            end
            if LoopDashNoclipConn then
                LoopDashNoclipConn:Disconnect()
                LoopDashNoclipConn = nil
            end
        end
    end
})

LoopDashSection:Toggle({
    Title = "Auto Cancel Dash",
    Icon = "cog",
    Value = true,
    Callback = function(state)
        LoopDashConfig.CancelEnabled = state
    end
})

LoopDashSection:Toggle({
    Title = "Hide Cooldown Anim",
    Icon = "cog",
    Value = true,
    Callback = function(state)
        LoopDashConfig.CooldownActive = state
    end
})

LoopDashSection:Toggle({
    Title = "NoClip Better",
    Icon = "cog",
    Value = true,
    Callback = function(state)
        LoopDashConfig.NoClipEnabled = state
    end
})

LoopDashSection:Toggle({
    Title = "Cam Smooth",
    Icon = "cog",
    Value = false,
    Callback = function(state)
        LoopDashConfig.CamSmooth = state
        LoopDashUpdateCamSmooth(state)
    end
})

LoopDashSection:Slider({
    Title = "Dash Delay",
    Value = {Min = 0, Max = 2, Default = 0.28},
    Step = 0.01,
    Callback = function(value)
        LoopDashConfig.LoopDashDelay = value
    end
})

LoopDashSection:Slider({
    Title = "Jump Power",
    Value = {Min = 0, Max = 100, Default = 55},
    Step = 1,
    Callback = function(value)
        LoopDashConfig.LoopDashJump = value
    end
})

LoopDashSection:Slider({
    Title = "Dash Duration",
    Value = {Min = 0.1, Max = 5, Default = 1.5},
    Step = 0.1,
    Callback = function(value)
        LoopDashConfig.DashDuration = value
    end
})

LoopDashSection:Slider({
    Title = "Accuracy / Flip",
    Value = {Min = 0, Max = 50, Default = 15},
    Step = 0.5,
    Callback = function(value)
        LoopDashConfig.LoopDashAccuracy = value
    end
})

LoopDashSection:Slider({
    Title = "Dash Range",
    Value = {Min = 1, Max = 30, Default = 8},
    Step = 1,
    Callback = function(value)
        LoopDashConfig.DashRange = value
    end
})

LoopDashSection:Slider({
    Title = "Cancel Delay",
    Value = {Min = 0, Max = 2, Default = 0.4},
    Step = 0.01,
    Callback = function(value)
        LoopDashConfig.LoopDashCancelDelay = value
    end
})

LoopDashSection:Slider({
    Title = "Jump Delay (Custom Mode)",
    Value = {Min = 0, Max = 2, Default = 0.25},
    Step = 0.01,
    Callback = function(value)
        LoopDashConfig.JumpDelay = value
    end
})

LoopDashSection:Button({
    Title = "Cycle Rotation Mode",
    Icon = "cog",
    Justify = "Between",
    Callback = function()
        if LoopDashConfig.LoopDashMode == "BodyGyro" then
            LoopDashConfig.LoopDashMode = "Flip"
            _G.LoopDashLastAcc = LoopDashConfig.LoopDashAccuracy
            LoopDashConfig.LoopDashAccuracy = 0.25
        elseif LoopDashConfig.LoopDashMode == "Flip" then
            LoopDashConfig.LoopDashMode = "AlignOrientation"
            LoopDashConfig.LoopDashAccuracy = _G.LoopDashLastAcc or 15
        else
            LoopDashConfig.LoopDashMode = "BodyGyro"
            LoopDashConfig.LoopDashAccuracy = _G.LoopDashLastAcc or 15
        end
        WindUI:Notify({
            Title = "Loop Dash",
            Content = "Rotation Mode: " .. LoopDashConfig.LoopDashMode,
            Icon = "rotate-cw",
            Duration = 2,
        })
    end
})

LoopDashSection:Button({
    Title = "Toggle Jump Mode",
    Icon = "arrow-up-circle",
    Justify = "Between",
    Callback = function()
        LoopDashConfig.JumpMode = (LoopDashConfig.JumpMode == "Normal") and "Custom" or "Normal"
        WindUI:Notify({
            Title = "Loop Dash",
            Content = "Jump Mode: " .. LoopDashConfig.JumpMode,
            Icon = "arrow-up-circle",
            Duration = 2,
        })
    end
})

local SupaTechSection = AutoTechTab:Section({
    Title = "Supa Tech",
    Icon = "zap",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

SupaTechSection:Toggle({
    Title = "Enable Supa Tech",
    Icon = "power",
    Value = false,
    Callback = function(state)
        SupaLegitConfig.Enabled = state
        if state then
            ConnectSupaLegit()
            if not SupaLegitConfig.CharConnection then
                SupaLegitConfig.CharConnection = LocalPlayer.CharacterAdded:Connect(function()
                    if SupaLegitConfig.Enabled then
                        task.wait(0.5)
                        ConnectSupaLegit()
                    end
                end)
            end
        else
            if SupaLegitConfig.Connection then
                SupaLegitConfig.Connection:Disconnect()
                SupaLegitConfig.Connection = nil
            end
            if SupaLegitConfig.CharConnection then
                SupaLegitConfig.CharConnection:Disconnect()
                SupaLegitConfig.CharConnection = nil
            end
            SupaLegitConfig.Busy = false
            SupaLegitConfig.InCooldown = false
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
            if SupaLegitCooldownBillboard then
                SupaLegitCooldownBillboard:Destroy()
                SupaLegitCooldownBillboard = nil
            end
        end
    end
})

local K1ngTechSection = AutoTechTab:Section({
    Title = "K1ng Tech",
    Icon = "crown",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

K1ngTechSection:Toggle({
    Title = "Enable K1ng Tech",
    Icon = "power",
    Value = false,
    Callback = function(state)
        K1ngTechConfig.Enabled = state
        if state then
            ConnectK1ngTech()
        else
            if K1ngTechConfig.Connection then
                K1ngTechConfig.Connection:Disconnect()
                K1ngTechConfig.Connection = nil
            end
            if K1ngTechConfig.CharConnection then
                K1ngTechConfig.CharConnection:Disconnect()
                K1ngTechConfig.CharConnection = nil
            end
            K1ngTechConfig.OnCooldown = false
            K1ngTechConfig.Busy = false
            if K1ngTechConfig.CooldownGui then
                K1ngTechConfig.CooldownGui:Destroy()
                K1ngTechConfig.CooldownGui = nil
            end
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

K1ngTechSection:Slider({
    Title = "Detect Delay",
    Desc = "Delay before detecting uppercut anim",
    Value = {Min = 0.05, Max = 0.5, Default = 0.249},
    Step = 0.001,
    Callback = function(value)
        K1ngTechConfig.DetectDelay = value
    end
})

K1ngTechSection:Slider({
    Title = "Start Delay",
    Desc = "Delay before executing combo",
    Value = {Min = 0, Max = 0.5, Default = 0},
    Step = 0.01,
    Callback = function(value)
        K1ngTechConfig.StartDelay = value
    end
})

K1ngTechSection:Slider({
    Title = "Wait Time",
    Desc = "Time between jump and flip",
    Value = {Min = 0.05, Max = 0.5, Default = 0.15},
    Step = 0.005,
    Callback = function(value)
        K1ngTechConfig.WaitTime = value
    end
})

K1ngTechSection:Slider({
    Title = "Velo Power",
    Desc = "Jump velocity power",
    Value = {Min = 30, Max = 100, Default = 56.7},
    Step = 0.5,
    Callback = function(value)
        K1ngTechConfig.VeloPower = value
    end
})

K1ngTechSection:Slider({
    Title = "Cooldown Time",
    Desc = "Cooldown after detecting an attack",
    Value = {Min = 1, Max = 8, Default = 3},
    Step = 0.5,
    Callback = function(value)
        K1ngTechConfig.CooldownTime = value
    end
})

local GojoTechSection = AutoTechTab:Section({
    Title = "Gojo Tech",
    Icon = "infinity",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

GojoTechSection:Toggle({
    Title = "Enable Gojo Tech",
    Icon = "power",
    Value = false,
    Callback = function(state)
        GojoTechConfig.Enabled = state
        if state then
            ConnectGojoTech()
        else
            if GojoTechConfig.AutoConnection then
                GojoTechConfig.AutoConnection:Disconnect()
                GojoTechConfig.AutoConnection = nil
            end
            if GojoTechConfig.PhaseConnection then
                GojoTechConfig.PhaseConnection:Disconnect()
                GojoTechConfig.PhaseConnection = nil
            end
            if GojoTechConfig.StabilizeConnection then
                GojoTechConfig.StabilizeConnection:Disconnect()
                GojoTechConfig.StabilizeConnection = nil
            end
            if GojoTechConfig.TimerConnection then
                GojoTechConfig.TimerConnection:Disconnect()
                GojoTechConfig.TimerConnection = nil
            end
            GojoTechConfig.Busy = false
            GojoTechConfig.IsTimerReady = true
            GojoTechConfig.AutoMode = false
        end
    end
})

GojoTechSection:Toggle({
    Title = "Auto Mode (detect anim)",
    Icon = "refresh-cw",
    Value = false,
    Callback = function(state)
        GojoTechConfig.AutoMode = state
        if state and GojoTechConfig.Enabled then
            ConnectGojoTech()
        end
    end
})

GojoTechSection:Slider({
    Title = "Start Y Offset",
    Value = {Min = -50, Max = 50, Default = -10},
    Step = 1,
    Callback = function(value)
        GojoTechConfig.StartYOffset = value
    end
})

GojoTechSection:Slider({
    Title = "End Y Offset",
    Value = {Min = -50, Max = 50, Default = 10},
    Step = 1,
    Callback = function(value)
        GojoTechConfig.EndYOffset = value
    end
})

GojoTechSection:Slider({
    Title = "Float Duration",
    Value = {Min = 0.1, Max = 2, Default = 0.7},
    Step = 0.05,
    Callback = function(value)
        GojoTechConfig.FloatDuration = value
    end
})

GojoTechSection:Slider({
    Title = "Q Delay",
    Value = {Min = 0, Max = 0.2, Default = 0.04},
    Step = 0.01,
    Callback = function(value)
        GojoTechConfig.QDelay = value
    end
})

GojoTechSection:Button({
    Title = "Manual Float",
    Icon = "play",
    Justify = "Between",
    Callback = function()
        if GojoTechConfig.Enabled and GojoTechConfig.IsTimerReady then
            task.spawn(GojoStartFloat)
        end
    end
})

GojoTechSection:Button({
    Title = "Reset to Default",
    Icon = "refresh-cw",
    Justify = "Between",
    Callback = function()
        GojoTechConfig.StartYOffset = -10
        GojoTechConfig.EndYOffset = 10
        GojoTechConfig.FloatDuration = 0.7
        GojoTechConfig.QDelay = 0.04
        WindUI:Notify({
            Title = "Reset",
            Content = "Gojo Tech settings reset to default",
            Icon = "check-circle",
            Duration = 2,
        })
    end
})

local LixTechSection = AutoTechTab:Section({
    Title = "Lix Tech",
    Icon = "settings-2",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

LixTechSection:Paragraph({
    Title = "Notice",
    Content = "Turn off Shift Lock before using Lix Tech!",
})

LixTechSection:Toggle({
    Title = "Enable Lix Tech",
    Icon = "power",
    Value = false,
    Callback = function(state)
        LixTechConfig.Enabled = state
        if state then
            ConnectLixTech()
        else
            if LixTechConfig.Connection then
                LixTechConfig.Connection:Disconnect()
                LixTechConfig.Connection = nil
            end
            LixTechConfig.Busy = false
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

LixTechSection:Slider({
    Title = "Delay",
    Value = {Min = 0.1, Max = 2, Default = 0.3},
    Step = 0.05,
    Callback = function(value)
        LixTechConfig.Delay = value
    end
})

local KyotoSection = AutoTechTab:Section({
    Title = "Auto Kyoto",
    Icon = "activity",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

KyotoSection:Toggle({
    Title = "Enable Auto Kyoto",
    Icon = "power",
    Value = false,
    Callback = function(state)
        AutoKyotoConfig.Enabled = state
        if state then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                SetupKyotoListener(hum)
            end
        else
            if AutoKyotoConfig.Connection then
                AutoKyotoConfig.Connection:Disconnect()
                AutoKyotoConfig.Connection = nil
            end
        end
    end
})

KyotoSection:Slider({
    Title = "Speed",
    Value = {Min = 1, Max = 30, Default = 8.6},
    Step = 0.1,
    Callback = function(value)
        AutoKyotoConfig.Speed = value
    end
})

KyotoSection:Slider({
    Title = "Animation Delay",
    Value = {Min = 0.1, Max = 5, Default = 1.71},
    Step = 0.01,
    Callback = function(value)
        AutoKyotoConfig.AnimationDelay = value
    end
})

local InstantLethalSection = AutoTechTab:Section({
    Title = "Instant Lethal",
    Icon = "target",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

InstantLethalSection:Toggle({
    Title = "Enable Instant Lethal",
    Icon = "power",
    Value = false,
    Callback = function(state)
        InstantLethalConfig.Enabled = state
        if state then
            ConnectInstantLethal()
        else
            if InstantLethalConfig.Connection then
                InstantLethalConfig.Connection:Disconnect()
                InstantLethalConfig.Connection = nil
            end
        end
    end
})

InstantLethalSection:Slider({
    Title = "Smoothness",
    Value = {Min = 0.1, Max = 1, Default = 0.22},
    Step = 0.01,
    Callback = function(value)
        InstantLethalConfig.Smoothness = value
    end
})

local LethalDashSection = AutoTechTab:Section({
    Title = "Lethal Dash",
    Icon = "arrow-right",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

LethalDashSection:Toggle({
    Title = "Enable Lethal Dash",
    Icon = "power",
    Value = false,
    Callback = function(state)
        LethalDashConfig.Enabled = state
        if state then
            ConnectLethalDash()
        else
            if LethalDashConfig.Connection then
                LethalDashConfig.Connection:Disconnect()
                LethalDashConfig.Connection = nil
            end
            if LethalDashConfig.LerpConnection then
                LethalDashConfig.LerpConnection:Disconnect()
                LethalDashConfig.LerpConnection = nil
            end
            LethalDashConfig.Busy = false
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

LethalDashSection:Slider({
    Title = "Wait Time",
    Value = {Min = 0.5, Max = 3, Default = 1.6},
    Step = 0.05,
    Callback = function(value)
        LethalDashConfig.WaitTime = value
    end
})

LethalDashSection:Slider({
    Title = "Snap Duration",
    Value = {Min = 0.1, Max = 1, Default = 0.38},
    Step = 0.02,
    Callback = function(value)
        LethalDashConfig.SnapDuration = value
    end
})

LethalDashSection:Slider({
    Title = "Velo Power",
    Value = {Min = 10, Max = 150, Default = 62},
    Step = 1,
    Callback = function(value)
        LethalDashConfig.JumpPower = value
    end
})

LethalDashSection:Slider({
    Title = "Lock Distance",
    Value = {Min = 5, Max = 50, Default = 15},
    Step = 1,
    Callback = function(value)
        LethalDashConfig.LockDistance = value
    end
})

LethalDashSection:Slider({
    Title = "Cam Smooth Power",
    Value = {Min = 0.01, Max = 1, Default = 0.15},
    Step = 0.01,
    Callback = function(value)
        LethalDashConfig.SmoothPower = value
    end
})

local BoomyLethalSection = AutoTechTab:Section({
    Title = "Boomy Lethal Dash",
    Icon = "zap",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

BoomyLethalSection:Toggle({
    Title = "Enable Boomy Lethal Dash",
    Icon = "power",
    Value = false,
    Callback = function(state)
        BoomyLethalConfig.Enabled = state
        if state then
            BoomyLethal_connect()
        else
            if BoomyLethalConfig.Connection then
                BoomyLethalConfig.Connection:Disconnect()
                BoomyLethalConfig.Connection = nil
            end
            if BoomyLethalConfig.CharConnection then
                BoomyLethalConfig.CharConnection:Disconnect()
                BoomyLethalConfig.CharConnection = nil
            end
            BoomyLethalConfig.Debounce = false
            BoomyLethalConfig.Blocked = false
            BoomyLethalConfig.IsExecuting = false
            BoomyLethal_cancelActiveLockAndRestore()
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

BoomyLethalSection:Slider({
    Title = "Wait Detect",
    Value = {Min = 0.1, Max = 10, Default = 3.2},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.WaitDetect = value
    end
})

BoomyLethalSection:Slider({
    Title = "Wait Jump",
    Value = {Min = 0, Max = 5, Default = 0},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.WaitJump = value
    end
})

BoomyLethalSection:Slider({
    Title = "Wait Remote",
    Value = {Min = 0, Max = 5, Default = 1},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.WaitRemote = value
    end
})

BoomyLethalSection:Slider({
    Title = "Lock Duration",
    Value = {Min = 0.1, Max = 20, Default = 9.7},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.LockDuration = value
    end
})

BoomyLethalSection:Slider({
    Title = "Target Radius",
    Value = {Min = 1, Max = 150, Default = 67.7},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.TargetRadius = value
    end
})

BoomyLethalSection:Slider({
    Title = "Cooldown",
    Value = {Min = 0.1, Max = 20, Default = 10},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.Cooldown = value
    end
})

BoomyLethalSection:Slider({
    Title = "Responsiveness",
    Value = {Min = 1, Max = 10000, Default = 857},
    Step = 1,
    Callback = function(value)
        BoomyLethalConfig.Responsiveness = value
    end
})

BoomyLethalSection:Slider({
    Title = "Initial Delay",
    Value = {Min = 0, Max = 30, Default = 13},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.InitialDelay = value
    end
})

BoomyLethalSection:Slider({
    Title = "Jump Power",
    Value = {Min = 1, Max = 150, Default = 68},
    Step = 1,
    Callback = function(value)
        BoomyLethalConfig.ForceJumpUpwardVelocity = value
    end
})

BoomyLethalSection:Toggle({
    Title = "Cancel Enabled",
    Value = true,
    Callback = function(state)
        BoomyLethalConfig.CancelEnabled = state
    end
})

BoomyLethalSection:Slider({
    Title = "Cancel Delay",
    Value = {Min = 0, Max = 2, Default = 0.4},
    Step = 0.01,
    Callback = function(value)
        BoomyLethalConfig.LoopDashCancelDelay = value
    end
})

BoomyLethalSection:Slider({
    Title = "Accuracy",
    Value = {Min = 0, Max = 50, Default = 15},
    Step = 0.5,
    Callback = function(value)
        BoomyLethalConfig.LoopDashAccuracy = value
    end
})

BoomyLethalSection:Slider({
    Title = "Dash Duration",
    Value = {Min = 0.1, Max = 5, Default = 1.5},
    Step = 0.1,
    Callback = function(value)
        BoomyLethalConfig.DashDuration = value
    end
})

BoomyLethalSection:Toggle({
    Title = "Flick Enabled",
    Value = false,
    Callback = function(state)
        BoomyLethalConfig.FlickEnabled = state
    end
})

BoomyLethalSection:Slider({
    Title = "Flick Delay",
    Value = {Min = 0, Max = 1, Default = 0.2},
    Step = 0.01,
    Callback = function(value)
        BoomyLethalConfig.FlickDelay = value
    end
})

BoomyLethalSection:Button({
    Title = "Cycle Mode",
    Icon = "rotate-cw",
    Justify = "Between",
    Callback = function()
        local modes = {"V1", "V2", "V3"}
        local function findModeIndex(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then return i end
    end
    return nil
end
local currentIndex = findModeIndex(modes, BoomyLethalConfig.LoopDashMode) or 1
        local nextIndex = currentIndex % #modes + 1
        BoomyLethalConfig.LoopDashMode = modes[nextIndex]
        WindUI:Notify({
            Title = "Boomy Lethal",
            Content = "Mode: " .. modes[nextIndex],
            Icon = "rotate-cw",
            Duration = 2,
        })
    end
})

local TwistedSection = AutoTechTab:Section({
    Title = "Twisted",
    Icon = "repeat",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

TwistedSection:Toggle({
    Title = "Enable Twisted",
    Icon = "power",
    Value = false,
    Callback = function(state)
        TwistedConfig.Enabled = state
        if state then
            ConnectTwisted()
        else
            if TwistedConfig.Connection then
                TwistedConfig.Connection:Disconnect()
                TwistedConfig.Connection = nil
            end
            if TwistedConfig.AutoRotateConnection then
                TwistedConfig.AutoRotateConnection:Disconnect()
                TwistedConfig.AutoRotateConnection = nil
            end
            TwistedConfig.Busy = false
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

local ITWDSection = AutoTechTab:Section({
    Title = "Instant Twisted V1",
    Icon = "repeat",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

ITWDSection:Toggle({
    Title = "Enable Instant Twisted",
    Icon = "power",
    Value = false,
    Callback = function(state)
        InstantTwistedWiseDirConfig.Enabled = state
        if state then
            ConnectInstantTwistedWiseDir()
            if not InstantTwistedWiseDirConfig.CharConnection then
                InstantTwistedWiseDirConfig.CharConnection = LocalPlayer.CharacterAdded:Connect(function()
                    if InstantTwistedWiseDirConfig.Enabled then
                        task.wait(0.5)
                        ConnectInstantTwistedWiseDir()
                    end
                end)
            end
        else
            if InstantTwistedWiseDirConfig.AnimConnection then
                InstantTwistedWiseDirConfig.AnimConnection:Disconnect()
                InstantTwistedWiseDirConfig.AnimConnection = nil
            end
            if InstantTwistedWiseDirConfig.CharConnection then
                InstantTwistedWiseDirConfig.CharConnection:Disconnect()
                InstantTwistedWiseDirConfig.CharConnection = nil
            end
            if InstantTwistedWiseDirConfig.RotateConn then
                InstantTwistedWiseDirConfig.RotateConn:Disconnect()
                InstantTwistedWiseDirConfig.RotateConn = nil
            end
            if InstantTwistedWiseDirConfig.GyroLock then
                InstantTwistedWiseDirConfig.GyroLock:Destroy()
                InstantTwistedWiseDirConfig.GyroLock = nil
            end
            InstantTwistedWiseDirConfig.DoingTheThing = false
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

ITWDSection:Slider({
    Title = "Dash Wait",
    Value = {Min = 0.05, Max = 0.5, Default = 0.23},
    Step = 0.01,
    Callback = function(value)
        InstantTwistedWiseDirConfig.DashWait = value
    end
})

ITWDSection:Slider({
    Title = "After Dash",
    Value = {Min = 0.005, Max = 0.2, Default = 0.02},
    Step = 0.005,
    Callback = function(value)
        InstantTwistedWiseDirConfig.AfterDash = value
    end
})

ITWDSection:Slider({
    Title = "Turn Time",
    Value = {Min = 0.005, Max = 0.1, Default = 0.025},
    Step = 0.005,
    Callback = function(value)
        InstantTwistedWiseDirConfig.TurnTime = value
    end
})

ITWDSection:Slider({
    Title = "Stay Left",
    Value = {Min = 0.01, Max = 0.3, Default = 0.07},
    Step = 0.01,
    Callback = function(value)
        InstantTwistedWiseDirConfig.StayLeft = value
    end
})

ITWDSection:Slider({
    Title = "Lock Time",
    Value = {Min = 0.05, Max = 0.5, Default = 0.15},
    Step = 0.01,
    Callback = function(value)
        InstantTwistedWiseDirConfig.LockTime = value
    end
})

ITWDSection:Slider({
    Title = "Predict",
    Value = {Min = 0.05, Max = 0.6, Default = 0.22},
    Step = 0.01,
    Callback = function(value)
        InstantTwistedWiseDirConfig.Predict = value
    end
})

ITWDSection:Slider({
    Title = "Max Distance",
    Value = {Min = 20, Max = 300, Default = 100},
    Step = 5,
    Callback = function(value)
        InstantTwistedWiseDirConfig.MaxDist = value
    end
})

ITWDSection:Slider({
    Title = "Turn Degrees",
    Value = {Min = -180, Max = -10, Default = -87},
    Step = 1,
    Callback = function(value)
        InstantTwistedWiseDirConfig.TurnDeg = value
    end
})

ITWDSection:Button({
    Title = "Reset to Default",
    Icon = "refresh-cw",
    Justify = "Between",
    Callback = function()
        InstantTwistedWiseDirConfig.DashWait = 0.23
        InstantTwistedWiseDirConfig.AfterDash = 0.02
        InstantTwistedWiseDirConfig.TurnTime  = 0.025
        InstantTwistedWiseDirConfig.StayLeft  = 0.07
        InstantTwistedWiseDirConfig.LockTime  = 0.15
        InstantTwistedWiseDirConfig.Predict   = 0.22
        InstantTwistedWiseDirConfig.MaxDist   = 100
        InstantTwistedWiseDirConfig.TurnDeg   = -87
        WindUI:Notify({
            Title   = "Reset",
            Content = "Twisted Combo settings reset to default",
            Icon    = "check-circle",
            Duration = 2,
        })
    end
})

local InstantTwistedV2Section = AutoTechTab:Section({
    Title = "Instant Twisted V2",
    Icon = "repeat",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

InstantTwistedV2Section:Toggle({
    Title = "Enable Instant Twisted V2",
    Icon = "power",
    Value = false,
    Callback = function(state)
        InstantTwistedV2Config.Enabled = state
        if state then
            ConnectInstantTwistedV2()
        else
            if InstantTwistedV2Config.AnimConnection then
                InstantTwistedV2Config.AnimConnection:Disconnect()
                InstantTwistedV2Config.AnimConnection = nil
            end
            if InstantTwistedV2Config.CharConnection then
                InstantTwistedV2Config.CharConnection:Disconnect()
                InstantTwistedV2Config.CharConnection = nil
            end
            if InstantTwistedV2_noclipConnection then
                InstantTwistedV2_noclipConnection:Disconnect()
                InstantTwistedV2_noclipConnection = nil
            end
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

InstantTwistedV2Section:Slider({
    Title = "Dash Duration",
    Value = {Min = 0.1, Max = 2, Default = 0.6},
    Step = 0.01,
    Callback = function(value)
        InstantTwistedV2Config.DashDuration = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Delay",
    Value = {Min = 0.05, Max = 0.5, Default = 0.237},
    Step = 0.001,
    Callback = function(value)
        InstantTwistedV2Config.Delay = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Noclip Range",
    Value = {Min = 1, Max = 30, Default = 10},
    Step = 1,
    Callback = function(value)
        InstantTwistedV2Config.NoclipRange = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Aim Range",
    Value = {Min = 1, Max = 50, Default = 10},
    Step = 1,
    Callback = function(value)
        InstantTwistedV2Config.AimRange = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Angle 1",
    Value = {Min = -180, Max = 180, Default = 100},
    Step = 1,
    Callback = function(value)
        InstantTwistedV2Config.Angle1 = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Angle 2",
    Value = {Min = -180, Max = 180, Default = 160},
    Step = 1,
    Callback = function(value)
        InstantTwistedV2Config.Angle2 = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Angle 3",
    Value = {Min = -180, Max = 180, Default = 60},
    Step = 1,
    Callback = function(value)
        InstantTwistedV2Config.Angle3 = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Angle 4",
    Value = {Min = -180, Max = 180, Default = 0},
    Step = 1,
    Callback = function(value)
        InstantTwistedV2Config.Angle4 = value
    end
})

InstantTwistedV2Section:Slider({
    Title = "Twist Delay",
    Value = {Min = 0.01, Max = 0.5, Default = 0.1},
    Step = 0.001,
    Callback = function(value)
        InstantTwistedV2Config.TwistDelay = value
    end
})

local SideDashNewSection = AutoTechTab:Section({
    Title = "Side Dash ( Only Player )",
    Icon = "zap",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

SideDashNewSection:Toggle({
    Title = "Enable Side Dash",
    Icon = "power",
    Value = false,
    Callback = function(state)
        SideDashNewConfig.Enabled = state
        if state then
            local char = LocalPlayer.Character
            if char then
                task.spawn(function() sd_connect(char) end)
            end
            if not SideDashNewConfig.charConnection then
                SideDashNewConfig.charConnection = LocalPlayer.CharacterAdded:Connect(function(char)
                    SideDashNewConfig.isDashing   = false
                    SideDashNewConfig.debounce    = false
                    SideDashNewConfig.activeDashId = SideDashNewConfig.activeDashId + 1
                    SideDashNewConfig.velocityHistories = {}
                    if SideDashNewConfig.Enabled then
                        task.wait(1)
                        sd_connect(char)
                    end
                end)
            end
        else
            sd_disconnect()
            if SideDashNewConfig.charConnection then
                SideDashNewConfig.charConnection:Disconnect()
                SideDashNewConfig.charConnection = nil
            end
        end
    end
})

local function refreshPlayerListForDropdown()
    local playerNames = {"Auto"}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(playerNames, plr.Name)
        end
    end
    return playerNames
end

task.wait(1)
SideDashNewSection:Dropdown({
    Title = "Select Target",
    Desc = "Choose Auto or a specific player",
    Values = refreshPlayerListForDropdown(),
    Default = "Auto",
    Callback = function(selected)
        if selected == "Auto" then
            SideDashNewConfig.UseAutoTarget = true
            SideDashNewConfig.SelectedTargetName = nil
            SideDashNewConfig.targetIsDead = false
        else
            SideDashNewConfig.UseAutoTarget = false
            SideDashNewConfig.SelectedTargetName = selected
            SideDashNewConfig.targetIsDead = false
        end
    end
})

SideDashNewSection:Slider({
    Title = "Target Distance",
    Icon = "crosshair",
    Value = {Min = 5, Max = 100, Default = 50},
    Step = 1,
    Callback = function(value)
        SideDashNewConfig.TargetDistance = value
    end
})

SideDashNewSection:Button({
    Title = "Refresh Player List",
    Icon = "refresh-cw",
    Justify = "Between",
    Callback = function()
        WindUI:Notify({
            Title = "Refresh",
            Content = "Please restart the script or reload the tab to update player list",
            Duration = 3,
        })
    end
})

local AutoBlockSection = AutoTechTab:Section({
    Title = "Auto Block",
    Icon = "shield",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

AutoBlockSection:Toggle({
    Title = "Enable Auto Block",
    Icon = "power",
    Value = false,
    Callback = function(state)
        AutoBlockConfig.Enabled = state
        if state then
            AutoBlockStartDetect()
            if AutoBlockConfig.BlockSpin then
                SetupBlockSpin()
            end
        else
            AutoBlockStopDetect()
            if BlockSpinConnection then
                BlockSpinConnection:Disconnect()
                BlockSpinConnection = nil
            end
            local _, hum = GetCharacterData()
            if hum then hum.AutoRotate = true end
        end
    end
})

AutoBlockSection:Toggle({
    Title = "M1 After Block",
    Icon = "sword",
    Value = false,
    Callback = function(state)
        AutoBlockConfig.M1AfterBlock = state
    end
})

AutoBlockSection:Toggle({
    Title = "Auto Counter",
    Icon = "refresh-cw",
    Value = false,
    Callback = function(state)
        AutoBlockConfig.AutoCounter = state
    end
})

AutoBlockSection:Toggle({
    Title = "Block Spin",
    Icon = "rotate-cw",
    Value = false,
    Callback = function(state)
        AutoBlockConfig.BlockSpin = state
        if AutoBlockConfig.Enabled then
            if state then
                SetupBlockSpin()
            else
                if BlockSpinConnection then
                    BlockSpinConnection:Disconnect()
                    BlockSpinConnection = nil
                end
                local _, hum = GetCharacterData()
                if hum then hum.AutoRotate = true end
            end
        end
    end
})

AutoBlockSection:Slider({
    Title = "Block Range",
    Value = {Min = 5, Max = 50, Default = 15},
    Step = 1,
    Callback = function(value)
        AutoBlockConfig.NormalRange = value
    end
})

AutoBlockSection:Button({
    Title = "Reset Range to Default (15)",
    Icon = "refresh-cw",
    Justify = "Between",
    Callback = function()
        AutoBlockConfig.NormalRange = 15
        WindUI:Notify({
            Title = "Reset",
            Content = "Block range reset to 15",
            Icon = "check-circle",
            Duration = 2,
        })
    end
})


local AntiShakeSection = AutoTechTab:Section({
    Title = "Anti Shake",
    Icon = "shield",
    TextSize = 18,
    TextXAlignment = "Center",
    Box = true,
    BoxBorder = true,
    Opened = false,
    FontWeight = Enum.FontWeight.SemiBold,
})

AntiShakeSection:Paragraph({
    Title = "Information",
    Content = "Prevents camera shake when hit.",
})

AntiShakeSection:Toggle({
    Title = "Enable Anti Shake",
    Icon = "power",
    Value = false,
    Callback = function(state)
        AntiShakeConfig.Enabled = state
        if state then
            SetupAntiShake()
        else
            if AntiShakeConfig.Connection then
                AntiShakeConfig.Connection:Disconnect()
                AntiShakeConfig.Connection = nil
            end
        end
    end
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local TonghopTab = Window:Tab({
    Title = "TongHop",
    Icon = "triangle-alert",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local MovesetsTab = Window:Tab({
    Title = "Movesets",
    Icon = "package",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local TechTab = Window:Tab({
    Title = "Tech",
    Icon = "globe",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local FixLagTab = Window:Tab({
    Title = "FixLag",
    Icon = "rocket",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local TsbTab = Window:Tab({
    Title = "TSB",
    Icon = "shield-user",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "list-todo",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local EmoteTab = Window:Tab({
    Title = "Emote Limited",
    Icon = "laugh",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "chart-no-axes-combined",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "users-round",
    IconColor = Color3.fromHex("#FFFFFF"),
})

local HopTab = Window:Tab({
    Title = "Hop",
    Icon = "headset",
    IconColor = Color3.fromHex("#FFFFFF"),
})

MainTab:Toggle({
    Title = "Silent Aim",
    Callback = function(Value)
        MasterEnabled = Value
        CombatEnabled = Value
        if not Value then
            CurrentTarget = nil
        end
    end
})

MainTab:Toggle({
    Title = "Cam Lock",
    Desc = "Lock camera on target",
    Callback = function(Value)
        CamlockEnabled = Value
        if not Value then
            CamlockTarget = nil
        end
    end
})

TonghopTab:Button({
    Title = "BaeMinhHub",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/ngm2807-sudo/3bb38870095ccba814f13993813410f3/raw/32addd5af4b65ffa18a7002eac6e71b9f01076ed/BaeMinhHub.lua"))()
    end
})

TonghopTab:Button({
    Title = "TthanhHub",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/Tthanh%20Tong%20Hop%20Tech.txt"))()
    end
})

MovesetsTab:Button({
    Title = "Sukuna",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/damir512/whendoesbrickdie/main/tspno.txt", true))()
    end
})

MovesetsTab:Button({
    Title = "Gojo",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/KJ-The-Strongest-Battlegrounds-battleground-gojo-script-saitama-to-gojo-26980"))()
    end
})

MovesetsTab:Button({
    Title = "Kars",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/OfficialAposty/RBLX-Scripts/refs/heads/main/UltimateLifeForm.lua"))()
    end
})

MovesetsTab:Button({
    Title = "Wally West",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Nova2ezz/west/refs/heads/main/Protected_4638864115822087.lua.txt"))()
    end
})

MovesetsTab:Button({
    Title = "MAFIOSO",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Lovelymoonlight/Lovelymoonlight/refs/heads/main/Baldy%20to%20mafioso'))()
    end
})

MovesetsTab:Button({
    Title = "Beerus",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sparksnaps/Beerus-The-Destroyer/refs/heads/main/Lua"))()
    end
})

MovesetsTab:Button({
    Title = "Madara",
    Desc = "",
    Callback = function()
        getgenv().Cutscene = false
        loadstring(game:HttpGet("https://raw.githubusercontent.com/LolnotaKid/SCRIPTSBYVEUX/refs/heads/main/BoombasticLol.lua.txt"))()
    end
})

MovesetsTab:Button({
    Title = "Golden Head",
    Desc = "",
    Callback = function()
        getgenv().stand = false
        getgenv().ken = false
        getgenv().Spawn = true
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Saitama%20to%20golden%20sigma'))()
    end
})

MovesetsTab:Button({
    Title = "Jun",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/GoldenHeads2/f66279000c58a020e894a6db44914838/raw/62e53e1acacec0b38b43cd0f594292c32e09c39b/gistfile1.txt"))()
    end
})

MovesetsTab:Button({
    Title = "Mahito",
    Desc = "",
    Callback = function()
        getgenv().Swordm1 = true
        getgenv().night = false
        getgenv().plushie = false
        getgenv().blackflash = true
        getgenv().chat = false
        loadstring(game:HttpGet('https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Mahito%20v2%20sigma%20tp%20exploit'))()
    end
})

MovesetsTab:Button({
    Title = "Naruto",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/LolnotaKid/NarutoBeatUpSasukeAss/refs/heads/main/NarutoCums"))()
    end
})

MovesetsTab:Button({
    Title = "Gabriel",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/damir512/youinsinificants/main/insignificantFuck.txt", true))()
    end
})

MovesetsTab:Button({
    Title = "Void Garou",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yes1nt/yes/refs/heads/main/Void%20Reaper%20Obfuscated.txt"))()
    end
})

MovesetsTab:Button({
    Title = "Mastery Deku",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/xKextYP5"))()
    end
})

MovesetsTab:Button({
    Title = "SONIC.EXE",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/4zLt8a2P/raw"))()
    end
})

TechTab:Button({
    Title = "Supa Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/SupaLegitV2/refs/heads/main/SupaLegitV2.lua",true))()
    end
})

TechTab:Button({
    Title = "Sikibidi Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/Sikibidi%20Tech%20New.lua"))()
    end
})

TechTab:Button({
    Title = "Pefect LoopDash",
    Desc = "By ThanhDuy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/Pefect%20LoopDash%20V2"))()
    end
})

TechTab:Button({
    Title = "Instant Lethal V1",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/Instant-Lethal/refs/heads/main/InstanLethal.lua"))()
    end
})

TechTab:Button({
    Title = "Instant Lethal V2",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/InstantLethalV2.luau"))()
    end
})

TechTab:Button({
    Title = "Surfing Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/GarouSurfingTech/refs/heads/main/Protected_2674673126232747.lua"))()
    end
})

TechTab:Button({
    Title = "Loop Dash V2",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/84e2bd29cccc0f5302267e4dc952cff6816db4af36416cbd477daaa26d60863d.lua"))()
    end
})

TechTab:Button({
    Title = "Mini Supa Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/MiniSupaTech.luau"))()
    end
})

TechTab:Button({
    Title = "Auto Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/NewAutoTech/refs/heads/main/Protected_6389347658054908.lua"))()
    end
})

TechTab:Button({
    Title = "Instant Twisted",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantTwistedRevamp/refs/heads/main/Protected_7455521176683315.lua"))()
    end
})

TechTab:Button({
    Title = "Instant Lethal",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantLethal/refs/heads/main/Protected_5983112998592296.lua"))()
    end
})

TechTab:Button({
    Title = "Combat Gui",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/CombatGUI/refs/heads/main/TSBCombatGUI"))()
    end
})

TechTab:Button({
    Title = "Kai Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/YQANTGV2/YQANTGV2/refs/heads/main/Kai"))()
    end
})

TechTab:Button({
    Title = "Auto Downslam",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/atds"))()
    end
})

TechTab:Button({
    Title = "Gojo Tech Old",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ngoclinh02042011-stack/Gojo-Tech/refs/heads/main/DuydepzaiGojoTech.lua"))()
    end
})

TechTab:Button({
    Title = "Gojo Tech New",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://gojotech.tsbscripts.workers.dev/"))()
    end
})

TechTab:Button({
    Title = "Supa V2 Fix",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/2753546c83053761e44664d36ffe5035d6e20fc8aee1d19f0eb7b933974ae537.lua"))()
    end
})

TechTab:Button({
    Title = "Side Dash V1",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/94a29c6b88bfe8c49ea221eaa9225398790c1b7436b0f08caf7517c3002e8782.lua"))()
    end
})

TechTab:Button({
    Title = "Side Dash V2",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/52b3b7317bd590bfe678009b3359e74316d9c731ec1395f3e800718d520501f1.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Tech V2.5",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/All-Tech/refs/heads/main/AutoTech.luau"))()
    end
})

TechTab:Button({
    Title = "Lethal Dash V1",
    Desc = "",
    Callback = function()
        getgenv().SCRIPT_KEY = "502d56da-8bf7-410a-b1f3-9a3e6e0f62aa" loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/a96b9a4a030dd50b2b737088b6401b7a7500f4c90a9119c9525a940e5d05c3f7/download"))()
    end
})

TechTab:Button({
    Title = "Supa Cancel",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/SupaCancel"))()
    end
})

TechTab:Button({
    Title = "Normal Punch Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/NormalPunchTech"))()
    end
})

TechTab:Button({
    Title = "TwetiQ Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/bduzr7pS/raw"))()
    end
})

TechTab:Button({
    Title = "Lethal Revamp",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantLethalRevamp/refs/heads/main/Protected_6977817281150270.lua"))()
    end
})

TechTab:Button({
    Title = "Reflex Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/ReflexTech/refs/heads/main/Protected_7459802026542834.lua"))()
    end
})

TechTab:Button({
    Title = "Oreo Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/OreoTech/refs/heads/main/Protected_6856895483929371.lua"))()
    end
})

TechTab:Button({
    Title = "Supa V3",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/ea0b7cbd8c395e01ec38271794b2559808d26501bd6e6e30c48660759a7db7b3.lua"))()
    end
})

TechTab:Button({
    Title = "Kiba Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kietsonphongthanhnghia-a11y/Uhyeah/refs/heads/main/Protected_1425045629292384.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Instant Twisted New",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/Instant-Twisted-Sigma/refs/heads/main/instant_Twisted%20(1).lua"))()
    end
})

TechTab:Button({
    Title = "3 in 1 Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/NJfMV5ze/raw"))()
    end
})

TechTab:Button({
    Title = "Solitude Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/86e0da30855e98f4a12efbde49222668b5d711e1ef1b099db7d5eca09bba15ac/download"))()
    end
})

TechTab:Button({
    Title = "CamLock V9",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/924afb8e0b82b94c3852bd7bdbad2183713eadf7fe084bfbee9869668add0286/download"))()
    end
})

TechTab:Button({
    Title = "Reflex Tech V2",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/ReflexTech/refs/heads/main/Protected_7459802026542834.lua"))()
    end
})

TechTab:Button({
    Title = "KibaZ Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Kibaz/main/kibaztech.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Binding Cloth Dash Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/ngm2807-sudo/aeccf3ce4aef451f61f56d6b21ade701/raw/bindingclothdash.lua"))()
    end
})

TechTab:Button({
    Title = "Supa Tech ( Settings )",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/SupaLegit-Release/refs/heads/main/SupaLegit.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Kyoto Rework",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/KyotoTechRework/refs/heads/main/Protected_9378660372508532.lua"))()
    end
})

TechTab:Button({
    Title = "Loop Dash V3",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/774bd154b84449a478cb0d5717df6f56eddf16d5d85a87792d84978a1f75e84a/download"))()
    end
})

TechTab:Button({
    Title = "Auto Uppercut",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://arch-http.vercel.app/files/Auto%20Uppercut.lua"))()
    end
})

TechTab:Button({
    Title = "The Fish X (Dash)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/TheFishX/refs/heads/main/obfuscated_script-1757331576860.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Auto Kyoto (By Mark)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mark22028/Auto-Kyoto-Combo/refs/heads/main/Skibidi%20Sigma%20Combo.txt"))()
    end
})

TechTab:Button({
    Title = "Auto Kyoto Combo",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Thestrongesthgg-/main/Kyoto.lua.txt"))()
    end
})

TechTab:Button({
    Title = "KibaZ V1",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/KIBAZ-TECH-/main/Kibaztechv1.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Supa Vole Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/SupaVeloTech.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Combo Kyoto (Corex Hub)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Thestrongesthgg-/main/Kyoto.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Lethal Dash",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/57a4d240a2440f0450986c966469092ccfb8d4797392cb8f469fa8b6e605e64d/download"))()
    end
})

TechTab:Button({
    Title = "Hex Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DuyYeuEmNhieuLam/Hex-Tech/refs/heads/main/Hex%20Tech.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Combo Kyoto (Saturn Hub)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sigmavexr/AUTO-KYOTO-SATURN-HUB/refs/heads/main/AUTO%20KYOTO"))()
    end
})

TechTab:Button({
    Title = "Skibidi Tech v4",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenduchunganh519-source/IL4SK-skibidi/refs/heads/main/IL4SK%20skibidi"))()
    end
})

TechTab:Button({
    Title = "Dripz Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ngoclinh02042011-stack/DripzTech/refs/heads/main/DripzTech.txt"))()
    end
})

TechTab:Button({
    Title = "Auto Block V8",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/5659752fa0f7c10df56777eafd8f4813f15d3cde1b206f7e10f6b87af4fa9dfd/download"))()
    end
})

TechTab:Button({
    Title = "Auto Block V12",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/CombatGuiNew/refs/heads/main/Auto%20Block%20V12"))()
    end
})

TechTab:Button({
    Title = "Garou Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/GarouTechs/refs/heads/main/Protected_9831634675356265.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Block V1 (Cps Network)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/6f502e252308fb97855295005faa73a0.lua"))()
    end
})

TechTab:Button({
    Title = "Garou Damage (2 Garou)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/GAROUDAME/refs/heads/main/TSB"))()
    end
})

TechTab:Button({
    Title = "LoopDash V2",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/28513f51c0ca2c03d4d7d94f59215d13ce1a2a470bf187f0a685b58ccb4dae98/download"))()
    end
})

TechTab:Button({
    Title = "Twinnie Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/TwinnieTech", true))()
    end
})

TechTab:Button({
    Title = "Instant Lethal V2",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/a23acf82fb18b827dca096e149ab0272fc74ea9bb8153cd43e44555acb943c86/download"))()
    end
})

TechTab:Button({
    Title = "LoopYen",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/dd205f0487a772434c4bcde88a7d11d52b207c2afda89351d4a4f6f8ecfce48d/download"))()
    end
})

TechTab:Button({
    Title = "Oreo Tech ( Setting )",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/OreoTech"))()
    end
})

TechTab:Button({
    Title = "SupaX Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/SupaxTech", true))()
    end
})

TechTab:Button({
    Title = "Boomy Twisted",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/BoomyTwisted"))()
    end
})

TechTab:Button({
    Title = "M1 Reset",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-M1-RESET-57657"))()
    end
})

TechTab:Button({
    Title = "Gojo Shuriken ",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/TSB/refs/heads/main/GojoShiruken"))()
    end
})

TechTab:Button({
    Title = "Dripz Tech",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/The-Strongest-Battlegrounds/refs/heads/main/DripzTech"))()
    end
})

TechTab:Button({
    Title = "Legit M1 Reset",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Defy-cloud/Scripts/refs/heads/main/LegitM1Reset"))()
    end
})

FixLagTab:Button({
    Title = "Fps Booster V3 (Joshzzz)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/JoshzzAlteregooo/JoshzzFpsBoosterVersion3/refs/heads/main/JoshzzNewFpsBooster"))()
    end
})

FixLagTab:Button({
    Title = "BloxStrap",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/qwertyui-is-back/Bloxstrap/main/Initiate.lua"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost (ItLouisPlay)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/ItsLouisPlay-Fps-Booster/refs/heads/main/TSB"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost (Vikichard)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VikiChardd/AntiLag_TSB/main/Protect_MeowTBS1999.lua.txt"))()
    end
})

FixLagTab:Button({
    Title = "Low GFX",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Low-GFX-38613"))()
    end
})

FixLagTab:Button({
    Title = "Turbo Lite",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/TurboLite/Script/main/FixLag.lua"))()
    end
})

FixLagTab:Button({
    Title = "Turbo Lite (Blue)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MeoLazy/Script/refs/heads/main/FixLag.lua"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Fps-boost/refs/heads/main/029298383"))()
    end
})

FixLagTab:Button({
    Title = "Fix Lag",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Fix-Lag/refs/heads/main/Made%20By%20MinhNhat"))()
    end
})

FixLagTab:Button({
    Title = "Remove Skill",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/louismich4el/ItsLouisPlayz-Scripts/main/TSB%20Anti%20Lag.lua"))()
    end
})

FixLagTab:Button({
    Title = "Kaito FixLag",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaitofixlag-hub/Fixlag/refs/heads/main/fixlag.txt"))()
    end
})

FixLagTab:Button({
    Title = "Fix lag (Mumya)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/dhiPeX7H/raw"))()
    end
})

FixLagTab:Button({
    Title = "Fps Boost v0.5 (Corex Hub)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/gamerscripter90/Fps-booster/main/Fpsbooster.lua.txt"))()
    end
})

TsbTab:Button({
    Title = "Trash Can",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/yes1nt/yes/refs/heads/main/Trashcan%20Man"))()
    end
})

TsbTab:Button({
    Title = "Aimlock Universal",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/Bestaimbot/refs/heafs/main/Merebennie"))()
    end
})

TsbTab:Button({
    Title = "Napoleon Hub",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/raydjs/napoleonHub/refs/heads/main/src.lua"))()
    end
})

TsbTab:Button({
    Title = "VexonHub",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/DiosDi/VexonHub/refs/heads/main/VexonHub"))()
    end
})

TsbTab:Button({
    Title = "AimLock Old",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Mark22028-2ndAcc/Scripts/refs/heads/main/Camlock%20OldV.lua"))()
    end
})

TsbTab:Button({
    Title = "TSB Script (Emerson)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Emerson2-creator/Scripts-Roblox/refs/heads/main/TSBLuna.lua"))()
    end
})

TsbTab:Button({
    Title = "Farm Kill V1",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ngoclinh02042011-stack/Farm-Kill-V1/refs/heads/main/FarmKillV1.lua"))()
    end
})

TsbTab:Button({
    Title = "Khanh Ly Auto Farm Vip [Beta]",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/khoavipok/ScriptkhanhlyHUB/refs/heads/main/Khanhly%20strongest%20pranium"))()
    end
})

TsbTab:Button({
    Title = "Phantasm Hub",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ATrainz/Phantasm/refs/heads/main/Games/TSB.lua"))()
    end
})

TsbTab:Button({
    Title = "Invinsible",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Invisible/refs/heads/main/TSB"))()
    end
})

TsbTab:Button({
    Title = "Farm Kill",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/FARM-KILL/refs/heads/main/TSB"))()
    end
})

TsbTab:Button({
    Title = "Farm Kill V2",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/minhnhatdepzai8-cloud/Farm-Kill-V2/refs/heads/main/TSB"))()
    end
})

TsbTab:Button({
    Title = "Auto Farm",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nullrush0/Auto-Farm/refs/heads/main/Lua"))()
    end
})

TsbTab:Button({
    Title = "Dovi Hub",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/DoviHub/refs/heads/main/obfuscated_Dovi_HUB_Cracked_by_Merebennie.txt"))()
    end
})

MiscTab:Button({
    Title = "No Colldown Dash",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/RRc9D0kj/raw"))()
    end
})

MiscTab:Button({
    Title = "Oinan-Thickhoof-Axe",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Guestly-Scripts/Items-Scripts/refs/heads/main/Oinan-Thickhoof"))()
    end
})

MiscTab:Button({
    Title = "Erisyphia staff",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/GuestlyTheGreatestGuest/Scripts/refs/heads/main/Erisyphia-Staff-made-by-Guestly"))()
    end
})

MiscTab:Button({
    Title = "M1 Cid effect",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/M1-effect/refs/heads/main/Cid%20M1%20Effect.lua"))()
    end
})

MiscTab:Button({
    Title = "M1 Kars effect",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/Kars-M1-effect/refs/heads/main/Kars%20M1%20Effect.lua"))()
    end
})

MiscTab:Button({
    Title = "M1 Gojo effect",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kaimm2/data/refs/heads/main/effectm1"))()
    end
})

MiscTab:Button({
    Title = "Kill Void (Garou Strategy 1)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Duytsb1609/Kill-Void/refs/heads/main/Kill%20Void%20(%20Use%20Garou%20Strategy%201%20)"))()
    end
})

MiscTab:Button({
    Title = "Hitbox expander (Sonic)",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/The-Strongest-Battlegrounds-SION-ELTNAM-ATLASIA-61168"))()
    end
})

MiscTab:Button({
    Title = "Open UI Fling Player",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/ngm2807-sudo/7155874edfab6e1d774d5017ea0b3018/raw/32e909c874a9a5192fd52fd5afe4579e1c74cdb9/flingplayer.lua"))()
    end
})

MiscTab:Input({
    Title = "Enter username to kill",
    Desc = "Empty = nearest player",
    Placeholder = "Username...",
    Callback = function(text)
        nameInput = text
    end
})

MiscTab:Toggle({
    Title = "Auto Kill",
    Desc = "",
    Callback = function(Value)
        killEnabled = Value
    end
})

MiscTab:Toggle({
    Title = "Orbit Target",
    Desc = "",
    Callback = function(Value)
        orbitEnabled = Value
    end
})

task.spawn(function()
    while task.wait(0.1) do
        if killEnabled then
            if nameInput ~= "" then
                targetPlayer = Players:FindFirstChild(nameInput)
            else
                targetPlayer = getNearestPlayerAK()
            end
            
            if targetPlayer and targetPlayer.Character then
                local char = LocalPlayer.Character
                local thrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                local thum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                local comm = char and char:FindFirstChild("Communicate")
                
                if char and thrp and thum and comm and thum.Health > 0 then
                    local distance = (char.HumanoidRootPart.Position - thrp.Position).Magnitude
                    if distance <= 6 then
                        comm:FireServer({ Goal = "LeftClick", Mobile = true })
                        task.wait(0.15)
                        
                        tapKey(Enum.KeyCode.Q, 0.1)
                        tapKey(Enum.KeyCode.One)
                        tapKey(Enum.KeyCode.Two)
                        tapKey(Enum.KeyCode.Three)
                        tapKey(Enum.KeyCode.Four)
                        
                        task.wait(0.15)
                        tapKey(Enum.KeyCode.G, 0.15)
                        local randomKey = ({Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four})[math.random(1,4)]
                        tapKey(randomKey)
                    end
                end
            end
        end
    end
end)

local radius = 5.5
local heightMin = -1.5
local heightMax = 2
local teleportSpeed = 2

local function randomOffset()
    local dir = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)).Unit
    local height = math.random() * (heightMax - heightMin) + heightMin
    return dir * radius + Vector3.new(0, height, 0)
end

RunService.RenderStepped:Connect(function()
    if orbitEnabled and targetPlayer and targetPlayer.Character then
        local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                for _ = 1, teleportSpeed do
                    char.HumanoidRootPart.CFrame = CFrame.new(root.Position + randomOffset(), root.Position)
                end
            end
        end
    end
end)

EmoteTab:Button({
    Title = "Free slot Emote",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/kVbOxOjb/raw"))()
    end
})

EmoteTab:Button({
    Title = "Final Stand",
    Desc = "",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "final_stand",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://113876851900426"
        local track = humanoid:LoadAnimation(anim)
        track:Play()

        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
            acc.Parent = character
            acc:SetAttribute("EmoteProperty", true)

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Final Stand",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 113876851900426,
                    RealBind = acc,
                })
            end)
        end)

        task.delay(9, function()
            if not character or not character.Parent then return end
            
            local soundIds = {"112446641141594", "98080224862986"}
            for _, id in ipairs(soundIds) do
                local s = Instance.new("Sound")
                s.SoundId = "rbxassetid://" .. id
                s.Volume = 1
                s.Looped = true
                s.Parent = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
                if s.Parent then
                    s:Play()
                    Debris:AddItem(s, 60)
                end
            end

            local auraClone = ReplicatedStorage:FindFirstChild("Emotes") and 
                             ReplicatedStorage.Emotes:FindFirstChild("VFX") and
                             ReplicatedStorage.Emotes.VFX:FindFirstChild("VfxMods") and
                             ReplicatedStorage.Emotes.VFX.VfxMods:FindFirstChild("FS") and
                             ReplicatedStorage.Emotes.VFX.VfxMods.FS:FindFirstChild("vfx") and
                             ReplicatedStorage.Emotes.VFX.VfxMods.FS.vfx:FindFirstChild("Aura")
            
            if auraClone then
                auraClone = auraClone:Clone()
                for _, part in pairs(auraClone:GetChildren()) do
                    local targetPart = character:FindFirstChild(part.Name)
                    if not targetPart and part.Name == "HumanoidRootPart" then
                        targetPart = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
                    end
                    
                    if targetPart then
                        for _, fx in pairs(part:GetChildren()) do
                            if fx:IsA("ParticleEmitter") then
                                fx.LockedToPart = true
                                fx.Parent = targetPart
                                fx:SetAttribute("LimitedAura", true)
                                Debris:AddItem(fx, 65)
                            end
                        end
                    end
                end
                auraClone:Destroy()
            end
        end)
    end
})

EmoteTab:Button({
    Title = "Inner Rage",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = false, -- disable button. optional
    LockedTitle = "Locked", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- màu fallback (source gốc thiếu)
local v3189 = Color3.fromRGB(
    math.random(100,255),
    math.random(50,150),
    math.random(50,150)
)

local v67 = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
local vu68 = {}

-- animation đầu
local v69 = Instance.new("Animation")
v69.AnimationId = "rbxassetid://96993907314948"
local v70 = humanoid:LoadAnimation(v69)
v70:Play()

-- animation tiếp
v70.Stopped:Connect(function()
    local v71 = Instance.new("Animation")
    v71.AnimationId = "rbxassetid://127234845846317"
    humanoid:LoadAnimation(v71):Play()
end)

-- holder
local vu72 = Instance.new("Accessory")
vu72.Name = "#EmoteHolder_" .. math.random(1,100000)
vu72.Parent = character
CollectionService:AddTag(vu72, "emoteendstuff"..character.Name)

-- VFX chính
require(ReplicatedStorage.Emotes.VFX):MainFunction({
    Character = character,
    vfxName = "Energy Explosion",
    AnimSent = 96993907314948,
    RealBind = vu72,
    NoInsertion = true,
    Colour = v67,
})

local vu73, vu74, vu75 = {}, {}, {}

-- xử lý tóc + aura
task.delay(1.3, function()
    if not vu72.Parent then return end

    for _,acc in pairs(character.FakeHead:GetChildren()) do
        if acc:IsA("Accessory")
        and acc:FindFirstChild("Handle")
        and acc.Handle:FindFirstChild("HairAttachment") then

            local handle = acc.Handle
            table.insert(vu74, handle)

            for _,mesh in pairs(handle:GetChildren()) do
                if mesh:IsA("SpecialMesh") then
                    mesh:SetAttribute("basetext", mesh.TextureId)
                end
            end
        end
    end

    for _,hair in pairs(vu74) do
        local clone = hair:Clone()
        table.insert(vu73, clone)

        local weld = Instance.new("Weld")
        weld.Part0 = clone
        weld.Part1 = hair
        weld.Parent = clone

        clone.Parent = workspace.Thrown
        hair.Transparency = 1

        TweenService:Create(hair, TweenInfo.new(0.25), {Transparency = 0}):Play()

        local mesh = hair:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            mesh.TextureId = ""
            local glow = ReplicatedStorage.Resources.DeathEffect.Template:Clone()
            glow.Color3 = Color3.new(v3189.R*5, v3189.G*5, v3189.B*5)
            glow.Parent = clone
        end
    end

    vu68[character] = {hairs = vu74, destroy = vu73}

    -- aura holder
    local auraHolder = Instance.new("Folder")
    auraHolder.Name = "AuraHolder"
    auraHolder:SetAttribute("LimAura", true)
    auraHolder:SetAttribute("EmoteEffect", true)
    auraHolder.Parent = character

    task.delay(203, function()
        if auraHolder then auraHolder:Destroy() end
    end)

    -- aura real
    for _,obj in pairs(ReplicatedStorage.Emotes.AuraReal:GetChildren()) do
        local clone = obj:Clone()
        clone:SetAttribute("LimAura", true)

        if clone:IsA("Attachment") then
            clone.Parent = character.PrimaryPart
        else
            local weld = Instance.new("Weld")
            weld.Part0 = character.PrimaryPart
            weld.Part1 = clone
            weld.Parent = clone
        end

        for _,fx in pairs(clone:GetDescendants()) do
            if fx:IsA("ParticleEmitter") or fx:IsA("PointLight") then
                fx.Enabled = false
                fx:SetAttribute("LimitedAura", true)
                fx:SetAttribute("InnerRageAura", true)

                if fx:IsA("ParticleEmitter") then
                    fx.Color = ColorSequence.new(v3189)
                end
                if fx:IsA("PointLight") then
                    fx.Color = v3189
                    fx.Brightness = 1.3
                end

                table.insert(vu75, fx)
            end
        end

        task.delay(203, function()
            if clone then clone:Destroy() end
        end)
    end
end)

-- bật aura + đổi anim
task.delay(5.3, function()
    if not vu72.Parent then return end

    for _,fx in pairs(vu75) do
        fx.Enabled = true
    end

    task.wait(0.05)

    for _,track in pairs(humanoid:GetPlayingAnimationTracks()) do
        if track.Animation.AnimationId == "rbxassetid://127234845846317" then
            track:Stop()
            local v132 = Instance.new("Animation")
            v132.AnimationId = "rbxassetid://117177504280717"
            humanoid:LoadAnimation(v132):Play()
        end
    end
end)

    end
})

EmoteTab:Button({
    Title = "Shadow Eruption",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = false, -- disable button. optional
    LockedTitle = "Locked", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--========================
-- START SOUND (delay-based)
--========================
local soundList = {
    {
        SoundId = "rbxassetid://117425361961655",
        Volume = 0,
        ParentTorso = true,
    },
}

for delayTime, info in pairs(soundList) do
    task.delay(delayTime, function()
        local s = Instance.new("Sound")
        s.SoundId = info.SoundId
        s.Volume = info.Volume or 1
        s.Looped = info.Looped or false
        s.Parent = info.ParentTorso
            and (character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
            or workspace
        s:Play()
    end)
end

--========================
-- ANIMATION
--========================
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://121032789756540"
humanoid:LoadAnimation(anim):Play()

--========================
-- MAIN VFX
--========================
task.delay(0.1, function()
    local acc = Instance.new("Accessory")
    acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
    acc.Parent = character

    require(ReplicatedStorage.Emotes.VFX):MainFunction({
        Character = character,
        vfxName = "Shadow Eruption",
        SpecificModule = ReplicatedStorage.Emotes.VFX,
        AnimSent = 121032789756540,
        RealBind = acc,
    })
end)

--========================
-- AURA + LOOP SOUND
--========================
task.delay(8.1, function()
    if not character or not character.Parent then return end
    if not workspace:FindFirstChild("Live") then return end
    if not workspace.Live:FindFirstChild(character.Name) then return end

    -- Aura holder
    local auraFolder = Instance.new("Folder")
    auraFolder.Name = "AuraHolder"
    auraFolder.Parent = character

    -- ⚠️ THAY THẾ script.auraNew
    -- 👉 PHẢI TỒN TẠI Ở ReplicatedStorage
    local auraSource = ReplicatedStorage:WaitForChild("Emotes"):WaitForChild("AuraNew")

    for _,part in pairs(auraSource:GetChildren()) do
        local charPart = character:FindFirstChild(part.Name)
        if charPart then
            local clone = part:Clone()
            clone.Parent = auraFolder
            clone:SetAttribute("LimitedAura", true)

            task.delay(65, function()
                if clone then clone:Destroy() end
            end)

            for _,fx in pairs(clone:GetDescendants()) do
                if fx:IsA("Trail") or fx:IsA("Beam") or fx:IsA("ParticleEmitter") then
                    fx.Enabled = true
                    task.delay(60, function()
                        if fx then fx.Enabled = false end
                    end)
                end
            end
        end
    end

    -- LOOP SOUND
    local loopSound = Instance.new("Sound")
    loopSound.SoundId = "rbxassetid://128082194939921"
    loopSound.Looped = true
    loopSound.Volume = 1
    loopSound.Parent = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    loopSound:Play()

    Debris:AddItem(loopSound, 80)

    task.delay(60, function()
        TweenService:Create(loopSound, TweenInfo.new(1), {Volume = 0}):Play()
        Debris:AddItem(loopSound, 1.2)

        for _,v in pairs(character:GetDescendants()) do
            if v:GetAttribute("aura") then
                if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
                    v.Enabled = false
                    Debris:AddItem(v, 5)
                end
            end
        end
    end)
end)

    end
})

EmoteTab:Button({
    Title = "Divine Form",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = false, -- disable button. optional
    LockedTitle = "Locked", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()
-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--==============================
-- DELAYED AURA (7.14s)
--==============================
task.spawn(function()
    task.wait(7.14)

    local char = player.Character
    if not char then return end

    local auraSource =
        ReplicatedStorage.Emotes.VFX.VfxMods.Evolved.vfx.Folder

    local auraFolder = Instance.new("Folder")
    auraFolder.Name = "AuraHolder"
    auraFolder:SetAttribute("DivineForm", true)
    auraFolder:SetAttribute("LimAura", true)
    auraFolder:SetAttribute("EmoteEffect", true)
    auraFolder.Parent = char

    for _,obj in pairs(auraSource:GetChildren()) do
        if obj:IsA("BasePart") then
            local bodyPart = char:FindFirstChild(obj.Name)
            if bodyPart then
                local clone = obj:Clone()
                clone.Transparency = 1
                clone.Massless = true
                clone.Name = tostring(math.random(1, 1000))
                clone:SetAttribute("LimAura", true)
                clone.Parent = auraFolder

                local weld = Instance.new("Weld")
                weld.Part0 = bodyPart
                weld.Part1 = clone
                weld.Parent = clone

                for _,fx in pairs(clone:GetDescendants()) do
                    if fx:IsA("ParticleEmitter") or fx:IsA("Beam") then
                        fx:SetAttribute("LimitedAura", true)
                        task.delay(240, function()
                            if fx then fx.Enabled = false end
                        end)
                    end
                end

                task.delay(244, function()
                    if clone and clone.Parent then
                        clone:Destroy()
                    end
                end)
            end
        end
    end
end)

--==============================
-- MAIN ANIMATION
--==============================
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://116187503451999"
humanoid:LoadAnimation(anim):Play()

--==============================
-- MAIN VFX BIND
--==============================
local acc = Instance.new("Accessory")
acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
acc.Parent = character
acc:SetAttribute("EmoteProperty", true)

require(ReplicatedStorage.Emotes.VFX):MainFunction({
    Character = character,
    vfxName = "Divine Form",
    SpecificModule = ReplicatedStorage.Emotes.VFX,
    AnimSent = 116187503451999,
    RealBind = acc,
})

--==============================
-- SECOND AURA (7s)
--==============================
task.delay(7, function()
    if not acc or not acc.Parent then return end
    if not workspace:FindFirstChild("Live") then return end
    if not workspace.Live:FindFirstChild(character.Name) then return end

    local auraFolder = Instance.new("Folder")
    auraFolder.Name = "AuraHolder"
    auraFolder:SetAttribute("DivineForm", true)
    auraFolder:SetAttribute("LimAura", true)
    auraFolder:SetAttribute("EmoteEffect", true)
    auraFolder.Parent = character

    local auraSource =
        ReplicatedStorage.Emotes.VFX.VfxMods.Evolved.vfx.Folder

    for _,obj in pairs(auraSource:GetChildren()) do
        if obj:IsA("BasePart") then
            local bodyPart = character:FindFirstChild(obj.Name)
            if bodyPart then
                local clone = obj:Clone()
                clone.Transparency = 1
                clone.Massless = true
                clone.Name = tostring(math.random(1, 1000))
                clone:SetAttribute("LimAura", true)
                clone.Parent = auraFolder

                local weld = Instance.new("Weld")
                weld.Part0 = bodyPart
                weld.Part1 = clone
                weld.Parent = clone

                for _,fx in pairs(clone:GetDescendants()) do
                    if fx:IsA("ParticleEmitter") or fx:IsA("Beam") then
                        fx:SetAttribute("LimitedAura", true)
                        task.delay(2, function()
                            if fx then fx.Enabled = false end
                        end)
                    end
                end

                task.delay(4, function()
                    if clone and clone.Parent then
                        clone:Destroy()
                    end
                end)
            end
        end
    end
end)

    end
})

EmoteTab:Button({
    Title = "The Strongest",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = false, -- disable button. optional
    LockedTitle = "Locked", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--==============================
-- SOUND SEQUENCE (GIỮ TIMING GỐC)
--==============================
local soundTable = {
    [0] = {
        SoundId = "rbxassetid://117787451950766",
        Volume = 2,
    },
    [0.01] = {
        SoundId = "rbxassetid://97998065677521",
        Volume = 1.85,
    },
    [2.29] = {
        SoundId = "rbxassetid://99535007576182",
        Volume = 2,
        Looped = true,
    },
}

for delayTime, data in pairs(soundTable) do
    task.delay(delayTime, function()
        local sound = Instance.new("Sound")
        sound.SoundId = data.SoundId
        sound.Volume = data.Volume or 1
        sound.Looped = data.Looped or false
        sound.Parent = workspace
        sound:Play()
    end)
end

--==============================
-- ANIMATION
--==============================
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://86505219150915"
humanoid:LoadAnimation(anim):Play()

--==============================
-- VFX BIND (0.1s)
--==============================
task.delay(0.1, function()
    local bind = Instance.new("Folder")
    bind.Name = "PrideBind"
    bind.Parent = character
    bind:SetAttribute("EmoteProperty", true)

    require(ReplicatedStorage.Emotes.VFX):MainFunction({
        Character = character,
        vfxName = "Boss Raid",
        SpecificModule = ReplicatedStorage.Emotes.VFX,
        AnimSent = 86505219150915,
        RealBind = bind,
    })
end)

    end
})

EmoteTab:Button({
    Title = "Boundless Rage",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = false, -- disable button. optional
    LockedTitle = "Locked", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()
-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- SAFE CHARACTER
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--==============================
-- ANIMATION
--==============================
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://107649573628906"
humanoid:LoadAnimation(anim):Play()

local emoteAcc = nil
local noRotateFolder = nil

--==============================
-- MAIN VFX + NO ROTATE (0.1s)
--==============================
task.delay(0.1, function()
    emoteAcc = Instance.new("Accessory")
    emoteAcc.Name = "#EmoteHolder_" .. math.random(1, 100000)
    emoteAcc.Parent = character
    emoteAcc:SetAttribute("EmoteProperty", true)

    require(ReplicatedStorage.Emotes.VFX):MainFunction({
        Character = character,
        vfxName = "Boundless Rage",
        SpecificModule = ReplicatedStorage.Emotes.VFX,
        AnimSent = 107649573628906,
        RealBind = emoteAcc,
    })

    noRotateFolder = Instance.new("Folder")
    noRotateFolder.Name = "NoRotate"
    noRotateFolder.Parent = character
    noRotateFolder:SetAttribute("EmoteProperty", true)
end)

--==============================
-- AURA + LOOP SOUND (4s)
--==============================
task.delay(4, function()
    if not character or not character.Parent then return end

    -- ❌ bỏ workspace.Live cứng → tránh crash
    local auraTemplate =
        ReplicatedStorage.Emotes.VFX.VfxMods.Boundless.vfx.AuraChar:Clone()

    Debris:AddItem(auraTemplate, 5)

    if noRotateFolder and noRotateFolder.Parent then
        noRotateFolder:Destroy()
    end

    -- LOOP SOUND
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://81055990581650"
    sound.Looped = true
    sound.Volume = 1
    sound.Name = "CrushEmoteAmbience"
    sound.Parent =
        character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character

    sound:Play()

    -- APPLY AURA
    for _,part in pairs(auraTemplate:GetChildren()) do
        if part:IsA("BasePart") then
            local charPart = character:FindFirstChild(part.Name)
            if charPart then
                for _,obj in pairs(part:GetChildren()) do
                    if obj:IsA("Attachment") or obj:IsA("ParticleEmitter") then
                        local clone = obj:Clone()
                        clone.Parent = charPart
                        clone:SetAttribute("LimitedAura", true)

                        -- FADE OUT + SOUND STOP
                        task.delay(60, function()
                            TweenService:Create(
                                sound,
                                TweenInfo.new(0.5),
                                { Volume = 0 }
                            ):Play()

                            task.delay(0.75, function()
                                if sound and sound.Parent then
                                    sound:Destroy()
                                end
                            end)

                            if clone:IsA("ParticleEmitter") then
                                clone.Enabled = false
                            else
                                for _,fx in pairs(clone:GetChildren()) do
                                    if fx:IsA("ParticleEmitter") or fx:IsA("Beam") then
                                        fx.Enabled = false
                                    end
                                end
                            end
                        end)

                        task.delay(65, function()
                            if clone and clone.Parent then
                                clone:Destroy()
                            end
                        end)
                    end
                end
            end
        end
    end

    auraTemplate:Destroy()
end)

    end
})

EmoteTab:Button({
    Title = "The Fallen",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = false, -- disable button. optional
    LockedTitle = "Locked", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()
-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SAFE CHARACTER
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--==============================
-- ANIMATION
--==============================
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://133818134745501"
humanoid:LoadAnimation(anim):Play()

--==============================
-- VFX + SOUND (0.1s)
--==============================
task.delay(0.1, function()
    if not character or not character.Parent then return end

    -- REMOVE OLD EFFECT
    local old = character:FindFirstChild("DismantleEffect")
    if old then
        old:Destroy()
    end

    -- ACCESSORY BIND
    local acc = Instance.new("Accessory")
    acc.Name = "DismantleEffect"
    acc.Parent = character
    acc:SetAttribute("EmoteEffect", true)

    require(ReplicatedStorage.Emotes.VFX):MainFunction({
        Character = character,
        vfxName = "Pride",
        SpecificModule = ReplicatedStorage.Emotes.VFX,
        AnimSent = 133818134745501,
        RealBind = acc,
        CanRotate = true,
    })

    -- SOUND (FIX PARENT)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://93369149563360"
    sound.Volume = 2
    sound.Looped = false
    sound.Parent =
        character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
        or character

    sound:Play()
end)

    end
})

EmoteTab:Button({
    Title = "True Aura",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = false, -- disable button. optional
    LockedTitle = "Locked", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()

        --==============================
        -- SERVICES (GIỮ NGUYÊN)
        --==============================
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CollectionService = game:GetService("CollectionService")

        local character = Players.LocalPlayer.Character
        if not character then return end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        --==============================
        -- ANIMATION
        --==============================
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://103668868712897"
        humanoid:LoadAnimation(anim):Play()

        task.delay(0.1, function()
            if not character or not character.Parent then return end

            --==============================
            -- ACCESSORY BIND
            --==============================
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 100000)
            acc.Parent = character

            CollectionService:AddTag(acc, "emoteendstuff" .. character.Name)

            require(ReplicatedStorage.Emotes.VFX):MainFunction({
                Character = character,
                vfxName = "True Aura",
                SpecificModule = ReplicatedStorage.Emotes.VFX,
                AnimSent = 103668868712897,
                RealBind = acc,
            })

            --==============================
            -- SPECIAL USER CHECK (GIỮ NGUYÊN, KHÔNG SỬA LOGIC)
            --==============================
            local root = character.PrimaryPart

            if tostring(character) == "YungCrepetics" and root then
                task.delay(6.3, function()
                    if acc and acc.Parent then
                        for _, part in pairs(
                            workspace:GetPartBoundsInRadius(root.Position, 40)
                        ) do
                            local _ = part:GetAttribute("IsTree") or part.Name == "TreeRoot"
                            local hum = part.Parent:FindFirstChildOfClass("Humanoid")

                            if hum and hum.Name ~= "FakeHumanoid" then
                                local _ = hum == humanoid
                            end
                        end
                    end
                end)
            end

            --==============================
            -- SOUND (R6 ONLY → TORSO)
            --==============================
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://83049960731792"
            sound.Volume = 3
            sound.Looped = false
            sound.Parent = character:FindFirstChild("Torso")

            if sound.Parent then
                sound:Play()
            end
        end)
    end
})

EmoteTab:Button({ --//BUG
    Title = "Eternal Seal",
    Desc = "Limited Emote",
    Icon = "mouse-pointer-click", -- lucide icon or "rbxassetid://". optional
    IconAlign = "Right", -- "Left" or "Right". optional
    Locked = true, -- disable button. optional
    LockedTitle = "Bug", -- text shown when locked. optional
    Justify = "Between", -- "Between" or "Center". optional
    Flag = "my_button", -- for config saving. optional
    Callback = function()
-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("Torso") -- R6

--==============================
-- ANIMATION + MAIN VFX
--==============================
task.spawn(function()
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://100255267749203"
    humanoid:LoadAnimation(anim):Play()

    local silent = Instance.new("Sound")
    silent.SoundId = "rbxassetid://79605009444651"
    silent.Volume = 0
    silent.Parent = torso
    silent:Play()

    local bind = Instance.new("Folder")
    bind.Name = "RuthlessBind"
    bind.Parent = character
    bind:SetAttribute("EmoteProperty", true)

    require(ReplicatedStorage.Emotes.VFX):MainFunction({
        Character = character,
        vfxName = "Eternal Seal",
        SpecificModule = ReplicatedStorage.Emotes.VFX,
        AnimSent = 100255267749203,
        RealBind = bind,
    })
end)

--==============================
-- SOUND
--==============================
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://79605009444651"
sound.Volume = 2
sound.Parent = torso
sound:Play()

--==============================
-- THROWN FOLDER
--==============================
local thrown = Workspace:FindFirstChild("Thrown")
if not thrown then
    thrown = Instance.new("Folder")
    thrown.Name = "Thrown"
    thrown.Parent = Workspace
end

local tracked = {}

local function register(obj)
    obj:SetAttribute("EmoteProperty", true)
    CollectionService:AddTag(obj, "emoteendstuff" .. character.Name)
    table.insert(tracked, obj)
    obj.Parent = thrown
end

--==============================
-- CLONE MODELS
--==============================
local Prison = ReplicatedStorage.Emotes.PrisonRealmRig:Clone()
local Prism = ReplicatedStorage.Emotes.RealmPrism:Clone()
local Strings = ReplicatedStorage.Emotes.Strings:Clone()

register(Prison)
register(Prism)
register(Strings)

--==============================
-- WELD (GIỮ NGUYÊN LOGIC GỐC)
--==============================
for _,model in pairs({
    Prison,
    Prism,
    unpack(Strings:GetChildren())
}) do
    model.PrimaryPart.Anchored = false

    local weld = Instance.new("Weld")
    weld.Part0 = character.PrimaryPart or torso
    weld.Part1 = model.PrimaryPart
    weld.C0 = model:GetAttribute("Offset") -- ⚠️ QUAN TRỌNG
    weld.Parent = model.PrimaryPart
end

--==============================
-- BONE SOUND
--==============================
local boneSound = Instance.new("Sound")
boneSound.SoundId = "rbxassetid://116434570262349"
boneSound.Volume = 2
boneSound.Parent = Prison:FindFirstChild("Bone_L", true)
boneSound:Play()

--==============================
-- MODEL ANIMATIONS
--==============================
local function playAnim(model, id)
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id

    local controller =
        model:FindFirstChild("AnimationController")
        or model:FindFirstChildOfClass("Humanoid")

    if controller then
        controller:LoadAnimation(anim):Play()
    end
end

playAnim(Prison, 132931842051377)
playAnim(Prism, 73313263538976)

local ids = {
    115400109213203,
    129152881643120,
    116148929833466,
    106613129685108,
    85535076926939,
    136688312702757,
}

for i, id in ipairs(ids) do
    local stringModel = Strings:FindFirstChild("String" .. i)
    if stringModel then
        playAnim(stringModel, id)
    end
end

--==============================
-- ANTI FREEZE (GIỮ PLAYER DI CHUYỂN)
--==============================
RunService.RenderStepped:Connect(function()
    if character and character.Parent then
        for _,p in pairs(character:GetDescendants()) do
            if p:IsA("BasePart") and p.Anchored then
                p.Anchored = false
            end
        end
    end
end)

    end
})

EmoteTab:Button({
    Title = "World Cutting Slash",
    Desc = "",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "world_cutting_slash",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://120001337057214"
        local track = humanoid:LoadAnimation(anim)
        track:Play()

        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "HugeSlash",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 120001337057214,
                    RealBind = acc,
                    CanRotate = true,
                })
            end)

            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://103835306879590"
            sound.Volume = 3
            sound.Parent = character:FindFirstChild("Torso") or character.PrimaryPart
            if sound.Parent then
                sound:Play()
                Debris:AddItem(sound, 10)
            end
        end)
    end
})

EmoteTab:Button({
    Title = "My Brother",
    Desc = "",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "my_brother",

    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

        local Replication = ReplicatedStorage:FindFirstChild("Replication")
        if not Replication then
            warn("Replication not found")
            return
        end

        local function GetRandomFriend()
            local success, pages = pcall(function()
                return Players:GetFriendsAsync(LocalPlayer.UserId)
            end)

            if not success or not pages then
                warn("Failed to fetch friends list")
                return nil
            end

            local allFriends = {}

            repeat
                for _, friend in ipairs(pages:GetCurrentPage()) do
                    table.insert(allFriends, friend)
                end

                if pages.IsFinished then
                    break
                end

                pages:AdvanceToNextPageAsync()
            until false

            if #allFriends == 0 then
                warn("No friends found!")
                return nil
            end

            local randomFriend = allFriends[math.random(1, #allFriends)]
            return randomFriend.Id
        end

        local targetId = GetRandomFriend()
        if not targetId then
            return
        end

        local RockTemplate = ReplicatedStorage:FindFirstChild("Emotes") and
                             ReplicatedStorage.Emotes:FindFirstChild("RockThrow")

        if not RockTemplate then
            warn("RockThrow not found")
            return
        end

        local Rock = RockTemplate:Clone()
        Rock:SetAttribute("EmoteProperty", true)
        Rock.Name = "Rock"
        Rock.Parent = character

        local weld = Rock:WaitForChild("Rock", 2)
        if weld and character.PrimaryPart then
            weld:SetAttribute("EmoteProperty", true)
            weld.Part0 = character.PrimaryPart
            weld.Part1 = Rock
            weld.Parent = character.PrimaryPart
        end

        task.delay(0.573,function()
            if Rock and Rock.Parent then
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://91571189388577"
                sound.Volume = 1
                sound.RollOffMaxDistance = 100
                sound.Parent = Rock
                sound:Play()
            end
        end)

        local Humanoid = character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://123464270068243"
            Humanoid:LoadAnimation(anim):Play()
        end

        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if torso then
            local s1 = Instance.new("Sound")
            s1.SoundId = "rbxassetid://104813362309681"
            s1.Volume = 1
            s1.Parent = torso
            s1:Play()

            task.delay(0.01,function()
                local s2 = Instance.new("Sound")
                s2.SoundId = "rbxassetid://103206475338370"
                s2.Volume = 0.8
                s2.Parent = torso
                s2:Play()
            end)
        end

task.wait(2.4)

pcall(function()
    for _,conn in pairs(getconnections(Replication.OnClientEvent)) do
        if conn.Function then
            pcall(function()
                conn.Function({
                    Effect = "Best Brother",
                    char = character,
                    Id = targetId,
                })
            end)
        end
    end
end)

if Rock then
    Rock.Transparency = 1
end

    end
})

EmoteTab:Button({
    Title = "Final Spark",
    Desc = "",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "final_spark",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://129361308786827"
        humanoid:LoadAnimation(anim):Play()

        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Final Spark",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 129361308786827,
                    RealBind = acc,
                })
            end)
        end)
    end
})

EmoteTab:Button({
    Title = "Last Will",
    Desc = "",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "last_will",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://113450724032380"
        humanoid:LoadAnimation(anim):Play()

        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "Last Will",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 113450724032380,
                    RealBind = acc,
                })
            end)
        end)
    end
})

EmoteTab:Button({
    Title = "The Fallen Finisher",
    Desc = "",
    Icon = "mouse-pointer-click",
    IconAlign = "Right",
    Locked = false,
    Justify = "Between",
    Flag = "fallen_finisher",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")

        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if torso then
            local sound1 = Instance.new("Sound")
            sound1.SoundId = "rbxassetid://113267998039039"
            sound1.Volume = 1.65
            sound1.Parent = torso
            sound1:Play()
            Debris:AddItem(sound1, 10)
        end

        local sound2 = Instance.new("Sound")
        sound2.SoundId = "rbxassetid://87401852788032"
        sound2.Volume = 1
        sound2.Parent = workspace
        sound2:Play()
        Debris:AddItem(sound2, 10)

        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://95171537920426"
        humanoid:LoadAnimation(anim):Play()

        task.delay(0.1, function()
            local acc = Instance.new("Accessory")
            acc.Name = "#EmoteHolder_" .. math.random(1, 99999)
            acc:SetAttribute("EmoteProperty", true)
            acc.Parent = character

            pcall(function()
                require(ReplicatedStorage.Emotes.VFX):MainFunction({
                    Character = character,
                    vfxName = "slice combo",
                    SpecificModule = ReplicatedStorage.Emotes.VFX,
                    AnimSent = 95171537920426,
                    RealBind = acc,
                })
            end)
        end)
    end
})

InfoTab:Button({
    Title = "Copy Discord Link",
    Desc = "",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/tgK6PfbsN")
            WindUI:Notify({
                Title = "Copied!",
                Content = "Discord link copied to clipboard",
                Duration = 3,
            })
        end
    end
})

InfoTab:Paragraph({
    Title = "UPDATE SCRIPT:",
    Content = "Update weekly ",
})

local MusicList = {
    ["Ai la nguoi thuong em"] = "138017380471511",
}

local musicNames = {}
for name, _ in pairs(MusicList) do
    table.insert(musicNames, name)
end

local SelectedMusic = "Ai la nguoi thuong em"
local CurrentVolume = 0.5
local IsLooped = false
local Sound = nil

local function CreateSound()
    if Sound then
        pcall(function()
            Sound:Stop()
            Sound:Destroy()
        end)
    end

    Sound = Instance.new("Sound")
    Sound.Name = "BoomboxSound"
    Sound.Parent = workspace.CurrentCamera
    Sound.Volume = CurrentVolume
    Sound.Looped = IsLooped
    Sound.SoundId = "rbxassetid://" .. MusicList[SelectedMusic]
    Sound:Stop()
end

CreateSound()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Sound then
        Sound.Parent = workspace.CurrentCamera
    end
end)

PlayerTab:Dropdown({
    Title = "Select Music",
    Desc = "",
    Values = musicNames,
    Default = "Ai la nguoi thuong em",
    Callback = function(selected)
        SelectedMusic = selected
        if Sound then
            Sound.SoundId = "rbxassetid://" .. MusicList[selected]
            Sound:Stop()
            Sound.TimePosition = 0
        end
    end
})

PlayerTab:Button({
    Title = "Play",
    Desc = "",
    Callback = function()
        if not Sound then return end
        Sound:Stop()
        Sound.TimePosition = 0
        Sound:Play()
    end
})

PlayerTab:Button({
    Title = "Stop",
    Desc = "",
    Callback = function()
        if Sound then
            Sound:Stop()
        end
    end
})

PlayerTab:Toggle({
    Title = "Loop",
    Desc = "",
    Callback = function(Value)
        IsLooped = Value
        if Sound then
            Sound.Looped = Value
        end
    end
})

PlayerTab:Slider({
    Title = "Volume",
    Desc = "",
    Min = 0,
    Max = 150,
    Default = 50,
    Callback = function(Value)
        CurrentVolume = Value / 100
        if Sound then
            Sound.Volume = CurrentVolume
        end
    end
})

PlayerTab:Button({
    Title = "Golden Shoulder",
    Desc = "",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end

        local old = char:FindFirstChild("GoldenShoulder")
        if old then old:Destroy() end

        local acc = Instance.new("Accessory")
        acc.Name = "GoldenShoulder"
        acc.Parent = char

        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(1, 1, 1)
        handle.Anchored = false
        handle.Massless = true
        handle.CanCollide = false
        handle.Parent = acc

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshId = "rbxassetid://4307568890"
        mesh.TextureId = "rbxassetid://4307568951"
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = handle

        local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
        if rightArm then
            local weld = Instance.new("Weld")
            weld.Part0 = handle
            weld.Part1 = rightArm
            weld.C0 = CFrame.new(-0.6, -1.3, 0)
            weld.Parent = handle
        end
    end
})

PlayerTab:Input({
    Title = "Kill Sound ID",
    Desc = "",
    Placeholder = "Enter Sound ID",
    Callback = function(text)
        text = tostring(text):gsub("%s+", "")
        if text == "" then return end
        
        local soundId = "rbxassetid://" .. text
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 1
        sound.Parent = SoundService
        
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        if leaderstats then
            local kills = leaderstats:FindFirstChild("Kills")
            if kills then
                kills:GetPropertyChangedSignal("Value"):Connect(function()
                    local soundClone = sound:Clone()
                    soundClone.Parent = workspace.CurrentCamera
                    soundClone:Play()
                    Debris:AddItem(soundClone, 5)
                end)
            end
        end
    end
})

PlayerTab:Button({
    Title = "Fix Lag MAX (Boost)",
    Desc = "",
    Callback = function()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e9
        Lighting.Brightness = 1

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Explosion") or obj:IsA("Highlight") then
                pcall(function()
                    obj.Enabled = false
                    obj:Destroy()
                end)
            end
            if obj:IsA("BasePart") then
                obj.CastShadow = false
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end

        local map = workspace:FindFirstChild("Map")
        if map then
            local treesFolder = map:FindFirstChild("Trees")
            if treesFolder then
                for _, tree in ipairs(treesFolder:GetChildren()) do
                    if tree:IsA("Model") and tree.Name == "Tree" then
                        tree:Destroy()
                    end
                end
            end
        end

        WindUI:Notify({
            Title = "Fix Lag",
            Content = "MAX Boost Enabled",
            Duration = 3,
        })
    end
})

local function formatTime(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    return string.format("%02dh %02dm %02ds", h, m, s)
end

HopTab:Paragraph({
    Title = "Server Info",
    Content = "Loading...",
})

task.spawn(function()
    while true do
        local currentPlayers = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local placeId = game.PlaceId
        local jobId = game.JobId
        local uptime = workspace.DistributedGameTime
        
        for _, element in ipairs(HopTab:GetChildren()) do
            if element:IsA("Paragraph") and element.Title == "Server Info" then
                element.Content = "Players: " .. currentPlayers .. "/" .. maxPlayers ..
                    "\nPlaceId: " .. placeId ..
                    "\nSession Time: " .. formatTime(uptime) ..
                    "\nJobId: " .. jobId
                break
            end
        end
        task.wait(1)
    end
end)

HopTab:Button({
    Title = "Copy JobId",
    Desc = "",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            WindUI:Notify({
                Title = "Copied!",
                Content = "JobId copied to clipboard",
                Duration = 2,
            })
        end
    end
})

HopTab:Button({
    Title = "Rejoin Server",
    Desc = "",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end)
    end
})

HopTab:Button({
    Title = "Hop Server (Random)",
    Desc = "",
    Callback = function()
        local function getServers(maxPages)
            local servers = {}
            local cursor = ""
            local pages = 0

            repeat
                pages = pages + 1
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local success, res = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet(url))
                end)

                if not success or not res or not res.data then break end

                for _, srv in ipairs(res.data) do
                    if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                        table.insert(servers, srv)
                    end
                end

                cursor = res.nextPageCursor
            until not cursor or pages >= (maxPages or 5)

            return servers
        end

        local servers = getServers(6)
        if #servers > 0 then
            local pick = servers[math.random(1, #servers)]
            task.wait(0.2)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
        end
    end
})

HopTab:Button({
    Title = "Anti AFK",
    Desc = "",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/23rycg2Q/raw"))()
    end
})

HopTab:Input({
    Title = "Join by JobID",
    Desc = "",
    Placeholder = "Paste JobId...",
    Callback = function(text)
        if text and text ~= "" then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, text, LocalPlayer)
        end
    end
})


WindUI:Notify("ThanhDuy Hub", "Loaded successfully!", 3)