#!/bin/bash

# Script to generate themed app icons for all theme colors

echo "Generating themed app icons..."

# Define theme colors
declare -A themes=(
    ["red_velvet"]="#8B2635"
    ["royal_blue"]="#4169E1"
    ["emerald_green"]="#50C878"
    ["purple_majesty"]="#6A0DAD"
    ["sunset_orange"]="#FF6347"
    ["forest_green"]="#228B22"
    ["deep_pink"]="#FF1493"
    ["midnight_blue"]="#191970"
    ["golden_yellow"]="#FFD700"
    ["crimson_red"]="#DC143C"
    ["piano_black"]="#000000"
)

# Backup original pubspec.yaml
cp pubspec.yaml pubspec.yaml.backup

# Generate icons for each theme
for theme in "${!themes[@]}"; do
    echo "Generating icon for theme: $theme with color: ${themes[$theme]}"
    
    # Update pubspec.yaml with theme color
    sed -i "s/adaptive_icon_background: \"#[0-9A-F]*\"/adaptive_icon_background: \"${themes[$theme]}\"/g" pubspec.yaml
    sed -i "s/android: \".*\"/android: \"launcher_icon_$theme\"/g" pubspec.yaml
    
    # Generate the icon
    flutter pub run flutter_launcher_icons
    
    echo "Generated icon for $theme"
done

# Restore original pubspec.yaml
cp pubspec.yaml.backup pubspec.yaml
rm pubspec.yaml.backup

echo "All themed icons generated!"
