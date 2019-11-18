import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/levelAndPanConverter.dart';
import 'package:qu_me/core/model/faderLevelPanModel.dart';
import 'package:qu_me/core/model/metersModel.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/gestures/dragFader.dart';
import 'package:qu_me/util.dart';
import 'package:qu_me/widget/quTheme.dart';

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
  final _levelPanModel = FaderLevelPanModel();
  final keyFaderSlider = GlobalKey();
  final Map<Type, GestureRecognizerFactory> gestures = {};
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
    final sliderWidth = keyFaderSlider.currentContext.size.width - 40;
    final deltaNormalized = (delta / (sliderWidth));
    if (widget.pan) {
      final currentSliderValue = _levelPanModel.getPanSlider(id);
      _levelPanModel.onSliderPan(id, currentSliderValue + deltaNormalized);
    } else {
      final currentSliderValue = _levelPanModel.getLevelSLider(id);
      _levelPanModel.onSliderLevel(id, currentSliderValue + deltaNormalized);
    }
  }

  void onPointerStop() {
    setState(() => activePointers--);
  }

  Widget faderLabel(FaderInfo info) {
    String primary;
    String secondary;
    if (widget.forceDisplayTechnicalName) {
      primary = info.technicalName;
      if (active && info.personName != null && info.personName.isNotEmpty) {
        secondary = info.personName;
      } else {
        secondary = info.name;
      }
    } else {
      primary = info.name;
      if (active || info.personName == null || info.personName.isEmpty) {
        secondary = info.technicalName;
      } else {
        secondary = info.personName;
      }
    }
    Color color = info.color;
    if (!active) {
      final quTheme = QuThemeData.get();
      color = color.withAlpha(quTheme.labelBackgroundAlpha);
    }

    return _FaderLabel(primary, secondary, color);
  }

  BoxDecoration decoration(BuildContext context, FaderInfo faderInfo) {
    final quTheme = QuThemeData.get();

    Color bgColor;
    if (active) {
      bgColor = quTheme.faderBackgroundColor;
    } else {
      bgColor = quTheme.faderInactiveBackgroundColor;
    }

    Gradient bgGradient;
    if (faderInfo.muted) {
      bgGradient = LinearGradient(
        begin: horizontalFader ? Alignment(0.015, 0) : Alignment(0, 0.015),
        end: horizontalFader ? Alignment(0, 0.05) : Alignment(0.05, 0),
        tileMode: TileMode.repeated,
        stops: [0, 0.5, 0.5, 1],
        colors: [
          bgColor,
          bgColor,
          quTheme.faderMutedBackgroundColor,
          quTheme.faderMutedBackgroundColor
        ],
      );
    }

    return BoxDecoration(
      color: bgGradient == null ? bgColor : null,
      gradient: bgGradient,
      borderRadius: quTheme.borderRadius,
      border: Border.all(color: faderInfo.color, width: quTheme.borderWidth),
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

  Widget buildSlider(BuildContext context, FaderInfo faderInfo) {
    // Switch between pan and level mode
    return AnimatedSwitcher(
      key: keyFaderSlider,
      child: RawGestureDetector(
          key: ValueKey(widget.pan),
          behavior: HitTestBehavior.opaque,
          gestures: gestures,
          child: widget.pan
              ? _PanSlider(faderInfo.id, faderInfo.muted, active)
              : _LevelSlider(
                  faderInfo.id, faderInfo.muted, active, faderInfo.stereo)),
      duration: const Duration(milliseconds: 400),
    );
  }
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
      decoration: decoration(context, faderInfo),
      child: Row(
        children: [
          faderLabel(faderInfo),
          Expanded(child: buildSlider(context, faderInfo)),
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
      decoration: decoration(context, faderInfo),
      child: Column(
        children: [
          faderLabel(faderInfo),
          Expanded(
            child: Padding(
              // padding because the width is larger than in horizontal fader
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: RotatedBox(
                quarterTurns: 3,
                child: buildSlider(context, faderInfo),
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
  final String secondary;
  final Color color;

  const _FaderLabel(this.primary, this.secondary, this.color, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints.tightFor(width: 72, height: 50),
      padding: const EdgeInsets.all(8),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
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
            style: theme.textTheme.caption,
          )
        ],
      ),
    );
  }
}

abstract class _Slider extends StatelessWidget {
  final levelPanModel = FaderLevelPanModel();
  final int id;
  final bool muted;
  final bool active;

  _Slider(this.id, this.muted, this.active, {key: Key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Container(
            height: height,
            width: width,
            decoration: decoration(),
            child: Stack(
              overflow: Overflow.visible,
              children: children(context, width, height),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration decoration();

  List<Widget> children(BuildContext context, double width, double height);

  Color getKnobColor(BuildContext context) {
    final quTheme = QuThemeData.get();
    final theme = Theme.of(context);
    Color knobColor = theme.iconTheme.color;
    if (!active) {
      knobColor = knobColor.withAlpha(quTheme.labelBackgroundAlpha);
    }
    return knobColor;
  }

  Widget buildMuteLabel(double left, double top) {
    final color = QuThemeData.get().sliderMuteLabelColor;
    final text = QuLocalizations.get(Strings.Mute);
    return _Label(text, left, top, Offset(-0.5, -0.5),
        textColor: color, textScaleFactor: 2.0);
  }

  Widget buildZeroMarker(double left, double top) {
    final quTheme = QuThemeData.get();
    return Positioned(
      left: left - 0.5,
      top: top,
      child: Container(
        color: quTheme.sliderZeroMarkerColor,
        width: 1,
        height: 8,
      ),
    );
  }
}

class _PanSlider extends _Slider {
  _PanSlider(int id, bool muted, bool active, {Key key})
      : super(id, muted, active, key: key);

  @override
  BoxDecoration decoration() {
    final quTheme = QuThemeData.get();
    return BoxDecoration(
      color: quTheme.sliderPanBackgroundColor,
      borderRadius: quTheme.sliderBorderRadius,
    );
  }

  List<Widget> children(BuildContext context, double width, double height) {
    final knobColor = getKnobColor(context);
    final xCenter = width / 2;
    final yCenter = height / 2;
    final labels =
        QuLocalizations.getList([Strings.Left, Strings.Center, Strings.Right]);
    return [
      buildZeroMarker(xCenter, -12),
      buildZeroMarker(xCenter, height + 4),
      _Label(labels[0], 8, yCenter, Offset(0, -0.5)),
      _Label(labels[1], xCenter, yCenter, Offset(-0.5, -0.5)),
      _Label(labels[2], width - 8, yCenter, Offset(-1, -0.5)),
      if (muted) buildMuteLabel(xCenter, height / 2),
      StreamBuilder(
        initialData: levelPanModel.getPanSlider(id),
        stream: levelPanModel.getPanStreamForId(id),
        builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
          var fractionalOffset = snapshot.data;
          const stepSize = 1.0 / 74.0;
          if (fractionalOffset > 0.5 - stepSize &&
              fractionalOffset < 0.5 + stepSize) {
            fractionalOffset = 0.5;
          }
          return _FaderKnop(fractionalOffset * width, knobColor);
        },
      )
    ];
  }
}

class _LevelSlider extends _Slider {
  static const stop = dBLevelToSliderValue;
  static const levelTexts = ["-\u221e", "-30", "-10", "0"]; // TODO: inf symbol?
  static const levelFractionalOffset = [0.0, -0.5, -0.5, -0.5];
  static const levelAbsoluteOffset = [8.0, 0.0, 0.0, 0.0];
  static final levelStops = [stop(-128), stop(-30), stop(-10), stop(0)];
  static final gradientStops = [stop(-128), stop(-5), stop(0), stop(10)];
  final bool stereo;

  _LevelSlider(int id, bool muted, bool active, this.stereo, {Key key})
      : super(id, muted, active, key: key);

  @override
  BoxDecoration decoration() {
    final quTheme = QuThemeData.get();
    final colors = quTheme.sliderLevelColors;
    return BoxDecoration(
      gradient: LinearGradient(colors: colors, stops: gradientStops),
      borderRadius: quTheme.sliderBorderRadius,
    );
  }

  @override
  List<Widget> children(BuildContext context, double width, double height) {
    final knobColor = getKnobColor(context);
    final yCenter = height / 2;
    final xCenter = width / 2;
    final levelLabels = mapIndexed(levelTexts, (i, text) {
      final left = levelStops[i] * width + levelAbsoluteOffset[i];
      final fractionalOffset = Offset(levelFractionalOffset[i], -0.5);
      return _Label(text, left, yCenter, fractionalOffset);
    });
    final zeroStop = levelStops[3] * width;
    return [
      ...getLevelIndicator(width, height),
      buildZeroMarker(zeroStop, -12),
      buildZeroMarker(zeroStop, height + 4),
      ...levelLabels,
      if (muted) buildMuteLabel(xCenter, yCenter),
      StreamBuilder(
        initialData: levelPanModel.getLevelSLider(id),
        stream: levelPanModel.getLevelStreamForId(id),
        builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
          // TODO: if linked, base on left channel!
          return _FaderKnop(snapshot.data * width, knobColor);
        },
      ),
    ];
  }

  List<Widget> getLevelIndicator(double width, double height) {
    if (stereo) {
      return [
        StreamBuilder<List<double>>(
          initialData: MetersModel.levelsInDb,
          builder: (_, AsyncSnapshot<List<double>> snapshot) {
            final level = dBLevelToSliderValue(snapshot.data[id]);
            return _LevelIndicator.left(level, width, height / 2.0);
          },
        ),
        StreamBuilder<List<double>>(
          initialData: MetersModel.levelsInDb,
          builder: (_, AsyncSnapshot<List<double>> snapshot) {
            final level = dBLevelToSliderValue(snapshot.data[id + 1]);
            return _LevelIndicator.right(level, width, height / 2.0);
          },
        ),
      ];
    } else {
      return [
        StreamBuilder<List<double>>(
          initialData: MetersModel.levelsInDb,
          builder: (_, AsyncSnapshot<List<double>> snapshot) {
            final level = dBLevelToSliderValue(snapshot.data[id]);
            return _LevelIndicator.mono(level, width);
          },
        ),
      ];
    }
  }
}

class _FaderKnop extends StatelessWidget {
  final double position;
  final Color color;

  const _FaderKnop(this.position, this.color);

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
            color: color,
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
    final quTheme = QuThemeData.get();
    final radius = quTheme.sliderRadius;
    final levelPos = max((1 - level) * width, radius);
    var yOffset = 0.0;
    // TODO: proberbly can be simplified because min level is -110 db
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
          color: quTheme.sliderLevelShadowColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final double left;
  final double top;
  final Offset fractionalOffset;
  final textColor;
  final textScaleFactor;

  const _Label(
    this.text,
    this.left,
    this.top,
    this.fractionalOffset, {
    this.textColor,
    this.textScaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = textColor ?? QuThemeData.get().sliderValueLabelColor;
    return Positioned(
      left: left,
      top: top,
      child: Center(
        child: FractionalTranslation(
          translation: fractionalOffset,
          child: Text(
            text,
            overflow: TextOverflow.visible,
            style: theme.textTheme.caption.copyWith(color: color),
            textScaleFactor: textScaleFactor,
          ),
        ),
      ),
    );
  }
}
