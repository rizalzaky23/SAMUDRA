import 'package:flutter/material.dart';

class RiskIndicator extends StatelessWidget {
  final String risk;

  const RiskIndicator({Key? key, required this.risk}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color riskColor;
    IconData riskIcon;
    String riskText;

    switch (risk.toLowerCase()) {
      case 'awas':
        riskColor = Colors.red;
        riskIcon = Icons.warning_amber_rounded;
        riskText = 'Awas';
        break;
      case 'siaga':
        riskColor = Colors.orange;
        riskIcon = Icons.error_outline;
        riskText = 'Siaga';
        break;
      case 'waspada':
        riskColor = Colors.yellow.shade700;
        riskIcon = Icons.info_outline;
        riskText = 'Waspada';
        break;
      case 'aman':
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle_outline;
        riskText = 'Aman';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskIcon, color: riskColor, size: 24),
          const SizedBox(width: 8),
          Text(
            riskText,
            style: TextStyle(
              color: riskColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
