# Flutter Notification Example

A comprehensive Flutter project demonstrating local and remote (Firebase Cloud Messaging) notifications for both Android and iOS platforms.

## 🎯 Features

### User Management

- 👤 **Dynamic User System** - MongoDB-based user management
- ➕ **User Registration** - Create new users with email validation
- 📋 **User Selection** - Pick user before accessing features
- 🔐 **User Context** - All notifications tied to user identity

### Local Notifications

- ✅ **Instant Notifications** - Send notifications immediately
- ⏰ **Scheduled Notifications** - Schedule notifications for 5 or 30 seconds later
- 🕐 **Time-based Notifications** - Schedule notifications for specific times

### Remote Notifications (FCM)

- 📨 **Push Notifications** - Firebase Cloud Messaging integration
- 👥 **User-to-User Notifications** - Send invitations between users
- 📢 **Broadcast Notifications** - Send to all users/devices at once
- 📱 **Device Management** - Track and manage devices separately
- 🎯 **Selective Sending** - Choose specific devices to receive notifications
- 👥 **Multi-device Selection** - Checkbox-based device picker
- 🎭 **Topic Subscriptions** - Subscribe to notification topics
- 🔄 **Batch Processing** - Auto-split into 500-device batches

### Backend API

- 🚀 **Node.js Server** - Express backend with MongoDB
- 💾 **MongoDB Database** - Persistent user and device storage
- 🔐 **Token Management** - FCM token registration and management
- 📊 **Bulk Notifications** - Send to thousands of devices
- 🎯 **Platform Filtering** - Target iOS or Android specifically
- 📝 **Swagger Documentation** - Auto-generated API docs

## 📱 Platform Support

- ✅ Android (API 21+)
- ✅ iOS (13.0+)
- 🔔 Background & Foreground notifications
- 📍 Notification when app is terminated

## 🚀 Quick Start

See [SETUP.md](SETUP.md) for detailed setup instructions.

### Prerequisites

- Flutter SDK (3.0+)
- Node.js (16+)
- MongoDB (Community Edition)
- Firebase account
- iOS: Xcode 14+
- Android: Android Studio

### Basic Setup

```bash
# Clone repository
git clone <your-repo-url>
cd notification_example

# Install Flutter dependencies
flutter pub get

# Start MongoDB
brew services start mongodb-community

# Install backend dependencies
cd backend_test && npm install && cd ..

# Run backend server (with Swagger docs at :3000/api-docs)
cd backend_test && node server.js

# Run app
flutter run
```

## 🗄️ Database

The app uses **MongoDB** for persistent storage:

- **Users Collection**: User profiles with email and FCM tokens
- **Devices Collection**: Device registrations with platform info
- **Connection**: `mongodb://localhost:27017/notification_db`

All data persists across app/server restarts!

## 🔒 Security

⚠️ **IMPORTANT**: This repository does NOT include:

- `service_account.json` (Firebase Admin credentials)
- `google-services.json` (Android config)
- `GoogleService-Info.plist` (iOS config)

You must obtain these from your Firebase Console. See [SECURITY.md](SECURITY.md) for details.

## 📚 Documentation

