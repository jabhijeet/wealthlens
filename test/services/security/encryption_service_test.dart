import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wealthlens/services/security/encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late EncryptionService encryptionService;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    encryptionService = EncryptionService(secureStorage: mockSecureStorage);
  });

  group('EncryptionService', () {
    test('should encrypt and decrypt data successfully', () async {
      const password = 'test-password-123';
      const plaintext = 'This is a secret message that needs encryption';

      // Encrypt
      final encryptedData = await encryptionService.encryptData(
        plaintext,
        password: password,
      );

      expect(encryptedData.ciphertext, isNotEmpty);
      expect(encryptedData.salt, isNotEmpty);
      expect(encryptedData.iv, isNotEmpty);
      // authTag may be empty for GCM mode (included in ciphertext)
      // expect(encryptedData.authTag, isNotEmpty);

      // Decrypt
      final decrypted = await encryptionService.decryptData(
        encryptedData,
        password: password,
      );

      expect(decrypted, equals(plaintext));
    });

    test('should fail decryption with wrong password', () async {
      const password = 'correct-password';
      const wrongPassword = 'wrong-password';
      const plaintext = 'Test data';

      final encryptedData = await encryptionService.encryptData(
        plaintext,
        password: password,
      );

      expect(
        () async => await encryptionService.decryptData(
          encryptedData,
          password: wrongPassword,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should validate password strength', () {
      expect(encryptionService.validatePasswordStrength(''), isFalse);
      expect(encryptionService.validatePasswordStrength('short'), isFalse);
      expect(
        encryptionService.validatePasswordStrength('onlylowercase'),
        isFalse,
      );
      expect(
        encryptionService.validatePasswordStrength('UPPERCASEONLY'),
        isFalse,
      );
      expect(encryptionService.validatePasswordStrength('12345678'), isFalse);
      expect(encryptionService.validatePasswordStrength('GoodPass1'), isTrue);
      expect(
        encryptionService.validatePasswordStrength('Strong@Password123'),
        isTrue,
      );
    });

    test('should handle empty plaintext', () async {
      const password = 'test-password';
      const plaintext = '';

      final encryptedData = await encryptionService.encryptData(
        plaintext,
        password: password,
      );

      final decrypted = await encryptionService.decryptData(
        encryptedData,
        password: password,
      );

      expect(decrypted, equals(plaintext));
    });

    test('should handle special characters in plaintext', () async {
      const password = 'test-password';
      const plaintext = 'Special chars: !@#\$%^&*()_+{}|:"<>?~`';

      final encryptedData = await encryptionService.encryptData(
        plaintext,
        password: password,
      );

      final decrypted = await encryptionService.decryptData(
        encryptedData,
        password: password,
      );

      expect(decrypted, equals(plaintext));
    });

    test('should generate different IV and salt for each encryption', () async {
      const password = 'same-password';
      const plaintext = 'Same text encrypted twice';

      final encrypted1 = await encryptionService.encryptData(
        plaintext,
        password: password,
      );
      final encrypted2 = await encryptionService.encryptData(
        plaintext,
        password: password,
      );

      // IV and salt should be different (random)
      expect(encrypted1.iv, isNot(equals(encrypted2.iv)));
      expect(encrypted1.salt, isNot(equals(encrypted2.salt)));
      // Ciphertext should be different due to different IV
      expect(encrypted1.ciphertext, isNot(equals(encrypted2.ciphertext)));
    });
  });
}
