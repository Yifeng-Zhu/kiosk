#!/bin/bash

export DISPLAY=:0

sleep 10

CSV_URL="https://raw.githubusercontent.com/Yifeng-Zhu/kiosk/main/kiosk.csv"
CSV_FILE="/tmp/kiosk.csv"

get_link_from_csv() {

  curl -o $CSV_FILE $CSV_URL

  MAC_ADDRESS=$(cat /sys/class/net/wlan0/address)

  LINK=$(grep "$MAC_ADDRESS" "$CSV_FILE" | cut -d',' -f3)

  echo $LINK
}

LINK=$(get_link_from_csv)

firefox --kiosk "$LINK" &
xdotool mousemove 0 4096

# Start an infinite loop to periodically check for updates and refresh the page
while true 
do
  # Wait for an hour
  sleep 3600

  # Refresh the CSV file and get the new link
  NEW_LINK=$(get_link_from_csv)

  # If the link has changed, update the Firefox session
  if [ "$LINK" != "$NEW_LINK" ]; then
    LINK=$NEW_LINK
    # Kill the current Firefox process
    pkill firefox
    # Wait for a few seconds to ensure the process has ended
    sleep 5
    # Launch Firefox again in kiosk mode with the new link
    firefox --kiosk "$LINK" &
    # Move the mouse pointer out of the way
    xdotool mousemove 0 4096
  fi

  # Refresh the current page in Firefox
  xdotool key ctrl+r
done