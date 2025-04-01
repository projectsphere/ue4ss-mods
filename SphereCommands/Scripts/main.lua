local UEHelpers = require("UEHelpers")
local logMgr = FindFirstOf("BP_PalLogManager_C")

local godmodePlayers = {}
local noclipPlayers = {}
local flyModePlayers = {}

local function sendPersonalLog(playerController, msg)
    if playerController and playerController:IsValid() and logMgr then
        playerController:SendLog_ToClient(1, FText(msg), {})
    end
end

local function IsServerSide()
    local PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
    return PalUtilities and PalUtilities:IsValid() and PalUtilities:IsDedicatedServer(PalUtilities)
end

local function spawnItem(playerState, item)
    local quantity = 1
    if string.find(item, ":") then
        item, quantity = string.match(item, "(.*):(.*)")
    end

    local inventory = playerState:GetInventoryData()
    if IsServerSide() then
        inventory:AddItem_ServerInternal(FName(item), quantity, false)
    else
        inventory:RequestAddItem(FName(item), quantity, false)
    end
end

local function giveExperience(PlayerState, quantity)
    local PlayerController = PlayerState:GetPlayerController()
    local PlayerCharacter = PlayerController and PlayerController.Pawn
    if not PlayerCharacter or not PlayerCharacter:IsValid() then return end

    local WorldContext = PlayerCharacter:GetWorld()
    if not WorldContext or not WorldContext:IsValid() then return end

    local Location = PlayerCharacter:K2_GetActorLocation()
    local ExpRadius = 1000.0

    local PalUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    if not PalUtility or not PalUtility:IsValid() then return end

    PalUtility:GiveExpToAroundPlayerCharacter(WorldContext, Location, ExpRadius, quantity, true)
end

local function IsPlayerAdmin(playerState)
    return playerState and playerState:IsValid() and playerState:GetPlayerController().bAdmin
end

local function BroadcastServerMessage(message)
    local gameStateInstance = FindFirstOf("PalGameStateInGame")
    if gameStateInstance and gameStateInstance:IsValid() then
        gameStateInstance:BroadcastServerNotice(message)
    end
end

local function IsGodmodeEnabled(playerId)
    return godmodePlayers[playerId] == true
end

RegisterHook("/Script/Pal.PalDamageReactionComponent:ApplyDamageForHP", function(_, damageInfo)
    local result = damageInfo:get()
    if not result then return end

    local defender = result.Defender
    if not defender or not defender:IsValid() then return end

    local state = defender.PlayerState
    if not state or not state:IsValid() then return end

    local playerId = state:GetPlayerId()
    if IsGodmodeEnabled(playerId) then
        result.Damage = 0
    end
end)

RegisterHook("/Script/Pal.PalStatusComponent:AddStatus_ToServer", function(self, statusName, statusValue)
    local allPlayers = FindAllOf("PalPlayerController")
    for _, controller in pairs(allPlayers) do
        if controller and controller:IsValid() then
            local state = controller.PlayerState
            if state and state:IsValid() then
                local playerId = state:GetPlayerId()
                if playerId and IsGodmodeEnabled(playerId) then
                    self:set(nil)
                    statusName:set(nil)
                    statusValue:set(nil)
                    return
                end
            end
        end
    end
end)

RegisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", function(ctx, chat)
    local text = chat:get().Message:ToString()
    local playerState = ctx:get()
    local PlayerController = playerState:GetPlayerController()
    
    local command, rest = text:match("^/(%S+)%s*(.*)$")
    if command then
        command = command:lower()

        if command == "sspectate" then
            if not IsPlayerAdmin(playerState) then
                sendPersonalLog(PlayerController, "You do not have permission")
                return
            end
            if PlayerController and PlayerController:IsValid() then
                PlayerController:ClientBeginSpectate(true)
                sendPersonalLog(PlayerController, "Entered spectator mode.")
            end

        elseif command == "sannounce" then
            if not IsPlayerAdmin(playerState) then
                sendPersonalLog(PlayerController, "You do not have permission")
                return
            end

            if not rest or rest == "" then
                sendPersonalLog(PlayerController, "Usage: /sannounce <message>")
                return
            end

            BroadcastServerMessage(rest)
            sendPersonalLog(PlayerController, "Announced server wide message.")

        elseif command == "sgodmode" then
            if not IsPlayerAdmin(playerState) then
                sendPersonalLog(PlayerController, "You do not have permission")
                return
            end

            local playerId = playerState:GetPlayerId()
            if not playerId then return end

            if godmodePlayers[playerId] then
                godmodePlayers[playerId] = nil
                sendPersonalLog(PlayerController, "Godmode disabled.")
            else
                godmodePlayers[playerId] = true
                sendPersonalLog(PlayerController, "Godmode enabled.")
            end

        elseif command == "sfly" then
            if not IsPlayerAdmin(playerState) then
                sendPersonalLog(PlayerController, "You do not have permission")
                return
            end

            local playerId = playerState:GetPlayerId()
            if not playerId then return end

            if PlayerController and PlayerController:IsValid() then
                if flyModePlayers[playerId] then
                    flyModePlayers[playerId] = nil
                    PlayerController:EndFlyToServer()
                    sendPersonalLog(PlayerController, "Fly mode has been deactivated.")
                else
                    flyModePlayers[playerId] = true
                    PlayerController:StartFlyToServer()
                    sendPersonalLog(PlayerController, "Fly mode has been activated.")
                end
            end

        elseif command == "snoclip" then
            if not IsPlayerAdmin(playerState) then
                sendPersonalLog(PlayerController, "You do not have permission")
                return
            end

            local playerId = playerState:GetPlayerId()
            if not playerId then return end

            local PlayerCharacter = FindFirstOf("PalPlayerCharacter")
            if not PlayerCharacter or not PlayerCharacter:IsValid() then return end

            if noclipPlayers[playerId] then
                noclipPlayers[playerId] = nil
                PlayerCharacter:SetSpectatorMode(false)
                sendPersonalLog(PlayerController, "Left noclip mode.")
            else
                noclipPlayers[playerId] = true
                PlayerCharacter:SetSpectatorMode(true)
                sendPersonalLog(PlayerController, "Entered noclip mode.")
            end

        elseif command == "sgive" then
            if not IsPlayerAdmin(playerState) then
                sendPersonalLog(PlayerController, "You do not have permission")
                return
            end

            if not rest or rest == "" then
                sendPersonalLog(PlayerController, "Usage: /sgive item[:amount] [item2[:amount] ...]")
                return
            end

            for item in rest:gmatch("%S+") do
                spawnItem(playerState, item)
            end

        elseif command == "sexp" then
            if not IsPlayerAdmin(playerState) then
                sendPersonalLog(PlayerController, "You do not have permission")
                return
            end

            local amount = tonumber(rest)
            if not amount then
                sendPersonalLog(PlayerController, "Usage: /sexp <amount>")
                return
            end

            giveExperience(playerState, amount)
            sendPersonalLog(PlayerController, string.format("Granted %d EXP to your party.", amount))

        elseif command == "unstuck" then
            if PlayerController and PlayerController:IsValid() then
                PlayerController:TeleportToSafePoint_ToServer()
                sendPersonalLog(PlayerController, "You have been teleported back to base!")
            end
        end
    end
end)