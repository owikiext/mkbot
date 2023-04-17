local DirNorth, DirEast, DirSouth, DirWest = 0, 1, 2, 3
local DirNorthEast, DirSouthEast, DirSouthWest, DirNorthWest = 4, 5, 6, 7
local PlayerPosNeighbours = {
	[DirNorth] = { x = 0, y = -1 },
	[DirEast] = { x = 1, y = 0 },
	[DirSouth] = { x = 0, y = 1 },
	[DirWest] = { x = -1, y = 0 },
	[DirNorthEast] = { x = 1, y = -1 },
	[DirSouthEast] = { x = 1, y = 1 },
	[DirSouthWest] = { x = -1, y = 1 },
	[DirNorthWest] = { x = -1, y = -1 }
}

function GetPosFromDir(pos, dir)
	local x, y, z = pos.x, pos.y, pos.z
	local neighbour = PlayerPosNeighbours[dir]
	return { x = x + neighbour.x, y = y + neighbour.y, z = z }
end

local locations = {}
local __locations = {
  ["2074,2157,7"] = "hydra",
  ["1951,2157,8"] = "warlock",
  ["1921,2211,7"] = "dragon lord",
  ["2001,2005,9"] = "rotworm",
  ["1754,2229,7"] = "cold giant",
  ["2854,3534,7"] = "raiz frog",
  ["1235,1612,7"] = "creep muffer",
  ["2437,3564,7"] = "infernalist",
  ["4645,4537,8"] = 'lubicant',
  ["1783,528,3"] = "poison cever",
  ['1245,744,7'] = 'red ranger',
  ["4235,4499,7"] = "cagnazzo",
  ["1500,3132,8"] = "dwarf soldier",
  ["2845,2751,8"] = "sea predator",
  ["880,558,7"] = "empusa",
  ["2867,2713,8"] = "uatri",
  ["2105,3020,12"] = "grims",
}
for kpos, vname in pairs(__locations) do
	local split_pos = kpos:split(',')
	locations[vname] = {x=split_pos[1],y=split_pos[2],z=split_pos[3]}
end

--[[local locations = {
    ["hydra"] = {x=2074,y=2157,z=7},
    ["warlock"] = {x=1951,y=2157,z=8},
    ["dragon lord"] = {x=1921,y=2211,z=7},
    ["rotworm"] = {x=2001,y=2005,z=9},
    ["cold giant"] = {x=1754,y=2229,z=7},
    ["raiz frog"] = {x=2854,y=3534,z=7},
    ["creep muffer"] = {x=1235,y=1612,z=7},
    ["infernalist"] = {x=2437,y=3564,z=7},
	['lubicant'] = {x=4645,y=4537,z=8},
}]]
setDefaultTab('Main')
local ui = setupUI([[
Panel
  id: wayToAttri
  height: 60
  layout: verticalBox
  BotSeparator
  BotButton
    id: start
    text: Find The Way To Attri
  BotTextEdit
    id: location
    text: dragon lord
  BotSeparator
]])
local ui_start = ui:recursiveGetChildById('start')
local ui_location = ui:recursiveGetChildById('location')
local function WayToAttri()
    local location_text = ui_location:getText():lower()
    local location = locations[location_text]
	local f = modules.game_textmessage.displayGameMessage
    if location == nil then f('location ' .. location_text .. ' is not available.' ) return end
    local ppos = player:getPosition()
    local dx, dy, dz = ppos.x - location.x, ppos.y - location.y, ppos.z - location.z
	local distance = math.max(math.abs(dx), math.abs(dy))
    local msg = ''
	local function info(n, a, b) if n ~= 0 then msg = msg .. '* ' .. math.abs(n) .. ' ' .. (n < 0 and a or b) .. '\n' end end
	info(dx, 'right', 'left')info(dy, 'bottom', 'top')info(dz, 'down', 'up')
	if dz == 0 and distance <= 1 then f(msg .. "on position") return end
	if dz == 0 and distance < 100 then
		local path = getPath(ppos, location, 100, { ignoreNonPathable = false, allowUnseen = true, precision = 1 })
		if path and path[1] then
			g_game.autoWalk(path, {x=0,y=0,z=0})
			f("auto walking")
			return
		end
	end
	if #msg > 0 then msg = msg .. "please move manually, can't auto walk" end
	f(#msg > 0 and ('please move to:\n' .. msg) or ('you are on position!'))
end
ui_start.onClick = WayToAttri