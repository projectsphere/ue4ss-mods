local commands = require("libs/commands")
local commandHandlers = require("libs/handler")
local logic = {}

for k in pairs(commandHandlers) do
    print("Registered commands:", k)
end

function logic.chatHook(ctx, chat)
    local text = chat:get().Message:ToString()
    local state = ctx:get()
    local pc = state:GetPlayerController()

    local cmd, rest = text:match("^!(%S+)%s*(.*)$")
    if not cmd then
        return
    end

    cmd = cmd:lower()

    local entry = commandHandlers[cmd]
    if not entry then
        commands.sendSystemAnnounce(pc, "Unknown command. Type !help.")
        return
    end

    if entry.admin and not commands.IsPlayerAdmin(state) then
        commands.sendSystemAnnounce(pc, "You do not have permission.")
        return
    end

    entry.func(state, rest)
end

return logic
