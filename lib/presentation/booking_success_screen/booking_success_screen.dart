import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Successful'),
      ),
      body: const Center(
        child: Text('Booking Success Screen - Placeholder'),
      ),
    );
  }
}
