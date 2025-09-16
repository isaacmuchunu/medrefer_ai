import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: const Center(
        child: Text('Booking Screen - Placeholder'),
      ),
    );
  }
}
