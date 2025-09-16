import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class TopDoctorsScreen extends StatelessWidget {
  const TopDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Doctors'),
      ),
      body: const Center(
        child: Text('Top Doctors Screen - Placeholder'),
      ),
    );
  }
}
