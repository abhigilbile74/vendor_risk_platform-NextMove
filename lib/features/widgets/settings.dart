import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_cubit/themeCubit.dart';
import '../../features/auth/screens/login_screen.dart';
import '../auth/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Converted to StatelessWidget since Cubit handles the state now
  @override
  Widget build(BuildContext context) {
    // Watch the current theme state from your Cubit
    final themeMode = context.watch<ThemeCubit>().state;
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), elevation: 0),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // --- PROFILE EDIT SECTION ---
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Edit Profile"),
            subtitle: const Text("Change name, email, and avatar"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to a Profile Edit Page
            },
          ),
          const Divider(indent: 20, endIndent: 20),

          // --- THEME TOGGLE SECTION ---
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: const Text("Appearance"),
            subtitle: Text(isDark ? "Dark Mode Enabled" : "Light Mode Enabled"),
            value: isDark,
            activeThumbColor: Theme.of(context).primaryColor,
            onChanged: (bool value) {
              // Call your Cubit's method to toggle the theme
              // Replace 'toggleTheme()' with your actual method name
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
          const Divider(indent: 20, endIndent: 20),

          // --- LOGOUT SECTION ---
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }
}
