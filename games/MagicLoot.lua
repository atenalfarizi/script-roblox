-- Magic Loot - Gift by Value (FULL + Auto Discord + Online/Offline)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Vim = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local RE = RS:WaitForChild("Msg"):WaitForChild("RemoteEvent"):WaitForChild("NetWorkRemoteEvent")
local GIFT = "赠送请求"
local SWITCH_HELD = "背包工具栏切换手持"

-- ========== WEBHOOK DISCORD ==========
local WEBHOOK_URL = "https://discord.com/api/webhooks/1540078528911900783/aEt2AN6EId7RSjsxu-xX87_E0jQFsgA4PrvenV8Yfw_QJyVWFNpdcy5-orGa2KDibc4Y"
-- ====================================

local Prices = {
	["Bear Bone"] = 1120,
	["Ice Magic Crystal"] = 1340,
	["Bear Paw"] = 1610,
	["Scarlet Heart Flower"] = 1930, ["绯心花"] = 1930,
	["Blue Dragon Egg"] = 2320,
	["Frost Vein"] = 2780,
}

local PriceLower = {}
for name, price in pairs(Prices) do
	PriceLower[name:lower()] = { name = name, price = price }
end

local MIN_ITEM_VALUE = 1000
local selectedPlayer = nil
local selectedPlayerOnline = false
local running = false
local cachedItems = {}
local backpackTotal = 0

-- ===== DELAY =====
local delayHold = 0.75
local delayAfterGift = 1.8
local delayBetween = 1.0
local holdRetryWait = 0.5
local successCooldown = 1.6

-- ===== RESUME STATE =====
local currentTarget = 0
local currentGifted = 0
local lastGifted = 0

local minimized = false
local animating = false
local scanning = false
local scriptReady = false
local lastScanAt = 0
local SCAN_COOLDOWN = 0.6

-- Discord safety
local lastCheckClick = 0
local DOUBLE_TAP_WINDOW = 3.0
local sendingDiscord = false
local lastDiscordSend = 0
local DISCORD_COOLDOWN = 8.0
local lastAutoDiscordTotal = -1

local function formatVal(m)
	m = tonumber(m) or 0
	local abs = math.abs(m)
	if abs >= 1e6 then return string.format("%.2fT", m / 1e6) end
	if abs >= 1 then return string.format("%.2fB", m / 1e3) end
	if abs > 0 then return string.format("%.3fB", m / 1e3) end
	return "0B"
end

-- ===== DISCORD STORE =====
local STORE_FILE = "MLGift_DiscordMsgIds.json"

local function loadMsgIds()
	local data = {}
	if isfile and isfile(STORE_FILE) then
		local ok, content = pcall(function()
			return readfile(STORE_FILE)
		end)
		if ok and content and content ~= "" then
			local ok2, decoded = pcall(function()
				return HttpService:JSONDecode(content)
			end)
			if ok2 and type(decoded) == "table" then
				data = decoded
			end
		end
	end
	local folder = workspace:FindFirstChild("MLGiftDiscordStore")
	if folder then
		for _, v in ipairs(folder:GetChildren()) do
			if v:IsA("StringValue") and v.Name:sub(1, 4) == "msg_" then
				local name = v.Name:sub(5)
				if not data[name] then
					data[name] = v.Value
				end
			end
		end
	end
	return data
end

local function saveMsgIds(data)
	if writefile then
		pcall(function()
			writefile(STORE_FILE, HttpService:JSONEncode(data))
		end)
	end
	local folder = workspace:FindFirstChild("MLGiftDiscordStore")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "MLGiftDiscordStore"
		folder.Parent = workspace
	end
	for name, id in pairs(data) do
		local key = "msg_" .. name
		local val = folder:FindFirstChild(key)
		if not val then
			val = Instance.new("StringValue")
			val.Name = key
			val.Parent = folder
		end
		val.Value = tostring(id)
	end
end

local function getMessageId()
	local data = loadMsgIds()
	return data[LP.Name]
end

local function setMessageId(id)
	if not id or id == "" then return end
	local data = loadMsgIds()
	data[LP.Name] = tostring(id)
	saveMsgIds(data)
end

local function clearMessageId()
	local data = loadMsgIds()
	data[LP.Name] = nil
	saveMsgIds(data)
