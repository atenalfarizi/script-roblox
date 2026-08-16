-- Magic Loot - Gift by Value (smooth bar + total backpack live)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local RE = RS:WaitForChild("Msg"):WaitForChild("RemoteEvent"):WaitForChild("NetWorkRemoteEvent")
local GIFT = "赠送请求"
local SWITCH_HELD = "背包工具栏切换手持"

local Prices = {
	["Bear Bone"] = 1120,
	["Ice Magic Crystal"] = 1340,
	["Bear Paw"] = 1610,
	["Scarlet Heart Flower"] = 1930, ["绯心花"] = 1930,
	["Blue Dragon Egg"] = 2320,
	["Frost Vein"] = 2780,
}

local PriceList = {}
for name, price in pairs(Prices) do
	table.insert(PriceList, { name = name, low = name:lower(), price = price })
end
table.sort(PriceList, function(a, b) return #a.low > #b.low end)

local MIN_ITEM_VALUE = 2000
local selectedPlayer = nil
local running = false
local cachedItems = {}
local backpackTotal = 0 -- total value backpack (berkurang saat gift)
local delayHold = 1.0
local delayAfterGift = 2.5
local delayBetween = 2.0
local minimized = false
local animating = false
local lastGifted = 0
local scanning = false
local scriptReady = false
local lastCount = -1

local function formatVal(m)
	m = tonumber(m) or 0
	local abs = math.abs(m)
	if abs >= 1e6 then return string.format("%.2fT", m / 1e6)
	elseif abs >= 1 then return string.format("%.2fB", m / 1e3)
	elseif abs > 0 then return string.format("%.3fB", m / 1e3)
	end
	return "0B"
end

pcall(function()
	local o = PG:FindFirstChild("MLGiftValue")
	if o then o:Destroy() end
	local l = PG:FindFirstChild("MLGiftLoad")
	if l then l:Destroy() end
end)

-- LOADING
local loadGui = Instance.new("ScreenGui")
loadGui.Name = "MLGiftLoad"
loadGui.ResetOnSpawn = false
loadGui.IgnoreGuiInset = true
loadGui.DisplayOrder = 100
loadGui.Parent = PG

local loadBg = Instance.new("Frame", loadGui)
loadBg.Size = UDim2.new(1, 0, 1, 0)
loadBg.BackgroundColor3 = Color3.fromRGB(12, 10, 18)

local loadCard = Instance.new("Frame", loadBg)
loadCard.Size = UDim2.new(0, 270, 0, 150)
loadCard.AnchorPoint = Vector2.new(0.5, 0.5)
loadCard.Position = UDim2.new(0.5, 0, 0.5, 0)
loadCard.BackgroundColor3 = Color3.fromRGB(28, 22, 36)
Instance.new("UICorner", loadCard).CornerRadius = UDim.new(0, 12)
local lcs = Instance.new("UIStroke", loadCard)
lcs.Color = Color3.fromRGB(255, 120, 160)
lcs.Transparency = 0.5
lcs.Thickness = 1.3

local loadHeart = Instance.new("TextLabel", loadCard)
loadHeart.Size = UDim2.new(1, 0, 0, 28)
loadHeart.Position = UDim2.new(0, 0, 0, 12)
loadHeart.BackgroundTransparency = 1
loadHeart.Text = "♡"
loadHeart.TextColor3 = Color3.fromRGB(255, 120, 160)
loadHeart.Font = Enum.Font.GothamBold
loadHeart.TextSize = 24

local loadTitle = Instance.new("TextLabel", loadCard)
loadTitle.Size = UDim2.new(1, -16, 0, 24)
loadTitle.Position = UDim2.new(0, 8, 0, 44)
loadTitle.BackgroundTransparency = 1
loadTitle.Text = "Tunggu ya cayang..."
loadTitle.TextColor3 = Color3.fromRGB(255, 210, 230)
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 15

local loadSub = Instance.new("TextLabel", loadCard)
loadSub.Size = UDim2.new(1, -16, 0, 36)
loadSub.Position = UDim2.new(0, 8, 0, 72)
loadSub.BackgroundTransparency = 1
loadSub.Text = "Scan backpack 💕"
loadSub.TextColor3 = Color3.fromRGB(200, 170, 190)
loadSub.Font = Enum.Font.Gotham
loadSub.TextSize = 12
loadSub.TextWrapped = true

local barBg = Instance.new("Frame", loadCard)
barBg.Size = UDim2.new(1, -40, 0, 7)
barBg.Position = UDim2.new(0, 20, 0, 120)
barBg.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 120, 160)
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

