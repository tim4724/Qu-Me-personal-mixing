import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/entities/faderInfo.dart';

class QuThemeData {
  // Button
  final TextStyle buttonTextStyle;
  final Color buttonColor;
  final Color buttonCheckColor;
  final double buttonPressedOpacity;
  final Color mutedButtonColor;

  // Faderitem/Groupitem
  final double itemRadius;
  final double itemBorderWidth;
  final QuColorSwatch itemBackgroundColor;

  // Fader
  final Map<FaderInfoCategory, QuColorSwatch> faderColors;
  final QuColorSwatch faderMixColors;
  final QuColorSwatch faderFxReturnColors;
  final Color faderMutedBackgroundColor;

  // Group
  final QuColorSwatch defaultGroupColors;
  final QuColorSwatch meGroupColors;

  // GroupWheel
  final Color wheelCarveColor;
  final QuColorSwatch wheelColor;

  // Slider
  final double sliderRadius;
  final Color sliderPanBackgroundColor;
  final Color sliderValueLabelColor;
  final Color sliderMuteTextColor;
  final Color sliderLevelShadowColor;
  final Color sliderZeroMarkerColor;
  final QuColorSwatch sliderIconColor;
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

  QuThemeData({
    this.buttonTextStyle,
    this.buttonColor,
    this.buttonCheckColor,
    this.buttonPressedOpacity,
    this.mutedButtonColor,
    this.itemRadius,
    this.itemBorderWidth,
    this.itemBackgroundColor,
    this.faderColors,
    this.faderMixColors,
    this.faderFxReturnColors,
    this.faderMutedBackgroundColor,
    this.defaultGroupColors,
    this.meGroupColors,
    this.wheelCarveColor,
    this.wheelColor,
    this.sliderRadius,
    this.sliderPanBackgroundColor,
    this.sliderValueLabelColor,
    this.sliderMuteTextColor,
    this.sliderLevelShadowColor,
    this.sliderZeroMarkerColor,
    this.sliderIconColor,
    this.sliderLevelColors,
  });
}

class QuColorSwatch extends ColorSwatch<bool> {
  QuColorSwatch.fromColors(Color activeColor, Color basicColor)
      : super(activeColor.value, {true: activeColor, false: basicColor});

  QuColorSwatch(int activeColorValue, int inActiveColorValue)
      : this.fromColors(Color(activeColorValue), Color(inActiveColorValue));

  QuColorSwatch.fromSingleColor(Color activeColor, int basicAlpha)
      : this.fromColors(activeColor, activeColor.withAlpha(basicAlpha));
}
