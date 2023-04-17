setDefaultTab('Main')

local IS_PERCENTAGE = true

local math_abs = math.abs
local math_max = math.max
local table_remove = table.remove
local g_game_getPing = g_game.getPing
local g_game_findItemInContainers = g_game.findItemInContainers
local g_game_useInventoryItemWith = g_game.useInventoryItemWith

local NORMAL_PING = 50
local player = g_game.getLocalPlayer()
local PLAYER_NAME = player:getName()

local IS_KNIGHT = VOCATION == 1
local IS_DRUID = VOCATION == 2
local IS_SORCERER = VOCATION == 3
local IS_PALADIN = VOCATION == 4
local IS_MAGE = IS_SORCERER or IS_DRUID

local SuperHighPrio = {
	['Ogre Knifethrower'] = 150,
	['Elf Warlord'] = 100,
	['Paralyzer'] = 50,
}

local PLAYER_SPELLS = {
	UtamoVitaSpell = nil,
	HasteSpell = nil,
	ExetaSpell = nil,
	SelfHealSpell = nil,
	FriendHealSpell = nil,
	Rune = nil,
	SingleTarget = nil,
	SingleMultiTarget = nil,
	MultiTarget = nil,
	SuperMultiTarget = nil,
	BuffSpell = nil,
	ManaRune = nil,
	HealingRune = nil,
	Bless = {},
	PartyHelper = nil,
	KnightHur = nil,
}

local CurrentTarget = nil
local CurrentPrevTarget = nil
local CurrentPos = player:getPosition()
local CurrentMana = player:getMana()
local CurrentMaxMana = player:getMaxMana()
local CurrentManaPercent = CurrentMana * 100 / CurrentMaxMana
local CurrentHealthPercent = player:getHealthPercent()
local CurrentLevel = player:getLevel()
local CurrentAttackingCreature = nil
local CurrentPK = false
local PreviousLevel = player:getLevel()

local CurrentPlayerStates = player:getStates()
local CurrentIsParalyzed = bit.band(CurrentPlayerStates, 32) > 0
local CurrentHasHaste = bit.band(CurrentPlayerStates, 64) > 0
local CurrentIsInPz = bit.band(CurrentPlayerStates, 16384) > 0
local CurrentHasManaShield = bit.band(CurrentPlayerStates, 16) > 0
local CurrentHasPartyBuff = bit.band(CurrentPlayerStates, 4096) > 0
local CurrentIsHasted = CurrentHasHaste and not CurrentIsParalyzed
local CurrentIsOnTrainMonks = false
local CurrentIsInSafePos = CurrentIsOnTrainMonks or CurrentIsInPz

----------------------------
----------------------------
----------------------------

local spell_names = {
	tera = {
		['exori max tera'] = true,
		['exevo gran mas tera'] = true,
	},
	frigo = {
		['exori max frigo'] = true,
		['exevo gran mas frigo'] = true,
	},
	vis = {
		['exori max vis'] = true,
		['exevo gran mas vis'] = true,
	},
	flam = {
		['exori max flam'] = true,
		['exevo gran mas flam'] = true,
	},
}

local vocation_bless = {
	[1] = 'exura',
	[2] = 'mana',
	[3] = 'mage',
	[4] = 'divine',
}

