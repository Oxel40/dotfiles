-- Hyprland Lua config
-- https://wiki.hypr.land/Configuring/Start/


------------------
---- MONITORS ----
------------------

hl.monitor({ output = "",         mode = "highrr",  position = "auto", scale = "1", vrr = 2 })
hl.monitor({ output = "HDMI-A-1", mode = "highres", position = "auto", scale = "2", vrr = 2 })


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("dunst")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/waybar-runner.sh")
    hl.exec_cmd("1password --silent")
    hl.exec_cmd("wifi-manager")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("SSH_AUTH_SOCK",      "~/.1password/agent.sock")


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "se,us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.4,
        },
    },
})

-- Razer DeathAdder 2013 (appears as two devices)
hl.device({ name = "razer-razer-deathadder-2013",   sensitivity = -0.7 })
hl.device({ name = "razer-razer-deathadder-2013-1", sensitivity = -0.7 })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = 4,
        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        layout = "lua:aerospace",
    },

    decoration = {
        rounding = 3,

        shadow = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },

    group = {
        groupbar = {
            enabled   = true,
            height    = 20,
            font_size = 12,
            gradients = false,
        },
    },
})

hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "default" })


-----------------
---- LAYOUTS ----
-----------------

local aero = require("aerospace")
aero.setup()

hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
        new_on_top  = true,
    },
})


--------------------------
---- WORKSPACE RULES  ----
--------------------------

-- Smart gaps: no gaps/borders when only one tiled window is visible
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })

hl.window_rule({ name = "no-border-tv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
hl.window_rule({ name = "no-border-f1",  match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 })

-- Multi-monitor workspace placement
for i = 1, 6 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-3" })
end
hl.workspace_rule({ workspace = "7",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "8",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "9",  monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-1" })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Monocle layout toggle (global, flips between aerospace and monocle)
local monocle_active = false
local function toggle_monocle()
    if monocle_active then
        monocle_active = false
        hl.config({ general = { layout = "lua:aerospace" } })
    else
        monocle_active = true
        hl.config({ general = { layout = "monocle" } })
    end
end

-- Terminals & apps
hl.bind(mainMod .. " + SHIFT + S",      hl.dsp.exec_cmd("st"))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("GTK_IM_MODULE=simple ghostty"))
hl.bind(mainMod .. " + SHIFT + A",      hl.dsp.exec_cmd("alacritty"))
hl.bind(mainMod .. " + E",              hl.dsp.exec_cmd("nautilus"))

-- Launcher
hl.bind(mainMod .. " + D",     hl.dsp.exec_cmd("tofi_run_recent"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("tofi_run_recent"))

-- Window management
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(mainMod .. " + MINUS",     hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())

-- Monocle toggle
hl.bind(mainMod .. " + SHIFT + M", toggle_monocle)

-- Screenshots (moved off G to make room for groups)
hl.bind(mainMod .. " + Print",         hl.dsp.exec_cmd("grimblast save area"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("grimblast copy area"))

-- Groups
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.lock())

-- AeroSpace-style tree: focus / move / join-with (H/J/K/L or arrows)
local dirs = { H = "left", J = "down", K = "up", L = "right", left = "left", down = "down", up = "up", right = "right" }
for key, dir in pairs(dirs) do
    hl.bind(mainMod .. " + " .. key,              aero.cmd("focus " .. dir))
    hl.bind(mainMod .. " + SHIFT + " .. key,      aero.cmd("move " .. dir))
    hl.bind(mainMod .. " + CTRL + " .. key,       aero.cmd("join-with " .. dir))
end
hl.bind(mainMod .. " + TAB", hl.dsp.window.cycle_next())

-- Container layout (AeroSpace alt-slash / alt-comma)
hl.bind(mainMod .. " + period", aero.cmd("layout tiles horizontal vertical"))
hl.bind(mainMod .. " + comma",  aero.cmd("layout accordion horizontal vertical"))

-- Resize
hl.bind(mainMod .. " + ALT + H", aero.cmd("resize width -50"))
hl.bind(mainMod .. " + ALT + L", aero.cmd("resize width +50"))
hl.bind(mainMod .. " + ALT + J", aero.cmd("resize height -50"))
hl.bind(mainMod .. " + ALT + K", aero.cmd("resize height +50"))
hl.bind(mainMod .. " + SHIFT + B", aero.cmd("balance-sizes"))
hl.bind(mainMod .. " + SHIFT + R", aero.cmd("flatten-workspace-tree"))

-- Switch / move to workspaces 1-10 (key 0 = workspace 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- U/I/O/P aliases for workspaces 1-4
local uiop = { U = 1, I = 2, O = 3, P = 4 }
for key, ws in pairs(uiop) do
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = ws }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws }))
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%- && wpctl set-mute @DEFAULT_SINK@ 0"), { locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+ && wpctl set-mute @DEFAULT_SINK@ 0"), { locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),                                   { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("light -U 5"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("light -A 5"), { locked = true })
