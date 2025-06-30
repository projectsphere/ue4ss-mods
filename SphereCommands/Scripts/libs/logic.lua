local commands = require("libs/commands")
local logic = {}

function logic.chatHook(ctx, chat)
    local text = chat:get().Message:ToString()
    local playerState = ctx:get()
    local PlayerController = playerState:GetPlayerController()
    local cmd, rest = text:match("^!(%S+)%s*(.*)$")
    if cmd then
        cmd = cmd:lower()
        if cmd == "spectate" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleSpectate(playerState)
        elseif cmd == "announce" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleAnnounce(playerState, rest)
        elseif cmd == "fly" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.toggleFlyMode(playerState, rest:lower())
        elseif cmd == "noclip" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.toggleNoclip(playerState, rest:lower())
        elseif cmd == "give" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleGiveCommand(playerState, rest)
        elseif cmd == "exp" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleExpCommand(playerState, rest)
        elseif cmd == 'giveme' then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handlePersonalGive(playerState, rest)
        elseif cmd == "giveexp" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handlePersonalExp(playerState, rest)
        elseif cmd == "settime" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleTime(playerState, rest)
        elseif cmd == "slay" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleSlay(playerState, rest)
        elseif cmd == "goto" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleGoto(playerState, rest)
        elseif cmd == "spawn" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleSpawnPal(playerState, rest)
        elseif cmd == "getpos" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleGetPos(playerState)
        elseif cmd == "kick" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleKick(playerState, rest)
        elseif cmd == 'time' then
            commands.handleCurrentTime(playerState)
        elseif cmd == "help" then
            commands.sendSystemAnnounce(PlayerController, "!give PlayerName item:amount | !exp PlayerName amount | !spawn PalAsset | !slay PlayerName | !kick PlayerName | !fly enable/disable | !noclip enable/disable | !spectate | !announce msg | !settime 0-23 | !giveme item:amount | !giveexp amount | !goto x,y,z | !getpos | !time | !unstuck")
        elseif cmd == "unstuck" then
            commands.handleUnstuck(playerState)
        end
    end
end

return logic
