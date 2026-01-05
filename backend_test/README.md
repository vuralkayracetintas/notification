# 🚀 Notification Backend Test Server

MongoDB tabanlı Node.js backend servisi.

## 📦 Kurulum

```bash
cd backend_test

# Dependencies yükle
npm install

# MongoDB'yi başlat
brew services start mongodb-community

# Service account JSON'ı kopyala
cp ../service_account.json ./service_account.json
```

## ▶️ Çalıştırma

```bash
# Normal mod
npm start

# Development mod (auto-restart)
npm run dev
```

Server: `http://localhost:3000`
Swagger API Docs: `http://localhost:3000/api-docs`

## 🗄️ Database

- **MongoDB**: `mongodb://localhost:27017/notification_db`
- **Collections**:
  - `users` - Kullanıcı bilgileri
  - `devices` - Cihaz kayıtları

## 📋 Kullanıcı Yönetimi

Artık hardcoded kullanıcılar yok! Kullanıcılar MongoDB'de dinamik olarak yönetiliyor.

## 🔌 API Endpoints

### User Management

#### 1. Kullanıcıları Listele

```bash
GET http://localhost:3000/api/users
```

#### 2. Yeni Kullanıcı Oluştur

```bash
POST http://localhost:3000/api/create-user
Content-Type: application/json

{
  "name": "Ali Veli",
  "email": "ali@example.com"
}
```

#### 3. FCM Token Kaydet

```bash
POST http://localhost:3000/api/register-token
Content-Type: application/json

{
  "userId": "65abc123def456789",  // MongoDB ObjectId
  "fcmToken": "YOUR_FCM_TOKEN_FROM_APP"
}
```

### Device Management

#### 4. Device Kaydet

```bash
POST http://localhost:3000/api/register-device
Content-Type: application/json

{
  "deviceId": "device-uuid-123",
  "fcmToken": "YOUR_FCM_TOKEN",
  "userId": "65abc123def456789",
  "platform": "iOS",
  "deviceInfo": "iPhone 15 Pro"
}
```

#### 5. Kayıtlı Device'ları Listele

```bash
GET http://localhost:3000/api/devices
```

### Notification Endpoints

#### 6. Basit Bildirim Gönder (User Bazlı)

```bash
POST http://localhost:3000/api/send-notification
Content-Type: application/json

{
  "userId": "65abc123def456789",
  "title": "Test Bildirimi",
  "body": "Bu bir test mesajıdır",
  "data": {
    "screen": "home"
  }
}
```

#### 7. Device'a Bildirim Gönder

```bash
POST http://localhost:3000/api/send-to-device
Content-Type: application/json

{
  "deviceId": "device-uuid-123",
  "title": "Cihaza Özel",
  "body": "Bu bildirim sadece bu cihaza gönderildi",
  "data": {}
}
```

#### 8. Seçili Device'lara Toplu Bildirim (YENİ!)

```bash
POST http://localhost:3000/api/send-to-multiple-devices
Content-Type: application/json

{
  "deviceIds": ["device-123", "device-456", "device-789"],
  "title": "Seçili Cihazlara Bildirim",
  "body": "Bu bildirim sadece seçili cihazlara gönderildi",
  "data": {
    "type": "selected"
  }
}
```

**Response:**

```json
{
  "success": true,
  "totalDevices": 50,
  "foundDevices": 48,
  "notFoundDevices": 2,
  "notFoundList": ["device-999", "device-888"],
  "successCount": 47,
  "failureCount": 1,
  "batchCount": 1,
  "batchSize": 500
}
```

#### 9. Tüm Device'lara Toplu Bildirim

```bash
POST http://localhost:3000/api/send-bulk-devices
Content-Type: application/json

{
  "title": "📢 Duyuru",
  "body": "Bu mesaj tüm cihazlara gönderildi",
  "data": {
    "type": "announcement"
  },
  "platform": "iOS"  // Opsiyonel: "iOS" veya "Android"
}
```

**Response:**

```json
{
  "success": true,
  "totalDevices": 2000,
  "successCount": 1993,
  "failureCount": 7,
  "batchCount": 4,
  "batchSize": 500,
  "platform": "iOS"
}
```

#### 10. Davetiye Gönder

#### 10. Davetiye Gönder

```bash
POST http://localhost:3000/api/send-invitation
Content-Type: application/json

{
  "inviterId": "65abc123def456789",
  "invitedUserId": "65abc987fed654321",
  "eventName": "Doğum günü partisi"
}
```

#### 11. Mesaj Bildirimi

```bash
POST http://localhost:3000/api/send-message
Content-Type: application/json

{
  "senderId": "65abc123def456789",
  "recipientId": "65abc987fed654321",
  "messageText": "Merhaba, nasılsın?"
}
```

#### 12. Toplu Bildirim (Tüm Kullanıcılara)

```bash
POST http://localhost:3000/api/send-bulk
Content-Type: application/json

{
  "title": "📢 Duyuru",
  "body": "Bu mesaj tüm kullanıcılara gönderildi",
  "data": {
    "type": "announcement"
  }
}
```

## 📊 Batch Processing

Toplu bildirim endpoint'leri otomatik olarak **500'lük gruplar** halinde gönderir:

- **2000 cihaz** = 4 batch (500+500+500+500)
- **10,000 cihaz** = 20 batch
- **Sınırsız** cihaz desteği

**Console Output:**

