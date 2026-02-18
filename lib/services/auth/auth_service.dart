import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 익명 로그인
  Future<User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user!;

    // Create user document if it doesn't exist
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set(
        UserModel(uid: user.uid, createdAt: DateTime.now()).toFirestore(),
      );
    }

    return user;
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
