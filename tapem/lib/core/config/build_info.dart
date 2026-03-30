class BuildInfo {
  BuildInfo._();

  static const buildDate = String.fromEnvironment(
    'BUILD_DATE',
    defaultValue: '–',
  );
}
