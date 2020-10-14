"""
This is a setup to prepare the continuous integration build.

Since Firebase Cloud Messaging needs a configuration file
(including API keys) and we subsequently don't want to include
it in the public repository, we render it from a template
using environment variables.
"""

import os


FCM_PLIST_PATH = 'peerbridge-ios/GoogleService-Info.plist'

if os.path.isfile(FCM_PLIST_PATH):
    print('The FCM configuration file already exists.')
    exit(0)

FCM_PLIST_CONTENTS = f"""
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>{os.environ['CLIENT_ID']}</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>{os.environ['REVERSED_CLIENT_ID']}</string>
    <key>API_KEY</key>
    <string>{os.environ['API_KEY']}</string>
    <key>GCM_SENDER_ID</key>
    <string>{os.environ['GCM_SENDER_ID']}</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>com.peerbridge.ios</string>
    <key>PROJECT_ID</key>
    <string>{os.environ['PROJECT_ID']}</string>
    <key>STORAGE_BUCKET</key>
    <string>{os.environ['STORAGE_BUCKET']}</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <false/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <false/>
    <key>GOOGLE_APP_ID</key>
    <string>{os.environ['GOOGLE_APP_ID']}</string>
    <key>DATABASE_URL</key>
    <string>{os.environ['DATABASE_URL']}</string>
    <key>SERVER_KEY</key>
    <string>{os.environ['SERVER_KEY']}</string>
</dict>
</plist>
"""

with open(FCM_PLIST_PATH, 'w') as fcm_plist_file:
    fcm_plist_file.write(FCM_PLIST_CONTENTS)
