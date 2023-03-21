local cURL = require("cURL")

local argparse = require("argparse")
local parser = argparse()
parser:flag("-d --download", "Calls the function to measure download's speed.")
parser:flag("-u --upload", "Calls the function to measure upload's speed.")
local args = parser:parse()

local upload_host_url = "http://vln038-speedtest-1.tele2.net/upload.php"
local download_host_url = "http://vln038-speedtest-1.tele2.net/10MB.zip"

local file_size = 1024 * 1024 * 10 -- 10 MB

function measure_download_speed()
    local easy = cURL.easy{
        url = download_host_url,
        writefunction = function() end
    }
    easy:perform()

    download_speed = easy:getinfo(cURL.INFO_SPEED_DOWNLOAD_T) / 125000

    easy:close()
end

function measure_upload_speed()
    local easy = cURL.easy{
        url = upload_host_url,
        upload = true,
        readfunction = io.open("upload_file.zip", "rb"),
        infilesize = file_size
    }

    easy:perform()

    upload_speed = easy:getinfo(cURL.INFO_SPEED_UPLOAD_T) / 125000

    easy:close()
end

if (args.download) then 
    measure_download_speed()
    print(string.format("Average download speed: %.2f Mbps", download_speed))
end

if (args.upload) then
    measure_upload_speed()
    print(string.format("Average upload speed: %.2f Mbps", upload_speed))
end