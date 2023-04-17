setDefaultTab('Main')

local CONFIG_PLAYER_PATH = PLAYER_DIR .. 'FollowBot.json'
local CONFIG_MULTIEXE_PATH = MULTIEXE_DIR .. 'FollowBot.json'
local CONFIG_PLAYER_ENUM, CONFIG_MULTIEXE_ENUM = 1, 2
local CONFIG_PLAYER, CONFIG_MULTIEXE = {}, { leader_path = {} }
local CONFIG_LEADER_PATH = CONFIG_MULTIEXE.leader_path

local g_game_findItemInContainers = g_game.findItemInContainers

local GetPosFromDir = GetPosFromDir
local fs_read_table, fs_write_table = fs_read_table, fs_write_table
local pairs, table_insert, table_remove = pairs, table.insert, table.remove

local function ReadSettings(config_enum)
	if config_enum == CONFIG_PLAYER_ENUM then
		return fs_read_table(CONFIG_PLAYER_PATH)
	end
	if config_enum == CONFIG_MULTIEXE_ENUM then
		return fs_read_table(CONFIG_MULTIEXE_PATH)
	end
	return {}
end

local function SaveSettings(config_enum)
	if config_enum == CONFIG_PLAYER_ENUM then
		return fs_write_table(CONFIG_PLAYER_PATH, CONFIG_PLAYER)
	elseif config_enum == CONFIG_MULTIEXE_ENUM then
		return fs_write_table(CONFIG_MULTIEXE_PATH, CONFIG_MULTIEXE)
	end
end

if fs_file_exists(CONFIG_PLAYER_PATH) then
	local CompareSettings
	CompareSettings = function(s1, s2)
		for k, v in pairs(s1) do
			if s2[k] then
				if type(v) ~= type(s2[k]) then
					--print(1, k, type(v), type(s2[k]))
					s2[k] = v
				elseif type(v) == 'table' then
					CompareSettings(s1[k], s2[k])
				else
					--print(2, k, type(v), type(s2[k]))
					s2[k] = v
				end
			else
				--print(3, k, type(v))
				s2[k] = v
			end
		end
	end
	CompareSettings(ReadSettings(CONFIG_PLAYER_ENUM), CONFIG_PLAYER)
	SaveSettings(CONFIG_PLAYER_ENUM)
else
	SaveSettings(CONFIG_PLAYER_ENUM)
end
if not fs_file_exists(CONFIG_MULTIEXE_PATH) then
	SaveSettings(CONFIG_MULTIEXE_ENUM)
end

local type, math_min, math_abs, math_max, tonumber, g_game_getPing = type, math.min, math.abs, math.max, tonumber,
g_game.getPing
local PLAYER, PLAYER_NAME = g_game.getLocalPlayer(), g_game.getCharacterName()
local getDirectionFromPos = getDirectionFromPos

-------------------------------------

local LEADER_IPOS = 0

local CurrentPos = PLAYER:getPosition()
local CurrentPlayerStates = PLAYER:getStates()

local FOLLOW_ACTION_GOTO = 0
local FOLLOW_ACTION_TP = 1
local FOLLOW_ACTION_ITEM = 2
local FOLLOW_ACTION_EXANIHUR = 3
local FOLLOW_ACTION_ROPE = 4
local FOLLOW_ACTION_BLOCKED_PATH = 5

local FOLLOWER_WAIT_TIMEOUT = 0
local FOLLOWER_LAST_ACTION = nil
local FOLLOWER_PATH = {}
local MultiExeTimer = 0

local SETTINGS = nil

local function PosToID(pos)
	return pos.x .. "," .. pos.y .. "," .. pos.z
end

local function GetDistanceBetween(p1, p2, check_z)
	if check_z == nil then
		check_z = true
	end
	if not p2 then
		print("FollowBot.lua GetDistanceBetween p2 nil")
	end
	if check_z and p1.z ~= p2.z then
		return 1000
	end
	return math_max(math_abs(p1.x - p2.x), math_abs(p1.y - p2.y))
end

local function copy(info)
	return { info[1], { x = info[2].x, y = info[2].y, z = info[2].z }, info[3], info[4] }
end

