import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInService {
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign In instance for v7.2.0
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of Firebase auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google (v7.2.0 API)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: Starting Google sign-in process...');
      }

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        if (kDebugMode) {
          print('🔵 GoogleSignInService: ⚠️ User cancelled Google sign-in');
        }
        return null;
      }

      if (kDebugMode) {
        print('🔵 GoogleSignInService: ✅ Google account selected: ${googleUser.email}');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (kDebugMode) {
        print('🔵 GoogleSignInService: Got authentication tokens');
        print('🔵 GoogleSignInService: Access Token: ${googleAuth.accessToken != null ? "Present" : "Missing"}');
        print('🔵 GoogleSignInService: ID Token: ${googleAuth.idToken != null ? "Present" : "Missing"}');
      }

      // Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) {
        print('🔵 GoogleSignInService: Signing in to Firebase...');
      }

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print('🔵 GoogleSignInService: ✅✅✅ SUCCESS! ✅✅✅');
        print('🔵 GoogleSignInService: Firebase User UID: ${userCredential.user?.uid}');
        print('🔵 GoogleSignInService: Firebase User Email: ${userCredential.user?.email}');
        print('🔵 GoogleSignInService: Firebase User Name: ${userCredential.user?.displayName}');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: ❌ FirebaseAuthException: ${e.code}');
        print('🔵 GoogleSignInService: Message: ${e.message}');
      }
      
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('An account already exists with the same email address but different sign-in credentials.');
        case 'invalid-credential':
          throw Exception('The credential is malformed or has expired.');
        case 'operation-not-allowed':
          throw Exception('Google sign-in is not enabled for this project.');
        case 'user-disabled':
          throw Exception('This user account has been disabled.');
        case 'user-not-found':
          throw Exception('No user found for the given credential.');
        case 'wrong-password':
          throw Exception('Invalid credential.');
        default:
          throw Exception('Google sign-in failed: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: ❌ Unexpected error: $e');
        print('🔵 GoogleSignInService: Error type: ${e.runtimeType}');
      }
      throw Exception('An unexpected error occurred during Google sign-in: $e');
    }
  }

  /// Silent sign-in - try to sign in without user interaction
  Future<UserCredential?> silentSignIn() async {
    try {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: Attempting silent sign-in...');
      }

      // Try to sign in silently
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      if (googleUser == null) {
        if (kDebugMode) {
          print('🔵 GoogleSignInService: No cached account found');
        }
        return null;
      }

      if (kDebugMode) {
        print('🔵 GoogleSignInService: Found cached account: ${googleUser.email}');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print('🔵 GoogleSignInService: ✅ Silent sign-in successful!');
      }

      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: Silent sign-in failed: $e');
      }
      return null;
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: Signing out...');
      }

      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();

      if (kDebugMode) {
        print('🔵 GoogleSignInService: ✅ User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: ❌ Error during sign out: $e');
      }
      rethrow;
    }
  }

  /// Disconnect Google account (revoke access)
  Future<void> disconnectGoogle() async {
    try {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: Disconnecting Google account...');
      }

      await _googleSignIn.disconnect();
      await _auth.signOut();

      if (kDebugMode) {
        print('🔵 GoogleSignInService: ✅ Google account disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔵 GoogleSignInService: ❌ Error disconnecting Google account: $e');
      }
      rethrow;
    }
  }

  /// Check if user is currently signed in with Google
  Future<bool> isSignedInWithGoogle() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current Google Sign-In account
  GoogleSignInAccount? get currentGoogleAccount => _googleSignIn.currentUser;

  /// Check if Firebase user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Get user display name
  String? getUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  /// Get user email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Get user photo URL
  String? getUserPhotoUrl() {
    return _auth.currentUser?.photoURL;
  }

  /// Get user ID
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get detailed user information
  Map<String, dynamic>? getUserInfo() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'phoneNumber': user.phoneNumber,
      'metadata': {
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      },
      'providerData': user.providerData.map((info) => {
        'providerId': info.providerId,
        'uid': info.uid,
        'displayName': info.displayName,
        'email': info.email,
        'photoURL': info.photoURL,
        'phoneNumber': info.phoneNumber,
      }).toList(),
    };
  }
}