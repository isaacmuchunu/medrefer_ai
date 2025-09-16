import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
      ),
      body: const Center(
        child: Text('Articles Screen - Placeholder'),
      ),
    );
  }
}
