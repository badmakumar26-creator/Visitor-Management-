/// App-wide configuration.
///
/// The API base URL can be overridden at build time:
///   flutter run --dart-define=API_BASE_URL=https://xxxx.mockapi.io/api/v1
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://6ae04b7abe3bc8fead96d649.mockapi.io/',
  );

  static const Duration requestTimeout = Duration(seconds: 15);

  static const List<String> visitorTypes = ['Customer', 'Vendor', 'Other'];
  static const List<String> projects = ['Project A', 'Project B', 'Project C'];
}
