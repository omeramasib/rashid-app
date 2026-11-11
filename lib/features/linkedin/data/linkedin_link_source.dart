import 'package:app_links/app_links.dart';

abstract class LinkedInLinkSource {
  Future<Uri?> getInitialLink();

  Stream<Uri> get uriLinkStream;
}

class AppLinksLinkedInSource implements LinkedInLinkSource {
  final AppLinks _links = AppLinks();

  @override
  Future<Uri?> getInitialLink() => _links.getInitialLink();

  @override
  Stream<Uri> get uriLinkStream => _links.uriLinkStream;
}
