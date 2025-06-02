import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  User? get currentUser => _auth.currentUser;

  // Add auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('User signed in successfully: ${result.user?.uid}');
      return {'success': true, 'user': result.user};
    } catch (e) {
      _logger.e('Error signing in: $e');
      String errorMessage = _getErrorMessage(e);
      return {'success': false, 'error': errorMessage};
    }
  }

  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String namaLengkap,
    required String kodeKkn,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Save additional user data to Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'namaLengkap': namaLengkap,
          'kodeKkn': kodeKkn,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _logger.i('User registered successfully: ${result.user?.uid}');
        return {'success': true, 'user': result.user};
      }

      return {'success': false, 'error': 'Gagal membuat akun'};
    } catch (e) {
      _logger.e('Error registering: $e');
      String errorMessage = _getErrorMessage(e);
      return {'success': false, 'error': errorMessage};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i('Password reset email sent to: $email');
      return {'success': true};
    } catch (e) {
      _logger.e('Error sending password reset email: $e');
      String errorMessage = _getErrorMessage(e);
      return {'success': false, 'error': errorMessage};
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Password minimal 6 karakter';
        case 'email-already-in-use':
          return 'Email sudah terdaftar';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'user-not-found':
          return 'Email tidak terdaftar';
        case 'wrong-password':
          return 'Password salah';
        case 'invalid-credential':
          return 'Email atau password salah';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan, coba lagi nanti';
        default:
          return 'Terjadi kesalahan: ${error.message}';
      }
    }
    return 'Terjadi kesalahan tidak dikenal';
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Error signing out: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        _logger.i('User data retrieved successfully');
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user data: $e');
      return null;
    }
  }
}
