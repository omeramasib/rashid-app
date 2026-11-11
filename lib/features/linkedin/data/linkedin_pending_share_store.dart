import '../../../../core/storage/secure_storage_service.dart';

abstract class LinkedInPendingShareStore {
  Future<void> save(String simulationId);

  Future<String?> read();

  Future<void> clear();
}

class SecureLinkedInPendingShareStore implements LinkedInPendingShareStore {
  static const String storageKey = 'linkedin_pending_simulation_id';

  final SecureStorageService storage;

  SecureLinkedInPendingShareStore(this.storage);

  @override
  Future<void> save(String simulationId) {
    return storage.write(key: storageKey, value: simulationId);
  }

  @override
  Future<String?> read() {
    return storage.read(key: storageKey);
  }

  @override
  Future<void> clear() {
    return storage.delete(key: storageKey);
  }
}
