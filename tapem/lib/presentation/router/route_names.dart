/// Route path constants. Use these — never hardcode strings.
abstract final class RouteNames {
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const usernameSetup = '/auth/username-setup';
  static const gymSetup = '/auth/gym-setup';

  static const home = '/';
  static const gym = '/gym';
  static const activeWorkout = '/workout/active'; // shell branch 2
  static const progress = '/progress';
  static const plans = '/progress/plans';
  static const planNew = '/progress/plans/new';
  static const community = '/community';
  static const profile = '/profile';
  static const admin = '/admin';
  static const adminNfc = '/admin/nfc';
}
