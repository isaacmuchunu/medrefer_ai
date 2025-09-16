import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  List<FAQItem> _faqs = [];
  List<FAQItem> _filteredFaqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFAQs();
  }

  void _loadFAQs() {
    // Mock FAQ data
    _faqs = [
      FAQItem(
        question: 'How do I create a new referral?',
        answer: 'To create a new referral, tap the "Create Referral" button on the dashboard, select a patient, choose a specialist, and fill in the required medical information.',
        category: 'Referrals',
      ),
      FAQItem(
        question: 'How can I track the status of my referrals?',
        answer: 'You can track referral status in the "Referrals" tab. Each referral shows its current status with color-coded indicators and timeline updates.',
        category: 'Referrals',
      ),
      FAQItem(
        question: 'How do I send secure messages to specialists?',
        answer: 'Use the messaging feature by tapping the message icon next to any specialist or referral. All messages are encrypted and HIPAA compliant.',
        category: 'Communication',
      ),
      FAQItem(
        question: 'Can I schedule video calls with specialists?',
        answer: 'Yes, you can schedule and join video calls directly from the app. Look for the video call icon in specialist profiles or referral details.',
        category: 'Communication',
      ),
      FAQItem(
        question: 'How do I add a new patient to the system?',
        answer: 'Tap the "Add Patient" button in the patient search screen, then fill in the required information including personal details, contact info, and medical history.',
        category: 'Patients',
      ),
      FAQItem(
        question: 'Is my patient data secure?',
        answer: 'Yes, all data is encrypted and stored securely. The app is HIPAA compliant and follows strict security protocols to protect patient information.',
        category: 'Security',
      ),
      FAQItem(
        question: 'What should I do if the app is not working properly?',
        answer: 'Try restarting the app first. If issues persist, check your internet connection, update the app, or contact support for assistance.',
        category: 'Technical',
      ),
      FAQItem(
        question: 'How do I update my profile information?',
        answer: 'Go to Settings > Profile to update your personal information, contact details, and professional credentials.',
        category: 'Account',
      ),
    ];

    setState(() {
      _filteredFaqs = _faqs;
      _isLoading = false;
    });
  }

  void _filterFAQs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _faqs;
      } else {
        _filteredFaqs = _faqs.where((faq) =>
          faq.question.toLowerCase().contains(query.toLowerCase()) ||
          faq.answer.toLowerCase().contains(query.toLowerCase()) ||
          faq.category.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          isScrollable: true,
          tabs: [
            Tab(text: 'FAQ'),
            Tab(text: 'Tutorials'),
            Tab(text: 'Contact'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(theme),
          _buildTutorialsTab(theme),
          _buildContactTab(theme),
          _buildFeedbackTab(theme),
        ],
      ),
    );
  }

  Widget _buildFAQTab(ThemeData theme) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search FAQs...',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: _filterFAQs,
          ),
        ),

        // FAQ List
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                )
              : _filteredFaqs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No FAQs found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFaqs.length,
                      itemBuilder: (context, index) {
                        final faq = _filteredFaqs[index];
                        return _buildFAQItem(faq, theme);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(FAQItem faq, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            faq.category,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialsTab(ThemeData theme) {
    final tutorials = [
      TutorialItem(
        title: 'Getting Started with MedRefer AI',
        description: 'Learn the basics of navigating the app',
        duration: '5 min',
        thumbnail: 'assets/images/tutorial1.png',
      ),
      TutorialItem(
        title: 'Creating Your First Referral',
        description: 'Step-by-step guide to creating referrals',
        duration: '8 min',
        thumbnail: 'assets/images/tutorial2.png',
      ),
      TutorialItem(
        title: 'Using Secure Messaging',
        description: 'Communicate securely with specialists',
        duration: '6 min',
        thumbnail: 'assets/images/tutorial3.png',
      ),
      TutorialItem(
        title: 'Video Conferencing Features',
        description: 'Host and join video calls with specialists',
        duration: '10 min',
        thumbnail: 'assets/images/tutorial4.png',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return _buildTutorialItem(tutorial, theme);
      },
    );
  }
  Widget _buildTutorialItem(TutorialItem tutorial, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.play_circle_outline,
            color: theme.colorScheme.primary,
            size: 32,
          ),
        ),
        title: Text(
          tutorial.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              tutorial.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tutorial.duration,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          size: 16,
        ),
        onTap: () => _playTutorial(tutorial),
      ),
    );
  }

  Widget _buildContactTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get in Touch',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Live Chat
          _buildContactOption(
            theme,
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            status: 'Available now',
            statusColor: Colors.green,
            onTap: _startLiveChat,
          ),

          // Email Support
          _buildContactOption(
            theme,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'Send us an email',
            status: 'Response within 24 hours',
            statusColor: Colors.blue,
            onTap: _sendEmail,
          ),

          // Phone Support
          _buildContactOption(
            theme,
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            subtitle: 'Call our support line',
            status: 'Mon-Fri 9AM-6PM EST',
            statusColor: Colors.orange,
            onTap: _callSupport,
          ),

          // Submit Ticket
          _buildContactOption(
            theme,
            icon: Icons.confirmation_number_outlined,
            title: 'Submit Ticket',
            subtitle: 'Create a support ticket',
            status: 'Track your request',
            statusColor: Colors.purple,
            onTap: _submitTicket,
          ),

          const SizedBox(height: 24),

          // App Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Version', '1.0.0'),
                _buildInfoRow('Build', '2024.01.15'),
                _buildInfoRow('Platform', 'Flutter'),
                _buildInfoRow('Support ID', 'MRA-${DateTime.now().millisecondsSinceEpoch}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildContactOption(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We Value Your Feedback',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve MedRefer AI by sharing your thoughts and suggestions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Feedback Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Feedback',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _feedbackController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Tell us about your experience, report bugs, or suggest new features...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(Icons.send),
                    label: Text('Submit Feedback'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Action methods
  void _playTutorial(TutorialItem tutorial) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing tutorial: ${tutorial.title}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting live chat...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening email client...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling support: +1-800-MEDREFER'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _submitTicket() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ticket submission form...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _submitFeedback() {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your feedback'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: Colors.green,
      ),
    );

    _feedbackController.clear();
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening app store for rating...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening bug report form...'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _suggestFeature() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening feature suggestion form...'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening share dialog...'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

// Data models
class FAQItem {
  final String question;
  final String answer;
  final String category;

  FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class TutorialItem {
  final String title;
  final String description;
  final String duration;
  final String thumbnail;

  TutorialItem({
    required this.title,
    required this.description,
    required this.duration,
    required this.thumbnail,
  });
}
