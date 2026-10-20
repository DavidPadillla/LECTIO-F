import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'lectio_auth_service.dart';

class BiometricCredentials {
  const BiometricCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

abstract interface class BiometricSessionStore {
  Future<bool> isAvailable();
  Future<bool> hasSavedCredentials();
  Future<bool> authenticate({required String reason});
  Future<BiometricCredentials?> authenticateAndReadCredentials();
  Future<void> saveCredentials(BiometricCredentials credentials);
  Future<void> clearCredentials();
}

class SecureBiometricSessionStore implements BiometricSessionStore {
  SecureBiometricSessionStore({
    LocalAuthentication? localAuthentication,
    FlutterSecureStorage? storage,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _storage = storage ?? const FlutterSecureStorage();

  static const _credentialsKey = 'lectio.biometric.credentials';
  static const _enabledKey = 'lectio.biometric.enabled';
  static const _legacySessionKey = 'lectio.biometric.session';

  final LocalAuthentication _localAuthentication;
  final FlutterSecureStorage _storage;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    try {
      if (!await _localAuthentication.canCheckBiometrics) return false;
      return (await _localAuthentication.getAvailableBiometrics()).isNotEmpty;
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<bool> hasSavedCredentials() async {
    try {
      final enabled = await _storage.read(key: _enabledKey) == 'true';
      final credentials = await _storage.read(key: _credentialsKey);
      if (!enabled || credentials == null) {
        await clearCredentials();
        return false;
      }
      return true;
    } on PlatformException catch (error) {
      throw AuthException(
        'No se pudo consultar el acceso biométrico: ${error.message ?? error.code}',
      );
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      if (error.code == LocalAuthExceptionCode.userCanceled ||
          error.code == LocalAuthExceptionCode.systemCanceled) {
        return false;
      }
      throw AuthException(
        error.description ?? 'No se pudo verificar la huella del dispositivo.',
      );
    }
  }

  @override
  Future<BiometricCredentials?> authenticateAndReadCredentials() async {
    if (!await authenticate(
      reason: 'Verifica tu identidad para entrar a Lectio.',
    )) {
      return null;
    }

    try {
      final encodedCredentials = await _storage.read(key: _credentialsKey);
      if (encodedCredentials == null) {
        await clearCredentials();
        throw const AuthException(
          'No hay credenciales guardadas. Inicia sesión con tu contraseña.',
        );
      }
      final decoded = jsonDecode(encodedCredentials);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved credentials');
      }
      final data = decoded;
      final username = data['username'];
      final password = data['password'];
      if (username is! String ||
          username.isEmpty ||
          password is! String ||
          password.isEmpty) {
        await clearCredentials();
        throw const AuthException(
          'El acceso biométrico guardado no es válido. Inicia sesión con tu contraseña.',
        );
      }
      return BiometricCredentials(username: username, password: password);
    } on PlatformException catch (error) {
      throw AuthException(
        'No se pudo leer la sesión segura: ${error.message ?? error.code}',
      );
    } on FormatException {
      await clearCredentials();
      throw const AuthException(
        'Las credenciales guardadas no son válidas. Inicia sesión con tu contraseña.',
      );
    }
  }

  @override
  Future<void> saveCredentials(BiometricCredentials credentials) async {
    try {
      await _storage.write(
        key: _credentialsKey,
        value: jsonEncode({
          'username': credentials.username,
          'password': credentials.password,
        }),
      );
      await _storage.delete(key: _legacySessionKey);
      await _storage.write(key: _enabledKey, value: 'true');
    } on PlatformException catch (error) {
      throw AuthException(
        'No se pudo guardar el acceso seguro: ${error.message ?? error.code}',
      );
    }
  }

  @override
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _credentialsKey);
      await _storage.delete(key: _enabledKey);
      await _storage.delete(key: _legacySessionKey);
    } on PlatformException catch (error) {
      throw AuthException(
        'No se pudo borrar el acceso guardado: ${error.message ?? error.code}',
      );
    }
  }
}
