local EditorApp = dofile("apps/editor/EditorApp.lua")

return {
    name = "Editor",
    description = "Advanced compact text editor",

    run = function(ctx, args)
        local app = EditorApp.new(ctx, args or {})
        return app:run()
    end
}