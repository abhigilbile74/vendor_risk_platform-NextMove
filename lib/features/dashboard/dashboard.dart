import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/settings.dart';

class NextMoveDashboard extends StatefulWidget {
  const NextMoveDashboard({super.key});

  @override
  State<NextMoveDashboard> createState() => _NextMoveDashboardState();
}

class _NextMoveDashboardState extends State<NextMoveDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isDrawerOpen = false;

  /// ✅ Default Page
  Widget selectedPage = const Center(child: Text("Dashboard"));

  void toggleDrawer() {
    if (isDrawerOpen) {
      Navigator.of(context).pop();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }

    setState(() {
      isDrawerOpen = !isDrawerOpen;
    });
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
                  Navigator.pop(context); // close only on mobile
                  onMenuSelected(page);
                },
              ),
            ),

      body: Row(
        children: [
          /// 💻 Desktop Sidebar (Always Visible)
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
                  height: 70,
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

                      _buildUserHeader(context),
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
Widget _buildUserHeader(BuildContext context) {
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
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Alex Rivera",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                "View Profile",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
