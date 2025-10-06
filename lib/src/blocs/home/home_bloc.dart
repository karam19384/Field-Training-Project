// lib/src/blocs/home/home_bloc.dart

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/expense.dart';
import '../../models/budget_summary.dart';
import '../../services/firestore_service.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirestoreService _firestoreService;
  
  StreamSubscription<List<Expense>>? _expensesSubscription;
  StreamSubscription<BudgetSummary>? _summarySubscription;
  
  List<Expense> _latestExpenses = [];
  BudgetSummary _latestSummary = BudgetSummary(
    totalIncome: 0, 
    totalExpenses: 0, 
    totalDebtToMe: 0, 
    totalDebtFromMe: 0, 
    netBalance: 0
  );
  bool _hasInitialData = false;

  HomeBloc(this._firestoreService) : super(const HomeInitial()) {
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<AddNewExpenseEvent>(_onAddNewExpense);

    // تسجيل معالج لحدث جلب البيانات الرئيسي
    on<GetHomeDataEvent>((event, emit) async {
      await _cancelSubscriptions();
      emit(const HomeLoading());
      _hasInitialData = false;
      
      try {
        _setupStreamSubscriptions();
      } catch (e) {
        emit(HomeError(message: 'خطأ في بدء جلب البيانات: $e'));
      }
    });
    
    // تسجيل معالج للتحديث اليدوي
    on<RefreshHomeDataEvent>((event, emit) {
      emit(const HomeLoading());
      _hasInitialData = false;
      _setupStreamSubscriptions();
    });

    // ✅ تسجيل المعالجين للأحداث الداخلية
    on<_InternalUpdateEvent>((event, emit) {
      if (!isClosed) {
        emit(HomeLoaded(
          budgetSummary: event.summary,
          expenses: event.expenses,
        ));
      }
    });

    on<_InternalErrorEvent>((event, emit) {
      if (!isClosed) {
        emit(HomeError(message: event.message));
      }
    });
  }

  // دالة لإعداد الاشتراكات في الـ Streams
  void _setupStreamSubscriptions() {
    _expensesSubscription = _firestoreService.getExpenses().map((list) {
      return list.map((json) => Expense.fromJson(json)).toList();
    }).listen(
      (expenses) {
        _latestExpenses = expenses;
        _checkAndEmitLoadedState();
      },
      onError: (error) {
        add(_InternalErrorEvent(message: 'خطأ في جلب المصاريف: $error'));
      }
    );

    _summarySubscription = _firestoreService.getBudgetSummary().map((data) {
      return BudgetSummary.fromJson(data);
    }).listen(
      (summary) {
        _latestSummary = summary;
        _checkAndEmitLoadedState();
      },
      onError: (error) {
        add(_InternalErrorEvent(message: 'خطأ في جلب الملخص: $error'));
      }
    );
  }

  // دالة للتحقق وإطلاق الحالة عند اكتمال البيانات
  void _checkAndEmitLoadedState() {
    if (!_hasInitialData) {
      _hasInitialData = true;
      add(_InternalUpdateEvent(
        expenses: _latestExpenses,
        summary: _latestSummary,
      ));
    } else {
      // تحديث البيانات بشكل مستمر بعد التحميل الأولي
      add(_InternalUpdateEvent(
        expenses: _latestExpenses,
        summary: _latestSummary,
      ));
    }
  }

    void _onAddNewExpense(AddNewExpenseEvent event, Emitter<HomeState> emit) async {
    try {
      await _firestoreService.addExpense(
        title: event.title, 
        amount: event.amount, 
        type: event.type,
        currency: event.currency,
        category: event.category,
        notes: event.notes,
        person: event.person,
      );
      // لا حاجة لإطلاق أي حدث، الـ Stream سيتحدث تلقائياً
    } catch (e) {
      if (!isClosed) {
        emit(HomeError(message: 'خطأ في إضافة المعاملة: ${e.toString()}'));
      }
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _expensesSubscription?.cancel();
    await _summarySubscription?.cancel();
    _expensesSubscription = null;
    _summarySubscription = null;
    _hasInitialData = false;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
// في ملف home_bloc.dart، أضف معالجين للأحداث الجديدة:

// ثم أضف الدوال المعالجة:
void _onUpdateExpense(UpdateExpenseEvent event, Emitter<HomeState> emit) async {
  try {
    await _firestoreService.updateExpense(
      expenseId: event.expenseId,
      title: event.title,
      amount: event.amount,
      type: event.type,
      currency: event.currency,
      category: event.category,
      notes: event.notes,
      person: event.person,
    );
    // لا حاجة لإطلاق حالة جديدة، لأن الـ Stream سيتحدث تلقائياً
  } catch (e) {
    if (!isClosed) {
      emit(HomeError(message: 'خطأ في تعديل المعاملة: ${e.toString()}'));
    }
  }
}

void _onDeleteExpense(DeleteExpenseEvent event, Emitter<HomeState> emit) async {
  try {
    await _firestoreService.deleteExpense(event.expenseId);
    // لا حاجة لإطلاق حالة جديدة، لأن الـ Stream سيتحدث تلقائياً
  } catch (e) {
    if (!isClosed) {
      emit(HomeError(message: 'خطأ في حذف المعاملة: ${e.toString()}'));
    }
  }
}

}

// أحداث داخلية للاستخدام داخل الـ Bloc فقط
class _InternalUpdateEvent extends HomeEvent {
  final List<Expense> expenses;
  final BudgetSummary summary;

  const _InternalUpdateEvent({
    required this.expenses,
    required this.summary,
  });

  @override
  List<Object> get props => [expenses, summary];
}

class _InternalErrorEvent extends HomeEvent {
  final String message;

  const _InternalErrorEvent({required this.message});

  @override
  List<Object> get props => [message];
}
