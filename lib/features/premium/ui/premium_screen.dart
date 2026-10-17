import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  final bool? isGoToMain;

  const PremiumScreen({super.key, this.isGoToMain});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: const Center(child: Text('Premium features are coming soon.')),
    );
  }
}
