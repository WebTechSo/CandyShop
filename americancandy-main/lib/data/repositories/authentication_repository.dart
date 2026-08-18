import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:american_sweets/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:american_sweets/utils/exceptions/firebase_exceptions.dart';
import 'package:american_sweets/utils/exceptions/platform_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _appName = 'Sweet Stop';

  ActionCodeSettings _verificationActionSettings() {
    return ActionCodeSettings(
      url:
          'https://amaricancandy-c87c3.firebaseapp.com/verify-email?app=${Uri.encodeComponent(_appName)}',
      handleCodeInApp: true,
      iOSBundleId: 'com.example.shopHopProkit',
      androidPackageName: 'com.sweetstop.app',
      androidInstallApp: true,
      androidMinimumVersion: '1',
    );
  }

  ActionCodeSettings _passwordResetActionSettings() {
    return ActionCodeSettings(
      url:
          'https://amaricancandy-c87c3.firebaseapp.com/reset-password?app=${Uri.encodeComponent(_appName)}',
      handleCodeInApp: true,
      iOSBundleId: 'com.example.shopHopProkit',
      androidPackageName: 'com.sweetstop.app',
      androidInstallApp: true,
      androidMinimumVersion: '1',
    );
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _sendEmailVerificationCompat(User user) async {
    final settings = _verificationActionSettings();
    try {
      await (user as dynamic).sendEmailVerification();
      return;
    } catch (_) {}
    try {
      await (user as dynamic)
          .sendEmailVerification();
      return;
    } catch (_) {}
    await user.sendEmailVerification();
  }

  Future<UserCredential> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw UFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw UPlatformException(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final u = cred.user;
      if (u != null) await _sendEmailVerificationCompat(u);
      return cred;
    } on FirebaseAuthException catch (e) {
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw UFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw UPlatformException(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final settings = _passwordResetActionSettings();
      try {
        await (_auth as dynamic)
            .sendPasswordResetEmail(email: email, actionCodeSettings: settings);
      } catch (_) {
        await _auth.sendPasswordResetEmail(email: email);
      }
    } on FirebaseAuthException catch (e) {
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw UFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw UPlatformException(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final u = _auth.currentUser;
      if (u != null) await _sendEmailVerificationCompat(u);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw 'You have to wait 5 minutes before requesting another verification email. Please try again later.';
      }
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw UFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw UPlatformException(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
