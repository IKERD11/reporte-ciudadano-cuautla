import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Exact vector paths extracted from the supplied Figma Make Icon component.
const citizenIconPaths = <String, String>{
  'activity':
      r'''<circle cx="12" cy="12" r="9"></circle><path d="M12 7v5l3 2"></path>''',
  'alert':
      r'''<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"></path><path d="M10 21h4"></path>''',
  'arrow-left': r'''<path d="m19 12-14 0m6-6-6 6 6 6"></path>''',
  'arrow-right': r'''<path d="m5 12 14 0m-6-6 6 6-6 6"></path>''',
  'bell':
      r'''<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"></path><path d="M10 21h4"></path>''',
  'bulb':
      r'''<path d="M9 18h6M10 22h4"></path><path d="M8.5 15.5a7 7 0 1 1 7 0c-.8.6-1.1 1.3-1.1 2.5H9.6c0-1.2-.3-1.9-1.1-2.5Z"></path><path d="M12 2V.8M4.9 4.9 4 4M19.1 4.9 20 4"></path>''',
  'calendar':
      r'''<rect x="3" y="5" width="18" height="16" rx="2"></rect><path d="M8 3v4M16 3v4M3 10h18"></path><path d="M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01"></path>''',
  'camera':
      r'''<path d="M5 7h3l1.5-2h5L16 7h3a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2Z"></path><circle cx="12" cy="13" r="4"></circle>''',
  'car':
      r'''<path d="m5 11 1.7-5h10.6l1.7 5"></path><path d="M4 11h16a2 2 0 0 1 2 2v5H2v-5a2 2 0 0 1 2-2Z"></path><path d="M5 18v3M19 18v3"></path><circle cx="6" cy="14.5" r="1"></circle><circle cx="18" cy="14.5" r="1"></circle>''',
  'check': r'''<path d="m4 12 5 5L20 6"></path>''',
  'chevron': r'''<path d="m9 18 6-6-6-6"></path>''',
  'clipboard':
      r'''<rect x="5" y="4" width="14" height="17" rx="2"></rect><path d="M9 4V2h6v2M9 10h6M9 14h6"></path>''',
  'close': r'''<path d="m6 6 12 12M18 6 6 18"></path>''',
  'cone':
      r'''<path d="m9 3-4 16h14L15 3Z"></path><path d="M7.5 10h9M6 16h12M3 21h18"></path>''',
  'copy':
      r'''<rect x="8" y="8" width="11" height="12" rx="2"></rect><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h3"></path>''',
  'crosshair':
      r'''<circle cx="12" cy="12" r="6"></circle><circle cx="12" cy="12" r="2"></circle><path d="M12 2v4M12 18v4M2 12h4M18 12h4"></path>''',
  'edit':
      r'''<path d="m14 5 5 5M4 20l3.5-.7L20 6.8a1.8 1.8 0 0 0-2.6-2.6L5 16.5Z"></path>''',
  'eye':
      r'''<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"></path><circle cx="12" cy="12" r="2.5"></circle>''',
  'eye-off':
      r'''<path d="M3 3l18 18"></path><path d="M10.6 6.2A11.8 11.8 0 0 1 12 6c6.5 0 10 6 10 6a17 17 0 0 1-3 3.7M6.6 6.7C3.6 8.5 2 12 2 12s3.5 6 10 6c1.6 0 3-.4 4.2-1"></path><path d="M9.9 9.8a3 3 0 0 0 4.2 4.3"></path>''',
  'filter': r'''<path d="M4 5h16M7 12h10M10 19h4"></path>''',
  'gallery':
      r'''<rect x="3" y="4" width="18" height="16" rx="2"></rect><circle cx="9" cy="10" r="2"></circle><path d="m4 18 5-5 3 3 2-2 6 5"></path>''',
  'heart':
      r'''<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"></path>''',
  'help':
      r'''<circle cx="12" cy="12" r="9"></circle><path d="M9.5 9a2.7 2.7 0 1 1 4.2 2.3c-1 .7-1.7 1.1-1.7 2.7M12 18h.01"></path>''',
  'home':
      r'''<path d="m3 11 9-8 9 8"></path><path d="M5 10v10h14V10M9 20v-6h6v6"></path>''',
  'lock':
      r'''<rect x="5" y="10" width="14" height="11" rx="2"></rect><path d="M8 10V7a4 4 0 0 1 8 0v3"></path>''',
  'logout': r'''<path d="M10 4H4v16h6M14 8l4 4-4 4M8 12h10"></path>''',
  'mail':
      r'''<rect x="3" y="5" width="18" height="14" rx="2"></rect><path d="m4 7 8 6 8-6"></path>''',
  'map':
      r'''<path d="m3 6 5-2 8 2 5-2v14l-5 2-8-2-5 2Z"></path><path d="M8 4v14M16 6v14"></path>''',
  'mask':
      r'''<path d="M4 5c4 2 12 2 16 0v7c0 5-3.6 9-8 10-4.4-1-8-5-8-10Z"></path><path d="M7.5 11c1.4-1 2.7-1 4 0M12.5 11c1.3-1 2.6-1 4 0M10 16c1.3 1 2.7 1 4 0"></path>''',
  'megaphone':
      r'''<path d="m3 11 13-5v12L3 13Z"></path><path d="M6 14v5h4l1-4M19 9c1 1 1 5 0 6"></path>''',
  'message':
      r'''<path d="M21 11.5a8.5 8.5 0 0 1-11.7 7.9L4 21l1.6-5.3A8.5 8.5 0 1 1 21 11.5Z"></path>''',
  'more':
      r'''<circle cx="5" cy="12" r="1.5" fill="currentColor" stroke="none"></circle><circle cx="12" cy="12" r="1.5" fill="currentColor" stroke="none"></circle><circle cx="19" cy="12" r="1.5" fill="currentColor" stroke="none"></circle>''',
  'paw':
      r'''<ellipse cx="12" cy="16.5" rx="5.5" ry="4.5"></ellipse><ellipse cx="6" cy="10" rx="2" ry="2.8"></ellipse><ellipse cx="18" cy="10" rx="2" ry="2.8"></ellipse><ellipse cx="9.5" cy="6.5" rx="2" ry="2.8"></ellipse><ellipse cx="14.5" cy="6.5" rx="2" ry="2.8"></ellipse>''',
  'phone':
      r'''<path d="M5 3h4l2 5-3 2a16 16 0 0 0 6 6l2-3 5 2v4a2 2 0 0 1-2 2C10.2 20.5 3.5 13.8 3 5a2 2 0 0 1 2-2Z"></path>''',
  'pin':
      r'''<path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z"></path><circle cx="12" cy="10" r="2.5"></circle>''',
  'plus': r'''<path d="M12 5v14M5 12h14"></path>''',
  'refresh':
      r'''<path d="M20 7v5h-5"></path><path d="M4 17v-5h5"></path><path d="M6.1 8a7 7 0 0 1 11.8-1L20 12M4 12l2.1 5a7 7 0 0 0 11.8-1"></path>''',
  'search':
      r'''<circle cx="11" cy="11" r="7"></circle><path d="m16 16 5 5"></path>''',
  'settings':
      r'''<circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1-2.8 2.8-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.6v.2h-4V21a1.7 1.7 0 0 0-1-1.6 1.7 1.7 0 0 0-1.9.3l-.1.1L4.2 17l.1-.1a1.7 1.7 0 0 0 .3-1.9A1.7 1.7 0 0 0 3 14H2.8v-4H3a1.7 1.7 0 0 0 1.6-1 1.7 1.7 0 0 0-.3-1.9L4.2 7 7 4.2l.1.1a1.7 1.7 0 0 0 1.9.3A1.7 1.7 0 0 0 10 3V2.8h4V3a1.7 1.7 0 0 0 1 1.6 1.7 1.7 0 0 0 1.9-.3l.1-.1L19.8 7l-.1.1a1.7 1.7 0 0 0-.3 1.9 1.7 1.7 0 0 0 1.6 1h.2v4H21a1.7 1.7 0 0 0-1.6 1Z"></path>''',
  'share':
      r'''<path d="M12 3v12M8 7l4-4 4 4"></path><path d="M5 11H3v10h18V11h-2"></path>''',
  'shield':
      r'''<path d="M12 2 4 5v6c0 5 3.4 8.7 8 11 4.6-2.3 8-6 8-11V5Z"></path><path d="m8.5 12 2.2 2.2 4.8-5"></path>''',
  'spray':
      r'''<path d="M8 8h9v13H7V10a2 2 0 0 1 1-2Z"></path><path d="M10 8V5h5l2 3M15 5l3-2M19 6h3M19 9l2 1"></path>''',
  'sos':
      r'''<path d="M12 3v3M5.6 5.6l2.1 2.1M3 12h3M18 12h3M16.3 7.7l2.1-2.1"></path><path d="M7 20v-6a5 5 0 0 1 10 0v6Z"></path>''',
  'user':
      r'''<circle cx="12" cy="8" r="4"></circle><path d="M4 21a8 8 0 0 1 16 0"></path>''',
  'users':
      r'''<circle cx="12" cy="8" r="3.5"></circle><circle cx="5" cy="10" r="2.5"></circle><circle cx="19" cy="10" r="2.5"></circle><path d="M6 20v-2a6 6 0 0 1 12 0v2M1.5 19v-1a4 4 0 0 1 4-4M22.5 19v-1a4 4 0 0 0-4-4"></path>''',
  'woman':
      r'''<circle cx="12" cy="6" r="3"></circle><path d="M8 21v-6H5l3-6h8l3 6h-3v6M10 15v6M14 15v6"></path>''',
};

class CitizenIcon extends StatelessWidget {
  const CitizenIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
  });
  final String name;
  final double size, strokeWidth;
  final Color? color;
  @override
  Widget build(BuildContext context) => Center(
    widthFactor: 1,
    heightFactor: 1,
    child: SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-linecap="round" stroke-linejoin="round" stroke-width="$strokeWidth">${citizenIconPaths[name] ?? citizenIconPaths["more"]}</svg>',
        width: size,
        height: size,
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(
          color ?? IconTheme.of(context).color ?? const Color(0xff092b60),
          BlendMode.srcIn,
        ),
      ),
    ),
  );
}
