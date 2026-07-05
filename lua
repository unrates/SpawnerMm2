local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local LP               = Players.LocalPlayer

-- ============================================================
-- ALLOWED WEAPONS LIST (WHITELIST)
-- ============================================================
local WeaponsToSpawn = {
    "TravelerGunChroma", "TreeGun2023Chroma", "TreeKnife2023Chroma", "BaubleChroma", 
    "ConstellationChroma", "VampireGunChroma", "Gingerscope", "UFOKnifeChroma", 
    "RaygunChroma", "TravelerAxe", "BlizzardChroma", "SunsetGunChroma", 
    "SnowcannonChroma", "SnowstormChroma", "SnowDaggerChroma", "TravelerGun", 
    "SunsetKnifeChroma", "TreeGun2023", "Constellation", "BaubleKnifeChroma", 
    "TreeKnife2023", "WatergunChroma", "Turkey2023", "Celestial", 
    "VampireGun", "Bauble", "Darkshot", "Darksword", "Blossom_G", 
    "Sakura_K", "Sorry", "VampireAxe", "UFOKnife", "Harvester", 
    "Raygun", "Icepiercer"
}

-- Quick helper to verify if a database item is allowed to spawn
local function isWeaponAllowed(weaponName)
    for _, allowedName in ipairs(WeaponsToSpawn) do
        if allowedName == weaponName then
            return true
        end
    end
    return false
end

-- ============================================================
-- HELPERS
-- ============================================================

local function H(s) return Color3.fromHex(s) end

local function new(class, props)
    local o = Instance.new(class)
    if props then
        local parent = props.Parent
        for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end
        if parent then o.Parent = parent end
    end
    return o
end

local function corner(p, r)  return new("UICorner", {CornerRadius=UDim.new(0,r or 8), Parent=p}) end
local function pad(p, all)   return new("UIPadding", {PaddingLeft=UDim.new(0,all), PaddingRight=UDim.new(0,all), PaddingTop=UDim.new(0,all), PaddingBottom=UDim.new(0,all), Parent=p}) end
local function listV(p, gap) return new("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, Padding=UDim.new(0,gap or 6), SortOrder=Enum.SortOrder.LayoutOrder, Parent=p}) end
local function tween(o, t, props, st, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, st or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function gradSeq(colors)
    local kp = {}
    for i, c in ipairs(colors) do
        table.insert(kp, ColorSequenceKeypoint.new((i-1)/math.max(#colors-1,1), c))
    end
    return ColorSequence.new(kp)
end

-- ============================================================
-- PALETTE  (Spring 2026)
-- ============================================================

local C = {
    Bg      = H"#0f0c16",
    Panel   = H"#141228",
    Input   = H"#1c1a2e",
    BtnDark = H"#1e1c35",
    Drop    = H"#181630",

    Pink    = H"#f472b6",
    Mint    = H"#86efac",
    Gold    = H"#fde047",
    Rose    = H"#fb7185",
    Sky     = H"#7dd3fc",
    Cyan    = H"#00d4ff",
    Purple  = H"#b400ff",

    Text    = H"#e2e0ff",
    TextSub = H"#8888a8",
    Good    = H"#86efac",
    Bad     = H"#fb7185",
}

local BORDER_SEQ  = gradSeq({C.Pink, C.Mint, C.Sky, C.Purple, C.Pink})
local SPAWN_SEQ   = gradSeq({C.Pink, C.Cyan})
local DIVIDER_SEQ = gradSeq({Color3.new(1,1,1), C.Pink, C.Mint, Color3.new(1,1,1)})
local DIVIDER_TRANS = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   1),
    NumberSequenceKeypoint.new(0.1, 0),
    NumberSequenceKeypoint.new(0.9, 0),
    NumberSequenceKeypoint.new(1,   1),
})

-- ============================================================
-- SCREEN GUI + ROOT FRAME
-- ============================================================

local sg = new("ScreenGui", {
    Name           = "TestolSpawnerRemastered",
    DisplayOrder   = 9998,
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
})
pcall(function() sg.Parent = CoreGui end)
if not sg.Parent then sg.Parent = LP:WaitForChild("PlayerGui") end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local VP       = workspace.CurrentCamera.ViewportSize
local FW       = isMobile and math.min(math.floor(VP.X - 24), 380) or 320
local FH       = isMobile and math.min(430, math.floor(VP.Y * 0.82)) or 430
local frame = new("Frame", {
    Size             = UDim2.fromOffset(FW, FH),
    Position         = UDim2.new(0.5, -FW/2, 0.5, -FH/2),
    BackgroundColor3 = C.Bg,
    BorderSizePixel  = 0,
    ClipsDescendants = false,
    Parent           = sg,
})
corner(frame, 14)

new("UIGradient", {
    Color    = gradSeq({H"#1a1535", C.Bg, C.Bg}),
    Rotation = 135,
    Parent   = frame,
})

local borderStroke = new("UIStroke", {
    Thickness       = 2,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    LineJoinMode    = Enum.LineJoinMode.Round,
    Parent          = frame,
})
local borderGrad = new("UIGradient", {Color=BORDER_SEQ, Parent=borderStroke})

task.spawn(function()
    while frame and frame.Parent do
        tween(borderGrad, 3, {Rotation=(borderGrad.Rotation or 0)+360}, Enum.EasingStyle.Linear)
        task.wait(3)
    end
end)

-- ============================================================
-- HEADER
-- ============================================================

local header = new("Frame", {
    Size             = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = C.Panel,
    BorderSizePixel  = 0,
    Parent           = frame,
})
new("UIGradient", {Color=gradSeq({H"#1e1a38", C.Panel}), Rotation=90, Parent=header})

local titleLbl = new("TextLabel", {
    Size                   = UDim2.new(1, -60, 0, 26),
    Position               = UDim2.fromOffset(16, 8),
    BackgroundTransparency = 1,
    Text                   = "Rhyzen Spawner",
    Font                   = Enum.Font.GothamBlack,
    TextSize               = 22,
    TextColor3             = Color3.new(1,1,1),
    TextXAlignment         = Enum.TextXAlignment.Left,
    TextStrokeColor3       = Color3.new(0,0,0),
    TextStrokeTransparency = 0.6,
    Parent                 = header,
})
new("UIGradient", {Color=gradSeq({C.Pink, C.Mint}), Parent=titleLbl})

new("TextLabel", {
    Size                   = UDim2.new(1, -60, 0, 16),
    Position               = UDim2.fromOffset(16, 32),
    BackgroundTransparency = 1,
    Text                   = "Remastered",
    Font                   = Enum.Font.GothamMedium,
    TextSize               = 12,
    TextColor3             = C.TextSub,
    TextXAlignment         = Enum.TextXAlignment.Left,
    Parent                 = header,
})

local closeBtn = new("TextButton", {
    Size             = UDim2.fromOffset(28, 28),
    Position         = UDim2.new(1, -38, 0.5, -14),
    BackgroundColor3 = H"#2a1830",
    BorderSizePixel  = 0,
    Text             = "x",
    TextColor3       = C.Rose,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    AutoButtonColor  = false,
    Parent           = header,
})
corner(closeBtn, 8)
new("UIStroke", {Thickness=1, Color=C.Rose, Transparency=0.6, Parent=closeBtn})
closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.12, {BackgroundColor3=H"#4a1030", TextColor3=Color3.new(1,1,1)}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.12, {BackgroundColor3=H"#2a1830", TextColor3=C.Rose}) end)

