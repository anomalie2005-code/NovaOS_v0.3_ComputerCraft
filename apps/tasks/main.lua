local TasksApp = dofile("apps/tasks/TasksApp.lua")

return {
    name = "Tasks",
    description = "System task viewer",

    run = function(ctx, args)
        local app = TasksApp.new(ctx, args or {})
        return app:run()
    end
}