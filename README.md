# PRVNT (Production)

PRVNT is a production-ready Flutter app for a BLE safety button. It scans and connects to a BLE device, listens for `PANIC` notifications, and triggers an emergency workflow with location sharing and local event logging.

## Highlights
- Riverpod + go_router architecture
- Liquid glass UI with frosted blur, soft gradients, and iOS-like motion
- BLE scan/connect/notify with service filtering
- Emergency countdown, cancel, mock/real sending
- Friends status (demo mode) and emergency contact sync
- Contacts + settings stored locally (Hive)
- Event logs stored in SQLite (sqflite)
- Dark mode and system theme support

## Requirements
- Flutter stable
- Xcode (iOS) or Android Studio (Android)

## Run
```sh
flutter pub get
flutter run
```

## BLE Device Contract
- Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- Notify Characteristic UUID: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- Payloads:
  - ASCII: `PANIC`
  - JSON: `{ "event": "PANIC", "ts": <unix_ms> }`

## Permissions
### iOS
Ensure `ios/Runner/Info.plist` includes:
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSContactsUsageDescription`

### Android
`android/app/src/main/AndroidManifest.xml` includes:
- `android.permission.BLUETOOTH`
- `android.permission.BLUETOOTH_ADMIN`
- `android.permission.BLUETOOTH_SCAN`
- `android.permission.BLUETOOTH_CONNECT`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.READ_CONTACTS`

## Architecture
```
lib/
  app/              # theme, router, constants
  features/
    home/
    device/
    emergency/
    contacts/
    settings/
    logs/
  services/
    ble/
    location/
    storage/
    permissions/
  models/
  widgets/
```

## Emergency Workflow
1. BLE notification contains `PANIC`
2. Full-screen emergency modal shows countdown
3. Cancel or allow escalation
4. Fetch high accuracy location
5. Send alert (mock by default)
6. Log event + locations

## Mock vs Real SMS
- Mock mode is ON by default (Settings)
- To enable real sending:
  - Toggle Mock Mode OFF
  - Set Backend URL in Settings
  - The app calls:
    ```
    POST <backend>/send-sms
    Body: { contacts: [{name, phone}], message: "..." }
    ```

## Demo Mode
Enable Demo Mode in Settings to allow simulated PANIC events from the Device tab.

## BLE Testing
- Use nRF Connect or Arduino to send `PANIC` on the notify characteristic.
- On-device only; BLE scanning is not supported on iOS simulator.

## Troubleshooting
- iOS: allow Local Network access for your terminal/Xcode to connect to the Dart VM.
- If Bluetooth permissions are denied, use the Permission Required card to open Settings.