-- smooth progress bar
local function setBar(progress, duration)
	duration = duration or 0.55
	TweenService:Create(barFill, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
	}):Play()
end

-- MAIN GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MLGiftValue"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = PG

local f = Instance.new("Frame", gui)
f.Size = UDim2.new(0, 240, 0, 270)
f.AnchorPoint = Vector2.new(0.5, 0.5)
f.Position = UDim2.new(0.5, 0, 0.5, 0)
f.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
f.BackgroundTransparency = 0.15
f.ClipsDescendants = true
f.Active = true
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
local fStroke = Instance.new("UIStroke", f)
fStroke.Color = Color3.fromRGB(120, 140, 180)
fStroke.Transparency = 0.55
fStroke.Thickness = 1.2

local title = Instance.new("TextLabel", f)
title.Size = UDim2.new(1, -28, 0, 24)
title.BackgroundColor3 = Color3.fromRGB(28, 32, 45)
title.BackgroundTransparency = 0.25
title.Text = "  Gift Magic Loot"
title.TextColor3 = Color3.fromRGB(230, 235, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Active = true
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local minBtn = Instance.new("TextButton", f)
minBtn.Size = UDim2.new(0, 26, 0, 24)
minBtn.Position = UDim2.new(1, -26, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(210, 215, 230)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.ZIndex = 2
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

local content = Instance.new("Frame", f)
content.Size = UDim2.new(1, 0, 1, -24)
content.Position = UDim2.new(0, 0, 0, 24)
content.BackgroundTransparency = 1

local st = Instance.new("TextLabel", content)
st.Size = UDim2.new(1, -12, 0, 36)
st.Position = UDim2.new(0, 6, 0, 4)
st.BackgroundTransparency = 1
st.Text = "Buka backpack → auto scan"
st.TextColor3 = Color3.fromRGB(170, 180, 210)
st.Font = Enum.Font.Gotham
st.TextSize = 11
st.TextWrapped = true
st.TextXAlignment = Enum.TextXAlignment.Left

local pScroll = Instance.new("ScrollingFrame", content)
pScroll.Size = UDim2.new(1, -12, 0, 52)
pScroll.Position = UDim2.new(0, 6, 0, 42)
pScroll.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
pScroll.BackgroundTransparency = 0.25
pScroll.BorderSizePixel = 0
pScroll.ScrollBarThickness = 3
Instance.new("UICorner", pScroll).CornerRadius = UDim.new(0, 5)
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 2)

local valBox = Instance.new("TextBox", content)
valBox.Size = UDim2.new(1, -12, 0, 26)
valBox.Position = UDim2.new(0, 6, 0, 100)
valBox.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
valBox.Text = "1"
valBox.TextColor3 = Color3.fromRGB(235, 240, 255)
valBox.Font = Enum.Font.GothamBold
valBox.TextSize = 13
valBox.ClearTextOnFocus = false
Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 5)

local btnContainer = Instance.new("Frame", content)
btnContainer.Size = UDim2.new(1, -12, 0, 100)
btnContainer.Position = UDim2.new(0, 6, 0, 134)
btnContainer.BackgroundTransparency = 1

