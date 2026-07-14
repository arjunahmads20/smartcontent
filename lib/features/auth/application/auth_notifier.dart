import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthInitial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = AuthLoading();
    try {
      final user = await _repository.checkAuthStatus();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      final user = await _repository.login(email, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    int? careerDreamId,
  }) async {
    state = AuthLoading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        careerDreamId: careerDreamId,
      );
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthUnauthenticated();
  }

  Future<void> updateCareer(int careerDreamId) async {
    if (state is! AuthAuthenticated) return;
    
    // Save current user in case we need to revert on error
    final currentUser = (state as AuthAuthenticated).user;
    
    try {
      final user = await _repository.updateProfile({'career_dream': careerDreamId});
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthAuthenticated(currentUser);
      throw Exception('Failed to update career: $e');
    }
  }

  Future<void> updateProfile({String? firstName, String? lastName, String? avatarUrl}) async {
    if (state is! AuthAuthenticated) return;
    
    final currentUser = (state as AuthAuthenticated).user;
    final Map<String, dynamic> data = {};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    
    try {
      final user = await _repository.updateProfile(data);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthAuthenticated(currentUser);
      throw Exception('Failed to update profile: $e');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
