local NetworkApp = dofile("apps/network/NetworkApp.lua")

return {
    name = "Network",
    description = "Rednet and modem network manager",

    run = function(ctx, args)
        local app = NetworkApp.new(ctx, args or {})
        return app:run()
    end
}