local BTN_TEXT = Color3.fromRGB(220, 225, 235)
local function createBtn(text, color, y)
	local b = Instance.new("TextButton", btnContainer)
	b.Size = UDim2.new(1, 0, 0, 28)
	b.Position = UDim2.new(0, 0, 0, y)
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = BTN_TEXT
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local startBtn = createBtn("▶   Mulai Gift", Color3.fromRGB(0, 140, 60), 0)
local scanBtn  = createBtn("🔍  Cek Backpack", Color3.fromRGB(55, 85, 140), 34)
local stopBtn  = createBtn("■  Berhenti", Color3.fromRGB(150, 45, 45), 68)

local function status(t) st.Text = t end

local normalSize = UDim2.new(0, 240, 0, 270)
local miniSize   = UDim2.new(0, 240, 0, 24)

local function setMinimized(state)
	if animating then return end
	animating = true
	minimized = state
	if minimized then
		minBtn.Text = "+"
		title.Text = "  Semangat Cayangku ♡"
		content.Visible = false
		local tw = TweenService:Create(f, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = miniSize })
		tw:Play()
		tw.Completed:Wait()
	else
		minBtn.Text = "−"
		title.Text = "  Gift Magic Loot"
		content.Visible = true
		local tw = TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = normalSize })
		tw:Play()
		tw.Completed:Wait()
	end
	animating = false
end

minBtn.MouseButton1Click:Connect(function()
	setMinimized(not minimized)
end)

