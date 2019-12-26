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
  final double buttonDisabledOpacity;

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
  final QuColorSwatch accentQuColors;

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

  Radius get itemRadiusCircular {
    return Radius.circular(itemRadius);
  }

  BorderRadius get itemBorderRadius {
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
    this.buttonDisabledOpacity,
    this.mutedButtonColor,
    this.itemRadius,
    this.itemBorderWidth,
    this.itemBackgroundColor,
    this.faderColors,
    this.faderMixColors,
    this.faderFxReturnColors,
    this.faderMutedBackgroundColor,
    this.defaultGroupColors,
    this.accentQuColors,
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

///
/// A ColorSwatch with bool index
/// true -> active-color
/// false -> inactive-color
///
class QuColorSwatch extends ColorSwatch<bool> {
  QuColorSwatch.fromColors(Color activeColor, Color inActiveColor)
      : super(activeColor.value, {true: activeColor, false: inActiveColor});

  QuColorSwatch(int activeColorValue, int inActiveColorValue)
      : this.fromColors(Color(activeColorValue), Color(inActiveColorValue));

  QuColorSwatch.fromSingleColor(Color activeColor, int inactiveAlpha)
      : this.fromColors(activeColor, activeColor.withAlpha(inactiveAlpha));
}
