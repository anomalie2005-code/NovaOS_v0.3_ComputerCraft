return {
    version = "0.3.0",

    files = {
        "startup.lua",

        -- apps/about
        "apps/about/main.lua",
        "apps/about/manifest.lua",

        -- apps/editor
        "apps/editor/EditorApp.lua",
        "apps/editor/EditorBuffer.lua",
        "apps/editor/EditorDialogs.lua",
        "apps/editor/EditorFile.lua",
        "apps/editor/EditorView.lua",
        "apps/editor/main.lua",
        "apps/editor/manifest.lua",

        -- apps/files
        "apps/files/FileActions.lua",
        "apps/files/FileDialogs.lua",
        "apps/files/FileHelp.lua",
        "apps/files/FileOperations.lua",
        "apps/files/FilePreview.lua",
        "apps/files/FilesApp.lua",
        "apps/files/FileScanner.lua",
        "apps/files/main.lua",
        "apps/files/manifest.lua",

        -- apps/launcher
        "apps/launcher/LauncherApp.lua",
        "apps/launcher/LauncherData.lua",
        "apps/launcher/LauncherView.lua",
        "apps/launcher/main.lua",
        "apps/launcher/manifest.lua",

        -- apps/logs
        "apps/logs/LogsApp.lua",
        "apps/logs/LogsData.lua",
        "apps/logs/LogsView.lua",
        "apps/logs/main.lua",
        "apps/logs/manifest.lua",

        -- apps/monitor
        "apps/monitor/main.lua",
        "apps/monitor/manifest.lua",
        "apps/monitor/MonitorApp.lua",
        "apps/monitor/MonitorData.lua",
        "apps/monitor/MonitorView.lua",

        -- apps/network
        "apps/network/main.lua",
        "apps/network/manifest.lua",
        "apps/network/NetworkApp.lua",
        "apps/network/NetworkData.lua",
        "apps/network/NetworkDialogs.lua",
        "apps/network/NetworkView.lua",

        -- apps/packages
        "apps/packages/main.lua",
        "apps/packages/manifest.lua",
        "apps/packages/PackageOperations.lua",
        "apps/packages/PackagesApp.lua",
        "apps/packages/PackagesData.lua",
        "apps/packages/PackagesView.lua",
        "apps/packages/PackageTemplate.lua",

        -- apps/settings
        "apps/settings/main.lua",
        "apps/settings/manifest.lua",
        "apps/settings/SettingsApp.lua",
        "apps/settings/SettingsStore.lua",
        "apps/settings/SettingsView.lua",
        "apps/settings/ThemeSelector.lua",

        -- apps/tasks
        "apps/tasks/main.lua",
        "apps/tasks/manifest.lua",
        "apps/tasks/TasksApp.lua",
        "apps/tasks/TasksData.lua",
        "apps/tasks/TasksView.lua",

        -- commands
        "commands/apps.lua",
        "commands/cat.lua",
        "commands/cd.lua",
        "commands/clear.lua",
        "commands/cp.lua",
        "commands/edit.lua",
        "commands/fetch.lua",
        "commands/help.lua",
        "commands/log.lua",
        "commands/ls.lua",
        "commands/mkdir.lua",
        "commands/mv.lua",
        "commands/open.lua",
        "commands/peripherals.lua",
        "commands/pkg.lua",
        "commands/pwd.lua",
        "commands/reboot.lua",
        "commands/reload.lua",
        "commands/rm.lua",
        "commands/run.lua",
        "commands/shutdown.lua",
        "commands/theme.lua",
        "commands/touch.lua",

        -- data, only portable settings
        "data/aliases.lua",
        "data/history.lua",
        "data/settings.lua",

        -- lib
        "lib/help_dialog.lua",
        "lib/path_utils.lua",
        "lib/string_utils.lua",
        "lib/table_utils.lua",
        "lib/utils.lua",

        -- sys
        "sys/app_manager.lua",
        "sys/autocomplete.lua",
        "sys/class.lua",
        "sys/command_parser.lua",
        "sys/command_registry.lua",
        "sys/config.lua",
        "sys/filesystem.lua",
        "sys/history.lua",
        "sys/kernel.lua",
        "sys/logger.lua",
        "sys/prompt.lua",
        "sys/terminal.lua",
        "sys/terminal_buffer.lua",
        "sys/terminal_input.lua",
        "sys/terminal_renderer.lua",
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
        "ui/status_bar.lua",
        "ui/table.lua"
    }
}