local function WalkToDir(dir)
	if player:canWalk(dir, false) then
		FOLLOWER_WAIT_TIMEOUT = now + 250 + g_game_getPing()
		FOLLOWER_LAST_ACTION = { -1, GetPosFromDir(CurrentPos, dir), -1 }
		g_game.walk(dir, false)
		--print('walk')
		return true
	end
	print('CANT WALK!!!')
	return false
end

local function PathInfo(src, dst, ignore_blocking, precision)
	local distance = GetDistanceBetween(src, dst)
	if distance == 0 then
		return -1
	end
	if distance == 1 and not ignore_blocking then
		for _, spec in ipairs(SPECTATORS) do
			if GetDistanceBetween(spec[2], dst) == 0 then
				return -1
			end
		end
	end
	local path = getPath(src, dst, distance + 5,
	{ precision = precision or 1, ignoreNonPathable = not CurrentIsInPz, allowUnseen = true, allowOnlyVisibleTiles = false })
	if path and path[1] then
		return path[1]
	end
	return -2
end

local function ResetMove()
	if FOLLOWER_LAST_ACTION then
		if now < FOLLOWER_WAIT_TIMEOUT then
			local path = PathInfo(CurrentPos, FOLLOWER_LAST_ACTION[2], CurrentIsInPz)
			--spec blocking path or on position or cant find path
			if path == -1 or path == -2 then
				FOLLOWER_LAST_ACTION = nil
				return true
			end
			return false
		end
		FOLLOWER_LAST_ACTION = nil
	end
	return true
end

local function TryUseItem(info)
	if info[1] ~= FOLLOW_ACTION_ITEM then
		return false
	end
	local tile = g_map.getTile(info[2])
	local item = tile and tile:getTopUseThing() or nil
	local item_id = item and item:getId() or 0
	if info[3] == item_id then
		FOLLOWER_WAIT_TIMEOUT = now + 250 + g_game_getPing()
		FOLLOWER_LAST_ACTION = copy(info)
		g_game.use(item)
		return true
	end
	return false
end

local function TryUseTeleportItem(info)
	if info[1] ~= FOLLOW_ACTION_ITEM then
		return false
	end
	if info[3] ~= 3232 then
		return false
	end
	local item = g_game_findItemInContainers(3232)
	if item then
		g_game.use(item)
		TELEPORT_ITEM_TIMER = now
		return true
	end
	return false
end

local function TryUseRope(info)
	if info[1] ~= FOLLOW_ACTION_ROPE then
		return false
	end
	local tile = g_map.getTile(info[2])
	local item = tile and tile:getTopUseThing() or nil
	if item then
		FOLLOWER_WAIT_TIMEOUT = now + 250 + g_game_getPing()
		FOLLOWER_LAST_ACTION = copy(info)
		g_game.useInventoryItemWith(info[3], item)
		return true
	end
	return false
end

local function TryExaniHur(i)
	local info = FOLLOWER_PATH[i]
	if info[1] ~= FOLLOW_ACTION_EXANIHUR then
		return false
	end
	for j = i - 1, 1, -1 do
		local info_prev = FOLLOWER_PATH[j]
		if info_prev and info_prev[2].z == CurrentPos.z then
			if info_prev[5] > 0 then
				local path = PathInfo(CurrentPos, info_prev[2])
				if path > -1 then
					WalkToDir(path)
					return true
				end
			elseif player:getDirection() ~= info[3] then
				g_game.turn(info[3])
			else
				local dz = info_prev[2].z - info[2].z
				if dz < 0 then
					g_game.talk('exani hur "down')
					return true
				end
				if dz > 0 then
					g_game.talk('exani hur "up')
					return true
				end
			end
			return false
		end
	end
	return false
end

