local M = {}

local SERVER_LIST_FILE = "/tmp/servers.json"
local RESULTS_FILE = "/tmp/speed_test_results.json"
local INTERIM_FILE = "/tmp/speedtest_interim.json"

function M.get_country()
    local handle = io.popen("main.lua --country")
    local output = handle:read("*a")
    return { country = output }
end

function M.start_finding_best_server()
    io.popen("main.lua --bestServer")
    local content = "Finding best server..."
    return { content = content }
end

function M.get_best_server()
    local file = io.open(INTERIM_FILE, "r")
    local output = file:read("*a")
    file:close()
    return { content = output }
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
    local content = "Started automatic test..."
    return { content = content }
end

-- PARAMS: server - server host; type - download/upload
function M.specific_test(params)
    io.popen("main.lua --specific " .. params.server .. " --" .. params.type .. " file")
    local content = "Started specific test to a chosen server..."
    return { content = content }
end

return M