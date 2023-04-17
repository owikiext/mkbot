local PLAYER_NAME = player:getName()

local MANA_POTION_SERVER_TIMER = 0

local GROUP_SPELL_LOCAL_TIMER = { support = 0, attack = 0, healing = 0 }
local GROUP_SPELL_SERVER_TIMER = { support = 0, attack = 0, healing = 0 }

local g_game_findItemInContainers = g_game.findItemInContainers
local g_game_useInventoryItemWith = g_game.useInventoryItemWith

local onSpellCastCb = {}
function OnSpellCast(func)
    table.insert(onSpellCastCb, func)
end

function IsSpellGroupOnCd(group_type)
	if now < GROUP_SPELL_LOCAL_TIMER[group_type] + 50 then
		return true
	end
	if now < GROUP_SPELL_SERVER_TIMER[group_type] + 1000 then
		return true
	end
	return false
end

SPELL_DATA = {}
SPELL_CLASS = Class()

function SPELL_CLASS:__init(name, group_type, spell_type, level, amount, isInArea)
    self.valid = true
    if type(name) == 'number' then
        self.id = name
        self.is_mana_rune = self.id ~= 3160
    else
        self.name = name
    end
    self.group_type = group_type
    self.local_timer = 0
    self.server_timer = 0
    if isInArea then
        if type(isInArea) == 'number' then
            self.range = isInArea
        else
            self.isInArea = isInArea
        end
    end
    self.is_party_helper = spell_type == 'party_helper'
    self.is_attack_rune = spell_type == 'aarune'
    self.is_oxygenbless = spell_type == 'oxygen_bless'
    self.spell_type = spell_type
    self.level = level
    if self.is_oxygenbless then
        self.friend_name = amount
    elseif self.is_party_helper then
        self.isInArea = amount
    else
        self.amount = amount
    end
    self.duration = 1000
    self.group_duration = 1000
    if self.spell_type == 'aabuff' or self.is_oxygenbless then
        self.duration = 60000 - 1000--1 sec extra
    end
    if self.is_party_helper then
        self.duration = 120000 - 5000--5 sec extra
    end
end

function SPELL_CLASS:IsReady()
    if not self.valid or now < self.local_timer + 50 then
        return false
    end
    if self.id then
        if now > self.local_timer + self.duration then
            if self.amount then
                return self:MobsInRange()
            end
            return true
        end
        if not self.is_mana_rune and now < self.local_timer + 100 then
            return false
        end
    end
    if now < self.server_timer + self.duration then
        return false
    end
    if self.is_mana_rune then
        if now < MANA_POTION_SERVER_TIMER + self.duration then
            return false
        end
    end
    if not self.is_mana_rune then
        if now < GROUP_SPELL_LOCAL_TIMER[self.group_type] + 50 then
            return false
        end
        if now < GROUP_SPELL_SERVER_TIMER[self.group_type] + self.group_duration then
            return false
        end
    end
    if self.is_oxygenbless then
        return self:FriendInRange()
    end
    if self.amount then
        return self:MobsInRange()
    end
    if self.is_party_helper then
        return self:FriendsInRange(true)
    end
    return true
end

function SPELL_CLASS:FriendInRange()
    if self.friend_name == PLAYER_NAME then
        return true
    end
    for _, spec in ipairs(SPECTATORS) do
        if spec[6] and self.friend_name == spec[8] then
            if spec[1] and spec[3] < 9 and spec[1]:canShoot(spec[3]) then
                return true
            end
            return false
        end
    end
    return false
end

function SPELL_CLASS:FriendsInRange(party)
    local friends_count = 1
    for k, v in pairs(FRIENDS) do
        if v then
            friends_count = friends_count + 1
        end
    end
    local friends_around_player = 0
    if not party or player:isPartyMember() then
        friends_around_player = friends_around_player + 1
    end
    local playerPos = player:getPosition()
    for _, spec in ipairs(SPECTATORS) do
        if spec[6] and FRIENDS[spec[8]] then
            if not spec[2] then
                print('Spell.lua SPELL_CLASS:FriendsInRange(party)')
            end
            if spec[1] and spec[3] < 9 and spec[1]:canShoot(spec[3]) and self.isInArea(playerPos, spec[2]) then
                if not party or spec[1]:isPartyMember() then
                    friends_around_player = friends_around_player + 1
                end
            end
        end
    end
    return friends_around_player == friends_count
