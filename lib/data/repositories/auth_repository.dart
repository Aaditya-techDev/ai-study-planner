import '../models/user_model.dart';
import '../remote/firebase_auth_service.dart';
import '../local/sqlite_helper.dart';

class AuthRepository {
  final FirebaseAuthService _authService;
  final SQLiteHelper _sqliteHelper;

  AuthRepository({
    FirebaseAuthService? authService,
    SQLiteHelper? sqliteHelper,
  })  : _authService = authService ?? FirebaseAuthService(),
        _sqliteHelper = sqliteHelper ?? SQLiteHelper.instance;

  Stream<User?> get authStateChanges => _authService.authStateChanges;
  User? get currentUser => _authService.currentUser;

  Future<User?> checkPersistedUser() async {
    return await _authService.restorePersistedUser();
  }

  Future<User> login(String email, String password) async {
    final user = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _sqliteHelper.insertUser(user);
    return user;
  }

  Future<User> register(String email, String password) async {
    final user = await _authService.registerWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _sqliteHelper.insertUser(user);
    return user;
  }

  Future<void> updateUser(User user) async {
    await _sqliteHelper.insertUser(user);
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
