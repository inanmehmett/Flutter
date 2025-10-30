import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/cache/cache_manager.dart';
import 'package:dio/dio.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _displayNameCtrl;
  late TextEditingController _bioCtrl;
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
    _displayNameCtrl = TextEditingController(text: profile?.displayName ?? profile?.userName ?? '');
    _bioCtrl = TextEditingController(text: profile?.bio ?? '');
    _currentPwdCtrl = TextEditingController();
    _newPwdCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _emailCtrl.dispose();
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final client = getIt<NetworkManager>();
      final state = context.read<AuthBloc>().state;
      final profile = state is AuthAuthenticated ? state.user : null;
      
      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı')));
        return;
      }
      
      // Build payload and avoid sending unchanged username (prevents unnecessary 409 checks)
      final Map<String, dynamic> payload = {
        'userId': profile.id,
        'email': _emailCtrl.text.trim(),
        'displayName': _displayNameCtrl.text.trim(),
        'profilePictureUrl': profile.profileImageUrl,
        'bio': _bioCtrl.text.trim(),
        'targetLanguage': 'en',
        'nativeLanguage': 'tr',
        'dailyGoalMinutes': 30,
        'emailNotifications': true,
        'isProfilePublic': true,
      };
      final newUserName = _userNameCtrl.text.trim();
      if (newUserName.isNotEmpty && newUserName != profile.userName) {
        payload['userName'] = newUserName;
      }

      final resp = await client.put('/api/ApiUserProfile', data: payload);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        // Invalidate cached profile to avoid stale data, then refresh
        try {
          final cache = getIt<CacheManager>();
          await cache.removeData('user/profile');
        } catch (_) {}
        try {
          getIt<NetworkManager>().clearHttpCache();
        } catch (_) {}
        // Refresh auth state to pull updated profile
        context.read<AuthBloc>().add(CheckAuthStatus());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellendi')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Güncelleme başarısız')));
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final serverMsg = (e.response?.data is Map && (e.response?.data)['message'] is String)
          ? (e.response?.data)['message'] as String
          : null;
      if (status == 409) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg ?? 'Bu kullanıcı adı zaten kullanılıyor.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMsg ?? 'Hata oluştu')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
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
      final resp = await client.put('/api/ApiUserProfile/password', data: {
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

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: AppColors.background,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(AppRadius.cardRadius),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil Detayları',
                      style: AppTypography.title1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: AppColors.textQuaternary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bilgilerini güncelle ve yönet',
                            style: AppTypography.subhead.copyWith(
                              color: AppColors.textQuaternary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Details')),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildModernHeader(),
          Expanded(
            child: AbsorbPointer(
              absorbing: _saving,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _displayNameCtrl,
                        decoration: const InputDecoration(labelText: 'Ad Soyad'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'İsim gerekli' : null,
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bioCtrl,
                        decoration: const InputDecoration(labelText: 'Biyografi (opsiyonel)'),
                        maxLines: 3,
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
          ),
        ],
      ),
    );
  }
}

