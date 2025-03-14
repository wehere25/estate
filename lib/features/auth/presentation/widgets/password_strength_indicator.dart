import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String strength;
  
  const PasswordStrengthIndicator({
    Key? key,
    required this.strength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    double value;
    
    switch (strength) {
      case 'Weak':
        color = Colors.red;
        value = 0.3;
        break;
      case 'Medium':
        color = Colors.orange;
        value = 0.6;
        break;
      case 'Strong':
        color = Colors.green;
        value = 1.0;
        break;
      default:
        color = Colors.grey;
        value = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            Text(
              strength,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 5,
        ),
        if (strength == 'Weak')
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Use at least 8 characters with uppercase, lowercase, numbers, and symbols',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
