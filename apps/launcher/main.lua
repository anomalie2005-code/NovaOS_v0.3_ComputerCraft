local LauncherApp = dofile("apps/launcher/LauncherApp.lua")

return {
    name = "Launcher",
    description = "Application launcher",

    run = function(ctx, args)
        local app = LauncherApp.new(ctx, args or {})
        return app:run()
    end
}