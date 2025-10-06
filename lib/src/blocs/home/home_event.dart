// lib/src/blocs/home/home_event.dart

part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class GetHomeDataEvent extends HomeEvent {
  const GetHomeDataEvent();
}

class RefreshHomeDataEvent extends HomeEvent {
  const RefreshHomeDataEvent();
}

class AddNewExpenseEvent extends HomeEvent {
  final String title;
  final double amount;
  final String type;
  final String currency;
  final String category;
  final String? notes;
  final String? person;

  const AddNewExpenseEvent({
    required this.title,
    required this.amount,
    required this.type,
    this.currency = '\$',
    this.category = 'عام',
    this.notes,
    this.person,
  });
  
  @override
  List<Object> get props => [title, amount, type, currency, category];
}

// ✅ أحداث جديدة للتعديل والحذف
class UpdateExpenseEvent extends HomeEvent {
  final String expenseId;
  final String title;
  final double amount;
  final String type;
  final String currency;
  final String category;
  final String? notes;
  final String? person;

  const UpdateExpenseEvent({
    required this.expenseId,
    required this.title,
    required this.amount,
    required this.type,
    this.currency = '\$',
    this.category = 'عام',
    this.notes,
    this.person,
  });
  
  @override
  List<Object> get props => [expenseId, title, amount, type, currency, category];
}

class DeleteExpenseEvent extends HomeEvent {
  final String expenseId;

  const DeleteExpenseEvent({required this.expenseId});
  
  @override
  List<Object> get props => [expenseId];
}