local Config = require("sys.config")
local Theme = require("sys.theme")
local Logger = require("sys.logger")
local Screen = require("sys.ui.screen")
local Box = require("sys.ui.box")
local List = require("sys.ui.list")
local StatusBar = require("sys.ui.status_bar")
local TableView = require("sys.ui.table")
local Input = require("sys.ui.input")
local FileSystem = require("sys.filesystem")
local History = require("sys.history")
local Autocomplete = require("sys.autocomplete")
local CommandRegistry = require("sys.command_registry")
local AppManager = require("sys.app_manager")
local Prompt = require("sys.prompt")
local Terminal = require("sys.terminal")
local PeripheralService = require("sys.services.peripheral_service")
local RednetService = require("sys.services.rednet_service")
local TaskService = require("sys.services.task_service")

local Kernel = {}

function Kernel.ensureFolders()
    local folders = {
        "sys",
        "sys/ui",
        "sys/services",
        "commands",
        "apps",
        "data",
        "data/logs",
        "home",
        "home/user",
        "lib"
    }

    for _, folder in ipairs(folders) do
        if not fs.exists(folder) then
            fs.makeDir(folder)
        end
    end
end

function Kernel.boot()
    Kernel.ensureFolders()

    local config = Config.load()
    local theme = Theme.get(config.theme)
    local logger = Logger:new("data/logs/system.log")
    local screen = Screen:new(term.current())
    local filesystem = FileSystem:new(config.homeDir)
    local history = History:new("data/history.lua")
    local autocomplete = Autocomplete:new()
    local registry = CommandRegistry:new("commands")

    local ctx = {
        config = config,
        theme = theme,
        logger = logger,
        screen = screen,
        filesystem = filesystem,
        history = history,
        autocomplete = autocomplete,
        registry = registry,
        kernel = Kernel,

        ui = {
            Box = Box,
            List = List,
            StatusBar = StatusBar,
            Table = TableView,
            Input = Input
        },

        services = {
            peripherals = PeripheralService.new(),
            rednet = RednetService.new(),
            tasks = TaskService.new()
        }
    }

    local appManager = AppManager:new(ctx, "apps")
    local prompt = Prompt:new()

    ctx.appManager = appManager
    ctx.prompt = prompt

    ctx.services.tasks:create("NovaShell", "system", "running")

    screen:clear(theme.background, theme.text)
    screen:centerText(3, config.systemName, theme.accent)
    screen:centerText(5, "loading terminal environment...", theme.muted)

    logger:info("Boot started")

    registry:load(ctx)

    logger:info("Commands loaded")
    logger:info("Boot completed")

    sleep(0.3)

    local terminal = Terminal:new(ctx)
    ctx.terminal = terminal

    terminal:run()
end

return Kernel