# 🚀 Notification Backend Test Server

Local test için basit Node.js backend servisi.

## 📦 Kurulum

```bash
cd backend_test

# Dependencies yükle
npm install

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

## 📋 Test Kullanıcıları

- **user1**: Ahmet Yılmaz (ahmet@example.com)
- **user2**: Mehmet Demir (mehmet@example.com)
- **user3**: Ayşe Kaya (ayse@example.com)

## 🔌 API Endpoints

### 1. Health Check

```bash
GET http://localhost:3000/
```

### 2. Kullanıcıları Listele

```bash
GET http://localhost:3000/api/users
```

### 3. FCM Token Kaydet

```bash
POST http://localhost:3000/api/register-token
Content-Type: application/json

{
  "userId": "user1",
  "fcmToken": "YOUR_FCM_TOKEN_FROM_APP"
}
```

### 4. Basit Bildirim Gönder

```bash
POST http://localhost:3000/api/send-notification
Content-Type: application/json

{
  "userId": "user1",
  "title": "Test Bildirimi",
  "body": "Bu bir test mesajıdır",
  "data": {
    "screen": "home"
  }
}
```

### 5. Davetiye Gönder

```bash
POST http://localhost:3000/api/send-invitation
Content-Type: application/json

{
  "inviterId": "user1",
  "invitedUserId": "user2",
  "eventName": "Doğum günü partisi"
}
```

### 6. Mesaj Bildirimi

```bash
POST http://localhost:3000/api/send-message
Content-Type: application/json

{
  "senderId": "user1",
  "recipientId": "user2",
  "messageText": "Merhaba, nasılsın?"
}
```

### 7. Toplu Bildirim (Herkese)

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

## 🧪 Test Senaryosu

### 1. Flutter App'te FCM Token Al

Flutter uygulamanızı çalıştırın ve FCM token'ı kopyalayın (ana ekranda gösteriliyor).

### 2. Token'ı Backend'e Kaydet

```bash
curl -X POST http://localhost:3000/api/register-token \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user1",
    "fcmToken": "KOPYALADIĞINIZ_TOKEN"
  }'
```

### 3. Bildirim Gönder

```bash
curl -X POST http://localhost:3000/api/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user1",
    "title": "Merhaba!",
    "body": "Backend test başarılı 🎉"
  }'
```

### 4. Flutter App'te Bildirim Gelir ✅

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

Server çalışırken her bildirim gönderiminde log göreceksiniz:

```
✅ Token kaydedildi: Ahmet Yılmaz
✅ Bildirim gönderildi: Ahmet Yılmaz
✅ Davetiye gönderildi: Ahmet Yılmaz → Mehmet Demir
```

## ⚠️ Notlar

- `service_account.json` dosyası gerekli!
- Port 3000 kullanılıyor (değiştirmek için `server.js`)
- Mock database kullanıyor (gerçek DB yok)
- Token'lar memory'de tutuluyor (restart'ta sıfırlanır)

## 🎯 Sonraki Adımlar

Production için:

- Gerçek database ekle (PostgreSQL, MongoDB)
- Authentication ekle (JWT)
- Rate limiting ekle
- Logging sistemi ekle (Winston)
- Environment variables düzenle