local function UnlockLeaderPath()
	local info = FOLLOWER_PATH[#FOLLOWER_PATH]
	if info == nil or info[1] ~= FOLLOW_ACTION_BLOCKED_PATH then return false end
	local path_info = PathInfo(CurrentPos, info[2])
	if path_info and path_info >= 0 then
		WalkToDir(path_info)
	end
	print('blocked path')
	return true
end

local function MoveToLeader()
	local leader = getCreatureByName(CONFIG_MULTIEXE.leader_name)
	if leader == nil then
		return false
	end
	local leader_pos = leader:getPosition()
	local path = PathInfo(CurrentPos, leader_pos, true, CONFIG_MULTIEXE.follow_maxdist_textedit)
	if path == -1 then
		--use item if last action is item
		--print(0, now)
		TryUseItem(FOLLOWER_PATH[#FOLLOWER_PATH])
		return true
	end
	local distance = GetDistanceBetween(leader_pos, CurrentPos)
	if distance <= CONFIG_MULTIEXE.follow_maxdist_textedit then
		--use item if last action is item
		TryUseItem(FOLLOWER_PATH[#FOLLOWER_PATH])
		--print(1, now)
		return true
	end
	if path == -2 then
		--print(2, now)
		return false
	end
	--move to leader
	WalkToDir(path)
	--print(3, now)
	return true
end

local function DoAction(i)
	local info = FOLLOWER_PATH[i]
	local info_pos = info[2]
	local info_dist = info[5]

	if info_pos.z ~= CurrentPos.z then
		if TryExaniHur(i) then
			print('exani hur')
			return true
		end
		return false
	end

	if info_dist > 20 then
		return false
	end

	if info_dist <= 1 and TryUseTeleportItem(info) then
		print('using teleport item 1')
		return true
	end

	if info_dist <= 1 and TryUseItem(info) then
		print('using item 1')
		return true
	end

	if info_dist <= 1 and TryUseRope(info) then
		print('using rope 1')
		return true
	end

	if info_dist == 0 then
		if i > 1 then
			for j = i - 1, #FOLLOWER_PATH do
				local infoj = FOLLOWER_PATH[j]
				if infoj[5] <= 1 and TryUseItem(infoj) then
					print('using item 2')
					return true
				end
				if infoj[5] <= 1 and TryUseRope(infoj) then
					print('using rope 2')
					return true
				end
				if infoj[5] <= 1 and TryUseTeleportItem(infoj) then
					print('using teleport item 2')
					return true
				end
			end
		end
		--print('dist == 0', info[1])
		return true
	end

	if info_dist >= 1 then
		local path = PathInfo(CurrentPos, info_pos)
		if path > -1 then
			WalkToDir(path)
			return true
		end
	end

	return false
end

local function NormalFollow()
	if not ResetMove() then
		return
	end

	if UnlockLeaderPath() then
		return
	end

	if MoveToLeader() then
		return
	end

	for i = #FOLLOWER_PATH, 1, -1 do
		if DoAction(i) then
			return
		end
	end
end

-------------------------------------

local __settings = Class()

function __settings:__init()
	self.follow_action_timer = 0

	local function __READ__(config, read_result)
		for i = #config, 1, -1 do
			table_remove(config, i)
		end
		for i = 1, #read_result do
			table_insert(config, read_result[i])
		end
	end

	self.__read__ = {
		['leader_path'] = function(v) __READ__(CONFIG_LEADER_PATH, v) end,
	}

	self.__configs__ = {
		[CONFIG_PLAYER_ENUM] = { CONFIG_PLAYER_PATH, CONFIG_PLAYER },
		[CONFIG_MULTIEXE_ENUM] = { CONFIG_MULTIEXE_PATH, CONFIG_MULTIEXE },
	}

	self:Menu_FollowBot()
end

function __settings:Menu_FollowBot()
	local followBot = [[
Panel
  layout: verticalBox
  height: 160
  BotLabel
  BotSwitch
    id: is_follower_switch
    text: Is Follower
  BotSwitch
    id: is_leader_switch
    text: Is Leader
  BotSwitch
    id: follow_quest_switch
    text: Quest Follow
  BotLabel
    id: FollowQuestLabel
    !text: tr('Follow Delay:  ')
  BotTextEdit
    id: follow_delay_textedit
  BotLabel
    id: FollowDistanceLabel
    !text: tr('Hold Distance:  ')
  BotTextEdit
    id: follow_maxdist_textedit
]]
	self.followBot = setupUI(followBot)

	local player_settings = {
		switch = {
			is_follower_switch = true,
			is_leader_switch = false,
			follow_quest_switch = false,
		},
		textedit = {
			follow_delay_textedit = 0,
			follow_maxdist_textedit = 2,
		},
	}

	for k, v in pairs(player_settings) do
		for id, value in pairs(v) do
			if CONFIG_PLAYER[id] == nil then
				CONFIG_PLAYER[id] = value
			end
		end
	end

	local multiexe_settings = {
		switch = {
			is_leader_switch = false,
			follow_quest_switch = false,
		},
		textedit = {
			leader_name = '',
			follow_delay_textedit = 50,
			follow_maxdist_textedit = 2,
		},
	}

	local function SetMultiExe()
		if CONFIG_PLAYER.is_leader_switch then
			CONFIG_MULTIEXE.is_leader_switch = true
			CONFIG_MULTIEXE.follow_quest_switch = CONFIG_PLAYER.follow_quest_switch
			CONFIG_MULTIEXE.leader_name = PLAYER_NAME
			CONFIG_MULTIEXE.follow_delay_textedit = CONFIG_PLAYER.follow_delay_textedit
			CONFIG_MULTIEXE.follow_maxdist_textedit = CONFIG_PLAYER.follow_maxdist_textedit
			local seen = {}
			local current = nil
			for i = #CONFIG_LEADER_PATH, 1, -1 do
				local __t = {}
				for j in CONFIG_LEADER_PATH[i]:gmatch("%d+") do
					table_insert(__t, tonumber(j))
				end
				if seen[__t[1]] or __t[1] > LEADER_IPOS then
					table_remove(CONFIG_LEADER_PATH, i)
				end
				if current == nil then
					current = __t
				end
				seen[__t[1]] = true
			end
			if current and GetDistanceBetween(PLAYER:getPosition(), { x = current[3], y = current[4], z = current[5] }) > 0 then
				while #CONFIG_LEADER_PATH > 0 do
					table_remove(CONFIG_LEADER_PATH, 1)
				end
			end
			if #CONFIG_LEADER_PATH == 0 then
				self:Config_AddFollowAction({ FOLLOW_ACTION_GOTO, PLAYER:getPosition() })
			end
			self:Config_Save(CONFIG_MULTIEXE_ENUM)
		elseif CONFIG_MULTIEXE.leader_name == PLAYER_NAME then
			CONFIG_MULTIEXE.is_leader_switch = false
			self:Config_Save(CONFIG_MULTIEXE_ENUM)
		end
	end

	local function SetMultiExe2()
		self:Config_Read(CONFIG_MULTIEXE_ENUM)
		if CONFIG_PLAYER.is_leader_switch and CONFIG_MULTIEXE.is_leader_switch then
			CONFIG_MULTIEXE.follow_quest_switch = CONFIG_PLAYER.follow_quest_switch
			CONFIG_MULTIEXE.follow_delay_textedit = CONFIG_PLAYER.follow_delay_textedit
			CONFIG_MULTIEXE.follow_maxdist_textedit = CONFIG_PLAYER.follow_maxdist_textedit
			self:Config_Save(CONFIG_MULTIEXE_ENUM)
		end
	end

	for id, value in pairs(player_settings.switch) do
		local child = self:Menu_GetChild(id, self.followBot)
		child:setOn(CONFIG_PLAYER[id])
		if id == 'is_leader_switch' then
			self:Config_Read(CONFIG_MULTIEXE_ENUM)
			if CONFIG_MULTIEXE.is_leader_switch then
				SetMultiExe()
			end
			child.onClick = function(widget)
				self:Config_Read(CONFIG_MULTIEXE_ENUM)
				CONFIG_PLAYER[id] = not CONFIG_PLAYER[id]
				widget:setOn(CONFIG_PLAYER.is_leader_switch)
				self:Config_Save(CONFIG_PLAYER_ENUM)
				SetMultiExe()
			end
		elseif id == 'follow_quest_switch' then
			SetMultiExe2()
			child.onClick = function(widget)
				CONFIG_PLAYER.follow_quest_switch = not CONFIG_PLAYER.follow_quest_switch
				widget:setOn(CONFIG_PLAYER[id])
				self:Config_Save(CONFIG_PLAYER_ENUM)
				SetMultiExe2()
			end
		else
			child.onClick = function(widget)
				CONFIG_PLAYER[id] = not CONFIG_PLAYER[id]
				widget:setOn(CONFIG_PLAYER[id])
				self:Config_Save(CONFIG_PLAYER_ENUM)
			end
		end
	end

	for id, value in pairs(player_settings.textedit) do
		local child = self:Menu_GetChild(id, self.followBot)
		child:setText(CONFIG_PLAYER[id])
		if id == 'follow_delay_textedit' then
			SetMultiExe2()
			child.onTextChange = function(widget, text)
				local num = nil
				if type(CONFIG_PLAYER[id]) == "number" then
					num = tonumber(string.match(text, "%-?%d+"))
				end
				if not num then
					return
				end
				CONFIG_PLAYER[id] = num
				self:Config_Save(CONFIG_PLAYER_ENUM)
				SetMultiExe2()
			end
		elseif id == 'follow_maxdist_textedit' then
			SetMultiExe2()
			child.onTextChange = function(widget, text)
				local num = nil
				if type(CONFIG_PLAYER[id]) == "number" then
					num = tonumber(string.match(text, "%d+"))
				end
				if not num then
					return
				end
				CONFIG_PLAYER[id] = num
				self:Config_Save(CONFIG_PLAYER_ENUM)
				SetMultiExe2()
			end
		else
			child.onTextChange = function(widget, text)
				local num = nil
				if type(CONFIG_PLAYER[id]) == "number" then
					num = tonumber(string.match(text, "%d+"))
				end
				CONFIG_PLAYER[id] = num or text
				self:Config_Save(CONFIG_PLAYER_ENUM)
			end
		end
	end

	self:Config_Save(CONFIG_PLAYER_ENUM)
end

function __settings:Menu_GetChild(id, parent)
	return parent:recursiveGetChildById(id)
end

function __settings:Config_Read(enum_config)
	local enum_settings_info = self.__configs__[enum_config]
	local enum_settings_data = enum_settings_info[2]
	local result = ReadSettings(enum_config)
	for k, v in pairs(result) do
		local __read__ = self.__read__[k]
		if __read__ then
			__read__(v)
		else
			enum_settings_data[k] = v
		end
	end
end

function __settings:Config_Save(enum_config)
	SaveSettings(enum_config)
end

function __settings:Config_AddFollowAction(action)
	LEADER_IPOS = LEADER_IPOS + 1
	local strAction = tostring(LEADER_IPOS) ..
		',' .. action[1] .. ',' .. PosToID(action[2]) .. ',' .. (#action > 2 and action[3] or '0')
	table_insert(CONFIG_LEADER_PATH, strAction)
	if #CONFIG_LEADER_PATH > 20 then
		table_remove(CONFIG_LEADER_PATH, 1)
	end
	self:Config_Save(CONFIG_MULTIEXE_ENUM)
	self.follow_action_timer = now
end

SETTINGS = __settings()

--------------------------------------------------

onPlayerPositionChange(function(newPos, oldPos)
	if now < TELEPORT_ITEM_TIMER + 1000 then
		return
	end
	if CONFIG_PLAYER.is_leader_switch then
		if newPos == nil or oldPos == nil then
			-- first step
			SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_GOTO, newPos or oldPos })
		elseif newPos.z ~= oldPos.z or math_abs(oldPos.x - newPos.x) > 1 or math_abs(oldPos.y - newPos.y) > 1 then
			-- stairs/teleport
			-- print(newPos.z ~= oldPos.z, math_abs(oldPos.x - newPos.x) > 1, math_abs(oldPos.y - newPos.y) > 1)
			SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_TP, oldPos })
			SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_GOTO, newPos })
		else
			SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_GOTO, newPos })
		end
	elseif FOLLOWER_LAST_ACTION and CONFIG_MULTIEXE.is_leader_switch and CONFIG_PLAYER.is_follower_switch then
		if newPos == nil or oldPos == nil then
			local pos = newPos or oldPos
			if GetDistanceBetween(FOLLOWER_LAST_ACTION[2], pos) == 0 then
				FOLLOWER_LAST_ACTION = nil
			end
		elseif newPos.z ~= oldPos.z or math_abs(oldPos.x - newPos.x) > 1 or math_abs(oldPos.y - newPos.y) > 1 then
			if GetDistanceBetween(FOLLOWER_LAST_ACTION[2], oldPos) == 0 then
				FOLLOWER_LAST_ACTION = nil
			end
		else
			if GetDistanceBetween(FOLLOWER_LAST_ACTION[2], newPos) == 0 then
				FOLLOWER_LAST_ACTION = nil
			end
		end
	end
