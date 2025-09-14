import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class CreateNewPasswordScreen extends StatelessWidget {
  const CreateNewPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Password'),
      ),
      body: const Center(
        child: Text('Create New Password Screen - Placeholder'),
      ),
    );
  }
}
