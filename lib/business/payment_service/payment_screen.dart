// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:spotify_project/Business_Logic/firestore_database_service.dart';
import 'package:spotify_project/business/payment_service/payment_service.dart';
import 'package:spotify_project/screens/register_page.dart';

FirestoreDatabaseService _firestoreDatabaseService = FirestoreDatabaseService();

// New PaymentResult class added at the top
class PaymentResult {
  final bool success;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.errorMessage,
  });
}

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final String merchantName;

  const PaymentScreen({
    Key? key,
    required this.amount,
    this.currency = 'PLN',
    this.merchantName = 'Musee',
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(PaymentResult(
          success: false,
          errorMessage: 'Payment cancelled',
        ));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Processing Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop(PaymentResult(
                success: false,
                errorMessage: 'Payment cancelled',
              ));
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startPayment() async {
    print('Starting payment process');
    print('Original amount: ${widget.amount} ${widget.currency}');

    if (!mounted) return;

    try {
      setState(() => _status = 'Creating payment intent...');

      // The amount is already in PLN, so multiply by 100 to convert to groszy
      final amountInCents = (widget.amount * 100).toInt();
      print('Amount in cents/groszy: $amountInCents ${widget.currency}');

      // Add these lines to get user details
      final userEmail = currentUser?.email;
      final userName = currentUser?.displayName;

      print('Processing payment for user: $userName ($userEmail)');

      // Updated initialization with user details
      await _paymentService.initializePaymentSheet(
        amount: amountInCents,
        currency: widget.currency.toLowerCase(),
        merchantDisplayName: widget.merchantName,
        email: userEmail,
        name: userName,
      );

      if (!mounted) return;
      setState(() => _status = 'Payment sheet initialized...');
      print('Payment sheet initialized successfully');

      // Present payment sheet
      setState(() => _status = 'Opening payment form...');
      final success = await _paymentService.presentPaymentSheet();
      print('Payment sheet presented with result: $success');

      if (success && mounted) {
        await _showSuccessDialog();
        Navigator.of(context).pop(PaymentResult(
          success: true,
        ));
        print('Payment was successful');

        // TODO: Add the logic to update the user's subscription status
        _firestoreDatabaseService.updatePaymentDuration();
      } else if (mounted) {
        print('Payment was not successful');
        setState(() => _status = 'Payment failed');
        Navigator.of(context).pop(PaymentResult(
          success: false,
          errorMessage: 'Payment failed',
        ));
      }
    } on PaymentException catch (e) {
      print('PaymentException caught: ${e.message}');
      if (!mounted) return;

      if (!e.isCancelled) {
        setState(() => _status = 'Error: ${e.message}');
        Navigator.of(context).pop(PaymentResult(
          success: false,
          errorMessage: e.message,
        ));
      } else {
        setState(() => _status = 'Payment cancelled');
        Navigator.of(context).pop(PaymentResult(
          success: false,
          errorMessage: 'Payment cancelled',
        ));
      }
    } catch (e) {
      print('Unexpected error: $e');
      if (!mounted) return;

      setState(() => _status = 'Error: $e');
      Navigator.of(context).pop(PaymentResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      ));
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Successful'),
          content: const Text('Your payment has been processed successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
