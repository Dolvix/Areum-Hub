local Data = {}

Data.Staff = {}
Data.Loaders = {}

Data.Loaders["BTRLoader"] = {
    Lversion = "2.472.3",
    state = "working",
    load = function()
        local result, err = pcall(function()
            local AreumUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/Built-the-Railroad-Loader.lua"))()
        end)

        if err then 
            warn("[Areum Hub]: Error Received While loading |"..err)
        end

        return result
    end,
}

Data.Loaders["UAV_StrikeLoader"] = {
    Lversion = "3.305.1",
    state = "working",
    load = function()
        local result, err = pcall(function()
            local AreumUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dolvix/Areum-Hub/main/UAV-STRIKE-Loader-Source.lua"))()
        end)

        if err then 
            warn("[Areum Hub]: Error Received While loading |"..err)
        end

        return result
    end,
}

return Data