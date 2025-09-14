import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../services/mpesa_service.dart';

class MpesaPaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String? orderId;

  const MpesaPaymentScreen({
    Key? key,
    required this.amount,
    required this.description,
    this.orderId,
  }) : super(key: key);

  @override
  State<MpesaPaymentScreen> createState() => _MpesaPaymentScreenState();
}

class _MpesaPaymentScreenState extends State<MpesaPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  bool _isProcessing = false;
  String? _transactionId;
  MpesaTransactionStatus? _transactionStatus;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'M-Pesa Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF00A651), // M-Pesa green
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // M-Pesa Logo and Header
                _buildHeader(),
                SizedBox(height: 4.h),

                // Payment Summary
                _buildPaymentSummary(),
                SizedBox(height: 4.h),

                // Phone Number Input
                _buildPhoneNumberInput(),
                SizedBox(height: 4.h),

                // Payment Instructions
                _buildInstructions(),
                SizedBox(height: 4.h),

                // Transaction Status
                if (_transactionId != null) _buildTransactionStatus(),
                SizedBox(height: 4.h),

                // Pay Button
                _buildPayButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00A651), Color(0xFF00D65F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // M-Pesa Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'M-PESA',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A651),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Secure Mobile Payment',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            'Pay with your mobile phone',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                'KSh ${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A651),
                ),
              ),
            ],
          ),
          if (widget.orderId != null) ...[
            SizedBox(height: 1.h),
            Text(
              'Order ID: ${widget.orderId}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneNumberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'M-Pesa Phone Number',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '0712345678 or +254712345678',
            prefixIcon: Icon(Icons.phone, color: Color(0xFF00A651)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF00A651), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your M-Pesa phone number';
            }
            
            final mpesaService = Provider.of<MpesaService>(context, listen: false);
            if (!mpesaService.isValidPhoneNumber(value)) {
              return 'Please enter a valid Kenyan phone number';
            }
            
            return null;
          },
          onChanged: (value) {
            if (value.isNotEmpty) {
              final mpesaService = Provider.of<MpesaService>(context, listen: false);
              if (mpesaService.isValidPhoneNumber(value)) {
                _phoneController.text = mpesaService.formatPhoneNumber(value);
                _phoneController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _phoneController.text.length),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Payment Instructions',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '1. Enter your M-Pesa registered phone number\n'
            '2. Tap "Pay with M-Pesa" button\n'
            '3. You will receive an STK push on your phone\n'
            '4. Enter your M-Pesa PIN to complete payment\n'
            '5. You will receive a confirmation SMS',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStatus() {
    return Consumer<MpesaService>(
      builder: (context, mpesaService, child) {
        final transaction = mpesaService.getTransaction(_transactionId!);
        if (transaction == null) return SizedBox.shrink();

        Color statusColor;
        IconData statusIcon;
        String statusText;

        switch (transaction.status) {
          case MpesaTransactionStatus.pending:
            statusColor = Colors.orange;
            statusIcon = Icons.hourglass_empty;
            statusText = 'Payment Pending';
            break;
          case MpesaTransactionStatus.completed:
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = 'Payment Successful';
            break;
          case MpesaTransactionStatus.failed:
            statusColor = Colors.red;
            statusIcon = Icons.error;
            statusText = 'Payment Failed';
            break;
          case MpesaTransactionStatus.cancelled:
            statusColor = Colors.grey;
            statusIcon = Icons.cancel;
            statusText = 'Payment Cancelled';
            break;
          case MpesaTransactionStatus.timeout:
            statusColor = Colors.red;
            statusIcon = Icons.access_time;
            statusText = 'Payment Timeout';
            break;
        }

        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24.sp),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'Transaction ID: ${transaction.id.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (transaction.status == MpesaTransactionStatus.pending) ...[
                SizedBox(height: 2.h),
                LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  backgroundColor: statusColor.withOpacity(0.2),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Please check your phone for the M-Pesa prompt',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              if (transaction.status == MpesaTransactionStatus.completed) ...[
                SizedBox(height: 2.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Continue'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing || _transactionId != null ? null : _initiatePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF00A651),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 20.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'Pay KSh ${widget.amount.toStringAsFixed(2)} with M-Pesa',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final mpesaService = Provider.of<MpesaService>(context, listen: false);
      
      final result = await mpesaService.initiateSTKPush(
        phoneNumber: _phoneController.text,
        amount: widget.amount,
        accountReference: widget.orderId ?? 'MedRefer-${DateTime.now().millisecondsSinceEpoch}',
        transactionDesc: widget.description,
      );

      if (result.success) {
        setState(() {
          _transactionId = result.transactionId;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
