import 'package:notification_example/firebase_messaging_service.dart';

/// Bu dosya, device ID bazlı bildirim sistemi için kullanım örneklerini gösterir

class DeviceNotificationExample {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  /// Uygulama başlatıldığında çağrılmalı
  Future<void> initializeWithDeviceId() async {
    // 1. Firebase Messaging servisini başlat
    await _messagingService.initialize();

    // 2. Device ID'yi al
    final deviceId = await _messagingService.getDeviceId();
    print('Current Device ID: $deviceId');

    // 3. (Opsiyonel) Kullanıcı giriş yaptıktan sonra device bilgilerini backend'e kaydet
    // await _messagingService.registerDeviceToServer(
    //   userId: 'user_123',
    //   additionalData: 'iPhone 15 Pro',
    // );
  }

  /// Backend'den belirli bir cihaza bildirim göndermek için kullanılacak bilgiler
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceId = await _messagingService.getDeviceId();
    final fcmToken = _messagingService.fcmToken;

    return {
      'device_id': deviceId ?? 'unknown',
      'fcm_token': fcmToken ?? 'not_available',
    };
  }
}

/* ==========================================
 * BACKEND TARAFINDA NASIL KULLANILIR?
 * ==========================================
 * 
 * 1. Veritabanında device kaydetme:
 * 
 * CREATE TABLE user_devices (
 *   id SERIAL PRIMARY KEY,
 *   user_id VARCHAR(50),
 *   device_id VARCHAR(100) UNIQUE,
 *   fcm_token TEXT,
 *   platform VARCHAR(20),
 *   registered_at TIMESTAMP,
 *   last_active TIMESTAMP
 * );
 * 
 * ==========================================
 * 2. Belirli bir cihaza bildirim gönderme (Node.js örneği):
 * 
 * const admin = require('firebase-admin');
 * 
 * async function sendToSpecificDevice(deviceId, message) {
 *   // Veritabanından device'ın FCM token'ını al
 *   const device = await db.query(
 *     'SELECT fcm_token FROM user_devices WHERE device_id = $1',
 *     [deviceId]
 *   );
 *   
 *   if (!device.rows.length) {
 *     throw new Error('Device not found');
 *   }
 * 
 *   const fcmToken = device.rows[0].fcm_token;
 * 
 *   // FCM mesajı gönder (target_device_id ekleyerek)
 *   const payload = {
 *     token: fcmToken,
 *     notification: {
 *       title: message.title,
 *       body: message.body,
 *     },
 *     data: {
 *       target_device_id: deviceId,  // Bu önemli!
 *       screen: message.screen || '',
 *       // Diğer custom data
 *     },
 *   };
 * 
 *   const response = await admin.messaging().send(payload);
 *   console.log('Successfully sent message:', response);
 *   return response;
 * }
 * 
 * ==========================================
 * 3. Kullanıcının tüm cihazlarına bildirim gönderme:
 * 
 * async function sendToUserAllDevices(userId, message) {
 *   // Kullanıcının tüm device'larını al
 *   const devices = await db.query(
 *     'SELECT fcm_token, device_id FROM user_devices WHERE user_id = $1',
 *     [userId]
 *   );
 * 
 *   const tokens = devices.rows.map(d => d.fcm_token);
 * 
 *   const payload = {
 *     tokens: tokens,
 *     notification: {
 *       title: message.title,
 *       body: message.body,
 *     },
 *     data: {
 *       screen: message.screen || '',
 *     },
 *   };
 * 
 *   const response = await admin.messaging().sendMulticast(payload);
 *   console.log(`Sent to ${response.successCount} devices`);
 *   return response;
 * }
 * 
 * ==========================================
 * 4. Belirli device'ları hariç tutarak gönderme:
 * 
 * async function sendToUserExceptDevice(userId, excludeDeviceId, message) {
 *   const devices = await db.query(
 *     'SELECT fcm_token FROM user_devices WHERE user_id = $1 AND device_id != $2',
 *     [userId, excludeDeviceId]
 *   );
 * 
 *   const tokens = devices.rows.map(d => d.fcm_token);
 * 
 *   if (tokens.length === 0) {
 *     console.log('No other devices found for user');
 *     return;
 *   }
 * 
 *   const payload = {
 *     tokens: tokens,
 *     notification: {
 *       title: message.title,
 *       body: message.body,
 *     },
 *   };
 * 
 *   return await admin.messaging().sendMulticast(payload);
 * }
 * 
 * ==========================================
 * 5. API Endpoint Örnekleri (Express.js):
 * 
 * // Device kaydetme
 * app.post('/api/device/register', async (req, res) => {
 *   const { device_id, fcm_token, user_id, platform } = req.body;
 *   
 *   await db.query(
 *     `INSERT INTO user_devices (user_id, device_id, fcm_token, platform, registered_at, last_active)
 *      VALUES ($1, $2, $3, $4, NOW(), NOW())
 *      ON CONFLICT (device_id) 
 *      DO UPDATE SET fcm_token = $3, last_active = NOW()`,
 *     [user_id, device_id, fcm_token, platform]
 *   );
 *   
 *   res.json({ success: true, message: 'Device registered' });
 * });
 * 
 * // Belirli device'a bildirim gönderme
 * app.post('/api/notification/send-to-device', async (req, res) => {
 *   const { device_id, title, body, data } = req.body;
 *   
 *   try {
 *     const result = await sendToSpecificDevice(device_id, {
 *       title,
 *       body,
 *       ...data
 *     });
 *     res.json({ success: true, result });
 *   } catch (error) {
 *     res.status(500).json({ success: false, error: error.message });
 *   }
 * });
 * 
 * // Kullanıcının tüm cihazlarına gönderme
 * app.post('/api/notification/send-to-user', async (req, res) => {
 *   const { user_id, title, body } = req.body;
 *   
 *   const result = await sendToUserAllDevices(user_id, { title, body });
 *   res.json({ success: true, result });
 * });
 * 
 * ==========================================
 * 6. Flutter tarafında kullanım:
 * 
 * // main.dart veya ilgili sayfada:
 * 
 * void main() async {
 *   WidgetsFlutterBinding.ensureInitialized();
 *   await Firebase.initializeApp();
 *   
 *   final messagingService = FirebaseMessagingService();
 *   await messagingService.initialize();
 *   
 *   // Kullanıcı giriş yaptıktan sonra:
 *   // await messagingService.registerDeviceToServer(
 *   //   userId: currentUser.id,
 *   //   additionalData: 'iPhone 15 Pro',
 *   // );
 *   
 *   runApp(MyApp());
 * }
 * 
 * // Device ID'yi almak için:
 * final deviceId = await FirebaseMessagingService().getDeviceId();
 * print('Device ID: $deviceId');
 * 
 * ==========================================
 * NOTLAR:
 * 
 * 1. Bildirim göndermeden önce, message.data içinde 'target_device_id' 
 *    alanı olup olmadığını kontrol eden kod ekledik.
 * 
 * 2. Eğer 'target_device_id' varsa ve mevcut device ID ile eşleşmiyorsa,
 *    bildirim gösterilmeyecek.
 * 
 * 3. Birden fazla device'a göndermek için 'target_device_ids' alanında
 *    virgülle ayrılmış device ID'leri gönderebilirsiniz:
 *    data: { target_device_ids: "device1,device2,device3" }
 * 
 * 4. registerDeviceToServer metodunu kendi API'nize göre düzenlemelisiniz.
 * 
 * 5. Device ID'ler shared_preferences'da saklanır, böylece her seferinde
 *    aynı ID kullanılır.
 */
