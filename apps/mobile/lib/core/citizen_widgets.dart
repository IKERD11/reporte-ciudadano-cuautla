import 'package:flutter/material.dart';
import 'citizen_theme.dart';

class PilotNotice extends StatelessWidget {
  const PilotNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xff211a40),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: navy),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Prueba piloto · Sin atención municipal.\nNo sustituye a los servicios de emergencia.',
            style: TextStyle(fontSize: 11, color: navy, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) {
    final done = ['Resuelto', 'Cerrado'].contains(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: done ? const Color(0xff153c36) : const Color(0xff262054),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: done ? const Color(0xff6ee7b5) : const Color(0xffbba2ff),
        ),
      ),
    );
  }
}
