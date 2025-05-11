local PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
local logMgr = FindFirstOf("BP_PalLogManager_C")
local FGuid = require("util/fguid")

local godmodePlayers = {}
local noclipPlayers = {}
local flyModePlayers = {}

local commands = {}

function commands.sendSystemAnnounce(PalPlayerController, Message)
	ExecuteWithDelay(100, function()
		local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
		local world = FindFirstOf("World")
		local playerState = PalPlayerController.PlayerState
		local playerUid = FGuid.translate(playerState.PlayerUId)
		palUtility:SendSystemToPlayerChat(world, Message, playerUid)
	end)
end

function commands.sendPersonalLog(playerController, msg)
    if playerController and playerController:IsValid() and logMgr then
        playerController:SendLog_ToClient(1, FText(msg), {})
    end
end

function commands.findPlayerControllerByName(name)
	local allPlayers = FindAllOf("PalPlayerController")
	for _, pc in ipairs(allPlayers) do
		if pc and pc:IsValid() then
			local state = pc.PlayerState
			if state and state:IsValid() then
				if state.PlayerNamePrivate:ToString() == name then
					return pc
				end
			end
		end
	end
end

function commands.IsServerSide()
    return PalUtilities and PalUtilities:IsValid() and PalUtilities:IsDedicatedServer(PalUtilities)
end

function commands.spawnItem(playerState, item)
    local quantity = 1
    if string.find(item, ":") then
        item, quantity = string.match(item, "(.*):(.*)")
    end

    local inventory = playerState:GetInventoryData()
    if commands.IsServerSide() then
        inventory:AddItem_ServerInternal(FName(item), quantity, false)
    else
        inventory:RequestAddItem(FName(item), quantity, false)
    end
end

function commands.giveExperience(playerState, quantity)
    local PlayerController = playerState:GetPlayerController()
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

function commands.IsPlayerAdmin(playerState)
    return playerState and playerState:IsValid() and playerState:GetPlayerController().bAdmin
end

function commands.BroadcastServerMessage(message)
    local gameStateInstance = FindFirstOf("PalGameStateInGame")
    if gameStateInstance and gameStateInstance:IsValid() then
        gameStateInstance:BroadcastServerNotice(message)
    end
end

function commands.IsGodmodeEnabled(playerId)
    return godmodePlayers[playerId] == true
end

function commands.toggleGodmode(playerState, arg)
    local playerId = playerState:GetPlayerId()
    if not playerId then return end
    local PlayerController = playerState:GetPlayerController()

    if arg == "enable" then
        godmodePlayers[playerId] = true
        commands.sendSystemAnnounce(PlayerController, "Godmode enabled.")
    elseif arg == "disable" then
        godmodePlayers[playerId] = nil
        commands.sendSystemAnnounce(PlayerController, "Godmode disabled.")
    else
        commands.sendSystemAnnounce(PlayerController, "Usage: !godmode enable | disable")
    end
end

function commands.toggleFlyMode(playerState, arg)
    local playerId = playerState:GetPlayerId()
    if not playerId then return end
    local PlayerController = playerState:GetPlayerController()
    if not PlayerController or not PlayerController:IsValid() then return end

    if arg == "enable" then
        if not flyModePlayers[playerId] then
            flyModePlayers[playerId] = true
            PlayerController:StartFlyToServer()
            commands.sendSystemAnnounce(PlayerController, "Fly mode has been activated.")
        else
            commands.sendSystemAnnounce(PlayerController, "Fly mode is already enabled.")
        end
    elseif arg == "disable" then
        if flyModePlayers[playerId] then
            flyModePlayers[playerId] = nil
            PlayerController:EndFlyToServer()
            commands.sendSystemAnnounce(PlayerController, "Fly mode has been deactivated.")
        else
            commands.sendSystemAnnounce(PlayerController, "Fly mode is already disabled.")
        end
    else
        commands.sendSystemAnnounce(PlayerController, "Usage: !fly enable | disable")
    end
end

function commands.toggleNoclip(playerState, arg)
    local playerId = playerState:GetPlayerId()
    if not playerId then return end
    local PlayerController = playerState:GetPlayerController()
    if not PlayerController or not PlayerController:IsValid() then return end

    local PlayerCharacter = PlayerController.Pawn
    if not PlayerCharacter or not PlayerCharacter:IsValid() then return end

    if arg == "enable" then
        if not noclipPlayers[playerId] then
            noclipPlayers[playerId] = true
            PlayerCharacter:SetSpectatorMode(true)
            commands.sendSystemAnnounce(PlayerController, "Entered noclip mode.")
        else
            commands.sendSystemAnnounce(PlayerController, "Noclip mode is already enabled.")
        end
    elseif arg == "disable" then
        if noclipPlayers[playerId] then
            noclipPlayers[playerId] = nil
            PlayerCharacter:SetSpectatorMode(false)
            commands.sendSystemAnnounce(PlayerController, "Left noclip mode.")
        else
            commands.sendSystemAnnounce(PlayerController, "Noclip mode is already disabled.")
        end
    else
        commands.sendSystemAnnounce(PlayerController, "Usage: !noclip enable | disable")
    end
