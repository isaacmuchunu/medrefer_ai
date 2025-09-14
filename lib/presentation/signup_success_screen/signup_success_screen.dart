import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class SignUpSuccessScreen extends StatelessWidget {
  const SignUpSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success'),
      ),
      body: const Center(
        child: Text('Sign Up Success Screen - Placeholder'),
      ),
    );
  }
}
