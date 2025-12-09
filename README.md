# Flutter Local Notifications Example

A comprehensive Flutter project demonstrating local notification implementation for both Android and iOS platforms. This app showcases instant notifications, scheduled notifications, and time-based notifications.

## Features

- ✅ **Instant Notifications** - Send notifications immediately
- ⏰ **Scheduled Notifications** - Schedule notifications for 5 or 30 seconds later
- 🕐 **Time-based Notifications** - Schedule notifications for specific times (e.g., 17:15)
- 📱 **Cross-platform Support** - Works on both Android and iOS
- 🔔 **Background Notifications** - Notifications work even when the app is closed
- ⚙️ **Permission Handling** - Automatic permission requests for Android 13+ and iOS
- 🌍 **Timezone Support** - Handles different timezones correctly

## Screenshots

[Add screenshots of your app here]

## Dependencies

```yaml
dependencies:
  flutter_local_notifications: ^latest
  timezone: ^latest
  flutter_timezone: ^latest
```

## Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd notification_example
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Platform-Specific Setup

### Android

The following permissions are automatically configured in `AndroidManifest.xml`:
- `POST_NOTIFICATIONS` - For Android 13+ notification permission
- `SCHEDULE_EXACT_ALARM` - For exact scheduled notifications
- `USE_EXACT_ALARM` - Alternative for exact alarms
- `VIBRATE` - For notification vibration
- `RECEIVE_BOOT_COMPLETED` - To restore notifications after device restart

### iOS

The app includes proper iOS configuration in:
- `Info.plist` - Background modes for notifications
- `AppDelegate.swift` - Notification center delegate setup

Permissions are requested automatically when the app launches.

## Usage

### 1. Instant Notification
Tap the "Send Instant Notification" button to receive an immediate notification.

### 2. Scheduled Notifications
- **5 Seconds**: Tap the button and receive a notification after 5 seconds
- **30 Seconds**: Tap the button and receive a notification after 30 seconds

### 3. Time-based Notification
Tap the "Send Notification at 17:15" button to schedule a notification for 5:15 PM. If the time has already passed today, it will be scheduled for tomorrow.

## Code Structure

```
lib/
├── main.dart                 # Main app entry point and UI
└── notification_service.dart # Notification service implementation
```

### Key Components

- **NotificationService**: Singleton service managing all notification operations
- **initialize()**: Sets up notification channels and permissions
- **showNotification()**: Sends instant notifications
- **scheduleNotification()**: Schedules notifications with DateTime
- **scheduleNotification2()**: Schedules notifications with specific hour/minute

## Testing

### Test on Android
```bash
flutter run -d android
```

### Test on iOS
```bash
flutter run -d ios
```

### Test Notifications While App is Closed

1. Open the app
2. Schedule a notification (e.g., 30 seconds)
3. Close the app completely
4. Wait for the scheduled time
5. Notification will appear! ✅

## Troubleshooting

### Notifications not showing on iOS?
- Check Settings → Notifications → notification_example
- Ensure "Allow Notifications" is enabled
- Try restarting the app completely (not just hot reload)

### Notifications not showing on Android?
- For Android 13+, ensure notification permission is granted
- Check app notification settings in device settings
- Verify that battery optimization is disabled for the app

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Resources

- [flutter_local_notifications package](https://pub.dev/packages/flutter_local_notifications)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Android Notification Guide](https://developer.android.com/develop/ui/views/notifications)
- [iOS Notification Guide](https://developer.apple.com/documentation/usernotifications)