end

function commands.handleGiveCommand(playerState, rest)
	local senderController = playerState:GetPlayerController()
	if not rest or rest == "" then
		commands.sendSystemAnnounce(senderController, "Usage: !give <name> item:amount item2:amount")
		return
	end

	local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
	local world = FindFirstOf("World")
	local playerList = palUtility:GetPlayerListDisplayMessages(world)
	local targetController = nil
	local targetName = nil
	local remaining = nil

	if playerList then
		for i = 1, #playerList do
			local info = playerList[i]:get():ToString()
			local name = info:match("^(.-),")
			if name and rest:sub(1, #name) == name and rest:sub(#name + 1, #name + 1) == " " then
				targetName = name
				remaining = rest:sub(#name + 2)
				local playerChar = palUtility:GetPlayerCharacterByPlayerIndex(world, i - 1)
				if playerChar and playerChar:IsValid() then
					targetController = playerChar:GetPalPlayerController()
				end
				break
			end
		end
	end

	if not targetController or not remaining then
		commands.sendSystemAnnounce(senderController, "Player not found.")
		return
	end

	local targetState = targetController.PlayerState
	for item in remaining:gmatch("%S+") do
		local name = item
		local qty = 1
		if item:find(":") then
			name, qty = string.match(item, "^(.*):(%d+)$")
			qty = tonumber(qty) or 1
		end

		commands.spawnItem(targetState, item)
		commands.sendSystemAnnounce(senderController, string.format("Gave %d x %s to %s", qty, name, targetName))
	end
end

function commands.handleExpCommand(playerState, rest)
	local senderController = playerState:GetPlayerController()
	if not rest or rest == "" then
		commands.sendSystemAnnounce(senderController, "Usage: !exp <name> <amount>")
		return
	end

	local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
	local world = FindFirstOf("World")
	local playerList = palUtility:GetPlayerListDisplayMessages(world)
	local targetController = nil
	local targetName = nil
	local remaining = nil

	if playerList then
		for i = 1, #playerList do
			local info = playerList[i]:get():ToString()
			local name = info:match("^(.-),")
			if name and rest:sub(1, #name) == name and rest:sub(#name + 1, #name + 1) == " " then
				targetName = name
				remaining = rest:sub(#name + 2)
				local playerChar = palUtility:GetPlayerCharacterByPlayerIndex(world, i - 1)
				if playerChar and playerChar:IsValid() then
					targetController = playerChar:GetPalPlayerController()
				end
				break
			end
		end
	end

	if not targetController or not remaining then
		commands.sendSystemAnnounce(senderController, "Player not found.")
		return
	end

	local amount = tonumber(remaining)
	if not amount then
		commands.sendSystemAnnounce(senderController, "Invalid amount.")
		return
	end

	local targetState = targetController.PlayerState
	commands.giveExperience(targetState, amount)
	commands.sendSystemAnnounce(senderController, string.format("Granted %d EXP to %s", amount, targetName))
end

function commands.handlePersonalGive(playerState, rest)
	local PlayerController = playerState:GetPlayerController()
	if not rest or rest == "" then
		commands.sendSystemAnnounce(PlayerController, "Usage: !give item:amount item2:amount")
		return
	end

	for item in rest:gmatch("%S+") do
		local name = item
		local qty = 1
		if string.find(item, ":") then
			name, qty = string.match(item, "^(.*):(%d+)$")
			qty = tonumber(qty) or 1
		end
		commands.spawnItem(playerState, item)
		commands.sendSystemAnnounce(PlayerController, string.format("Spawned %d x %s", qty, name))
	end
end

function commands.handlePersonalExp(playerState, rest)
	local PlayerController = playerState:GetPlayerController()
	local amount = tonumber(rest)
	if not amount then
		commands.sendSystemAnnounce(PlayerController, "Usage: !giveexp <amount>")
		return
	end
	commands.giveExperience(playerState, amount)
	commands.sendSystemAnnounce(PlayerController, string.format("Granted %d EXP to your party.", amount))
end

function commands.handleSpectate(playerState)
    local PlayerController = playerState:GetPlayerController()
    if PlayerController and PlayerController:IsValid() then
        PlayerController:ClientBeginSpectate(true)
        commands.sendSystemAnnounce(PlayerController, "Entered spectator mode.")
    end
end

function commands.handleAnnounce(playerState, rest)
    local PlayerController = playerState:GetPlayerController()
    if not rest or rest == "" then
        commands.sendSystemAnnounce(PlayerController, "Usage: !announce <message>")
        return
    end
    commands.BroadcastServerMessage(rest)
    commands.sendSystemAnnounce(PlayerController, "Announced server wide message.")
end

function commands.handleUnstuck(playerState)
    local PlayerController = playerState:GetPlayerController()
    if PlayerController and PlayerController:IsValid() then
        PlayerController:TeleportToSafePoint_ToServer()
        commands.sendSystemAnnounce(PlayerController, "You have been teleported back to base!")
    end
end

function commands.handleTime(playerState, rest)
	local PlayerController = playerState:GetPlayerController()
	if not rest or rest == "" then
		commands.sendSystemAnnounce(PlayerController, "Usage: !time <hour>")
		return
	end

	local hour = tonumber(rest)
	if not hour or hour < 0 or hour > 23 then
		commands.sendSystemAnnounce(PlayerController, "Invalid hour. Must be between 0 and 23.")
		return
	end

	local timeManager = FindFirstOf("PalTimeManager")
	if not timeManager or not timeManager:IsValid() then
		commands.sendSystemAnnounce(PlayerController, "PalTimeManager not found.")
		return
	end

	timeManager:SetGameTime_FixDay(hour)
	local timeStr = timeManager:GetDebugTimeString():ToString()
	commands.sendSystemAnnounce(PlayerController, "Game time set. Current time: " .. timeStr)
end

function commands.handleCurrentTime(playerState)
	local PlayerController = playerState:GetPlayerController()
	local timeManager = FindFirstOf("PalTimeManager")
	if not timeManager or not timeManager:IsValid() then
		commands.sendSystemAnnounce(PlayerController, "PalTimeManager not found.")
		return
	end

	local timeStr = timeManager:GetDebugTimeString():ToString()
	commands.sendSystemAnnounce(PlayerController, "Current Game Time: " .. timeStr)
end

function commands.handleSlay(playerState, rest)
	local PlayerController = playerState:GetPlayerController()
	if not rest or rest == "" then
		commands.sendSystemAnnounce(PlayerController, "Usage: !slay <name>")
		return
	end

	local targetName = rest:lower()
	for _, state in ipairs(FindAllOf("PalPlayerState") or {}) do
		if state and state:IsValid() then
			local name = state.PlayerNamePrivate:ToString():lower()
			if name == targetName then
				local controller = state:GetPlayerController()
				if controller and controller:IsValid() then
					controller:SelfKillPlayer()
					commands.sendSystemAnnounce(PlayerController, rest .. " has been killed.")
				else
					commands.sendSystemAnnounce(PlayerController, "Could not find valid controller.")
				end
				return
			end
		end
	end

	commands.sendSystemAnnounce(PlayerController, "Player not found.")
end

function commands.handleGoto(playerState, rest)
    local PlayerController = playerState:GetPlayerController()
    local Character = PlayerController and PlayerController.Pawn
    if not Character or not Character:IsValid() then return end

    if rest and rest:find(",") then
        local x, y, z = rest:match("([^,]+),([^,]+),([^,]+)")
        if x and y and z then
            local vec = { X = tonumber(x), Y = tonumber(y), Z = tonumber(z) + 500 }
            local quat = { X = 0, Y = 0, Z = 0, W = 0 }
            local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
            palUtility:TeleportAroundLoccation(Character, vec, quat)
            commands.sendSystemAnnounce(PlayerController, string.format("Teleported to [%s, %s, %s]", x, y, z))
        else
            commands.sendSystemAnnounce(PlayerController, "Invalid format. Use: !goto x,y,z")
        end
    else
        commands.sendSystemAnnounce(PlayerController, "Usage: !goto x,y,z")
    end
end

-- Thanks Mathayus for this kick method
function commands.handleKick(playerState, rest)
    local PlayerController = playerState:GetPlayerController()
    if not rest or rest == "" then
        commands.sendSystemAnnounce(PlayerController, "Usage: !kick <name>")
        return
    end

    local targetName = rest:lower()
    for _, state in ipairs(FindAllOf("PalPlayerState") or {}) do
        if state and state:IsValid() then
            local name = state.PlayerNamePrivate:ToString()
            if name and name:lower() == targetName then
                local controller = state:GetPlayerController()
                if controller and controller:IsValid() then
                    controller:ClientTravelInternal("Void", 0, false, nil)
                    commands.sendSystemAnnounce(PlayerController, "Player " .. name .. " has been kicked.")
                else
                    commands.sendSystemAnnounce(PlayerController, "Could not find valid controller.")
                end
                return
            end
        end
    end

    commands.sendSystemAnnounce(PlayerController, "Player not found.")
end

return commands
