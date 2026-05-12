local MonitorApp = dofile("apps/monitor/MonitorApp.lua")

return {
    name = "Monitor",
    description = "System and peripheral monitor",

    run = function(ctx, args)
        local app = MonitorApp.new(ctx, args or {})
        return app:run()
    end
}