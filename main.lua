cURL = require("cURL")
JSON = require("json")
argparse = require("argparse")

-- Global constants
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
HOST_URL = "speed-kaunas.telia.lt:8080"
IP_API_URL = "http://ip-api.com/json/?fields=25115"
SERVER_LIST_URL = "https://raw.githubusercontent.com/beniusis/speedtest-lua/master/server_list.json"
SERVER_LIST_FILE = "/tmp/servers.json"

-- Global variables
download_speed = 0
upload_speed = 0
start_time = 0

-- Downloading progress function
function download_progress(_, dlnow, _, _)
    download_speed = (dlnow / 1024 / 1000 * 8) / (os.time() - start_time)
end

-- Uploading progress function
function upload_progress(_, _, _, ulnow)
    upload_speed = (ulnow / 1024 / 1000 * 8) / (os.time() - start_time)
end

-- Method for measuring the download speed
function measure_download_speed()
    local easy = cURL.easy{
        url = HOST_URL .. "/download",
        useragent = USER_AGENT,
        writefunction = io.open("/dev/null", "wb"),
        noprogress = false,
        timeout = 10,
        progressfunction = download_progress
    }

    start_time = os.time()
    local success, err = pcall(easy.perform, easy)

    if err == "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)"
        or err == "[CURL-EASY][PARTIAL_FILE] Transferred a partial file (18)"
            or err == nil then
                print(string.format("Download speed: %.2f Mbps", download_speed))
    else
        print(err)
    end

    easy:close()
    start_time = 0
end

-- Method for measuring the upload speed
function measure_upload_speed()
    local easy = cURL.easy{
        url = HOST_URL .. "/upload",
        useragent = USER_AGENT,
        post = true,
        httppost = cURL.form{
            zero = {
                file = "/dev/zero",
                name = "upload_speed_test_file"
            }
        },
        noprogress = false,
        timeout = 10,
        progressfunction = upload_progress
    }

    start_time = os.time()

    local success, err = pcall(easy.perform, easy)

    if err == "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)"
        or err == nil then
            print(string.format("Upload speed: %.2f Mbps", upload_speed))
    else
        print(err)
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

    local easy = cURL.easy{
        url = SERVER_LIST_URL,
        useragent = USER_AGENT,
        httpget = true,
        writefunction = io.open(SERVER_LIST_FILE, "w")
    }

    local success, err = pcall(easy.perform, easy)

    if not success then
        print(err)
    else
        print("Server list has been successfully downloaded!")
    end

    easy:close()
end

-- Get servers from the server list file by provided country
-- If the server list file does not exist in the system - download it first
-- If country parameter is not provided or there are zero servers found of provided country - return nil
function get_servers(country)
    download_server_list() -- does nothing if the server list file exists

    local servers = {}
    local server_file = io.open(SERVER_LIST_FILE, "r")
    local server_file_contents = server_file:read("*a")

    if country == nil then
        return nil
    end

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

-- Firstly, check whether the server responds to the HTTP request within the 3 seconds
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
    local best_latency = 99999
    local server_host = nil

    if servers == nil then
        return nil
    end

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

parser = argparse()
parser:flag("-d", "Call the function to measure download's speed")
parser:flag("-u", "Call the function to measure upload's speed")
parser:flag("-c", "Call the function to get the client's country")
parser:flag("-s", "Call the function to get the server list")
parser:flag("-b", "Call the function to find the best server from the server list")
args = parser:parse()

if (args.d) then
    measure_download_speed()
elseif (args.u) then
    measure_upload_speed()
elseif (args.c) then
    local country = get_country()
elseif (args.s) then
    local country = get_country()
    local servers = get_servers(country)
elseif (args.b) then
    local country = get_country()
    local servers = get_servers(country)
    local best_server = find_best_server(servers)
end