import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/gestures/dragFader.dart';

enum LevelType { mono, stereo_left, stereo_right }

abstract class Fader extends StatefulWidget {
  final String _faderName;
  final String _channel;
  final String _userName;
  final Color _accentColor;
  final bool _stereo;

  Fader(this._faderName, this._channel, this._userName, this._accentColor,
      this._stereo,
      {Key key})
      : super(key: key);
}

class HorizontalFader extends Fader {
  HorizontalFader(String faderName, String channel, String userName,
      Color accentColor, bool stereo)
      : super(faderName, channel, userName, accentColor, stereo);

  @override
  State<StatefulWidget> createState() => _HorizontalFaderState();
}

class VerticalFader extends Fader {
  VerticalFader(String faderName, String channel, String userName,
      Color accentColor, bool stereo)
      : super(faderName, channel, userName, accentColor, stereo);

  @override
  State<StatefulWidget> createState() => _VerticalFaderState();
}

abstract class _FaderState extends State<Fader> {
  final Color backgroundColor = Colors.black45;
  final Color backgroundActiveColor = Colors.black.withAlpha(150);
  final keyFaderSlider = GlobalKey();
  final Map<Type, GestureRecognizerFactory> gestures = {};
  int activePointers = 0;
  double value = 0;

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
    var sliderSize = keyFaderSlider.currentContext.size;
    var newValue = value + delta / (sliderSize.width - 16);
    setState(() => value = newValue.clamp(0.0, 1.0));
  }

  void onPointerStop() {
    setState(() => activePointers--);
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
    bool active = activePointers > 0;
    Widget label = active
        ? _FaderLabel(
            value.toStringAsFixed(2), widget._channel, widget._accentColor)
        : _FaderLabel(widget._faderName, widget._userName, widget._accentColor);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: active ? backgroundActiveColor : backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(2)),
        border: Border.all(color: widget._accentColor, width: 1),
      ),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: gestures,
        child: Row(
          children: [
            label,
            Expanded(
              child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: _FaderSlider(value, active, widget._stereo,
                      key: keyFaderSlider)),
            )
          ],
          crossAxisAlignment: CrossAxisAlignment.stretch,
        ),
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
    bool active = activePointers > 0;
    Widget label = active
        ? _FaderLabel(
            value.toStringAsFixed(2), widget._channel, widget._accentColor)
        : _FaderLabel(widget._faderName, widget._userName, widget._accentColor);
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: active ? backgroundActiveColor : backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(2)),
        border: Border.all(color: widget._accentColor, width: 1),
      ),
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: gestures,
        child: Column(
          children: [
            label,
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: _FaderSlider(value, active, widget._stereo,
                        key: keyFaderSlider)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaderLabel extends StatelessWidget {
  final String primary;
  final String secondary;
  final Color color;

  const _FaderLabel(this.primary, this.secondary, this.color, {Key key})
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

class _FaderSlider extends StatelessWidget {
  static const radius = 9.0;
  static const stops = [0.0, 0.3, 0.5, 0.7, 0.9];
  static const colors = [
    Colors.green,
    Colors.green,
    Colors.green,
    Colors.yellow,
    Colors.red
  ];
  static const levels = ["-inf", "-20", "-10", "0", "+10"];
  final double value;
  final bool active;
  final bool stereo;

  const _FaderSlider(this.value, this.active, this.stereo, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: LayoutBuilder(builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = constraints.maxHeight;
        var knobPos = value * width;

        return Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, stops: stops),
            borderRadius: BorderRadius.all(Radius.circular(radius)),
          ),
          child: Stack(
            overflow: Overflow.visible,
            children: [0, 1, 2, 3, 4]
                .map<Widget>((i) => _LevelLabel(
                    levels[i], stops[i] * width, value * 0.7 > stops[i]))
                .toList()
                  ..insertAll(
                    0,
                    stereo
                        ? [
                            _LevelIndicator.left(
                                value * 0.6, width, height / 2.0, radius),
                            _LevelIndicator.right(
                                value * 0.7, width, height / 2.0, radius),
                          ]
                        : [
                            _LevelIndicator.mono(value * 0.7, width, radius),
                          ],
                  )
                  ..add(_FaderKnop(knobPos, active)),
          ),
        );
      }),
    );
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
    Color shadowColor = Colors.black.withAlpha(180);
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
  final double offset;
  final bool highlight;

  const _LevelLabel(this.text, this.offset, this.highlight);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: max(offset, 16),
      bottom: 0,
      top: 0,
      child: Center(
        child: FractionalTranslation(
          translation: Offset(-0.5, 0),
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
