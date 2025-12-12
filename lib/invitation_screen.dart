import 'package:flutter/material.dart';
import 'backend_service.dart';

class InvitationScreen extends StatefulWidget {
  final String currentUserId;

  const InvitationScreen({super.key, required this.currentUserId});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final TextEditingController _eventNameController = TextEditingController();
  List<String> _selectedUserIds = []; // Tek yerine liste
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await BackendService.getUsers();
    setState(() {
      // Kendisi hariç diğer kullanıcıları göster
      _users = users.where((u) => u['id'] != widget.currentUserId).toList();
    });
  }

  Future<void> _sendInvitation() async {
    if (_selectedUserIds.isEmpty) {
      _showMessage('Lütfen en az bir kullanıcı seçin');
      return;
    }

    if (_eventNameController.text.trim().isEmpty) {
      _showMessage('Lütfen etkinlik adı girin');
      return;
    }

    setState(() => _isLoading = true);

    // Tüm seçili kullanıcılara gönder
    int successCount = 0;
    for (String userId in _selectedUserIds) {
      final result = await BackendService.sendInvitation(
        inviterId: widget.currentUserId,
        invitedUserId: userId,
        eventName: _eventNameController.text.trim(),
      );
      if (result != null) {
        successCount++;
      }
    }

    setState(() => _isLoading = false);

    if (successCount > 0) {
      _showMessage('✅ Davetiye gönderildi! ($successCount kullanıcı)', isSuccess: true);
      _eventNameController.clear();
      setState(() => _selectedUserIds.clear());
    } else {
      _showMessage('❌ Davetiye gönderilemedi');
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Davetiye Gönder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı bilgisi
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sen:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      widget.currentUserId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Kullanıcı seçimi - Multi-select
            const Text(
              'Davet edilecek kullanıcılar:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_users.isEmpty)
              const CircularProgressIndicator()
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // "Tümünü Seç" butonu
                    CheckboxListTile(
                      title: const Text(
                        'Tümünü Seç',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: _selectedUserIds.length == _users.length,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedUserIds = _users
                                .map((u) => u['id'] as String)
                                .toList();
                          } else {
                            _selectedUserIds.clear();
                          }
                        });
                      },
                    ),
                    const Divider(height: 1),
                    // Kullanıcı listesi
                    ..._users.map((user) {
                      final userId = user['id'] as String;
                      final isSelected = _selectedUserIds.contains(userId);
                      
                      return CheckboxListTile(
                        title: Row(
                          children: [
                            Icon(
                              user['hasToken'] ? Icons.check_circle : Icons.cancel,
                              color: user['hasToken'] ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(user['name'] as String),
                          ],
                        ),
                        subtitle: Text(user['email'] as String),
                        value: isSelected,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedUserIds.add(userId);
                            } else {
                              _selectedUserIds.remove(userId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Seçili kullanıcı sayısı
            if (_selectedUserIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${_selectedUserIds.length} kullanıcı seçildi',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Etkinlik adı
            const Text(
              'Etkinlik adı:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Örn: Doğum günü partisi',
                prefixIcon: Icon(Icons.event),
              ),
            ),
            const SizedBox(height: 24),

            // Gönder butonu
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendInvitation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Gönderiliyor...' : 'Davetiye Gönder'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Bilgi
            Card(
              color: Colors.orange[50],
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Yeşil işaret = Token kayıtlı (bildirim alabilir)\n'
                        'Kırmızı işaret = Token yok (bildirim alamaz)',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    super.dispose();
  }
}