local MenuInst = MENU_CLASS(PLAYER_DIR .. "SpellBot.json", function()
	local ui_info = {
		switch = {},
		textedit = {},
		callbacks = {},
	}

	local otml = [[
Panel
  id: spellsPanel
  height: 180
  layout: verticalBox
]]

	otml = otml .. [[
  BotSwitch
    id: mana_potion_switch
    text: Mana Potion
  BotTextEdit
    id: mana_potion_textedit
    text: 3162
]]

	ui_info.switch.mana_potion_switch = true
	ui_info.textedit.mana_potion_textedit = 3162
	ui_info.callbacks.mana_potion_textedit = function(value) RefreshSpells() end

	otml = otml .. [[
  BotSwitch
    id: attack_switch
    text: Attack
  BotSwitch
    id: attack_spells_switch
    text: Attack Spells
  BotSwitch
    id: auto_follow_switch
    text: Auto Follow
  BotLabel
]]
	ui_info.switch.auto_follow_switch = false
	ui_info.switch.attack_switch = true
	ui_info.switch.attack_spells_switch = true

	if IS_KNIGHT then
		otml = otml .. [[
  BotSwitch
    id: exeta_res
    text: Exeta Res
]]
		ui_info.switch.exeta_res = true
	end

	if IS_DRUID then
		otml = otml .. [[
  BotSwitch
    id: exura_sio
    text: Exura Sio
  BotSwitch
    id: exori_tera
    text: Tera(On)/Frigo(Off)
]]
		ui_info.switch.exura_sio = true
		ui_info.switch.exori_tera = true
		ui_info.callbacks.exori_tera = function(enabled) RefreshSpells() end
	end

	if IS_SORCERER then
		otml = otml .. [[
  BotSwitch
    id: exori_vis
    text: Vis(On)/Flam(Off)
]]
		ui_info.switch.exori_vis = true
		ui_info.callbacks.exori_vis = function(enabled) RefreshSpells() end
	end

	otml = otml .. [[
  BotSwitch
    id: oxygenbless
    text: Gran Bless(On)/Bless(Off)
]]
	ui_info.switch.oxygenbless = false
	ui_info.callbacks.oxygenbless = function(enabled) RefreshSpells() end

	return otml, ui_info
end)
local Settings = MenuInst.settings
SpellBotSettings = Settings
----------------------------
----------------------------
----------------------------

local function GetAllyNames(me)
	local names = {}
	if me then table.insert(names, PLAYER_NAME) end
	for ally, _ in pairs(FRIENDS) do
		table.insert(names, ally)
	end
	return names
end

AddSpell(3162, nil, 'mana_rune', 1)
AddSpell(3171, nil, 'mana_rune', 800)
AddSpell(3160, 'healing', 'healing_rune', 1)

AddSpell('mana waste', 'support', 'manatrain', 1)
AddSpell('exani hur', 'support', 'levitate', 12)
AddSpell('utani hur', 'support', 'haste', 14)

