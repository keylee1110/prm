import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricsHelper {
  BiometricsHelper._privateConstructor();
  static final BiometricsHelper instance = BiometricsHelper._privateConstructor();

  final LocalAuthentication _auth = LocalAuthentication();

  // Check hardware support and if any biometric is enrolled
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) return false;

      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Trigger biometric authentication UI
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Vui lòng xác thực sinh trắc học để tiếp tục sử dụng ứng dụng.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}