local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = f.Position
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local function refreshPlayers()
	for _, c in ipairs(pScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local y = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local b = Instance.new("TextButton", pScroll)
			b.Size = UDim2.new(1, -4, 0, 20)
			b.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
			b.Text = plr.Name
			b.TextColor3 = Color3.fromRGB(210, 215, 230)
			b.Font = Enum.Font.Gotham
			b.TextSize = 11
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
			b.MouseButton1Click:Connect(function()
				selectedPlayer = plr
				status("Target: " .. plr.Name)
				for _, x in ipairs(pScroll:GetChildren()) do
					if x:IsA("TextButton") then x.BackgroundColor3 = Color3.fromRGB(45, 50, 65) end
				end
				b.BackgroundColor3 = Color3.fromRGB(0, 120, 70)
			end)
			y += 22
		end
	end
	pScroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function matchPrice(text)
	if not text or text == "" then return nil, 0 end
	local clean = text:gsub("%s+", " "):match("^%s*(.-)%s*$") or text
	if Prices[clean] then return clean, Prices[clean] end
	local low = clean:lower()
	for _, e in ipairs(PriceList) do
		if low == e.low then return e.name, e.price end
	end
	for _, e in ipairs(PriceList) do
		if #e.low >= 4 and low:find(e.low, 1, true) then return e.name, e.price end
	end
	return nil, 0
end

local function recalcTotal()
	local total = 0
	for _, it in ipairs(cachedItems) do total += it.price end
	backpackTotal = total
	return total
end

local function doScan()
	if scanning then return #cachedItems > 0 end
	scanning = true
	local found, seen = {}, {}
	local function consider(oid, name, price)
		if not oid or not name or not price or price < MIN_ITEM_VALUE then return end
		local key = tostring(oid)
		if seen[key] then return end
		seen[key] = true
		table.insert(found, { onlyID = tonumber(oid) or oid, name = name, price = price })
	end
	for _, obj in ipairs(PG:GetDescendants()) do
		local oid = obj:GetAttribute("OnlyID") or obj:GetAttribute("onlyID") or obj:GetAttribute("OnlyId")
		if oid and not seen[tostring(oid)] then
			for _, attr in ipairs({"ItemName", "Name", "ZhName", "ShowName", "itemName", "showName"}) do
				local a = obj:GetAttribute(attr)
				if type(a) == "string" then
					local n, pr = matchPrice(a)
					if n then consider(oid, n, pr) break end
				end
			end
			if not seen[tostring(oid)] then
				local function checkText(t)
					if type(t) == "string" then
						local n, pr = matchPrice(t)
						if n then consider(oid, n, pr) end
					end
				end
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then checkText(obj.Text) end
				for _, ch in ipairs(obj:GetChildren()) do
					if seen[tostring(oid)] then break end
					if ch:IsA("TextLabel") or ch:IsA("TextButton") then checkText(ch.Text) end
					for _, ch2 in ipairs(ch:GetChildren()) do
						if seen[tostring(oid)] then break end
						if ch2:IsA("TextLabel") or ch2:IsA("TextButton") then checkText(ch2.Text) end
					end
				end
			end
		end
	end
	table.sort(found, function(a, b) return a.price < b.price end)
	cachedItems = found
	recalcTotal()
	scanning = false
	return #found > 0
end

local function showScanResult()
	if #cachedItems == 0 then
		backpackTotal = 0
		status("0 item ≥" .. formatVal(MIN_ITEM_VALUE) .. "\nBuka backpack dulu")
	else
		status(string.format("%d Item | Total %s", #cachedItems, formatVal(backpackTotal)))
	end
end

local function closeLoading()
	if scriptReady then return end
	scriptReady = true
	gui.Enabled = true
	pcall(function()
		if loadGui and loadGui.Parent then loadGui:Destroy() end
	end)
	showScanResult()
end

local function manualCheckValue()
	if scanning then status("Sedang scan...") return end
	status("Cek backpack...")
	task.wait(0.2)
	doScan()
	task.wait(0.15)
	doScan()
	showScanResult()
end

local function isHeld(oid)
	local char = LP.Character
	if not char then return false end
	local held = char:FindFirstChild("当前手持")
	if not held then return false end
	local key = tostring(oid)
	for _, m in ipairs(held:GetChildren()) do
		local id = m:GetAttribute("OnlyID") or m:GetAttribute("onlyID")
		if id and tostring(id) == key then return true end
	end
	return false
end

local function holdByOnlyID(oid)
	pcall(function() RE:FireServer(SWITCH_HELD, { onlyID = oid }) end)
end

local function giftTo(uid)
	pcall(function() RE:FireServer(GIFT, uid) end)
end

local function pickItem(remaining, items)
	local bestFit, bestFitIdx = nil, nil
	local smallestOver, smallestOverIdx = nil, nil
	for i, it in ipairs(items) do
		if it.price <= remaining then
			if not bestFit or it.price < bestFit.price then bestFit, bestFitIdx = it, i end
		else
			if not smallestOver or it.price < smallestOver.price then smallestOver, smallestOverIdx = it, i end
		end
	end
	if bestFit then return bestFit, bestFitIdx end
	if smallestOver then return smallestOver, smallestOverIdx end
	return nil, nil
end

local function runGiftByValue()
	if running then return end
	if not selectedPlayer then status("Pilih player") return end
	local targetB = tonumber(valBox.Text) or 0
	if targetB <= 0 then status("Isi target (1 = 1B)") return end
	local target = targetB * 1000

	if #cachedItems == 0 then
		doScan()
		task.wait(0.1)
		doScan()
	end
	if #cachedItems == 0 then status("0 item — buka backpack") return end

	running = true
	lastGifted = 0
	startBtn.Text = "⏳  Gifting..."
	startBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 40)

	local uid = selectedPlayer.UserId
	local gifted, okCount, failCount = 0, 0, 0
	local pool = table.clone(cachedItems)

	while running do
		if gifted >= target or #pool == 0 then break end
		if not selectedPlayer.Parent then break end
		local it, idx = pickItem(target - gifted, pool)
		if not it then break end

		status(string.format("Hold %s (%s)\nGift %s | Bag %s", it.name, formatVal(it.price), formatVal(gifted), formatVal(backpackTotal)))
		holdByOnlyID(it.onlyID)
		task.wait(delayHold)
		if not isHeld(it.onlyID) then
			holdByOnlyID(it.onlyID)
			task.wait(delayHold)
		end
		if not isHeld(it.onlyID) then
			failCount += 1
			table.remove(pool, idx)
			if failCount >= 6 then break end
			task.wait(delayBetween)
			continue
		end

		giftTo(uid)
		task.wait(delayAfterGift)
		if not isHeld(it.onlyID) then
			gifted += it.price
			lastGifted = gifted
			okCount += 1
			table.remove(pool, idx)

			-- kurangi dari cachedItems + backpackTotal
			for j = #cachedItems, 1, -1 do
				if tostring(cachedItems[j].onlyID) == tostring(it.onlyID) then
					table.remove(cachedItems, j)
					break
				end
			end
			backpackTotal = math.max(0, backpackTotal - it.price)

			status(string.format("OK +%s\nGift %s | Bag %s", formatVal(it.price), formatVal(gifted), formatVal(backpackTotal)))
		else
			failCount += 1
			task.wait(2.5)
			if failCount >= 6 then break end
		end
		task.wait(delayBetween)
	end

	running = false
	startBtn.Text = "▶   Mulai Gift"
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	status(string.format("Selesai | Gift %s\nSisa bag: %s | OK %d FAIL %d",
		formatVal(gifted), formatVal(backpackTotal), okCount, failCount))
end

startBtn.MouseButton1Click:Connect(function() task.spawn(runGiftByValue) end)
scanBtn.MouseButton1Click:Connect(function() task.spawn(manualCheckValue) end)
stopBtn.MouseButton1Click:Connect(function()
	running = false
	startBtn.Text = "▶   Mulai Gift"
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	status(string.format("Stopped\nGift %s | Bag %s", formatVal(lastGifted), formatVal(backpackTotal)))
end)

PG.DescendantAdded:Connect(function(obj)
	if running or scanning then return end
	local oid = obj:GetAttribute("OnlyID") or obj:GetAttribute("onlyID") or obj:GetAttribute("OnlyId")
	if not oid then return end
	task.defer(function()
		task.wait(0.25)
		if running or scanning then return end
		doScan()
		if scriptReady and #cachedItems ~= lastCount then
			lastCount = #cachedItems
			showScanResult()
		end
	end)
end)

Players.PlayerAdded:Connect(function() task.wait(0.2) refreshPlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.15) refreshPlayers() end)
refreshPlayers()

-- LOADING + SMOOTH BAR
task.spawn(function()
	local steps = {
		{ t = "Tunggu ya cayang...", s = "Persiapan 💕", p = 0.22 },
		{ t = "Scan backpack...", s = "Cari item...", p = 0.48 },
		{ t = "Scan lagi...", s = "Biar akurat 💕", p = 0.72 },
		{ t = "Hampir selesai...", s = "Sebentar lagi ✨", p = 0.90 },
	}

	for i, step in ipairs(steps) do
		loadTitle.Text = step.t
		loadSub.Text = step.s
		setBar(step.p, 0.65) -- tween smooth

		if i == 2 or i == 3 then
			doScan()
			if #cachedItems > 0 then
				loadSub.Text = string.format("Ketemu %d item | %s 💕", #cachedItems, formatVal(backpackTotal))
			end
		end
		task.wait(0.8)
	end

	doScan()
	setBar(1, 0.45)

	if #cachedItems > 0 then
		loadTitle.Text = "Semangat Jualannya Cayang ♡"
		loadSub.Text = string.format("%d item | %s", #cachedItems, formatVal(backpackTotal))
		lastCount = #cachedItems
	else
		loadTitle.Text = "Semangat Jualannya Cayang ♡"
		loadSub.Text = "Buka backpack ya 💕"
	end

	task.wait(0.85)
	closeLoading()
end)

task.delay(7, function()
	if loadGui and loadGui.Parent then closeLoading() end
end)

print("Gift smooth bar + live backpack total loaded")
