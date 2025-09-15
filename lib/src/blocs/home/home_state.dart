// lib/src/blocs/home/home_state.dart
import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

// حالة عندما يتم تحميل البيانات بنجاح
class HomeLoaded extends HomeState {
  final Map<String, double> budgetSummary;
  final List<Map<String, dynamic>> expenses;

  const HomeLoaded({
    required this.budgetSummary,
    required this.expenses,
  });

  @override
  List<Object> get props => [budgetSummary, expenses];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}