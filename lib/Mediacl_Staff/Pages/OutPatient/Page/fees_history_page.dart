import 'package:flutter/material.dart';
import '../../../../Services/payment_service.dart';

class FeesHistoryPage extends StatefulWidget {
  const FeesHistoryPage({super.key});

  @override
  State<FeesHistoryPage> createState() => _FeesHistoryPageState();
}

class _FeesHistoryPageState extends State<FeesHistoryPage> {
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();

    // Load ONLY PAID Fees
    _historyFuture = PaymentService().getAllPendingFees().then(
      (list) => list.where((c) => c['status'] == 'PAID').toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fees History"),
        backgroundColor: const Color(0xFFBF955E),
      ),
      body: FutureBuilder(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data!;

          if (history.isEmpty) {
            return const Center(child: Text("No Paid Fees Available"));
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final patient = item['Patient'] ?? {};

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(patient['name'] ?? "-"),
                  subtitle: Text("Amount: ₹ ${item['amount']}"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
