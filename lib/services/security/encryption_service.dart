import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for handling encryption and decryption of sensitive data
class EncryptionService {
  EncryptionService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();
  static const String _encryptionKeyStorageKey = 'backup_encryption_key';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _ivLength = 16; // 128 bits for AES GCM IV

  final FlutterSecureStorage _secureStorage;

  /// Generates a secure encryption key from a password using PBKDF2
  Key _generateKeyFromPassword(String password, String salt) {
    // Use PBKDF2 with SHA-256 for key derivation
    final keyBytes = _pbkdf2(
      password: utf8.encode(password),
      salt: utf8.encode(salt),
      iterationCount: 100000,
      desiredKeyLength: _keyLength,
    );

    return Key(Uint8List.fromList(keyBytes));
  }

  /// Generates a random salt for key derivation
  String _generateSalt() {
    final random = IV.fromSecureRandom(_ivLength);
    return base64Encode(random.bytes);
  }

  /// Encrypts data using AES-256-GCM
  Future<EncryptedData> encryptData(
    String plaintext, {
    required String password,
  }) async {
    try {
      // Generate salt for key derivation
      final salt = _generateSalt();

      // Derive key from password
      final key = _generateKeyFromPassword(password, salt);

      // Generate random IV
      final iv = IV.fromSecureRandom(_ivLength);

      // Create encryptor with AES-256-GCM
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      // Encrypt the data
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // For GCM mode, we need to handle authentication tag differently
      // The encrypt package handles GCM internally
      return EncryptedData(
        ciphertext: base64Encode(encrypted.bytes),
        iv: base64Encode(iv.bytes),
        salt: salt,
        algorithm: 'AES-256-GCM',
      );
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypts data using AES-256-GCM
  Future<String> decryptData(
    EncryptedData encryptedData, {
    required String password,
  }) async {
    try {
      // Derive key from password using stored salt
      final key = _generateKeyFromPassword(password, encryptedData.salt);

      // Decode IV and ciphertext
      final iv = IV(base64Decode(encryptedData.iv));
      final ciphertext = base64Decode(encryptedData.ciphertext);

      // Create decryptor with AES-256-GCM
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      // Decrypt the data
      final encrypted = Encrypted(ciphertext);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      if (e.toString().contains('Authentication') ||
          e.toString().contains('GCM')) {
        throw EncryptionException('Invalid password or corrupted data');
      }
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Stores an encryption key securely
  Future<void> storeEncryptionKey(String keyId, String key) async {
    await _secureStorage.write(
      key: '$_encryptionKeyStorageKey.$keyId',
      value: key,
    );
  }

  /// Retrieves an encryption key securely
  Future<String?> getEncryptionKey(String keyId) async {
    return await _secureStorage.read(key: '$_encryptionKeyStorageKey.$keyId');
  }

  /// Deletes an encryption key
  Future<void> deleteEncryptionKey(String keyId) async {
    await _secureStorage.delete(key: '$_encryptionKeyStorageKey.$keyId');
  }

  /// Validates password strength
  bool validatePasswordStrength(String password) {
    if (password.length < 8) return false;

    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'\d').hasMatch(password);
    final hasSpecialChars = RegExp(
      r'[!@#$%^&*(),.?":{}|<>]',
    ).hasMatch(password);

    // Require at least 3 of the 4 criteria
    final criteriaMet = [
      hasUpperCase,
      hasLowerCase,
      hasDigits,
      hasSpecialChars,
    ].where((c) => c).length;

    return criteriaMet >= 3;
  }

  /// Generates a secure random password
  String generateSecurePassword({int length = 16}) {
    final random = IV.fromSecureRandom(length);
    const chars =
        'abcdefghijklmnopqrstuvwxyz'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        '0123456789'
        '!@#\$%^&*()';

    final password = String.fromCharCodes(
      random.bytes.map((byte) => chars.codeUnitAt(byte % chars.length)),
    );

    return password;
  }

  /// PBKDF2 implementation for key derivation
  List<int> _pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterationCount,
    required int desiredKeyLength,
  }) {
    // Simple PBKDF2 implementation using HMAC-SHA256
    final hmac = Hmac(sha256, password);
    final derivedKey = <int>[];

    for (
      var blockIndex = 1;
      derivedKey.length < desiredKeyLength;
      blockIndex++
    ) {
      final block = _pbkdf2F(hmac, salt, iterationCount, blockIndex);
      derivedKey.addAll(block);
    }

    return derivedKey.sublist(0, desiredKeyLength);
  }

  List<int> _pbkdf2F(
    Hmac hmac,
    List<int> salt,
    int iterationCount,
    int blockIndex,
  ) {
    final u1 = hmac.convert(salt + _intToBytes(blockIndex)).bytes;
    var ui = List<int>.from(u1);

    for (var i = 1; i < iterationCount; i++) {
      final temp = hmac.convert(ui).bytes;
      for (var j = 0; j < temp.length; j++) {
        ui[j] ^= temp[j];
      }
    }

    return ui;
  }

  List<int> _intToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }
}

/// Represents encrypted data with all necessary components for decryption
class EncryptedData {
  EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.salt,
    required this.algorithm,
    this.metadata = const {},
  });

  /// Deserializes from JSON
  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String,
      salt: json['salt'] as String,
      algorithm: json['algorithm'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  final String ciphertext;
  final String iv;
  final String salt;
  final String algorithm;
  final Map<String, dynamic> metadata;

  /// Serializes to JSON for storage
  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'iv': iv,
    'salt': salt,
    'algorithm': algorithm,
    'metadata': metadata,
    'version': '1.0',
  };

  @override
  String toString() {
    return 'EncryptedData(algorithm: $algorithm, ciphertext: ${ciphertext.substring(0, 20)}..., iv: ${iv.substring(0, 10)}...)';
  }
}

/// Exception thrown when encryption/decryption fails
class EncryptionException implements Exception {
  EncryptionException(this.message);
  final String message;

  @override
  String toString() => 'EncryptionException: $message';
}

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});
