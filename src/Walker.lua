setDefaultTab('Walker')

local __SETTINGS_PATH__ = PLAYER_DIR .. 'Walker.json'
local __SETTINGS_WPTS_PATH__ = WPTS_DIR

local SETTINGS = {
    FILE = "filename.json",
    WAYPOINTS = {},
    LURE_MIN = 1,
    LURE_MAX = 3,
    LURE_DELAY = 300,
    LOAD_FILE = ""
}

local FILES = {}
local WAYPOINTS = SETTINGS.WAYPOINTS
local CURRENT_INDEX = 0
local CURRENT_WAYPOINT
local LAST_INDEX = 0
local IS_DUNGEON = false
local waypointList

local WAITING_POS = nil
local WAITING_TIMEOUT = 0

local onPathBlockCb = {}
function OnPathBlock(func)
    table.insert(onPathBlockCb, func)
end

local GetPosFromDir = GetPosFromDir

local fs_read_table, fs_write_table = fs_read_table, fs_write_table
local pairs, ipairs, table_insert, table_remove = pairs, ipairs, table.insert, table.remove

local function ReadSettings(file)
    return fs_read_table(file and (__SETTINGS_WPTS_PATH__ .. file) or (__SETTINGS_PATH__))
end

local function SaveSettings(file)
    fs_write_table(file and (__SETTINGS_WPTS_PATH__ .. file) or (__SETTINGS_PATH__),
        file and SETTINGS.WAYPOINTS or SETTINGS)
end

if fs_file_exists(__SETTINGS_PATH__) then
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
    CompareSettings(ReadSettings(), SETTINGS)
    SaveSettings()
else
    SaveSettings()
end

local function GetSpectators(range)
    local monsters, players = {}, {}
    for _, spec in ipairs(SPECTATORS) do
        if spec[3] <= range then
            if spec[5] then
                table.insert(monsters, spec[1])
            elseif spec[6] then
                table.insert(players, spec[1])
            end
        end
    end
    return monsters, players
end

local function SetLureUI()
    local lure = setupUI(GetLurePanelOTML())
    local minTextEdit = lure:recursiveGetChildById('minTextEdit')
    local maxTextEdit = lure:recursiveGetChildById('maxTextEdit')
    local delayTextEdit = lure:recursiveGetChildById('delayTextEdit')
    minTextEdit:setText(tostring(SETTINGS.LURE_MIN))
    maxTextEdit:setText(tostring(SETTINGS.LURE_MAX))
    delayTextEdit:setText(tostring(SETTINGS.LURE_DELAY))
    minTextEdit.onTextChange = function(widget, text)
        local value = tonumber(string.match(text, "%d+"))
        if value then
            SETTINGS.LURE_MIN = value
            SaveSettings()
        end
    end
    maxTextEdit.onTextChange = function(widget, text)
        local value = tonumber(string.match(text, "%d+"))
        if value then
            SETTINGS.LURE_MAX = value
            SaveSettings()
        end
    end
    delayTextEdit.onTextChange = function(widget, text)
        local value = tonumber(string.match(text, "%d+"))
        if value then
            SETTINGS.LURE_DELAY = value
            SaveSettings()
        end
    end
end

