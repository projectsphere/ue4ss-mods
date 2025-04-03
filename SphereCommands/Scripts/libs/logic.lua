local commands = require("libs/commands")
local logic = {}

function logic.damageHook(_, damageInfo)
    local result = damageInfo:get()
    if not result then return end
    local defender = result.Defender
    if not defender or not defender:IsValid() then return end
    local state = defender.PlayerState
    if not state or not state:IsValid() then return end
    local playerId = state:GetPlayerId()
    if commands.IsGodmodeEnabled(playerId) then
        result.Damage = 0
    end
end

function logic.statusHook(self, statusName, statusValue)
    local allPlayers = FindAllOf("PalPlayerController")
    for _, controller in pairs(allPlayers) do
        if controller and controller:IsValid() then
            local state = controller.PlayerState
            if state and state:IsValid() then
                local playerId = state:GetPlayerId()
                if playerId and commands.IsGodmodeEnabled(playerId) then
                    self:set(nil)
                    statusName:set(nil)
                    statusValue:set(nil)
                    return
                end
            end
        end
    end
end

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
        elseif cmd == "godmode" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.toggleGodmode(playerState, rest:lower())
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
        elseif cmd == 'time' then
            commands.handleCurrentTime(playerState)
        elseif cmd == "help" then
            commands.sendSystemAnnounce(PlayerController, "!give PlayerName item:amount | !exp PlayerName amount | !fly enable/disable | !noclip enable/disable | !godmode enable/disable | !spectate | !announce msg | !settime 0-23 | !giveme item:amount | !giveexp amount | !time | !unstuck")
        elseif cmd == "unstuck" then
            commands.handleUnstuck(playerState)
        end
    end
end

return logic
