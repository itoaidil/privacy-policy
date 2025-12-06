// Feature Flags Configuration
// Toggle features ON/OFF untuk gradual rollout dan easy rollback

class FeatureFlags {
  // Province-based location filtering
  // Set to false untuk rollback ke behavior lama tanpa app update
  static const bool enableProvinceFiltering = true; // 🚩 TOGGLE THIS

  // Debug mode untuk print logs
  static const bool debugMode = true;

  // Future features (placeholder)
  static const bool enablePushNotifications = false;
  static const bool enableRealTimeTracking = true;
  static const bool enableChatSupport = false;
}

// Helper class untuk check features
class Features {
  static bool get isProvinceFilteringEnabled =>
      FeatureFlags.enableProvinceFiltering;
  static bool get isDebugMode => FeatureFlags.debugMode;

  static void log(String message) {
    if (FeatureFlags.debugMode) {
      print('[FeatureFlag] $message');
    }
  }
}
