import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class ReferenceUi {
  // Light palette keeps the reference layout while matching SANAD's app tone.
  static const darkBg = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFFF7F7F8);
  static const darkCard = Color(0xFFFFFFFF);
  static const darkCardAlt = Color(0xFFF1F1F3);
  static const darkBorder = Color(0xFFE7E7EA);
  static const darkText = Color(0xFF171719);
  static const darkMuted = Color(0xFF85858B);

  // Vibrant Accents
  static const blue = Color(0xFF3886FF);
  static const cyan = Color(0xFF00C9A7);
  static const green = Color(0xFF00E676);
  static const yellow = Color(0xFFFFC400);
  static const orange = Color(0xFFFF6D00);
  static const red = Color(0xFFFF3D00);
  static const purple = Color(0xFFA855F7);
  static const pink = Color(0xFFEC4899);

  // Legacy light references
  static const ink = Color(0xFF151515);
  static const secondary = Color(0xFF858585);
  static const panel = Color(0xFFF1F1F1);
  static const divider = Color(0xFFE7E7EA);
  static const magenta = Color(0xFFEC65FB);
  static const periwinkle = Color(0xFF8185FF);
  static const mint = Color(0xFF3CE4C4);
  static const ring = Color(0xFF3886FF);

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.3,
    color: darkMuted,
  );
  static const TextStyle number = TextStyle(
    fontSize: 46,
    height: 1.05,
    fontWeight: FontWeight.w600,
    letterSpacing: -2,
    color: darkText,
  );

  static ThemeData theme(ThemeData base, bool arabic) => base.copyWith(
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.light(
      surface: darkSurface,
      primary: blue,
      secondary: cyan,
      onSurface: darkText,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: arabic ? 'Tajawal' : 'Poppins',
      fontFamilyFallback: const ['Arial', 'Roboto'],
      bodyColor: darkText,
      displayColor: darkText,
    ),
  );
}

enum ReferenceSymbol {
  steps,
  heart,
  watch,
  run,
  grid,
  person,
  flame,
  moon,
  layers,
  scan,
  oxygen,
  today,
  search,
  calendar,
  info,
  menu,
  chevronDown,
  chevronLeft,
  chevronRight,
  weight,
  envelope,
  comment,
  globe,
  marker,
  refresh,
  signOut,
  pulse,
  chart,
}

class ReferenceIcon extends StatelessWidget {
  const ReferenceIcon(
    this.symbol, {
    super.key,
    this.color = ReferenceUi.ink,
    this.size = 24,
  });
  final ReferenceSymbol symbol;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (symbol == ReferenceSymbol.steps) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(
          'assets/icons/flaticon/footprints.png',
          width: size,
          height: size,
          semanticLabel: _labelFor(symbol),
        ),
      );
    }
    return SvgPicture.asset(
      _assetFor(symbol),
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: _labelFor(symbol),
    );
  }

  static String _assetFor(ReferenceSymbol icon) => switch (icon) {
    ReferenceSymbol.heart => 'assets/icons/flaticon/heart.svg',
    ReferenceSymbol.pulse => 'assets/icons/flaticon/pulse.svg',
    ReferenceSymbol.watch => 'assets/icons/flaticon/smartphone.svg',
    ReferenceSymbol.person => 'assets/icons/flaticon/user.svg',
    ReferenceSymbol.flame => 'assets/icons/flaticon/flame.svg',
    ReferenceSymbol.moon => 'assets/icons/flaticon/moon.svg',
    ReferenceSymbol.oxygen => 'assets/icons/flaticon/raindrops.svg',
    ReferenceSymbol.scan ||
    ReferenceSymbol.search => 'assets/icons/flaticon/search.svg',
    ReferenceSymbol.grid => 'assets/icons/flaticon/apps.svg',
    ReferenceSymbol.run => 'assets/icons/flaticon/dashboard.svg',
    ReferenceSymbol.steps => 'assets/icons/flaticon/heart.svg',
    ReferenceSymbol.chart => 'assets/icons/flaticon/chart-histogram.svg',
    ReferenceSymbol.layers => 'assets/icons/flaticon/layers.svg',
    ReferenceSymbol.today => 'assets/icons/flaticon/sun.svg',
    ReferenceSymbol.calendar => 'assets/icons/flaticon/calendar.svg',
    ReferenceSymbol.info => 'assets/icons/flaticon/info.svg',
    ReferenceSymbol.menu => 'assets/icons/flaticon/menu-dots-vertical.svg',
    ReferenceSymbol.chevronDown => 'assets/icons/flaticon/angle-small-down.svg',
    ReferenceSymbol.chevronLeft => 'assets/icons/flaticon/angle-small-left.svg',
    ReferenceSymbol.chevronRight =>
      'assets/icons/flaticon/angle-small-right.svg',
    ReferenceSymbol.weight => 'assets/icons/flaticon/scale.svg',
    ReferenceSymbol.envelope => 'assets/icons/flaticon/envelope.svg',
    ReferenceSymbol.comment => 'assets/icons/flaticon/comment.svg',
    ReferenceSymbol.globe => 'assets/icons/flaticon/globe.svg',
    ReferenceSymbol.marker => 'assets/icons/flaticon/map-marker.svg',
    ReferenceSymbol.refresh => 'assets/icons/flaticon/refresh.svg',
    ReferenceSymbol.signOut => 'assets/icons/flaticon/sign-out.svg',
  };

  static String _labelFor(ReferenceSymbol icon) => switch (icon) {
    ReferenceSymbol.heart => 'Heart',
    ReferenceSymbol.pulse => 'Heart rate',
    ReferenceSymbol.chart => 'Trends',
    ReferenceSymbol.watch => 'Wearable',
    ReferenceSymbol.person => 'Profile',
    ReferenceSymbol.flame => 'Energy',
    ReferenceSymbol.moon => 'Sleep',
    ReferenceSymbol.oxygen => 'Oxygen',
    ReferenceSymbol.scan || ReferenceSymbol.search => 'Search',
    ReferenceSymbol.steps => 'Steps',
    ReferenceSymbol.grid => 'Apps',
    ReferenceSymbol.run => 'Activity',
    ReferenceSymbol.layers => 'Insights',
    ReferenceSymbol.today => 'Today',
    ReferenceSymbol.calendar => 'Calendar',
    ReferenceSymbol.info => 'Information',
    ReferenceSymbol.menu => 'More options',
    ReferenceSymbol.chevronDown ||
    ReferenceSymbol.chevronLeft ||
    ReferenceSymbol.chevronRight => 'Navigate',
    ReferenceSymbol.weight => 'Weight',
    ReferenceSymbol.envelope => 'Email',
    ReferenceSymbol.comment => 'Message',
    ReferenceSymbol.globe => 'Country',
    ReferenceSymbol.marker => 'Location',
    ReferenceSymbol.refresh => 'Refresh',
    ReferenceSymbol.signOut => 'Sign out',
  };
}
