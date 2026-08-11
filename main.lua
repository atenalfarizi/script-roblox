-- Multi-game Hub: Magic Loot + Mine Per Click
local Games = {
	[133188236593503] = {
		name = "Magic Loot",
		url = "https://raw.githubusercontent.com/atenalfarizi/script-roblox/refs/heads/main/games/MagicLoot.lua",
	},
	[74193805629461] = {
		name = "Mine Per Click",
		url = "https://raw.githubusercontent.com/atenalfarizi/script-roblox/main/games/MinePerClick.lua",,
	},
}

local info = Games[game.PlaceId]

if not info then
	warn("[Hub] Game belum didukung | PlaceId:", game.PlaceId)
	return
end

print("[Hub] Loading:", info.name)

local ok, err = pcall(function()
	loadstring(game:HttpGet(info.url))()
end)

if not ok then
	warn("[Hub] Gagal load", info.name, "→", err)
else
	print("[Hub] Loaded:", info.name)
end
