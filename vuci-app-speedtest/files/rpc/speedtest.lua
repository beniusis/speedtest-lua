local M = {}

local SERVER_LIST_FILE = "/tmp/servers.json"
local RESULTS_FILE = "/tmp/speed_test_results.json"

function M.get_country()
    local handle = io.popen("main.lua --country")
    local output = handle:read("*a")
    return { country = output }
end

function M.get_best_server()
    local handle = io.popen("main.lua --bestServer")
    local output = handle:read("*a")
    return { server = output }
end

function M.get_results()
    local file = io.open(RESULTS_FILE, "r")
    local content = file:read("*a")
    file:close()
    return { results = content }
end

function M.get_servers()
    io.popen("main.lua --servers")
    local file = io.open(SERVER_LIST_FILE, "r")
    local content = file:read("*a")
    file:close()
    return { servers = content }
end

function M.automatic_test()
    io.popen("main.lua --auto file")
end

-- PARAMS: server - server host; type - download/upload
function M.specific_test(params)
    io.popen("main.lua --specific " .. params.server .. " --" .. params.type .. " file")
end

return M