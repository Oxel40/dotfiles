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

        layout = "master",
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

-- Monocle layout toggle (global, flips between master and monocle)
local monocle_active = false
local function toggle_monocle()
    if monocle_active then
        monocle_active = false
        hl.config({ general = { layout = "master" } })
    else
        monocle_active = true
        hl.config({ general = { layout = "monocle" } })
    end
end

-- J: cycle forward through group; pop out to next tile at end of group
local function cycle_j()
    local win = hl.get_active_window()
    if win and win.group and win.group.size > 0 then
        if win.group.current_index < win.group.size then
            hl.dispatch(hl.dsp.group.next())
        else
            hl.dispatch(hl.dsp.window.cycle_next())
        end
    else
		hl.dispatch(hl.dsp.layout("cyclenext"))
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
end

-- K: cycle backward through group; pop out to prev tile at start of group
local function cycle_k()
    local win = hl.get_active_window()
    if win and win.group and win.group.size > 0 then
        if win.group.current_index > 1 then
            hl.dispatch(hl.dsp.group.prev())
        else
            hl.dispatch(hl.dsp.window.cycle_next("prev"))
        end
    else
		hl.dispatch(hl.dsp.layout("cycleprev"))
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
end

-- SHIFT+J/K: move active window into the next/prev group on the workspace
local function shift_j()
    hl.dispatch(hl.dsp.group.move_window(true))
end

local function shift_k()
    hl.dispatch(hl.dsp.group.move_window(false))
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

-- Master layout
hl.bind(mainMod .. " + RETURN", hl.dsp.layout("swapwithmaster"))
hl.bind(mainMod .. " + N",      hl.dsp.layout("addmaster"))
hl.bind(mainMod .. " + M",      hl.dsp.layout("removemaster"))

-- Focus movement (H/L always move between tiles; J/K are context-aware)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))
hl.bind(mainMod .. " + H",     hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + L",     hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + J",     cycle_j)
hl.bind(mainMod .. " + K",     cycle_k)
hl.bind(mainMod .. " + TAB",   hl.dsp.window.cycle_next())

-- Resize master area
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.layout("mfact -0.05"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.layout("mfact +0.05"))

-- Move window into next/prev group
hl.bind(mainMod .. " + SHIFT + J", shift_j)
hl.bind(mainMod .. " + SHIFT + K", shift_k)

-- Rotate master orientation (cycle forward only)
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.layout("orientationnext"))

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
