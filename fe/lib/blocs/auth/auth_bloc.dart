// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    // Khi bloc khởi tạo, ta lắng nghe authStateChanges để tự động chuyển state
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        add(_AuthUserChanged(user));
      } else
        add(_AuthUserChanged(null));
    });

    // Xử lý các event public
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInWithFacebook>(_onSignInWithFacebook);
    on<AuthSignInWithApple>(_onSignInWithApple);
    on<AuthSignOut>(_onSignOut);
    // Event private để xử lý khi authStateChanges thay đổi
    on<_AuthUserChanged>(_onUserChanged);
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred?.user != null) {
        emit(AuthAuthenticated(cred!.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Google sign-in thất bại: $e'));
    }
  }

  Future<void> _onSignInWithFacebook(
    AuthSignInWithFacebook event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final cred = await _authService.signInWithFacebook();
      if (cred?.user != null) {
        emit(AuthAuthenticated(cred!.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Facebook sign-in thất bại: $e'));
    }
  }

  Future<void> _onSignInWithApple(
    AuthSignInWithApple event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final cred = await _authService.signInWithApple();
      if (cred?.user != null) {
        emit(AuthAuthenticated(cred!.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Apple sign-in thất bại: $e'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOut event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authService.signOut();
    emit(AuthUnauthenticated());
  }

  // Event private để phản hồi authStateChanges
  void _onUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null)
      emit(AuthAuthenticated(event.user!));
    else
      emit(AuthUnauthenticated());
  }
}

// Event private không expose ra ngoài
class _AuthUserChanged extends AuthEvent {
  final User? user;
  _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user?.uid];
}
