import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static String hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static bool verify({required String password, required String passwordHash}) {
    return hash(password) == passwordHash;
  }
}
