local LogsApp = dofile("apps/logs/LogsApp.lua")

return {
    name = "Logs",
    description = "Scrollable system log viewer",

    run = function(ctx, args)
        local app = LogsApp.new(ctx, args or {})
        return app:run()
    end
}