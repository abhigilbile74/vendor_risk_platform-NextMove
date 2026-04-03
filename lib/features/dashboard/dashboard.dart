import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/settings.dart';
import '../screens/DashboardPage.dart';
import '../../core/services/api_service.dart';

class NextMoveDashboard extends StatefulWidget {
  const NextMoveDashboard({super.key});

  @override
  State<NextMoveDashboard> createState() => _NextMoveDashboardState();
}

class _NextMoveDashboardState extends State<NextMoveDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// ✅ Default Page
  Widget selectedPage = const DashboardPage();

  Map<String, dynamic>? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  /// ✅ FIXED: Safe API handling
  Future<void> loadUser() async {
    try {
      final users = await ApiService().fetchUsers();

      if (users.isNotEmpty) {
        setState(() {
          user = users[0];
        });
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ✅ Handle Sidebar Click
  void onMenuSelected(Widget page) {
    setState(() {
      selectedPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,

      /// 📱 Mobile Drawer
      drawer: isDesktop
          ? null
          : Drawer(
              child: SidebarContent(
                onItemSelected: (page) {
                  Navigator.pop(context);
                  onMenuSelected(page);
                },
              ),
            ),

      body: Row(
        children: [
          /// 💻 Desktop Sidebar
          if (isDesktop)
            Container(
              width: 260,
              color: const Color(0xFF1E1E26),
              child: SidebarContent(onItemSelected: onMenuSelected),
            ),

          /// 📊 Main Content
          Expanded(
            child: Column(
              children: [
                /// 🔝 HEADER
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// ☰ Mobile Menu Button
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),

                      const Spacer(),

                      /// ✅ FIXED: Better loading + null handling
                      if (isLoading)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (user != null)
                        _buildUserHeader(context, user!)
                      else
                        const Text("No User"),
                    ],
                  ),
                ),

                /// 🧠 Dynamic Page Content
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: selectedPage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 👤 User Profile Header
Widget _buildUserHeader(BuildContext context, Map<String, dynamic> user) {
  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SettingsScreen()),
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              user['profilePic'] ?? 'https://via.placeholder.com/150',
            ),
          ),
          const SizedBox(width: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (user['fullName'] as String?) ?? "No Name",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                "View Profile",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(width: 6),
          const Icon(Icons.settings, size: 18),
        ],
      ),
    ),
  );
}