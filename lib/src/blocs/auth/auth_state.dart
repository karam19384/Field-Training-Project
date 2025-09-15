// lib/blocs/auth/auth_state.dart
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart'; // import the Firebase User

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthenticatedState extends AuthState {
  final User? user; // تم إضافة بيانات المستخدم
  const AuthenticatedState(this.user);
  @override
  List<Object> get props => [user ?? ''];
}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
  @override
  List<Object> get props => [message];
}