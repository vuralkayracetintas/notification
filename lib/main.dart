import 'package:flutter/material.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
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

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Button Count:', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
