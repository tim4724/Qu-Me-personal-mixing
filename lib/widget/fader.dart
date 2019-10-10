import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/levelConverter.dart';
import 'package:qu_me/core/model/faderLevelModel.dart';
import 'package:qu_me/core/model/metersModel.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/gestures/dragFader.dart';

enum LevelType { mono, stereo_left, stereo_right }

abstract class Fader extends StatefulWidget {
  final bool pan;
  final bool forceDisplayTechnicalName;
  final ValueNotifier<FaderInfo> _faderInfoNotifier;
  final Function doubleTap;

  Fader(this._faderInfoNotifier, this.pan,
      {this.forceDisplayTechnicalName = false, this.doubleTap, Key key})
      : super(key: key);
}

class HorizontalFader extends Fader {
  HorizontalFader(ValueNotifier<FaderInfo> faderInfo, bool pan,
      {bool forceDisplayTechnicalName = false, Function doubleTap, Key key})
      : super(faderInfo, pan,
            forceDisplayTechnicalName: forceDisplayTechnicalName,
            doubleTap: doubleTap,
            key: key);

  @override
  State<StatefulWidget> createState() => _HorizontalFaderState();
}

class VerticalFader extends Fader {
  VerticalFader(ValueNotifier<FaderInfo> faderInfo, pan,
      {bool forceDisplayTechnicalName = false, Function doubleTap, Key key})
      : super(faderInfo, pan,
            forceDisplayTechnicalName: forceDisplayTechnicalName,
            doubleTap: doubleTap,
            key: key);

  @override
  State<StatefulWidget> createState() => _VerticalFaderState();
}

abstract class _FaderState extends State<Fader> {
  static const borderRadius = BorderRadius.all(const Radius.circular(4));
  static const int inActiveAlpha = 148;
  static const Color backgroundActiveColor =
      const Color.fromARGB(255, 42, 42, 42);
  static final Color backgroundColor =
      backgroundActiveColor.withAlpha(inActiveAlpha);
  final keyFaderSlider = GlobalKey();
  final Map<Type, GestureRecognizerFactory> gestures = {};
  final FaderLevelModel faderModel = FaderLevelModel();
  final bool horizontalFader;
  var activePointers = 0;

  bool get active => activePointers > 0;

