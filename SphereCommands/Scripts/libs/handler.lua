local commands = require("libs/commands")

local commandHandlers = {
    spectate = { admin = true, func = commands.handleSpectate },
    announce = { admin = true, func = commands.handleAnnounce },
    fly = { admin = true, func = commands.toggleFlyMode },
    noclip = { admin = true, func = commands.toggleNoclip },
    give = {
        admin = true,
        func = function(state, rest)
            if not rest or rest == "" or not rest:find(" ") then
                commands.handlePersonalGive(state, rest)
            else
                commands.handleGiveCommand(state, rest)
            end
        end
    },
    exp = {
        admin = true,
        func = function(state, rest)
            if not rest or rest == "" or not rest:find(" ") then
                commands.handlePersonalExp(state, rest)
            else
                commands.handleExpCommand(state, rest)
            end
        end
    },
    giveme = { admin = true, func = commands.handlePersonalGive },
    giveexp = { admin = true, func = commands.handlePersonalExp },
    settime = { admin = true, func = commands.handleTime },
    slay = { admin = true, func = commands.handleSlay },
    ["goto"] = { admin = true, func = commands.handleGoto },
    spawn = { admin = true, func = commands.handleSpawnPal },
    getpos = {
        admin = true,
        func = function(state, rest)
            if rest == "" then
                commands.handleGetPos(state)
            else
                commands.handlePlayerGetPos(state, rest)
            end
        end
    },
    kick = { admin = true, func = commands.handleKick },
    time = { admin = false, func = commands.handleCurrentTime },
    unstuck = { admin = false, func = commands.handleUnstuck },
    godmode = { admin = true, func = commands.toggleGodMode },
    help = {
        admin = false,
        func = function(state)
            local pc = state:GetPlayerController()
            commands.sendSystemAnnounce(pc,
                "!give Player item:amount | !exp Player amount | !spawn PalAsset | !slay Player | !kick Player | " ..
                "!fly enable/disable | !noclip enable/disable | !spectate | !announce msg | !settime 0-23 | " ..
                "!giveme item:amount | !giveexp amount | !goto x,y,z | !getpos Player | !time | !unstuck"
            )
        end
    }
}

return commandHandlers