```
📤 2000 cihaza 4 batch halinde gönderiliyor...
   Batch 1/4: 500/500 başarılı
   Batch 2/4: 498/500 başarılı
   Batch 3/4: 500/500 başarılı
   Batch 4/4: 495/500 başarılı
✅ Toplu device bildirimi tamamlandı: 1993/2000 başarılı
```

## 🧪 Test Senaryosu

### Adım 1: Kullanıcı Oluştur

```bash
curl -X POST http://localhost:3000/api/create-user \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com"
  }'
```

Response'dan `userId`'yi kopyala (örn: `65abc123def456789`)

### Adım 2: Flutter App'te Device Kaydet

Flutter uygulamanızda UserSelectionScreen'den kullanıcıyı seç. Uygulama otomatik olarak:

- FCM token alır
- Device'ı kaydeder
- MongoDB'ye kaydeder

### Adım 3: Bildirim Gönder

**Tek cihaza:**

```bash
curl -X POST http://localhost:3000/api/send-to-device \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "YOUR_DEVICE_ID",
    "title": "Merhaba!",
    "body": "Backend test başarılı 🎉"
  }'
```

**Seçili cihazlara:**

```bash
curl -X POST http://localhost:3000/api/send-to-multiple-devices \
  -H "Content-Type: application/json" \
  -d '{
    "deviceIds": ["device-1", "device-2", "device-3"],
    "title": "Seçili Grup",
    "body": "3 cihaza özel bildirim"
  }'
```

**Tüm cihazlara:**

```bash
curl -X POST http://localhost:3000/api/send-bulk-devices \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Toplu Bildirim",
    "body": "Herkese gönderildi",
    "platform": "iOS"
  }'
```

### Adım 4: Flutter App'te Bildirim Gelir ✅

## 💡 Postman ile Test

1. Postman'i aç
2. Import → Raw Text
3. Aşağıdaki collection'ı yapıştır:

```json
{
  "info": {
    "name": "Notification Backend Test",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Register FCM Token",
      "request": {
        "method": "POST",
        "header": [{ "key": "Content-Type", "value": "application/json" }],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"userId\": \"user1\",\n  \"fcmToken\": \"YOUR_TOKEN_HERE\"\n}"
        },
        "url": "http://localhost:3000/api/register-token"
      }
    },
    {
      "name": "Send Notification",
      "request": {
        "method": "POST",
        "header": [{ "key": "Content-Type", "value": "application/json" }],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"userId\": \"user1\",\n  \"title\": \"Test\",\n  \"body\": \"Backend'den bildirim\"\n}"
        },
        "url": "http://localhost:3000/api/send-notification"
      }
    },
    {
      "name": "Send Invitation",
      "request": {
        "method": "POST",
        "header": [{ "key": "Content-Type", "value": "application/json" }],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"inviterId\": \"user1\",\n  \"invitedUserId\": \"user2\",\n  \"eventName\": \"Parti\"\n}"
        },
        "url": "http://localhost:3000/api/send-invitation"
      }
    }
  ]
}
```

## 🔍 Console Logları

Server çalışırken her işlem için detaylı log göreceksiniz:

```
✅ MongoDB bağlantısı başarılı
✅ Yeni kullanıcı oluşturuldu: Test User
✅ Device kaydedildi: device-uuid-123 (iOS)
✅ Token kaydedildi: Test User
📤 50 cihaza 1 batch halinde gönderiliyor...
   Batch 1/1: 48/50 başarılı
✅ Toplu device bildirimi tamamlandı: 48/50 başarılı
⚠️  2 device bulunamadı: device-999, device-888
```

## 📱 Flutter Features

### User Selection Screen

- MongoDB'den dinamik kullanıcı listesi
- Yeni kullanıcı oluşturma formu
- Avatar ve token durumu gösterimi

### Main Screen Features

1. **📢 Toplu Bildirim (Tüm Cihazlar)** - Tüm kayıtlı cihazlara
2. **📱 Seçili Cihazlara Gönder** - Checkbox ile seçim
3. **📨 Davetiye Gönder** - Kullanıcılar arası davetiye
4. **💬 Mesaj Gönder** - Direkt mesaj bildirimi

### Seçili Cihazlara Gönderim

- Device listesinden checkbox ile seçim
- "Tümünü Seç" butonu
- Platform bilgisi (iOS/Android)
- Detaylı sonuç raporu

## ⚠️ Önemli Notlar

- ✅ MongoDB gerekli (`brew services start mongodb-community`)
- ✅ `service_account.json` dosyası gerekli
- ✅ Port 3000 kullanılıyor
- ✅ Swagger docs: `http://localhost:3000/api-docs`
- ✅ Batch processing: Otomatik 500'lük gruplar
- ✅ Sınırsız cihaz desteği

## 🎯 Firebase Limits

| Metod           | Limit     | Çözüm            |
| --------------- | --------- | ---------------- |
| `send()`        | 1 cihaz   | Tek gönderim     |
| `sendEach()`    | 500 cihaz | Batch processing |
| `sendToTopic()` | Sınırsız  | Topic kullan     |

## 🚀 Production Checklist

- [x] MongoDB entegrasyonu
- [x] User management
- [x] Device tracking
- [x] Batch processing
- [x] Error handling
- [x] Detailed logging
- [ ] Authentication (JWT)
- [ ] Rate limiting
- [ ] HTTPS/SSL
- [ ] Environment variables
- [ ] Docker container
- [ ] Load balancing
