import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static GoogleSignIn? _googleSignIn;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Private constructor
  AuthService._internal();

  // Factory constructor for singleton
  factory AuthService({String? googleClientId}) {
    if (googleClientId != null) {
      _googleSignIn ??= GoogleSignIn(
        clientId: googleClientId,
        scopes: ['email', 'profile'],
      );
    }
    return _instance;
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign up with email and password
  Future<User?> signUpWithEmail(
    String email,
    String password, {
    required String firstname,
    required String lastname,
    required String username,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName('$firstname $lastname');

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'firstname': firstname,
          'lastname': lastname,
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login with email and password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw Exception(
          'Google Sign-In not initialized. Please provide googleClientId.');
    }

    try {
      GoogleSignInAccount? googleUser = await _googleSignIn!.signInSilently();
      googleUser ??= await _googleSignIn!.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by user');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      // Only save to Firestore on first-time Google sign-in
      if (user != null &&
          userCredential.additionalUserInfo?.isNewUser == true) {
        final nameParts = (user.displayName ?? '').split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'firstname': firstName,
          'lastname': lastName,
          'username': firstName.toLowerCase(),
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      if (e.toString().contains('popup_closed') ||
          e.toString().contains('cancelled')) {
        return null;
      }
      throw Exception('Google sign-in error: ${e.toString()}');
    }
  }

  // Sign in with Facebook
  Future<User?> signInWithFacebook() async {
    try {
      throw UnimplementedError('Facebook sign-in not yet implemented');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send verification email
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // Reload user data
  Future<void> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  // Helper method to handle Firebase auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-credential':
        return 'Invalid credentials provided.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}