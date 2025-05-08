// import 'package:flutter/foundation.dart';
// import 'package:nutrition_app/models/user_model.dart';
// import '../services/auth_service.dart';

// class AuthProvider extends ChangeNotifier {
//   final AuthService _service;

//   UserModel? _user;
//   bool _isLoading = true;
//   String? _error;

//   UserModel? get user => _user;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   AuthProvider(this._service) {
//     // Nghe sự thay đổi đăng nhập
//     _service.authStateChanges.listen((u) {
//       _user = u;
//       _isLoading = false;
//       notifyListeners();
//     });
//   }

//   Future<void> signIn(String email, String pass) async {
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//     final u = await _service.signIn(email, pass);
//     if (u == null) {
//       _error = 'Đăng nhập thất bại';
//       _isLoading = false;
//       notifyListeners();
//     }
//     // nếu thành công, stream đã cập nhật _user
//   }

//   Future<void> signOut() => _service.signOut();
// }
