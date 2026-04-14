import 'package:flutter/material.dart';

class PepLogo extends StatelessWidget {
  final double size;
  const PepLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/logo_pep.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