closeBtn.MouseButton1Click:Connect(function()
    tween(frame, 0.2, {BackgroundTransparency=1, Size=UDim2.fromOffset(FW, 0)})
    task.wait(0.22)
    frame.Visible = false
    
    -- If on mobile, reset the floating pill text back to "Spawner"
    local tSG = CoreGui:FindFirstChild("TestolToggle") or LP:WaitForChild("PlayerGui"):FindFirstChild("TestolToggle")
    if tSG and tSG:FindFirstChild("TextButton") then
        tSG.TextButton.Text = "Spawner"
    end
end)
local divider = new("Frame", {
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.fromOffset(0, 54),
    BackgroundColor3 = Color3.new(1,1,1),
    BorderSizePixel  = 0,
    Parent           = frame,
})
new("UIGradient", {Color=DIVIDER_SEQ, Transparency=DIVIDER_TRANS, Parent=divider})

-- ============================================================
-- BODY
-- ============================================================

local body = new("ScrollingFrame", {
    Size                   = UDim2.new(1, 0, 1, -55),
    Position               = UDim2.fromOffset(0, 55),
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    ScrollBarThickness     = isMobile and 3 or 0,
    ScrollBarImageColor3   = C.Pink,
    CanvasSize             = UDim2.fromScale(1, 0),
    AutomaticCanvasSize    = Enum.AutomaticSize.Y,
    ScrollingDirection     = Enum.ScrollingDirection.Y,
    ElasticBehavior        = Enum.ElasticBehavior.Always,
    Parent                 = frame,
})
pad(body, 16)
listV(body, 10)