end)

onUse(function(pos, itemId, stackPos, subType)
	if now < TELEPORT_ITEM_TIMER + 1000 then
		return
	end
	if CONFIG_PLAYER.is_leader_switch then
		if itemId == 3232 then
			SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_ITEM, player:getPosition(), itemId })
		elseif pos.x ~= 0xFFFF then
			local tile = g_map.getTile(pos)
			if tile then
				for k, item in pairs(tile:getItems()) do
					local item_id = item and item:getId() or 0
					if itemId == item_id then
						SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_ITEM, pos, itemId })
					end
				end
			end
		end
	elseif FOLLOWER_LAST_ACTION and CONFIG_MULTIEXE.is_leader_switch and CONFIG_PLAYER.is_follower_switch and
		itemId == FOLLOWER_LAST_ACTION[3] and GetDistanceBetween(pos, FOLLOWER_LAST_ACTION[2]) == 0
	then
		FOLLOWER_LAST_ACTION = nil
	end
end)

onUseWith(function(pos, itemId, target, subType)
	if CONFIG_PLAYER.is_leader_switch and itemId == 3003 and target then
		SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_ROPE, target:getPosition(), itemId })
	end
end)

OnSpellCast(function(spell, extra_info)
	if extra_info and spell.name == 'exani hur' then
		SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_EXANIHUR, PLAYER:getPosition(), PLAYER:getDirection() })
	end
