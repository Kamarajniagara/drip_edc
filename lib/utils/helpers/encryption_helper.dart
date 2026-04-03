import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class EncryptionHelper {
  static const String _encryptionKey = "1442edd0ed64858387254415854db56f46d97e232380f82ba45842e0fe543bf3";
  static const int _ivLength = 12;
  static const int _authTagLength = 16;

  static Uint8List? _keyBytes;
  static bool _isInitialized = false;

  static void init() {
    // Only initialize once
    if (_isInitialized) {
      print('EncryptionHelper already initialized, skipping...');
      return;
    }

    _keyBytes = _hexDecode(_encryptionKey);
    _isInitialized = true;
    print('EncryptionHelper initialized successfully');
  }

  static Uint8List _hexDecode(String hexString) {
    if (hexString.length % 2 != 0) {
      throw Exception('Invalid hex string length');
    }

    final bytes = <int>[];
    for (int i = 0; i < hexString.length; i += 2) {
      final hexByte = hexString.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  static String decrypt(String encryptedPayload) {
    // Ensure initialized
    if (!_isInitialized) {
      init();
    }

    try {
      final data = base64.decode(encryptedPayload);

      final iv = data.sublist(0, _ivLength);
      final authTag = data.sublist(_ivLength, _ivLength + _authTagLength);
      final cipherText = data.sublist(_ivLength + _authTagLength);

      final keyParam = KeyParameter(_keyBytes!);
      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(keyParam, _authTagLength * 8, iv, Uint8List(0)));

      // Combine ciphertext and auth tag for decryption
      final combined = Uint8List(cipherText.length + authTag.length)
        ..setAll(0, cipherText)
        ..setAll(cipherText.length, authTag);

      final decrypted = Uint8List(combined.length);
      final len = cipher.processBytes(combined, 0, combined.length, decrypted, 0);
      final finalLen = cipher.doFinal(decrypted, len);

      final result = decrypted.sublist(0, len + finalLen);
      return utf8.decode(result);
    } catch (e) {
      print('Decryption error: $e');
      return encryptedPayload;
    }
  }

  static bool isEncrypted(String response) {
    try {
      final decoded = base64.decode(response);
      return decoded.length > _ivLength;
    } catch (e) {
      return false;
    }
  }
}