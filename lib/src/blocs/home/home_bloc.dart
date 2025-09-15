// lib/src/blocs/home/home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:my_budget/src/services/firestore_service.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirestoreService _firestoreService;

  HomeBloc(this._firestoreService) : super(HomeInitial()) {
    on<GetHomeDataEvent>((event, emit) async {
      emit(HomeLoading());
      try {
        // نستخدم Stream لتلقي تحديثات لحظية
        final budgetStream = _firestoreService.getBudgetSummary();
        final expensesStream = _firestoreService.getExpenses();

        // نجمع البيانات من كلا الـ Streams
        await emit.forEach(
          Rx.combineLatest2(budgetStream, expensesStream, (
            Map<String, double> budget,
            List<Map<String, dynamic>> expenses,
          ) {
            return HomeLoaded(
              budgetSummary: budget,
              expenses: expenses,
            );
          }),
          onData: (HomeLoaded data) => data,
          onError: (error, stackTrace) => HomeError(error.toString()),
        );
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}