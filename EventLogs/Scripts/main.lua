local config = require("config")
local Logger = {}
local palUtility = nil
local playerName = {}

local function GetPalUtility()
    if not palUtility or not palUtility:IsValid() then
        palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    end
end

local log_folder = "eventlogs"
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

local function SendWebhook(url, message)
    if url and url ~= "" then
        local escaped = message:gsub('"', '\\"')
        local cmd = string.format(
            'curl -s -H "Content-Type: application/json" -X POST -d "{\\"content\\": \\"%s\\"}" "%s"',
            escaped, url
        )
        os.execute(cmd)
    end
end

function Logger.ChatLogs(playerState, chatMessage)
    local senderName = chatMessage.Sender:ToString()
    local category = chatMessage.Category
    local messageText = chatMessage.Message:ToString()
    local categoryText = "Undefined"

    if category == 1 then
        categoryText = "[Global]"
        if config.chatLogLevel < 1 then return end
    elseif category == 3 then
        categoryText = "[Say]"
        if config.chatLogLevel < 2 then return end
    elseif category == 2 then
        categoryText = "[Guild]"
        if config.chatLogLevel < 3 then return end
    else
        return
    end

    local logLine = string.format("%s %s: %s", categoryText, senderName, messageText)
    LogToFile("chatlog.txt", logLine)
    SendWebhook(config.chatWebhook, logLine)
end

function Logger.DeathLogs(deadInfo, context)
    GetPalUtility()
    if not (deadInfo and deadInfo.SelfActor and deadInfo.LastAttacker) then return end

    local victim = deadInfo.SelfActor
    local attacker = deadInfo.LastAttacker
    if not (victim:IsValid() and attacker:IsValid()) then return end

    if not (victim.PlayerState and victim.PlayerState:IsValid()) then return end
    local victimName = GetPlayerName(victim.PlayerState)
    if not victimName or victimName == "" then return end

    local attackerName = nil
    if palUtility:IsOtomo(attacker) then
        local owner = palUtility:GetOtomoPlayerCharacter(attacker)
        if owner and owner:IsValid() and owner.PlayerState and owner.PlayerState:IsValid() then
            attackerName = GetPlayerName(owner.PlayerState)
        end
    elseif attacker.PlayerState and attacker.PlayerState:IsValid() then
        attackerName = GetPlayerName(attacker.PlayerState)
    end
    if not attackerName or attackerName == "" then return end

    local deathMessage = ""
    if victimName == attackerName then
        deathMessage = string.format("%s committed suicide!", victimName)
    else
        deathMessage = string.format("%s was killed by %s", victimName, attackerName)
    end

    LogToFile("deaths.txt", deathMessage)
    SendWebhook(config.deathWebhook, deathMessage)

    if config.BroadcastDeaths and victim.PlayerState and victim.PlayerState:IsValid() then
        SendAnnounce(context, deathMessage)
    end
end

function Logger.ConnectLogs(character)
    if character and character:IsValid() and character.PlayerState and character.PlayerState:IsValid() then
        local name = GetPlayerName(character.PlayerState)
        playerName[character:GetFullName()] = name

        local message = string.format("%s has connected.", name)
        LogToFile("connections.txt", message)
        SendWebhook(config.connectionWebhook, message)

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
        SendWebhook(config.connectionWebhook, message)

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