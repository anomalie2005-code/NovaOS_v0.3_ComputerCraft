local SettingsApp = dofile("apps/settings/SettingsApp.lua")

return {
    name = "Settings",
    description = "NovaOS settings",

    run = function(ctx, args)
        local app = SettingsApp.new(ctx, args or {})
        return app:run()
    end
}