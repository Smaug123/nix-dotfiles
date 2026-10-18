#!/bin/sh

# Set the env var $ROFI to the rofi binary.

sink=$(pactl list short sinks | rofi -dmenu -p "Audio Output" | cut -f1)
if [ -n "$sink" ]; then
  pactl set-default-sink "$sink"
fi

