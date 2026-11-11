import 'package:url_launcher/url_launcher.dart';

abstract class LinkedInAuthorizationLauncher {
  Future<bool> open(Uri url);
}

class UrlLauncherLinkedInAuthorization
    implements LinkedInAuthorizationLauncher {
  @override
  Future<bool> open(Uri url) {
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
