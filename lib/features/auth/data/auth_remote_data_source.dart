import '../../../firebase/services/auth_service.dart';
import 'models/user_dto.dart';

class AuthRemoteDataSource {
  final AuthService _authService;

  AuthRemoteDataSource(this._authService);

  Future<UserDto?> signIn(String email, String password) async {
    return await _authService.signIn(email, password);
  }

  Future<UserDto?> signUp(String email, String password) async {
    return await _authService.signUp(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<UserDto?> getCurrentUser() async {
    return await _authService.getCurrentUser();
  }
}
