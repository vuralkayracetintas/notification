import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:notification_example/firebase_options.dart';
import 'notification_service.dart';
import 'firebase_messaging_service.dart';
import 'backend_service.dart';
import 'invitation_screen.dart';
import 'user_register_screen.dart';
import 'user_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  await FirebaseMessagingService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const UserSelectionScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.selectedUserId,
    required this.selectedUserName,
  });

  final String title;
  final String selectedUserId;
  final String selectedUserName;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final NotificationService _notificationService = NotificationService();
  final FirebaseMessagingService _fcmService = FirebaseMessagingService();
  String _fcmToken = 'Loading...';
  String _deviceId = 'Loading...';
  bool _isSubscribedToAll = true;
  late String _currentUserId;
  late String _currentUserName;
  List<Map<String, dynamic>> _registeredDevices = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.selectedUserId;
    _currentUserName = widget.selectedUserName;
    _loadFCMToken();
    _registerToken();
    _registerDeviceToBackend();
  }

  Future<void> _loadFCMToken() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final deviceId = await _fcmService.getDeviceId();
    setState(() {
      _fcmToken = _fcmService.fcmToken ?? 'Token not available';
      _deviceId = deviceId ?? 'Device ID not available';
    });
  }

  Future<void> _registerToken() async {
    // Backend'e token kaydet (user bazlı)
    await BackendService.registerFCMToken(_currentUserId);
  }

  Future<void> _registerDeviceToBackend() async {
    // Backend'e device kaydet (device bazlı)
    final deviceId = await _fcmService.getDeviceId();
    final token = _fcmService.fcmToken;

    if (deviceId != null && token != null) {
      // Platform değerini backend'in kabul ettiği formatta gönder (dart:io kullanarak context'siz)
      String platformValue = 'unknown';
      if (Platform.isIOS) {
        platformValue = 'iOS';
      } else if (Platform.isAndroid) {
        platformValue = 'Android';
      }

      await BackendService.registerDevice(
        deviceId: deviceId,
        fcmToken: token,
        userId: _currentUserId,
        platform: platformValue,
        deviceInfo: 'Flutter Device',
      );
    }
  }

  Future<void> _loadDevices() async {
    final devices = await BackendService.getDevices();
    setState(() {
      _registeredDevices = devices;
    });
  }

  Future<void> _toggleAllUsersSubscription() async {
    try {
      if (_isSubscribedToAll) {
        await _fcmService.unsubscribeFromTopic('all_users');
        setState(() => _isSubscribedToAll = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unsubscribed from broadcast notifications'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await _fcmService.subscribeToTopic('all_users');
        setState(() => _isSubscribedToAll = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscribed to broadcast notifications'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmService.fcmToken != null) {
      // You can add clipboard functionality here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token: ${_fcmService.fcmToken}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _sendNotification() async {
    try {
      final hasPermission = await _notificationService.checkPermissions();
      print('Has notification permission: $hasPermission');

      await _notificationService.showNotification(
        title: 'Notification Title',
        body: 'This is a test notification! Counter: $_counter',
        payload: 'notification_data',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasPermission
                  ? 'Notification sent successfully'
                  : 'Notification sent but permission may not be granted',
            ),
            backgroundColor: hasPermission ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Notification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendScheduledNotification() async {
    try {
      final scheduledDate = DateTime.now().add(const Duration(seconds: 5));
      await _notificationService.scheduleNotification(
        title: 'Zamanlanmış Bildirim',
        body: '5 saniye sonra gösterilen bildirim. Sayaç: $_counter',
        scheduledDate: scheduledDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim 5 saniye sonra gösterilecek'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendScheduledNotification2() async {
    try {
      final scheduledDate = DateTime.now().add(const Duration(seconds: 30));
      await _notificationService.scheduleNotification(
        title: 'Scheduled Notification',
        body: 'Notification shown after 30 seconds. Counter: $_counter',
        scheduledDate: scheduledDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification will be shown in 30 seconds'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _customNotification() async {
    try {
      await _notificationService.scheduleNotification2(
        title: 'Scheduled Notification',
        body: 'Your notification scheduled for 17:15',
        hour: 17,
        minute: 15,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom notification scheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Custom notification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendToDevice() async {
    if (_registeredDevices.isEmpty) {
      await _loadDevices();
    }

    if (!mounted) return;

    if (_registeredDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıtlı device bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Device seçimi için dialog göster
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Seç'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _registeredDevices.length,
            itemBuilder: (context, index) {
              final device = _registeredDevices[index];
              return ListTile(
                leading: Icon(
                  device['platform']?.contains('iOS') ?? false
                      ? Icons.phone_iphone
                      : Icons.phone_android,
                ),
                title: Text(device['deviceId'] ?? 'Unknown'),
                subtitle: Text(
                  'User: ${device['userId'] ?? 'N/A'}\n${device['platform'] ?? 'Unknown'}',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await BackendService.sendToDevice(
                    deviceId: device['deviceId'],
                    title: 'Device Notification',
                    body:
                        'Bu bildirim ${device['deviceId']} cihazına gönderildi',
                    data: {
                      'type': 'device_specific',
                      'counter': _counter.toString(),
                    },
                  );
                  if (mounted) {
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text(
                    //       'Bildirim ${device['deviceId']} cihazına gönderildi',
                    //     ),
                    //     backgroundColor: Colors.green,
                    //   ),
                    // );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _sendBulkToAllDevices() async {
    if (_registeredDevices.isEmpty) {
      await _loadDevices();
    }

    if (!mounted) return;

    if (_registeredDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıtlı device bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Platform seçimi için dialog göster
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Bildirim Gönder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_registeredDevices.length} kayıtlı cihaz bulundu'),
            const SizedBox(height: 20),
            const Text('Hangi platformlara gönderilsin?'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await BackendService.sendBulkToDevices(
                title: 'Toplu Bildirim 📢',
                body: 'Bu bildirim tüm kayıtlı cihazlara gönderildi!',
                data: {'type': 'bulk', 'counter': _counter.toString()},
              );
              if (mounted && result != null) {
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text(
                //       '✅ ${result['successCount']}/${result['totalDevices']} cihaza gönderildi',
                //     ),
                //     backgroundColor: Colors.green,
                //     duration: const Duration(seconds: 3),
                //   ),
                // );
              }
            },
            icon: const Icon(Icons.devices),
            label: const Text('Tüm Cihazlar'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await BackendService.sendBulkToDevices(
                title: 'iOS Bildirim 🍎',
                body: 'Bu bildirim sadece iOS cihazlara gönderildi',
                platform: 'iOS',
                data: {'type': 'bulk_ios', 'counter': _counter.toString()},
              );
              if (mounted && result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ ${result['successCount']}/${result['totalDevices']} iOS cihaza gönderildi',
                    ),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.phone_iphone),
            label: const Text('Sadece iOS'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final result = await BackendService.sendBulkToDevices(
                title: 'Android Bildirim 🤖',
                body: 'Bu bildirim sadece Android cihazlara gönderildi',
                platform: 'Android',
                data: {'type': 'bulk_android', 'counter': _counter.toString()},
              );
              if (mounted && result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ ${result['successCount']}/${result['totalDevices']} Android cihaza gönderildi',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.phone_android),
            label: const Text('Sadece Android'),
          ),
        ],
      ),
    );
  }

  // Seçili device'lara toplu bildirim gönder
  Future<void> _sendToSelectedDevices() async {
    if (_registeredDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Kayıtlı cihaz bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Seçilebilir device listesi
    final List<String> selectedDeviceIds = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cihaz Seç'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_registeredDevices.length} cihaz mevcut'),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _registeredDevices.length,
                        itemBuilder: (context, index) {
                          final device = _registeredDevices[index];
                          final deviceId = device['deviceId'] as String;
                          final platform = device['platform'] ?? 'unknown';
                          final isSelected = selectedDeviceIds.contains(
                            deviceId,
                          );

                          return CheckboxListTile(
                            title: Text(
                              deviceId.length > 20
                                  ? '${deviceId.substring(0, 20)}...'
                                  : deviceId,
                            ),
                            subtitle: Text('Platform: $platform'),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedDeviceIds.add(deviceId);
                                } else {
                                  selectedDeviceIds.remove(deviceId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedDeviceIds.clear();
                      selectedDeviceIds.addAll(
                        _registeredDevices.map((d) => d['deviceId'] as String),
                      );
                    });
                  },
                  child: const Text('Tümünü Seç'),
                ),
                ElevatedButton(
                  onPressed: selectedDeviceIds.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          _confirmAndSendToSelected(selectedDeviceIds);
                        },
                  child: Text('Gönder (${selectedDeviceIds.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSendToSelected(List<String> deviceIds) async {
    final result = await BackendService.sendToMultipleDevices(
      deviceIds: deviceIds,
      title: 'Seçili Cihazlara Bildirim 📱',
      body: '${deviceIds.length} cihaza özel bildirim gönderildi!',
      data: {'type': 'selected_devices', 'counter': _counter.toString()},
    );

    if (mounted && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${result['successCount']}/${result['foundDevices']} cihaza gönderildi\n'
            '${result['notFoundDevices'] > 0 ? '⚠️  ${result['notFoundDevices']} cihaz bulunamadı' : ''}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Button Count:', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  // FCM Token Display
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kullanıcı:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _currentUserName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const Text(
                            'Device ID:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _deviceId,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'FCM Token:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _fcmToken,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _copyTokenToClipboard,
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Show Token'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Broadcast Subscription Toggle
                  Card(
                    color: _isSubscribedToAll
                        ? Colors.green.shade50
                        : Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            _isSubscribedToAll
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: _isSubscribedToAll
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSubscribedToAll
                                      ? 'Broadcast: ON'
                                      : 'Broadcast: OFF',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _isSubscribedToAll
                                      ? 'Receiving notifications to all users'
                                      : 'Not receiving broadcast notifications',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isSubscribedToAll,
                            onChanged: (value) => _toggleAllUsersSubscription(),
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Device'a Bildirim Gönder Butonu
                  ElevatedButton.icon(
                    onPressed: _sendToDevice,
                    icon: const Icon(Icons.phone_android),
                    label: const Text('📱 Device\'a Bildirim Gönder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Toplu Bildirim Butonu (Tüm Device'lara)
                  ElevatedButton.icon(
                    onPressed: _sendBulkToAllDevices,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('📢 Toplu Bildirim (Tüm Cihazlar)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Seçili Device'lara Toplu Bildirim
                  ElevatedButton.icon(
                    onPressed: _sendToSelectedDevices,
                    icon: const Icon(Icons.phone_android),
                    label: const Text('📱 Seçili Cihazlara Gönder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Davetiye Gönder Butonu
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              InvitationScreen(currentUserId: _currentUserId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('📨 Davetiye Gönder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Yeni Kullanıcı Kayıt Butonu
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserRegisterScreen(),
                        ),
                      );
                      // Kullanıcı oluşturuldu ise listeyi yenile
                      if (result == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kullanıcı listesi güncellendi'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('👤 Yeni Kullanıcı Kayıt'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Send Instant Notification'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: _sendScheduledNotification,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Send Notification in 5 Seconds'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendScheduledNotification2,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Send Notification in 30 Seconds'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _customNotification,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Send Notification at 17:15'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
