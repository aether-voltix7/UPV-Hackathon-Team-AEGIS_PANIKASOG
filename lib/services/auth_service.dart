import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Stream ───────────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ─── Email / Password Sign-Up ─────────────────────────────────────────────
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String phoneNumber,
    required String name,
    required String username,
    required String address,
    required List<String> skills,
    required List<String> preferredTasks,
    String? usedReferralCode,
  }) async {
    // 1. Check username uniqueness
    final usernameSnap = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (usernameSnap.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'This username is already taken.',
      );
    }

    // 2. Create Firebase Auth user
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name);

    // 3. Generate unique referral code
    final referralCode = _generateReferralCode(user.uid);

    // 4. Handle referral bonus
    int bonusPoints = 0;
    String? validatedReferral;
    if (usedReferralCode != null && usedReferralCode.isNotEmpty) {
      final referrerSnap = await _db
          .collection('users')
          .where('referralCode', isEqualTo: usedReferralCode)
          .limit(1)
          .get();
      if (referrerSnap.docs.isNotEmpty) {
        validatedReferral = usedReferralCode;
        bonusPoints = 100;
        // Give referrer their 100 pts
        await referrerSnap.docs.first.reference.update({
          'points': FieldValue.increment(100),
        });
      }
    }

    // 5. Create Firestore user document
    final userModel = UserModel(
      uid: user.uid,
      email: email,
      phoneNumber: phoneNumber,
      name: name,
      username: username,
      address: address,
      skills: skills,
      preferredTasks: preferredTasks,
      referralCode: referralCode,
      usedReferralCode: validatedReferral,
      points: bonusPoints,
      dateJoined: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(userModel.toFirestore());

    // 6. Send email verification
    await user.sendEmailVerification();

    return userModel;
  }

  // ─── Email / Password Login ───────────────────────────────────────────────
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUserModel(credential.user!.uid);
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────
  // Future<UserModel> signInWithGoogle() async {
  //   final googleUser = await _googleSignIn.signIn();
  //   if (googleUser == null) {
  //     throw FirebaseAuthException(
  //       code: 'sign-in-cancelled',
  //       message: 'Google sign-in was cancelled.',
  //     );
  //   }
  //   final googleAuth = await googleUser.authentication;
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth.accessToken,
  //     idToken: googleAuth.idToken,
  //   );
  //   final userCredential = await _auth.signInWithCredential(credential);
  //   final user = userCredential.user!;

  //   // Check if first-time
  //   final doc = await _db.collection('users').doc(user.uid).get();
  //   if (!doc.exists) {
  //     // Create minimal profile – user will complete profile later
  //     final username = 'user_${user.uid.substring(0, 6)}';
  //     final userModel = UserModel(
  //       uid: user.uid,
  //       email: user.email ?? '',
  //       name: user.displayName ?? 'User',
  //       username: username,
  //       referralCode: _generateReferralCode(user.uid),
  //       avatarUrl: user.photoURL,
  //       dateJoined: DateTime.now(),
  //     );
  //     await _db.collection('users').doc(user.uid).set(userModel.toFirestore());
  //     return userModel;
  //   }
  //   return UserModel.fromFirestore(doc);
  // }

  Future<UserModel> signInWithGoogle() async {
    try {
      print("Starting Google Sign-In...");
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google sign-in was cancelled by user.");
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }
      print("Google user obtained: ${googleUser.email}");
      
      final googleAuth = await googleUser.authentication;
      print("ID Token: ${googleAuth.idToken}");
      print("Access Token: ${googleAuth.accessToken}");
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      print("Firebase sign-in successful: ${userCredential.user?.uid}");
      
      final user = userCredential.user!;
      // Check if first-time user
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final username = 'user_${user.uid.substring(0, 6)}';
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
          username: username,
          referralCode: _generateReferralCode(user.uid),
          avatarUrl: user.photoURL,
          dateJoined: DateTime.now(),
        );
        await _db.collection('users').doc(user.uid).set(userModel.toFirestore());
        return userModel;
      }
      return UserModel.fromFirestore(doc);
    } catch (e, st) {
      print("Google sign-in failed: $e");
      print(st);
      rethrow;
    }
  }


  // ─── Fetch User Model ─────────────────────────────────────────────────────
  Future<UserModel> _fetchUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User profile not found.',
      );
    }
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchUserModel(user.uid);
    } catch (_) {
      return null;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ─── Password Reset ───────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _generateReferralCode(String uid) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    final base = uid.substring(0, 4).toUpperCase();
    final suffix = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
    return '$base$suffix';
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Validate Philippine mobile number (+63XXXXXXXXXX)
  static bool isValidPhilippinePhone(String phone) {
    return RegExp(r'^\+63[0-9]{10}$').hasMatch(phone);
  }
}
