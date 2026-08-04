-- Gift by Value (Anti Lag - Hitung Selisih)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local ok, GiftRemote = pcall(function()
	return RS.Remotes.Server.GiftLoot
end)
if not ok or not GiftRemote then
	warn("GiftLoot tidak ditemukan")
	return
end

local Prices = {
	["Totem"] = 1.20,
	["Glitched Cube"] = 1.00,
	["Dark Matter"] = 1.12,
	["Dinosaur Skull"] = 1.50,
	["Saturn"] = 1.35,
	["Car"] = 1.70,
}

pcall(function()
	local old = PG:FindFirstChild("GiftMobile")
	if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "GiftMobile"
gui.ResetOnSpawn = false
gui.Parent = PG

local f = Instance.new("Frame", gui)
f.Size = UDim2.new(0, 260, 0, 310)
f.Position = UDim2.new(0.5, -130, 0.25, 0)
f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

local logo = Instance.new("TextButton", gui)
logo.Size = UDim2.new(0, 50, 0, 50)
logo.Position = UDim2.new(0.5, -25, 0.25, 0)
logo.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
logo.Text = "G"
logo.TextColor3 = Color3.new(1,1,1)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 22
logo.Visible = false
Instance.new("UICorner", logo).CornerRadius = UDim.new(1, 0)

local title = Instance.new("TextLabel", f)
title.Size = UDim2.new(1, -30, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.Text = "Gift Anti Lag"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local minBtn = Instance.new("TextButton", f)
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -28, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
minBtn.Text = "–"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local totalLbl = Instance.new("TextLabel", f)
totalLbl.Size = UDim2.new(1, -12, 0, 22)
totalLbl.Position = UDim2.new(0, 6, 0, 32)
totalLbl.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
totalLbl.Text = "Inv: ..."
totalLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
totalLbl.Font = Enum.Font.GothamBold
totalLbl.TextSize = 11
Instance.new("UICorner", totalLbl).CornerRadius = UDim.new(0, 5)

local list = Instance.new("ScrollingFrame", f)
list.Size = UDim2.new(1, -12, 0, 90)
list.Position = UDim2.new(0, 6, 0, 58)
list.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new()
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 5)
Instance.new("UIListLayout", list).Padding = UDim.new(0, 3)

local valBox = Instance.new("TextBox", f)
valBox.Size = UDim2.new(1, -12, 0, 26)
valBox.Position = UDim2.new(0, 6, 0, 154)
valBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
valBox.PlaceholderText = "Target (1=1B)"
valBox.Text = "1"
valBox.TextColor3 = Color3.new(1,1,1)
valBox.Font = Enum.Font.Gotham
valBox.TextSize = 12
Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 5)

local startBtn = Instance.new("TextButton", f)
startBtn.Size = UDim2.new(1, -12, 0, 30)
startBtn.Position = UDim2.new(0, 6, 0, 186)
startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
startBtn.Text = "Start Gift"
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 13
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 5)

local refBtn = Instance.new("TextButton", f)
refBtn.Size = UDim2.new(0.48, -4, 0, 26)
refBtn.Position = UDim2.new(0, 6, 0, 222)
refBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
refBtn.Text = "Refresh"
refBtn.TextColor3 = Color3.new(1,1,1)
refBtn.Font = Enum.Font.Gotham
refBtn.TextSize = 11
Instance.new("UICorner", refBtn).CornerRadius = UDim.new(0, 5)

local calcBtn = Instance.new("TextButton", f)
calcBtn.Size = UDim2.new(0.48, -4, 0, 26)
calcBtn.Position = UDim2.new(0.52, 0, 0, 222)
calcBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 90)
calcBtn.Text = "Hitung"
calcBtn.TextColor3 = Color3.new(1,1,1)
calcBtn.Font = Enum.Font.Gotham
calcBtn.TextSize = 11
Instance.new("UICorner", calcBtn).CornerRadius = UDim.new(0, 5)

local st = Instance.new("TextLabel", f)
st.Size = UDim2.new(1, -12, 0, 40)
st.Position = UDim2.new(0, 6, 0, 255)
st.BackgroundTransparency = 1
st.Text = "Pilih player"
st.TextColor3 = Color3.fromRGB(170, 170, 170)
st.Font = Enum.Font.Gotham
st.TextSize = 11
st.TextWrapped = true

minBtn.MouseButton1Click:Connect(function()
	f.Visible = false
	logo.Position = f.Position
	logo.Visible = true
end)
logo.MouseButton1Click:Connect(function()
	logo.Visible = false
	f.Position = logo.Position
	f.Visible = true
end)

local selected, running = nil, false

local function getV(t)
	return (Prices[t.Name] or 0) * 1e9
end