if IS_KNIGHT then
	AddSpell('exori hur', 'attack', 'knight_hur', 28, 1, 5)
	AddSpell('utamo mas sio', 'support', 'party_helper', 800, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		if (dx <= 1 or dy <= 1) then
			return dx + dy <= 5
		end
		return dx + dy <= 6
	end)
	AddSpell('exura bless "' .. PLAYER_NAME .. '"', 'support', 'oxygen_bless', 300, PLAYER_NAME)
	AddSpell('exura gran bless "' .. PLAYER_NAME .. '"', 'support', 'oxygen_bless', 400, PLAYER_NAME)
	AddSpell('exori gran ico', 'attack', 'aa_single_target', 300, 1, 3)
	AddSpell('utamo tempo', 'support', 'aabuff', 200)
	AddSpell('exura gran ico', 'healing', 'selfheal', 200)
	AddSpell('exori ico', 'attack', 'aa_single_target', 16, 1, 1)
	AddSpell('exori mas', 'attack', 'aa_multi_target', 33, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('naya', 'attack', 'aa_multi_target', 600, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('exevo max exori', 'attack', 'aa_multi_target', 700, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('exevo gran mas exori', 'attack', 'aa_multi_target', 150, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('exura ico', 'healing', 'selfheal', 10)
	AddSpell('exura gran ico', 'healing', 'selfheal', 200)
	AddSpell('exeta res', 'support', 'exeta', 20, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 2 + extra
	end)
	if VOCATION_POWER > 2 then--barbarian, ninja
		AddSpell('exeta gran res', 'support', 'exeta', 500, 1, function(p1, p2)
			local dx = math_abs(p1.x - p2.x)
			local dy = math_abs(p1.y - p2.y)
			if (dx <= 1 or dy <= 1) then
				return dx + dy <= 5
			end
			return dx + dy <= 6
		end)
	end
end

if IS_SORCERER then
	AddSpell('utori mas sio', 'support', 'party_helper', 800, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		if (dx <= 1 or dy <= 1) then
			return dx + dy <= 5
		end
		return dx + dy <= 6
	end)
	for _, name in ipairs(GetAllyNames(true)) do
		AddSpell('mage bless "' .. name .. '"', 'support', 'oxygen_bless', 300, name)
		AddSpell('mage gran bless "' .. name .. '"', 'support', 'oxygen_bless', 400, name)
	end
	AddSpell('mazoori', 'attack', 'aa_multi_target', 600, 2, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('exevo max mort', 'attack', 'aa_multi_target', 700, 2, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('exori max vis', 'attack', 'aa_single_target', 500, 1, 5)
	AddSpell('exori max flam', 'attack', 'aa_single_target', 500, 1, 5)
	AddSpell('utito magic', 'support', 'aabuff', 200)
	AddSpell('exevo gran mas vis', 'attack', 'aa_multi_target', 55, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		return dx + dy <= 6
	end)
	AddSpell('exevo gran mas flam', 'attack', 'aa_multi_target', 60, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		return dx + dy <= 6
	end)
	AddSpell('exevo gran mas mort', 'attack', 'aa_multi_target', 150, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		return dx + dy <= 6
	end)
end

if IS_DRUID then
	AddSpell('utura mas sio', 'support', 'party_helper', 800, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		if (dx <= 1 or dy <= 1) then
			return dx + dy <= 5
		end
		return dx + dy <= 6
	end)
	AddSpell('exevo max frigo', 'attack', 'aa_multi_target', 700, 2, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	for _, name in ipairs(GetAllyNames(true)) do
		AddSpell('mana bless "' .. name .. '"', 'support', 'oxygen_bless', 300, name)
		AddSpell('mana gran bless "' .. name .. '"', 'support', 'oxygen_bless', 400, name)
	end
	AddSpell('rattle', 'attack', 'aa_multi_target', 600, 2, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('utito magic', 'support', 'aabuff', 200)
	AddSpell('exori max tera', 'attack', 'aa_single_target', 500, 1, 5)
	AddSpell('exori max frigo', 'attack', 'aa_single_target', 500, 1, 5)
	AddSpell('exevo gran mas frigo', 'attack', 'aa_multi_target', 60, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		return dx + dy <= 6
	end)
	AddSpell('exevo gran mas tera', 'attack', 'aa_multi_target', 55, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		return dx + dy <= 6
	end)
	AddSpell('exura sio', 'healing', 'friendheal', 18)
end

if IS_PALADIN then
	AddSpell('exevo max san', 'attack', 'aa_multi_target', 700, 2, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('utito mas sio', 'support', 'party_helper', 800, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		if (dx <= 1 or dy <= 1) then
			return dx + dy <= 5
		end
		return dx + dy <= 6
	end)
	for _, name in ipairs(GetAllyNames(true)) do
		AddSpell('divine bless "' .. name .. '"', 'support', 'oxygen_bless', 300, name)
		AddSpell('divine gran bless "' .. name .. '"', 'support', 'oxygen_bless', 400, name)
	end
	AddSpell('utito tempo san', 'support', 'aabuff', 200)
	AddSpell('exori con', 'attack', 'aa_single_target', 23, 1, 7)
	AddSpell('exori gran con', 'attack', 'aa_single_target', 300, 1, 7)
	AddSpell('exori max con', 'attack', 'aa_single_target', 800, 1, 7)
	AddSpell('exevo mas san', 'attack', 'aa_multi_target', 50, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('exevo gran mas san', 'attack', 'aa_multi_target', 150, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('zoltri', 'attack', 'aa_multi_target', 600, 1, function(p1, p2)
		local dx = math_abs(p1.x - p2.x)
		local dy = math_abs(p1.y - p2.y)
		local extra = (dx == 0 or dy == 0) and 0 or 1
		return dx + dy <= 3 + extra
	end)
	AddSpell('exura san', 'healing', 'selfheal', 35)
	AddSpell('exura gran san', 'healing', 'selfheal', 200)
end

if IS_MAGE then
	AddSpell('exori mort', 'attack', 'aa_single_target', 16, 1, 5)
	AddSpell('exura vita', 'healing', 'selfheal', 30)
	AddSpell('utani gran hur', 'support', 'haste', 20)
end

if not IS_MAGE then
	AddSpell('utani mas hur', 'support', 'haste', 100)
end

if not IS_KNIGHT then
	AddSpell('exura', 'healing', 'selfheal', 9)
	AddSpell('exura gran', 'healing', 'selfheal', 20)
	AddSpell('utamo vita', 'support', 'manashield', 14)
end

----------------------------
----------------------------
----------------------------

function RefreshSpells()
	PLAYER_SPELLS.Bless = {}
	for k, v in pairs(PLAYER_SPELLS) do
		if k ~= 'Bless' then
			PLAYER_SPELLS[k] = nil
		end
	end
	local HasteSpellLvl, ExetaSpellLvl = 0, 0
	local SelfHealSpellLvl, FriendHealSpellLvl = 0, 0
	local RuneLvl, SingleTargetLvl, MultiTargetLvl, SuperMultiTargetLvl = 0, 0, 0, 0
	local myLevel = player:getLevel()
	for k, spell in pairs(SPELL_DATA) do
		if myLevel >= spell.level then
			if spell.group_type == 'attack' then
				local valid = true
				if spell.name then
					if IS_DRUID then
						if Settings.exori_tera and spell_names.frigo[spell.name] then
							valid = false
							--print(spell.name)
						elseif not Settings.exori_tera and spell_names.tera[spell.name] then
							valid = false
							--print(spell.name)
						end
					elseif IS_SORCERER then
						if Settings.exori_vis and spell_names.flam[spell.name] then
							valid = false
							--print(spell.name)
						elseif not Settings.exori_vis and spell_names.vis[spell.name] then
							valid = false
							--print(spell.name)
						end
					end
				end
				if spell.spell_type == 'knight_hur' then
					PLAYER_SPELLS.KnightHur = spell
				elseif spell.spell_type == 'aarune' then
					if spell.level > RuneLvl and g_game_findItemInContainers(spell.id) then
						RuneLvl = spell.level
						PLAYER_SPELLS.Rune = spell
					end
				elseif spell.spell_type == 'aa_single_target' then
					if valid and spell.level > SingleTargetLvl then
						SingleTargetLvl = spell.level
						PLAYER_SPELLS.SingleTarget = spell
					end
				elseif spell.spell_type == 'aa_multi_target' then
					if valid and spell.level > MultiTargetLvl then
						MultiTargetLvl = spell.level
						PLAYER_SPELLS.MultiTarget = spell
					end
				elseif spell.spell_type == 'aa_super_multi_target' then
					if spell.level > SuperMultiTargetLvl then
						SuperMultiTargetLvl = spell.level
						PLAYER_SPELLS.SuperMultiTarget = spell
					end
				end
			elseif spell.spell_type == 'party_helper' then
				PLAYER_SPELLS.PartyHelper = spell
			elseif spell.spell_type == 'oxygen_bless' then
				local valid = true
				if spell.name:find(' gran bless') then
					if not Settings.oxygenbless then
						valid = false
					end
				elseif Settings.oxygenbless then
					valid = false
				end
				if valid then
					print('BLESS>>>', spell.name)
					table.insert(PLAYER_SPELLS.Bless, spell)
				end
				--[[local gran = vocation_bless[VOCATION] .. ' gran bless'
				if Settings.oxygenbless then
				else
				end
				local extra = Settings.oxygenbless and ' gran' or ''
				spell.name = vocation_bless[VOCATION] .. extra .. ' bless "' .. spell.friend_name .. '"'
				--print('OXYGEN>>>>>>>>>>',spell.name)
				table.insert(PLAYER_SPELLS.Bless, spell)]]
			elseif spell.spell_type == 'aabuff' then
				PLAYER_SPELLS.BuffSpell = spell
			elseif spell.spell_type == 'haste' then
				if spell.level > HasteSpellLvl then
					HasteSpellLvl = spell.level
					PLAYER_SPELLS.HasteSpell = spell
				end
			elseif spell.spell_type == 'exeta' then
				if spell.level > ExetaSpellLvl then
					ExetaSpellLvl = spell.level
					PLAYER_SPELLS.ExetaSpell = spell
				end
			elseif spell.spell_type == 'selfheal' then
				if spell.level > SelfHealSpellLvl then
					SelfHealSpellLvl = spell.level
					PLAYER_SPELLS.SelfHealSpell = spell
				end
			elseif spell.spell_type == 'friendheal' then
				if spell.level > FriendHealSpellLvl then
					FriendHealSpellLvl = spell.level
					PLAYER_SPELLS.FriendHealSpell = spell
				end
			elseif spell.spell_type == "manashield" then
				PLAYER_SPELLS.UtamoVitaSpell = spell
			elseif spell.spell_type == 'mana_rune' then
				if Settings.mana_potion_textedit == spell.id then
					PLAYER_SPELLS.ManaRune = spell
					print('mana rune added:)')
				end
			elseif spell.spell_type == 'healing_rune' then
				PLAYER_SPELLS.HealingRune = spell
				--print('healing rune added:)')
			end
		end
	end
	if IS_SORCERER then
		if myLevel >= 200 then
			--use exori ko
			PLAYER_SPELLS.MultiTarget.amount = 2
		else
			PLAYER_SPELLS.MultiTarget.amount = 1
		end
	end
	if IS_PALADIN then
		if myLevel >= 300 then
			--use exori gran con
			PLAYER_SPELLS.MultiTarget.amount = 2
		else
			PLAYER_SPELLS.MultiTarget.amount = 1
		end
	end
	if IS_KNIGHT then
		PLAYER_SPELLS.MultiTarget.amount = myLevel >= 300 and 2 or 1 --use exori gran ico
	end
	if IS_DRUID then
		if myLevel >= 500 then
			--use exori max frigo
			PLAYER_SPELLS.MultiTarget.amount = 2
		else
			PLAYER_SPELLS.MultiTarget.amount = 1
		end
	end
end

local function GetDistanceBetween(p1, p2)
	if not p2 then
		print("SpellBot.lua GetDistanceBetween p2 nil")
	end
	if p1.z ~= p2.z then
		return 1000
	end
	return math_max(math_abs(p1.x - p2.x), math_abs(p1.y - p2.y))
end

local function GetClosestTarget(name)
	local closest = nil
	local best_distance = 1000
	for _, spec in ipairs(SPECTATORS) do
		if spec[5] and spec[1]:getName():lower():find(name) and GetDistanceBetween(CurrentPos, spec[2]) < best_distance then
			best_distance = GetDistanceBetween(CurrentPos, spec[2])
			closest = spec[1]
		end
	end
	return closest
end

local function CheckMobsAround(mob)
	local mobs_around = 0
	for _, spec in ipairs(SPECTATORS) do
		if spec[5] and GetDistanceBetween(mob[2], spec[2]) <= 1 then
			mobs_around = mobs_around + 1
		end
	end
	return mobs_around
end

local function IsAttackingTrainingMonk()
	local monk = g_game.getAttackingCreature()
	if monk and monk:getName():find("Training Monk") then
		return true
	end
	return false
end

local function RefreshGameData()
	CurrentPos = player:getPosition()
	CurrentMana = player:getMana()
	CurrentMaxMana = player:getMaxMana()
	CurrentLevel = player:getLevel()

	if CurrentLevel ~= PreviousLevel then
		RefreshSpells()
		print("[ON LEVEL CHANGE]", CurrentLevel, PreviousLevel)
		PreviousLevel = CurrentLevel
	end

	if IS_PERCENTAGE then
		CurrentManaPercent = CurrentMana
		CurrentHealthPercent = player:getHealth()
	else
		CurrentManaPercent = CurrentMana * 100 / CurrentMaxMana
		CurrentHealthPercent = player:getHealthPercent()
	end

	CurrentPlayerStates = player:getStates()
	CurrentIsParalyzed = bit.band(CurrentPlayerStates, 32) > 0
	CurrentHasHaste = bit.band(CurrentPlayerStates, 64) > 0
	CurrentIsInPz = bit.band(CurrentPlayerStates, 16384) > 0
	CurrentHasManaShield = bit.band(CurrentPlayerStates, 16) > 0
	CurrentHasPartyBuff = bit.band(CurrentPlayerStates, 4096) > 0
	CurrentIsHasted = CurrentHasHaste and not CurrentIsParalyzed
	CurrentIsOnTrainMonks = IsAttackingTrainingMonk()
	CurrentIsInSafePos = CurrentIsOnTrainMonks or CurrentIsInPz
	CurrentPK = false
	CurrentAttackingCreature = g_game.isAttacking() and g_game.getAttackingCreature() or nil
	if CurrentAttackingCreature then
		if CurrentAttackingCreature:isPlayer() then
			CurrentPK = true
		end
		if CurrentAttackingCreature:isDead() or CurrentAttackingCreature:getHealthPercent() == 0 then
			CurrentAttackingCreature = nil
		end
	end
	if CurrentAttackingCreature == nil then
		CurrentPrevTarget = nil
	end

	CurrentTarget = nil
	if not CurrentPK then
		local function FindTarget(max_range)
			local bestPriority = 0
			for _, spec in ipairs(SPECTATORS) do
				if spec[5] and spec[3] <= max_range then
					local priority = SuperHighPrio[spec[8]] or 0
					priority = priority + (8 - spec[3])
					--priority = priority + CheckMobsAround(spec)
					priority = priority + (5 - spec[4] * 0.05)
					if priority > bestPriority then
						CurrentTarget = spec[1]
						bestPriority = priority
					end
				end
			end
		end
		local single_spell = PLAYER_SPELLS.SingleTarget
		if single_spell then
			FindTarget(single_spell.range < 7 and single_spell.range or 6)
		end
		if CurrentTarget == nil then
			FindTarget(7)
		end
	end
	if CurrentTarget and CurrentTarget == CurrentAttackingCreature then
		CurrentTarget = nil
	end
end

local function Items()
	local manaPercent = 95
	local ManaRune = PLAYER_SPELLS.ManaRune
	if Settings.mana_potion_switch and CurrentManaPercent < manaPercent and ManaRune and ManaRune:IsReady() then
		ManaRune:Cast(player)
		-- print('using mana potion')
		return
	end
end

local function HealingSpells()
	if IsSpellGroupOnCd('healing') then
		return
	end
	local SelfHealSpell = PLAYER_SPELLS.SelfHealSpell
	if CurrentHealthPercent < 100 and SelfHealSpell and SelfHealSpell:IsReady() then
		-- print('cast self heal')
		SelfHealSpell:Cast()
		return
	end
	if IS_DRUID and Settings.exura_sio then
		local FriendHealSpell = PLAYER_SPELLS.FriendHealSpell
		if FriendHealSpell and FriendHealSpell:IsReady() then
			for _, spec in ipairs(SPECTATORS) do
				if spec[6] and spec[4] < 95 then
					local ally = spec[1]:getName()
					if IsFriend(ally) then
						-- print('cast friend heal')
						FriendHealSpell:Cast(' "' .. ally)
						return
					end
				end
			end
		end
	end
end

local function SupportSpells()
	if IsSpellGroupOnCd('support') then
		return
	end
	local UtamoVitaSpell = PLAYER_SPELLS.UtamoVitaSpell
	if UtamoVitaSpell and not CurrentHasManaShield and UtamoVitaSpell:IsReady() then
		UtamoVitaSpell:Cast()
		return
	end
	local PartyHelper = PLAYER_SPELLS.PartyHelper
	if PartyHelper and PartyHelper:IsReady() then
		PartyHelper:Cast()
		return
	end
	for _, bless in ipairs(PLAYER_SPELLS.Bless) do
		if bless:IsReady() then
			bless:Cast()
		end
	end
	local HasteSpell = PLAYER_SPELLS.HasteSpell
	if not CurrentIsHasted and HasteSpell and (not CurrentIsInSafePos or not player:canWalk()) and HasteSpell:IsReady() then
		-- print('cast haste spell')
		HasteSpell:Cast()
		return
	end
	local ManaWaste = SPELL_DATA['mana waste']
	if CurrentIsInSafePos and CurrentManaPercent >= 95 and ManaWaste:IsReady() then
		-- print('cast utevo mana')
		ManaWaste:Cast()
		return
	end
	--if not CurrentHasPartyBuff then
	local BuffSpell = PLAYER_SPELLS.BuffSpell
	if BuffSpell and BuffSpell:IsReady() then
		BuffSpell:Cast()
		-- print('BUFF')
		return
	end
	--end
	if IS_KNIGHT and Settings.exeta_res and not CurrentIsInSafePos then
		local ExetaSpell = PLAYER_SPELLS.ExetaSpell
		if ExetaSpell and ExetaSpell:IsReady() then
			ExetaSpell:Cast()
			-- print('BUFF')
			return
		end
	end
end

local function Attack()
	if CurrentTarget and CurrentTarget ~= CurrentPrevTarget then
		g_game.attack(CurrentTarget)
		CurrentPrevTarget = CurrentTarget
	end
end

local function AttackSpells()
	if CurrentIsInSafePos then
		if CurrentIsOnTrainMonks then
			if not CurrentHasPartyBuff then
				local BuffSpell = PLAYER_SPELLS.BuffSpell
				if BuffSpell and BuffSpell:IsReady() then
					BuffSpell:Cast()
					-- print('BUFF')
					return
				end
			end
			if CurrentManaPercent > 70 then
				return
			end
			local SuperMultiTarget = PLAYER_SPELLS.SuperMultiTarget
			if SuperMultiTarget then
				local old_amount = SuperMultiTarget.amount
				SuperMultiTarget.amount = 1
				if SuperMultiTarget:IsReady() then
					SuperMultiTarget:Cast()
					SuperMultiTarget.amount = old_amount
					return
				end
				SuperMultiTarget.amount = old_amount
			end
			local MultiTarget = PLAYER_SPELLS.MultiTarget
			if MultiTarget then
				local old_amount = MultiTarget.amount
				MultiTarget.amount = 1
				if MultiTarget:IsReady() then
					MultiTarget:Cast()
					MultiTarget.amount = old_amount
					return
				end
				MultiTarget.amount = old_amount
			end
		end
		return
	end
	if Settings.attack_switch then
		Attack()
	end
	if not Settings.attack_spells_switch then
		return
	end

	if IsSpellGroupOnCd('attack') then
		return
	end

	-- attacking player
	if CurrentPK then
		return
	end

	if IS_KNIGHT or CurrentAttackingCreature == nil or SuperHighPrio[CurrentAttackingCreature:getName()] == nil then
		local SuperMultiTarget = PLAYER_SPELLS.SuperMultiTarget
		if SuperMultiTarget and SuperMultiTarget:IsReady() then
			-- print('SUPER MULTI')
			SuperMultiTarget:Cast()
			-- say(SuperMultiTarget.name)
			return
		end

		local MultiTarget = PLAYER_SPELLS.MultiTarget
		if MultiTarget and MultiTarget:IsReady() then
			-- print('MULTI')
			MultiTarget:Cast()
			-- say(MultiTarget.name)
			return
		end
	end

	local SingleTarget = PLAYER_SPELLS.SingleTarget
	if SingleTarget and SingleTarget:IsReady() then
		-- print('SINGLE')
		SingleTarget:Cast()
		-- say(SingleTarget.name)
	end

	if IS_KNIGHT then
		local KnightHur = PLAYER_SPELLS.KnightHur
		if KnightHur and KnightHur:IsReady() then
			-- print('SINGLE')
			KnightHur:Cast()
			-- say(SingleTarget.name)
		end
	end
end

RefreshSpells()

macro(20, function()
	if now < TELEPORT_ITEM_TIMER + 1000 then
		return
	end
	SafeCall(RefreshGameData, "RefreshGameData")
	SafeCall(Items, "Items")
	SafeCall(HealingSpells, "HealingSpells")
	SafeCall(AttackSpells, "AttackSpells")
	SafeCall(SupportSpells, "SupportSpells")
	if CurrentIsOnTrainMonks then
		if g_game.isAttacking() then
			if CurrentAttackingCreature and CurrentAttackingCreature:getName() ~= 'Training Monk' then
				g_game.attack(GetClosestTarget('training monk'))
			end
		else
			g_game.attack(GetClosestTarget('training monk'))
		end
	end
end)
