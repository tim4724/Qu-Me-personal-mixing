import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/faderModel.dart';
import 'package:qu_me/core/levelConverter.dart';
import 'package:qu_me/core/metersModel.dart';
import 'package:qu_me/gestures/dragFader.dart';

enum LevelType { mono, stereo_left, stereo_right }

abstract class Fader extends StatefulWidget {
  final int id;
  final String _faderName;
  final String _technicalName;
  final String _userName;
  final Color _accentColor;
  final bool _stereo;

  Fader(this.id, this._faderName, this._technicalName, this._userName,
      this._accentColor, this._stereo,
      {Key key})
      : super(key: key);
}

class HorizontalFader extends Fader {
  HorizontalFader(int id, String faderName, String technicalName,
      String userName, Color accentColor, bool stereo)
      : super(id, faderName, technicalName, userName, accentColor, stereo);

  @override
  State<StatefulWidget> createState() => _HorizontalFaderState();
}

class VerticalFader extends Fader {
  VerticalFader(int id, String faderName, String technicalName, String userName,
      Color accentColor, bool stereo)
      : super(id, faderName, technicalName, userName, accentColor, stereo);

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
  final FaderModel faderModel = FaderModel();
  var activePointers = 0;
  var value = 0.0;

  bool get active => activePointers > 0;

  Color get color => widget._accentColor;

  _FaderState() {
    gestures[MultiTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<MultiTapGestureRecognizer>(
            () => MultiTapGestureRecognizer(), (recognizer) {
      recognizer
        ..onTapDown = ((pointer, details) => onPointerStart())
        ..onTapCancel = ((pointer) => onPointerStop())
        ..onTapUp = (pointer, details) => onPointerStop();
    });
  }

  void onPointerStart() {
    setState(() => activePointers++);
  }

  void onDragUpdate(double delta) {
    final sliderWidth = keyFaderSlider.currentContext.size.width;
    final deltaNormalized = (delta / (sliderWidth - 16));
    final currentSliderValue = faderModel.getSliderValue(widget.id);
    final newSliderValue = currentSliderValue + deltaNormalized;
    faderModel.onNewSliderValue(widget.id, newSliderValue);
  }

  void onPointerStop() {
    setState(() => activePointers--);
  }

  Widget get faderLabel {
    if (!active) {
      return _FaderLabel(widget._faderName, widget._userName, color, active);
    }
    return Selector<FaderModel, String>(
      selector: (_, model) {
        final db = model.getValueInDb(widget.id);
        return (db >= 0.1 ? "+" : "") + "${db.toStringAsFixed(1)}db";
      },
      builder: (_, dbValue, child) {
        return _FaderLabel(dbValue, widget._technicalName, color, active,
            textAlignPrimary: TextAlign.end);
      },
    );
  }

  BoxDecoration get decoration {
    return BoxDecoration(
      color: active ? backgroundActiveColor : backgroundColor,
      borderRadius: _FaderState.borderRadius,
      border: Border.all(color: widget._accentColor, width: 1),
    );
  }
}

class _HorizontalFaderState extends _FaderState {
  _HorizontalFaderState() : super() {
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
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: decoration,
      child: Row(
        children: [
          faderLabel,
          Expanded(
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: gestures,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: FaderSlider(widget.id, active, widget._stereo,
                    key: keyFaderSlider),
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
  _VerticalFaderState() : super() {
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
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: decoration,
      child: Column(
        children: [
          faderLabel,
          Expanded(
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: gestures,
              child: RotatedBox(
                quarterTurns: 3,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: FaderSlider(widget.id, active, widget._stereo,
                        key: keyFaderSlider)),
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

class FaderSlider extends StatelessWidget {
  static const stop = convertFromDbValue;
  static const _levelTexts = ["-inf", "-30", "-10", "0"];
  static const _levelFractionalOffset = [0.1, -0.5, -0.5, -0.5];
  static const _colors = [
    Colors.green,
    Colors.green,
    Colors.yellow,
    Colors.red
  ];
  static const _radius = 9.0;
  static final _levelStops = [stop(-128), stop(-30), stop(-10), stop(0)];
  static final _gradientStops = [stop(-128), stop(-5), stop(0), stop(10)];
  final int _id;
  final bool _active;
  final bool _stereo;

  FaderSlider(this._id, this._active, this._stereo, {Key key})
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
              gradient: LinearGradient(colors: _colors, stops: _gradientStops),
              borderRadius:
                  const BorderRadius.all(const Radius.circular(_radius)),
            ),
            child: Stack(
              overflow: Overflow.visible,
              children: [0, 1, 2, 3]
                  .map<Widget>((i) => _LevelLabel(_levelTexts[i],
                      _levelStops[i] * width, _levelFractionalOffset[i]))
                  .toList()
                    ..insertAll(0, _getLevelIndicator(0.5, width, height))
                    ..add(Selector<FaderModel, double>(selector: (_, model) {
                      return model.getSliderValue(_id);
                    }, builder: (_, sliderValue, child) {
                      return _FaderKnop(sliderValue * width, _active);
                    })),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _getLevelIndicator(double level, double width, double height) {
    // TODO: check mix is mono
    if (_stereo) {
      return [
        Selector<MetersModel, double>(selector: (_, model) {
          return model.getMeterValue(_id);
        }, builder: (_, level, child) {
          return _LevelIndicator.left(level, width, height / 2.0);
        }),
        Selector<MetersModel, double>(selector: (_, model) {
          return model.getMeterValue(_id % 2 == 0 ? _id + 1 : _id - 1);
        }, builder: (_, level, child) {
          return _LevelIndicator.right(level, width, height / 2.0);
        }),
      ];
    }
    return [
      Selector<MetersModel, double>(selector: (_, model) {
        return model.getMeterValue(_id);
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
    const radius = FaderSlider._radius;
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

class _LevelLabel extends StatelessWidget {
  static const textColor = Color.fromARGB(196, 0, 0, 0);
  final String text;
  final double position;
  final double fractionalOffset;

  const _LevelLabel(this.text, this.position, this.fractionalOffset);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position,
      bottom: 0,
      top: 0,
      child: Center(
        child: FractionalTranslation(
          translation: Offset(fractionalOffset, 0),
          child: Text(
            text,
            style: const TextStyle(inherit: false, color: textColor),
          ),
        ),
      ),
    );
  }
}
