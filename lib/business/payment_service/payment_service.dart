// lib/services/payment_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static const String _baseUrl = 'https://api.stripe.com/v1';
  static String get _secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';
  static String get _publishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required int amount,
    required String currency,
    String? email,
  }) async {
    try {
      print('Creating payment intent for amount: $amount $currency');

      final Map<String, dynamic> body = {
        'amount': amount.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
        if (email != null) 'receipt_email': email,
      };

      print('Making request to Stripe API...');
      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode != 200) {
        print(
            'Payment intent creation failed with status: ${response.statusCode}');
        print('Error response: $responseData');
        throw PaymentException(
          'Payment intent creation failed: ${responseData['error']?['message'] ?? response.body}',
        );
      }

      print(
          'Payment intent created successfully with ID: ${responseData['id']}');
      return responseData;
    } catch (e) {
      print('Error creating payment intent: $e');
      if (e is PaymentException) {
        rethrow;
      }
      throw PaymentException('Failed to create payment intent: $e');
    }
  }

  Future<void> initializePaymentSheet({
    required int amount,
    required String currency,
    required String merchantDisplayName,
    String? email,
    String? name,
  }) async {
    try {
      print('Initializing payment sheet...');
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        email: email,
      );

      print('Setting up payment sheet parameters...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: merchantDisplayName,
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.system,
          billingDetails: email != null || name != null
              ? BillingDetails(
                  email: email,
                  name: name,
                )
              : null,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF0553B1),
            ),
            shapes: PaymentSheetShape(
              borderWidth: 1,
              shadow: PaymentSheetShadowParams(color: Colors.black),
            ),
          ),
        ),
      );
      print('Payment sheet initialized successfully');
    } catch (e) {
      print('Error initializing payment sheet: $e');
      throw PaymentException('Payment sheet initialization failed: $e');
    }
  }

  Future<bool> presentPaymentSheet() async {
    try {
      print('Presenting payment sheet...');
      await Stripe.instance.presentPaymentSheet();
      print('Payment completed successfully');
      return true;
    } on StripeException catch (e) {
      print('Stripe exception during payment: ${e.error.localizedMessage}');
      if (e.error.code == 'cancelled') {
        throw PaymentException(
          'Payment cancelled by user',
          isCancelled: true,
        );
      }
      throw PaymentException(e.error.localizedMessage ?? 'Payment failed');
    } catch (e) {
      print('Error during payment: $e');
      throw PaymentException('Payment failed: $e');
    }
  }
}

class PaymentException implements Exception {
  final String message;
  final bool isCancelled;

  PaymentException(this.message, {this.isCancelled = false});

  @override
  String toString() => message;
}
