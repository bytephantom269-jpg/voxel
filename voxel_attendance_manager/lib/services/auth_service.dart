import 'package:shared_preferences/shared_preferences.dart';
import '../utils/security.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  late SharedPreferences _prefs;
  
  String? _currentUser;
  String? _sessionToken;
  DateTime? _sessionStart;
  static const int sessionTimeoutMinutes = 60;
  
  List<String> _allowedUsers = [];
  Map<String, List<String>> _userPermissions = {};

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _setupPermissions();
  }

  void _setupPermissions() {
    _allowedUsers = ['admin', 'manager', 'employee'];
    
    _userPermissions = {
      'admin': ['add_employee', 'edit_employee', 'delete_employee', 'export', 'settings'],
      'manager': ['add_employee', 'edit_employee', 'export'],
      'employee': ['view_attendance', 'checkin'],
    };
  }

  Future<bool> login(String username, String password) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        SecurityValidator.logAudit('LOGIN_FAILED', username, 'Empty credentials', false);
        return false;
      }

      if (!SecurityValidator.checkRateLimit('login_$username')) {
        SecurityValidator.logAudit('LOGIN_BLOCKED', username, 'Rate limit exceeded', false);
        return false;
      }

      if (!_allowedUsers.contains(username)) {
        SecurityValidator.logAudit('LOGIN_FAILED', username, 'User not found', false);
        return false;
      }

      final hashedPassword = SecurityValidator.hashPassword(password);
      final storedHash = _prefs.getString('user_password_$username');
      
      if (storedHash != hashedPassword) {
        SecurityValidator.logAudit('LOGIN_FAILED', username, 'Invalid password', false);
        return false;
      }

      _currentUser = username;
      _sessionToken = SecurityValidator.generateSecureToken(username);
      _sessionStart = DateTime.now();
      
      await _prefs.setString('current_user', username);
      await _prefs.setString('session_token', _sessionToken!);
      
      SecurityValidator.logAudit('LOGIN_SUCCESS', username, 'User logged in', true);
      print('Login successful for: $username');
      return true;
    } catch (e) {
      SecurityValidator.logAudit('LOGIN_ERROR', username, e.toString(), false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        SecurityValidator.logAudit('LOGOUT', _currentUser!, 'User logged out', true);
      }
      
      _currentUser = null;
      _sessionToken = null;
      _sessionStart = null;
      
      await _prefs.remove('current_user');
      await _prefs.remove('session_token');
      print('Logout successful');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  bool isSessionValid() {
    if (_sessionStart == null) return false;
    
    final elapsed = DateTime.now().difference(_sessionStart!);
    if (elapsed.inMinutes > sessionTimeoutMinutes) {
      print('Session expired');
      return false;
    }
    
    return true;
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    if (!isSessionValid()) return false;
    
    final permissions = _userPermissions[_currentUser];
    return permissions?.contains(permission) ?? false;
  }

  String? getCurrentUser() => _currentUser;
  String? getSessionToken() => _sessionToken;

  Future<bool> registerUser(String username, String role, String password) async {
    try {
      if (username.isEmpty || role.isEmpty || password.isEmpty) {
        return false;
      }

      if (!_allowedUsers.contains(role)) {
        return false;
      }

      final existing = _prefs.getString('user_password_$username');
      if (existing != null) {
        return false;
      }

      final hashedPassword = SecurityValidator.hashPassword(password);
      await _prefs.setString('user_password_$username', hashedPassword);
      await _prefs.setString('user_role_$username', role);
      
      SecurityValidator.logAudit('USER_REGISTERED', username, 'New user registered with role: $role', true);
      print('User registered: $username');
      return true;
    } catch (e) {
      SecurityValidator.logAudit('REGISTRATION_ERROR', username, e.toString(), false);
      return false;
    }
  }
}
