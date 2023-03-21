cURL = require("cURL")

user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
file_size = 1024 * 1024 * 10 -- 10MB
download_host_url = "speed-kaunas.telia.lt:8080/download"
upload_host_url = "speed-kaunas.telia.lt:8080/upload"

-- speed variables
download_speed = 0
upload_speed = 0

function measure_download_speed()
    local start_time = os.clock()
    local success, err = pcall(function()
        cURL.easy{
            url = download_host_url,
            useragent = user_agent,
            writefunction = io.open("/dev/null", "wb"),
            noprogress = false,
            timeout = 10,
            progressfunction = function (download_total, download_now, _, _)
                download_speed = ((download_now / 125000) / (os.clock() - start_time))
            end
        }:perform():close()
    end)

    if not success then
        print("DOWNLOAD FAILURE: " .. err)
    else
        print(string.format("Average download speed: %.2f Mbps", download_speed))
    end
end

function measure_upload_speed()
    local start_time = os.clock()
    local success, err = pcall(function ()
        cURL.easy{
            url = download_host_url,
            useragent = user_agent,
            infilesize = file_size,
            httpheader = { "Transfer-Encoding: chunked" },
            httppost = cURL.form():add_file("upload_test", "/dev/zero"),
            noprogress = false,
            timeout = 10,
            progressfunction = function (_, _, upload_total, upload_now)
                upload_speed = (upload_now / 125000) / (os.clock() - start_time)
            end
        }:perform():close()
    end)

    if not success then
        print("UPLOAD FAILURE: " .. err)
    else
        print(string.format("Average upload speed: %.2f Mbps", upload_speed))
    end    
end

-- measure_download_speed()
-- measure_upload_speed()