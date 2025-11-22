class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Get current user data
  Map<String, dynamic>? get currentUser => _currentUser;

  // Set user data after login
  void setUser(Map<String, dynamic> userData) {
    _currentUser = userData;
  }

  // Clear user data on logout
  void logout() {
    _currentUser = null;
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
