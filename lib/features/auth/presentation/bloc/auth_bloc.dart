import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/auth_models.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../vocabulary_notebook/data/local/local_vocabulary_store.dart';
import '../../../vocabulary_notebook/data/repositories/vocabulary_repository_impl.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/realtime/signalr_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

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

class GoogleLoginRequested extends AuthEvent {
  final String idToken;

  const GoogleLoginRequested({required this.idToken});

  @override
  List<Object?> get props => [idToken];
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
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  // Getter to access the auth service
  AuthServiceProtocol get authService => _authService;

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    // Eğer zaten AuthUnauthenticated durumundaysa tekrar kontrol etme
    if (state is AuthUnauthenticated) {
      Logger.auth('Already unauthenticated, skipping check');
      return;
    }

    // Eğer zaten AuthAuthenticated durumundaysa ve cache'den geliyorsa tekrar kontrol etme
    // (Sonsuz döngüyü önlemek için)
    if (state is AuthAuthenticated) {
      Logger.auth('Already authenticated, skipping check to prevent infinite loops');
      return;
    }

    emit(AuthChecking());

    try {
      final user = await _authService.fetchUserProfile(forceRefresh: false);
      emit(AuthAuthenticated(user));
    } catch (e) {
      Logger.warning('Auth check failed: $e');

      // Offline mode - try to get cached profile
      try {
        final cacheManager = getIt<CacheManager>();
        final cachedProfile = await cacheManager.getData('user/profile');
        if (cachedProfile != null) {
          Logger.auth('Found cached profile, using offline mode');
          // Parse cached profile and emit AuthAuthenticated
          // For now, emit unauthenticated to use guest mode
        }
      } catch (cacheError) {
        Logger.warning('No cached profile available: $cacheError');
      }

      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logger.auth('Login requested for: ${event.userNameOrEmail}');

    emit(AuthLoading());

    try {
      // AuthService.login() zaten fetchUserProfile(forceRefresh: true) çağırıyor
      final user = await _authService.login(
        event.userNameOrEmail,
        event.password,
        event.rememberMe,
      );
      Logger.auth('Login successful: ${user.userName}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is AuthError) {
        errorMessage = e.localizedDescription;
      }
      Logger.error('Login error: $errorMessage', e);
      emit(AuthErrorState(errorMessage));
    }
  }

