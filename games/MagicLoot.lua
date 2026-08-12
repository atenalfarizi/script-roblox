-- Magic Loot - Gift by Value (M/B/T + item baru) - Mobile Friendly + Minimize
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local RE = RS:WaitForChild("Msg"):WaitForChild("RemoteEvent"):WaitForChild("NetWorkRemoteEvent")
local GIFT = "赠送请求"
local SWITCH_HELD = "背包工具栏切换手持"

-- Harga internal = M (1 = 1M). Edit angka sesuai market.
local Prices = {
	-- lama
	["Ritual Mask"] = 225, ["祭祀面具"] = 225,
	["Staff Gem"] = 200, ["权杖宝石"] = 200,
	["Dwarf Emblem"] = 175, ["矮人徽章"] = 175, ["矮人族徽"] = 175,
	["Firefly"] = 150, ["萤火虫"] = 150,
	["Eye of Stone"] = 125, ["石之眼"] = 125,
	["Ginseng"] = 60, ["人参"] = 60,
	["Queen Blood Sac"] = 55, ["蜘蛛血囊"] = 55, ["女王血囊"] = 55,
	-- baru
	["Bear Bone"] = 1120,
	["Ice Magic Crystal"] = 1340,
	["Bear Paw"] = 1610,
	["Scarlet Heart Flower"] = 1930, ["绯心花"] = 1930,
	["Blue Dragon Egg"] = 2320,
	["Frost Vein"] = 2780,
}

local selectedPlayer = nil
local running = false
local cachedItems = {}
local delayHold = 1.0
local delayAfterGift = 2.5
local delayBetween = 2.0
local minimized = false

-- internal M → tampilan M / B / T
local function formatVal(m)
	m = tonumber(m) or 0
	local abs = math.abs(m)
	if abs >= 1e6 then
		return string.format("%.2fT", m / 1e6)
	elseif abs >= 1e3 then
		return string.format("%.2fB", m / 1e3)
	elseif abs >= 1 then
		return string.format("%.0fM", m)
	elseif abs > 0 then
		return string.format("%.2fM", m)
	end
	return "0"
end

pcall(function()
	local o = PG:FindFirstChild("MLGiftValue")
	if o then o:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "MLGiftValue"
gui.ResetOnSpawn = false
gui.Parent = PG

-- ========== MAIN FRAME (lebih kecil) ==========
local f = Instance.new("Frame", gui)
f.Size = UDim2.new(0, 240, 0, 265)          -- sebelumnya 300x310
f.Position = UDim2.new(0.02, 0, 0.12, 0)
f.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
f.ClipsDescendants = true
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

-- Title bar
local title = Instance.new("TextLabel", f)
title.Size = UDim2.new(1, -28, 0, 24)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
title.Text = "  Gift by Value"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- Minimize button
local minBtn = Instance.new("TextButton", f)
minBtn.Size = UDim2.new(0, 26, 0, 24)
minBtn.Position = UDim2.new(1, -26, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 8)

-- Content container (yang di-hide saat minimize)
local content = Instance.new("Frame", f)
content.Size = UDim2.new(1, 0, 1, -24)
content.Position = UDim2.new(0, 0, 0, 24)
content.BackgroundTransparency = 1
content.Name = "Content"

local st = Instance.new("TextLabel", content)
st.Size = UDim2.new(1, -10, 0, 38)
st.Position = UDim2.new(0, 5, 0, 2)
st.BackgroundTransparency = 1
st.Text = "Scan 1x → gift pelan (anti spam)"
st.TextColor3 = Color3.fromRGB(180, 180, 180)
st.Font = Enum.Font.Gotham
st.TextSize = 11
st.TextWrapped = true
st.TextXAlignment = Enum.TextXAlignment.Left

local function mk(y, t, c)
	local b = Instance.new("TextButton", content)
	b.Size = UDim2.new(1, -10, 0, 24)
	b.Position = UDim2.new(0, 5, 0, y)
	b.BackgroundColor3 = c
	b.Text = t
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	return b
end

local pScroll = Instance.new("ScrollingFrame", content)
pScroll.Size = UDim2.new(1, -10, 0, 55)
pScroll.Position = UDim2.new(0, 5, 0, 42)
pScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
pScroll.BorderSizePixel = 0
pScroll.ScrollBarThickness = 3
Instance.new("UICorner", pScroll).CornerRadius = UDim.new(0, 5)
Instance.new("UIListLayout", pScroll).Padding = UDim.new(0, 2)

local valBox = Instance.new("TextBox", content)
valBox.Size = UDim2.new(1, -10, 0, 26)
valBox.Position = UDim2.new(0, 5, 0, 102)
valBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
valBox.PlaceholderText = "Target: 500=500M"
valBox.Text = "500"
valBox.TextColor3 = Color3.new(1,1,1)
valBox.Font = Enum.Font.GothamBold
valBox.TextSize = 13
Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 5)

