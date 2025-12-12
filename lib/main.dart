import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:notification_example/firebase_options.dart';
import 'notification_service.dart';
import 'firebase_messaging_service.dart';
import 'backend_service.dart';
import 'invitation_screen.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final NotificationService _notificationService = NotificationService();
  final FirebaseMessagingService _fcmService = FirebaseMessagingService();
  String _fcmToken = 'Loading...';
  bool _isSubscribedToAll = true;
  String _currentUserId = 'user1'; // Varsayılan kullanıcı

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
    _registerToken();
  }

  Future<void> _loadFCMToken() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _fcmToken = _fcmService.fcmToken ?? 'Token not available';
    });
  }

  Future<void> _registerToken() async {
    // Backend'e token kaydet
    await BackendService.registerFCMToken(_currentUserId);
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
                              DropdownButton<String>(
                                value: _currentUserId,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'user1',
                                    child: Text('user1 (Ahmet)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'user2',
                                    child: Text('user2 (Mehmet)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'user3',
                                    child: Text('user3 (Ayşe)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _currentUserId = value);
                                    _registerToken();
                                  }
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          const Text(
                            'FCM Token:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
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
