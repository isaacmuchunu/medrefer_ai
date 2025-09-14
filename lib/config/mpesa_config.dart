/// M-Pesa Configuration for MedRefer AI
/// 
/// This file contains all the configuration needed for M-Pesa integration.
/// Replace the sandbox values with production values when going live.

class MpesaConfig {
  // Environment Configuration
  static const bool isProduction = false; // Set to true for production
  
  // API URLs
  static const String sandboxBaseUrl = 'https://sandbox.safaricom.co.ke';
  static const String productionBaseUrl = 'https://api.safaricom.co.ke';
  
  static String get baseUrl => isProduction ? productionBaseUrl : sandboxBaseUrl;
  
  // Sandbox Credentials (Replace with your actual sandbox credentials)
  static const String sandboxConsumerKey = 'YOUR_SANDBOX_CONSUMER_KEY';
  static const String sandboxConsumerSecret = 'YOUR_SANDBOX_CONSUMER_SECRET';
  static const String sandboxBusinessShortCode = '174379';
  static const String sandboxPasskey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  
  // Production Credentials (Replace with your actual production credentials)
  static const String productionConsumerKey = 'YOUR_PRODUCTION_CONSUMER_KEY';
  static const String productionConsumerSecret = 'YOUR_PRODUCTION_CONSUMER_SECRET';
  static const String productionBusinessShortCode = 'YOUR_BUSINESS_SHORTCODE';
  static const String productionPasskey = 'YOUR_PRODUCTION_PASSKEY';
  
  // Current Environment Credentials
  static String get consumerKey => isProduction ? productionConsumerKey : sandboxConsumerKey;
  static String get consumerSecret => isProduction ? productionConsumerSecret : sandboxConsumerSecret;
  static String get businessShortCode => isProduction ? productionBusinessShortCode : sandboxBusinessShortCode;
  static String get passkey => isProduction ? productionPasskey : sandboxPasskey;
  
  // Callback URLs
  static const String sandboxCallbackUrl = 'https://your-sandbox-app.com/mpesa/callback';
  static const String productionCallbackUrl = 'https://your-production-app.com/mpesa/callback';
  
  static String get callbackUrl => isProduction ? productionCallbackUrl : sandboxCallbackUrl;
  
  // Transaction Configuration
  static const String transactionType = 'CustomerPayBillOnline';
  static const int timeoutSeconds = 120; // 2 minutes
  static const int maxRetries = 3;
  
  // Validation
  static bool get isConfigured {
    return consumerKey != 'YOUR_SANDBOX_CONSUMER_KEY' && 
           consumerKey != 'YOUR_PRODUCTION_CONSUMER_KEY' &&
           consumerSecret != 'YOUR_SANDBOX_CONSUMER_SECRET' &&
           consumerSecret != 'YOUR_PRODUCTION_CONSUMER_SECRET';
  }
  
  // Test Phone Numbers (Sandbox only)
  static const List<String> testPhoneNumbers = [
    '254708374149', // Test number 1
    '254711XXXXXX', // Test number 2
    '254733XXXXXX', // Test number 3
  ];
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    '1': 'Insufficient funds in the account',
    '1001': 'Unable to lock subscriber, a transaction is already in process for the current subscriber',
    '1019': 'Transaction expired. No MO has been received',
    '1032': 'Request cancelled by user',
    '1037': 'DS timeout user cannot be reached',
    '2001': 'Invalid PIN entered',
    '4001': 'Transaction failed',
    '4002': 'Transaction failed - Invalid account',
    '4003': 'Transaction failed - Invalid amount',
    '4004': 'Transaction failed - Invalid phone number',
    '4005': 'Transaction failed - Transaction not permitted to originator',
    '4006': 'Transaction failed - Transaction not permitted to receiver',
    '4007': 'Transaction failed - Cannot route to receiver',
    '4008': 'Transaction failed - Transaction expired',
    '4009': 'Transaction failed - Invalid transaction reference',
    '4010': 'Transaction failed - Unable to reach M-Pesa system',
  };
  
  static String getErrorMessage(String code) {
    return errorMessages[code] ?? 'Transaction failed with error code: $code';
  }
}

