from typing import List  # noqa: F401

from libqtile import layout, bar, widget, hook
from libqtile.config import Key, Screen, Group, Drag, Click, Match
from libqtile.lazy import lazy

import os
import subprocess


@hook.subscribe.startup_once
def autostart():
    sqript = os.path.expanduser('~/.config/qtile/autostart.sh')
    subprocess.call(['bash', sqript])


def float_to_front(qtile):
    """
    Bring all floating windows of the group to front
    """
    for window in qtile.current_group.windows:
        if window.floating:
            window.cmd_bring_to_front()


# Vars
mod = 'mod4'
my_terminal = 'alacritty'
my_terminal_exec = '-e'


keys = [
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(),
        desc="Move window focus to other window"),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(),
        desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(),
        desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(),
        desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(),
        desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(),
        desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(),
        desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod, "control"], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack"),
    # Launch terminal
    Key([mod], "Return", lazy.spawn(my_terminal), desc="Launch terminal"),

    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),

    Key([mod, "control"], "r", lazy.restart(), desc="Restart Qtile"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(),
        desc="Spawn a command using a prompt widget"),

    # Toggle fullscreen
    Key([mod, 'mod1'], 'Return', lazy.window.toggle_fullscreen()),
    # Handle minimize/maximize
    Key([mod, 'mod1'], 'comma', lazy.window.toggle_minimize()),
    Key([mod, 'mod1'], 'period', lazy.window.toggle_minimize()),

    # Bring floatig windows to front
    Key([mod, 'mod1'], 'f', lazy.function(float_to_front)),

    # Rofi bindings
    Key([mod], 'd', lazy.spawn('rofi -show run')),
    Key([mod], 'f', lazy.spawn('rofi -show window')),

    # Audio controlls
    Key([], 'XF86AudioMute', lazy.spawn('amixer -q set Master toggle')),
    Key([], 'XF86AudioLowerVolume', lazy.spawn('amixer sset Master 5%- unmute')),
    Key([], 'XF86AudioRaiseVolume', lazy.spawn('amixer sset Master 5%+ unmute')),

    # Brightness controlls
    Key([], 'XF86MonBrightnessUp', lazy.spawn(
        'bash -c "if [[ 1 -eq $(echo \\"$(xbacklight -get) < 5\\" | bc) ]]; then xbacklight -set 5; else xbacklight -inc 5; fi"')),
    Key([], 'XF86MonBrightnessDown', lazy.spawn(
        'bash -c "if [[ 1 -eq $(echo \\"$(xbacklight -get) <= 5\\" | bc) ]]; then xbacklight -set 1; else xbacklight -dec 5; fi"')),

    # Monitor focus keys
    Key([mod], "1",
        lazy.to_screen(0),
        desc='Keyboard focus to monitor 1'
        ),
    Key([mod], "2",
        lazy.to_screen(1),
        desc='Keyboard focus to monitor 2'
        ),
    # Switch monitor focus
    # TODO
    # Key(["mod1"], "Tab",
    #     lazy.next_screen(),
    #     desc='Move focus to next monitor'
    #     ),

    # Switch to previous group
    Key(["mod1"], "Tab",
        lazy.screen.toggle_group(),
        desc='Switch to previous group'
        ),
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
    "margin": 8,
    "border_focus": "8fbcbb",
    "border_normal": "181c24",
}

layouts = [
    layout.Columns(**layout_theme),
    layout.Max(**layout_theme),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    layout.MonadTall(**layout_theme),
    # layout.MonadWide(),
    # layout.RatioTile(),
    layout.Tile(**layout_theme),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
    layout.Floating(**layout_theme),
]

widget_defaults = dict(
    font='sans',
    fontsize=14,
    padding=5,
    # background='21252b',
    background='181c24',
)
extension_defaults = widget_defaults.copy()


screens = [
    Screen(
        bottom=bar.Bar(
            [
                widget.CurrentLayoutIcon(
                       custom_icon_paths = [os.path.expanduser("~/.config/qtile/icons")],
                       scale = 0.7,
                       ),
                widget.GroupBox(
                    margin_y=4,
                    borderwidth=3,
                    rounded=True,
                    disable_drag=True,
                    highlight_method="line",
                    highlight_color=['2eb398', '2eb398'],
                    this_current_screen_border='2eb398',
                ),
                widget.Prompt(),
                widget.WindowName(),

                widget.Systray(),
                widget.TextBox(
                    text="|"
                ),
                widget.Volume(
                    fmt='Volume: {}'
                ),
                widget.TextBox(
                    text="|"
                ),
                widget.Clock(format='%Y-%m-%d %H:%M'),
            ],
            24,
        ),
    ),
    Screen(
        bottom=bar.Bar(
            [
                widget.CurrentLayoutIcon(
                       custom_icon_paths = [os.path.expanduser("~/.config/qtile/icons")],
                       scale = 0.7,
                       ),
                widget.GroupBox(
                    margin_y=4,
                    borderwidth=3,
                    rounded=True,
                    disable_drag=True,
                    highlight_method="line",
                    highlight_color=['2eb398', '2eb398'],
                    this_current_screen_border='2eb398',
                ),
                widget.WindowName(),
                widget.Clock(format='%Y-%m-%d %H:%M'),
            ],
            24,
        )
    )
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
main = None  # WARNING: this is deprecated and will be removed soon
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(float_rules=[
    # Run the utility of `xprop` to see the wm class and name of an X client.
    *layout.Floating.default_float_rules,
    Match(wm_class='confirmreset'),  # gitk
    Match(wm_class='makebranch'),  # gitk
    Match(wm_class='maketag'),  # gitk
    Match(wm_class='ssh-askpass'),  # ssh-askpass
    Match(title='branchdialog'),  # gitk
    Match(title='pinentry'),  # GPG key password entry
])
auto_fullscreen = True
focus_on_window_activation = "smart"

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
