import 'dart:ui';

import 'package:flutter/foundation.dart';

class QuItemColors {
  final Color borderColor;
  final Color backgroundColor;
  final Color activebackgroundColor;
  final Color labelColor;
  final Color activeLabelColor;

  QuItemColors({
    @required this.borderColor,
    @required this.backgroundColor,
    @required this.activebackgroundColor,
    @required this.labelColor,
    @required this.activeLabelColor,
  });

  border() {
    return borderColor;
  }

  background(bool active) {
    return active ? activebackgroundColor : backgroundColor;
  }

  label(bool active) {
    return active ? activeLabelColor : labelColor;
  }
}
