// lib/src/blocs/home/home_state.dart
part of 'home_bloc.dart';

// جميع الحالات (States) يجب أن ترث من Equatable
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

// 1. الحالة الأولية
class HomeInitial extends HomeState {
  const HomeInitial();
}

// 2. حالة التحميل
class HomeLoading extends HomeState {
  const HomeLoading();
}

// 3. حالة تحميل البيانات بنجاح
class HomeLoaded extends HomeState {
  final BudgetSummary budgetSummary;
  final List<Expense> expenses;

  const HomeLoaded({required this.budgetSummary, required this.expenses});

  // إضافة props للمقارنة
  @override
  List<Object> get props => [budgetSummary, expenses];

  // دالة نسخ (CopyWith) مفيدة لتحديث حالة معينة دون غيرها
  HomeLoaded copyWith({
    BudgetSummary? budgetSummary,
    List<Expense>? expenses,
  }) {
    return HomeLoaded(
      budgetSummary: budgetSummary ?? this.budgetSummary,
      expenses: expenses ?? this.expenses,
    );
  }
}

// 4. حالة وجود خطأ
class HomeError extends HomeState {
  final String message;
  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}