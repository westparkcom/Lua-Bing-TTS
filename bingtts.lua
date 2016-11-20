-- luarocks install luasec
-- luarocks install --server=http://luarocks.org/dev http

local http = require("http.request")

--
-- Get url and return binary result
--
function ms_wget(postheaders, setbody)
    local posturl = "https://speech.platform.bing.com/synthesize"
    local request = http.new_from_uri(posturl)
    for k,v in pairs(postheaders) do
        request.headers:upsert(k, v)
    end
    request.headers:upsert(":method", "POST")
    request:set_body(setbody)
    local headers, stream = request:go(10)
    if headers:get(":status") ~= "200" then
        print("Error: " .. headers:get(":status"))
        print(stream:get_body_as_string()..'\n')
        return nil
    end
    return stream:get_body_as_string()
end

--
-- Token Generator for Azure Cognitive API
--
function ms_token_gen(client_secret, authurl)
    local request = http.new_from_uri(authurl)
    request.headers:upsert("Ocp-Apim-Subscription-Key", client_secret)
    request.headers:upsert(":method", "POST")
    local headers, stream = request:go(10)
    if headers:get(":status") ~= "200" then
        print("Error: " .. headers:get(":status"))
        print(stream:get_body_as_string()..'\n')
        return nil
    end
    return stream:get_body_as_string()
end

--
-- BingTTS Class
--

local BingTTS = {
    -- default field values
    authurl = "https://api.cognitive.microsoft.com/sts/v1.0/issueToken",
    -- Properties
    data = {},
    langs = {},
}

function BingTTS:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

function BingTTS:prepare(client_secret, textstr, lang, gender, format)
    -- Prepare Bing TTS
    if string.len(textstr) == 0 then
        return false
    end
    namemap = {
        ["ar-EG,Female"] = "Microsoft Server Speech Text to Speech Voice (ar-EG, Hoda)",
        ["de-DE,Female"] = "Microsoft Server Speech Text to Speech Voice (de-DE, Hedda)",
        ["de-DE,Male"] = "Microsoft Server Speech Text to Speech Voice (de-DE, Stefan, Apollo)",
        ["en-AU,Female"] = "Microsoft Server Speech Text to Speech Voice (en-AU, Catherine)",
        ["en-CA,Female"] = "Microsoft Server Speech Text to Speech Voice (en-CA, Linda)",
        ["en-GB,Female"] = "Microsoft Server Speech Text to Speech Voice (en-GB, Susan, Apollo)",
        ["en-GB,Male"] = "Microsoft Server Speech Text to Speech Voice (en-GB, George, Apollo)",
        ["en-IN,Male"] = "Microsoft Server Speech Text to Speech Voice (en-IN, Ravi, Apollo)",
        ["en-US,Male"] = "Microsoft Server Speech Text to Speech Voice (en-US, BenjaminRUS)",
        ["en-US,Female"] = "Microsoft Server Speech Text to Speech Voice (en-US, ZiraRUS)",
        ["es-ES,Female"] = "Microsoft Server Speech Text to Speech Voice (es-ES, Laura, Apollo)",
        ["es-ES,Male"] = "Microsoft Server Speech Text to Speech Voice (es-ES, Pablo, Apollo)",
        ["es-MX,Male"] = "Microsoft Server Speech Text to Speech Voice (es-MX, Raul, Apollo)",
        ["fr-CA,Female"] = "Microsoft Server Speech Text to Speech Voice (fr-CA, Caroline)",
        ["fr-FR,Female"] = "Microsoft Server Speech Text to Speech Voice (fr-FR, Julie, Apollo)",
        ["fr-FR,Male"] = "Microsoft Server Speech Text to Speech Voice (fr-FR, Paul, Apollo)",
        ["it-IT,Male"] = "Microsoft Server Speech Text to Speech Voice (it-IT, Cosimo, Apollo)",
        ["ja-JP,Female"] = "Microsoft Server Speech Text to Speech Voice (ja-JP, Ayumi, Apollo)",
        ["ja-JP,Male"] = "Microsoft Server Speech Text to Speech Voice (ja-JP, Ichiro, Apollo)",
        ["pt-BR,Male"] = "Microsoft Server Speech Text to Speech Voice (pt-BR, Daniel, Apollo)",
        ["ru-RU,Female"] = "Microsoft Server Speech Text to Speech Voice (ru-RU, Irina, Apollo)",
        ["ru-RU,Male"] = "Microsoft Server Speech Text to Speech Voice (ru-RU, Pavel, Apollo)",
        ["zh-CN,Female"] = "Microsoft Server Speech Text to Speech Voice (zh-CN, HuihuiRUS)",
        ["zh-CN,Male"] = "Microsoft Server Speech Text to Speech Voice (zh-CN, Kangkang, Apollo)",
        ["zh-HK,Male"] = "Microsoft Server Speech Text to Speech Voice (zh-HK, Danny, Apollo)",
        ["zh-TW,Female"] = "Microsoft Server Speech Text to Speech Voice (zh-TW, Yating, Apollo)",
        ["zh-TW,Male"] = "Microsoft Server Speech Text to Speech Voice (zh-TW, Zhiwei, Apollo)"
    }
    -- Capitalize first letter
    gender = gender:sub(1,1):upper()..gender:sub(2)
    langmap = lang .. ',' .. gender
    if namemap[langmap] == nil then
        return false
    end
    servicename = namemap[langmap]
    self.data = {
        ["client_secret"] = client_secret,
        ["language"] = lang,
        ["format"] = format,
        ["gender"] = gender,
        ["text"] = textstr,
        ["service"] = servicename
    }
end

function BingTTS:run()
    -- Run will call Bing TTS API and reproduce audio
    -- Generate Authorization Token
    token = ms_token_gen(self.data["client_secret"], self.authurl)
    if token == nil then
        print('Token error, returning nil.\n')
        return nil
    end
    -- Build Authorization Headers
    headertable = {["Content-type"] = "application/ssml+xml",
                   ["Authorization"] = "Bearer "..token,
                   ["X-Microsoft-OutputFormat"] = self.data["format"],
                   ["X-Search-AppId"] = "07D3234E49CE426DAA29772419F436CA",
                   ["X-Search-ClientID"] = "1ECFAE91408841A480F00935DC390960",
                   }
    postbody = "<speak version='1.0' xml:lang='"..self.data["language"].."'><voice xml:lang='"..self.data["language"].."' xml:gender='"..self.data["gender"].."' name='"..self.data["service"].."'>"..self.data["text"].."</voice></speak>"
    output = ms_wget(headertable, postbody)
    return output
end

return BingTTS
