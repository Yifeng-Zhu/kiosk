#!/bin/bash

# Export the display environment variable for GUI applications
export DISPLAY=:0

# URL to the CSV file in the GitHub repository
CSV_URL="https://raw.githubusercontent.com/Yifeng-Zhu/kiosk/main/kiosk.csv"

# Local path to store the downloaded CSV file temporarily
CSV_FILE="/tmp/kiosk.csv"

  # Download the CSV file to the temporary location
  curl -o $CSV_FILE $CSV_URL

  # Get the MAC address of the Raspberry Pi
  MAC_ADDRESS=$(cat /sys/class/net/wlan0/address)

  # Find the corresponding link in the CSV file by matching the MAC address
  LINK=$(grep "$MAC_ADDRESS" "$CSV_FILE" | cut -d',' -f3)

  echo $LINK


set +x


# Wait for a few seconds to ensure everything is ready
sleep 5

# Launch Firefox in kiosk mode with the found link
firefox --kiosk "$LINK" &
# Move the mouse pointer out of the way
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