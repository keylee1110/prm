import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JGMS Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.indigoAccent,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Sử dụng font mặc định Roboto, dễ dàng đổi sang font khác
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Lớp Wrapper chịu trách nhiệm lắng nghe thay đổi của AuthState
/// và tự động định tuyến (Switch Screen) giữa màn hình Login và Home.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authStateProvider);

    return switch (authState) {
      AuthInitial() || AuthLoading() => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.indigo),
                SizedBox(height: 16),
                Text(
                  'Đang tải phiên làm việc...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      AuthAuthenticated() => const HomeScreen(),
      AuthUnauthenticated() || AuthError() => const LoginScreen(),
    };
  }
}