-- â”€â”€ helper: builds a stepper widget [ - | N | + ] inside a parent frame
local function makeStepperWidget(parent, defaultVal, maxVal)
    local pill = new("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Input,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    corner(pill, 8)
    new("UIStroke", {Thickness=1, Color=C.TextSub, Transparency=0.7, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=pill})

    local minus = new("TextButton", {
        Size             = UDim2.new(0, 30, 1, 0),
        Position         = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Text             = "-",
        TextColor3       = C.Text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        AutoButtonColor  = false,
        Parent           = pill,
    })
    local countLbl = new("TextLabel", {
        Size                   = UDim2.new(0, 44, 1, 0),
        Position               = UDim2.fromOffset(30, 0),
        BackgroundTransparency = 1,
        Text                   = tostring(defaultVal),
        Font                   = Enum.Font.GothamBold,
        TextSize               = 13,
        TextColor3             = C.Text,
        Parent                 = pill,
    })
    local plus = new("TextButton", {
        Size             = UDim2.new(0, 30, 1, 0),
        Position         = UDim2.fromOffset(74, 0),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Text             = "+",
        TextColor3       = C.Text,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        AutoButtonColor  = false,
        Parent           = pill,
    })
    new("Frame", {Size=UDim2.fromOffset(1,20), Position=UDim2.new(0,30,0.5,-10), BackgroundColor3=C.TextSub, BackgroundTransparency=0.5, BorderSizePixel=0, Parent=pill})
    new("Frame", {Size=UDim2.fromOffset(1,20), Position=UDim2.new(0,74,0.5,-10), BackgroundColor3=C.TextSub, BackgroundTransparency=0.5, BorderSizePixel=0, Parent=pill})

    local val = defaultVal
    minus.MouseButton1Click:Connect(function()
        if val > 1 then val = val - 1; countLbl.Text = tostring(val) end
    end)
    plus.MouseButton1Click:Connect(function()
        if val < maxVal then val = val + 1; countLbl.Text = tostring(val) end
    end)
    return pill, function() return val end, countLbl
end

-- â”€â”€ ITEM SELECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
new("TextLabel", {
    Size = UDim2.new(1,0,0,12), BackgroundTransparency=1,
    Text="FILTER", Font=Enum.Font.GothamBold, TextSize=10,
    TextColor3=C.TextSub, TextXAlignment=Enum.TextXAlignment.Left,
    LayoutOrder=1, Parent=body,
})

local filterBox = new("TextBox", {
    Size=UDim2.new(1,0,0,36), BackgroundColor3=C.Input, BorderSizePixel=0,
    PlaceholderText="Search items (knife, chroma, godly...)",
    Text="", PlaceholderColor3=C.TextSub, TextColor3=C.Text,
    Font=Enum.Font.Gotham, TextSize=13, ClearTextOnFocus=false,
    LayoutOrder=2, Parent=body,
})
corner(filterBox, 8); pad(filterBox, 10)
local filterStroke = new("UIStroke", {Thickness=1.5, Color=C.TextSub, Transparency=0.6, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=filterBox})
filterBox.Focused:Connect(function()  tween(filterStroke, 0.15, {Transparency=0,   Color=C.Pink}) end)
filterBox.FocusLost:Connect(function() tween(filterStroke, 0.15, {Transparency=0.6, Color=C.TextSub}) end)

local selectedDisplay = new("TextButton", {
    Size=UDim2.new(1,0,0,36), BackgroundColor3=C.Input, BorderSizePixel=0,
    Text="None selected", TextColor3=C.TextSub,
    Font=Enum.Font.GothamMedium, TextSize=13,
    AutoButtonColor=false, TextXAlignment=Enum.TextXAlignment.Left,
    LayoutOrder=3, Parent=body,
})
corner(selectedDisplay, 8); pad(selectedDisplay, 10)
local selectedStroke = new("UIStroke", {Thickness=1.5, Color=C.Mint, Transparency=0.7, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=selectedDisplay})
new("TextLabel", {
    Size=UDim2.fromOffset(20,36), Position=UDim2.new(1,-26,0,0),
    BackgroundTransparency=1, Text="â€º", Font=Enum.Font.GothamBold,
    TextSize=18, TextColor3=C.TextSub, Parent=selectedDisplay,
})

-- â”€â”€ SPAWN SECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local spawnRow = new("Frame", {
    Size=UDim2.new(1,0,0,44), BackgroundTransparency=1,
    LayoutOrder=4, Parent=body,
})

local spawnBtn = new("TextButton", {
    Size=UDim2.new(1,-112,0,44), BackgroundColor3=C.BtnDark, BorderSizePixel=0,
    Text="Spawn Item", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=14,
    AutoButtonColor=false, Parent=spawnRow,
})
corner(spawnBtn, 10)
new("UIGradient", {Color=SPAWN_SEQ, Rotation=135, Parent=spawnBtn})
local spawnStroke = new("UIStroke", {Thickness=1.5, Transparency=0.6, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=spawnBtn})
new("UIGradient", {Color=SPAWN_SEQ, Parent=spawnStroke})
spawnBtn.MouseEnter:Connect(function() tween(spawnStroke, 0.12, {Transparency=0}) end)
spawnBtn.MouseLeave:Connect(function() tween(spawnStroke, 0.12, {Transparency=0.6}) end)

local spawnStepper = new("Frame", {
    Size=UDim2.fromOffset(104,44), Position=UDim2.new(1,-104,0,0),
    BackgroundTransparency=1, Parent=spawnRow,
})
local _, getSpawnAmt = makeStepperWidget(spawnStepper, 1, 100)

local progContainer = new("Frame", {
    Size=UDim2.new(1,0,0,5), BackgroundColor3=C.Input,
    BorderSizePixel=0, LayoutOrder=5, Parent=body,
})
corner(progContainer, 3)
local progFill = new("Frame", {
    Size=UDim2.new(0,0,1,0), BackgroundColor3=C.Pink, BorderSizePixel=0, Parent=progContainer,
})
corner(progFill, 3)
new("UIGradient", {Color=SPAWN_SEQ, Parent=progFill})

local statusLbl = new("TextLabel", {
    Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
    Text="Ready", TextColor3=C.TextSub,
    Font=Enum.Font.GothamMedium, TextSize=11,
    LayoutOrder=6, Parent=body,
})
local function setStatus(txt, col) statusLbl.Text=txt; statusLbl.TextColor3=col or C.TextSub end

-- â”€â”€ DUPE SECTION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local divFrame = new("Frame", {
    Size=UDim2.new(1,0,0,1), BackgroundColor3=Color3.new(1,1,1),
    BorderSizePixel=0, LayoutOrder=7, Parent=body,
})
new("UIGradient", {
    Color=gradSeq({Color3.new(1,1,1), C.Gold, C.Cyan, Color3.new(1,1,1)}),
    Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.1,0),
        NumberSequenceKeypoint.new(0.9,0),
        NumberSequenceKeypoint.new(1,1),
    }),
    Parent=divFrame,
})

new("TextLabel", {
    Size=UDim2.new(1,0,0,12), BackgroundTransparency=1,
    Text="DUPE IN INVENTORY", Font=Enum.Font.GothamBold, TextSize=10,
    TextColor3=C.Gold, TextXAlignment=Enum.TextXAlignment.Left,
    LayoutOrder=8, Parent=body,
})

local dupeRow = new("Frame", {
    Size=UDim2.new(1,0,0,44), BackgroundTransparency=1,
    LayoutOrder=9, Parent=body,
})

