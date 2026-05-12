return {
    version = "0.1.0",

    files = {
        "startup.lua",

        -- apps
        "apps/about/main.lua",
        "apps/editor/main.lua",
        "apps/files/main.lua",
        "apps/monitor/main.lua",
        "apps/settings/main.lua",

        -- commands
        "commands/apps.lua",
        "commands/cat.lua",
        "commands/cd.lua",
        "commands/clear.lua",
        "commands/fetch.lua",
        "commands/help.lua",
        "commands/log.lua",
        "commands/ls.lua",
        "commands/open.lua",
        "commands/peripherals.lua",
        "commands/pwd.lua",
        "commands/reboot.lua",
        "commands/run.lua",
        "commands/shutdown.lua",
        "commands/theme.lua",

        -- data
        "data/aliases.lua",
        "data/history.lua",
        "data/settings.lua",

        -- home
        "home/user/readme.txt",

        -- lib
        "lib/path_utils.lua",
        "lib/string_utils.lua",
        "lib/table_utils.lua",
        "lib/utils.lua",

        -- sys
        "sys/app_manager.lua",
        "sys/autocomplete.lua",
        "sys/class.lua",
        "sys/command_registry.lua",
        "sys/config.lua",
        "sys/filesystem.lua",
        "sys/history.lua",
        "sys/kernel.lua",
        "sys/logger.lua",
        "sys/prompt.lua",
        "sys/terminal.lua",
        "sys/theme.lua",

        -- sys/services
        "sys/services/peripheral_service.lua",
        "sys/services/rednet_service.lua",
        "sys/services/system_info.lua",
        "sys/services/task_service.lua",

        -- ui
        "ui/ascii.lua",
        "ui/box.lua",
        "ui/input.lua",
        "ui/list.lua",
        "ui/screen.lua",
        "ui/status_bar.lua"
    }
}