end

-- ===== HTTP REQUEST =====
local function httpRequest(opts)
	if syn and syn.request then
		return syn.request(opts)
	elseif http_request then
		return http_request(opts)
	elseif request then
		return request(opts)
	elseif http and http.request then
		return http.request(opts)
	else
		local ok, res = pcall(function()
			return HttpService:RequestAsync({
				Url = opts.Url,
				Method = opts.Method or "POST",
				Headers = opts.Headers or {},
				Body = opts.Body
			})
		end)
		if ok then return res end
		return nil
	end
end

pcall(function()
	local o = PG:FindFirstChild("MLGiftValue")
	if o then o:Destroy() end
	local l = PG:FindFirstChild("MLGiftLoad")
	if l then l:Destroy() end
end)

-- ===== LOADING =====
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
loadSub.Text = "Buka backpack + scan 💕"
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

local function setBar(p, dur)
	TweenService:Create(barFill, TweenInfo.new(dur or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(math.clamp(p, 0, 1), 0, 1, 0)
	}):Play()
end

local function softOpenBackpack()
	pcall(function()
		RE:FireServer("打开背包")
	end)
	pcall(function()
		Vim:SendKeyEvent(true, Enum.KeyCode.Backquote, false, game)
		task.wait(0.03)
		Vim:SendKeyEvent(false, Enum.KeyCode.Backquote, false, game)
	end)
end

-- ===== MAIN GUI =====
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
title.Text = " Gift Magic Loot"
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
valBox.PlaceholderText = "Target: 1 = 1B"
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

local startBtn = createBtn("▶ Mulai Gift", Color3.fromRGB(0, 140, 60), 0)
local scanBtn  = createBtn("🔍 Cek Backpack", Color3.fromRGB(55, 85, 140), 34)
local stopBtn  = createBtn("■ Berhenti", Color3.fromRGB(150, 45, 45), 68)

local function status(t) st.Text = t end

local function progressText()
	if currentTarget <= 0 then
		return string.format("%s / -", formatVal(currentGifted))
	end
	return string.format("%s / %s", formatVal(currentGifted), formatVal(currentTarget))
end

local normalSize = UDim2.new(0, 240, 0, 270)
local miniSize   = UDim2.new(0, 240, 0, 24)

local function setMinimized(state)
	if animating then return end
	animating = true
	minimized = state
	if minimized then
		minBtn.Text = "+"
		title.Text = " Semangat Cayangku ♡"
		content.Visible = false
		local tw = TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = miniSize })
		tw:Play()
		tw.Completed:Wait()
	else
		minBtn.Text = "−"
		title.Text = " Gift Magic Loot"
		content.Visible = true
		local tw = TweenService:Create(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = normalSize })
		tw:Play()
		tw.Completed:Wait()
	end
	animating = false
end

