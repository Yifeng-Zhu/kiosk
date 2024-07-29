#!/bin/bash
export DISPLAY=:0
echo "$(date) - HDMI turned on" >> /home/ece/cron.log
xrandr --output HDMI-1 --auto
