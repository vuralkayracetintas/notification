import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

class BackendService {
  // Local test server
  static const String baseUrl = 'http://localhost:3000/api';

  // Production için değiştir:
  // static const String baseUrl = 'https://your-api.com/api';

  /// FCM Token'ı backend'e kaydet
  static Future<bool> registerFCMToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) {
        print('FCM token alınamadı');
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token backend\'e kaydedildi');
        return true;
      } else {
        print('❌ Token kaydetme hatası: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Hata: $e');
      return false;
    }
  }

  /// Davetiye gönder
  static Future<Map<String, dynamic>?> sendInvitation({
    required String inviterId,
    required String invitedUserId,
    required String eventName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-invitation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inviterId': inviterId,
          'invitedUserId': invitedUserId,
          'eventName': eventName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Davetiye gönderildi: ${data['message']}');
        return data;
      } else {
        print('❌ Davetiye hatası: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Hata: $e');
      return null;
    }
  }

  /// Basit bildirim gönder
  static Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Bildirim gönderildi');
        return true;
      } else {
        print('❌ Bildirim hatası: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Hata: $e');
      return false;
    }
  }

  /// Mesaj bildirimi gönder
  static Future<bool> sendMessage({
    required String senderId,
    required String recipientId,
    required String messageText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'recipientId': recipientId,
          'messageText': messageText,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Mesaj bildirimi gönderildi');
        return true;
      } else {
        print('❌ Mesaj hatası: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Hata: $e');
      return false;
    }
  }

  /// Tüm kullanıcıları listele
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['users']);
      } else {
        print('❌ Kullanıcı listesi hatası: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Hata: $e');
      return [];
    }
  }

  // ===== DEVICE BAZLI BİLDİRİM METODLARi =====

  /// Device bilgilerini backend'e kaydet
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
        print('   Kayıt zamanı: ${data['registeredAt']}');
        return true;
      } else {
        print('❌ Device kaydetme hatası: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Hata: $e');
      return false;
    }
  }

  /// Belirli bir device'a bildirim gönder
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
        final responseData = jsonDecode(response.body);
        print('✅ Device\'a bildirim gönderildi');
        print('   Device ID: $deviceId');
        print('   Message ID: ${responseData['messageId']}');
        return true;
      } else {
        print('❌ Device bildirim hatası: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Hata: $e');
      return false;
    }
  }

  /// Kayıtlı tüm device'ları listele
  static Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Toplam ${data['totalDevices']} device kayıtlı');
        return List<Map<String, dynamic>>.from(data['devices']);
      } else {
        print('❌ Device listesi hatası: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Hata: $e');
      return [];
    }
  }

  /// Tüm kayıtlı device'lara toplu bildirim gönder
  static Future<Map<String, dynamic>?> sendBulkToDevices({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? platform, // 'iOS', 'Android' veya null (tümü)
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
        print('   Toplam device: ${responseData['totalDevices']}');
        print('   Başarılı: ${responseData['successCount']}');
        print('   Başarısız: ${responseData['failureCount']}');
        if (platform != null) {
          print('   Platform: $platform');
        }
        return responseData;
      } else {
        print('❌ Toplu bildirim hatası: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Hata: $e');
      return null;
    }
  }
}
