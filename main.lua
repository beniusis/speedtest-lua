cURL = require("cURL")

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
HOST_URL = "speed-kaunas.telia.lt:8080"

-- speed variables
download_speed = 0
upload_speed = 0

function measure_download_speed()
    local start_time = os.time()
    local success, err = pcall(function()
        cURL.easy{
            url = HOST_URL .. "/download",
            useragent = USER_AGENT,
            writefunction = io.open("/dev/null", "wb"),
            noprogress = false,
            timeout = 1,
            progressfunction = function (download_total, download_now, _, _)
                download_speed = (download_now / 125000) / (os.time() - start_time)
            end
        }:perform():close()
    end)

    if err then
        print(string.format("Average download speed: %.2f Mbps", download_speed))
    end
end

function measure_upload_speed()
    local start_time = os.time()
    local success, err = pcall(function ()
        cURL.easy{
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
        }:perform():close()
    end)
    
    if err then
        print(string.format("Average upload speed: %.2f Mbps", upload_speed))
    end
end

measure_download_speed()
measure_upload_speed()