import 'package:flutter/material.dart';

class ChildLocationScreen extends StatelessWidget {
  const ChildLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Children Location Screen',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
