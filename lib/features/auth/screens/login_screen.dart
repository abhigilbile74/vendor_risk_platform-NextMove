import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:vendor_risk_platform/features/dashboard/dashboard.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final url = "http://127.0.0.1:5000/api/users";
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? error;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    final res = await AuthService.login(
      email: email.text.trim(),
      password: password.text.trim(),
    );

    setState(() => loading = false);

    if (res == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NextMoveDashboard()),
      );
    } else {
      setState(() => error = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

   return Scaffold(
  backgroundColor: Colors.grey[100],
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width > 600
                    ? 400
                    : double.infinity,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 🔥 important
                    children: [
                      Image.asset(
                        'assets/images/Login_image.png',
                        height: 180,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Welcome Back 👋",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: email,
                        decoration: _inputDecoration(
                          label: "Email",
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Enter email" : null,
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: password,
                        obscureText: true,
                        decoration: _inputDecoration(
                          label: "Password",
                          icon: Icons.lock_outline,
                        ),
                        validator: (value) =>
                            value!.length < 6 ? "Min 6 characters" : null,
                      ),

                      const SizedBox(height: 20),

                      if (error != null)
                        Text(error!,
                            style: const TextStyle(color: Colors.red)),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Login"),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              children: [

                                const Text("New here? "),

                                TextButton(
                                  onPressed: () {

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterScreen(),
                                      ),
                                    );
                                  },

                                  child: const Text("Create Account"),
                                ),
                              ],
                            ),

                      const SizedBox(height: 40), // 🔥 prevents bottom cut
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  ),
);
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}