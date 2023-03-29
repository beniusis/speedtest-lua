cURL = require("cURL")
JSON = require("json")
argparse = require("argparse")

-- Global constants
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
HOST_URL = "speed-kaunas.telia.lt:8080"
IP_API_URL = "http://ip-api.com/json/?fields=25115"
SERVER_LIST_URL = "https://raw.githubusercontent.com/beniusis/speedtest-lua/master/server_list.json"
SERVER_LIST_FILE = "/tmp/servers.json"
RESULTS_FILE = "/tmp/speed_test_results.json"

-- Global variables
download_speed = 0
upload_speed = 0
start_time = 0
how_to_show_results = nil -- terminal OR file

-- Round the provided number to 10s
-- For example: 9.56321 to 9.56, 5.98741 to 5.99 and so on ...
function round(number)
    return tonumber(string.format("%.2f", number))
end

-- Downloading progress function
function download_progress(_, dlnow, _, _)
    download_speed = round((dlnow / 1024 / 1000 * 8) / (os.time() - start_time))
    result("Downloading", download_speed, upload_speed)
end

-- Uploading progress function
function upload_progress(_, _, _, ulnow)
    upload_speed = round((ulnow / 1024 / 1000 * 8) / (os.time() - start_time))
    result("Uploading", download_speed, upload_speed)
end

-- Method for measuring the download speed
function measure_download_speed(server_host)
    local easy = cURL.easy{
        url = server_host .. "/download",
        useragent = USER_AGENT,
        writefunction = io.open("/dev/null", "wb"),
        noprogress = false,
        timeout = 15,
        progressfunction = download_progress
    }

    start_time = os.time()
    local success, err = pcall(easy.perform, easy)

    if err == "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)"
        or err == "[CURL-EASY][PARTIAL_FILE] Transferred a partial file (18)"
            or err == nil then
                result("Finished downloading", download_speed, upload_speed)
    else
        result("Failed", 0, 0)
    end

    easy:close()
    start_time = 0
end

-- Method for measuring the upload speed
function measure_upload_speed(server_host)
    local easy = cURL.easy{
        url = server_host .. "/upload",
        useragent = USER_AGENT,
        post = true,
        httppost = cURL.form{
            zero = {
                file = "/dev/zero",
                name = "upload_speed_test_file"
            }
        },
        noprogress = false,
        timeout = 15,
        progressfunction = upload_progress
    }

    start_time = os.time()

    local success, err = pcall(easy.perform, easy)

    if err == "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)"
        or err == nil then
            result("Finished uploading", download_speed, upload_speed)
    else
        result("Failed", 0, 0)
    end

    easy:close()
    start_time = 0
end

-- Get the country of a client using geolocation API (ip-api.com) ------ endpoint is limited to 45 rpm from an IP address
-- If there is an error in the call - return "Unknown" as the country, otherwise return country's name
function get_country()
    local country
    local easy = cURL.easy{
        url = IP_API_URL,
        useragent = USER_AGENT,
        httpget = true,
        writefunction = function(data)
            country = JSON.decode(data).country
        end
    }

    local success, err = pcall(easy.perform, easy)

    if not success then
        return "Unknown"
    else
        return country
    end

    easy:close()
end

-- Download server list file if it doesn't exist in the system
-- If the file exists - close it and do nothing
function download_server_list()
    local server_file = io.open(SERVER_LIST_FILE, "r")

    if server_file ~= nil then
        server_file:close()
        return
    end
    
    server_file = io.open(SERVER_LIST_FILE, "w")

    local easy = cURL.easy{
        url = SERVER_LIST_URL,
        useragent = USER_AGENT,
        httpget = true,
        writefunction = server_file
    }

    local success, err = pcall(easy.perform, easy)

    if not success then
        result("Failed", 0, 0)
    end

    server_file:close()
    easy:close()
end

-- Get servers from the server list file by provided country
-- If the server list file does not exist in the system - download it first
-- If country parameter is not provided or there are zero servers found of provided country - return nil
function get_servers(country)
    if country == nil then
        return nil
    end

    download_server_list() -- does nothing if the server list file exists

    local servers = {}
    local server_file = io.open(SERVER_LIST_FILE, "r")
    local server_file_contents = server_file:read("*a")

    local server_list = JSON.decode(server_file_contents)
    for _, server in ipairs(server_list) do
        if server.country == country then
            table.insert(servers, server)
        end
    end

    if #servers ~= 0 then
        return servers
    else
        return nil
    end
end

-- Checks whether the server responds to the HTTP request within the 3 seconds
-- If it does respond - return latency (in microseconds)
-- If it doesn't respond - return nil
function get_server_latency(server_host)
    local easy = cURL.easy()
    easy:setopt_url(server_host)
    easy:setopt_timeout(3)
    easy:setopt_ssl_verifyhost(false)
    easy:setopt_ssl_verifypeer(false)
    
    local success, err = pcall(easy.perform, easy)
    if success then
        return easy:getinfo(cURL.INFO_CONNECT_TIME_T)
    else
        return nil
    end

    easy:close()
end

-- Find the best server with the best response time
-- If provided server list is empty - returns nil
function find_best_server(servers)
    if servers == nil then
        return nil
    end

    local best_latency = 99999
    local server_host = nil

    for _, server in ipairs(servers) do
        local latency = get_server_latency(server.host)
        if latency ~= nil then
            if latency < best_latency then
                best_latency = latency
                server_host = server.host
            end
        end
    end
    return server_host
end

--[[
    Prints test results into a terminal or writes them into a file "/tmp/speed_test_results.json"

    Status:
        Failed - test failed, error occurred
        Downloading - ongoing download speed test
        Uploading - ongoing upload speed test
        Finished downloading - download speed test has been finished
        Finished uploading - upload speed test has been finished

    Download: download speed result
    Upload: upload speed result
]]
function result(status, download, upload)
    local res = JSON.encode(
        {
            status = status,
            download = download,
            upload = upload
        }
    )

    if how_to_show_results == "terminal" then
        print(res)
    elseif how_to_show_results == "file" then
        local results_file = io.open(RESULTS_FILE, "w")
        results_file:write(res)
        results_file:close()
    end
end

parser = argparse()
parser:group("Running tests",
    parser:option("--auto", "Calls the function to measure download and upload speeds to the best found server."):argname("terminal/file"):default("terminal"):defmode("a"),
    parser:option("--specific", "Calls the function to measure download and upload speeds to the chosen server."):args("1-2"):argname({"<server>", "terminal/file"})
)
parser:group("Retrieving data",
    parser:flag("--country", "Calls the function to get the client's country."),
    parser:flag("--servers", "Calls the function to get the server list.")
)
args = parser:parse()

if args.auto then
    how_to_show_results = args.auto
    local best_server_host = find_best_server(get_servers(get_country()))
    measure_download_speed(best_server_host)
    os.execute("sleep 3")
    measure_upload_speed(best_server_host)
elseif args.specific then
    how_to_show_results = args.specific[2] or "terminal"
    local server_host = args.specific[1]
    measure_download_speed(server_host)
    os.execute("sleep 3")
    measure_upload_speed(server_host)
elseif args.country then
    print(get_country())
elseif args.servers then
    download_server_list()
end