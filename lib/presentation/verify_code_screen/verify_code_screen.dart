import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class VerifyCodeScreen extends StatelessWidget {
  const VerifyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Code'),
      ),
      body: const Center(
        child: Text('Verify Code Screen - Placeholder'),
      ),
    );
  }
}
