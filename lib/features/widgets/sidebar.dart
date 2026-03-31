
import 'package:flutter/material.dart';
import '../dashboard/dashboard.dart';
import '../screens/marketMonitor.dart';
import '../screens/themesMoitor.dart';

class SidebarContent extends StatelessWidget {
  final Function(Widget) onItemSelected;

  const SidebarContent({
    super.key,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.primaryColorDark, // Sidebar background
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildLogo(theme),
          const SizedBox(height: 20),

          /// MONITORS
          _buildSection(
            title: "MONITORS",
            items: [
              _MenuItem(
                icon: Icons.dashboard,
                title: "Dashboard",
                page: NextMoveDashboard(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.analytics,
                title: "Market Monitor",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.palette,
                title: "Themes Monitor",
                page: Themesmoitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.pie_chart,
                title: "Sector Monitor",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.bolt,
                title: "Catalyst Monitor",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.visibility,
                title: "Watchlist Monitor",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.lightbulb,
                title: "Trading Ideas",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
            ],
          ),

          const Divider(color: Colors.white24),

          /// SERVICES
          _buildSection(
            title: "SERVICES",
            items: [
              _MenuItem(
                icon: Icons.health_and_safety,
                title: "Financial Health",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.gavel,
                title: "Regulatory Compliance",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.balance,
                title: "Legal Proceedings",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.campaign,
                title: "Negative News",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
              _MenuItem(
                icon: Icons.settings_input_component,
                title: "Operational Stability",
                page: Marketmonitor(),
                onTap: onItemSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const FlutterLogo(size: 32),
          const SizedBox(width: 12),
          Text(
            "NextMove",
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        ...items,
      ],
    );
  }
}

/// 🔥 FIXED MENU ITEM
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget page;
  final Function(Widget) onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.page,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        onTap(page); 
      },
    );
  }
}