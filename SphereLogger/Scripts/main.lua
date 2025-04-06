local config = require("config")
local Logger = {}
local palUtility = nil
local playerName = {}

local function GetPalUtility()
    if not palUtility or not palUtility:IsValid() then
        palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    end
end

local log_folder = "sphere"
os.execute("mkdir " .. log_folder)

local function GetCurrentTimestamp()
    return os.date("%d/%m/%Y %H:%M:%S")
end

local function LogToFile(filename, line)
    local fileHandler = io.open(log_folder .. "/" .. filename, "a")
    if fileHandler then
        fileHandler:write(string.format("[%s] %s\n", GetCurrentTimestamp(), line))
        fileHandler:close()
    end
end

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
    LogToFile("chatlog.txt", logLine)
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

    LogToFile("deaths.txt", deathMessage)

    if config.BroadcastDeaths and victimType == "Player" then
        SendAnnounce(context, deathMessage)
    end
end

function Logger.ConnectLogs(character)
    if character and character:IsValid() and character.PlayerState and character.PlayerState:IsValid() then
        local name = GetPlayerName(character.PlayerState)
        playerName[character:GetFullName()] = name

        local message = string.format("%s has connected.", name)
        LogToFile("connections.txt", message)

        if config.BroadcastConnects then
            SendAnnounce(character, message)
        end
    end
end

function Logger.DisconnectLogs(character)
    if character and character:IsValid() then
        local name = playerName[character:GetFullName()] or "Unknown"
        local message = string.format("%s has disconnected.", name)
        LogToFile("connections.txt", message)

        if config.BroadcastDisconnects then
            SendAnnounce(character, message)
        end

        playerName[character:GetFullName()] = nil
    end
end

function Logger.CaptureLogs()
    for _, player in ipairs(FindAllOf("PalPlayerCharacter") or {}) do
        if player and player:IsValid() and player.PlayerState and player.PlayerState:IsValid() then
            local name = player.PlayerState.PlayerNamePrivate:ToString()
            LogToFile("captures.txt", string.format("%s captured a Pal.", name))
            break
        end
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

RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", function(ctx, character)
    local player = ctx:get()
    Logger.ConnectLogs(player)
end)

RegisterHook("/Game/Pal/Blueprint/Character/Player/Female/BP_Player_Female.BP_Player_Female_C:ReceiveEndPlay", function(ctx)
    local player = ctx:get()
    Logger.DisconnectLogs(player)
end)

ExecuteWithDelay(3000, function()
    RegisterHook("/Game/Pal/Blueprint/Weapon/Other/NewPalSphere/BP_PalSphere_Body.BP_PalSphere_Body_C:CaptureSuccessEvent", function()
        Logger.CaptureLogs()
    end)
end)

return Logger