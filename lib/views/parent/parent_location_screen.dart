import 'package:flutter/material.dart';

class ParentLocationScreen extends StatelessWidget {
  const ParentLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Parent Location Screen',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
