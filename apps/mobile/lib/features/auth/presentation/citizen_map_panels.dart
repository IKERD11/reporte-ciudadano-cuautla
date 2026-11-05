import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/citizen_design.dart';
import '../../../core/citizen_sticker.dart';

const citizenMapFilters = [
  'Todos',
  'Seguridad',
  'Vialidad',
  'Servicios',
  'Animales',
];

class CitizenMapFilterMenu extends StatelessWidget {
  const CitizenMapFilterMenu({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    width: 128,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33184069),
          blurRadius: 27,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final filter in citizenMapFilters) ...[
          if (filter != citizenMapFilters.first) const SizedBox(height: 4),
          Semantics(
            selected: selected == filter,
            button: true,
            child: Material(
              color: selected == filter
                  ? const Color(0xffe9f2ff)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: () => onSelected(filter),
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: selected == filter
                            ? const Color(0xff0d61d6)
                            : const Color(0xff55718f),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class CitizenNearbySheet extends StatelessWidget {
  const CitizenNearbySheet({
    super.key,
    required this.expanded,
    this.collapsed = false,
    this.onCollapse,
    required this.availableHeight,
    required this.reports,
    required this.onToggle,
    required this.onSelected,
  });
  final bool expanded, collapsed;
  final VoidCallback? onCollapse;
  final double availableHeight;
  final List<Map<String, dynamic>> reports;
  final VoidCallback onToggle;
  final ValueChanged<Map<String, dynamic>> onSelected;
  double get targetHeight => collapsed
      ? 64
      : expanded
      ? math
            .min(560.0, availableHeight - 125)
            .clamp(203.0, double.infinity)
            .toDouble()
      : 203;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const ValueKey('nearby-sheet'),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    curve: Curves.ease,
    height: targetHeight,
    padding: EdgeInsets.fromLTRB(19, 18, 19, collapsed ? 12 : 14),
    decoration: const BoxDecoration(
      color: Color(0xfafbfdff),
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      boxShadow: [
        BoxShadow(
          color: Color(0x1a123f65),
          blurRadius: 28,
          offset: Offset(0, -10),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: SizedBox(
            height: 31,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Incidentes cercanos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xff082b65),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.72,
                      height: 1.5,
                    ),
                  ),
                ),
                if (!collapsed)
                  Semantics(
                    expanded: expanded,
                    button: true,
                    child: TextButton(
                      key: const ValueKey('nearby-toggle'),
                      onPressed: onToggle,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            expanded ? 'Ver menos' : 'Ver todos',
                            style: const TextStyle(
                              color: Color(0xff0862dd),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const CitizenIcon(
                            'chevron',
                            size: 18,
                            color: Color(0xff0862dd),
                            strokeWidth: 2.4,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (onCollapse != null)
                  TextButton(
                    onPressed: onCollapse,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(31, 31),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (collapsed)
                          const Text('Mostrar', style: TextStyle(fontSize: 12)),
                        Semantics(
                          label: collapsed
                              ? 'Mostrar incidentes cercanos'
                              : 'Ocultar incidentes cercanos',
                          child: AnimatedRotation(
                            turns: collapsed ? -.25 : .25,
                            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
                            child: const CitizenIcon('chevron', size: 19),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!collapsed)
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: expanded ? double.infinity : 130,
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false, overscroll: false),
                  child: ListView(
                    padding: EdgeInsets.only(bottom: expanded ? 5 : 0),
                    children: [
                      if (reports.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Text(
                            'Aún no hay reportes de la comunidad con ubicación en esta zona.',
                            style: TextStyle(
                              color: Color(0xff6782a5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      for (var i = 0; i < reports.length; i++)
                        _NearbyCard(
                          report: reports[i],
                          first: i == 0,
                          onTap: () => onSelected(reports[i]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.report,
    required this.first,
    required this.onTap,
  });
  final Map<String, dynamic> report;
  final bool first;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final title = '${report['category'] ?? report['folio'] ?? 'Reporte'}';
    final artwork = categoryArtwork(title);
    final date = DateTime.tryParse('${report['created_at'] ?? ''}')?.toLocal();
    final dateLabel = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      margin: EdgeInsets.only(top: first ? 12 : 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12174267),
            blurRadius: 20,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 103),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 59,
                    height: 59,
                    decoration: BoxDecoration(
                      color: artwork.$2,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: CitizenSticker(artwork.$1, size: 54),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff092b60),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${report['address'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff6782a5),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        if (dateLabel.isNotEmpty)
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: Color(0xff6782a5),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 24,
                    child: CitizenIcon(
                      'chevron',
                      size: 22,
                      color: Color(0xff5c7ba3),
                      strokeWidth: 2.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
