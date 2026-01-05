# Device ID Bazlı Bildirim Sistemi

Bu güncelleme ile artık bildirimleri **Device ID**'ye göre gönderebilirsiniz. Bu sayede:

✅ Her cihaz benzersiz ID ile tanımlanır  
✅ Aynı kullanıcının farklı cihazlarına ayrı ayrı bildirim gönderilebilir  
✅ Kullanıcı bağımsız, cihaz bazlı bildirim yönetimi

## 🚀 Nasıl Çalışır?

### 1. Backend API Endpoint'leri

#### Device Kaydı

```bash
POST /api/register-device
```

**Request Body:**

```json
{
  "deviceId": "unique-device-id-123",
  "fcmToken": "fcm-token-xyz",
  "userId": "user1", // Opsiyonel
  "platform": "iOS", // Opsiyonel
  "deviceInfo": "iPhone 15" // Opsiyonel
}
```

#### Device'a Bildirim Gönder

```bash
POST /api/send-to-device
```

**Request Body:**

```json
{
  "deviceId": "unique-device-id-123",
  "title": "Bildirim Başlığı",
  "body": "Bildirim içeriği",
  "data": {
    "customKey": "customValue"
  }
}
```

#### Kayıtlı Device'ları Listele

```bash
GET /api/devices
```

**Response:**

```json
{
  "success": true,
  "totalDevices": 2,
  "devices": [
    {
      "deviceId": "device-001",
      "platform": "iOS",
      "userId": "user1",
      "registeredAt": "2026-01-05T10:30:00Z",
      "lastActive": "2026-01-05T12:15:00Z",
      "hasToken": true
    }
  ]
}
```

### 2. Flutter Tarafında Kullanım

#### Device ID'yi Al

```dart
final fcmService = FirebaseMessagingService();
final deviceId = await fcmService.getDeviceId();
print('Device ID: $deviceId');
```

#### Device'ı Backend'e Kaydet

```dart
await BackendService.registerDevice(
  deviceId: deviceId,
  fcmToken: fcmToken,
  userId: 'user1',
  platform: 'iOS',
  deviceInfo: 'iPhone 15 Pro',
);
```

#### Device'a Bildirim Gönder

```dart
await BackendService.sendToDevice(
  deviceId: 'target-device-id',
  title: 'Test Notification',
  body: 'Bu mesaj sadece senin cihazına gönderildi',
  data: {'type': 'custom'},
);
```

#### Kayıtlı Device'ları Listele

```dart
final devices = await BackendService.getDevices();
for (var device in devices) {
  print('Device: ${device['deviceId']} - ${device['platform']}');
}
```

## 📱 User Bazlı vs Device Bazlı

### User Bazlı (Eski Yöntem)

```dart
// User ID ile - aynı user ID'ye sahip TÜM cihazlara gider
await BackendService.sendNotification(
  userId: 'user1',
  title: 'Bildirim',
  body: 'Tüm cihazlara gider',
);
```

### Device Bazlı (Yeni Yöntem)

```dart
// Device ID ile - SADECE belirtilen cihaza gider
await BackendService.sendToDevice(
  deviceId: 'device-001',
  title: 'Bildirim',
  body: 'Sadece bu cihaza gider',
);
```

## 🎯 Kullanım Senaryoları

### 1. Çoklu Cihaz Yönetimi

Kullanıcının telefon, tablet ve web'de açık uygulaması varsa:

```dart
// Sadece telefona bildirim
await BackendService.sendToDevice(
  deviceId: userPhoneDeviceId,
  title: 'Mobil Bildirim',
  body: 'Sadece telefonda görünür',
);

// Sadece tablete bildirim
await BackendService.sendToDevice(
  deviceId: userTabletDeviceId,
  title: 'Tablet Bildirim',
  body: 'Sadece tablette görünür',
);
```

### 2. Platform Bazlı Bildirim

```dart
final devices = await BackendService.getDevices();

// Sadece iOS cihazlara gönder
for (var device in devices) {
  if (device['platform'] == 'iOS') {
    await BackendService.sendToDevice(
      deviceId: device['deviceId'],
      title: 'iOS Özel Bildirim',
      body: 'Bu sadece iOS cihazlar için',
    );
  }
}
```

### 3. Son Aktif Cihaza Bildirim

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

## 🔧 Test Etme

### 1. Backend'i Başlat

```bash
cd backend_test
npm install
npm start
```

### 2. Flutter Uygulamasını Çalıştır

```bash
flutter run
```

### 3. Postman veya VS Code REST Client ile Test

`device-test-requests.http` dosyasını kullan.

## 📊 Veritabanı Yapısı (Örnek)

Production ortamında kullanabileceğiniz tablo yapısı:

```sql
CREATE TABLE user_devices (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(50),
  device_id VARCHAR(100) UNIQUE NOT NULL,
  fcm_token TEXT NOT NULL,
  platform VARCHAR(20),
  device_info TEXT,
  registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_device_id ON user_devices(device_id);
CREATE INDEX idx_user_id ON user_devices(user_id);
CREATE INDEX idx_last_active ON user_devices(last_active);
```

## 🎨 UI Değişiklikleri

Ana ekranda:

- ✅ Device ID gösterimi eklendi
- ✅ "Device'a Bildirim Gönder" butonu eklendi
- ✅ Kayıtlı cihazları listeleyen dialog
- ✅ Platform ikonları (iOS/Android)

## 🔐 Güvenlik Notları

⚠️ Production ortamında:

1. Device ID'yi JWT token ile doğrulayın
2. Rate limiting uygulayın
3. Device sayısını kullanıcı başına sınırlayın
4. Eski/inactive cihazları temizleyin

## 📝 Örnek Kullanım

```dart
// Uygulama başlatıldığında
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final fcmService = FirebaseMessagingService();
  await fcmService.initialize();

  // Device'ı kaydet
  final deviceId = await fcmService.getDeviceId();
  final token = fcmService.fcmToken;

  if (deviceId != null && token != null) {
    await BackendService.registerDevice(
      deviceId: deviceId,
      fcmToken: token,
      userId: getCurrentUserId(), // Kullanıcı giriş yaptıktan sonra
      platform: Platform.operatingSystem,
    );
  }

  runApp(MyApp());
}
```

## 🎉 Başarılı!

Artık device bazlı bildirim sisteminiz hazır! 🚀