local function getTotalValue()
	local total = 0
	local function scan(c)
		if not c then return end
		for _, i in ipairs(c:GetChildren()) do
			if i:IsA("Tool") then
				local v = getV(i)
				if v > 0 then total += v end
			end
		end
	end
	scan(LP:FindFirstChild("Backpack"))
	scan(LP.Character)
	scan(LP:FindFirstChild("HiddenTools"))
	return total
end

local function calc()
	local total, cnt = 0, 0
	local function scan(c)
		if not c then return end
		for _, i in ipairs(c:GetChildren()) do
			if i:IsA("Tool") then
				local v = getV(i)
				if v > 0 then total += v cnt += 1 end
			end
		end
	end
	scan(LP:FindFirstChild("Backpack"))
	scan(LP.Character)
	totalLbl.Text = string.format("Inv: %.2fB (%d)", total/1e9, cnt)
end

local function equip(t)
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum and t and t.Parent then
		pcall(function() hum:EquipTool(t) end)
		return true
	end
	return false
end

local function refresh()
	if running then return end
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	selected = nil
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			n += 1
			local b = Instance.new("TextButton", list)
			b.Size = UDim2.new(1, -6, 0, 24)
			b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			b.Text = p.Name
			b.TextColor3 = Color3.new(1,1,1)
			b.Font = Enum.Font.Gotham
			b.TextSize = 11
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
			b.MouseButton1Click:Connect(function()
				for _, o in ipairs(list:GetChildren()) do
					if o:IsA("TextButton") then o.BackgroundColor3 = Color3.fromRGB(45, 45, 45) end
				end
				b.BackgroundColor3 = Color3.fromRGB(0, 120, 55)
				selected = p
				st.Text = "Selected: " .. p.Name
			end)
		end
	end
	list.CanvasSize = UDim2.new(0, 0, 0, n * 27)
	st.Text = n == 0 and "Tidak ada player" or ("Pilih player ("..n..")")
end

Players.PlayerAdded:Connect(function() task.wait(0.5) refresh() end)
Players.PlayerRemoving:Connect(function() task.wait(0.3) refresh() end)
refBtn.MouseButton1Click:Connect(refresh)
calcBtn.MouseButton1Click:Connect(calc)

startBtn.MouseButton1Click:Connect(function()
	if running then return end
	if not selected then st.Text = "Pilih player dulu" return end
	local target = tonumber(valBox.Text)
	if not target or target <= 0 then st.Text = "Target salah" return end
	target = target * 1e9
	local uid = selected.UserId
	local name = selected.Name

	running = true
	startBtn.Text = "..."
	startBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 0)

	-- Hitung value SEBELUM gift
	local beforeValue = getTotalValue()
	st.Text = string.format("Sebelum: %.2fB\nMulai gift...", beforeValue/1e9)

	local tools = {}
	local function grab(c)
		if not c then return end
		for _, i in ipairs(c:GetChildren()) do
			if i:IsA("Tool") then
				local v = getV(i)
				if v > 0 then table.insert(tools, {t=i, v=v}) end
			end
		end
	end
	grab(LP:FindFirstChild("Backpack"))
	grab(LP.Character)

	if #tools == 0 then
		st.Text = "Tidak ada item"
		running = false
		startBtn.Text = "Start Gift"
		startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
		return
	end

	table.sort(tools, function(a,b) return a.v > b.v end)

	local cnt = 0
	local estimated = 0

	for _, d in ipairs(tools) do
		if not running or estimated >= target then break end
		if not d.t or not d.t.Parent then continue end

		cnt += 1
		estimated += d.v
		st.Text = string.format("Gift #%d\nEstimasi: %.2fB", cnt, estimated/1e9)

		if equip(d.t) then
			task.wait(0.18)
			pcall(function()
				GiftRemote:FireServer(uid)
			end)
			task.wait(0.22)
		end
	end

	-- Tunggu server selesai proses (penting untuk lag)
	st.Text = "Menunggu server..."
	task.wait(1.8)

	-- Hitung value SESUDAH gift
	local afterValue = getTotalValue()
	local reallyGifted = beforeValue - afterValue

	if reallyGifted < 0 then reallyGifted = 0 end

	st.Text = string.format("Selesai → %s\nBenar-benar gift: %.2fB", name, reallyGifted/1e9)
	running = false
	startBtn.Text = "Start Gift"
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	calc()
end)

-- Drag
local UIS = game:GetService("UserInputService")
local function makeDraggable(obj, handle)
	local drag, start, pos, inp
	handle = handle or obj
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = true
			start = i.Position
			pos = obj.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then drag = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			inp = i
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if i == inp and drag then
			local d = i.Position - start
			obj.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y)
		end
	end)
end
makeDraggable(f, title)
makeDraggable(logo)

refresh()
calc()
print("Gift Anti Lag loaded")
