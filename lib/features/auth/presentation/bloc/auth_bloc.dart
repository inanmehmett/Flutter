import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/auth_models.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String userNameOrEmail;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.userNameOrEmail,
    required this.password,
    this.rememberMe = true,
  });

  @override
  List<Object?> get props => [userNameOrEmail, password, rememberMe];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String userName;
  final String password;
  final String confirmPassword;

  const RegisterRequested({
    required this.email,
    required this.userName,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, userName, password, confirmPassword];
}

class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthChecking extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserProfile user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthLoading extends AuthState {}

class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthServiceProtocol _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    print('🔐 [AuthBloc] ===== INITIALIZATION =====');
    print(
        '🔐 [AuthBloc] AuthBloc created with AuthService: ${_authService.runtimeType}');

    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);

    print('🔐 [AuthBloc] Event handlers registered');
    print('🔐 [AuthBloc] Initial state: AuthInitial');
    print('🔐 [AuthBloc] ===== INITIALIZATION COMPLETE =====');
  }

  // Getter to access the auth service
  AuthServiceProtocol get authService => _authService;

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 [AuthBloc] ===== CHECK AUTH STATUS START =====');
    print('🔐 [AuthBloc] Current state: $state');
    print('🔐 [AuthBloc] Emitting AuthChecking...');
    emit(AuthChecking());
    print('🔐 [AuthBloc] ✅ AuthChecking emitted');

    try {
      print('🔐 [AuthBloc] Calling _authService.fetchUserProfile()...');
      final user = await _authService.fetchUserProfile();
      print('🔐 [AuthBloc] ✅ User profile fetched successfully');
      print('🔐 [AuthBloc] User: ${user.userName} (${user.email})');
      print('🔐 [AuthBloc] Emitting AuthAuthenticated...');
      emit(AuthAuthenticated(user));
      print('🔐 [AuthBloc] ✅ AuthAuthenticated emitted');
    } catch (e) {
      print('🔐 [AuthBloc] ===== CHECK AUTH STATUS ERROR =====');
      print('🔐 [AuthBloc] Error: $e');
      print('🔐 [AuthBloc] Error Type: ${e.runtimeType}');

      if (e is AuthError) {
        print('🔐 [AuthBloc] AuthError type: $e');
      }

      print('🔐 [AuthBloc] Emitting AuthUnauthenticated...');
      emit(AuthUnauthenticated());
      print('🔐 [AuthBloc] ✅ AuthUnauthenticated emitted');
    }

    print('🔐 [AuthBloc] ===== CHECK AUTH STATUS END =====');
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 [AuthBloc] ===== LOGIN REQUESTED START =====');
    print('🔐 [AuthBloc] Current state: $state');
    print('🔐 [AuthBloc] Username/Email: ${event.userNameOrEmail}');
    print('🔐 [AuthBloc] Remember Me: ${event.rememberMe}');
    print('🔐 [AuthBloc] Password length: ${event.password.length}');

    print('🔐 [AuthBloc] Emitting AuthLoading...');
    emit(AuthLoading());
    print('🔐 [AuthBloc] ✅ AuthLoading emitted');

    try {
      print('🔐 [AuthBloc] Calling _authService.login()...');
      final user = await _authService.login(
        event.userNameOrEmail,
        event.password,
        event.rememberMe,
      );
      print('🔐 [AuthBloc] ✅ Login successful');
      print('🔐 [AuthBloc] User: ${user.userName} (${user.email})');
      print('🔐 [AuthBloc] Emitting AuthAuthenticated...');
      emit(AuthAuthenticated(user));
      print('🔐 [AuthBloc] ✅ AuthAuthenticated emitted');
    } catch (e) {
      print('🔐 [AuthBloc] ===== LOGIN REQUESTED ERROR =====');
      print('🔐 [AuthBloc] Error: $e');
      print('🔐 [AuthBloc] Error Type: ${e.runtimeType}');

      String errorMessage = 'Login failed';
      if (e is AuthError) {
        print('🔐 [AuthBloc] AuthError type: $e');
        errorMessage = e.localizedDescription;
      }

      print('🔐 [AuthBloc] Error message: $errorMessage');
      print('🔐 [AuthBloc] Emitting AuthErrorState...');
      emit(AuthErrorState(errorMessage));
      print('🔐 [AuthBloc] ✅ AuthErrorState emitted');
    }

    print('🔐 [AuthBloc] ===== LOGIN REQUESTED END =====');
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 [AuthBloc] ===== REGISTER REQUESTED START =====');
    print('🔐 [AuthBloc] Current state: $state');
    print('🔐 [AuthBloc] Email: ${event.email}');
    print('🔐 [AuthBloc] Username: ${event.userName}');
    print('🔐 [AuthBloc] Password length: ${event.password.length}');
    print(
        '🔐 [AuthBloc] Confirm password length: ${event.confirmPassword.length}');

    print('🔐 [AuthBloc] Emitting AuthLoading...');
    emit(AuthLoading());
    print('🔐 [AuthBloc] ✅ AuthLoading emitted');

    try {
      print('🔐 [AuthBloc] Calling _authService.register()...');
      final user = await _authService.register(
        event.email,
        event.userName,
        event.password,
        event.confirmPassword,
      );
      print('🔐 [AuthBloc] ✅ Registration successful');
      print('🔐 [AuthBloc] User: ${user.userName} (${user.email})');
      print('🔐 [AuthBloc] Emitting AuthAuthenticated...');
      emit(AuthAuthenticated(user));
      print('🔐 [AuthBloc] ✅ AuthAuthenticated emitted');
    } catch (e) {
      print('🔐 [AuthBloc] ===== REGISTER REQUESTED ERROR =====');
      print('🔐 [AuthBloc] Error: $e');
      print('🔐 [AuthBloc] Error Type: ${e.runtimeType}');

      String errorMessage = 'Registration failed';
      if (e is AuthError) {
        print('🔐 [AuthBloc] AuthError type: $e');
        errorMessage = e.localizedDescription;
      }

      print('🔐 [AuthBloc] Error message: $errorMessage');
      print('🔐 [AuthBloc] Emitting AuthErrorState...');
      emit(AuthErrorState(errorMessage));
      print('🔐 [AuthBloc] ✅ AuthErrorState emitted');
    }

    print('🔐 [AuthBloc] ===== REGISTER REQUESTED END =====');
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔐 [AuthBloc] ===== LOGOUT REQUESTED START =====');
    print('🔐 [AuthBloc] Current state: $state');

    print('🔐 [AuthBloc] Emitting AuthLoading...');
    emit(AuthLoading());
    print('🔐 [AuthBloc] ✅ AuthLoading emitted');

    try {
      print('🔐 [AuthBloc] Calling _authService.logout()...');
      await _authService.logout();
      print('🔐 [AuthBloc] ✅ Logout successful');
      print('🔐 [AuthBloc] Emitting AuthUnauthenticated...');
      emit(AuthUnauthenticated());
      print('🔐 [AuthBloc] ✅ AuthUnauthenticated emitted');
    } catch (e) {
      print('🔐 [AuthBloc] ===== LOGOUT REQUESTED ERROR =====');
      print('🔐 [AuthBloc] Error: $e');
      print('🔐 [AuthBloc] Error Type: ${e.runtimeType}');

      print('🔐 [AuthBloc] Emitting AuthErrorState...');
      emit(AuthErrorState('Logout failed'));
      print('🔐 [AuthBloc] ✅ AuthErrorState emitted');
    }

    print('🔐 [AuthBloc] ===== LOGOUT REQUESTED END =====');
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    print('🔐 [AuthBloc] ===== STATE CHANGE =====');
    print('🔐 [AuthBloc] Previous state: ${change.currentState}');
    print('🔐 [AuthBloc] New state: ${change.nextState}');
    print('🔐 [AuthBloc] ===== STATE CHANGE END =====');
  }

  @override
  void onEvent(AuthEvent event) {
    super.onEvent(event);
    print('🔐 [AuthBloc] ===== EVENT RECEIVED =====');
    print('🔐 [AuthBloc] Event: $event');
    print('🔐 [AuthBloc] Event type: ${event.runtimeType}');
    print('🔐 [AuthBloc] ===== EVENT RECEIVED END =====');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    print('🔐 [AuthBloc] ===== ERROR OCCURRED =====');
    print('🔐 [AuthBloc] Error: $error');
    print('🔐 [AuthBloc] Error Type: ${error.runtimeType}');
    print('🔐 [AuthBloc] Stack Trace: $stackTrace');
    print('🔐 [AuthBloc] ===== ERROR OCCURRED END =====');
  }
}
