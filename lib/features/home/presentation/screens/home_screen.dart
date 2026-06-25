import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/security/biometrics_helper.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Prompt biometrics setup suggestion after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPromptBiometrics();
    });
  }

  Future<void> _checkAndPromptBiometrics() async {
    // 1. Check if hardware supports biometrics
    final isSupported = await BiometricsHelper.instance.isBiometricsAvailable();
    if (!isSupported) return;

    // 2. Check if user already configured biometrics (either true or false)
    // Read raw storage value to distinguish between null (not set) and false (disabled)
    const secureStorage = FlutterSecureStorage();
    final rawValue = await secureStorage.read(key: 'biometrics_enabled');
    if (rawValue != null) return; // User already made a choice previously

    if (mounted) {
      _showBiometricPromptSheet();
    }
  }

  void _showBiometricPromptSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 40,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kích hoạt Đăng nhập Nhanh?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sử dụng Face ID hoặc Vân tay của bạn để mở khóa phiên đăng nhập nhanh chóng cho các lần sau mà không cần nhập lại mật khẩu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        // User declines -> save as false so we don't prompt again
                        await SecureStorage.instance.setBiometricsEnabled(false);
                        if (mounted) Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Bỏ qua', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close sheet first
                        
                        // Call biometric auth verification
                        final authenticated = await BiometricsHelper.instance.authenticate();
                        if (authenticated) {
                          await SecureStorage.instance.setBiometricsEnabled(true);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kích hoạt Sinh trắc học thành công!')),
                            );
                          }
                        } else {
                          // Authentication failed or cancelled
                          await SecureStorage.instance.setBiometricsEnabled(false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Kích hoạt'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    String userName = '';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ JGMS'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Chào mừng quay trở lại, $userName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn đã đăng nhập thành công vào hệ thống di động JGMS.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
