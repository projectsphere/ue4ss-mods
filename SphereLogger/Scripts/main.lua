local config = require("config")
local Logger = {}
local palUtility = nil

local function GetPalUtility()
    if not palUtility or not palUtility:IsValid() then
        palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    end
end

local log_folder = "sphere"
os.execute(string.format("mkdir %s", log_folder))

local function GetPlayerName(ps)
    if ps and ps:IsValid() and ps.PlayerNamePrivate and ps.PlayerNamePrivate.ToString then
        local success, name = pcall(function() return ps.PlayerNamePrivate:ToString() end)
        return success and name or "Unknown"
    end
    return "Unknown"
end

local function SendAnnounce(ctx, msg)
    GetPalUtility()
    if palUtility and palUtility:IsValid() then
        palUtility:SendSystemAnnounce(ctx, msg)
    end
end

local function GetEntityType(actor)
    GetPalUtility()
    if not actor then return "Undefined" end
    if palUtility:IsOtomo(actor) then
        return "Otomo"
    elseif type(actor.PlayerCameraYaw) == "number" then
        return "Player"
    elseif palUtility:IsBaseCampPal(actor) then
        return "BaseCampPal"
    elseif palUtility:IsPalMonster(actor) then
        return "WildPal"
    elseif palUtility:IsWildNPC(actor) then
        return "NPC"
    elseif actor.bIsPlayer then
        return "Player"
    else
        return "Unknown"
    end
end

local function GetEntityName(actor, entityType)
    if entityType == "Player" then
        return GetPlayerName(actor.PlayerState)
    elseif entityType == "Otomo" or entityType == "WildPal" or entityType == "BaseCampPal" then
        local charComp = actor.CharacterParameterComponent
        if charComp and charComp:IsValid() then
            local individualParam = charComp:GetIndividualParameter()
            if individualParam and individualParam:IsValid() then
                return individualParam:GetCharacterID():ToString()
            end
        end
        return "Pal"
    elseif entityType == "NPC" then
        return "NPC"
    else
        return "Unknown"
    end
end

function Logger.ChatLogs(playerState, chatMessage)
    local senderName = chatMessage.Sender:ToString()
    local category = chatMessage.Category
    local messageText = chatMessage.Message:ToString()
    local categoryText = "Undefined"
    if category == 1 then
        categoryText = "[Global]"
    elseif category == 2 then
        categoryText = "[Guild]"
    elseif category == 3 then
        categoryText = "[Say]"
    end
    local logLine = string.format("%s %s: %s", categoryText, senderName, messageText)
    local fileHandler = io.open("sphere/chatlog.txt", "a")
    if fileHandler then
        fileHandler:write(logLine .. "\n")
        fileHandler:close()
    end
end

function Logger.DeathLogs(deadInfo, context)
    GetPalUtility()
    local victim = deadInfo and deadInfo.SelfActor
    local attacker = deadInfo and deadInfo.LastAttacker
    if not (victim and attacker and victim:IsValid() and attacker:IsValid()) then 
        return 
    end
    local victimType = GetEntityType(victim)
    local attackerType = GetEntityType(attacker)
    local victimName = GetEntityName(victim, victimType)
    local attackerName = GetEntityName(attacker, attackerType)
    local deathMessage = ""

    if victimType == "Player" then
        if attackerType == "Player" and attackerName == victimName then
            deathMessage = string.format("%s committed suicide!", victimName)
        else
            deathMessage = string.format("%s was killed by %s (%s)", victimName, attackerName, attackerType)
        end
    else
        deathMessage = string.format("%s killed a %s (%s)", attackerName, victimName, victimType)
    end

    if config.BroadcastDeaths == true then
        SendAnnounce(context, deathMessage)
    end

    local fileHandler = io.open("sphere/deaths.txt", "a")
    if fileHandler then
        fileHandler:write(deathMessage .. "\n")
        fileHandler:close()
    end
end

RegisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", function(arg1, arg2)
    local playerState = arg1:get()
    local chatMessage = arg2:get()
    Logger.ChatLogs(playerState, chatMessage)
end)

RegisterHook("/Game/Pal/Blueprint/Component/DamageReaction/BP_AIADamageReaction.BP_AIADamageReaction_C:OnDead", function(arg1, arg2)
    local context = arg1:get()
    local deadInfo = arg2:get()
    Logger.DeathLogs(deadInfo, context)
end)

RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", function(ctx, char)
    local player = ctx:get()
    if player and player.PlayerState and player.PlayerState:IsValid() then
        local playerName = GetPlayerName(player.PlayerState)
        local connectMessage = string.format("%s has connected.", playerName)

        local fileHandler = io.open("sphere/connections.txt", "a")
        if fileHandler then
            fileHandler:write(connectMessage .. "\n")
            fileHandler:close()
        end

        if config.BroadcastConnects == true then
            SendAnnounce(player, connectMessage)
        end
    end
end)

RegisterHook("/Game/Pal/Blueprint/Character/Player/Female/BP_Player_Female.BP_Player_Female_C:ReceiveEndPlay", function(ctx)
    local controller = ctx:get()
    local playerState = controller and controller.PlayerState
    local playerName = playerState and GetPlayerName(playerState) or "Unknown"

    local disconnectMessage = string.format("%s has disconnected.", playerName)

    local fileHandler = io.open("sphere/connections.txt", "a")
    if fileHandler then
        fileHandler:write(disconnectMessage .. "\n")
        fileHandler:close()
    end

    if config.BroadcastDisconnects == true then
        SendAnnounce(controller, disconnectMessage)
    end
end)


return Logger