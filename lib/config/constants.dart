import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

/* UI related */

final lightTheme = FlexThemeData.light(
  colors: const FlexSchemeColor(
    primary: Color.fromARGB(255, 76, 206, 232),
    primaryContainer: Color(0xffeaddff),
    secondary: Color(0xff328bb3),
    secondaryContainer: Color(0xffe8def8),
    tertiary: Color(0xfff38bb0),
    tertiaryContainer: Color(0xffffd8e4),
    appBarColor: Color(0xffe8def8),
    error: Color(0xffb00020),
  ),
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 20,
  appBarStyle: FlexAppBarStyle.background,
  appBarOpacity: 0.95,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 20,
    blendOnColors: false,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  fontFamily: GoogleFonts.manrope().fontFamily,
);

final darkTheme = FlexThemeData.dark(
  colors: const FlexSchemeColor(
    primary: Color.fromARGB(255, 150, 180, 220),
    primaryContainer: Color(0xff00325b),
    secondary: Color(0xffffb59d),
    secondaryContainer: Color(0xff872100),
    tertiary: Color(0xff86d2e1),
    tertiaryContainer: Color(0xff004e59),
    appBarColor: Color(0xff872100),
    error: Color(0xffcf6679),
  ),
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 15,
  appBarStyle: FlexAppBarStyle.background,
  appBarOpacity: 0.90,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 30,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  fontFamily: GoogleFonts.manrope().fontFamily,
);

const double kScaffoldPadding = 5;
const double kDefaultPadding = 15;

const double kSmallBorderRadius = 5;

const Duration kDefaultAnimationDuration = Duration(milliseconds: 300);

const double kLargeIconSize = 100;

// Business logic related

/// If a photo's variance is lower than this value, it will be considered blurry.
/// Found this number just by looking at photos
// TODO: fix value
const double kLaplacianBlurThreshold = 999999;

/// How many photos to load at a time
const int kPhotoPageSize = 100;

/// Maximum number of large videos to show
/// Assume there are 3 rows on a phone,
/// then we will show up to 7 rows
const int kMaxVideos = 21;

const List<String> kScreenshotsFolders = [
  "Screenshots",
  "Скриншоты",
  "Снимки экрана"
];
