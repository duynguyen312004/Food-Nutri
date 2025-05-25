// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 👉 Thêm dòng này để xoá session, buộc hiện lại account picker
      await _google.signOut();

      // Trigger the authentication flow
      final googleUser = await _google.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  Future<UserCredential?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status == LoginStatus.success) {
      final cred =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
      return _auth.signInWithCredential(cred);
    }
    return null;
  }

  Future<UserCredential?> signInWithApple() async {
    final appleCred = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );
    final cred = OAuthProvider("apple.com").credential(
      idToken: appleCred.identityToken,
      accessToken: appleCred.authorizationCode,
    );
    return _auth.signInWithCredential(cred);
  }

  Future<void> signOut() async {
    try {
      if (await _google.isSignedIn()) {
        await _google.signOut(); // Chỉ logout, không revoke
      }
    } catch (e) {
      print("Google signOut error: $e");
    }

    try {
      // await FacebookAuth.instance.logOut();
    } catch (e) {
      print("Facebook logout error: $e");
    }

    await _auth.signOut(); // Firebase logout
  }
}
