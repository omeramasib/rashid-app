import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rashed_app/app/routes_name.dart';
import 'package:rashed_app/core/auth/end_rashed_session.dart';
import 'package:rashed_app/core/auth/rashed_session.dart';
import 'package:rashed_app/core/storage/secure_storage_service.dart';

class MockStorage extends Mock implements SecureStorageService {}

void main() {
  late MockStorage storage;
  late RashedSession session;

  setUp(() {
    storage = MockStorage();
    session = RashedSession(storage);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => storage.deleteAll()).thenAnswer((_) async {});
  });

  test('clear deletes only the authentication keys and notifies listeners',
      () async {
    var notified = false;
    final sub = session.onCleared.listen((_) => notified = true);
    await session.clear();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(notified, isTrue);
    verify(() => storage.delete(key: RashedSession.tokenKey)).called(1);
    verify(() => storage.delete(key: RashedSession.userIdKey)).called(1);
    verify(() => storage.delete(key: RashedSession.emailKey)).called(1);
    verifyNever(() => storage.deleteAll());
  });

  testWidgets('profile logout opens login without signing out of Clerk',
      (tester) async {
    final sl = GetIt.asNewInstance();
    sl.registerSingleton<RashedSession>(session);
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          RoutesName.login: (_) => const Text('login-route'),
        },
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => endRashedSession(context, sl<RashedSession>()),
              child: const Text('logout'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('logout'));
    await tester.pumpAndSettle();
    expect(find.text('login-route'), findsOneWidget);
    verify(() => storage.delete(key: RashedSession.tokenKey)).called(1);
    verifyNever(() => storage.deleteAll());
  });
}
