if Eternal then
    return 
end
getgenv().Eternal = {
    Legit = true
}

local GameList = {
  [2440500124] = "Doors"
}

local BaseUrl = "https://raw.githubusercontent.com/catpaint/Eternal/refs/heads/main/"
getgenv().Eternal = {
    Environment = loadstring(game:HttpGet(BaseUrl .. "Components/Environment.luau"))(),
    ESPLibrary = loadstring(game:HttpGet(BaseUrl .. "Components/ESP.luau"))(),

    Legit = true, -- pog
}

local function CloneReference(Object)
    if Eternal and Eternal.Environment.cloneref then
        return Eternal.Environment.cloneref(Object)
    else
        return Object
    end
end

local Services = setmetatable({}, {
    __index = function(self, Name)
        return CloneReference(game:GetService(Name))
    end
})

if Eternal.Environment.writefile and Eternal.Environment.readfile then
    if not Eternal.Environment.isfile("Eternal/UserData.json") then
        local Data = {
            TotalExecutions = 0,
            UILibrary = "Obsidian"
        }
        Eternal.Environment.writefile("Eternal/UserData.json", Services.HttpService:JSONEncode(Data))
    end

    local UserData = Eternal.Environment.readfile("Eternal/UserData.json")
    local Decoded = Services.HttpService:JSONDecode(UserData)
    if not Decoded.TotalExecutions then
        Decoded.TotalExecutions = 0    
    end

    Decoded.TotalExecutions = Decoded.TotalExecutions + 1

    if not Decoded.UILibrary then
        Decoded.UILibrary = "Obsidian"
    end

    Eternal.TotalExecutions = Decoded.TotalExecutions
    Eternal.UILibrary = Decoded.UILibrary

    Eternal.Environment.writefile("Eternal/UserData.json", Services.HttpService:JSONEncode(Decoded))
end

Eternal.Interface = loadstring(game:HttpGet(BaseUrl .. "Components/Interface.luau"))()
Eternal.Analytics = loadstring(game:HttpGet(BaseUrl .. "Components/Analytics.luau"))()

local CurrentGame = GameList[game.GameId]
if CurrentGame then
    loadstring(game:HttpGet(BaseUrl .. "Games/" .. CurrentGame .. "/Loader.luau"))()
else
    loadstring(game:HttpGet(BaseUrl .. "Games/Universal/Loader.luau"))()
end
