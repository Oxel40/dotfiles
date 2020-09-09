# Start compositor
picom &
# Start gestures
# libinput-gestures &

# Set background
feh --bg-scale $HOME/Pictures/Wallpapers/129818.png &

# Start screenlocker
xset s off &
xss-lock -n /usr/lib/xsecurelock/dimmer -l -- xsecurelock &
