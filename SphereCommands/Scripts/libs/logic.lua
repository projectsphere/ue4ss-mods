local commands = require("libs/commands")
local logic = {}

-- function logic.damageHook(context, damageBlock, defenderObject)
--     local Utility = StaticFindObject("/Script/Pal.Default__PalUtility")
--     local attackRecord = damageBlock and damageBlock:get()
--     if not attackRecord then return end

--     local sourceUnit = attackRecord.Attacker
--     local defenderCtrl = context and context:get()
--     local defenderState = defenderCtrl and defenderCtrl.PlayerState
--     if not sourceUnit or not sourceUnit:IsValid() or not defenderCtrl or not defenderCtrl:IsValid() or not defenderState or not defenderState:IsValid() then
--         return
--     end

--     local function isPlayerEntity(entity)
--         return entity and entity:IsValid() and entity.PlayerState and entity.PlayerState:IsValid()
--     end

--     local function isPal(entity)
--         return Utility and Utility:IsValid() 
--                and Utility:IsOtomo(entity) 
--                and Utility:GetTrainerPlayerController_ForServer(entity) ~= nil
--     end

--     local sourceIsPlayer = isPlayerEntity(sourceUnit)
--     local sourceIsPal = isPal(sourceUnit)
--     local sourceIsWild = (not sourceIsPlayer) and (not sourceIsPal)

--     pcall(function()
--         attackRecord.NoDamage = true
--         attackRecord.Damage = 0
--         attackRecord.NativeDamageValue = 0
--         attackRecord.EffectType1 = nil
--         attackRecord.EffectType2 = nil
--         attackRecord.BlowVelocity = { X = 0, Y = 0, Z = 0 }
--     end)

--     damageBlock:set(attackRecord)
-- end

function logic.healthHook(_, damageInfo)
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
        elseif cmd == "kick" then
            if not commands.IsPlayerAdmin(playerState) then
                commands.sendSystemAnnounce(PlayerController, "You do not have permission")
                return
            end
            commands.handleKick(playerState, rest)
        elseif cmd == 'time' then
            commands.handleCurrentTime(playerState)
        elseif cmd == "help" then
            commands.sendSystemAnnounce(PlayerController, "!give PlayerName item:amount | !exp PlayerName amount | !slay PlayerName | !kick PlayerName | !fly enable/disable | !noclip enable/disable | !godmode enable/disable | !spectate | !announce msg | !settime 0-23 | !giveme item:amount | !giveexp amount | !goto x,y,z | !time | !unstuck")
        elseif cmd == "unstuck" then
            commands.handleUnstuck(playerState)
        end
    end
end

return logic
