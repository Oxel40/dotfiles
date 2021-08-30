from libqtile.config import Key, Screen, Group, Drag, Click
from libqtile.lazy import lazy
from libqtile import layout, bar, widget
from libqtile.widget import backlight
from libqtile.widget import base

from typing import List  # noqa: F401

import subprocess

# Vars
mod = 'mod4'
my_terminal = 'alacritty'
my_terminal_exec = '-e'
# my_wallpaper = '/home/erikp/Pictures/Wallpapers/risk.png'
my_wallpaper = '/home/erikp/Pictures/Wallpapers/wall.gif'

# Start compositor
subprocess.Popen(['picom'])

# Start gestures
subprocess.Popen(['libinput-gestures'])

# Set background
subprocess.Popen(['feh', '--bg-scale', my_wallpaper])

# Start screenlocker
subprocess.Popen(['xset', 's', '180', '5'])
subprocess.Popen(
    ['xss-lock', '-n', '/usr/lib/xsecurelock/dimmer', '-l', '--', 'xsecurelock'])

# Start ssh-agent
# subprocess.Popen(['eval', '$(ssh-agent)'])


# Costom widgets to be used in the bar
#
# Screen Brightness
class Brightness(base.InLoopPollText):

    def __init__(self, **config):
        self.max_brightness = self.get_max_brightness()
        base.InLoopPollText.__init__(self, **config)

    def get_curent_brightness(self):
        with open('/sys/class/backlight/intel_backlight/brightness', 'r') as f:
            return int(f.read())

    def get_max_brightness(self):
        with open('/sys/class/backlight/intel_backlight/max_brightness', 'r') as f:
            return int(f.read())

    def poll(self):
        current_brightness = self.get_curent_brightness()
        return "{}%".format(round(current_brightness * 100 / self.max_brightness))


keys = [
    # Switch between windows in current stack pane
    Key([mod], 'k', lazy.layout.down()),
    Key([mod], 'j', lazy.layout.up()),

    # Move windows up or down in current stack
    Key([mod, 'control'], 'k', lazy.layout.shuffle_down()),
    Key([mod, 'control'], 'j', lazy.layout.shuffle_up()),

    # Switch window focus to other pane(s) of stack
    Key([mod], 'space', lazy.layout.next()),

    # Swap panes of split stack
    Key([mod, 'shift'], 'space', lazy.layout.rotate()),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key([mod, 'shift'], 'Return', lazy.layout.toggle_split()),
    Key([mod], 'Return', lazy.spawn(my_terminal)),

    # Toggle between different layouts as defined below
    Key([mod], 'Tab', lazy.next_layout()),
    Key([mod], 'w', lazy.window.kill()),
    Key([mod], 'x', lazy.window.kill()),

    Key([mod, 'control'], 'r', lazy.restart()),
    Key([mod, 'control'], 'q', lazy.shutdown()),
    Key([mod], 'r', lazy.spawncmd()),

    # Custom keybindings
    Key([mod, 'control'], 'Return', lazy.layout.client_to_next()),

    Key([mod, 'control'], 'l', lazy.spawn('xsecurelock')),
    Key([mod], 'd', lazy.spawn('rofi -show run')),
    Key([mod], 'f', lazy.spawn('rofi -show window')),

    Key([], 'XF86AudioMute', lazy.spawn('amixer -q set Master toggle')),
    Key([], 'XF86AudioLowerVolume', lazy.spawn('amixer sset Master 5%- unmute')),
    Key([], 'XF86AudioRaiseVolume', lazy.spawn('amixer sset Master 5%+ unmute')),

    Key([], 'XF86MonBrightnessUp', lazy.spawn(
        'bash -c "if [[ 1 -eq $(echo \\"$(xbacklight -get) < 5\\" | bc) ]]; then xbacklight -set 5; else xbacklight -inc 5; fi"')),
    Key([], 'XF86MonBrightnessDown', lazy.spawn(
        'bash -c "if [[ 1 -eq $(echo \\"$(xbacklight -get) <= 5\\" | bc) ]]; then xbacklight -set 1; else xbacklight -dec 5; fi"')),
]

groups = [Group(i) for i in 'uiop']

for i in groups:
    keys.extend([
        # mod1 + letter of group = switch to group
        Key([mod], i.name, lazy.group[i.name].toscreen()),

        # mod1 + shift + letter of group = switch to & move focused window to group
        Key([mod, 'shift'], i.name, lazy.window.togroup(
            i.name, switch_group=True)),
        # Or, use below if you prefer not to switch to that group.
        # # mod1 + shift + letter of group = move focused window to group
        # Key([mod, 'shift'], i.name, lazy.window.togroup(i.name)),
    ])

layout_theme = {
    "border_width": 2,
    # "margin": 4,
    "border_focus": "#8fbcbb",
    "border_normal": "#1D2330",
}

layouts = [
    layout.Max(**layout_theme),
    # layout.Stack(num_stacks=2, **layout_theme),
    # Try more layouts by unleashing below layouts.
    # layout.Bsp(),
    # layout.Columns(),
    # layout.Matrix(),
    layout.MonadTall(**layout_theme),
    # layout.MonadWide(),
    # layout.RatioTile(),
    layout.Tile(**layout_theme),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font='sans',
    fontsize=14,
    padding=5,
    background='141a1b',  # #141a1b
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        bottom=bar.Bar(
            [
                widget.CurrentLayout(),
                widget.GroupBox(
                    margin_y=4,
                    borderwidth=3,
                    rounded=True,
                    highlight_method="line",
                    highlight_color=['2eb398', '2eb398'],
                    this_current_screen_border='2eb398',  # #2eb398
                    disable_drag=True,
                ),
                widget.Prompt(),
                widget.WindowName(),

                widget.Systray(),
                widget.CheckUpdates(
                    fmt='| {}',
                    mouse_callbacks={'Button1': lambda qtile: lazy.spawn(
                        my_terminal + ' ' + my_terminal_exec + ' sudo pacman -Syyu && echo "Press enter to exit..." && read')}
                ),
                widget.TextBox(
                    text="|"
                ),
                widget.Battery(
                    format='Battery: {char} {percent:2.0%} {hour:d}:{min:02d}'
                ),
                widget.TextBox(
                    text="|"
                ),
                widget.Volume(
                    fmt='Volume: {}'
                ),
                widget.TextBox(
                    text="|"
                ),
                Brightness(
                    update_interval=1,
                    fmt='Brightness: {}'
                ),
                widget.TextBox(
                    text="|"
                ),
                widget.Clock(format='%Y-%m-%d %H:%M'),
            ],
            24,
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], 'Button1', lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], 'Button3', lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], 'Button2', lazy.window.bring_to_front()),
    Click([mod, 'control'], 'Button1', lazy.window.toggle_floating())
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
main = None
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        {'wmclass': 'confirm'},
        {'wmclass': 'dialog'},
        {'wmclass': 'download'},
        {'wmclass': 'error'},
        {'wmclass': 'file_progress'},
        {'wmclass': 'notification'},
        {'wmclass': 'splash'},
        {'wmclass': 'toolbar'},
        {'wmclass': 'confirmreset'},  # gitk
        {'wmclass': 'makebranch'},  # gitk
        {'wmclass': 'maketag'},  # gitk
        {'wname': 'branchdialog'},  # gitk
        {'wname': 'pinentry'},  # GPG key password entry
        {'wmclass': 'ssh-askpass'},  # ssh-askpass
    ],
    **layout_theme
)
auto_fullscreen = True
focus_on_window_activation = 'smart'

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = 'LG3D'
