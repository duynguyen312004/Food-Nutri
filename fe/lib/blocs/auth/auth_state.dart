import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Ban đầu chưa xác định
class AuthInitial extends AuthState {}

// Đang chờ xử lý
class AuthLoading extends AuthState {}

// Đăng nhập thành công, chứa Firebase User
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user.uid];
}

// Chưa đăng nhập
class AuthUnauthenticated extends AuthState {}

// Có lỗi, chứa message
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
