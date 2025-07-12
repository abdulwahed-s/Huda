import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RevelationTypeBadge extends StatelessWidget {
  final String revelationType;

  const RevelationTypeBadge({
    super.key,
    required this.revelationType,
  });

  @override
  Widget build(BuildContext context) {
    final isMeccan = revelationType == 'Meccan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMeccan
              ? [Colors.amber[300]!, Colors.orange[400]!]
              : [Colors.blue[300]!, Colors.indigo[400]!],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (isMeccan ? Colors.orange : Colors.blue).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            isMeccan ? 'assets/images/mecca.svg' : 'assets/images/madina.svg',
            width: 12,
            height: 12,
          ),
          const SizedBox(width: 3),
          Text(
            revelationType,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
