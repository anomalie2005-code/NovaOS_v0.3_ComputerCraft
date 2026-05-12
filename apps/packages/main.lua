local PackagesApp = dofile("apps/packages/PackagesApp.lua")

return {
    name = "Packages",
    description = "Local NovaOS package manager",

    run = function(ctx, args)
        local app = PackagesApp.new(ctx, args or {})
        return app:run()
    end
}