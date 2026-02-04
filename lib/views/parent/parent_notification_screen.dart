import 'package:flutter/material.dart';

class ParentNotificationScreen extends StatelessWidget {
  const ParentNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Parent Notification Screen',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
