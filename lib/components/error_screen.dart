import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Kelola Kelas', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4F46E5),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'Terjadi kesalahan:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4F46E5),
              ),
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}