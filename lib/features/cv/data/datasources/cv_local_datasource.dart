import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/persisted_cv_record.dart';

class CvLocalDataSource {
  final SecureStorageService storage;

  CvLocalDataSource({required this.storage});

  static String keyFor(String userId) => 'cv_state_$userId';

  Future<PersistedCvRecord?> read(String userId) async {
    try {
      final raw = await storage.read(key: keyFor(userId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('cv state');
      }
      return PersistedCvRecord.fromJson(decoded);
    } on CacheException {
      rethrow;
    } catch (_) {
      throw CacheException('Could not read the saved CV');
    }
  }

  Future<void> write(String userId, PersistedCvRecord record) async {
    try {
      await storage.write(
        key: keyFor(userId),
        value: jsonEncode(record.toJson()),
      );
    } on CacheException {
      rethrow;
    } catch (_) {
      throw CacheException('Could not save the CV on this device');
    }
  }

  Future<void> delete(String userId) async {
    await storage.delete(key: keyFor(userId));
  }
}
