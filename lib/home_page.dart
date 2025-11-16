import 'package:flutter/material.dart';
import 'package:jura/transactions_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to Second Page'),
          onPressed: () {
            // Push the new route onto the navigation stack
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionsPage()),
            );
          },
        ),
      ),
    );
  }
}