- [Setup Guide](SETUP.md) - Complete setup instructions
- [Backend API](backend_test/README.md) - API documentation with examples
- [Security](SECURITY.md) - Security best practices
- [Swagger API Docs](http://localhost:3000/api-docs) - Interactive API documentation

## 🎮 Usage

### First Time Setup

1. **Launch App** → User Selection Screen appears
2. **Create User** → Tap "Yeni Kullanıcı Oluştur"
3. **Enter Details** → Name and email (with validation)
4. **Select User** → Choose from list to enter app

### Sending Notifications

#### 1. Toplu Bildirim (All Devices)

Send to all registered devices (2000+ supported):

- Tap "📢 Toplu Bildirim (Tüm Cihazlar)"
- Choose: All / iOS only / Android only
- Auto-batched in 500-device chunks

#### 2. Seçili Cihazlara Gönder (Selected Devices) ⭐ NEW

Pick specific devices:

- Tap "📱 Seçili Cihazlara Gönder"
- Check devices you want
- "Tümünü Seç" for all
- Send to selected group

#### 3. Davetiye Gönder (Invitation)

User-to-user invitations:

- Tap "📨 Davetiye Gönder"
- Choose recipient
- Enter event name
- Recipient gets notification

#### 4. Mesaj Gönder (Message)

Direct messages between users:

- Select recipient
- Type message
- Instant notification delivery

### Device Management

App automatically:

- Registers device on first launch
- Updates FCM token when changed
- Tracks platform (iOS/Android)
- Shows device list in admin panel

## 🔄 Batch Processing

For large-scale notifications:

| Devices   | Batches    | Approx. Time |
| --------- | ---------- | ------------ |
| 500       | 1          | ~1-2 sec     |
| 2,000     | 4          | ~4-8 sec     |
| 10,000    | 20         | ~20-40 sec   |
| Unlimited | Auto-split | Scalable     |

**Console Output:**

```
📤 2000 cihaza 4 batch halinde gönderiliyor...
   Batch 1/4: 500/500 başarılı
   Batch 2/4: 498/500 başarılı
   Batch 3/4: 500/500 başarılı
   Batch 4/4: 495/500 başarılı
✅ Toplu device bildirimi tamamlandı: 1993/2000 başarılı
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
├── main.dart                      # Main app with notification UI
├── user_selection_screen.dart     # User selection/login screen
├── user_register_screen.dart      # New user registration
├── invitation_screen.dart         # Invitation sending UI
├── backend_service.dart           # API client for backend
├── notification_service.dart      # Local notification service
├── firebase_messaging_service.dart # FCM service
└── firebase_options.dart          # Firebase configuration

backend_test/
├── server.js                      # Express server with all endpoints
├── models/
│   ├── User.js                    # Mongoose user schema
│   └── Device.js                  # Mongoose device schema
└── service_account.json           # Firebase Admin credentials (gitignored)
```

### Key Components

**Flutter:**

- **UserSelectionScreen**: Landing page, user picker
- **UserRegisterScreen**: User creation form with validation
- **BackendService**: HTTP client for API calls
- **FirebaseMessagingService**: FCM token management
- **NotificationService**: Local notification handling

**Backend:**

- **MongoDB Models**: User and Device schemas with validation
- **Batch Processing**: Auto-split large notification batches
- **Error Handling**: Detailed logging and error responses
- **Swagger Docs**: Auto-generated API documentation

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

### MongoDB connection failed?

```bash
# Start MongoDB
brew services start mongodb-community

# Check if running
brew services list | grep mongodb
```

### Backend port already in use?

```bash
# Kill existing process
pkill -f "node server.js"

# Or find and kill specific process
lsof -ti:3000 | xargs kill -9
```

### Notifications not showing on iOS?

- Check Settings → Notifications → notification_example
- Ensure "Allow Notifications" is enabled
- Try restarting the app completely (not just hot reload)
- Check console for FCM token

### Notifications not showing on Android?

- For Android 13+, ensure notification permission is granted
- Check app notification settings in device settings
- Verify that battery optimization is disabled for the app

### Device not registering?

- Check backend is running at `http://localhost:3000`
- Verify MongoDB is connected
- Check Flutter console for error messages
- Ensure device has valid FCM token

### User registration failing?

- Email must be valid format
- Email must be unique (check MongoDB)
- Name must be at least 3 characters
- Check backend logs for detailed error

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Resources

- [Backend API Documentation](backend_test/README.md)
- [Swagger API Docs](http://localhost:3000/api-docs) (when server running)
- [flutter_local_notifications package](https://pub.dev/packages/flutter_local_notifications)
- [firebase_messaging package](https://pub.dev/packages/firebase_messaging)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Android Notification Guide](https://developer.android.com/develop/ui/views/notifications)
- [iOS Notification Guide](https://developer.apple.com/documentation/usernotifications)

## 🆕 Recent Updates

### v2.0 - Database & Batch Processing

- ✅ MongoDB integration for users and devices
- ✅ Dynamic user registration system
- ✅ User selection screen on launch
- ✅ Device-based notification system
- ✅ Seçili cihazlara toplu gönderim (NEW!)
- ✅ Batch processing for 500+ devices
- ✅ Platform filtering (iOS/Android)
- ✅ Swagger API documentation
- ✅ Detailed error handling and logging

## 📊 API Endpoints Summary

| Endpoint                        | Method | Description                 |
| ------------------------------- | ------ | --------------------------- |
| `/api/users`                    | GET    | List all users              |
| `/api/create-user`              | POST   | Create new user             |
| `/api/devices`                  | GET    | List all devices            |
| `/api/register-device`          | POST   | Register device             |
| `/api/send-to-device`           | POST   | Send to single device       |
| `/api/send-to-multiple-devices` | POST   | Send to selected devices ⭐ |
| `/api/send-bulk-devices`        | POST   | Send to all devices         |
| `/api/send-invitation`          | POST   | User invitation             |
| `/api/send-message`             | POST   | Direct message              |

See [backend_test/README.md](backend_test/README.md) for complete API documentation.
