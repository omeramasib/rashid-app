import 'dart:async';

import '../data/linkedin_link_source.dart';
import '../domain/linkedin_oauth_return_link.dart';
import 'cubit/linkedin_share_cubit.dart';

class LinkedInOAuthCoordinator {
  final LinkedInLinkSource links;
  final LinkedInShareCubit cubit;
  final LinkedInReturnGate gate;

  StreamSubscription<Uri>? _subscription;
  var _started = false;

  LinkedInOAuthCoordinator({
    required this.links,
    required this.cubit,
    required this.gate,
  });

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final initial = await links.getInitialLink();
    if (initial != null) _dispatch(initial);
    _subscription = links.uriLinkStream.listen(
      _dispatch,
      onError: (_) {},
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }

  void _dispatch(Uri uri) {
    final parsed = LinkedInOAuthReturnLink.tryParse(uri);
    if (parsed == null) return;
    if (!gate.claim(parsed.dedupeKey)) return;
    cubit.onOAuthReturn(parsed);
  }
}
