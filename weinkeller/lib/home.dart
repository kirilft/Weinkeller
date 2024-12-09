import 'package:flutter/material.dart';
import 'widgets/frosted_box.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFFF0000), // Blue background
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: FrostedBox(),
          ),
        ],
      ),
    );
  }
}
