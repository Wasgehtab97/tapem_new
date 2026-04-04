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

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const admin = '/admin';
  static const adminOwnerOverview = '/admin/owner-overview';
  static const adminNfc = '/admin/nfc';
  static const adminGymSettings = '/admin/gym-settings';
  static const adminEquipment = '/admin/equipment';
  static const adminExercises = '/admin/exercises';
  static const adminMembers = '/admin/members';
  static const adminRoles = '/admin/roles';
  static const adminChallenges = '/admin/challenges';
  static const adminAnalytics = '/admin/analytics';
  static const adminEquipmentAnalytics = '/admin/equipment-analytics';
  static const adminEngagement = '/admin/engagement';
  static const adminModeration = '/admin/moderation';
  static const adminEquipmentFeedback = '/admin/equipment-feedback';
  static const adminFloorPlan = '/admin/floor-plan';

  // ── Nutrition ─────────────────────────────────────────────────────────────
  static const nutrition = '/nutrition';
  static const nutritionDay = '/nutrition/day';
  static const nutritionGoals = '/nutrition/goals';
  static const nutritionEntry = '/nutrition/entry';
  static const nutritionSearch = '/nutrition/search';
  static const nutritionScan = '/nutrition/scan';
  static const nutritionRecipes = '/nutrition/recipes';
  static const nutritionRecipeEdit = '/nutrition/recipe-edit';
  static const nutritionWeight = '/nutrition/weight';
  static const nutritionCalendar = '/nutrition/calendar';
}
