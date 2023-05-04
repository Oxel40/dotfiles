#!/bin/bash

while [ $(pidof Hyprland) ]
do
	waybar
done
