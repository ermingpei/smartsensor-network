import 'package:flutter/material.dart';

class QBitIcon extends StatelessWidget {
  final double size;

  const QBitIcon({Key? key, this.size = 42}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon/qbit_coin.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if image is missing
            return Container(
                color: Colors.amber,
                child: Center(
                    child: Text("Q",
                        style: TextStyle(fontWeight: FontWeight.bold))));
          },
        ),
      ),
    );
  }
}
