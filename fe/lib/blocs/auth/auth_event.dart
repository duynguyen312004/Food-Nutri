import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Sự kiện: user nhấn đăng nhập Google
class AuthSignInWithGoogle extends AuthEvent {}

// Sự kiện: user nhấn đăng nhập Facebook
class AuthSignInWithFacebook extends AuthEvent {}

// Sự kiện: user nhấn đăng nhập Apple
class AuthSignInWithApple extends AuthEvent {}

// Sự kiện: user nhấn đăng xuất
class AuthSignOut extends AuthEvent {}
