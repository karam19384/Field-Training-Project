// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'src/blocs/auth/auth_bloc.dart';
import 'src/blocs/home/home_bloc.dart'; // استيراد HomeBloc
import 'src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/services/auth_service.dart';
import 'src/services/firestore_service.dart'; // استيراد FirestoreService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService(); // تهيئة الخدمة

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(_authService),
        ),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              // الحل: نقوم بإنشاء HomeBloc هنا
              // لجعله متاحًا لـ HomeScreen
              return BlocProvider<HomeBloc>(
                create: (context) => HomeBloc(_firestoreService),
                child: const HomeScreen(),
              );
            }
            return LoginScreen();
          },
        ),
      ),
    );
  }
}