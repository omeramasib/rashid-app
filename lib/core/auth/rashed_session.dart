import 'dart:async';

import '../storage/secure_storage_service.dart';

/// Rashed application session stored separately from the Clerk session.
class RashedSession {
  RashedSession(this._storage);

  static const tokenKey = 'token';
  static const userIdKey = 'user_id';
  static const emailKey = 'email';

  static const authKeys = [tokenKey, userIdKey, emailKey];

  final SecureStorageService _storage;
  final StreamController<void> _cleared = StreamController<void>.broadcast();

  Stream<void> get onCleared => _cleared.stream;

  Future<String?> readToken() => _storage.read(key: tokenKey);

  Future<String?> readUserId() => _storage.read(key: userIdKey);

  Future<void> persist({
    String? token,
    String? userId,
    String? email,
  }) async {
    if (token != null && token.isNotEmpty) {
      await _storage.write(key: tokenKey, value: token);
    }
    if (userId != null && userId.isNotEmpty) {
      await _storage.write(key: userIdKey, value: userId);
    }
    if (email != null && email.isNotEmpty) {
      await _storage.write(key: emailKey, value: email);
    }
  }

  /// Removes only the Rashed authentication keys and notifies listeners.
  Future<void> clear() async {
    for (final key in authKeys) {
      await _storage.delete(key: key);
    }
    if (!_cleared.isClosed) _cleared.add(null);
  }
}
