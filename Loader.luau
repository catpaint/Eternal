local BaseUrl = "https://raw.githubusercontent.com/catpaint/Eternal/refs/heads/main/"

local function LoadMainScript()
    if isfile then
        local localPaths = {
            "Eternal/Games/Doors/Main.luau",
            "Games/Doors/Main.luau",
            "Doors/Main.luau",
            "Main.luau"
        }
        for _, p in ipairs(localPaths) do
            if isfile(p) then
                local content = readfile(p)
                if content and #content > 100 then
                    local fn = loadstring(content)
                    if fn then return fn() end
                end
            end
        end
    end

    if game.PlaceId ~= 6516141723 then
        loadstring(game:HttpGet(BaseUrl .. "Games/Doors/Main.luau"))()
    else
        loadstring(game:HttpGet(BaseUrl .. "Games/Doors/Lobby.luau"))()
    end
end

LoadMainScript()
