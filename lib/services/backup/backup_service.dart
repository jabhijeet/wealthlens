import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'backup_helper_stub.dart'
    if (dart.library.io) 'backup_helper_native.dart';
import '../security/encryption_service.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';

class BackupData {
  BackupData({
    required this.backupDate,
    required this.appVersion,
    required this.data,
  });

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      backupDate: DateTime.parse(json['backupDate'] as String),
      appVersion: json['appVersion'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
  final DateTime backupDate;
  final String appVersion;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
    'backupDate': backupDate.toIso8601String(),
    'appVersion': appVersion,
    'data': data,
  };
}

/// Exception thrown when backup operations fail
class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => 'BackupException: $message';
}

class BackupService {
  BackupService({
    required HoldingDao holdingDao,
    required InstrumentDao instrumentDao,
    required TransactionDao transactionDao,
    required SystematicPlanDao systematicPlanDao,
    required FdRdAccountDao fdRdAccountDao,
    required PpfAccountDao ppfAccountDao,
    required InsurancePolicyDao insurancePolicyDao,
    required CryptoHoldingDao cryptoHoldingDao,
    required RealEstateHoldingDao realEstateHoldingDao,
    required GoalDao goalDao,
    required EncryptionService encryptionService,
  }) : _holdingDao = holdingDao,
       _instrumentDao = instrumentDao,
       _transactionDao = transactionDao,
       _systematicPlanDao = systematicPlanDao,
       _fdRdAccountDao = fdRdAccountDao,
       _ppfAccountDao = ppfAccountDao,
       _insurancePolicyDao = insurancePolicyDao,
       _cryptoHoldingDao = cryptoHoldingDao,
       _realEstateHoldingDao = realEstateHoldingDao,
       _goalDao = goalDao,
       _encryptionService = encryptionService;
  final HoldingDao _holdingDao;
  final InstrumentDao _instrumentDao;
  final TransactionDao _transactionDao;
  final SystematicPlanDao _systematicPlanDao;
  final FdRdAccountDao _fdRdAccountDao;
  final PpfAccountDao _ppfAccountDao;
  final InsurancePolicyDao _insurancePolicyDao;
  final CryptoHoldingDao _cryptoHoldingDao;
  final RealEstateHoldingDao _realEstateHoldingDao;
  final GoalDao _goalDao;
  final EncryptionService _encryptionService;

