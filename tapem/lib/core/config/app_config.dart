/// Application-wide configuration constants.
/// Secrets are injected via --dart-define at build time, never hardcoded.
abstract final class AppConfig {
  // --dart-define=SUPABASE_URL=... (fallback for local dev)
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jkovfqvvdzpzcknpxzyi.supabase.co',
  );
  // --dart-define=SUPABASE_ANON_KEY=... (anon key is public — safe to embed)
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imprb3ZmcXZ2ZHpwemNrbnB4enlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NjQ3ODAsImV4cCI6MjA4OTQ0MDc4MH0'
        '.3ZSlnwW8zSLFxnZYCkmPxq4n75muy4c8rbB9tEHjBy8',
  );

  // --dart-define=USDA_API_KEY=... (register free at fdc.nal.usda.gov)
  // Falls back to DEMO_KEY for local dev (30 req/h limit — not for production).
  static const usdaApiKey = String.fromEnvironment(
    'USDA_API_KEY',
    defaultValue: 'DEMO_KEY',
  );

  static const appName = "Tap'em";
  static const appVersion = '1.0.0';

  /// Legal / support URLs (override per environment via --dart-define).
  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://tapem.app/privacy',
  );
  static const termsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
    defaultValue: 'https://tapem.app/terms',
  );
  static const imprintUrl = String.fromEnvironment(
    'IMPRINT_URL',
    defaultValue: 'https://tapem.app/imprint',
  );
  static const supportUrl = String.fromEnvironment(
    'SUPPORT_URL',
    defaultValue: 'https://tapem.app/support',
  );

  /// XP constants (authoritative values — server enforces these too)
  static const xpTrainingDay = 25;
  static const xpPerSet = 5;
  static const xpPerFiveReps = 1; // floor(reps/5)
  static const xpExerciseCap = 120;

  /// Muscle group XP — flat per exercise per group (≥1 set required).
  static const double xpMuscleGroupPrimary = 10.0;
  static const double xpMuscleGroupSecondary = 2.5;

  /// Performance budgets
  static const workoutStartBudgetMs = 700;
  static const setLoggingBudgetMs = 150;

  /// Sync
  static const syncRetryMaxAttempts = 5;
  static const syncRetryBaseDelayMs = 500;
}
