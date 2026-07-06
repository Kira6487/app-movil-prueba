import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(lg, md, lg, xxl);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets cardCompact = EdgeInsets.all(md);
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}
