#!/bin/bash

# Script to automatically update IP address in Android and iOS config files
# This script reads the IP from local_config.dart and updates native configs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Extract IP from local_config.dart
LOCAL_CONFIG="$PROJECT_DIR/lib/core/config/local_config.dart"
IP=$(grep -oP "lanBaseUrl = 'http://\K[^:]+" "$LOCAL_CONFIG" | head -1)

if [ -z "$IP" ]; then
    echo "❌ Could not extract IP address from local_config.dart"
    exit 1
fi

echo "📍 Found IP address: $IP"

# Update Android network_security_config.xml
ANDROID_CONFIG="$PROJECT_DIR/android/app/src/main/res/xml/network_security_config.xml"
if [ -f "$ANDROID_CONFIG" ]; then
    # Remove old IP domain entries and add new one
    # Keep localhost, 127.0.0.1, 10.0.2.2 entries
    sed -i.bak "s/<domain includeSubdomains=\"true\">192\.168\.[0-9]\+\.[0-9]\+<\/domain>//g" "$ANDROID_CONFIG"
    # Add new IP entry before closing domain-config tag
    sed -i.bak "/<\/domain-config>/i\\
        <domain includeSubdomains=\"true\">$IP</domain>
" "$ANDROID_CONFIG"
    # Clean up backup file
    rm -f "$ANDROID_CONFIG.bak"
    echo "✅ Updated Android network_security_config.xml"
else
    echo "⚠️  Android config file not found: $ANDROID_CONFIG"
fi

# Update iOS Info.plist
IOS_CONFIG="$PROJECT_DIR/ios/Runner/Info.plist"
if [ -f "$IOS_CONFIG" ]; then
    # Remove old IP domain entries (192.168.x.x pattern)
    sed -i.bak "/<key>192\.168\.[0-9]\+\.[0-9]\+<\/key>/,/<\/dict>/d" "$IOS_CONFIG"
    # Add new IP domain entry before closing NSExceptionDomains dict
    sed -i.bak "/<\/dict>/i\\
		<key>$IP</key>\\
		<dict>\\
			<key>NSExceptionAllowsInsecureHTTPLoads</key>\\
			<true/>\\
			<key>NSIncludesSubdomains</key>\\
			<true/>\\
			<key>NSExceptionRequiresForwardSecrecy</key>\\
			<false/>\\
			<key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>\\
			<true/>\\
		</dict>
" "$IOS_CONFIG"
    # Clean up backup file
    rm -f "$IOS_CONFIG.bak"
    echo "✅ Updated iOS Info.plist"
else
    echo "⚠️  iOS config file not found: $IOS_CONFIG"
fi

echo "✨ IP configuration updated successfully!"

