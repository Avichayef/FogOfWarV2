import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _serverConnected = false;
  bool _offlineMode = false; // New flag for offline mode

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isServerConnected => _serverConnected || _offlineMode;
  bool get isOfflineMode => _offlineMode;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First check network connectivity
      print('Checking network connectivity...');
      var connectivityResult = await Connectivity().checkConnectivity();
      bool hasConnectivity = connectivityResult != ConnectivityResult.none;

      print('Network connectivity: $hasConnectivity (${connectivityResult.name})');

      if (!hasConnectivity) {
        print('No network connectivity');
        _serverConnected = false;
      } else {
        // Check server connection with timeout
        print('Checking server connection...');
        try {
          _serverConnected = await _apiService.checkServerStatus()
              .timeout(const Duration(seconds: 5), onTimeout: () {
            print('Server connection check timed out');
            return false;
          });
        } catch (e) {
          print('Error checking server status: $e');
          _serverConnected = false;
        }

        print('Server connection status: $_serverConnected');

        if (!_serverConnected) {
          print('Warning: Server is not connected');
        }
      }

      // Check if user is already logged in
      String? username = await _secureStorage.read(key: 'username');
      String? password = await _secureStorage.read(key: 'password');

      if (username != null && password != null && _serverConnected) {
        await login(username, password);
      }
    } catch (e) {
      print('Error initializing auth provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enable offline mode for testing
  Future<void> enableOfflineMode() async {
    _offlineMode = true;
    notifyListeners();
  }

  Future<bool> register(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // If offline mode is enabled, create a mock user
      if (_offlineMode) {
        // Create a mock user with ID 999
        _currentUser = User(id: 999, username: username);

        // Save credentials securely
        await _secureStorage.write(key: 'username', value: username);
        await _secureStorage.write(key: 'password', value: password);

        notifyListeners();
        return true;
      }

      // Online mode - check server connection
      if (!_serverConnected) {
        _serverConnected = await _apiService.checkServerStatus();
        if (!_serverConnected) {
          throw Exception('Server is not connected');
        }
      }

      // Register user
      final result = await _apiService.registerUser(username, password);
      final int userId = result['id'];
      _currentUser = User(id: userId, username: username);

      // Save credentials securely
      await _secureStorage.write(key: 'username', value: username);
      await _secureStorage.write(key: 'password', value: password);

      notifyListeners();
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // If offline mode is enabled, create a mock user
      if (_offlineMode) {
        // Create a mock user with ID 999
        _currentUser = User(id: 999, username: username);

        // Save credentials securely
        await _secureStorage.write(key: 'username', value: username);
        await _secureStorage.write(key: 'password', value: password);

        notifyListeners();
        return true;
      }

      // Online mode - check server connection
      if (!_serverConnected) {
        _serverConnected = await _apiService.checkServerStatus();
        if (!_serverConnected) {
          throw Exception('Server is not connected');
        }
      }

      // Login user
      final result = await _apiService.loginUser(username, password);
      final int userId = result['id'];
      _currentUser = User(id: userId, username: username);

      // Save credentials securely
      await _secureStorage.write(key: 'username', value: username);
      await _secureStorage.write(key: 'password', value: password);

      notifyListeners();
      return true;
    } catch (e) {
      print('Error logging in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = null;

      // Clear saved credentials
      await _secureStorage.delete(key: 'username');
      await _secureStorage.delete(key: 'password');

      notifyListeners();
    } catch (e) {
      print('Error logging out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
