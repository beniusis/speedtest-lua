local cURL = require("cURL")

local upload_host_url = "http://vln038-speedtest-1.tele2.net/upload.php"
local download_host_url = "http://vln038-speedtest-1.tele2.net/10MB.zip"

local file_size = 1024 * 1024 * 10 -- 10 MB
local fd = io.open("upload_file.zip", "rb")

function measure_download_speed()
    local easy = cURL.easy()
    easy:setopt(cURL.OPT_URL, download_host_url)
    easy:setopt(cURL.OPT_WRITEFUNCTION, function() end)
    easy:perform()

    download_speed = easy:getinfo(cURL.INFO_SPEED_DOWNLOAD_T) / 125000
    easy:close()
end

function measure_upload_speed()
    local easy = cURL.easy()
    easy:setopt(cURL.OPT_URL, upload_host_url)
    easy:setopt(cURL.OPT_UPLOAD, true)
    easy:setopt(cURL.OPT_READFUNCTION, fd)
    easy:setopt(cURL.OPT_INFILESIZE, file_size)
    easy:perform(curl)
    
    upload_speed = easy:getinfo(cURL.INFO_SPEED_UPLOAD_T) / 125000
    easy:close()
end

measure_download_speed()
print(string.format("Average download speed: %.2f Mbps", download_speed))

measure_upload_speed()
print(string.format("Average upload speed: %.2f Mbps", upload_speed))