  Future<void> _onGoogleLoginRequested(
    GoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logger.auth('Google login requested');

    emit(AuthLoading());

    try {
      // AuthService.googleLogin() zaten fetchUserProfile(forceRefresh: true) çağırıyor
      final user = await _authService.googleLogin(idToken: event.idToken);
      Logger.auth('Google login successful: ${user.userName}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      String errorMessage = 'Google login failed';
      if (e is AuthError) {
        errorMessage = e.localizedDescription;
      }
      Logger.error('Google login error: $errorMessage', e);
      emit(AuthErrorState(errorMessage));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logger.auth('Register requested for: ${event.email}');

    emit(AuthLoading());

    try {
      final user = await _authService.register(
        event.email,
        event.userName,
        event.password,
        event.confirmPassword,
      );
      Logger.auth('Registration successful: ${user.userName}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e is AuthError) {
        errorMessage = e.localizedDescription;
      } else if (e is Exception) {
        final msg = e.toString();
        final idx = msg.indexOf(':');
        errorMessage = idx != -1 ? msg.substring(idx + 1).trim() : msg;
      }
      Logger.error('Registration error: $errorMessage', e);
      emit(AuthErrorState(errorMessage));
    }
  }

  /// Logout işlemi - doğru sıralama ile temizlik yapar
  /// 
  /// Sıralama:
  /// 1. SignalR bağlantısını kapat (realtime event'leri durdur)
  /// 2. API'ye logout request gönder
  /// 3. Token'ları temizle (SecureStorage)
  /// 4. Cache'leri temizle (CacheManager)
  /// 5. Hive box'ları temizle (user data)
  /// 6. In-memory store'ları temizle
  /// 7. State'i AuthUnauthenticated yap
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    Logger.auth('Logout requested - starting cleanup sequence');

    emit(AuthLoading());

    try {
      // 1. SignalR bağlantısını kapat (realtime event'leri durdur)
      Logger.auth('Step 1: Stopping SignalR connection...');
      try {
        final signalRService = getIt<SignalRService>();
        await signalRService.stop();
        Logger.auth('SignalR connection stopped');
      } catch (e) {
        Logger.warning('Error stopping SignalR: $e');
      }

      // 2. API'ye logout request gönder ve token'ları temizle
      // AuthService.logout() hem API'ye request gönderir hem de token'ları temizler
      Logger.auth('Step 2: Calling logout API and clearing tokens...');
      try {
        await _authService.logout();
        Logger.auth('Logout API call and token cleanup successful');
      } catch (e) {
        Logger.warning('Logout API call failed, continuing with local cleanup: $e');
        // API başarısız olsa bile token'ları temizle
        try {
          final secureStorage = getIt<SecureStorageService>();
          await secureStorage.clearTokens();
          Logger.auth('Tokens cleared locally');
        } catch (tokenError) {
          Logger.warning('Error clearing tokens: $tokenError');
        }
      }

      // 3. Cache'leri temizle (AuthService.logout() zaten temizliyor ama tekrar kontrol)
      Logger.auth('Step 3: Clearing all caches...');
      try {
        final cacheManager = getIt<CacheManager>();
        await cacheManager.clearAll();
        Logger.auth('All caches cleared');
      } catch (e) {
        Logger.warning('Error clearing caches: $e');
      }

      // 4. Hive box'ları temizle (user data)
      Logger.auth('Step 4: Clearing Hive boxes...');
      try {
        await _clearAllHiveBoxes();
        Logger.auth('All Hive boxes cleared');
      } catch (e) {
        Logger.warning('Error clearing Hive boxes: $e');
      }

      // 5. State'i AuthUnauthenticated yap
      Logger.auth('Step 5: Emitting AuthUnauthenticated state...');
      emit(AuthUnauthenticated());
      Logger.auth('Logout completed successfully');
    } catch (e) {
      Logger.error('Logout error: $e', e);
      emit(AuthErrorState('Logout failed'));
    }
  }

  Future<void> _clearAllHiveBoxes() async {
    try {
      // Clear user_words box (clear but don't close - box needs to stay open for app)
      if (Hive.isBoxOpen('user_words')) {
        try {
          final userWordsBox = Hive.box('user_words');
          await userWordsBox.clear();
          Logger.auth('user_words box cleared');
        } catch (e) {
          Logger.warning('Error clearing user_words box: $e');
          // If box is corrupted, try to close and reopen
          try {
            await Hive.box('user_words').close();
            Logger.auth('user_words box closed due to error');
          } catch (_) {}
        }
      }
      
      // Clear user_preferences box
      if (Hive.isBoxOpen('user_preferences')) {
        try {
          final userPrefsBox = Hive.box('user_preferences');
          await userPrefsBox.clear();
          Logger.auth('user_preferences box cleared');
        } catch (e) {
          Logger.warning('Error clearing user_preferences box: $e');
        }
      }
      
      // Clear favorites box
      if (Hive.isBoxOpen('favorites')) {
        try {
          final favoritesBox = Hive.box('favorites');
          await favoritesBox.clear();
          Logger.auth('favorites box cleared');
        } catch (e) {
          Logger.warning('Error clearing favorites box: $e');
        }
      }
      
      // Clear app_cache box (already cleared by CacheManager, but clear again to be sure)
      if (Hive.isBoxOpen('app_cache')) {
        try {
          final appCacheBox = Hive.box('app_cache');
          await appCacheBox.clear();
          Logger.auth('app_cache box cleared');
        } catch (e) {
          Logger.warning('Error clearing app_cache box: $e');
        }
      }
      
      // Clear LocalVocabularyStore (in-memory store)
      try {
        final localStore = LocalVocabularyStore();
        localStore.clearAll();
        Logger.auth('LocalVocabularyStore cleared');
      } catch (e) {
        Logger.warning('Error clearing LocalVocabularyStore: $e');
      }
      
      // Clear VocabularyRepository cache and state
      try {
        final vocabularyRepo = getIt<VocabularyRepositoryImpl>();
        vocabularyRepo.clearCache();
        Logger.auth('VocabularyRepository cache cleared');
      } catch (e) {
        Logger.warning('Error clearing VocabularyRepository cache: $e');
      }
    } catch (e) {
      Logger.warning('Error clearing Hive boxes: $e');
      // Don't rethrow - continue with logout even if cleanup fails
    }
  }

  @override
  void onChange(Change<AuthState> change) {
    super.onChange(change);
    Logger.auth('State changed: ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}');
  }

  @override
  void onEvent(AuthEvent event) {
    super.onEvent(event);
    Logger.auth('Event received: ${event.runtimeType}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    Logger.error('AuthBloc error: $error', error, stackTrace);
  }
}
