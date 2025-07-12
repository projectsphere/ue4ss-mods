local config = {}

-- Broadcast events in the server chat.
config.BroadcastDeaths = false
config.BroadcastConnects = false
config.BroadcastDisconnects = false
-- 1 = Global, 2 = Global + Say, 3 = All
config.chatLogLevel = 1
-- Webhook Configuration
config.chatWebhook = ""
config.deathWebhook = ""
config.connectionWebhook = ""

return config