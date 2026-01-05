import 'package:flutter/material.dart';
import 'backend_service.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await BackendService.createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['user']['name']} başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );

        // Form temizle
        _nameController.clear();
        _emailController.clear();

        // Ana ekrana dön
        Navigator.pop(context, true); // true = kullanıcı oluşturuldu
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Kullanıcı oluşturulamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Kullanıcı Kayıt'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 24),
              const Text(
                'Kullanıcı Bilgileri',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  hintText: 'Örn: Ahmet Yılmaz',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen ad soyad girin';
                  }
                  if (value.trim().length < 3) {
                    return 'Ad soyad en az 3 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Örn: ahmet@example.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen email girin';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Geçerli bir email adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kullanıcı Oluştur',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Bilgi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Kullanıcılar MongoDB veritabanına kaydedilir\n'
                        '• Email adresi benzersiz olmalıdır\n'
                        '• Kayıt sonrası bildirim gönderebilirsiniz',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
