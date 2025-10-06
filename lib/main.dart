import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_budget/src/services/auth_service.dart';
import 'firebase_options.dart';
import 'src/blocs/auth/auth_bloc.dart';
import 'src/blocs/home/home_bloc.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase قبل أي شيء آخر
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(_authService),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(_firestoreService),
        ),
      ],
      child: MaterialApp(
        title: 'My Budget',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Tajawal',
        ),
        home: FutureBuilder(
          future: Future.delayed(const Duration(milliseconds: 100)),
          builder: (context, snapshot) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('جاري التحميل...'),
                        ],
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  return const HomeScreen();
                }
                
                return LoginScreen();
              },
            );
          },
        ),
      ),
    );
  }
}