local DUPE_SEQ = gradSeq({C.Gold, C.Cyan})
local dupeBtn = new("TextButton", {
    Size=UDim2.new(1,-112,0,44), BackgroundColor3=C.BtnDark, BorderSizePixel=0,
    Text="Dupe in Inventory", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=14,
    AutoButtonColor=false, Parent=dupeRow,
})
corner(dupeBtn, 10)
new("UIGradient", {Color=DUPE_SEQ, Rotation=135, Parent=dupeBtn})
local dupeStroke = new("UIStroke", {Thickness=1.5, Transparency=0.6, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=dupeBtn})
new("UIGradient", {Color=DUPE_SEQ, Parent=dupeStroke})
dupeBtn.MouseEnter:Connect(function() tween(dupeStroke, 0.12, {Transparency=0}) end)
dupeBtn.MouseLeave:Connect(function() tween(dupeStroke, 0.12, {Transparency=0.6}) end)

local dupeStepper = new("Frame", {
    Size=UDim2.fromOffset(104,44), Position=UDim2.new(1,-104,0,0),
    BackgroundTransparency=1, Parent=dupeRow,
})
local _, getDupeAmt = makeStepperWidget(dupeStepper, 1, 1000)

local dupeStatusLbl = new("TextLabel", {
    Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
    Text="", TextColor3=C.TextSub,
    Font=Enum.Font.GothamMedium, TextSize=11,
    LayoutOrder=10, Parent=body,
})
local function setDupeStatus(txt, col) dupeStatusLbl.Text=txt; dupeStatusLbl.TextColor3=col or C.TextSub end

local function getItemAmount() return getSpawnAmt() end
local function getDupeAmount() return getDupeAmt() end

-- ============================================================
-- DROPDOWN  (floats above layout, ZIndex 20)
-- ============================================================

local DROP_Y   = 135
local DROP_MAX = 160
local dropOpen = false

local dropdown = new("Frame", {
    Size             = UDim2.new(1, -32, 0, 0),
    Position         = UDim2.fromOffset(16, DROP_Y),
    BackgroundColor3 = C.Drop,
    BorderSizePixel  = 0,
    ZIndex           = 20,
    ClipsDescendants = true,
    Visible          = false,
    Parent           = frame,
})
corner(dropdown, 8)
new("UIStroke", {Thickness=1.5, Color=C.Pink, Transparency=0.3, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=dropdown})

local dropScroll = new("ScrollingFrame", {
    Size                 = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel      = 0,
    ScrollBarThickness   = 3,
    ScrollBarImageColor3 = C.Pink,
    CanvasSize           = UDim2.fromScale(1, 0),
    AutomaticCanvasSize  = Enum.AutomaticSize.Y,
    ScrollingDirection   = Enum.ScrollingDirection.Y,
    ZIndex               = 20,
    Parent               = dropdown,
})
listV(dropScroll, 0)
pad(dropScroll, 4)

local function hideDropdown()
    dropOpen = false
    tween(dropdown, 0.12, {Size=UDim2.new(1,-32,0,0)})
    task.delay(0.13, function() if not dropOpen then dropdown.Visible = false end end)
end

local function showDropdown(h)
    dropOpen = true
    dropdown.Visible = true
    tween(dropdown, 0.12, {Size=UDim2.new(1,-32,0,math.min(h, DROP_MAX))})
end

local itemToSpawn = ""

