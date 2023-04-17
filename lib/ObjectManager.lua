setDefaultTab('Main')

local __SETTINGS_PATH__ = PLAYER_DIR .. 'ObjectManager.json'

local SETTINGS = {
    FRIENDS = {},
    ENEMIES = {},
}

local fs_read_table, fs_write_table = fs_read_table, fs_write_table
local pairs, ipairs, table_insert, table_remove = pairs, ipairs, table.insert, table.remove

local function ReadSettings()
    return fs_read_table(__SETTINGS_PATH__)
end

local function SaveSettings()
    fs_write_table(__SETTINGS_PATH__, SETTINGS)
end

if fs_file_exists(__SETTINGS_PATH__) then
    SETTINGS = ReadSettings()
else
    SaveSettings()
end

FRIENDS = SETTINGS.FRIENDS
ENEMIES = SETTINGS.ENEMIES
SPECTATORS = {}

function GetPlayerByName(name)
    for _, spec in ipairs(SPECTATORS) do
        if spec[6] and spec[8] == name then
            return spec[1]
        end
    end
    return nil
end

function IsFriend(_name)
    if FRIENDS[_name] then
        return true
    end
    return false
end

function IsEnemy(_name)
    if ENEMIES[_name] then
        return true
    end
    return false
end

function GetFriends()
    local result = {}
    for _, spec in ipairs(SPECTATORS) do
        if spec[6] and FRIENDS[spec[8]] then
            table_insert(result, spec)
        end
    end
    return result
end

function GetEnemies()
    local result = {}
    for _, spec in ipairs(SPECTATORS) do
        if spec[6] and ENEMIES[spec[8]] then
            table_insert(result, spec)
        end
    end
    return result
end

function GetPlayers()
    local result = {}
    for _, spec in ipairs(SPECTATORS) do
        if spec[6] and spec[1] ~= player then
            table_insert(result, spec)
        end
    end
    return result
end

function GetMonsters(range)
    range = range or 10
    local result = {}
    for _, spec in ipairs(SPECTATORS) do
        if spec[5] and spec[3] <= range then
            table_insert(result, spec)
        end
    end
    return result
end

function GetNewPlayers(range, canShoot)
    range = range or 7
    local result = {}
    local playerPos = player:getPosition()
    for i, spec in ipairs(g_map.getSpectators(playerPos)) do
        if spec and not spec:isDead() and spec:getHealthPercent() > 0 then
            local spec_pos = spec:getPosition()
            if spec_pos and spec_pos.z == playerPos.z then
                local distance = getDistanceBetween(playerPos, spec_pos)
                if distance <= range and (not canShoot or spec:canShoot(distance)) then
                    table_insert(
                        result,
                        { spec, spec_pos, distance, spec:getHealthPercent(), spec:isMonster(), spec:isPlayer(),
                            spec:isNpc(), spec:getName() }
                    )
                end
            end
        end
    end
    return result
end

function FriendsInRange(range)
    local friends_count = 1
    for k, v in pairs(FRIENDS) do
        if v then
            friends_count = friends_count + 1
        end
    end
    local party_leader = nil
    local friends_around_player = 1
    local party_friends_around_player = 0
    if player:isPartyLeader() or player:getShield() == ShieldWhiteYellow then
        party_leader = player
    end
    if player:isPartyMember() then
        party_friends_around_player = party_friends_around_player + 1
    end
    for _, spec in ipairs(GetNewPlayers(range, false)) do
        if spec[6] and FRIENDS[spec[8]] and spec[1] and spec[3] <= range then
            friends_around_player = friends_around_player + 1
            if spec[1]:isPartyMember() then
                party_friends_around_player = party_friends_around_player + 1
            end
            if spec[1]:isPartyLeader() or spec[1]:getShield() == ShieldWhiteYellow then
                party_leader = spec[1]
            end
        end
    end
    return friends_count, friends_around_player, party_friends_around_player, party_leader
end

macro(10, function()
    for i = #SPECTATORS, 1, -1 do
        for j = #SPECTATORS[i], 1, -1 do
            table_remove(SPECTATORS[i], j)
        end
        table_remove(SPECTATORS, i)
    end
    local playerPos = player:getPosition()
    if playerPos == nil then
        return
    end
    for i, spec in ipairs(g_map.getSpectators(playerPos)) do
        if spec and not spec:isDead() and spec:getHealthPercent() > 0 then
            local spec_pos = spec:getPosition()
            if spec_pos and spec_pos.z == playerPos.z then
                local distance = getDistanceBetween(playerPos, spec_pos)
                if distance < 8 and spec:canShoot(distance) then
                    table_insert(
                        SPECTATORS,
                        { spec, spec_pos, distance, spec:getHealthPercent(), spec:isMonster(), spec:isPlayer(),
                            spec:isNpc(), spec:getName() }
                    )
                end
            end
        end
    end
end)

