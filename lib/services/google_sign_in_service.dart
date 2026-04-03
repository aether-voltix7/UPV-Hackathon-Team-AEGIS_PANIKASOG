import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Get current signed-in account
  Future<GoogleSignInAccount?> get currentAccount => _googleSignIn.signInSilently();

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    final account = await currentAccount;
    return account != null;
  }

  // Sign in with Google
  Future<UserCredential?> signIn() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Disconnect (remove permissions)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  // Get user profile information
  Future<Map<String, String>?> getUserProfile() async {
    try {
      final account = await currentAccount;
      if (account == null) return null;

      return {
        'displayName': account.displayName ?? '',
        'email': account.email,
        'photoUrl': account.photoUrl ?? '',
      };
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get Google token
  Future<String?> getGoogleToken() async {
    try {
      final googleAuth = await _googleSignIn.currentUser?.authentication;
      return googleAuth?.accessToken;
    } catch (e) {
      print('Error getting Google token: $e');
      return null;
    }
  }

  // Get ID token
  Future<String?> getIdToken() async {
    try {
      final googleAuth = await _googleSignIn.currentUser?.authentication;
      return googleAuth?.idToken;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  // Link Google account to existing Firebase user
  Future<UserCredential?> linkGoogleAccount() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return null;

      final userCredential = await currentUser.linkWithCredential(credential);
      return userCredential;
    } catch (e) {
      print('Error linking Google account: $e');
      return null;
    }
  }

  // Unlink Google provider
  Future<void> unlinkGoogle() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await currentUser.unlink('google.com');
      }
    } catch (e) {
      print('Error unlinking Google: $e');
    }
  }
}