local function buildDropdown(list)
    for _, c in ipairs(dropScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    if #list == 0 then hideDropdown(); return end
    local relY = filterBox.AbsolutePosition.Y - frame.AbsolutePosition.Y
    dropdown.Position = UDim2.fromOffset(16, relY + filterBox.AbsoluteSize.Y + 4)

    local ROW = 28
    for _, name in ipairs(list) do
        local row = new("TextButton", {
            Size                   = UDim2.new(1, 0, 0, ROW),
            BackgroundTransparency = 1,
            BackgroundColor3       = H"#26224a",
            BorderSizePixel        = 0,
            Text                   = name,
            TextColor3             = C.Text,
            Font                   = Enum.Font.GothamMedium,
            TextSize               = 12,
            TextXAlignment         = Enum.TextXAlignment.Left,
            AutoButtonColor        = false,
            ZIndex                 = 21,
            Parent                 = dropScroll,
        })
        pad(row, 8)
        row.MouseEnter:Connect(function() tween(row, 0.08, {BackgroundTransparency=0, TextColor3=C.Gold}) end)
        row.MouseLeave:Connect(function() tween(row, 0.08, {BackgroundTransparency=1, TextColor3=C.Text}) end)
        row.MouseButton1Click:Connect(function()
            itemToSpawn = name
            selectedDisplay.Text = name
            selectedDisplay.TextColor3 = C.Mint
            tween(selectedStroke, 0.15, {Transparency=0.2, Color=C.Mint})
            hideDropdown()
        end)
    end
    showDropdown(#list * ROW + 8)
end

-- ============================================================
-- SPAWNER LOGIC  (Updated with Whitelist Verification)
-- ============================================================

local CRATE = "KnifeBox4"
local _BC   = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("BoxController")

local itemdatabase = nil
local spawning     = false

-- UPDATED: Filters out database items unless they exist inside WeaponsToSpawn
local function gettable(filter)
    local results = {}
    if not itemdatabase then return results end
    for key in pairs(itemdatabase) do
        if type(key) == "string" and isWeaponAllowed(key) then
            if filter == "" or key:lower():find(filter:lower(), 1, true) then
                table.insert(results, key)
            end
        end
    end
    table.sort(results)
    return results
end

task.spawn(function()
    local ok, err = pcall(function()
        itemdatabase = require(
            ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"):WaitForChild("Item")
        )
    end)
    if ok then
        setStatus("Ready â€” " .. #gettable("") .. " whitelist items loaded", C.Good)
    else
        setStatus("DB error: " .. tostring(err):sub(1, 55), C.Bad)
    end
end)

local ProfileData    = require(ReplicatedStorage.Modules.ProfileData)
local PlayerWeapons  = ProfileData.Weapons
local inventory      = {}

local function addToInventory(itemId, amount)
    inventory[itemId] = (inventory[itemId] or 0) + (amount or 1)
    RunService:BindToRenderStep("InvUpdate_" .. itemId, 0, function()
        PlayerWeapons.Owned[itemId] = inventory[itemId]
    end)
    local pGui = LP:WaitForChild("PlayerGui")
    local invGui = pGui:FindFirstChild("Inventory") or pGui:FindFirstChild("MainGui")
    if invGui then
        local invFrame = invGui:FindFirstChild("InventoryFrame", true)
        if invFrame then invFrame.Visible = false; task.wait(0.1); invFrame.Visible = true end
    end
    LP.Character:BreakJoints()
end

local function playLandEffect(itemName, amount)
    local eSG = new("ScreenGui", {
        Name           = "TestolLandEffect",
        DisplayOrder   = 99999,
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
    })
    pcall(function() eSG.Parent = CoreGui end)
    if not eSG.Parent then eSG.Parent = LP:WaitForChild("PlayerGui") end

    local overlay = new("Frame", {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = eSG,
    })

    local glow = new("ImageLabel", {
        Image                  = "rbxassetid://5028857084",
        Size                   = UDim2.fromScale(0, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3            = C.Gold,
        ImageTransparency      = 0,
        Parent                 = overlay,
    })

    local glow2 = new("ImageLabel", {
        Image                  = "rbxassetid://5028857084",
        Size                   = UDim2.fromScale(0, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3            = C.Pink,
        ImageTransparency      = 0.3,
        Parent                 = overlay,
    })

    local nameTxt = new("TextLabel", {
        Size                   = UDim2.fromScale(1, 0.18),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.42),
        BackgroundTransparency = 1,
        Text                   = itemName,
        Font                   = Enum.Font.GothamBlack,
        TextSize               = 0,
        TextColor3             = Color3.new(1, 1, 1),
        TextTransparency       = 1,
        TextStrokeColor3       = Color3.new(0, 0, 0),
        TextStrokeTransparency = 0.4,
        Parent                 = overlay,
    })
    new("UIGradient", {Color=gradSeq({C.Gold, C.Pink, C.Mint, C.Gold}), Parent=nameTxt})

    local subTxt = new("TextLabel", {
        Size                   = UDim2.fromScale(1, 0.07),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.57),
        BackgroundTransparency = 1,
        Text                   = (amount or 1) .. "x GODLY OBTAINED",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 20,
        TextColor3             = C.Gold,
        TextTransparency       = 1,
        Parent                 = overlay,
    })

    local shine = new("Frame", {
        Size                   = UDim2.new(0, 40, 1, 0),
        Position               = UDim2.fromScale(-0.1, 0),
        BackgroundColor3       = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        BorderSizePixel        = 0,
        Rotation               = 15,
        Parent                 = overlay,
    })
    new("UIGradient", {
        Color        = gradSeq({Color3.new(1,1,1), Color3.new(1,1,1), Color3.new(1,1,1)}),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent   = shine,
    })

    tween(overlay, 0.25, {BackgroundTransparency=0.55})
    tween(glow,    0.5,  {Size=UDim2.fromScale(2.2, 2.2), ImageTransparency=0.25}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(glow2,   0.6,  {Size=UDim2.fromScale(1.4, 1.4), ImageTransparency=0.5},  Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.15)
    tween(nameTxt, 0.45, {TextSize=64, TextTransparency=0}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(subTxt,  0.4,  {TextTransparency=0})
    task.spawn(function()
        task.wait(0.3)
        tween(shine, 0.55, {Position=UDim2.fromScale(1.1, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end)

    for i = 1, 28 do
        local angle  = (i / 28) * math.pi * 2
        local dist   = 0.25 + math.random() * 0.2
        local tx     = 0.5 + math.cos(angle) * dist
        local ty     = 0.5 + math.sin(angle) * dist * 0.6
        local pColors = {C.Gold, C.Pink, C.Mint, C.Cyan, Color3.new(1,1,1)}
        local sz     = math.random(4, 9)
        local p = new("Frame", {
            Size                   = UDim2.fromOffset(sz, sz),
            AnchorPoint            = Vector2.new(0.5, 0.5),
            Position               = UDim2.fromScale(0.5, 0.5),
            BackgroundColor3       = pColors[(i % #pColors) + 1],
            BackgroundTransparency = 0,
            BorderSizePixel        = 0,
            ZIndex                 = 5,
            Parent                 = overlay,
        })
        corner(p, sz)
        task.spawn(function()
            task.wait(0.1 + math.random() * 0.15)
            tween(p, 0.7 + math.random() * 0.5, {
                Position               = UDim2.fromScale(tx, ty),
                BackgroundTransparency = 1,
                Size                   = UDim2.fromOffset(2, 2),
            }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
    end

    task.wait(1.8)

    tween(overlay, 0.45, {BackgroundTransparency=1})
    tween(glow,    0.4,  {ImageTransparency=1, Size=UDim2.fromScale(3, 3)})
    tween(glow2,   0.4,  {ImageTransparency=1})
    tween(nameTxt, 0.4,  {TextTransparency=1, TextSize=80})
    tween(subTxt,  0.3,  {TextTransparency=1})
    task.wait(0.45)
    pcall(function() eSG:Destroy() end)
end

local CYCLE = {C.Gold, C.Pink, C.Mint, C.Cyan}

local function injectHighlight(f, boxGui)
    if not f or f:FindFirstChild("__THL") then return end
    new("BoolValue", {Name = "__THL", Parent = f})

    local bg = new("Frame", {
        Name                   = "__THLBg",
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = C.Gold,
        BackgroundTransparency = 0.72,
        BorderSizePixel        = 0,
        ZIndex                 = (f.ZIndex or 1) + 3,
        Parent                 = f,
    })
    corner(bg, 4)

    local glow = new("ImageLabel", {
        Image                  = "rbxassetid://5028857084",
        Size                   = UDim2.fromScale(1.4, 1.4),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3            = C.Gold,
        ImageTransparency      = 0.4,
        ZIndex                 = (f.ZIndex or 1) + 2,
        Parent                 = f,
    })

    local hs = new("UIStroke", {
        Thickness       = 3,
        Color           = C.Gold,
        Transparency    = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent          = f,
    })

    task.spawn(function()
        local i = 1
        while hs and hs.Parent and boxGui.Parent do
            local c = CYCLE[(i - 1) % #CYCLE + 1]
            tween(hs,   0.5, {Color = c})
            tween(bg,   0.5, {BackgroundColor3 = c})
            tween(glow, 0.5, {ImageColor3 = c})
            i = i + 1
            task.wait(0.5)
        end
    end)

    task.spawn(function()
        while glow and glow.Parent do
            tween(glow, 0.45, {ImageTransparency = 0.2})
            task.wait(0.45)
            tween(glow, 0.45, {ImageTransparency = 0.55})
            task.wait(0.45)
        end
    end)
end

local function addItemHighlight(animDur, targetItem)
    task.spawn(function()
        local pGui   = LP:WaitForChild("PlayerGui")
        local target = targetItem:lower()

        local boxGui
        for _ = 1, 25 do
            boxGui = pGui:FindFirstChild("MysteryBoxOpen")
            if boxGui then break end
            task.wait(0.08)
        end
        if not boxGui then return end

        local container
        pcall(function() container = boxGui:WaitForChild("Container", 2) end)
        if not container then return end

        local function tryHighlight(child)
            if not (child:IsA("GuiObject") and not child:IsA("UILayout") and not child:IsA("UIPadding")) then return end
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text:lower():find(target, 1, true) then
                    injectHighlight(child, boxGui)
                    if desc.Parent and desc.Parent ~= child then
                        injectHighlight(desc.Parent, boxGui)
                    end
                    return
                end
            end
        end

        local function processMain(mainFrame)
            local mc
            pcall(function()
                mc = mainFrame
                    :WaitForChild("Container",       2)
                    :WaitForChild("Background",      2)
                    :WaitForChild("ItemContainer",   2)
                    :WaitForChild("OffsetContainer", 2)
                    :WaitForChild("MainContainer",   2)
            end)
            if not mc then return end

            for _, child in ipairs(mc:GetChildren()) do tryHighlight(child) end

            mc.ChildAdded:Connect(function(child)
                task.defer(function() tryHighlight(child) end)
            end)
        end

        for _, f in ipairs(container:GetChildren()) do
            if f.Name == "Main" then task.spawn(function() processMain(f) end) end
        end
        container.ChildAdded:Connect(function(f)
            if f.Name == "Main" then task.spawn(function() processMain(f) end) end
        end)
    end)
end

local function runSpawn()
    if spawning then return end
    if itemToSpawn == "" then setStatus("Select an item first", C.Bad); return end
    spawning = true
    spawnBtn.Text = "Spawning..."
    setStatus("Unboxing...", C.Mint)

    task.spawn(function()
        local amount = getItemAmount()
        local payload = {}
        for _ = 1, amount do
            table.insert(payload, {MysteryBoxId = CRATE, RewardedItemId = itemToSpawn})
        end
        _BC:Fire(payload)
        addToInventory(itemToSpawn, amount)

        local animDur = 4.5
        tween(progFill, animDur, {Size=UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Linear)

        addItemHighlight(animDur, itemToSpawn)

        task.wait(animDur)

        playLandEffect(itemToSpawn, amount)
        task.wait(2.3)

        tween(progFill, 0.4, {Size=UDim2.new(0, 0, 1, 0)})
        setStatus("Spawned " .. amount .. "x " .. itemToSpawn, C.Good)
        task.wait(1)
        setStatus("Ready", C.TextSub)
        spawnBtn.Text = "Spawn Item"
        spawning = false
    end)
end

-- ============================================================
-- WIRING
-- ============================================================

filterBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = filterBox.Text:match("^%s*(.-)%s*$") or ""
    if q == "" then hideDropdown(); return end
    if not itemdatabase then return end
    buildDropdown(gettable(q))
end)

filterBox.FocusLost:Connect(function(enter)
    if not enter then task.delay(0.18, hideDropdown) end
end)

dupeBtn.MouseButton1Click:Connect(function()
    if itemToSpawn == "" then setDupeStatus("Select an item first", C.Bad); return end

    local owned   = PlayerWeapons and PlayerWeapons.Owned
    local current = (owned and owned[itemToSpawn]) or 0

    local dupeAmount = getDupeAmount()
    local newTotal   = current + dupeAmount

    PlayerWeapons.Owned[itemToSpawn] = newTotal
    inventory[itemToSpawn] = newTotal

    RunService:BindToRenderStep("DupePin_" .. itemToSpawn, 0, function()
        if PlayerWeapons and PlayerWeapons.Owned then
            PlayerWeapons.Owned[itemToSpawn] = inventory[itemToSpawn]
        end
    end)

    pcall(function()
        ReplicatedStorage.Remotes.Inventory.InventoryDataChanged:Fire()
    end)

    setDupeStatus("Duped +" .. dupeAmount .. "  total: " .. newTotal, C.Good)
end)

spawnBtn.MouseButton1Click:Connect(runSpawn)

-- ============================================================
-- DRAG  (header only â€” mouse + touch)
-- ============================================================

local dragging, dragStart, startPos

header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = i.Position
        startPos  = frame.Position
    end
end)
header.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                   startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ============================================================
-- INTRO / LOAD SCREEN
-- ============================================================

frame.Visible = false

;(function()
    local introSG = Instance.new("ScreenGui")
    introSG.Name           = "TestolSpawnerIntro"
    introSG.DisplayOrder   = 100001
    introSG.ResetOnSpawn   = false
    introSG.IgnoreGuiInset = true
    pcall(function() introSG.Parent = CoreGui end)
    if not introSG.Parent then introSG.Parent = LP:WaitForChild("PlayerGui") end

    local bg = Instance.new("Frame")
    bg.Size                   = UDim2.fromScale(1, 1)
    bg.BackgroundColor3       = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 1
    bg.BorderSizePixel        = 0
    bg.Parent                 = introSG

    local vignette = Instance.new("ImageLabel")
    vignette.Image              = "rbxassetid://5028857084"
    vignette.Size               = UDim2.fromScale(2.5, 2.5)
    vignette.Position           = UDim2.fromScale(0.5, 0.5)
    vignette.AnchorPoint        = Vector2.new(0.5, 0.5)
    vignette.BackgroundTransparency = 1
    vignette.ImageColor3        = C.Pink
    vignette.ImageTransparency  = 1
    vignette.Parent             = bg

    local pColors = {C.Pink, C.Mint, C.Gold, C.Cyan}
    for i = 1, 22 do
        local sz = math.random(2, 5)
        local p  = Instance.new("Frame")
        p.Size                   = UDim2.fromOffset(sz, sz)
        p.Position               = UDim2.fromScale(math.random(), 1.1)
        p.BackgroundColor3       = pColors[(i-1) % #pColors + 1]
        p.BackgroundTransparency = 1
        p.BorderSizePixel        = 0
        p.Parent                 = bg
        local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1,0); pc.Parent = p
        task.spawn(function()
            while p and p.Parent do
                local dur = math.random(7, 14)
                local sx  = math.random() * 0.95
                p.Position = UDim2.fromScale(sx, 1.1)
                p.BackgroundTransparency = 1
                TweenService:Create(p, TweenInfo.new(0.4), {BackgroundTransparency=0.3}):Play()
                TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear),
                    {Position=UDim2.fromScale(sx+(math.random()-0.5)*0.08, -0.05)}):Play()
                task.wait(dur * 0.9)
                TweenService:Create(p, TweenInfo.new(dur*0.1), {BackgroundTransparency=1}):Play()
                task.wait(dur * 0.1 + math.random())
            end
        end)
    end

    TweenService:Create(bg,       TweenInfo.new(0.3),  {BackgroundTransparency=0}):Play()
    TweenService:Create(vignette, TweenInfo.new(0.55), {ImageTransparency=0.65}):Play()
    task.wait(0.3)

    local titleLbl2 = Instance.new("TextLabel")
    titleLbl2.Size                   = UDim2.fromScale(1, 0.18)
    titleLbl2.Position               = UDim2.fromScale(0, 0.38)
    titleLbl2.BackgroundTransparency = 1
    titleLbl2.Font                   = Enum.Font.GothamBlack
    titleLbl2.TextSize               = isMobile and 52 or 62
    titleLbl2.Text                   = ""
    titleLbl2.TextTransparency       = 0
    titleLbl2.TextStrokeColor3       = Color3.new(0,0,0)
    titleLbl2.TextStrokeTransparency = 0.5
    titleLbl2.Parent                 = introSG
    local titleGrad = Instance.new("UIGradient")
    titleGrad.Color  = gradSeq({C.Pink, C.Mint})
    titleGrad.Parent = titleLbl2

    local titleText = "Rhyzen Spawner"
    for i = 1, #titleText do
        titleLbl2.Text = titleText:sub(1, i)
        task.wait(0.055)
    end
    task.wait(0.35)

    local subLbl = Instance.new("TextLabel")
    subLbl.Size                   = UDim2.fromScale(1, 0.08)
    subLbl.Position               = UDim2.fromScale(0, 0.55)
    subLbl.BackgroundTransparency = 1
    subLbl.Text                   = "Remastered  |  Spawn & Dupe"
    subLbl.Font                   = Enum.Font.GothamMedium
    subLbl.TextSize               = 18
    subLbl.TextColor3             = C.TextSub
    subLbl.TextTransparency       = 1
    subLbl.Parent                 = introSG
    TweenService:Create(subLbl, TweenInfo.new(0.35), {TextTransparency=0}):Play()
    task.wait(0.4)

    local btnRow = Instance.new("Frame")
    btnRow.Size                   = UDim2.fromOffset(isMobile and 320 or 380, 52)
    btnRow.AnchorPoint            = Vector2.new(0.5, 0)
    btnRow.Position               = UDim2.new(0.5, 0, 0.7, 0)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent                 = introSG
    local bl = Instance.new("UIListLayout")
    bl.FillDirection        = Enum.FillDirection.Horizontal
    bl.HorizontalAlignment  = Enum.HorizontalAlignment.Center
    bl.Padding              = UDim.new(0, 16)
    bl.Parent               = btnRow

    local function makeBtn(text, ca, cb, primary)
        local btn = Instance.new("TextButton")
        btn.Size                   = UDim2.fromOffset(isMobile and 146 or 176, 52)
        btn.BackgroundColor3       = ca
        btn.BorderSizePixel        = 0
        btn.Text                   = text
        btn.TextColor3             = Color3.new(1,1,1)
        btn.Font                   = Enum.Font.GothamBold
        btn.TextSize               = 14
        btn.AutoButtonColor        = false
        btn.BackgroundTransparency = 1
        btn.TextTransparency       = 1
        btn.Parent                 = btnRow
        local bc = Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,10); bc.Parent=btn
        local bg2 = Instance.new("UIGradient"); bg2.Color=ColorSequence.new(ca,cb); bg2.Rotation=135; bg2.Parent=btn
        local bs = Instance.new("UIStroke"); bs.Thickness=1.5; bs.Color=Color3.new(1,1,1); bs.Transparency=0.6; bs.Parent=btn
        if primary then
            local gl = Instance.new("ImageLabel")
            gl.Image="rbxassetid://5028857084"; gl.Size=UDim2.fromScale(1.5,2)
            gl.AnchorPoint=Vector2.new(0.5,0.5); gl.Position=UDim2.fromScale(0.5,0.5)
            gl.BackgroundTransparency=1; gl.ImageColor3=ca; gl.ImageTransparency=0.5; gl.ZIndex=0; gl.Parent=btn
        end
        TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundTransparency=0, TextTransparency=0}):Play()
        return btn
    end

    local launchBtn = makeBtn("Launch Spawner", C.Pink,    C.Mint,   true)
    local skipBtn2  = makeBtn("Skip",           H"#28263e", H"#16152a", false)

    local chosen
    launchBtn.MouseButton1Click:Connect(function() chosen = "launch" end)
    skipBtn2.MouseButton1Click:Connect(function()  chosen = "skip"   end)
    repeat task.wait() until chosen

    TweenService:Create(subLbl,   TweenInfo.new(0.2), {TextTransparency=1}):Play()
    TweenService:Create(titleLbl2,TweenInfo.new(0.2), {TextTransparency=1}):Play()
    for _, c in ipairs(btnRow:GetChildren()) do
        if c:IsA("TextButton") then
            TweenService:Create(c, TweenInfo.new(0.2), {BackgroundTransparency=1, TextTransparency=1}):Play()
        end
    end
    task.wait(0.2)
    TweenService:Create(bg,       TweenInfo.new(0.35), {BackgroundTransparency=1}):Play()
    TweenService:Create(vignette, TweenInfo.new(0.35), {ImageTransparency=1}):Play()
    task.wait(0.35)
    pcall(function() introSG:Destroy() end)

    frame.Visible = true
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.fromOffset(FW, 0)
    tween(frame, 0.35, {BackgroundTransparency=0, Size=UDim2.fromOffset(FW, FH)},
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- â”€â”€ TOGGLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    if isMobile then
        local tSG = new("ScreenGui", {
            Name="TestolToggle", DisplayOrder=9996,
            ResetOnSpawn=false, IgnoreGuiInset=true,
        })
        pcall(function() tSG.Parent = CoreGui end)
        if not tSG.Parent then tSG.Parent = LP:WaitForChild("PlayerGui") end

        local pill = new("TextButton", {
            Size             = UDim2.fromOffset(88, 30),
            Position         = UDim2.new(1, -96, 1, -46),
            BackgroundColor3 = C.Panel,
            BorderSizePixel  = 0,
            Text             = "Spawner",
            TextColor3       = Color3.new(1,1,1),
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            AutoButtonColor  = false,
            Parent           = tSG,
        })
        corner(pill, 15)
        new("UIGradient", {Color=gradSeq({C.Pink, C.Mint}), Rotation=135, Parent=pill})
        new("UIStroke", {Thickness=1.5, Color=C.Pink, Transparency=0.4,
            ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=pill})

        local td, tdStart, tdPos = false
        pill.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                td=true; tdStart=i.Position; tdPos=pill.Position
            end
        end)
        pill.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then td=false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if td and i.UserInputType == Enum.UserInputType.Touch then
                local d = i.Position - tdStart
                pill.Position = UDim2.new(tdPos.X.Scale, tdPos.X.Offset+d.Y)
            end
        end)

        pill.MouseButton1Click:Connect(function()
            local showing = not frame.Visible
            frame.Visible = showing
            if showing then
                local fp = frame.AbsolutePosition
                local vp = workspace.CurrentCamera.ViewportSize
                if fp.X < -FW*0.5 or fp.X > vp.X - FW*0.5
                or fp.Y < -FH*0.5 or fp.Y > vp.Y - FH*0.5 then
                    frame.Position = UDim2.new(0.5,-FW/2, 0.5,-FH/2)
                end
            end
            pill.Text = showing and "Hide" or "Spawner"
        end)

    else
        UserInputService.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.KeyCode == Enum.KeyCode.RightShift then
                frame.Visible = not frame.Visible
            end
        end)
    end
end)()
