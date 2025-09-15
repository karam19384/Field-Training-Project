// lib/src/blocs/auth/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_budget/src/services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authService.login(event.email, event.password);
        final user = _authService.getCurrentUser();
        emit(AuthenticatedState(user));
      } on FirebaseAuthException catch (e) {
        emit(AuthErrorState(e.code));
      }
    });

    on<RegisterEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authService.register(event.email, event.password, event.name);
        final user = _authService.getCurrentUser();
        emit(AuthenticatedState(user));
      } on FirebaseAuthException catch (e) {
        emit(AuthErrorState(e.code));
      }
    });

    on<SignOutEvent>((event, emit) async {
      await _authService.signOut();
      emit(AuthInitial());
    });
  }
}