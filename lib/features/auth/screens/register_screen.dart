import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final fullname = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? error;

  void register() async {
    // ✅ Validate form first
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    final res = await AuthService.signup(
      fullName: fullname.text.trim(),
      mobile: mobile.text.trim(),
      email: email.text.trim(),
      password: password.text,
    );

    setState(() => loading = false);

    if (res == null) {
      Navigator.pop(context);
    } else {
      setState(() => error = res);
    }
  }

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: isWeb ? 400 : double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),

            // ✅ FORM START
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Register to continue",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 25),

                  // 🔤 NAME
                  TextFormField(
                    controller: fullname,
                    decoration: inputStyle("Full Name"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Name is required";
                      }
                      if (value.trim().length < 3) {
                        return "Name must be required";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // 📱 MOBILE
                  TextFormField(
                    controller: mobile,
                    keyboardType: TextInputType.phone,
                    decoration: inputStyle("Mobile"),
                    validator: (value) {
                      value!.length < 10 ? "Min 10 Digit Number " : null;

                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return "Enter valid 10-digit mobile number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // 📧 EMAIL
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputStyle("Email"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Email is required";
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return "Enter valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // 🔐 PASSWORD
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: inputStyle("Password"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Password is required";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return "Include at least 1 uppercase letter";
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return "Include at least 1 number";
                      }
                      return null;
                    },
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : register,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Register"),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Already have an account? Login"),
                    ),
                  ),
                ],
              ),
            ),
            // ✅ FORM END
          ),
        ),
      ),
    );
  }
}
