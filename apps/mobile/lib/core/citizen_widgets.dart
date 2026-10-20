import 'package:flutter/material.dart';
import 'citizen_theme.dart';

class CitizenFrame extends StatelessWidget {
  const CitizenFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) {
      final desktop = viewport.maxWidth > 520;
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.8,
            colors: [Color(0xffc9effa), Color(0xffeaf7fc), Color(0xffd7f3ec)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(desktop ? 24 : 0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(desktop ? 38 : 0),
                boxShadow: desktop
                    ? const [
                        BoxShadow(
                          color: Color(0x3307325f),
                          blurRadius: 60,
                          offset: Offset(0, 20),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class PilotNotice extends StatelessWidget {
  const PilotNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xffedf5fc),
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
    final inProgress = ['En atención', 'En proceso'].contains(label);
    final done = ['Resuelto', 'Cerrado'].contains(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xffcaf6e5)
            : inProgress
            ? const Color(0xffdceeff)
            : const Color(0xfffff0bd),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: done
              ? const Color(0xff08745f)
              : inProgress
              ? const Color(0xff1263c2)
              : const Color(0xffbd7100),
        ),
      ),
    );
  }
}