local function SetWalkerUI()
    local walker = setupUI(GetWalkerListOTML("walker_waypoints", "WAYPOINTS", 240, "#C8FFAB66", 40))
    waypointList = walker:recursiveGetChildById('list')
    local file_name = walker:recursiveGetChildById('file_name')
    local save = walker:recursiveGetChildById('save')
    local add_wpt = walker:recursiveGetChildById('add_wpt')
    local add_dir = walker:recursiveGetChildById('add_dir')
    local files = setupUI(GetFileListOTML('walker_files', "FILES", 240, "#C8FFAB66", 40))
    local load = files:recursiveGetChildById('load')
    local fileList = files:recursiveGetChildById('list')
    local rootWidget = g_ui.getRootWidget()
    local function RefreshWaypoints()
        for i = #WAYPOINTS, 1, -1 do
            table.remove(WAYPOINTS, i)
        end
        --[[for i = 1, waypointList:getChildCount() do
            local child = waypointList:getChildByIndex(i)]]
        for index, child in ipairs(waypointList:getChildren()) do
            if child then
                local args = {}
                for part in child:getText():gmatch("[^:]+") do
                    table.insert(args, part)
                end
                local text = args[2]
                if text[1] == '"' then
                    --function
                else
                    local x, y, z = text:match("(%d+),(%d+),(%d+)$")
                    table.insert(WAYPOINTS, { x = tonumber(x), y = tonumber(y), z = tonumber(z) })
                end
            end
        end
    end
    local function AddWaypoint(pos)
        pos = pos or player:getPosition()
        local label = g_ui.createWidget("ListItem", waypointList)
        label:setText(tostring(#WAYPOINTS + 1) .. ': ' .. pos.x .. "," .. pos.y .. "," .. pos.z)
        label.remove.onClick = function()
            local last_selected = CURRENT_INDEX
            label:destroy()
            RefreshWaypoints()
            local list_count = waypointList:getChildCount()
            if last_selected > list_count then
                last_selected = list_count
            end
            for index, child in ipairs(waypointList:getChildren()) do
                if last_selected == index then
                    child:setColor('green')
                    waypointList:focusChild(child)
                    break
                end
            end
        end
        label.onMouseRelease = function(widget, mousePos, mouseButton)
            if mouseButton == 1 then
                local items = rootWidget:recursiveGetChildrenByPos(mousePos)
                local isLabel = false
                local isRemoveButton = false
                for _, item in ipairs(items) do
                    if item == label then
                        isLabel = true
                    end
                    if item:getId() == 'remove' then
                        isRemoveButton = true
                        break
                    end
                end
                if isLabel and not isRemoveButton then
                    local index = waypointList:getChildIndex(label)
                    for i, child in ipairs(waypointList:getChildren()) do
                        if child then
                            child:setColor('white')
                        end
                    end
                    label:setColor('green')
                    if CURRENT_INDEX ~= index then
                        CURRENT_INDEX = index
                        SaveSettings()
                    end
                end
            end
        end
        assert(type(pos.x) == 'number', 'ERROR SetWalkerUI type(pos.x) ~= number but -> ' .. type(pos.x))
        assert(type(pos.y) == 'number', 'ERROR SetWalkerUI type(pos.y) ~= number but -> ' .. type(pos.y))
        assert(type(pos.z) == 'number', 'ERROR SetWalkerUI type(pos.z) ~= number but -> ' .. type(pos.z))
        table.insert(WAYPOINTS, pos)
    end
    local function GetPosFromListItemText(text)
        local x, y, z = text:match("(%d+),(%d+),(%d+)$")
        return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
    end
    local function GetDirectionPos(pos, dir)
        pos = pos or player:getPosition()
        dir = dir or player:getDirection()
        if dir == North then
            pos.y = pos.y - 1
        elseif dir == South then
            pos.y = pos.y + 1
        elseif dir == West then
            pos.x = pos.x - 1
        else
            pos.x = pos.x + 1
        end
        return pos
    end
    local function AddFileListItem(file)
        table.insert(FILES, file)
        local label = g_ui.createWidget("NormalListItem", fileList)
        label:setText(file)
        return label
    end
    local function RefreshFileList()
        for i = #FILES, 1, -1 do
            table.remove(FILES, i)
        end
        while fileList:getChildCount() > 0 do
            local child = fileList:getLastChild()
            fileList:destroyChildren(child)
        end
        for _, file in ipairs(g_resources.listDirectoryFiles(WPTS_DIR, false, false)) do
            local label = AddFileListItem(file)
            if file == SETTINGS.LOAD_FILE then
                fileList:focusChild(label)
            end
        end
    end
    local function LoadNewWaypoints(wpts)
        for i = #WAYPOINTS, 1, -1 do
            table.remove(WAYPOINTS, i)
        end
        while waypointList:getChildCount() > 0 do
            local child = waypointList:getLastChild()
            waypointList:destroyChildren(child)
        end
        for i, pos in ipairs(wpts) do
            AddWaypoint(pos)
        end
    end
    local function Load()
        local fileWidget = fileList:getFocusedChild()
        if fileWidget == nil then return end
        local file = fileWidget:getText()
        if not fs_file_exists(WPTS_DIR .. file) then
            RefreshFileList()
            return
        end
        for i, file2 in ipairs(g_resources.listDirectoryFiles(WPTS_DIR, false, false)) do
            if file == file2 then
                local data = ReadSettings(file)
                SETTINGS.LOAD_FILE = file
                IS_DUNGEON = SETTINGS.LOAD_FILE:find('__dung') and true or false
                CURRENT_INDEX = #data > 0 and 1 or 0
                LoadNewWaypoints(data)
                SaveSettings()
                for index, child in ipairs(fileList:getChildren()) do
                    if child then
                        child:setColor('white')
                    end
                end
                fileWidget:setColor('green')
                if CURRENT_INDEX > 0 and #WAYPOINTS >= CURRENT_INDEX then
                    local child = waypointList:getChildByIndex(CURRENT_INDEX)
                    child:setColor('green')
                    waypointList:focusChild(child)
                end
                return
            end
        end
    end
    --------------------------------
    file_name:setText(SETTINGS.FILE)
    RefreshFileList()
    Load()
    --------------------------------
    fileList.onDoubleClick = function()
        Load()
    end
    add_wpt.onClick = function(widget)
        AddWaypoint()
    end
    add_dir.onClick = function(widget)
        AddWaypoint(GetDirectionPos())
    end
    file_name.onTextChange = function(widget, text)
        SETTINGS.FILE = text
        SaveSettings()
    end
    save.onClick = function(widget)
        if #WAYPOINTS > 0 then
            SaveSettings()
            SaveSettings(SETTINGS.FILE)
            RefreshFileList()
            IS_DUNGEON = SETTINGS.FILE:find('__dung') and true or false
        end
    end
    load.onClick = function(widget)
        Load()
    end
end

UI.Label()
SetLureUI()
SetWalkerUI()

local function GetDungeonPos(wpt, ppos)
    local x,y,z = wpt.x,wpt.y,ppos.z
    local function dung()
        local ymin = 1506 - 141
        local ymax = 1622 - 141
        for i = 1, 5 do
            if ppos.y >= ymin + 141 * i and ppos.y <= ymax + 141 * i then
                return i
            end
        end
        return 0
    end
    local function sety()
        local ymin = 1506
        local ymax = 1622
        for i = 5 * -141, 5 * 141, 141 do
            local y2 = y + i
            if y2 >= ymin and y2 <= ymax then
                y = y2 - 141
                return
            end
        end
    end
    local current_dung = dung()
    if current_dung == 0 then
        print("ERROR current_dung == 0")
        return nil
    end
    if current_dung == 1 then
        return {x=x,y=y,z=z}
    end
    sety()
    if current_dung == 2 or current_dung == 3 then
        x = x + 1
    end
    if current_dung == 4 then
        x = x + 2
    end
    return {x=x, y=y+141*current_dung, z=z}
end

local function NextWaypoint()
    LAST_INDEX = CURRENT_INDEX
    CURRENT_INDEX = CURRENT_INDEX + 1
    if (CURRENT_INDEX > #WAYPOINTS) then
        CURRENT_INDEX = 1
    end
    local count = waypointList:getChildCount()
    if LAST_INDEX <= count then
        waypointList:getChildByIndex(LAST_INDEX):setColor('white')
    end
    local child = waypointList:getChildByIndex(CURRENT_INDEX)
    child:setColor('green')
    waypointList:focusChild(child)
end

local function FindWaypointInRange(ppos, range)
    LAST_INDEX = CURRENT_INDEX
    local index
    for i, wpt in ipairs(WAYPOINTS) do
        if IS_DUNGEON or wpt.z == ppos.z then
            --print(index, getDistanceBetween(ppos, wpt))
            local pos = IS_DUNGEON and GetDungeonPos(wpt, ppos) or wpt
            local distance = getDistanceBetween(ppos, pos)
            if distance <= range then
                index = i
                break
            end
        else
            --print(wpt.z, ppos.z, wpt.z - ppos.z, type(wpt.z), type(ppos.z))
        end
    end
    if index then
        --print('best_distance', best_distance)
        CURRENT_INDEX = index
        if (CURRENT_INDEX > #WAYPOINTS) then
            CURRENT_INDEX = 1
        end
        local count = waypointList:getChildCount()
        if LAST_INDEX <= count then
            waypointList:getChildByIndex(LAST_INDEX):setColor('white')
        end
        local child = waypointList:getChildByIndex(CURRENT_INDEX)
        child:setColor('green')
        waypointList:focusChild(child)
    end
end

local function WalkInfo(src, dest, maxDist, params)
    local path = getPath(src, dest, maxDist, params)
    if not path or not path[1] then
        return -1
    end
    local dir = path[1]
    if player:canWalk(dir, false) then
        WAITING_POS = GetPosFromDir(src, dir)
        WAITING_TIMEOUT = now + 200 + g_game.getPing()
        g_game.walk(dir, false)
        return 0
    end
    return 1
end

local function IsWaypointValid(ppos)
    if #WAYPOINTS == 0 then
        print('#WAYPOINTS == 0')
        return false
    end

    CURRENT_WAYPOINT = IS_DUNGEON and GetDungeonPos(WAYPOINTS[CURRENT_INDEX], ppos) or WAYPOINTS[CURRENT_INDEX]

    if not CURRENT_WAYPOINT or CURRENT_WAYPOINT.z ~= ppos.z then
        NextWaypoint()
        print('NextWaypoint')
        return false
    end

    return true
end

local function IsOnWaypoint(stc, dst, dist)
    if dist == 0 then
        NextWaypoint()
        return true
    end
    if dist == 1 then
        for _, spec in ipairs(SPECTATORS) do
            if getDistanceBetween(spec[2], dst) == 0 then
                NextWaypoint()
                return true
            end
        end
    end
    return false
end

local function Delay(macro, delay)
    macro.delay = now + delay
end

local last_blocked_path_info = now
local function Walker(macro)
    local PPOS, PPOSZ, MOBS, PLAYERS, LURE_DELAY, DIST

    PPOS = player:getPosition()
    PPOSZ = PPOS.z

    if WAITING_POS then
        if now < WAITING_TIMEOUT and getDistanceBetween(PPOS, WAITING_POS) > 0 then
            Delay(macro, 10)
            --print('1')
            return
        end
        WAITING_POS = nil
    end

    if not IsWaypointValid(PPOS) then
        Delay(macro, 50)
        --print('2')
        return
    end

    DIST = getDistanceBetween(PPOS, CURRENT_WAYPOINT)

    if IsOnWaypoint(PPOS, CURRENT_WAYPOINT, DIST) then
        Delay(macro, 50)
        --print('4')
        return
    end

    if DIST > 40 then
        FindWaypointInRange(PPOS, 40)
        Delay(macro, 50)
        --print('5')
        return
    end

    MOBS, PLAYERS = GetSpectators(5)
    if (#MOBS >= SETTINGS.LURE_MIN) then
        local lureMax = SETTINGS.LURE_MAX
        if (#MOBS >= lureMax) then
            Delay(macro, 50)
            if SpellBotSettings.auto_follow_switch then
                local attackingCreature = g_game.getAttackingCreature()
                if attackingCreature then
                    local enemyPos = attackingCreature:getPosition()
                    WalkInfo(PPOS, enemyPos, 8, { precision = 1, ignoreNonPathable = true, allowUnseen = true, allowOnlyVisibleTiles = false })
                end
            end
            --print('5')
            return
        end
    end

    --if not WalkTo(PPOS, CURRENT_WAYPOINT, 40) then
    local info = WalkInfo(PPOS, CURRENT_WAYPOINT, 40, { ignoreNonPathable = true, allowUnseen = true, allowOnlyVisibleTiles = false })
    if info == -1 then
        info = WalkInfo(PPOS, CURRENT_WAYPOINT, 40, { precision = 5, ignoreNonPathable = true, allowUnseen = true, allowOnlyVisibleTiles = false })
        if info == -1 then
            if #MOBS == 0 and not player:isAutoWalking() then
                player:autoWalk(CURRENT_WAYPOINT)
            end
            --NextWaypoint()
            print('6')
            if #MOBS == 0 and now > last_blocked_path_info + 500 then
                for i = 1, #onPathBlockCb do
                    onPathBlockCb[i](WAYPOINTS[CURRENT_INDEX])
                end
                last_blocked_path_info = now
            end
            Delay(macro, 100)
            return
        end
    end

    if info == 1 then
        Delay(macro, 10)
        return
    end
    --end

    if info == 0 then
        if (MOBS and #MOBS >= SETTINGS.LURE_MIN) then
            LURE_DELAY = SETTINGS.LURE_DELAY
            if LURE_DELAY then
                LURE_DELAY = LURE_DELAY + 20 * #MOBS
            end
            LURE_DELAY = LURE_DELAY or 500
        end

        Delay(macro, math.max(LURE_DELAY or 100, player:getStepTicksLeft()))
    end
end

WALKER_BOT = macro(100, "Walker", function(macro)
    local friends_count, friends_around_player, party_friends_around_player, party_leader = FriendsInRange(5)
    if friends_around_player < friends_count or not SpellBotSettings then return end
    SafeCall(function() Walker(macro) end, 'Walker')
end)