local startBtn = mk(134, "Start Gift by Value", Color3.fromRGB(0, 140, 60))
local scanBtn  = mk(162, "Scan Inventory (1x)", Color3.fromRGB(70, 70, 90))
local stopBtn  = mk(190, "Stop", Color3.fromRGB(140, 40, 40))

local function status(t)
	st.Text = t
end

-- ========== Minimize Logic ==========
local normalSize = UDim2.new(0, 240, 0, 265)
local miniSize   = UDim2.new(0, 240, 0, 24)

minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		content.Visible = false
		f.Size = miniSize
		minBtn.Text = "+"
		title.Text = "  Gift by Value "
	else
		content.Visible = true
		f.Size = normalSize
		minBtn.Text = "−"
		title.Text = "  Gift by Value"
	end
end)

-- ========== Player List ==========
local function refreshPlayers()
	for _, c in ipairs(pScroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local y = 0
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local b = Instance.new("TextButton", pScroll)
			b.Size = UDim2.new(1, -4, 0, 20)
			b.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
			b.Text = plr.Name
			b.TextColor3 = Color3.new(1,1,1)
			b.Font = Enum.Font.Gotham
			b.TextSize = 11
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
			b.MouseButton1Click:Connect(function()
				selectedPlayer = plr
				status("Target: " .. plr.Name)
				for _, x in ipairs(pScroll:GetChildren()) do
					if x:IsA("TextButton") then
						x.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
					end
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
	if Prices[text] then return text, Prices[text] end
	local low = text:lower()
	for k, v in pairs(Prices) do
		local kk = k:lower()
		if low == kk or low:find(kk, 1, true) or kk:find(low, 1, true) then
			return k, v
		end
	end
	return nil, 0
end

local function scanInventory()
	status("Scanning...")
	task.wait(0.15)
	local found, seen = {}, {}
	for _, obj in ipairs(PG:GetDescendants()) do
		local oid = obj:GetAttribute("OnlyID") or obj:GetAttribute("onlyID")
		if oid and not seen[tostring(oid)] then
			local matchedName, price = nil, 0
			for _, attr in ipairs({"ItemName", "Name", "ZhName", "ShowName"}) do
				local a = obj:GetAttribute(attr)
				if type(a) == "string" then
					local n, pr = matchPrice(a)
					if n then matchedName, price = n, pr break end
				end
			end
			if not matchedName and obj:IsA("GuiObject") then
				local function check(t)
					if not t then return end
					t = t:gsub("%s+", " "):match("^%s*(.-)%s*$")
					if t and #t > 1 then
						local n, pr = matchPrice(t)
						if n then matchedName, price = n, pr end
					end
				end
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then check(obj.Text) end
				for _, ch in ipairs(obj:GetChildren()) do
					if matchedName then break end
					if ch:IsA("TextLabel") or ch:IsA("TextButton") then check(ch.Text) end
					for _, ch2 in ipairs(ch:GetChildren()) do
						if matchedName then break end
						if ch2:IsA("TextLabel") or ch2:IsA("TextButton") then check(ch2.Text) end
					end
				end
			end
			if matchedName and price > 0 then
				seen[tostring(oid)] = true
				table.insert(found, {
					onlyID = tonumber(oid) or oid,
					name = matchedName,
					price = price,
				})
			end
		end
	end
	table.sort(found, function(a, b) return a.price > b.price end)
	cachedItems = found
	local total = 0
	local parts = {}
	for _, it in ipairs(found) do
		total += it.price
		table.insert(parts, string.format("%s %s", it.name, formatVal(it.price)))
	end
	if #found == 0 then
		status("0 item — buka backpack dulu")
	else
		local preview = table.concat(parts, ", ")
		if #preview > 70 then
			preview = preview:sub(1, 67) .. "..."
		end
		status(string.format("Cache %d item | Total %s\n%s", #found, formatVal(total), preview))
	end
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
	pcall(function()
		RE:FireServer(SWITCH_HELD, { onlyID = oid })
	end)
end

local function giftTo(uid)
	pcall(function()
		RE:FireServer(GIFT, uid)
	end)
end

local function runGiftByValue()
	if running then return end
	if not selectedPlayer then status("Pilih player") return end
	local target = tonumber(valBox.Text) or 0
	if target <= 0 then status("Isi target (500=500M)") return end
	if #cachedItems == 0 then status("Scan dulu (1x)") return end

	running = true
	startBtn.Text = "Gifting..."
	startBtn.BackgroundColor3 = Color3.fromRGB(180, 90, 40)

	local uid = selectedPlayer.UserId
	local gifted, okCount, failCount = 0, 0, 0
	local queue = {}
	for _, it in ipairs(cachedItems) do
		table.insert(queue, it)
	end

	for _, it in ipairs(queue) do
		if not running then break end
		if gifted >= target then break end
		if not selectedPlayer.Parent then
			status("Target keluar")
			break
		end

		status(string.format("Hold %s (%s)\n%s / %s", it.name, formatVal(it.price), formatVal(gifted), formatVal(target)))
		holdByOnlyID(it.onlyID)
		task.wait(delayHold)

		if not isHeld(it.onlyID) then
			holdByOnlyID(it.onlyID)
			task.wait(delayHold)
		end

		if not isHeld(it.onlyID) then
			failCount += 1
			status("Gagal hold " .. it.name)
			task.wait(delayBetween)
			continue
		end

		giftTo(uid)
		status(string.format("Gift %s — tunggu server...", it.name))
		task.wait(delayAfterGift)

		if not isHeld(it.onlyID) then
			gifted += it.price
			okCount += 1
			for j = #cachedItems, 1, -1 do
				if tostring(cachedItems[j].onlyID) == tostring(it.onlyID) then
					table.remove(cachedItems, j)
					break
				end
			end
			status(string.format("OK %s +%s\n%s / %s", it.name, formatVal(it.price), formatVal(gifted), formatVal(target)))
		else
			failCount += 1
			status(string.format("FAIL %s (rate limit?)\nfail %d — jeda ekstra", it.name, failCount))
			task.wait(3.0)
		end

		task.wait(delayBetween)
		if failCount >= 6 then
			status("Banyak gagal — stop. Naikkan delay.")
			break
		end
	end

	running = false
	startBtn.Text = "Start Gift by Value"
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	status(string.format("Selesai → %s\n%s | OK %d | FAIL %d",
		selectedPlayer and selectedPlayer.Name or "?",
		formatVal(gifted), okCount, failCount
	))
end

startBtn.MouseButton1Click:Connect(function() task.spawn(runGiftByValue) end)
scanBtn.MouseButton1Click:Connect(function() task.spawn(scanInventory) end)
stopBtn.MouseButton1Click:Connect(function()
	running = false
	status("Stopped")
	startBtn.Text = "Start Gift by Value"
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
end)

-- Drag
local UIS = game:GetService("UserInputService")
local drag, ds, dp, di
title.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		drag = true
		ds = i.Position
		dp = f.Position
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then drag = false end
		end)
	end
end)
title.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		di = i
	end
end)
UIS.InputChanged:Connect(function(i)
	if i == di and drag then
		local d = i.Position - ds
		f.Position = UDim2.new(dp.X.Scale, dp.X.Offset + d.X, dp.Y.Scale, dp.Y.Offset + d.Y)
	end
end)

Players.PlayerAdded:Connect(function() task.wait(0.3) refreshPlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.2) refreshPlayers() end)
refreshPlayers()

print("Gift M/B/T + Minimize loaded")
