

local __SETTINGS_PATH__ = PLAYER_DIR .. 'Attris.json'

local SETTINGS =
{
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
    ["2105,3020,12"] = "grim reaper",
    ["825,1453,7"] = "nomad",
    ["1878,3528,8"] = "green warrior",
    ["1154,1059,13"] = "death reaper",
    ["868,897,12"] = "bony sea devil",
    ["77,3314,10"] = "orc zando",
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

local AttriMissiles =
{
    [19] =
    {
        ['1,-1'] = true,
        ['-1,1'] = true,
        ['1,1'] = true,
        ['-1,-1'] = true,
    },
    [38] =
    {
        ['1,-1'] = true,
    },
}

local RecordedMissiles = {}

local Missile = Class()

function Missile:__init(id, src, dst)
    self.id = id
    self.src = src
    self.dst = dst
    self.dst_id = dst.x .. ',' .. dst.y .. ',' .. dst.z
    self.dx = self.dst.x - self.src.x
    self.dy = self.dst.y - self.src.y
    self.diff = self.dx .. ',' .. self.dy
    self.timer = now + 100
end

function Missile:IsValid()
    if (now > self.timer) then
        return false
    end
    if AttriMissiles[self.id][self.diff] == nil then
        return false
    end
    return true
end

function Missile:IsAround(dst)
    local dx = math.abs(dst.x - self.dst.x)
    local dy = math.abs(dst.y - self.dst.y)
    return dx + dy == 1
end

local function Star()
    local function IsStarAround(dst)
        for _, missile in ipairs(RecordedMissiles) do
            if missile.id == 19 and missile:IsAround(dst) then
                return true
            end
        end
        return false
    end
    for _, missile in ipairs(RecordedMissiles) do
        if missile.id == 38 and IsStarAround(missile.dst) then
            local dst = missile.dst
            local attri = g_map.getTile(dst)
            if attri then
                local attri_id = dst.x .. ',' .. dst.y .. ',' .. dst.z
                if SETTINGS[attri_id] == nil then
                    SETTINGS[attri_id] = "?"
                    SaveSettings()
                end
                attri:setFill('white')
            end
        end
    end
end

onMissle(function(missle)
    if missle then
        local id = missle:getId()
        if AttriMissiles[id] then
            local src = missle:getSource()
            local dst = missle:getDestination()
            if src and dst and getDistanceBetween(src, dst) == 1 then
                table.insert(RecordedMissiles, Missile(id, src, dst))
                for i = #RecordedMissiles, 1, -1 do
                    if not RecordedMissiles[i]:IsValid() then
                        table.remove(RecordedMissiles, i)
                    end
                end
                Star()
            end
        end
    end
end)

local attris_multiexe_settings = SETTINGS_CLASS(MULTIEXE_DIR .. 'Attris.json', {})

local function IsInRange(a, b, rangex, rangey)
    rangex = rangex or 7
    rangey = rangey or 5
    return math.abs(a.x-b.x) <= rangex and math.abs(a.y-b.y) <= rangey
end

local TilesInfo = {}
setDefaultTab('Attri')
macro(200, 'tile timer', function()
    local ppos = player:getPosition()
    for i, tile in ipairs(g_map.getTiles(posz())) do
        local tpos = tile and tile:getPosition() or nil
        if tpos and IsInRange(ppos, tpos) then
            local id = PosToID(tpos)
            if TilesInfo[id] == nil then
                TilesInfo[id] = {tpos, now}
            end
        end
    end
    local save = false
    local multiexe_attris = attris_multiexe_settings:Read()
    local toRemove = {}
    for id, info in pairs(TilesInfo) do
        local tpos = info[1]
        local timer = info[2]
        local tile = g_map.getTile(tpos)
        if tile then
            if not IsInRange(ppos, tpos) then
                tile:setText('')
                table.insert(toRemove, id)
            elseif multiexe_attris[id] then
                tile:setText('ok')
            else
                local current_duration = now - timer
                if current_duration > 60000 then
                    multiexe_attris[id] = true
                    save = true
                    tile:setText('ok')
                else
                    tile:setText(tostring(current_duration))
                end
            end
        else
            table.insert(toRemove, id)
        end
    end
    for i, id in ipairs(toRemove) do
        TilesInfo[id] = nil
    end
    if save then
        attris_multiexe_settings:Save(multiexe_attris)
    end
end)
--[[
local function ExplorerAttri(tile, tpos)
    local attris = {[1772] = true,}
    if tile == nil then return end
    local effects = ''
    for _, e in ipairs(tile:getEffects()) do
		if e then
            effects = effects .. tostring(e:getId()) .. ' '
		end
	end
    local items = ''
    for _, i in ipairs(tile:getItems()) do
		if i and attris[i:getId()] then
            items = items .. tostring(i:getId()) .. ' '
            tile:setFill('green')
		end
	end

    tile:setText('effects: ' .. effects .. '\n' .. 'items: ' .. items)
end

macro(200, 'explorer attri', function()
    local ppos = player:getPosition()
    for i, tile in ipairs(g_map.getTiles(posz())) do
        local tpos = tile and tile:getPosition() or nil
        if tpos and IsInRange(ppos, tpos) and getDistanceBetween(ppos, tpos) > 0 then
            ExplorerAttri(tile, tpos)
        elseif tile then
            tile:setText('')
        end
    end
end)

onAddThing(function(tile,thing)
    if tile then
        tile:setFill('green')
    end
end)
]]