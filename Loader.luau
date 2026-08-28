getgenv().mstudio45 = nil
getgenv().Abysall = nil
getgenv().it = true

getgenv().mstudio45 = {
    Legit = false,
    Paid = true
}

local GameList = {
    [2440500124] = "Doors"
}

local BaseUrl = "https://raw.githubusercontent.com/catpaint/Eternal/refs/heads/main/"

local function SafeHttpGet(url)
    local filename = url:match("([^/]+%.luau)$")
    if filename and isfile then
        local localPaths = {
            "Eternal/Components/" .. filename,
            "Eternal/Games/Doors/" .. filename,
            "Eternal/" .. filename,
            "Components/" .. filename,
            filename
        }
        for _, p in ipairs(localPaths) do
            if isfile(p) then
                local content = readfile(p)
                if content and #content > 50 then
                    local fn = loadstring(content)
                    if fn then return fn() end
                end
            end
        end
    end

    local s, res = pcall(function() return game:HttpGet(url) end)
    if s and res and not res:find("404") then
        local fn = loadstring(res)
        if fn then return fn() end
    end
    return nil
end

getgenv().mstudio45 = {
    Environment = SafeHttpGet(BaseUrl .. "Components/Environment.luau") or {},
    ESPLibrary = SafeHttpGet(BaseUrl .. "Components/ESPLibrary.luau") or {},
    Legit = false,
    Paid = true
}

local function CloneReference(Object)
    if mstudio45 and mstudio45.Environment and mstudio45.Environment.cloneref then
        return mstudio45.Environment.cloneref(Object)
    else
        return Object
    end
end

local Services = setmetatable({}, {
    __index = function(self, Name)
        return CloneReference(game:GetService(Name))
    end
})

if mstudio45.Environment and mstudio45.Environment.writefile and mstudio45.Environment.readfile then
    pcall(function()
        if not mstudio45.Environment.isfile("mstudio45/UserData.json") then
            local Data = {
                TotalExecutions = 0,
                UILibrary = "Obsidian"
            }
            mstudio45.Environment.writefile("mstudio45/UserData.json", Services.HttpService:JSONEncode(Data))
        end

        local UserData = mstudio45.Environment.readfile("mstudio45/UserData.json")
        local Decoded = Services.HttpService:JSONDecode(UserData)
        if not Decoded.TotalExecutions then
            Decoded.TotalExecutions = 0    
        end

        Decoded.TotalExecutions = Decoded.TotalExecutions + 1

        if not Decoded.UILibrary then
            Decoded.UILibrary = "Obsidian"
        end

        mstudio45.TotalExecutions = Decoded.TotalExecutions
        mstudio45.UILibrary = Decoded.UILibrary

        mstudio45.Environment.writefile("mstudio45/UserData.json", Services.HttpService:JSONEncode(Decoded))
    end)
end

mstudio45.Interface = SafeHttpGet(BaseUrl .. "Components/Interface.luau")
mstudio45.Analytics = SafeHttpGet(BaseUrl .. "Components/Analytics.luau")

local CurrentGame = GameList[game.GameId]
if CurrentGame then
    SafeHttpGet(BaseUrl .. "Games/" .. CurrentGame .. "/Loader.luau")
else
    SafeHttpGet(BaseUrl .. "Games/Universal/Loader.luau")
end
