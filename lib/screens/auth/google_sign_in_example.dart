import 'package:flutter/material.dart';
import '../../services/google_sign_in_service.dart';

/// Google Sign-In Button Widget
/// Add this to your landing screen or login screen
class GoogleSignInButton extends StatefulWidget {
  final Function(String)? onSuccess; // Callback with user email
  final Function(String)? onError; // Callback with error message
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  late GoogleSignInService _googleSignInService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _googleSignInService = GoogleSignInService();
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // Sign in with Google
      final userCredential = await _googleSignInService.signIn();

      if (userCredential != null) {
        final user = userCredential.user;
        if (mounted) {
          // Success callback
          widget.onSuccess?.call(user?.email ?? '');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${user?.displayName ?? 'User'}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onError?.call('Sign-in cancelled');
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.grey, width: 1),
          disabledBackgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png', // Add Google logo to assets
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Example: How to add Google Sign-In to Landing Screen
/// 
/// Insert this into your LandingScreen's bottom card:
/// 
/// GoogleSignInButton(
///   onSuccess: (email) {
///     // Navigate to home screen
///     Navigator.pushReplacementNamed(context, '/home');
///   },
///   onError: (error) {
///     print('Sign-in error: $error');
///   },
/// ),
///
/// Add this after the Login button for reference.

/// Alternative: Full Google Sign-In Screen
class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _isLoading = false;
  String? _userEmail;
  String? _userName;
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _checkIfSignedIn();
  }

  Future<void> _checkIfSignedIn() async {
    final isSignedIn = await _googleSignInService.isSignedIn();
    if (isSignedIn) {
      final profile = await _googleSignInService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _userEmail = profile['email'];
          _userName = profile['displayName'];
          _userPhotoUrl = profile['photoUrl'];
        });
      }
    }
  }

  void _signIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await _googleSignInService.signIn();
      if (credential != null && mounted) {
        await _checkIfSignedIn();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
    await _googleSignInService.signOut();
    if (mounted) {
      setState(() {
        _userEmail = null;
        _userName = null;
        _userPhotoUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _userEmail == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_circle, size: 64, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      'Not Signed In',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In with Google'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_userPhotoUrl != null)
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: NetworkImage(_userPhotoUrl!),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _userName ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userEmail ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
