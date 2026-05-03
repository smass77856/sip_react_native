# iOS Privacy Permission Fix

## Issue
App Store Connect rejected the build with error:
```
ITMS-90683: Missing purpose string in Info.plist - NSCameraUsageDescription
```

## Solution Applied
Added required privacy permission keys to `ios/siprixreactnt/Info.plist`:

### Added Keys:
1. **NSCameraUsageDescription**
   - Purpose: "This app requires camera access to enable video calls and video conferencing features."

2. **NSMicrophoneUsageDescription**
   - Purpose: "This app requires microphone access to enable voice and video calls."

## Files Modified
- `ios/siprixreactnt/Info.plist` (backup saved as `Info.plist.backup`)

## Next Steps
1. Clean the build folder in Xcode: `Product > Clean Build Folder`
2. Rebuild the app
3. Archive and upload to App Store Connect
4. The ITMS-90683 error should now be resolved

## Additional Notes
- These permissions are required for VoIP/SIP applications
- Users will see these descriptions when the app requests camera/microphone access
- You can customize the description strings to better match your app's specific use case
