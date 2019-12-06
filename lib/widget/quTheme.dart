import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/entities/QuItemColors.dart';

class QuThemeData {
  final double itemRadius;
  final double borderWidth;
  final int labelBackgroundAlpha;

  final TextStyle buttonTextStyle;
  final Color buttonColor;
  final Color buttonCheckColor;
  final double buttonPressedOpacity;

  final QuItemColors defaultGroupColors;
  final TextStyle groupLabelTextStyle;

  final QuItemColors meColors;

  final Color wheelColor;
  final Color wheelCarveColor;
  final Color wheelInactiveColor;

  final Color mutedColor;

  final Color faderBackgroundColor;
  final Color faderInactiveBackgroundColor;
  final Color faderMutedBackgroundColor;

  final double sliderRadius;
  final Color sliderPanBackgroundColor;
  final Color sliderValueLabelColor;
  final Color sliderMuteLabelColor;
  final Color sliderLevelShadowColor;
  final Color sliderZeroMarkerColor;
  final List<Color> sliderLevelColors;

  // TODO: do better?
  static QuThemeData get() {
    return MyApp.quThemeData;
  }

  BorderRadius get borderRadius {
    return BorderRadius.circular(itemRadius);
  }

  BorderRadius get sliderBorderRadius {
    return BorderRadius.circular(sliderRadius);
  }

  const QuThemeData({
    this.itemRadius,
    this.borderWidth,
    this.buttonTextStyle,
    this.buttonColor,
    this.buttonCheckColor,
    this.buttonPressedOpacity,
    this.defaultGroupColors,
    this.groupLabelTextStyle,
    this.meColors,
    this.labelBackgroundAlpha,
    this.wheelColor,
    this.wheelInactiveColor,
    this.wheelCarveColor,
    this.mutedColor,
    this.faderBackgroundColor,
    this.faderMutedBackgroundColor,
    this.faderInactiveBackgroundColor,
    this.sliderRadius,
    this.sliderPanBackgroundColor,
    this.sliderValueLabelColor,
    this.sliderMuteLabelColor,
    this.sliderLevelShadowColor,
    this.sliderZeroMarkerColor,
    this.sliderLevelColors,
  });
}
