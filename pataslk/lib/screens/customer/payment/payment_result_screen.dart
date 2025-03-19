// This file doesn't use Firebase directly - it's a UI component for displaying payment results
import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final VoidCallback? onSuccess;

  const PaymentResultScreen({
    Key? key,
    required this.success,
    this.onSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: success ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              success ? Icons.check : Icons.close,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            success
                ? 'Payment Method Added Successfully!'
                : 'Payment Failed!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            success
                ? 'Your payment method has been added.'
                : 'Please try again or contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Closes the bottom sheet
                if (success && onSuccess != null) {
                  onSuccess!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
