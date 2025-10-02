import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/network_manager.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isProfilePublic = true;
  bool _saving = false;
  String _policyTitle = '';
  String _policyContent = '';

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    try {
      final client = getIt<NetworkManager>();
      final resp = await client.get('/api/ApiPrivacy');
      final data = resp.data as Map<String, dynamic>;
      final root = (data['data'] ?? {}) as Map<String, dynamic>;
      setState(() {
        _policyTitle = (root['title'] ?? '').toString();
        _policyContent = (root['content'] ?? '').toString();
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final client = getIt<NetworkManager>();
      await client.put('/api/ApiUserProfile', data: {
        'isProfilePublic': _isProfilePublic,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gizlilik ayarları kaydedildi')));
      context.read<AuthBloc>().add(CheckAuthStatus());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaydedilemedi')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_policyTitle.isNotEmpty) ...[
              Text(_policyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            if (_policyContent.isNotEmpty) ...[
              Text(_policyContent),
              const SizedBox(height: 20),
            ],
            SwitchListTile(
              value: _isProfilePublic,
              title: const Text('Profilim herkese açık'),
              subtitle: const Text('Profil bilgilerin görünürlüğünü kontrol et'),
              onChanged: (v) => setState(() => _isProfilePublic = v),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}


