import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/biometrics_helper.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isSupported = await BiometricsHelper.instance.isBiometricsAvailable();
    final isEnabled = await SecureStorage.instance.isBiometricsEnabled();
    setState(() {
      _isBiometricSupported = isSupported;
      _isBiometricEnabled = isEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (!_isBiometricSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiết bị không hỗ trợ sinh trắc học!')),
      );
      return;
    }

    if (value) {
      // Prompt biometric authentication to confirm activation
      final authenticated = await BiometricsHelper.instance.authenticate();
      if (authenticated) {
        await SecureStorage.instance.setBiometricsEnabled(true);
        setState(() {
          _isBiometricEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã bật đăng nhập bằng sinh trắc học.')),
        );
      } else {
        setState(() {
          _isBiometricEnabled = false;
        });
      }
    } else {
      await SecureStorage.instance.setBiometricsEnabled(false);
      setState(() {
        _isBiometricEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tắt đăng nhập bằng sinh trắc học.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    String userEmail = '';
    String userName = '';

    if (authState is AuthAuthenticated) {
      userEmail = authState.user.email;
      userName = authState.user.fullName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 20),
                // User info section
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Settings section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'BẢO MẬT & XÁC THỰC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 1,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Đăng nhập bằng Sinh trắc học'),
                        subtitle: Text(_isBiometricSupported
                            ? 'Sử dụng Face ID hoặc Vân tay để đăng nhập nhanh'
                            : 'Thiết bị không hỗ trợ sinh trắc học'),
                        value: _isBiometricEnabled,
                        onChanged: _isBiometricSupported ? _toggleBiometrics : null,
                        activeColor: Colors.indigo,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).logout();
                      Navigator.of(context).pop(); // Back to main wrapper screen
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
