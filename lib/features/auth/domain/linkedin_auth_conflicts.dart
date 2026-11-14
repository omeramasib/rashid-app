/// Backend `detail` strings for LinkedIn auth HTTP 409 responses.
class LinkedInAuthConflicts {
  static const emailAccountExists =
      'An account with this email already exists. Sign in with email '
      'and connect LinkedIn from your profile.';

  static const identityConflict = 'This LinkedIn account cannot be connected.';

  static bool offersEmailSignIn(String message) =>
      message == emailAccountExists;
}
