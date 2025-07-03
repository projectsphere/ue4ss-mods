local Json            = require("libs/json")
local KitConfig       = require("kit")
local FGuid           = require("libs/fguid")
local ModDirectory    = debug.getinfo(1, "S").source:match([[^@?(.*[\/])[^\/]-$]])
local PlayerDataFile  = ModDirectory .. "players.json"
AllPlayers = {}

local function EncodeJSON(data)
  return Json.encode(data)
end

local function SavePlayerData()
  local filtered = {}
  for playerName, playerData in pairs(AllPlayers) do
    filtered[playerName] = { ReceivedKit = playerData.ReceivedKit or false }
  end
  local file = io.open(PlayerDataFile, "w")
  if file then
    file:write(EncodeJSON(filtered))
    file:close()
  end
end

local function LoadPlayerData()
  local file = io.open(PlayerDataFile, "r")
  if not file then
    local newFile = io.open(PlayerDataFile, "w")
    if newFile then
      newFile:write("{}")
      newFile:close()
    end
    AllPlayers = {}
  else
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(Json.decode, content)
    if ok and type(data) == "table" then
      AllPlayers = data
    else
      AllPlayers = {}
    end
  end
  for name, data in pairs(AllPlayers) do
    data.ReceivedKit = data.ReceivedKit or false
  end
end

local function EnsurePlayerExists(playerName)
  if not AllPlayers[playerName] then
    AllPlayers[playerName] = { ReceivedKit = false }
    SavePlayerData()
  end
end

local function GetPlayerName(ps)
  if ps and ps:IsValid() and ps.PlayerNamePrivate then
    local ok, name = pcall(function() return ps.PlayerNamePrivate:ToString() end)
    if ok then
      return name
    end
  end
  return "Unknown"
end

local function SendSystemToPlayer(playerController, message)
  local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
  local world = FindFirstOf("World")
  local playerState = playerController.PlayerState
  local playerUid = playerState and playerState.PlayerUId
  if playerUid then
    local guid = FGuid.translate(playerUid)
    ExecuteWithDelay(100, function()
      palUtility:SendSystemToPlayerChat(world, message, guid)
    end)
  end
end

local function GiveStarterKitIfNeeded(playerName, ps)
  local playerData = AllPlayers[playerName]
  if KitConfig.enable and playerData and not playerData.ReceivedKit and ps and ps:IsValid() then
    local inv = ps:GetInventoryData()
    if inv and inv:IsValid() then
      for itemID, quantity in pairs(KitConfig.startingitems or {}) do
        inv:AddItem_ServerInternal(FName(itemID), quantity, false, 0)
      end
      playerData.ReceivedKit = true
      SavePlayerData()
    end
  end
end

RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", function(context, char)
  local playerChar = context:get()
  if playerChar and playerChar.PlayerState then
    local ps = playerChar.PlayerState
    local pName = GetPlayerName(ps)
    EnsurePlayerExists(pName)
    GiveStarterKitIfNeeded(pName, ps)
  end
end)

RegisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", function(ctx, chat)
  local text = chat:get().Message:ToString()
  local playerState = ctx:get()
  local controller = playerState:GetPlayerController()

  local cmd, rest = text:match("^!(%S+)%s*(.*)$")
  if not cmd then return end
  cmd = cmd:lower()

  if cmd == "kit" then
    if not controller.bAdmin then
      SendSystemToPlayer(controller, "You do not have permission")
      return
    end

    local targetName = rest
    local palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    local world = FindFirstOf("World")
    local playerList = palUtility:GetPlayerListDisplayMessages(world)
    local targetController = nil

    if playerList then
      for i = 1, #playerList do
        local info = playerList[i]:get():ToString()
        local name = info:match("^(.-),")
        if name == targetName then
          local playerChar = palUtility:GetPlayerCharacterByPlayerIndex(world, i - 1)
          if playerChar and playerChar:IsValid() then
            targetController = playerChar:GetPalPlayerController()
            break
          end
        end
      end
    end

    if not targetController then
      SendSystemToPlayer(controller, "Player not found")
      return
    end

    local targetState = targetController.PlayerState
    local name = GetPlayerName(targetState)
    EnsurePlayerExists(name)

    local inv = targetState:GetInventoryData()
    if inv and inv:IsValid() then
      for itemID, quantity in pairs(KitConfig.startingitems or {}) do
        inv:AddItem_ServerInternal(FName(itemID), quantity, false)
      end
      AllPlayers[name].ReceivedKit = true
      SavePlayerData()
      SendSystemToPlayer(controller, "Kit sent to " .. name)
    else
      SendSystemToPlayer(controller, "Failed to access target inventory.")
    end
  end
end)

LoadPlayerData()
print("[StarterKit] has been loaded successfully!")
