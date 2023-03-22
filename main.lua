cURL = require("cURL")
JSON = require("json")

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
HOST_URL = "speed-kaunas.telia.lt:8080"
IP_API = "http://ip-api.com/json/?fields=25115"

-- speed variables
download_speed = 0
upload_speed = 0

function init_perform(easy_object)
    easy_object:perform()
    easy_object:close()
end

function measure_download_speed()
    local start_time = os.time()
    local easy = cURL.easy{
        url = HOST_URL .. "/download",
        useragent = USER_AGENT,
        writefunction = io.open("/dev/null", "wb"),
        noprogress = false,
        timeout = 1,
        progressfunction = function (download_total, download_now, _, _)
            download_speed = (download_now / 125000) / (os.time() - start_time)
        end
    }

    local success, err = pcall(init_perform, easy)

    if err == "[CURL-EASY][OPERATION_TIMEDOUT] Timeout was reached (28)" then
        print(string.format("Download speed: %.2f Mbps", download_speed))
    else
        print(err)
    end
end

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
        timeout = 1,
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

function get_country()
    local country
    local easy = cURL.easy{
        url = IP_API,
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

measure_download_speed()
measure_upload_speed()