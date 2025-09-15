// lib/ui/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget/src/blocs/auth/auth_bloc.dart';
import 'package:my_budget/src/blocs/auth/auth_event.dart';
import 'package:my_budget/src/blocs/auth/auth_state.dart';
import 'package:my_budget/src/screens/home_screen.dart';

import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});


  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('المصادقة')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          } else if (state is AuthErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: ${state.message}')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return CircularProgressIndicator();
                  }
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                                LoginEvent(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                ),
                              );
                        },
                        child: Text('تسجيل الدخول'),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                         Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SignupScreen()),
                          );
                        },
                        child: Text('ليس لديك حساب؟ قم بإنشاء حساب'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}