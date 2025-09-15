// lib/src/blocs/home/home_event.dart
import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

// حدث لجلب جميع البيانات اللازمة للواجهة الرئيسية (الميزانية والمصاريف)
class GetHomeDataEvent extends HomeEvent {}