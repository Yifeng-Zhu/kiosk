#!/bin/bash

export DISPLAY=:0

# Log file location
LOG_FILE="/tmp/kiosk.log"

# Function to log messages with timestamp
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Sleep to allow the system to stabilize
sleep 10

CSV_URL="https://raw.githubusercontent.com/Yifeng-Zhu/kiosk/main/kiosk.csv"
CSV_FILE="/tmp/kiosk.csv"
CSV_BACKUP_FILE="/tmp/kiosk_backup.csv"

get_link_from_csv() {
  log_message "Attempting to download CSV file from $CSV_URL"
  
  if curl -o $CSV_FILE $CSV_URL; then
    log_message "CSV file downloaded successfully."
    # Update the backup file with the latest download
    cp $CSV_FILE $CSV_BACKUP_FILE
    log_message "Backup CSV file updated."
  else
    log_message "Failed to download CSV file. Using the backup file if available."
    if [ -f "$CSV_BACKUP_FILE" ]; then
      log_message "Backup CSV file found. Using the backup file."
      cp $CSV_BACKUP_FILE $CSV_FILE
    else
      log_message "No backup CSV file found. Exiting."
      exit 1
    fi
  fi

  MAC_ADDRESS=$(cat /sys/class/net/wlan0/address)
  log_message "MAC address detected: $MAC_ADDRESS"

  LINK=$(grep "$MAC_ADDRESS" "$CSV_FILE" | cut -d',' -f3)

  if [ -z "$LINK" ]; then
    log_message "No matching link found for MAC address $MAC_ADDRESS. Exiting."
    exit 1
  else
    log_message "Link found: $LINK"
  fi

  echo $LINK
}

LINK=$(get_link_from_csv)

log_message "Starting Firefox in kiosk mode with the link: $LINK"
firefox --kiosk "$LINK" &
xdotool mousemove 0 4096

# Start an infinite loop to periodically check for updates and refresh the page
while true 
do
  # Wait for an hour
  sleep 600

  log_message "Checking for updates to the presentation link."
  
  NEW_LINK=$(get_link_from_csv)

  if [ "$LINK" != "$NEW_LINK" ]; then
    log_message "Link has changed. Updating Firefox session to new link: $NEW_LINK"
    LINK=$NEW_LINK
    
    pkill firefox
    log_message "Firefox process killed."

    sleep 5
    
    firefox --kiosk "$LINK" &
    log_message "Firefox restarted with the new link: $LINK"

    xdotool mousemove 0 4096
  else
    log_message "Link has not changed. Refreshing the current page."
    xdotool key ctrl+r
  fi
done