minBtn.MouseButton1Click:Connect(function()
	task.spawn(setMinimized, not minimized)
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
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
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
				selectedPlayerOnline = true
				status("Target: " .. plr.Name .. " (Online)")
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
	if type(text) ~= "string" or text == "" then return nil, 0 end
	local clean = text:match("^%s*(.-)%s*$") or text
	if Prices[clean] then return clean, Prices[clean] end
	local hit = PriceLower[clean:lower()]
	if hit then return hit.name, hit.price end
	local low = clean:lower()
	for k, v in pairs(PriceLower) do
		if #k >= 4 and low:find(k, 1, true) then
			return v.name, v.price
		end
	end
	return nil, 0
end

local function doScan(force)
	local now = os.clock()
	if scanning then return #cachedItems > 0 end
	if not force and (now - lastScanAt) < SCAN_COOLDOWN then
		return #cachedItems > 0
	end
	scanning = true
	lastScanAt = now
	local found, seen = {}, {}
	local total = 0
	for _, obj in ipairs(PG:GetDescendants()) do
		local oid = obj:GetAttribute("OnlyID") or obj:GetAttribute("onlyID")
		if oid then
			local key = tostring(oid)
			if not seen[key] then
				local name, price = nil, 0
				for _, attr in ipairs({"ItemName", "ZhName", "ShowName", "Name"}) do
					local a = obj:GetAttribute(attr)
					if type(a) == "string" then
						name, price = matchPrice(a)
						if name then break end
					end
				end
				if not name and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
					name, price = matchPrice(obj.Text)
				end
				if not name then
					for _, ch in ipairs(obj:GetChildren()) do
						if ch:IsA("TextLabel") or ch:IsA("TextButton") then
							name, price = matchPrice(ch.Text)
							if name then break end
						end
					end
				end
				if name and price >= MIN_ITEM_VALUE then
					seen[key] = true
					total += price
					found[#found + 1] = { onlyID = tonumber(oid) or oid, name = name, price = price }
				end
			end
		end
	end
	table.sort(found, function(a, b) return a.price < b.price end)
	cachedItems = found
	backpackTotal = total
	scanning = false
	return #found > 0
end

local function showScanResult()
	if #cachedItems == 0 then
		status("0 item ≥" .. formatVal(MIN_ITEM_VALUE) .. "\nBuka backpack dulu")
	else
		status(string.format("%d Item | Total %s", #cachedItems, formatVal(backpackTotal)))
	end
end

-- ===== DISCORD =====
local function sendToDiscord(opts)
	opts = opts or {}
	local isAuto = opts.auto == true
	local force = opts.force == true
	local forceStatus = opts.status

	if sendingDiscord then
		if not isAuto then status("Sedang kirim Discord...") end
		return false
	end

	if not force and (os.clock() - lastDiscordSend) < DISCORD_COOLDOWN then
		if not isAuto then
			status(string.format("Tunggu %ds lagi\nbaru bisa kirim Discord",
				math.ceil(DISCORD_COOLDOWN - (os.clock() - lastDiscordSend))))
		end
		return false
	end

	if not WEBHOOK_URL or WEBHOOK_URL == "" or WEBHOOK_URL:find("ISI_WEBHOOK") then
		if not isAuto then status("Webhook belum diisi!") end
		return false
	end

	if isAuto and not force and lastAutoDiscordTotal == backpackTotal and not forceStatus then
		return false
	end

	sendingDiscord = true
	lastDiscordSend = os.clock()

	local itemCount = #cachedItems
	local totalStr = formatVal(backpackTotal)
	local timeStr = os.date("%d/%m %H:%M")
	local onlineStatus = forceStatus or "Online"

	local embed = {
		title = "📦 Backpack - " .. LP.Name,
		color = (onlineStatus == "Online") and 5814783 or 10027059,
		fields = {
			{ name = "Item", value = tostring(itemCount), inline = true },
			{ name = "Total Value", value = totalStr, inline = true },
			{ name = "Status", value = onlineStatus, inline = true },
			{ name = "Update", value = timeStr, inline = true },
		},
		footer = { text = "Magic Loot • " .. LP.Name }
	}

	local payload = HttpService:JSONEncode({
		username = "Magic Loot",
		embeds = { embed }
	})

	local headers = { ["Content-Type"] = "application/json" }
	local msgId = getMessageId()
	local success = false

	if msgId and msgId ~= "" then
		local res = httpRequest({
			Url = WEBHOOK_URL .. "/messages/" .. msgId,
			Method = "PATCH",
			Headers = headers,
			Body = payload
		})
		local code = res and (res.StatusCode or res.Status or res.status_code)
		if res and (res.Success or code == 200) then
			success = true
		else
			clearMessageId()
		end
	end

	if not success then
		local res = httpRequest({
			Url = WEBHOOK_URL .. "?wait=true",
			Method = "POST",
			Headers = headers,
			Body = payload
		})
		local code = res and (res.StatusCode or res.Status or res.status_code)
		if res and (res.Success or code == 200) then
			local bodyStr = res.Body or res.body
			if bodyStr and bodyStr ~= "" then
				local ok, body = pcall(function()
					return HttpService:JSONDecode(bodyStr)
				end)
				if ok and body and body.id then
					setMessageId(body.id)
				end
			end
			success = true
		end
	end

	sendingDiscord = false

	if success then
		lastAutoDiscordTotal = backpackTotal
		if not isAuto then
			status(string.format("%d Item | %s | %s\n✓ Update Discord", itemCount, totalStr, onlineStatus))
		else
			status(string.format("%d Item | %s | %s\n✓ Auto update Discord", itemCount, totalStr, onlineStatus))
		end
		return true
	else
		if not isAuto then
			status("Gagal kirim Discord\nCek executor / webhook")
		end
		return false
	end
end

local function autoUpdateDiscordAfterGift(okCount)
	task.spawn(function()
		if not okCount or okCount <= 0 then return end
		task.wait(0.5)
		if running then return end
		sendToDiscord({ auto = true })
	end)
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

	local now = os.clock()
	local isDoubleTap = (now - lastCheckClick) <= DOUBLE_TAP_WINDOW
	lastCheckClick = now
	if isDoubleTap then lastCheckClick = 0 end

	status("Cek backpack...")
	softOpenBackpack()
	task.wait(0.3)
	doScan(true)
	showScanResult()

	if isDoubleTap then
		task.wait(0.15)
		sendToDiscord({ force = true })
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

local function ensureHeld(oid)
	for attempt = 1, 3 do
		holdByOnlyID(oid)
		task.wait(delayHold)
		if isHeld(oid) then return true end
		task.wait(holdRetryWait)
	end
	return false
end

local function pickItem(remaining, items)
	local bestFit, bestFitIdx, smallestOver, smallestOverIdx
	for i, it in ipairs(items) do
		if it.price <= remaining then
			if not bestFit or it.price < bestFit.price then
				bestFit, bestFitIdx = it, i
			end
		elseif not smallestOver or it.price < smallestOver.price then
			smallestOver, smallestOverIdx = it, i
		end
	end
	if bestFit then return bestFit, bestFitIdx end
	if smallestOver then return smallestOver, smallestOverIdx end
	return nil, nil
end

local function runGiftByValue()
	if running then return end
	if not selectedPlayer then status("Pilih player") return end
	if not selectedPlayer.Parent then
		status("Target offline")
		selectedPlayer = nil
		selectedPlayerOnline = false
		return
	end

	local targetB = tonumber(valBox.Text) or 0
	if targetB <= 0 then status("Isi target (1 = 1B)") return end
	local newTarget = targetB * 1000

	if newTarget ~= currentTarget then
		currentTarget = newTarget
		currentGifted = 0
	end
	if currentGifted >= currentTarget then
		currentGifted = 0
	end

	if #cachedItems == 0 then
		softOpenBackpack()
		task.wait(0.3)
		doScan(true)
	end
	if #cachedItems == 0 then status("0 item — buka backpack") return end

	running = true
	startBtn.Text = "⏳ Gifting..."
	startBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 40)

	local uid = selectedPlayer.UserId
	local okCount, failCount = 0, 0
	local pool = table.clone(cachedItems)

	while running do
		if currentGifted >= currentTarget or #pool == 0 then break end
		if not selectedPlayer or not selectedPlayer.Parent then
			status("Target keluar game")
			break
		end

		local remaining = currentTarget - currentGifted
		local it, idx = pickItem(remaining, pool)
		if not it then break end

		status(string.format("Hold %s (%s)\n%s", it.name, formatVal(it.price), progressText()))

		local heldOk = ensureHeld(it.onlyID)
		if not heldOk then
			failCount += 1
			status(string.format("Gagal hold %s\n%s | fail %d", it.name, progressText(), failCount))
			table.remove(pool, idx)
			if failCount >= 8 then break end
			task.wait(delayBetween)
			continue
		end

		giftTo(uid)
		task.wait(delayAfterGift)

		if not isHeld(it.onlyID) then
			currentGifted += it.price
			lastGifted = currentGifted
			okCount += 1
			table.remove(pool, idx)

			for j = #cachedItems, 1, -1 do
				if tostring(cachedItems[j].onlyID) == tostring(it.onlyID) then
					table.remove(cachedItems, j)
					break
				end
			end
			backpackTotal = math.max(0, backpackTotal - it.price)
			status(string.format("OK +%s\n%s", formatVal(it.price), progressText()))
			task.wait(successCooldown)
		else
			failCount += 1
			status(string.format("GIFT FAILED %s\n%s | fail %d", it.name, progressText(), failCount))
			task.wait(1.6)
			if failCount >= 8 then break end
		end

		task.wait(delayBetween)
	end

	running = false
	startBtn.Text = "▶ Mulai Gift"
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)

	local kurang = math.max(0, currentTarget - currentGifted)
	if currentGifted >= currentTarget then
		status(string.format("Selesai ✓\n%s\nOK %d | FAIL %d", progressText(), okCount, failCount))
		currentGifted = 0
		currentTarget = 0
	else
		status(string.format("Stopped / Gagal\n%s\nKurang: %s | OK %d FAIL %d",
			progressText(), formatVal(kurang), okCount, failCount))
	end

	autoUpdateDiscordAfterGift(okCount)
end

startBtn.MouseButton1Click:Connect(function() task.spawn(runGiftByValue) end)
scanBtn.MouseButton1Click:Connect(function() task.spawn(manualCheckValue) end)
stopBtn.MouseButton1Click:Connect(function()
	if not running then return end
	running = false
	startBtn.Text = "▶ Mulai Gift"
	startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
	local kurang = math.max(0, currentTarget - currentGifted)
	if currentTarget > 0 then
		status(string.format("Stopped\n%s\nKurang: %s", progressText(), formatVal(kurang)))
	else
		status(string.format("Stopped\nGift %s | Bag %s", formatVal(lastGifted), formatVal(backpackTotal)))
	end
	if lastGifted > 0 then
		autoUpdateDiscordAfterGift(1)
	end
end)

-- ===== PLAYER LEAVE → AUTO UPDATE =====
local function onPlayerLeft(plr)
	if selectedPlayer and plr == selectedPlayer then
		selectedPlayer = nil
		selectedPlayerOnline = false
		if running then
			running = false
			startBtn.Text = "▶ Mulai Gift"
			startBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
			status("Target keluar game\nGift di-stop")
		else
			status("Target keluar game")
		end
		task.spawn(function()
			task.wait(0.3)
			sendToDiscord({ auto = true, force = true })
		end)
	end

	if plr == LP then
		pcall(function()
			sendToDiscord({ auto = true, force = true, status = "Offline" })
		end)
	end
end

Players.PlayerRemoving:Connect(function(plr)
	task.spawn(onPlayerLeft, plr)
end)

local pendingScan = false
PG.DescendantAdded:Connect(function(obj)
	if not scriptReady or running or scanning or pendingScan then return end
	if not (obj:GetAttribute("OnlyID") or obj:GetAttribute("onlyID")) then return end
	pendingScan = true
	task.delay(0.35, function()
		pendingScan = false
		if running or scanning then return end
		local before = #cachedItems
		doScan(false)
		if #cachedItems ~= before then showScanResult() end
	end)
end)

Players.PlayerAdded:Connect(function() task.wait(0.2) refreshPlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.15) refreshPlayers() end)
refreshPlayers()

task.spawn(function()
	setBar(0.2, 0.25)
	loadTitle.Text = "Tunggu ya cayang..."
	loadSub.Text = "Buka backpack 💕"
	softOpenBackpack()
	task.wait(0.4)
	setBar(0.55, 0.3)
	loadTitle.Text = "Scan backpack..."
	loadSub.Text = "Cari item..."
	doScan(true)
	if #cachedItems > 0 then
		loadSub.Text = string.format("Ketemu %d item | %s 💕", #cachedItems, formatVal(backpackTotal))
	end
	task.wait(0.35)

	if #cachedItems == 0 then
		setBar(0.75, 0.25)
		loadTitle.Text = "Coba lagi..."
		loadSub.Text = "Buka backpack ulang 💕"
		softOpenBackpack()
		task.wait(0.4)
		doScan(true)
		if #cachedItems > 0 then
			loadSub.Text = string.format("Ketemu %d item | %s 💕", #cachedItems, formatVal(backpackTotal))
		end
		task.wait(0.3)
	end

	setBar(1, 0.25)
	if #cachedItems > 0 then
		loadTitle.Text = "Semangat Jualannya Cayang ♡"
		loadSub.Text = string.format("%d item | %s", #cachedItems, formatVal(backpackTotal))
	else
		loadTitle.Text = "Semangat Jualannya Cayang ♡"
		loadSub.Text = "Buka backpack manual ya 💕"
	end
	task.wait(0.45)
	closeLoading()
end)

task.delay(5, function()
	if loadGui and loadGui.Parent then closeLoading() end
end)

print("Gift FULL + Auto Discord + Online/Offline loaded")
