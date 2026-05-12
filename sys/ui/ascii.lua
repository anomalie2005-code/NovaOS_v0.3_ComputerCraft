local Ascii = {}

Ascii.logos = {
    nova = {
        "        _   __                 ",
        "       / | / /___ _   ______ _ ",
        "      /  |/ / __ \\ | / / __ `/ ",
        "     / /|  / /_/ / |/ / /_/ /  ",
        "    /_/ |_/\\____/|___/\\__,_/   "
    },

    small = {
        " _   __              ",
        "/ | / /___ _   _____ ",
        "/  |/ / __ \\ | / / _ \\",
        "/ /|  / /_/ / |/ /  __/",
        "/_/ |_/\\____/|___/\\___/"
    }
}

function Ascii.getLogo(name)
    return Ascii.logos[name] or Ascii.logos.nova
end

return Ascii
