import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  // Generates a random AES encryption key for a space/group.
  static String generateGroupKey() {
    final key = enc.Key.fromSecureRandom(32);
    return key.base64;
  }

  // Encrypts plain text using the group's specific key.
  static String encryptMessage(String plainText, String base64Key) {
    if (base64Key.isEmpty || plainText.isEmpty) return plainText;
    try {
      final key = enc.Key.fromBase64(base64Key);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Combine IV and encrypted data separated by a dot
      return '${iv.base64}.${encrypted.base64}';
    } catch (e) {
      return plainText; // Fallback or Error handling
    }
  }

  // Decrypts cipher text using the group's specific key.
  static String decryptMessage(String cipherData, String base64Key) {
    if (base64Key.isEmpty || cipherData.isEmpty || !cipherData.contains('.')) {
      return cipherData;
    }
    try {
      final parts = cipherData.split('.');
      if (parts.length != 2) return cipherData;

      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final key = enc.Key.fromBase64(base64Key);

      final decrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      return decrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return '[(Encrypted Content)]'; // Fallback
    }
  }
}
