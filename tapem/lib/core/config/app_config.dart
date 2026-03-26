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

  static const appName = "Tap'em";
  static const appVersion = '1.0.0';

  /// XP constants (authoritative values — server enforces these too)
  static const xpTrainingDay = 25;
  static const xpPerSet = 5;
  static const xpPerFiveReps = 1; // floor(reps/5)
  static const xpExerciseCap = 120;

  /// Performance budgets
  static const workoutStartBudgetMs = 700;
  static const setLoggingBudgetMs = 150;

  /// Sync
  static const syncRetryMaxAttempts = 5;
  static const syncRetryBaseDelayMs = 500;
}
