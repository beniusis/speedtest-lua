cURL = require("cURL")
JSON = require("json")

-- Global constants
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
HOST_URL = "speed-kaunas.telia.lt:8080"
IP_API_URL = "http://ip-api.com/json/?fields=25115"
SERVER_LIST_URL = "https://raw.githubusercontent.com/beniusis/speedtest-lua/master/server_list.json"
SERVER_LIST_FILE = "/tmp/servers.json"

-- Speed variables (default values)
download_speed = 0
upload_speed = 0

-- Method which should be called inside pcalls to handle errors
function init_perform(easy_object)
    easy_object:perform()
    easy_object:close()
end

-- Method for measuring the download speed
function measure_download_speed()
    local start_time = os.time()
    local easy = cURL.easy{
        url = HOST_URL .. "/download",
        useragent = USER_AGENT,
        writefunction = io.open("/dev/null", "wb"),
        noprogress = false,
        timeout = 15,
        progressfunction = function (download_total, download_now, _, _)
            download_speed = (download_now / 125000) / (os.time() - start_time)
        end
    }

    local success, err = pcall(init_perform, easy)

    if err == "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)"
        or err == "[CURL-EASY][PARTIAL_FILE] Transferred a partial file (18)" then
            print(string.format("Download speed: %.2f Mbps", download_speed))
    else
        print(err)
    end
end

-- Method for measuring the upload speed
function measure_upload_speed()
    local start_time = os.time()
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
        timeout = 15,
        progressfunction = function (_, _, upload_total, upload_now)
           upload_speed = (upload_now / 125000) / (os.time() - start_time)
        end
    }

    local success, err = pcall(init_perform, easy)

    if err == "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)" then
        print(string.format("Upload speed: %.2f Mbps", upload_speed))
    else
        print(err)
    end
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
            country = json.decode(data).country
        end
    }

    local success, err = pcall(init_perform, easy)
    if not success then
        return "Unknown"
    else
        return country
    end
end

-- Download server list file if it doesn't exist in the system
-- If the file exists - close it and do nothing
function download_server_list()
    local server_file = io.open(SERVER_LIST_FILE, "r")
    if server_file == nil then
        local easy = cURL.easy{
            url = SERVER_LIST_URL,
            useragent = USER_AGENT,
            httpget = true,
            writefunction = io.open(SERVER_LIST_FILE, "w")
        }

        local success, err = pcall(init_perform, easy)

        if not success then
            print(err)
        else
            print("Server list has been successfully downloaded!")
        end
    else
        server_file:close()
    end
end

-- Get servers from the server list file by provided country
-- If the server list file does not exist in the system - download it first
-- If country parameter is not provided or there are zero servers found of provided country - return nil
function get_servers(country)
    download_server_list() -- does nothing if the server list file exists

    local servers = {}
    local server_file = io.open(SERVER_LIST_FILE, "r")
    local server_file_contents = server_file:read("*a")

    if country ~= nil then
        local server_list = json.decode(server_file_contents)
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
    else
        return nil
    end
end