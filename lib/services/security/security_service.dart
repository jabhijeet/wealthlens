import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/daos.dart';

class SecurityService {
  SecurityService({required SettingDao settingDao}) : _settingDao = settingDao;
  final LocalAuthentication _auth = LocalAuthentication();
  final SettingDao _settingDao;

  Future<bool> canAuthenticate() async {
    final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> authenticate({
    String reason = 'Please authenticate to access WealthLens',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _settingDao.getValue('biometric_enabled');
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _settingDao.setValue('biometric_enabled', enabled.toString());
  }

  Future<bool> isPrivacyModeEnabled() async {
    final val = await _settingDao.getValue('privacy_mode_enabled');
    return val == 'true';
  }

  Future<void> setPrivacyModeEnabled(bool enabled) async {
    await _settingDao.setValue('privacy_mode_enabled', enabled.toString());
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(settingDao: ref.watch(settingDaoProvider));
});
