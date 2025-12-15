#!/bin/bash

DISCORD_APP_ID="$1"
DISCORD_BOT_TOKEN="$2"

if [ -z "$DISCORD_APP_ID" ] || [ -z "$DISCORD_BOT_TOKEN" ]; then
  echo "Usage: ./register_commands.sh <APP_ID> <BOT_TOKEN>"
  exit 1
fi

echo "Registering slash commands..."

curl -X PUT \
  "https://discord.com/api/v10/applications/$DISCORD_APP_ID/commands" \
  -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "name": "server",
      "description": "Control the Minecraft server",
      "options": [
        {
          "name": "start",
          "description": "Start the Minecraft server",
          "type": 1
        },
        {
          "name": "stop",
          "description": "Stop the Minecraft server",
          "type": 1
        },
        {
          "name": "status",
          "description": "Check server status",
          "type": 1
        }
      ]
    }
  ]'

echo ""
echo "Done! Commands registered."
