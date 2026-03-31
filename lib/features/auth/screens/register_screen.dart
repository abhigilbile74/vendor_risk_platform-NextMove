import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? error;

  void register() async {
    setState(() {
      loading = true;
      error = null;
    });

    final res = await AuthService.signup(
      fullName: name.text,
      mobile: mobile.text,
      email: email.text,
      password: password.text,
    );

    setState(() => loading = false);

    if (res == null) {
      Navigator.pop(context);
    } else {
      setState(() => error = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: mobile, decoration: InputDecoration(labelText: "Mobile")),
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: "Password")),

            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: register, child: const Text("Register")),
          ],
        ),
      ),
    );
  }
}