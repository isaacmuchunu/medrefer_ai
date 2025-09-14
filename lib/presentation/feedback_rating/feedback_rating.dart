import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';

class FeedbackRating extends StatefulWidget {
  final String specialistId; // Pass specialist ID
  const FeedbackRating({Key? key, required this.specialistId}) : super(key: key);

  @override
  State<FeedbackRating> createState() => _FeedbackRatingState();
}

class _FeedbackRatingState extends State<FeedbackRating> {
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  void _submitFeedback() {
    final dataService = Provider.of<DataService>(context, listen: false);
    // Assume FeedbackDAO exists
    dataService.feedbackDAO?.submitFeedback(widget.specialistId, _rating, _feedbackController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback and Rating'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate the specialist:', style: TextStyle(fontSize: 18)),
            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 5,
              label: _rating.toString(),
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}