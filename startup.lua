local ok, kernelOrError = pcall(require, "sys.kernel")

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

if not ok then
    term.setTextColor(colors.red)
    print("NovaOS boot failed.")
    print()
    term.setTextColor(colors.orange)
    print(kernelOrError)
    print()
    term.setTextColor(colors.lightGray)
    print("Press any key to continue...")
    os.pullEvent("key")
    return
end

local okBoot, bootError = pcall(function()
    kernelOrError.boot()
end)

if not okBoot then
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.red)
    term.clear()
    term.setCursorPos(1, 1)

    print("NovaOS kernel panic.")
    print()
    term.setTextColor(colors.orange)
    print(bootError)
    print()
    term.setTextColor(colors.lightGray)
    print("Press any key to return to CraftOS shell...")
    os.pullEvent("key")
end