/// M-Pesa Setup Instructions
/// 
/// To set up M-Pesa integration:
/// 
/// 1. SANDBOX SETUP:
///    - Go to https://developer.safaricom.co.ke/
///    - Create an account and log in
///    - Create a new app
///    - Get your Consumer Key and Consumer Secret
///    - Replace the sandbox credentials above
/// 
/// 2. PRODUCTION SETUP:
///    - Apply for M-Pesa API access through Safaricom
///    - Get your production credentials
///    - Set up your callback URL endpoint
///    - Replace the production credentials above
///    - Set isProduction = true
/// 
/// 3. CALLBACK URL SETUP:
///    - Set up a server endpoint to receive M-Pesa callbacks
///    - The endpoint should handle POST requests
///    - Update the callback URLs above
/// 
/// 4. TESTING:
///    - Use the test phone numbers provided by Safaricom
///    - Test with small amounts first
///    - Monitor the transaction logs
/// 
/// 5. SECURITY:
///    - Never commit production credentials to version control
///    - Use environment variables for production
///    - Implement proper error handling
///    - Log all transactions for audit purposes
/// 
/// 6. COMPLIANCE:
///    - Ensure HIPAA compliance for medical payments
///    - Implement proper audit trails
///    - Follow PCI DSS guidelines
///    - Maintain transaction records as required by law

/// Sample Environment Variables (.env file):
/// 
/// # M-Pesa Sandbox
/// MPESA_SANDBOX_CONSUMER_KEY=your_sandbox_consumer_key
/// MPESA_SANDBOX_CONSUMER_SECRET=your_sandbox_consumer_secret
/// MPESA_SANDBOX_SHORTCODE=174379
/// MPESA_SANDBOX_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
/// MPESA_SANDBOX_CALLBACK_URL=https://your-sandbox-app.com/mpesa/callback
/// 
/// # M-Pesa Production
/// MPESA_PRODUCTION_CONSUMER_KEY=your_production_consumer_key
/// MPESA_PRODUCTION_CONSUMER_SECRET=your_production_consumer_secret
/// MPESA_PRODUCTION_SHORTCODE=your_business_shortcode
/// MPESA_PRODUCTION_PASSKEY=your_production_passkey
/// MPESA_PRODUCTION_CALLBACK_URL=https://your-production-app.com/mpesa/callback
/// 
/// # Environment
/// MPESA_ENVIRONMENT=sandbox # or production

/// Sample Callback Handler (Node.js/Express):
/// 
/// app.post('/mpesa/callback', (req, res) => {
///   const { Body } = req.body;
///   
///   if (Body && Body.stkCallback) {
///     const { MerchantRequestID, CheckoutRequestID, ResultCode, ResultDesc } = Body.stkCallback;
///     
///     // Process the callback
///     console.log('M-Pesa Callback:', {
///       MerchantRequestID,
///       CheckoutRequestID,
///       ResultCode,
///       ResultDesc
///     });
///     
///     // Update your database
///     // Send notifications to your app
///     
///     res.status(200).json({ message: 'Callback received' });
///   } else {
///     res.status(400).json({ error: 'Invalid callback' });
///   }
/// });

/// Sample Flutter Environment Setup:
/// 
/// 1. Add flutter_dotenv to pubspec.yaml:
///    dependencies:
///      flutter_dotenv: ^5.1.0
/// 
/// 2. Create .env file in project root
/// 
/// 3. Load environment variables:
///    import 'package:flutter_dotenv/flutter_dotenv.dart';
///    
///    void main() async {
///      await dotenv.load(fileName: ".env");
///      runApp(MyApp());
///    }
/// 
/// 4. Use environment variables:
///    static String get consumerKey => dotenv.env['MPESA_CONSUMER_KEY'] ?? '';
