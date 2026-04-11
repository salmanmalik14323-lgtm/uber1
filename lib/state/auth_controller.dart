import 'package:flutter/foundation.dart';

/// Mock auth: any non-empty email/phone + password succeeds. Guest skips auth.
class AuthController extends ChangeNotifier {
  bool _sessionActive = false;
  bool _isGuest = false;
  String? _displayLabel;

  bool get sessionActive => _sessionActive;
  bool get isGuest => _isGuest;
  String? get displayLabel => _displayLabel;

  void loginWithEmail(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('Enter email and password');
    }
    _isGuest = false;
    _displayLabel = email.trim();
    _sessionActive = true;
    notifyListeners();
  }

  void loginWithPhone(String phone, String password) {
    if (phone.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('Enter phone and password');
    }
    _isGuest = false;
    _displayLabel = phone.trim();
    _sessionActive = true;
    notifyListeners();
  }

  /// Mock Google-style sign-in (no real OAuth).
  void signInWithGoogleMock() {
    _isGuest = false;
    _displayLabel = 'Google user';
    _sessionActive = true;
    notifyListeners();
  }

  void continueAsGuest() {
    _isGuest = true;
    _displayLabel = 'Guest';
    _sessionActive = true;
    notifyListeners();
  }

  void signOut() {
    _sessionActive = false;
    _isGuest = false;
    _displayLabel = null;
    notifyListeners();
  }
}