  Future<BackupData> createBackup() async {
    final holdings = await _holdingDao.getAll();
    final instruments = await _instrumentDao.getAll();
    final transactions = await _transactionDao.getAll();
    final systematicPlans = await _systematicPlanDao.getAll();
    final fdRdAccounts = await _fdRdAccountDao.getAll();
    final ppfAccounts = await _ppfAccountDao.getAll();
    final insurancePolicies = await _insurancePolicyDao.getAll();
    final cryptoHoldings = await _cryptoHoldingDao.getAll();
    final realEstateHoldings = await _realEstateHoldingDao.getAll();
    final goals = await _goalDao.getAll();

    final packageInfo = await PackageInfo.fromPlatform();

    final data = {
      'holdings': holdings.map((h) => h.toJson()).toList(),
      'instruments': instruments.map((i) => i.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'systematicPlans': systematicPlans.map((p) => p.toJson()).toList(),
      'fdRdAccounts': fdRdAccounts.map((a) => a.toJson()).toList(),
      'ppfAccounts': ppfAccounts.map((a) => a.toJson()).toList(),
      'insurancePolicies': insurancePolicies.map((p) => p.toJson()).toList(),
      'cryptoHoldings': cryptoHoldings.map((c) => c.toJson()).toList(),
      'realEstateHoldings': realEstateHoldings.map((r) => r.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
    };

    return BackupData(
      backupDate: DateTime.now(),
      appVersion: packageInfo.version,
      data: data,
    );
  }

  Future<String> exportBackup({String? password}) async {
    final backupData = await createBackup();
    final jsonString = jsonEncode(backupData.toJson());

    if (password != null && password.isNotEmpty) {
      // Validate password strength
      if (!_encryptionService.validatePasswordStrength(password)) {
        throw BackupException(
          'Password must be at least 8 characters with uppercase, lowercase, '
          'numbers, and special characters',
        );
      }

      // Encrypt the backup using AES-256-GCM
      final encryptedData = await _encryptionService.encryptData(
        jsonString,
        password: password,
      );

      // Serialize encrypted data to JSON
      final encryptedJson = jsonEncode(encryptedData.toJson());
      return base64Encode(utf8.encode(encryptedJson));
    } else {
      // Unencrypted backup (not recommended for sensitive data)
      return jsonString;
    }
  }

  Future<Object> saveBackupToFile({String? password}) async {
    final backupString = await exportBackup(password: password);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'wealthlens_backup_$timestamp.json';

    return await BackupFileHelper.saveStringToFile(backupString, fileName);
  }

  Future<void> importBackupFromString(
    String backupString, {
    String? password,
  }) async {
    String jsonString;

    if (password != null && password.isNotEmpty) {
      try {
        // Decode base64 encoded encrypted JSON
        final decodedBytes = base64Decode(backupString);
        final encryptedJson = utf8.decode(decodedBytes);

        // Parse encrypted data from JSON
        final encryptedDataMap =
            jsonDecode(encryptedJson) as Map<String, dynamic>;
        final encryptedData = EncryptedData.fromJson(encryptedDataMap);

        // Decrypt using encryption service
        jsonString = await _encryptionService.decryptData(
          encryptedData,
          password: password,
        );
      } catch (e) {
        if (e is EncryptionException) {
          throw BackupException('Failed to decrypt backup: ${e.message}');
        }
        throw BackupException('Invalid backup format or corrupted data');
      }
    } else {
      // Unencrypted backup
      jsonString = backupString;
    }

    final backupData = BackupData.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );

    // Clear all dependent data first (foreign key order)
    await _systematicPlanDao.clearAll();
    await _transactionDao.clearAll();
    await _fdRdAccountDao.clearAll();
    await _ppfAccountDao.clearAll();
    await _insurancePolicyDao.clearAll();
    await _cryptoHoldingDao.clearAll();
    await _realEstateHoldingDao.clearAll();
    await _goalDao.clearAll();
    await _holdingDao.clearAll();
    await _instrumentDao.clearAll();

    // Import instruments
    final instrumentsList =
        backupData.data['instruments'] as List<dynamic>? ?? [];
    for (final item in instrumentsList) {
      await _instrumentDao.insert(
        Instrument.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import holdings
    final holdingsList = backupData.data['holdings'] as List<dynamic>? ?? [];
    for (final item in holdingsList) {
      await _holdingDao.insert(Holding.fromJson(item as Map<String, dynamic>));
    }

    // Import transactions
    final transactionsList =
        backupData.data['transactions'] as List<dynamic>? ?? [];
    for (final item in transactionsList) {
      await _transactionDao.insert(
        Transaction.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import systematic plans
    final plansList =
        backupData.data['systematicPlans'] as List<dynamic>? ?? [];
    for (final item in plansList) {
      await _systematicPlanDao.insert(
        SystematicPlan.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import FD/RD accounts
    final fdRdList = backupData.data['fdRdAccounts'] as List<dynamic>? ?? [];
    for (final item in fdRdList) {
      await _fdRdAccountDao.insert(
        FdRdAccount.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import PPF accounts
    final ppfList = backupData.data['ppfAccounts'] as List<dynamic>? ?? [];
    for (final item in ppfList) {
      await _ppfAccountDao.insert(
        PpfAccount.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import insurance policies
    final insList =
        backupData.data['insurancePolicies'] as List<dynamic>? ?? [];
    for (final item in insList) {
      await _insurancePolicyDao.insert(
        InsurancePolicy.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import crypto holdings
    final cryptoList =
        backupData.data['cryptoHoldings'] as List<dynamic>? ?? [];
    for (final item in cryptoList) {
      await _cryptoHoldingDao.insert(
        CryptoHolding.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import real estate holdings
    final reList =
        backupData.data['realEstateHoldings'] as List<dynamic>? ?? [];
    for (final item in reList) {
      await _realEstateHoldingDao.insert(
        RealEstateHolding.fromJson(item as Map<String, dynamic>),
      );
    }

    // Import goals
    final goalsList = backupData.data['goals'] as List<dynamic>? ?? [];
    for (final item in goalsList) {
      await _goalDao.insert(Goal.fromJson(item as Map<String, dynamic>));
    }
  }

  Future<void> importBackupFromFile(Object file, {String? password}) async {
    final backupString = await BackupFileHelper.readFileAsString(file);
    await importBackupFromString(backupString, password: password);
  }

  Future<List<Object>> listBackupFiles() async {
    return await BackupFileHelper.listBackupFiles();
  }

  Future<void> deleteBackupFile(Object file) async {
    await BackupFileHelper.deleteFile(file);
  }

  Future<String> getBackupInfo(Object file) async {
    return await BackupFileHelper.getFileInfo(file);
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    holdingDao: ref.watch(holdingDaoProvider),
    instrumentDao: ref.watch(instrumentDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    systematicPlanDao: ref.watch(systematicPlanDaoProvider),
    fdRdAccountDao: ref.watch(fdRdAccountDaoProvider),
    ppfAccountDao: ref.watch(ppfAccountDaoProvider),
    insurancePolicyDao: ref.watch(insurancePolicyDaoProvider),
    cryptoHoldingDao: ref.watch(cryptoHoldingDaoProvider),
    realEstateHoldingDao: ref.watch(realEstateHoldingDaoProvider),
    goalDao: ref.watch(goalDaoProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});
