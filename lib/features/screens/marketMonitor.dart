import 'package:flutter/material.dart';

class Marketmonitor extends StatelessWidget {
  const Marketmonitor({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 700;
          bool isTablet =
              constraints.maxWidth >= 700 && constraints.maxWidth < 1100;

          return Row(
            children: [
              /// ================= MAIN =================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// ================= INDEX CARDS =================
                      GridView.count(
                        crossAxisCount: isMobile ? 2 : 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _indexCard("NIFTY", "22,145", "+0.5%", true),
                          _indexCard("SENSEX", "73,210", "-0.1%", false),
                          _indexCard("BANK", "48,320", "+0.9%", true),
                          _indexCard("MIDCAP", "12,540", "+0.2%", true),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// ================= CONTENT =================
                      isMobile
                          ? Column(
                              children: [
                                _marketNews(),
                                const SizedBox(height: 16),
                                _brokersCard(),
                                const SizedBox(height: 16),
                                _sentimentCard(context),
                                const SizedBox(height: 16),
                                _traderCard(),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: _marketNews()),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 8,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _brokersCard()),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child:
                                                  _sentimentCard(context)),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _traderCard(),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 20),

                      /// ================= TABLE =================
                      _stockTable(),
                    ],
                  ),
                ),
              ),

              /// ================= SIDE PANEL (ONLY WEB/TABLET) =================
              if (!isMobile)
                Container(
                  width: isTablet ? 250 : 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade800),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🚨 Alerts"),
                      const SizedBox(height: 12),

                      _alertCard(),

                      const SizedBox(height: 20),

                      const Text("📊 Portfolio"),
                      const SizedBox(height: 10),

                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const LinearProgressIndicator(value: 0.75),
                          ),
                          const SizedBox(height: 6),
                          const Text("Profit +7.5%"),
                        ],
                      ),

                      const Spacer(),

                      OutlinedButton(
                        onPressed: () {},
                        child: const Text("Settings"),
                      )
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// ================= INDEX CARD =================
  Widget _indexCard(
      String name, String value, String change, bool isUp) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isUp
                ? [Colors.green.withOpacity(0.2), Colors.transparent]
                : [Colors.red.withOpacity(0.2), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 12)),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              change,
              style: TextStyle(color: isUp ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= NEWS =================
  Widget _marketNews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📰 Market News"),
        const SizedBox(height: 10),
        _newsCard("Economic Times",
            "RBI policy update may impact banking stocks.", Colors.blue),
        _newsCard("Moneycontrol",
            "Adani shares volatile amid market pressure.", Colors.red,
            alert: true),
      ],
    );
  }

  Widget _newsCard(String source, String text, Color color,
      {bool alert = false}) {
    return Card(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: alert
            ? BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 4)),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(text),
          ],
        ),
      ),
    );
  }

  /// ================= BROKERS =================
  Widget _brokersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text("Top Brokers"),
            SizedBox(height: 10),
            ListTile(title: Text("Zerodha")),
            ListTile(title: Text("Angel One")),
            ListTile(title: Text("Upstox")),
          ],
        ),
      ),
    );
  }

  /// ================= SENTIMENT =================
  Widget _sentimentCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Market Sentiment"),
            const SizedBox(height: 10),
            const Text("Bullish",
                style: TextStyle(fontSize: 20, color: Colors.green)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(value: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TRADER =================
  Widget _traderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text("Trader Activity"),
            SizedBox(height: 10),
            ListTile(title: Text("Retail Buying ↑")),
            ListTile(title: Text("FII Selling ↓")),
            ListTile(title: Text("DII Buying ↑")),
          ],
        ),
      ),
    );
  }

  /// ================= TABLE =================
  Widget _stockTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Company")),
            DataColumn(label: Text("Sector")),
            DataColumn(label: Text("Price")),
            DataColumn(label: Text("Change")),
          ],
          rows: const [
            DataRow(cells: [
              DataCell(Text("Reliance")),
              DataCell(Text("Energy")),
              DataCell(Text("₹2850")),
              DataCell(Text("+1.2%",
                  style: TextStyle(color: Colors.green))),
            ]),
            DataRow(cells: [
              DataCell(Text("TCS")),
              DataCell(Text("IT")),
              DataCell(Text("₹3650")),
              DataCell(Text("-0.8%",
                  style: TextStyle(color: Colors.red))),
            ]),
            DataRow(cells: [
              DataCell(Text("Infosys")),
              DataCell(Text("IT")),
              DataCell(Text("₹1520")),
              DataCell(Text("+0.5%",
                  style: TextStyle(color: Colors.green))),
            ]),
          ],
        ),
      ),
    );
  }

  /// ================= ALERT =================
  Widget _alertCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text("Adani Stocks Alert"),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Analyze"),
            )
          ],
        ),
      ),
    );
  }
}