end

function SPELL_CLASS:MobsInRange()
    local ppos = player:getPosition()
    if self.range then
        local currentTarget = g_game.getAttackingCreature()
        if currentTarget and getDistanceBetween(ppos, currentTarget:getPosition()) <= self.range and currentTarget:canShoot(self.range) then
            return true
        end
        return false
    end
    if self.is_attack_rune then
        local function RuneMobsInRange(_spec, _pos)
            local result = _spec == player and 0 or 1
            for _, spec in ipairs(SPECTATORS) do
                if not spec[2] then
                    print('Spell.lua SPELL_CLASS:MobsInRange() 1')
                end
                local isMob = spec[5]
                if isMob and _spec ~= spec[1] and self.isInArea(_pos, spec[2]) then
                    result = result + 1
                end
            end
            return result
        end
        local best_mob = nil
        local best_count = 0
        for _, spec in ipairs(SPECTATORS) do
            local isMob = spec[5]
            local _spec = spec[1]
            if isMob or _spec == player then
                local pos = spec[2]
                local dx = math.abs(ppos.x - pos.x)
                local dy = math.abs(ppos.y - pos.y)
                if dx <= 7 and dy <= 5 then
                    local current_count = RuneMobsInRange(_spec, pos)
                    if current_count > best_count then
                        best_mob = _spec
                        best_count = current_count
                    end
                end
            end
        end
        if best_mob and best_count >= self.amount then
            local tile = best_mob:getTile()
            if tile then
                return tile:getTopMultiUseThing() or tile:getTopUseThing() or tile:getTopCreature()
            end
        end
        return false
    end
    local current_amount = 0
    for _, spec in ipairs(SPECTATORS) do
        if not spec[2] then
            print('Spell.lua SPELL_CLASS:MobsInRange() 2')
        end
        if spec[5] and self.isInArea(ppos, spec[2]) then
            current_amount = current_amount + 1
        end
    end
    return current_amount >= self.amount
end

function SPELL_CLASS:Cast(extra_info)
    local timer = now
    if self.id then
        if g_game_findItemInContainers(self.id) then
            g_game_useInventoryItemWith(self.id, extra_info or player)
            if not self.is_mana_rune then
                GROUP_SPELL_LOCAL_TIMER[self.group_type] = timer
            end
        else
            timer = timer + 500
        end
    else
        --print(self.name .. (extra_info or ''))
        say(self.name .. (extra_info or ''))
    end
    self.local_timer = timer
end

function SPELL_CLASS:OnServerMessage()
    self.server_timer = now - g_game.getPing() * 0.5
    if not self.is_mana_rune then
        GROUP_SPELL_SERVER_TIMER[self.group_type] = self.server_timer
    end
end

function AddSpell(name, group_type, spell_type, level, amount, isInArea)
    SPELL_DATA[name] = SPELL_CLASS(name, group_type, spell_type, level, amount, isInArea)
end

local function extractWord(str, char)
    local pattern = "%" .. char .. "([%w]+)"
    return str:match(pattern)
end

onTalk(function(name, level, mode, text, channelId, pos)
    if mode == 44 and name == PLAYER_NAME then
        local spell
        local extra_info
        if text:find('exura sio') then
            spell = SPELL_DATA['exura sio']
            extra_info = extractWord(text, '"') or extractWord(text, "'")
        elseif text:find('exani hur') then
            spell = SPELL_DATA['exani hur']
            extra_info = extractWord(text, '"') or extractWord(text, "'")
        else
            spell = SPELL_DATA[text]
        end
        if not spell then return end
        spell:OnServerMessage()
        for i = 1, #onSpellCastCb do
            onSpellCastCb[i](spell, extra_info)
        end
    end
end)

onAnimatedText(function(thing, text)
    if #text < 11 and text:find('MANA') and thing and getDistanceBetween(thing:getPosition(), player:getPosition()) == 0 then
        --print(now - MANA_POTION_SERVER_TIMER)
        MANA_POTION_SERVER_TIMER = now - g_game.getPing() * 0.5
    end
end)
