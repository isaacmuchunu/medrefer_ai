import 'package:intl/intl.dart';
import '../../core/app_export.dart';
import '../../database/dao/payment_dao.dart';

class BillingPayment extends StatefulWidget {
  const BillingPayment({super.key});

  @override
  State<BillingPayment> createState() => _BillingPaymentState();
}

class _BillingPaymentState extends State<BillingPayment> {
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      final paymentDAO = PaymentDao();
      _paymentHistory = await paymentDAO.getPaymentHistory(user.id);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Payments'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentHistory,
              child: _paymentHistory.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildPaymentList(theme),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to a screen to make a new payment
        },
        label: const Text('New Payment'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = _paymentHistory[index];
        return _buildPaymentCard(theme, payment);
      },
    );
  }

  Widget _buildPaymentCard(ThemeData theme, Map<String, dynamic> payment) {
    final statusColor = _getStatusColor(payment['status'], theme);
    final paymentDate = DateTime.parse(payment['date']);
    final formattedAmount = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(payment['amount']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedAmount,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment['status'].toString().capitalize(),
                    style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              payment['description'] ?? 'No description',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd().add_jm().format(paymentDate),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navigate to payment details
                },
                child: const Text('View Receipt'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No payment history',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment records will appear here.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'completed':
        return theme.colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1)}";
    }
}