end)

OnPathBlock(function(walk_pos)
	if CONFIG_PLAYER.is_leader_switch then
		SETTINGS:Config_AddFollowAction({ FOLLOW_ACTION_BLOCKED_PATH, walk_pos })
		return
	end
	--print('siema block')
	--[[
	if CONFIG_PLAYER.is_leader_switch then
		local WalkButton = WALKER_BOT
		if WalkButton:isOn() then
			if now > SETTINGS.follow_action_timer + 5000 then
				if not CONFIG_MULTIEXE.blocked_path then
					CONFIG_MULTIEXE.blocked_path = true
					SETTINGS:Config_Save(CONFIG_MULTIEXE_ENUM)
				end
			elseif CONFIG_MULTIEXE.blocked_path then
				CONFIG_MULTIEXE.blocked_path = false
				SETTINGS:Config_Save(CONFIG_MULTIEXE_ENUM)
			end
		elseif CONFIG_MULTIEXE.blocked_path then
			CONFIG_MULTIEXE.blocked_path = false
			SETTINGS:Config_Save(CONFIG_MULTIEXE_ENUM)
		end
		return
	end
]]
end)

macro(50, function()
	if not CONFIG_PLAYER.is_follower_switch or now < TELEPORT_ITEM_TIMER + 1000 then
		return
	end

	CurrentPos = PLAYER:getPosition()
	CurrentMana = PLAYER:getMana()
	CurrentMaxMana = PLAYER:getMaxMana()
	CurrentPlayerStates = PLAYER:getStates()
	CurrentIsParalyzed = bit.band(CurrentPlayerStates, 32) > 0
	CurrentHasHaste = bit.band(CurrentPlayerStates, 64) > 0
	CurrentIsInPz = bit.band(CurrentPlayerStates, 16384) > 0
	CurrentIsOnTrainMonks = CurrentPos.y == 2056

	local function FollowInfo()
		if now < MultiExeTimer then return end
		SETTINGS:Config_Read(CONFIG_MULTIEXE_ENUM)
		MultiExeTimer = now + 250
		if CONFIG_MULTIEXE.is_leader_switch then
			for i = #FOLLOWER_PATH, 1, -1 do
				table_remove(FOLLOWER_PATH, i)
			end
			for i = 1, #CONFIG_LEADER_PATH do
				local __t = {}
				for match in CONFIG_LEADER_PATH[i]:gmatch("([^,]+)") do
					table.insert(__t, tonumber(match) or match)
				end
				table_insert(FOLLOWER_PATH, { __t[2], { x = __t[3], y = __t[4], z = __t[5] }, __t[6], __t[1] })
			end
		end
	end
	SafeCall(FollowInfo, "FollowInfo")

	if CONFIG_MULTIEXE.is_leader_switch and #FOLLOWER_PATH > 1 then
		for i = 1, #FOLLOWER_PATH do
			local info = FOLLOWER_PATH[i]
			FOLLOWER_PATH[i][5] = GetDistanceBetween(CurrentPos, info[2])
		end
		SafeCall(NormalFollow, "NormalFollow")
	end
end)
