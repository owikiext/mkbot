local pcall, json_encode, json_decode = pcall, json.encode, json.decode

function fs_file_exists(file)
    return g_resources.fileExists(file)
end

function fs_directory_exists(dir)
    return g_resources.directoryExists(dir)
end

function fs_create_directory(dir)
    while not g_resources.directoryExists(dir) do
        g_resources.makeDir(dir)
    end
end

function fs_write_table(file, content)
    local status, result
    while (not status or not result) do
        status, result = pcall(function()
            local encode_result = json_encode(content, 2)
            if encode_result then
                return g_resources.writeFileContents(file, encode_result)
            end
            return false
        end)
        if not status then
            print(result)
        end
    end
end

function fs_read_table(file)
    local status, result
    while (not status or not result) do
        status, result = pcall(function()
            local file_data = g_resources.readFileContents(file)
            local decode_result = json_decode(file_data)
            return decode_result
        end)
    end
    return result
end

WPTS_DIR = '/bot/mkbot/storage/wpts/'
PLAYER_DIR = '/bot/mkbot/storage/' .. player:getName() .. '/'
MULTIEXE_DIR = '/bot/mkbot/storage/'

fs_create_directory(WPTS_DIR)
fs_create_directory(PLAYER_DIR)