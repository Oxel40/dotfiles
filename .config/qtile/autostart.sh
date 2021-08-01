# Start compositor
# picom &
# Start gestures
# libinput-gestures &

# Set background
nitrogen --restore &

# Notification server
dunst &

# Start screenlocker
# xset s 300 5
# xss-lock -n /usr/lib/xsecurelock/dimmer -l -- xsecurelock &

# Authenticathon manager
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Mouse acceleration
xinput --set-prop 'pointer:Razer Razer DeathAdder 2013' 'libinput Accel Profile Enabled' {0, 1}

# Xorg setup because GMD just doesn't give a fuck about xorg.conf
xrandr --output HDMI-0 --mode 1920x1080 --rate 60 --right-of DP-0
xrandr --output DVI-D-0 --mode 1920x1080 --rate 60 --right-of DP-0
xrandr --output DP-0 --mode 1920x1080 --rate 144 --primary
