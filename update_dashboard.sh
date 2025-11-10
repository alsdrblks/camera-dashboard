#!/bin/bash

# -----------------------------
# Paths
# -----------------------------
SOURCE="/home/pi/captured_images"         # Folder where Pi saves images
WEB_REPO="/home/pi/my_website_repo"      # Local clone of your GitHub Pages repo
IMG_FOLDER="$WEB_REPO/images"            # Images folder in repo
JSON_FILE="$WEB_REPO/images.json"
STATUS_FILE="$WEB_REPO/status.json"

# -----------------------------
# Step 0: Ensure folders exist
# -----------------------------
mkdir -p "$IMG_FOLDER"
mkdir -p "$WEB_REPO"

# -----------------------------
# Step 1: Copy images to repo
# -----------------------------
cp -r "$SOURCE"/* "$IMG_FOLDER/" 2>/dev/null

# -----------------------------
# Step 2: Generate images.json safely
# -----------------------------
echo "[" > "$JSON_FILE"

for img in $(ls -1 "$IMG_FOLDER" 2>/dev/null); do
    FILE_PATH="images/$img"
    DATE=$(date -r "$IMG_FOLDER/$img" +"%Y-%m-%d")
    TIME=$(date -r "$IMG_FOLDER/$img" +"%H:%M:%S")

    echo "{
      \"filename\": \"$img\",
      \"date\": \"$DATE\",
      \"time\": \"$TIME\",
      \"path\": \"$FILE_PATH\"
    }," >> "$JSON_FILE"
done

# Remove trailing comma if there are any images
if [ -f "$JSON_FILE" ]; then
    sed -i '$ s/,$//' "$JSON_FILE"
fi

echo "]" >> "$JSON_FILE"

# -----------------------------
# Step 3: Generate status.json
# -----------------------------
UPTIME=$(uptime -p)

# Battery placeholder (no HAT installed)
BATTERY="N/A"

# Wi-Fi info
if iwgetid -r >/dev/null 2>&1; then
  WIFI_SSID=$(iwgetid -r)
  WIFI_SIGNAL=$(iwconfig wlan0 2>/dev/null | grep -i --color=none 'Link Quality' | awk -F '=' '{print $2}' | awk '{print $1}')
  WIFI_STATUS="$WIFI_SSID ($WIFI_SIGNAL)"
else
  WIFI_STATUS="Disconnected"
fi

echo "{
  \"uptime\": \"$UPTIME\",
  \"battery\": \"$BATTERY\",
  \"wifi\": \"$WIFI_STATUS\"
}" > "$STATUS_FILE"

# -----------------------------
# Step 4: Git commit & push
# -----------------------------
cd "$WEB_REPO" || exit
git add images images.json status.json
git commit -m "Auto-update dashboard: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null
git push origin main 2>/dev/null

# -----------------------------
# Step 5: Delete original images safely
# -----------------------------
if [ "$(ls -A $SOURCE 2>/dev/null)" ]; then
    rm -rf "$SOURCE"/*
fi
