import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import '../../../home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? error;

  void login() async {
    setState(() {
      loading = true;
      error = null;
    });

    final res = await AuthService.login(
      email: email.text,
      password: password.text,
    );

    setState(() => loading = false);

    if (res == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } else {
      setState(() => error = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Login", style: Theme.of(context).textTheme.headlineSmall),

              TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: "Password")),

              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 20),

              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: login, child: const Text("Login")),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text("Create Account"),
              )
            ],
          ),
        ),
      ),
    );
  }
}