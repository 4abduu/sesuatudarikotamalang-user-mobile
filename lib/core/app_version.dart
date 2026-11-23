class AppVersion {
  const AppVersion._();

  // Keep this in sync with pubspec.yaml. It can be overridden in release
  // builds with --dart-define=APP_VERSION=x.y.z.
  static const current = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.1.0',
  );
}