local function AddFriend(_name)
    if FRIENDS[_name] == nil then
        FRIENDS[_name] = true
        SaveSettings()
    end
end

local function AddEnemy(_name)
    if ENEMIES[_name] == nil then
        ENEMIES[_name] = true
        SaveSettings()
    end
end

local function RemoveFriend(_name)
    if FRIENDS[_name] then
        FRIENDS[_name] = nil
        SaveSettings()
    end
end

local function RemoveEnemy(_name)
    if ENEMIES[_name] then
        ENEMIES[_name] = nil
        SaveSettings()
    end
end

local function SetPlayerList(_list, _ui, _add_func, _rem_func)
    local list, ui, add_func, rem_func = _list, _ui, _add_func, _rem_func

    local id = ui:getId()
    local player_list = list

    local ui_list = ui.list
    local ui_name = ui.name
    local ui_add = ui.add

    local function addListItem(item_name)
        local name = item_name
        local label = g_ui.createWidget("ListItem", ui_list)
        label:setId("ListItem" .. name)
        label:setText(name)
        label.remove.onClick = function()
            label:destroy()
            rem_func(name)
        end
        add_func(name)
    end

    for item_name, item_value in pairs(player_list) do
        addListItem(item_name)
    end

    ui_add.onClick = function()
        local names = string.split(ui_name:getText(), ",")
        if #names == 0 then
            print("[PlayerList]: Name is missing!")
            return
        end
        for i = 1, #names do
            local name = names[i]:trim()
            if name:len() == 0 then
                print("[PlayerList]: Name is missing!")
            else
                if player_list[name] == nil then
                    addListItem(name)
                else
                    print("[PlayerList]: Player " .. name .. " is already added!")
                end
                ui_name:setText("")
            end
        end
    end
end

local friends = GetTextListOTML("FRIENDS", "FRIEND LIST", "Add Friend", 120, "#C8FFAB66", 40)
setupUI(friends)
FRIENDS_PANEL = panel:recursiveGetChildById("FRIENDS")
SetPlayerList(FRIENDS, FRIENDS_PANEL, AddFriend, RemoveFriend)
DynamicWidget('button', 'add_visible_players_to_friends', 'Add Visible Players To Friends', function(widget)
    local players = GetPlayers()
    for _, spec in ipairs(players) do
        local name = spec[1]:getName()
        if not IsEnemy(name) and not IsFriend(name) then
            local label = g_ui.createWidget("ListItem", FRIENDS_PANEL.list)
            label:setId("ListItem" .. name)
            label:setText(name)
            label.remove.onClick = function()
                label:destroy()
                RemoveFriend(name)
            end
            AddFriend(name)
        end
    end
end):setTooltip('Exceptions -> player, Friends, Enemies')
UI.Separator()

local enemies = GetTextListOTML("ENEMIES", "ENEMY LIST", "Add Enemy", 120, "#FFC8AB77", 40)
setupUI(enemies)
ENEMIES_PANEL = panel:recursiveGetChildById("ENEMIES")
SetPlayerList(ENEMIES, ENEMIES_PANEL, AddEnemy, RemoveEnemy)
DynamicWidget('button', 'add_visible_players_to_enemies', 'Add Visible Players To Enemies', function(widget)
    local players = GetPlayers()
    for _, spec in ipairs(players) do
        local name = spec[1]:getName()
        if not IsFriend(name) and not IsEnemy(name) then
            local label = g_ui.createWidget("ListItem", ENEMIES_PANEL.list)
            label:setId("ListItem" .. name)
            label:setText(name)
            label.remove.onClick = function()
                label:destroy()
                RemoveEnemy(name)
            end
            AddEnemy(name)
        end
    end
end):setTooltip('Exceptions -> player, Friends, Enemies')
UI.Separator()

-- API:
--  FRIENDS -> table(string)
--  ENEMIES -> table(string)
--  FRIENDS_PANEL -> Widget
--  ENEMIES_PANEL -> Widget
--  SPECTATORS -> table([1]Object(Creature) [2]Position(table) [3]Distance(number) [4]HealthPercent(number) [5]IsMonster(boolean) [6]IsPlayer(boolean) [7]IsNPC(boolean))
--  GetPlayerByName -> function(name) -> return Creature
--  IsFriend -> function(name) -> return boolean
--  IsEnemy -> function(name) -> return boolean
--  GetFriends -> function() -> return table(SPECTATORS)
--  GetEnemies -> function() -> return table(SPECTATORS)
--  GetPlayers -> function() -> return table(SPECTATORS)
