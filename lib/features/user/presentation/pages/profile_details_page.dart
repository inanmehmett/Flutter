import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/network_manager.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _currentPwdCtrl;
  late TextEditingController _newPwdCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    final profile = state is AuthAuthenticated ? state.user : null;
    _userNameCtrl = TextEditingController(text: profile?.userName ?? '');
    _emailCtrl = TextEditingController(text: profile?.email ?? '');
    _currentPwdCtrl = TextEditingController();
    _newPwdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final client = getIt<NetworkManager>();
      final resp = await client.put('/api/ApiUserProfile', data: {
        'userName': _userNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final root = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
        final updated = UserProfile.fromJson(root);
        // Refresh auth state to pull updated profile
        context.read<AuthBloc>().add(CheckAuthStatus());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellendi')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Güncelleme başarısız')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPwdCtrl.text.isEmpty || _newPwdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre alanlarını doldurun')));
      return;
    }
    setState(() => _saving = true);
    try {
      final client = getIt<NetworkManager>();
      final resp = await client.put('/connect/change-password', data: {
        'currentPassword': _currentPwdCtrl.text,
        'newPassword': _newPwdCtrl.text,
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre güncellendi')));
        _currentPwdCtrl.clear();
        _newPwdCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre güncellenemedi')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Details')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _userNameCtrl,
                  decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'En az 3 karakter' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'E‑posta'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Geçerli e‑posta girin' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Şifre Güncelle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _currentPwdCtrl,
                  decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPwdCtrl,
                  decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.password),
                  label: const Text('Şifreyi Güncelle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

