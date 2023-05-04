#!/bin/bash

# Set background
nitrogen --restore &

# Notification server
dunst &

# Start screenlocker
#light-locker &
xss-lock xsecurelock

# Mouse acceleration
# xinput --set-prop 'pointer:Razer Razer DeathAdder 2013' 'libinput Accel Profile Enabled' {0, 1}

if command -v libinput-gestures &> /dev/null
then
	libinput-gestures &
fi

# USB disk automount
udiskie &

# Polkit auth. agent
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
