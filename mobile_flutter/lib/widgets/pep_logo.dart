import 'package:flutter/material.dart';
import '../constants/theme.dart';

class PepLogo extends StatelessWidget {
  final double size;
  const PepLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: kPrimary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: size * 0.52,
          ),
        ),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Pep ',
                style: TextStyle(
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w500,
                  color: kPrimary,
                ),
              ),
              TextSpan(
                text: 'EDUCATION',
                style: TextStyle(
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
