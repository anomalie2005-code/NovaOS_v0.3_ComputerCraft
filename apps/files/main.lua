local FilesApp = dofile("apps/files/FilesApp.lua")

return {
    name = "Files",
    description = "Terminal file manager",

    run = function(ctx, args)
        local app = FilesApp.new(ctx, args or {})
        return app:run()
    end
}