  _FaderState(this.horizontalFader) {
    gestures[MultiTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<MultiTapGestureRecognizer>(
      () => MultiTapGestureRecognizer(),
      (recognizer) {
        recognizer
          ..onTapDown = ((pointer, details) => onPointerStart())
          ..onTapCancel = ((pointer) => onPointerStop())
          ..onTapUp = ((pointer, details) => onPointerStop());
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.doubleTap != null) {
      gestures[DoubleTapGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
        () => DoubleTapGestureRecognizer(),
        (recognizer) => recognizer.onDoubleTap = widget.doubleTap,
      );
    }
  }

  void onPointerStart() {
    setState(() => activePointers++);
  }

  void onDragUpdate(double delta) {
    final id = widget._faderInfoNotifier.value.id;
    final sliderWidth = keyFaderSlider.currentContext.size.width;
    final deltaNormalized = (delta / (sliderWidth - 16));
    final currentSliderValue = faderModel.getSliderValue(id);
    final newSliderValue = currentSliderValue + deltaNormalized;
    faderModel.onNewSliderValue(id, newSliderValue);
  }

  void onPointerStop() {
    setState(() => activePointers--);
  }

  Widget faderLabel(FaderInfo info) {
    final active = this.active;
    String primary;
    String secondary;
    if (widget.forceDisplayTechnicalName) {
      primary = info.technicalName;
      if (active) {
        secondary = info.personName;
      } else {
        secondary = info.name;
      }
    } else {
      primary = info.name;
      if (active) {
        secondary = info.technicalName;
      } else {
        secondary = info.personName;
      }
    }
    return _FaderLabel(primary, secondary, info.color, active);
  }

  BoxDecoration decoration(FaderInfo faderInfo) {
    Color bgColor;
    Gradient bgGradient;
    if (faderInfo.muted) {
      // TODO do in rotated box? or calculate exact 45 degrees?
      bgGradient = LinearGradient(
        begin: horizontalFader ? Alignment(0.015, 0) : Alignment(0, 0.015),
        end: horizontalFader ? Alignment(0, 0.05) : Alignment(0.05, 0),
        tileMode: TileMode.repeated,
        stops: [0, 0.5, 0.5, 1],
        colors: [
          active ? backgroundActiveColor : backgroundColor,
          active ? backgroundActiveColor : backgroundColor,
          active ? Color(0x30FF0000) : Color(0x40FF0000),
          active ? Color(0x30FF0000) : Color(0x40FF0000),
        ],
      );
    } else {
      bgColor = active ? backgroundActiveColor : backgroundColor;
    }

    return BoxDecoration(
      color: bgColor,
      gradient: bgGradient,
      borderRadius: _FaderState.borderRadius,
      border: Border.all(color: faderInfo.color, width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FaderInfo>(
      valueListenable: widget._faderInfoNotifier,
      builder: (context, faderInfo, child) {
        print("build fader: $faderInfo");
        return buildFader(context, faderInfo);
      },
    );
  }

  Widget buildFader(BuildContext context, FaderInfo faderInfo);
}

class _HorizontalFaderState extends _FaderState {
  _HorizontalFaderState() : super(true) {
    gestures[HorizontalFaderDragRecognizer] =
        GestureRecognizerFactoryWithHandlers<HorizontalFaderDragRecognizer>(
            () => HorizontalFaderDragRecognizer(), (recognizer) {
      recognizer
        ..onDragStart = ((offset) => onPointerStart())
        ..onDragUpdate = ((details) => onDragUpdate(details.delta.dx))
        ..onDragStop = () => onPointerStop();
    });
  }

  @override
  Widget buildFader(BuildContext context, FaderInfo faderInfo) {
    return Container(
      height: 56,
      decoration: decoration(faderInfo),
      child: Row(
        children: [
          faderLabel(faderInfo),
          Expanded(
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: gestures,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: !widget.pan
                    ? _LevelSlider(
                        faderInfo.id, active, faderInfo.stereo, faderInfo.muted,
                        key: keyFaderSlider)
                    : _PanSlider(faderInfo.muted, active, key: keyFaderSlider),
              ),
            ),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.stretch,
      ),
    );
  }
}

class _VerticalFaderState extends _FaderState {
  _VerticalFaderState() : super(false) {
    gestures[VerticalFaderDragRecognizer] =
        GestureRecognizerFactoryWithHandlers<VerticalFaderDragRecognizer>(
            () => VerticalFaderDragRecognizer(), (recognizer) {
      recognizer
        ..onDragStart = ((offset) => onPointerStart())
        ..onDragUpdate = ((details) => onDragUpdate(-details.delta.dy))
        ..onDragStop = () => onPointerStop();
    });
  }

  @override
  Widget buildFader(BuildContext context, FaderInfo faderInfo) {
    return Container(
      width: 72,
      decoration: decoration(faderInfo),
      child: Column(
        children: [
          faderLabel(faderInfo),
          Expanded(
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: gestures,
              child: RotatedBox(
                quarterTurns: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: !widget.pan
                      ? _LevelSlider(faderInfo.id, active, faderInfo.stereo,
                          faderInfo.muted, key: keyFaderSlider)
                      : _PanSlider(faderInfo.muted, active,
                          key: keyFaderSlider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaderLabel extends StatelessWidget {
  static const secondaryTextColor = const Color.fromARGB(196, 255, 255, 255);
  final String primary;
  final TextAlign textAlignPrimary;
  final String secondary;
  final Color color;
  final bool active;

  const _FaderLabel(this.primary, this.secondary, this.color, this.active,
      {Key key, this.textAlignPrimary = TextAlign.start})
      : super(key: key);

  Widget buildNameLabel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          primary,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          textAlign: textAlignPrimary,
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
        Text(
          secondary,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          textScaleFactor: 0.9,
          style: TextStyle(color: secondaryTextColor),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.tightFor(width: 72, height: 50),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: active ? color : color.withAlpha(_FaderState.inActiveAlpha),
      child: buildNameLabel(context),
    );
  }
}

class _PanSlider extends StatelessWidget {
  static const radius = 9.0;
  final bool muted;
  final bool active;

  const _PanSlider(this.muted, this.active, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius:
                  const BorderRadius.all(const Radius.circular(radius)),
            ),
            child: Stack(
              overflow: Overflow.visible,
              children: List<Widget>()
                ..add(_Label("Left", 0, 0, 8))
                ..add(_Label("Right", width, -1, -8))
                ..add(
                  muted
                      ? Positioned(
                          left: width / 2,
                          top: height / 2,
                          child: FractionalTranslation(
                            translation: Offset(-0.5, -0.5),
                            child: Text(
                              "Mute",
                              overflow: TextOverflow.visible,
                              textScaleFactor: 2,
                              style: TextStyle(
                                color: Color(0x90FF0000),
                              ),
                            ),
                          ),
                        )
                      : Container(),
                )
                ..add(_FaderKnop(0.5 * width, active)),
            ),
          );
        },
      ),
    );
  }
}

class _LevelSlider extends StatelessWidget {
  static const stop = convertFromDbValue;
  static const levelTexts = ["-inf", "-30", "-10", "0"];
  static const levelFractionalOffset = [0.0, -0.5, -0.5, -0.5];
  static const levelAbsoluteOffset = [8.0, 0.0, 0.0, 0.0];
  static const colors = [Colors.green, Colors.green, Colors.yellow, Colors.red];
  static const radius = 9.0;
  static final levelStops = [stop(-128), stop(-30), stop(-10), stop(0)];
  static final gradientStops = [stop(-128), stop(-5), stop(0), stop(10)];
  final int id;
  final bool active;
  final bool stereo;
  final bool muted;

  _LevelSlider(this.id, this.active, this.stereo, this.muted, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var width = constraints.maxWidth;
          var height = constraints.maxHeight;

          return Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, stops: gradientStops),
              borderRadius:
                  const BorderRadius.all(const Radius.circular(radius)),
            ),
            child: Stack(
              overflow: Overflow.visible,
              children: [0, 1, 2, 3]
                  .map<Widget>((i) => _Label(
                      levelTexts[i],
                      levelStops[i] * width,
                      levelFractionalOffset[i],
                      levelAbsoluteOffset[i]))
                  .toList()
                    ..add(
                      muted
                          ? Positioned(
                              left: width / 2,
                              top: height / 2,
                              child: FractionalTranslation(
                                translation: Offset(-0.5, -0.5),
                                child: Text(
                                  "Mute",
                                  overflow: TextOverflow.visible,
                                  textScaleFactor: 2,
                                  style: TextStyle(
                                    color: Color(0x90FF0000),
                                  ),
                                ),
                              ),
                            )
                          : Container(),
                    )
                    ..insertAll(0, _getLevelIndicator(0.5, width, height))
                    ..add(
                      Selector<FaderLevelModel, double>(
                        selector: (_, model) => model.getSliderValue(id),
                        builder: (_, sliderValue, child) =>
                            _FaderKnop(sliderValue * width, active),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _getLevelIndicator(double level, double width, double height) {
    // TODO: check mix is mono
    if (stereo) {
      return [
        Selector<MetersModel, double>(selector: (_, model) {
          return model.getMeterValue(id);
        }, builder: (_, level, child) {
          return _LevelIndicator.left(level, width, height / 2.0);
        }),
        Selector<MetersModel, double>(selector: (_, model) {
          return model.getMeterValue(id % 2 == 0 ? id + 1 : id - 1);
        }, builder: (_, level, child) {
          return _LevelIndicator.right(level, width, height / 2.0);
        }),
      ];
    }
    return [
      Selector<MetersModel, double>(selector: (_, model) {
        return model.getMeterValue(id);
      }, builder: (_, level, child) {
        return _LevelIndicator.mono(level, width);
      })
    ];
  }
}

class _FaderKnop extends StatelessWidget {
  static const color = Color.fromARGB(_FaderState.inActiveAlpha, 255, 255, 255);
  static const colorActive = Color.fromARGB(255, 255, 255, 255);
  final double position;
  final bool active;

  const _FaderKnop(this.position, this.active);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position,
      top: -32,
      bottom: -32,
      child: FractionalTranslation(
        translation: Offset(-0.5, 0),
        child: Center(
          child: Icon(
            Icons.adjust,
            color: active ? colorActive : color,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  static const shadowColor = const Color.fromARGB(128, 0, 0, 0);
  final LevelType type;
  final double level;
  final double width;
  final double height;

  const _LevelIndicator.left(this.level, this.width, this.height, {Key key})
      : type = LevelType.stereo_left,
        super(key: key);

  const _LevelIndicator.right(this.level, this.width, this.height, {Key key})
      : type = LevelType.stereo_right,
        super(key: key);

  const _LevelIndicator.mono(this.level, this.width, {Key key})
      : type = LevelType.mono,
        height = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    const radius = _LevelSlider.radius;
    final levelPos = max((1 - level) * width, radius);
    var yOffset = 0.0;
    BorderRadius borderRadius;
    switch (type) {
      case LevelType.stereo_left:
        borderRadius = BorderRadius.only(
          topLeft: Radius.circular(max(0, radius - width + levelPos)),
          topRight: const Radius.circular(radius),
        );
        break;
      case LevelType.stereo_right:
        borderRadius = BorderRadius.only(
          bottomLeft: Radius.circular(max(0, radius - width + levelPos)),
          bottomRight: const Radius.circular(radius),
        );
        yOffset = height;
        break;
      case LevelType.mono:
      default:
        borderRadius = BorderRadius.horizontal(
          right: const Radius.circular(radius),
          left: Radius.circular(max(0, radius - width + levelPos)),
        );
        break;
    }

    return Transform.translate(
      offset: Offset(width - levelPos, yOffset),
      child: Container(
        width: levelPos,
        height: height,
        decoration: BoxDecoration(
          color: shadowColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  static const textColor = Color.fromARGB(196, 0, 0, 0);
  final String text;
  final double position;
  final double fractionalOffset;
  final double absoluteOffset;

  const _Label(
      this.text, this.position, this.fractionalOffset, this.absoluteOffset);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position,
      bottom: 0,
      top: 0,
      child: Center(
        child: FractionalTranslation(
          translation: Offset(fractionalOffset, 0.0),
          child: Transform.translate(
            offset: Offset(absoluteOffset, 0.0),
            child: Text(
              text,
              style: const TextStyle(inherit: false, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}
