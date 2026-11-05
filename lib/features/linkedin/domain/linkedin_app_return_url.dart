/// Backend redirect target after LinkedIn publishing authorization.
///
/// The app already registers the `rashedapp` scheme. This host and path keep
/// the publishing return separate from Clerk sign-in redirects.
///
/// Vercel must set `LINKEDIN_APP_RETURN_URL` to [value]. This app does not
/// configure that variable.
class LinkedInAppReturnUrl {
  static const String scheme = 'rashedapp';
  static const String host = 'linkedin';
  static const String path = '/oauth';

  static final Uri uri = Uri(scheme: scheme, host: host, path: path);

  static String get value => uri.toString();
}
