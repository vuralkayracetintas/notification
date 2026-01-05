# Firebase Cloud Messaging - Device ID Bazlı Bildirim Sistemi Dokümantasyonu

## 📋 İçindekiler

1. [Proje Genel Bakış](#proje-genel-bakış)
2. [Sistem Mimarisi](#sistem-mimarisi)
3. [Firebase Entegrasyonu](#firebase-entegrasyonu)
4. [Backend API Dokümantasyonu](#backend-api-dokümantasyonu)
5. [Mobil Uygulama (Flutter)](#mobil-uygulama-flutter)
6. [Kullanım Senaryoları](#kullanım-senaryoları)
7. [Test ve Geliştirme](#test-ve-geliştirme)
8. [Deployment ve Production](#deployment-ve-production)

---

## 🎯 Proje Genel Bakış

Bu proje, **Firebase Cloud Messaging (FCM)** kullanarak device ID bazlı bir bildirim sistemi sunar. Geleneksel user ID bazlı sistemlerden farklı olarak, her cihaz benzersiz bir ID ile tanımlanır ve bildirimler cihaz seviyesinde yönetilebilir.

### Temel Özellikler

- ✅ **Device ID Bazlı Bildirim**: Her cihaz benzersiz ID ile tanımlanır
- ✅ **Toplu Bildirim**: Tüm cihazlara veya platform bazlı toplu bildirim
- ✅ **User Bazlı Bildirim**: Geleneksel user ID sistemi de desteklenir
- ✅ **Platform Filtreleme**: iOS/Android bazlı bildirim gönderimi
- ✅ **Davetiye Sistemi**: Kullanıcılar arası özel bildirimler
- ✅ **Swagger API Dokümantasyonu**: Tüm API'ler interaktif dokümante edilmiş
- ✅ **Real-time**: Firebase gerçek zamanlı bildirim desteği

---

## 🏗️ Sistem Mimarisi

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Device ID   │  │  FCM Token   │  │ Notification │      │
│  │  Management  │  │   Handler    │  │   Service    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTP/REST API
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Node.js Backend Server                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Express    │  │   Swagger    │  │   Firebase   │      │
│  │     API      │  │     Docs     │  │    Admin     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  Memory Storage (Development):                               │
│  ┌─────────────┐  ┌──────────────┐                         │
│  │   Users     │  │   Devices    │                         │
│  │  Database   │  │   Database   │                         │
│  └─────────────┘  └──────────────┘                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Firebase Admin SDK
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Firebase Cloud Messaging (FCM)                   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Push Notification Delivery to iOS & Android         │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Veri Akışı

1. **Uygulama Başlatma**

   ```
   Mobile App → FCM Token Al → Device ID Oluştur → Backend'e Kaydet
   ```

2. **Bildirim Gönderme**

   ```
   Backend API → Device ID/User ID Filtrele → Firebase Admin SDK → FCM → Mobil Cihaz
   ```

3. **Bildirim Alma**
   ```
   FCM → Mobil App → Notification Service → Local Notification Display
   ```

---

## 🔥 Firebase Entegrasyonu

### Firebase'den Kullanılan Servisler

#### 1. Firebase Cloud Messaging (FCM)

**Kullanım Amacı**: Push notification gönderimi ve alımı

**Backend Tarafı (Firebase Admin SDK)**:

```javascript
const admin = require("firebase-admin");

// Firebase Admin SDK başlatma
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Tek cihaza bildirim gönderme
await admin.messaging().send({
  token: deviceFCMToken,
  notification: {
    title: "Başlık",
    body: "İçerik",
  },
  data: {
    customKey: "customValue",
  },
  android: {
    priority: "high",
  },
  apns: {
    payload: {
      aps: {
        sound: "default",
        badge: 1,
      },
    },
  },
});

// Toplu bildirim gönderme
await admin.messaging().sendEach(messages);
```

**Mobil Tarafı (Flutter)**:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// FCM Token alma
final token = await FirebaseMessaging.instance.getToken();

// Foreground bildirimleri dinleme
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Bildirim geldiğinde yapılacaklar
});

// Background bildirimleri dinleme
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

// Bildirime tıklanma
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Navigasyon işlemleri
});
```

#### 2. Firebase Console Konfigürasyonu

**Gerekli Dosyalar**:

- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- `service_account.json` (Backend - Firebase Admin SDK)

**İzinler ve Ayarlar**:

- Cloud Messaging API aktif olmalı
- iOS için APNs sertifikası yüklenmeli
- Service Account key dosyası oluşturulmalı

#### 3. Firebase Topics (Broadcast Bildirimleri)

```dart
// Topic'e abone olma
await FirebaseMessaging.instance.subscribeToTopic('all_users');

// Topic'ten çıkma
await FirebaseMessaging.instance.unsubscribeFromTopic('all_users');
```

---

## 🖥️ Backend API Dokümantasyonu

### Teknoloji Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Firebase**: firebase-admin SDK
- **Documentation**: Swagger (swagger-ui-express, swagger-jsdoc)
- **CORS**: cors middleware

### API Endpoint'leri

#### 1. Health Check

```http
GET /
```

**Response**:

```json
{
  "status": "running",
  "message": "🚀 Notification Backend Test Server",
  "endpoints": {
    "POST /api/register-token": "FCM token kaydet (User ID bazlı)",
    "POST /api/register-device": "Device bilgilerini kaydet",
    "POST /api/send-to-device": "Belirli device'a bildirim gönder",
    "POST /api/send-bulk-devices": "Toplu bildirim (Device bazlı)",
    "GET /api/users": "Tüm kullanıcıları listele",
    "GET /api/devices": "Kayıtlı device'ları listele"
  }
}
```

#### 2. User Bazlı Sistem

##### 2.1 FCM Token Kaydet (User ID)

```http
POST /api/register-token
Content-Type: application/json

{
  "userId": "user1",
  "fcmToken": "fcm-token-xyz..."
}
```

**Response**:

```json
{
  "success": true,
  "message": "FCM token başarıyla kaydedildi",
  "user": {
    "id": "user1",
    "name": "Ahmet Yılmaz"
  }
}
```

##### 2.2 Kullanıcıları Listele

```http
GET /api/users
```

**Response**:

```json
{
  "success": true,
  "users": [
    {
      "id": "user1",
      "name": "Ahmet Yılmaz",
      "email": "ahmet@example.com",
      "hasToken": true
    }
  ]
}
```

##### 2.3 User'a Bildirim Gönder

```http
POST /api/send-notification
Content-Type: application/json

{
  "userId": "user1",
  "title": "Bildirim Başlığı",
  "body": "Bildirim içeriği",
  "data": {
    "type": "custom",
    "itemId": "123"
  }
}
```

#### 3. Device Bazlı Sistem (Yeni)

##### 3.1 Device Kaydet

```http
POST /api/register-device
Content-Type: application/json

{
  "deviceId": "ACB8A869-1456-4F30-8EDC-6E084B86AB62",
  "fcmToken": "fcm-token-xyz...",
  "userId": "user1",
  "platform": "iOS",
  "deviceInfo": "iPhone 15 Pro"
}
```

**Response**:

```json
{
  "success": true,
  "message": "Device başarıyla kaydedildi",
  "deviceId": "ACB8A869-1456-4F30-8EDC-6E084B86AB62",
  "registeredAt": "2026-01-05T10:02:19.465Z"
}
```

**Backend Kodu**:

```javascript
const devices = {}; // Memory storage

app.post("/api/register-device", (req, res) => {
  const { deviceId, fcmToken, userId, platform, deviceInfo } = req.body;

  if (!deviceId || !fcmToken) {
    return res.status(400).json({
      success: false,
      error: "deviceId ve fcmToken gerekli",
    });
  }

  devices[deviceId] = {
    fcmToken,
    userId: userId || null,
    platform: platform || "unknown",
    deviceInfo: deviceInfo || null,
    registeredAt: new Date().toISOString(),
    lastActive: new Date().toISOString(),
  };

  console.log(`✅ Device kaydedildi: ${deviceId} (${platform})`);

  res.json({
    success: true,
    message: "Device başarıyla kaydedildi",
    deviceId,
    registeredAt: devices[deviceId].registeredAt,
  });
});
```

##### 3.2 Device'ları Listele

```http
GET /api/devices
```

**Response**:

```json
{
  "success": true,
  "totalDevices": 3,
  "devices": [
    {
      "deviceId": "ACB8A869-1456-4F30-8EDC-6E084B86AB62",
      "platform": "iOS",
      "userId": "user1",
      "deviceInfo": "iPhone 15 Pro",
      "registeredAt": "2026-01-05T10:02:19.465Z",
      "lastActive": "2026-01-05T10:15:30.123Z",
      "hasToken": true
    }
  ]
}
```

##### 3.3 Device'a Bildirim Gönder

```http
POST /api/send-to-device
Content-Type: application/json

{
  "deviceId": "ACB8A869-1456-4F30-8EDC-6E084B86AB62",
  "title": "Device Notification",
  "body": "Bu bildirim sadece senin cihazına gönderildi",
  "data": {
    "type": "device_specific",
    "priority": "high"
  }
}
```

**Response**:

```json
{
  "success": true,
  "message": "Bildirim başarıyla gönderildi",
  "messageId": "projects/xxx/messages/xxx",
  "device": {
    "deviceId": "ACB8A869-1456-4F30-8EDC-6E084B86AB62",
    "platform": "iOS",
    "userId": "user1"
  }
}
```

**Backend Kodu**:

```javascript
app.post("/api/send-to-device", async (req, res) => {
  const { deviceId, title, body, data } = req.body;

  const device = devices[deviceId];

  if (!device) {
    return res.status(404).json({
      success: false,
      error: "Device bulunamadı",
    });
  }

  try {
    const message = {
      token: device.fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data || {},
      android: {
        priority: "high",
        notification: {
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    device.lastActive = new Date().toISOString();

    res.json({
      success: true,
      message: "Bildirim başarıyla gönderildi",
      messageId: response,
      device: {
        deviceId: deviceId,
        platform: device.platform,
        userId: device.userId,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
```

##### 3.4 Toplu Bildirim Gönder

```http
POST /api/send-bulk-devices
Content-Type: application/json

{
  "title": "Toplu Bildirim",
  "body": "Bu bildirim tüm kayıtlı cihazlara gönderildi",
  "data": {
    "type": "bulk"
  },
  "platform": "iOS"  // Opsiyonel: iOS, Android veya boş (tümü)
}
```

**Response**:

```json
{
  "success": true,
  "message": "Toplu bildirim tüm kayıtlı device'lara gönderildi",
  "totalDevices": 3,
  "successCount": 3,
  "failureCount": 0,
  "platform": "iOS",
  "devices": [
    {
      "deviceId": "device-1",
      "platform": "iOS",
      "userId": "user1"
    }
  ]
}
```

**Backend Kodu**:

```javascript
app.post("/api/send-bulk-devices", async (req, res) => {
  const { title, body, data, platform } = req.body;

  let targetDevices = Object.values(devices);

  // Platform filtresi
  if (platform) {
    targetDevices = targetDevices.filter((d) => d.platform === platform);
  }

  if (targetDevices.length === 0) {
    return res.status(400).json({
      success: false,
      error: "Kayıtlı device bulunamadı",
    });
  }

  try {
    const messages = targetDevices.map((device) => ({
      token: device.fcmToken,
      notification: { title, body },
      data: data || {},
      android: {
        priority: "high",
        notification: {
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    }));

    const response = await admin.messaging().sendEach(messages);

    res.json({
      success: true,
      message: "Toplu bildirim gönderildi",
      totalDevices: messages.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
      platform: platform || "all",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
```

#### 4. Özel Bildirimler

##### 4.1 Davetiye Gönder

```http
POST /api/send-invitation
Content-Type: application/json

{
  "inviterId": "user1",
  "invitedUserId": "user2",
  "eventName": "Doğum Günü Partisi"
}
```

**Response**:

```json
{
  "success": true,
  "message": "Davetiye başarıyla gönderildi",
  "invitation": {
    "id": "1704459600000",
    "inviter": "Ahmet Yılmaz",
    "invitedUser": "Mehmet Demir",
    "eventName": "Doğum Günü Partisi"
  },
  "messageId": "projects/xxx/messages/xxx"
}
```

### Swagger API Dokümantasyonu

Backend server çalıştığında Swagger UI'a erişim:

```
http://localhost:3000/api-docs
```

**Özellikler**:

- 📝 Tüm endpoint'lerin detaylı dokümantasyonu
- 🧪 "Try it out" ile direkt API test
- 📊 Request/Response şemaları
- 🏷️ Tag bazlı gruplandırma (Users, Devices, Notifications)

---

## 📱 Mobil Uygulama (Flutter)

### Teknoloji Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: setState (basit demo için)
- **Firebase**:
  - firebase_core
  - firebase_messaging
- **Local Notifications**: flutter_local_notifications
- **Device Info**: device_info_plus
- **Storage**: shared_preferences
- **HTTP**: http package

### Proje Yapısı

```
lib/
├── main.dart                           # Ana uygulama
├── firebase_options.dart               # Firebase konfigürasyonu
├── firebase_messaging_service.dart     # FCM servisi
├── notification_service.dart           # Local notification servisi
├── backend_service.dart                # Backend API servisi
├── invitation_screen.dart              # Davetiye gönderme ekranı
└── device_notification_example.dart    # Kullanım örnekleri
```

### Core Servisler

#### 1. FirebaseMessagingService

**Sorumluluklar**:

- FCM token yönetimi
- Bildirim dinleme (foreground, background, terminated)
- Device ID oluşturma ve yönetimi
- Topic subscription yönetimi

**Kod**:

```dart
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // FCM Token alma (retry mekanizması ile)
  Future<String?> _getTokenWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null) return token;
      } catch (e) {
        print('Attempt ${i + 1} failed to get FCM token: $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: i + 2));
        }
      }
    }
    return null;
  }

  // Servis başlatma
  Future<void> initialize({bool autoSubscribeToAll = true}) async {
    try {
      // İzin isteme
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      print('User granted permission: ${settings.authorizationStatus}');

      // iOS için APNS token bekleme
      await Future.delayed(const Duration(milliseconds: 1000));

      // FCM token al
      _fcmToken = await _getTokenWithRetry();
      print('FCM Token: $_fcmToken');
    } catch (e) {
      print('Error initializing FCM: $e');
    }

    // Token yenileme dinleme
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
    });

    // Foreground bildirim ayarları
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    // Bildirim dinleyicileri
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Uygulama kapalıyken gelen bildirim
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Auto-subscribe
    if (autoSubscribeToAll) {
      await subscribeToTopic('all_users');
    }
  }

  // Foreground bildirimi işle
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Local notification göster
    if (message.notification != null) {
      _notificationService.showNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  // Bildirime tıklanma işle
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Data: ${message.data}');

    // Navigation
    if (message.data.containsKey('screen')) {
      String screen = message.data['screen'];
      print('Navigate to screen: $screen');
    }
  }

  // Device ID oluştur/al
  Future<String?> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');

      if (deviceId == null) {
        final deviceInfo = DeviceInfoPlugin();

        if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ??
                     'ios_${DateTime.now().millisecondsSinceEpoch}';
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else {
          deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }

        await prefs.setString('device_id', deviceId);
      }

      return deviceId;
    } catch (e) {
      print('Error getting device ID: $e');
      return null;
    }
  }

  // Topic subscription
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}
```

#### 2. BackendService

**Sorumluluklar**:

- Backend API iletişimi
- HTTP request/response yönetimi
- Error handling

**Kod**:

```dart
class BackendService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Device kaydet
  static Future<bool> registerDevice({
    required String deviceId,
    required String fcmToken,
    String? userId,
    String? platform,
    String? deviceInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'fcmToken': fcmToken,
          'userId': userId,
          'platform': platform,
          'deviceInfo': deviceInfo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Device kaydedildi: $deviceId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Hata: $e');
      return false;
    }
  }

  // Device'a bildirim gönder
  static Future<bool> sendToDevice({
    required String deviceId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-to-device'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Device\'a bildirim gönderildi');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Hata: $e');
      return false;
    }
  }

  // Toplu bildirim
  static Future<Map<String, dynamic>?> sendBulkToDevices({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? platform,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-bulk-devices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'data': data ?? {},
          if (platform != null) 'platform': platform,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Toplu bildirim gönderildi');
        print('   Başarılı: ${responseData['successCount']}');
        return responseData;
      }
      return null;
    } catch (e) {
      print('❌ Hata: $e');
      return null;
    }
  }

  // Device'ları listele
  static Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['devices']);
      }
      return [];
    } catch (e) {
      print('❌ Hata: $e');
      return [];
    }
  }
}
```

#### 3. Uygulama Başlatma (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // Local notification servisi
  await NotificationService().initialize();

  // Firebase messaging servisi
  await FirebaseMessagingService().initialize();

  runApp(const MyApp());
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseMessagingService _fcmService = FirebaseMessagingService();
  final BackendService _backendService = BackendService();

  String _fcmToken = 'Loading...';
  String _deviceId = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // FCM token al
    await Future.delayed(const Duration(milliseconds: 500));
    final token = _fcmService.fcmToken;
    final deviceId = await _fcmService.getDeviceId();

    setState(() {
      _fcmToken = token ?? 'Token not available';
      _deviceId = deviceId ?? 'Device ID not available';
    });

    // Backend'e kaydet
    if (deviceId != null && token != null) {
      await BackendService.registerDevice(
        deviceId: deviceId,
        fcmToken: token,
        userId: 'user1',
        platform: Platform.operatingSystem,
        deviceInfo: 'Flutter Device',
      );
    }
  }
}
```

---

## 💡 Kullanım Senaryoları

### Senaryo 1: Çoklu Cihaz Yönetimi

**Problem**: Kullanıcının telefon, tablet ve bilgisayarında açık uygulaması var. Sadece telefonuna bildirim göndermek istiyoruz.

**Çözüm**:

```dart
// Her cihaz kendi device ID'si ile kayıtlı
// iPhone: ACB8A869-1456-4F30-8EDC-6E084B86AB62
// iPad: 7689A3F0-4B1D-4B6B-B748-A2C116DBBC5C
// Mac: A5B19B0F-1A83-4E32-8F2D-8A3A58C3FF42

// Sadece iPhone'a bildirim
await BackendService.sendToDevice(
  deviceId: 'ACB8A869-1456-4F30-8EDC-6E084B86AB62',
  title: 'Mobil Bildirim',
  body: 'Bu sadece telefonunda görünür',
);
```

### Senaryo 2: Platform Bazlı Kampanya

**Problem**: iOS kullanıcılarına özel bir kampanya bildirimi göndermek istiyoruz.

**Çözüm**:

```dart
await BackendService.sendBulkToDevices(
  title: 'iOS Özel Kampanya 🍎',
  body: 'iOS kullanıcılarına özel %50 indirim!',
  platform: 'iOS',
  data: {
    'campaign_id': 'ios_special_2024',
    'discount': '50'
  },
);
```

### Senaryo 3: Son Aktif Cihaza Bildirim

**Problem**: Kullanıcının birden fazla cihazı var ama bildirimi en son kullandığı cihaza göndermek istiyoruz.

**Çözüm**:

```dart
final devices = await BackendService.getDevices();

// En son aktif cihazı bul
devices.sort((a, b) =>
  DateTime.parse(b['lastActive'])
    .compareTo(DateTime.parse(a['lastActive']))
);

if (devices.isNotEmpty) {
  await BackendService.sendToDevice(
    deviceId: devices.first['deviceId'],
    title: 'Akıllı Bildirim',
    body: 'En son kullandığın cihaza gönderildi',
  );
}
```

### Senaryo 4: Davetiye Sistemi

**Problem**: Bir kullanıcı diğerini bir etkinliğe davet ediyor.

**Çözüm**:

```dart
// Davet gönderme
await BackendService.sendInvitation(
  inviterId: 'user1',
  invitedUserId: 'user2',
  eventName: 'Doğum Günü Partisi',
);

// Backend'de özel formatlama
notification: {
  title: `📨 ${inviter.name} seni davet etti!`,
  body: `${eventName} etkinliğine katılmak ister misin?`
},
data: {
  type: 'invitation',
  invitationId: invitationId,
  inviterId: inviter.id,
  screen: 'invitation_detail'
}

// Mobil tarafta özel işlem
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  if (message.data['type'] == 'invitation') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvitationDetailScreen(
          invitationId: message.data['invitationId']
        )
      )
    );
  }
});
```

### Senaryo 5: Zamanlanmış Lokal Bildirim

**Problem**: Kullanıcıya belirli bir saatte hatırlatma yapmak istiyoruz.

**Çözüm**:

```dart
await NotificationService().scheduleNotification2(
  title: 'Toplantı Hatırlatması',
  body: 'Saat 14:00\'te toplantınız var',
  hour: 14,
  minute: 0,
);
```

### Senaryo 6: Toplu Broadcast Bildirimi

**Problem**: Sistem genelinde tüm kullanıcılara önemli bir duyuru yapmak istiyoruz.

**Çözüm**:

```dart
// Topic bazlı (Firebase native)
await FirebaseMessaging.instance.subscribeToTopic('announcements');

// Backend'den topic'e gönderme
await admin.messaging().sendToTopic('announcements', {
  notification: {
    title: 'Sistem Duyurusu',
    body: 'Bakım çalışması planlandı'
  }
});

// Veya device bazlı toplu gönderim
await BackendService.sendBulkToDevices(
  title: 'Önemli Duyuru',
  body: 'Tüm kullanıcılara mesaj',
);
```

---

## 🧪 Test ve Geliştirme

### Geliştirme Ortamı Kurulumu

#### 1. Backend

```bash
cd backend_test
npm install
npm start
```

Server başlatıldığında:

- API: http://localhost:3000
- Swagger Docs: http://localhost:3000/api-docs

#### 2. Flutter

```bash
# Bağımlılıkları yükle
flutter pub get

# Çalıştır
flutter run

# Birden fazla cihazda çalıştır
flutter run -d <device-id-1>
flutter run -d <device-id-2>
flutter run -d <device-id-3>
```

### Test Araçları

#### 1. Postman / VS Code REST Client

```http
### Device Kaydet
POST http://localhost:3000/api/register-device
Content-Type: application/json

{
  "deviceId": "test-device-001",
  "fcmToken": "YOUR_FCM_TOKEN",
  "userId": "user1",
  "platform": "iOS"
}

### Device'a Bildirim Gönder
POST http://localhost:3000/api/send-to-device
Content-Type: application/json

{
  "deviceId": "test-device-001",
  "title": "Test Notification",
  "body": "Bu bir test mesajıdır"
}

### Toplu Bildirim
POST http://localhost:3000/api/send-bulk-devices
Content-Type: application/json

{
  "title": "Toplu Test",
  "body": "Tüm cihazlara gönderildi",
  "platform": "iOS"
}
```

#### 2. Firebase Console

Firebase Console'dan manuel test:

1. Firebase Console > Cloud Messaging
2. "Send test message"
3. FCM token gir
4. Test et

#### 3. Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

- Network trafiği izleme
- Log monitoring
- Performance profiling

### Debug Logging

Backend:

```javascript
console.log(`✅ Device kaydedildi: ${deviceId}`);
console.log(`📤 Bildirim gönderildi: ${response.successCount}/${total}`);
```

Flutter:

```dart
print('FCM Token: $token');
print('Device ID: $deviceId');
print('✅ Backend\'e kaydedildi');
```

---

## 🚀 Deployment ve Production

### Backend Deployment

#### 1. Environment Variables

```bash
# .env dosyası oluştur
PORT=3000
NODE_ENV=production
FIREBASE_SERVICE_ACCOUNT_PATH=./service_account.json
```

#### 2. Production Database

Memory storage yerine gerçek database kullan:

```javascript
// MongoDB örneği
const mongoose = require("mongoose");

const DeviceSchema = new mongoose.Schema({
  deviceId: { type: String, unique: true, required: true },
  fcmToken: { type: String, required: true },
  userId: String,
  platform: String,
  deviceInfo: String,
  registeredAt: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now },
});

const Device = mongoose.model("Device", DeviceSchema);
```

#### 3. Güvenlik

```javascript
// Rate limiting
const rateLimit = require("express-rate-limit");

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100, // max 100 request
});

app.use("/api/", limiter);

// JWT Authentication
const jwt = require("jsonwebtoken");

function authenticateToken(req, res, next) {
  const token = req.header("Authorization")?.split(" ")[1];
  if (!token) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

app.use("/api/send-*", authenticateToken);
```

#### 4. Hosting Seçenekleri

- **Heroku**: Kolay deployment
- **AWS EC2**: Tam kontrol
- **Google Cloud Run**: Serverless, otomatik scaling
- **DigitalOcean**: Basit ve uygun fiyatlı

```bash
# Heroku deployment
heroku create notification-backend
git push heroku main

# Cloud Run deployment
gcloud run deploy notification-backend \
  --source . \
  --platform managed \
  --region us-central1
```

### Flutter Production Build

#### iOS

```bash
# Release build
flutter build ios --release

# Archive ve App Store yükleme
# Xcode'da:
# Product > Archive
# Distribute App
```

**iOS Gereksinimleri**:

- Apple Developer hesabı ($99/yıl)
- APNs sertifikası
- Provisioning profile
- Push Notification capability aktif

#### Android

```bash
# Release build
flutter build apk --release

# veya App Bundle (önerilen)
flutter build appbundle --release
```

**Android Gereksinimleri**:

- google-services.json dosyası
- Signing key konfigürasyonu
- Firebase Cloud Messaging API aktif

### Production Checklist

- [ ] Firebase service account güvenli şekilde saklanıyor
- [ ] Environment variables kullanılıyor
- [ ] Rate limiting aktif
- [ ] Authentication/Authorization implementasyonu
- [ ] Error handling ve logging
- [ ] Database backup stratejisi
- [ ] Monitoring ve alerting (Sentry, Firebase Crashlytics)
- [ ] SSL/HTTPS zorunlu
- [ ] CORS politikaları doğru konfigüre edilmiş
- [ ] API dokümantasyonu güncel
- [ ] Test coverage yeterli
- [ ] Performance optimization yapılmış

---

## 📊 Performans ve Best Practices

### Backend Optimizasyonları

1. **Connection Pooling**

```javascript
// Database connection pool
mongoose.connect(mongoUri, {
  maxPoolSize: 10,
  minPoolSize: 5,
});
```

2. **Caching**

```javascript
const NodeCache = require("node-cache");
const cache = new NodeCache({ stdTTL: 600 }); // 10 dakika

app.get("/api/devices", (req, res) => {
  const cached = cache.get("devices");
  if (cached) return res.json(cached);

  // Fetch from database
  const devices = getDevicesFromDB();
  cache.set("devices", devices);
  res.json(devices);
});
```

3. **Batch Processing**

```javascript
// Toplu bildirimler için batch processing
const BATCH_SIZE = 500;
const batches = [];

for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
  batches.push(tokens.slice(i, i + BATCH_SIZE));
}

for (const batch of batches) {
  await admin.messaging().sendEach(batch);
}
```

### Flutter Optimizasyonları

1. **Lazy Loading**

```dart
// Cihaz listesini sadece gerektiğinde yükle
if (_registeredDevices.isEmpty) {
  await _loadDevices();
}
```

2. **State Management**

```dart
// Provider veya Riverpod kullan (büyük projelerde)
final deviceProvider = StateNotifierProvider<DeviceNotifier, List<Device>>(
  (ref) => DeviceNotifier()
);
```

3. **Network Error Handling**

```dart
Future<bool> sendNotificationWithRetry({int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await BackendService.sendToDevice(...);
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: math.pow(2, i).toInt()));
    }
  }
  return false;
}
```

### Firebase Best Practices

1. **Token Yenileme**

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  final deviceId = await getDeviceId();
  await BackendService.registerDevice(
    deviceId: deviceId,
    fcmToken: newToken,
  );
});
```

2. **Topic Management**

```dart
// User'ın ilgi alanlarına göre topic subscription
if (user.interests.contains('sports')) {
  await FirebaseMessaging.instance.subscribeToTopic('sports');
}
```

3. **Notification Priority**

```javascript
// Kritik bildirimler için high priority
{
  android: {
    priority: 'high'
  },
  apns: {
    headers: {
      'apns-priority': '10'
    }
  }
}
```

---

## 🔒 Güvenlik Notları

### Backend Güvenlik

1. **API Keys Güvenliği**

   - Service account key asla git'e commitlenmesin
   - Environment variables kullan
   - `.gitignore`'a ekle

2. **Input Validation**

```javascript
const { body, validationResult } = require("express-validator");

app.post(
  "/api/send-to-device",
  [
    body("deviceId").isString().trim().notEmpty(),
    body("title").isString().trim().isLength({ max: 100 }),
    body("body").isString().trim().isLength({ max: 500 }),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    // ...
  }
);
```

3. **Rate Limiting per User**

```javascript
const userRateLimiter = rateLimit({
  keyGenerator: (req) => req.user.id,
  windowMs: 60 * 1000,
  max: 10,
});
```

### Mobil Güvenlik

1. **API Endpoint Gizleme**

```dart
// .env dosyası kullan (flutter_dotenv)
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
```

2. **SSL Pinning**

```dart
// Certificate pinning
import 'package:http/io_client.dart';

final client = IOClient(
  HttpClient()
    ..badCertificateCallback = (cert, host, port) {
      return cert.sha1.toUpperCase() == expectedFingerprint;
    }
);
```

3. **Secure Storage**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'fcm_token', value: token);
```

---

## 📚 Kaynaklar

### Dokümantasyonlar

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Flutter Firebase](https://firebase.flutter.dev/)
- [Swagger Documentation](https://swagger.io/docs/)

### Paketler

**Flutter**:

- [firebase_core](https://pub.dev/packages/firebase_core)
- [firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [device_info_plus](https://pub.dev/packages/device_info_plus)

**Node.js**:

- [firebase-admin](https://www.npmjs.com/package/firebase-admin)
- [express](https://www.npmjs.com/package/express)
- [swagger-ui-express](https://www.npmjs.com/package/swagger-ui-express)

---

## 🎓 Sonuç

Bu sistem, modern bir mobile push notification altyapısı için gereken tüm özellikleri sunar:

✅ **Device ID bazlı** bildirim yönetimi ile her cihaza ayrı kontrol  
✅ **Firebase Cloud Messaging** entegrasyonu ile güvenilir bildirim iletimi  
✅ **RESTful API** ile kolay entegrasyon  
✅ **Swagger dokümantasyonu** ile geliştiricilere destek  
✅ **Platform filtreleme** ile hedefli bildirimler  
✅ **Toplu bildirim** desteği ile verimli operasyon  
✅ **Production-ready** kod yapısı

Bu dokümantasyon, projeyi anlamak, geliştirmek ve production ortamına taşımak için gereken tüm bilgileri içermektedir.

---

**Son Güncelleme**: 5 Ocak 2026  
**Versiyon**: 1.0.0  
**Geliştirici**: Notification Team
