import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class AudioCallScreen extends StatelessWidget {
  const AudioCallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Call'),
      ),
      body: const Center(
        child: Text('Audio Call Screen - Placeholder'),
      ),
    );
  }
}
