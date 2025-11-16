import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/network_manager.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _emailNotifications = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      // Fallback: if profile has field exposed in state, use it; otherwise keep default
      _emailNotifications = state.user.email.isNotEmpty ? true : _emailNotifications;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final client = getIt<NetworkManager>();
      await client.put('/api/ApiUserProfile', data: {
        'emailNotifications': _emailNotifications,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi')));
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
      appBar: AppBar(title: const Text('Bildirimler')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              value: _emailNotifications,
              title: const Text('E‑posta bildirimleri'),
              subtitle: const Text('İlerleme, rozet ve duyuru bildirimleri'),
              onChanged: (v) => setState(() => _emailNotifications = v),
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


