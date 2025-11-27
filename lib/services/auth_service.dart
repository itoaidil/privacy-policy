import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storageService = StorageService();
  Map<String, dynamic>? _currentUser;

  // Check if user is logged in (memory or storage)
  bool get isLoggedIn => _currentUser != null;

  // Get current user data
  Map<String, dynamic>? get currentUser => _currentUser;

  // Initialize - load user data from storage if exists
  Future<bool> initialize() async {
    try {
      final isLoggedIn = await _storageService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _storageService.getUserData();
        return _currentUser != null;
      }
      return false;
    } catch (e) {
      print('Error initializing auth: $e');
      return false;
    }
  }

  // Set user data after login and save to storage
  Future<void> setUser(Map<String, dynamic> userData) async {
    _currentUser = userData;
    await _storageService.saveLoginSession(userData);
  }

  // Clear user data on logout
  Future<void> logout() async {
    _currentUser = null;
    await _storageService.clearLoginSession();
  }

  // Get user ID
  int? get userId => _currentUser?['id'];

  // Get user name
  String? get userName => _currentUser?['full_name'];

  // Get user full name (alias)
  String? get userFullName => _currentUser?['full_name'];

  // Get user email
  String? get userEmail => _currentUser?['email'];

  // Get user phone
  String? get userPhone => _currentUser?['phone'];
}
