import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep black background
      body: SafeArea(
        child: Column(
          children: [
            // 🔷 Top Bar with Glassmorphic Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.radar, color: Color(0xFF00DAF3), size: 28),
                      SizedBox(width: 10),
                      Text(
                        "NEXTMOVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _progressBar(0.3),
                      _progressBar(1.0), // Active Page
                      _progressBar(0.3),
                    ],
                  ),
                ],
              ),
            ),

            // 🔷 Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // 🔶 Animated Radar Visual
                    Container(
                      height: 280,
                      width: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00DAF3).withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildRadarRing(180),
                          _buildRadarRing(100),
                          const Icon(
                            Icons.analytics_outlined,
                            size: 100,
                            color: Color(0xFF00DAF3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // 🔶 Categorized Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00DAF3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00DAF3).withOpacity(0.3)),
                      ),
                      child: const Text(
                        "ADVANCED MONITORING",
                        style: TextStyle(
                          color: Color(0xFF00DAF3),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Deep-Dive Market Surveillance",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Go beyond basic charts with our specialized monitors. Track emerging themes, identify volatile catalysts, and discover trading ideas before the crowd.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔶 Service Feature Tags
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeatureChip(icon: Icons.bolt, label: "Catalysts"),
                        _FeatureChip(icon: Icons.pie_chart, label: "Sector Intelligence"),
                        _FeatureChip(icon: Icons.lightbulb, label: "Trading Ideas"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 🔷 Futuristic Bottom Navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text("SKIP", style: TextStyle(color: Colors.white38, letterSpacing: 1.5)),
                  ),
                  _nextButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildRadarRing(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
    );
  }

  static Widget _progressBar(double value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: value == 1 ? 40 : 12,
      height: 4,
      decoration: BoxDecoration(
        color: value == 1 ? const Color(0xFF00DAF3) : Colors.white12,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _nextButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF00DAF3),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00DAF3).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: const [
            Text("GET STARTED", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00DAF3), size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}