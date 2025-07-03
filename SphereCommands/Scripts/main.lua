local logic     = require("libs/logic")
RegisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", logic.chatHook)