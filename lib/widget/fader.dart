import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/faderModel.dart';
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
  final Color backgroundColor = Colors.black45;
  final Color backgroundActiveColor = Colors.black.withAlpha(150);
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

  Widget getFaderLabel() {
    if (!active) {
      return _FaderLabel(widget._faderName, widget._userName, color);
    }
    return Selector<FaderModel, String>(
      selector: (_, model) {
        final db = model.getValueInDb(widget.id);
        return (db >= 0.1 ? "+" : "") + "${db.toStringAsFixed(1)}db";
      },
      builder: (_, dbValue, child) {
        return _FaderLabel(dbValue, widget._technicalName, color,
            textAlignPrimary: TextAlign.end);
      },
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
      decoration: BoxDecoration(
        color: active ? backgroundActiveColor : backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(2)),
        border: Border.all(color: widget._accentColor, width: 1),
      ),
      child: Row(
        children: [
          getFaderLabel(),
          Expanded(
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: gestures,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
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
      decoration: BoxDecoration(
        color: active ? backgroundActiveColor : backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(2)),
        border: Border.all(color: widget._accentColor, width: 1),
      ),
      child: Column(
        children: [
          getFaderLabel(),
          Expanded(
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: gestures,
              child: RotatedBox(
                quarterTurns: 3,
                child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
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
  final String primary;
  final TextAlign textAlignPrimary;
  final String secondary;
  final Color color;

  const _FaderLabel(this.primary, this.secondary, this.color,
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
        ),
        Text(
          secondary,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
          style: DefaultTextStyle.of(context)
              .style
              .apply(fontSizeFactor: 0.9, color: Colors.white70),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.tightFor(width: 72, height: 50),
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: color,
      child: buildNameLabel(context),
    );
  }
}

class FaderSlider extends StatelessWidget {
  static const rangeInDb = [-128, -50, -30, -10, 0, 10];
  static const sliderValues = [0.0, 0.125, 0.25, 0.5, 0.75, 1.0];
  static const _gradientStops = [0.0, 0.25, 0.5, 0.75, 1.0];
  static const _levels = ["-inf", "-30", "-10", "0", "+10"];
  static const _levelLabelOffsets = [0.2, -0.5, -0.5, -0.5, -1.1];
  static const _colors = [
    Colors.green,
    Colors.green,
    Colors.green,
    Colors.yellow,
    Colors.red
  ];
  static const _radius = 9.0;
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
              borderRadius: BorderRadius.all(Radius.circular(_radius)),
            ),
            child: Stack(
              overflow: Overflow.visible,
              children: [0, 1, 2, 3, 4]
                  .map<Widget>((i) => _LevelLabel(
                      _levels[i],
                      _gradientStops[i] * width,
                      0.5 > _gradientStops[i],
                      _levelLabelOffsets[i]))
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
    if (_stereo) {
      return [
        Selector<MetersModel, double>(selector: (_, model) {
          return model.getMeterValue(_id);
        }, builder: (_, level, child) {
          return _LevelIndicator.left(level, width, height / 2.0, _radius);
        }),
        Selector<MetersModel, double>(selector: (_, model) {
          return model.getMeterValue(_id + 1);
        }, builder: (_, level, child) {
          return _LevelIndicator.right(level, width, height / 2.0, _radius);
        }),
      ];
    }
    return [
      Selector<MetersModel, double>(selector: (_, model) {
        return model.getMeterValue(_id);
      }, builder: (_, level, child) {
        return _LevelIndicator.mono(level, width, _radius);
      })
    ];
  }
}

class _FaderKnop extends StatelessWidget {
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
            color: active ? Colors.white : Colors.white70,
            size: 40,
          ),
        ),
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  final LevelType type;
  final double level;
  final double width;
  final double height;
  final double radius;
  final shadowColor = const Color.fromARGB(128, 0, 0, 0);

  const _LevelIndicator.left(this.level, this.width, this.height, this.radius,
      {Key key})
      : type = LevelType.stereo_left,
        super(key: key);

  const _LevelIndicator.right(this.level, this.width, this.height, this.radius,
      {Key key})
      : type = LevelType.stereo_right,
        super(key: key);

  const _LevelIndicator.mono(this.level, this.width, this.radius, {Key key})
      : type = LevelType.mono,
        height = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    double levelPos = max((1 - level) * width, radius);
    var yOffset = 0.0;
    BorderRadius borderRadius;
    switch (type) {
      case LevelType.stereo_left:
        borderRadius = BorderRadius.only(
          topLeft: Radius.circular(max(0, radius - width + levelPos)),
          topRight: Radius.circular(radius),
        );
        break;
      case LevelType.stereo_right:
        borderRadius = BorderRadius.only(
          bottomLeft: Radius.circular(max(0, radius - width + levelPos)),
          bottomRight: Radius.circular(radius),
        );
        yOffset = height;
        break;
      case LevelType.mono:
      default:
        borderRadius = BorderRadius.horizontal(
          right: Radius.circular(radius),
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
  final String text;
  final double position;
  final bool highlight;
  final double fractionalOffset;

  const _LevelLabel(
      this.text, this.position, this.highlight, this.fractionalOffset);

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
            style: TextStyle(
              color: highlight ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
