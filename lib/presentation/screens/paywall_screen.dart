import 'package:flutter/material.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.star, size: 80, color: Colors.amber),
            const Text(
              'Unlock Full Power',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildPlanCard('Monthly', '\$4.99 / month'),
            _buildPlanCard('Yearly', '\$39.99 / year'),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('Restore Purchases')),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String price) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(price),
        trailing: ElevatedButton(onPressed: () {}, child: const Text('Buy')),
      ),
    );
  }
}
