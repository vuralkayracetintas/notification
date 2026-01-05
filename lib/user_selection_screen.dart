import 'package:flutter/material.dart';
import 'backend_service.dart';
import 'user_register_screen.dart';
import 'main.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await BackendService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Kullanıcılar yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectUser(Map<String, dynamic> user) async {
    // Ana ekrana git ve kullanıcı ID'sini gönder
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(
          title: 'Notification App',
          selectedUserId: user['id'],
          selectedUserName: user['name'],
        ),
      ),
    );
  }

  Future<void> _createNewUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserRegisterScreen()),
    );

    if (result == true && mounted) {
      _loadUsers(); // Listeyi yenile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Seçin'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.people, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  const Text(
                    'Devam etmek için bir kullanıcı seçin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_users.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Henüz kayıtlı kullanıcı yok',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Yeni kullanıcı oluşturun',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  user['name']?[0]?.toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(user['email'] ?? ''),
                              trailing: Icon(
                                user['hasToken'] == true
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: user['hasToken'] == true
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              onTap: () => _selectUser(user),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _createNewUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Yeni Kullanıcı Oluştur'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Listeyi Yenile'),
                  ),
                ],
              ),
            ),
    );
  }
}
