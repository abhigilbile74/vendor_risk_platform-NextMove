import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/themes.dart';
import 'core/theme/theme_cubit/themeCubit.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => ThemeCubit(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MyTheme.lightTheme,
          darkTheme: MyTheme.darkTheme,
          themeMode: themeMode,

          home: const LoginScreen(), // 🔥 START HERE
        );
      },
    );
  }
}