import 'package:flutter/material.dart';
import 'dart:ui';

class FrostedBox extends StatelessWidget {
  const FrostedBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(
            alignment: Alignment.center,
            height: 100.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.menu, color: Color(0xFF07070F), size: 30.0),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.camera_alt, color: Color(0xFF07070F), size: 30.0),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.person, color: Color(0xFF07070F), size: 30.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}