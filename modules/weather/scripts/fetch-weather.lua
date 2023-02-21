#!/usr/bin/lua

-- Original script source: https://gist.github.com/meskarune/5729e8d6c8428e9c70a72bed475db4e1

json = require("json")
config = require("config")

-- Url de l'api
api_url = "https://www.meteo.bzh/previsions/ajax/ville/heures"

-- Code insee de la ville dont on veut connaître la météo
insee = config.insee

-- measure is °C if metric and °F if imperial
measure = '°C'

cache_file = "weather.json"

currenttime = os.date("!%Y%m%d%H%M%S")
current_hour = math.floor(os.date("!%H") + 1)

file_exists = function (name)
    f=io.open(name,"r")
    if f~=nil then
        io.close(f)
        return true
    else
        return false
    end
end

if file_exists(cache_file) then
    cache = io.open(cache_file,"r+")
    data = json.decode(cache:read())
    timepassed = os.difftime(currenttime, data.timestamp)
else
    cache = io.open(cache_file, "w")
    timepassed = 6000
end

makecache = function (s)
    s.timestamp = currenttime
    save = json.encode(s)
    cache:write(save)
end

capture = function(cmd, raw)
    local handle = assert(io.popen(cmd, 'r'))
    local output = assert(handle:read('*a'))
    
    handle:close()
    
    if raw then 
        return output 
    end
   
    output = string.gsub(
        string.gsub(
            string.gsub(output, '^%s+', ''), 
            '%s+$', 
            ''
        ), 
        '[\n\r]+',
        ' '
    )
   
   return output
end

if timepassed < 3600 then
    response = data
else
    weather = capture(string.format("curl -L '%s' --form 'insee=%s' --form 'day=0' ", api_url, insee))
    if weather then
        response = json.decode(weather)[current_hour]
        makecache(response)
    else
        response = data
    end
end

math.round = function (n)
    return math.floor(n + 0.5)
end

temp = response.temp
conditions = response.forecast
city = response.name

io.write(("${color %s}${font %s:size=18}%s\n%s%s ${font %s:light:size=18}| %s\n"):format(config.color, config.font,city, math.round(temp), measure, config.font, conditions))

cache:close()
