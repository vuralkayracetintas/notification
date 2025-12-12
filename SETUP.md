# Project Setup Guide

## Prerequisites
- Flutter SDK (3.0+)
- Node.js (16+)
- Firebase account
- iOS: Xcode 14+
- Android: Android Studio

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd notification_example
```

### 2. Install Dependencies

#### Flutter
```bash
flutter pub get
```

#### Backend
```bash
cd backend_test
npm install
cd ..
```

### 3. Firebase Configuration

#### Get Firebase Config Files
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project or create new one
3. Download configuration files:
   - **Android**: `google-services.json` → `android/app/`
   - **iOS**: `GoogleService-Info.plist` → `ios/Runner/`
   - **Backend**: Service Account Key → `service_account.json` (root & backend_test/)

#### Get Service Account JSON
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download the JSON file
4. Copy to:
   ```
   notification_example/service_account.json
   notification_example/backend_test/service_account.json
   ```

⚠️ **IMPORTANT**: Never commit `service_account.json` to Git!

### 4. Run Backend Server

```bash
cd backend_test
node server.js
```

Server will start at `http://localhost:3000`

### 5. Run Flutter App

```bash
flutter run
```

## 📱 Test Users

Demo accounts (password: `123456`):
- `ahmet@example.com`
- `mehmet@example.com`
- `ayse@example.com`

## 🔧 Configuration

### Backend URL
- Local: `http://localhost:3000/api`
- Production: Update `backend_service.dart` baseUrl

### Firebase Options
Auto-generated in `lib/firebase_options.dart`

To regenerate:
```bash
flutterfire configure
```

## 📚 Documentation

- [FCM Guide](FCM_GUIDE.md) - Firebase Cloud Messaging setup
- [Broadcast Guide](BROADCAST_GUIDE.md) - Send to all users
- [Postman Guide](POSTMAN_GUIDE.md) - API testing
- [Security](SECURITY.md) - Security best practices

## 🐛 Troubleshooting

### iOS Simulator - FCM Token
FCM tokens **cannot be obtained in iOS simulator**. Use a real device.

### Backend Connection Failed
Ensure backend is running:
```bash
cd backend_test && node server.js
```

### Permission Denied
Check notification permissions in device settings.

## 📞 Support

For issues, check existing documentation or create an issue in the repository.
