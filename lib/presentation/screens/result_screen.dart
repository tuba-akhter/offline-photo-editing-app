import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Center(
        child: Column(
          children: [
             const Spacer(),
             const Text('Enhanced Image Here'),
             const Spacer(),
             ElevatedButton.icon(
               onPressed: () {
                 // TODO: Implement Save
               },
               icon: const Icon(Icons.save_alt),
               label: const Text('Save to Gallery'),
             ),
             const SizedBox(height: 10),
             TextButton.icon(
               onPressed: () {
                 context.go('/home');
               }, 
               icon: const Icon(Icons.home),
               label: const Text('Back to Home')
              ),
             const Spacer(),
          ],
        ),
      )
    );
  }
}
