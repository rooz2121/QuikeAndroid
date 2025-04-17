// App configuration for different environments
enum Environment { development, production }

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();
  
  // Current environment
  Environment environment = Environment.production;
  
  // API Keys
  String get groqApiKey {
    switch (environment) {
      case Environment.development:
        return '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'; // Development key
      case Environment.production:
        return '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'; // Production key (same for now)
    }
  }
  
  // App Settings
  bool get showDebugBanner => environment == Environment.development;
  String get appName => 'Quike AI';
  String get appVersion => '1.0.0';
  
  // Feature Flags
  bool get enableAnalytics => environment == Environment.production;
  bool get enableCrashReporting => environment == Environment.production;
}
