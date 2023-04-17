local fs_read_table, fs_write_table = fs_read_table, fs_write_table
local pairs, ipairs, table_insert, table_remove = pairs, ipairs, table.insert, table.remove

SETTINGS_CLASS = Class()

function SETTINGS_CLASS:__init(path, default)
    self.settings = default
    self.path = path
    if fs_file_exists(self.path) then
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
        CompareSettings(self:Read(), self.settings)
        self:Save()
    else
        self:Save()
    end
end

function SETTINGS_CLASS:Read()
    return fs_read_table(self.path)
end

function SETTINGS_CLASS:Save(new_settings)
    fs_write_table(self.path, new_settings or self.settings)
end