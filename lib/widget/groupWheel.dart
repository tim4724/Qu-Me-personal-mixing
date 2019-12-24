import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/gestures/dragFader.dart';
import 'package:qu_me/io/asset.dart' as asset;
import 'package:qu_me/widget/pageSends.dart';

typedef WheelDragUpdate = void Function(int id, double delta);
typedef WheelDragRelease = void Function(int id);

class GroupWheel extends StatefulWidget {
  final int _groupId;
  final ColorSwatch<bool> _colors;
  final WheelDragUpdate _dragUpdateCallback;
  final WheelDragRelease _dragReleaseCallback;

  GroupWheel(
    this._groupId,
    this._dragUpdateCallback,
    this._dragReleaseCallback, {
    Key key,
  })  : _colors = _colorsForType(_groupId),
        super(key: key);

  static ColorSwatch<bool> _colorsForType(int id) {
    if (sendGroupModel.getGroup(id).sendGroupType == SendGroupType.Me) {
      return quTheme.meGroupColors;
    }
    return quTheme.defaultGroupColors;
  }

  @override
  State<StatefulWidget> createState() {
    return _GroupWheelState();
  }
}

class _GroupWheelState extends State<GroupWheel> {
  final keyWheel = GlobalKey();
  Map<Type, GestureRecognizerFactory> gestures;
  ui.Image shadowOverlay;
  var wheelActive = false;
  var activePointers = 0;
  var wheelDragDelta = 0.0;
  var lastTapTimestamp = 0;

  int get id => widget._groupId;

  bool get active => activePointers > 0;

  _GroupWheelState() {
    asset.loadImage("assets/shadow.png").then((image) {
      setState(() => shadowOverlay = image);
    });
  }

  @override
  void initState() {
    super.initState();
    if (gestures == null) {
      final longTapDur = Duration(milliseconds: 100);
      gestures = {
        VerticalFaderDragRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalFaderDragRecognizer>(
                () => VerticalFaderDragRecognizer(slop: 2.0), (recognizer) {
          recognizer.onDragStart = (_) => onPointerStart();
          recognizer.onDragUpdate = (details) => onDragUpdate(details.delta.dy);
          recognizer.onDragStop = onPointerStop;
        }),
        MultiTapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<MultiTapGestureRecognizer>(
                () => MultiTapGestureRecognizer(longTapDelay: longTapDur),
                (recognizer) {
          recognizer.onTapDown = (_, __) => onPointerStart();
          recognizer.onTapCancel = (_) => onPointerStop();
          recognizer.onTapUp = (_, __) => onTapUp();
          recognizer.onLongTapDown = (_, __) => onDragUpdate(0);
        }),
      };
    }
  }

  void onPointerStart() {
    setState(() => activePointers++);
  }

  void onDragUpdate(double delta) {
    if (wheelActive) {
      final wheelHeight = keyWheel.currentContext.size.height;
      widget._dragUpdateCallback(id, -delta / wheelHeight / 2);
      final newWheelDragDelta = (wheelDragDelta - delta);
      setState(() => wheelDragDelta = newWheelDragDelta);
    }
  }

  void onTapUp() {
    onPointerStop();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastTapTimestamp < 300) {
      Navigator.of(context).push(
        platformPageRoute<void>(
          builder: (context) => PageSends(id),
          context: context,
        ),
      );
    }
    lastTapTimestamp = currentTime;
  }

  void onPointerStop() {
    setState(() {
      activePointers--;
      if (activePointers == 0) {
        widget._dragReleaseCallback(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = sendGroupModel.getGroup(id);
    String groupName = group.name;
    if (groupName == null || groupName.isEmpty) {
      groupName = SendGroupModel.getGroupTechnicalName(group);
    }

    return Selector<SendGroupModel, int>(
      selector: (_, model) => model.getSendIdsForGroup(id).length,
      builder: (BuildContext context, int sendsCount, _) {
        wheelActive = sendsCount > 0;
        return Container(
          decoration: BoxDecoration(
            color: quTheme.itemBackgroundColor[active],
            borderRadius: quTheme.itemBorderRadius,
            border: Border.all(
              color: widget._colors,
              width: quTheme.itemBorderWidth,
            ),
          ),
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: gestures,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GroupLabel(groupName, widget._colors[active]),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: buildWheelArea(context, wheelActive),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildWheelArea(BuildContext context, bool wheelActive) {
    final theme = Theme.of(context);
    if (wheelActive) {
      return CustomPaint(
        painter: _Wheel(
          wheelDragDelta,
          shadowOverlay,
          quTheme.wheelColor[active],
          quTheme.wheelCarveColor,
        ),
        key: keyWheel,
      );
    }
    return Center(
      child: Text(
        QuLocalizations.get(Strings.SendGroupNothingAssigned),
        textAlign: TextAlign.center,
        style: theme.textTheme.caption,
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _GroupLabel(this.text, this.color, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(quTheme.itemRadius);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
        color: color,
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
      ),
    );
  }
}

class _Wheel extends CustomPainter {
  final color;
  final carveColor;
  final double offset;
  final ui.Image shadowOverlay;

  const _Wheel(this.offset, this.shadowOverlay, this.color, this.carveColor);

  @override
  void paint(Canvas canvas, Size maxSize) {
    // Enforce a minimum aspect ratio.
    // The wheel must be double the height, than the width.
    final maxWidth = maxSize.height / 2.0;
    if (maxSize.width > maxWidth) {
      canvas.translate((maxSize.width - maxWidth) / 2.0, 0);
    }
    final size = Size(min(maxSize.width, maxWidth), maxSize.height);

    final paint = Paint();
    canvas.translate(4, 2);
    drawWheel(canvas, size - Offset(8, 4), paint);
    canvas.translate(-4, -2);

    if (shadowOverlay != null) {
      final srcRect = Offset.zero & sizeOf(shadowOverlay);
      final dstRect = Offset.zero & size;
      canvas.drawImageRect(shadowOverlay, srcRect, dstRect, paint);
    }
  }

  void drawWheel(Canvas canvas, Size size, Paint paint) {
    const carveHeight = 3.0;
    const minCarveOffset = 7.0;
    const maxCarveOffset = 12.0;
    paint.color = color;

    // clear the canvas area with the base grey color
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = carveColor;
    // carves of the wheel are drawn with a offset
    var drawOffset = (-offset % minCarveOffset) - carveHeight;

    while (drawOffset < size.height) {
      // offset to center on a scale from 0 to 1
      final offToCenter = (1 - 2 * drawOffset / size.height).abs();

      // calculate the top and bottom of the next carve in the wheel
      final t = max(drawOffset, 0.0);
      var h = carveHeight;
      h = ui.lerpDouble(h, h * minCarveOffset / maxCarveOffset, offToCenter);
      final b = min(size.height, drawOffset + h);

      // draw the carving
      canvas.drawRect(Rect.fromLTRB(0, t, size.width, b), paint);

      // next carve position:
      drawOffset += ui.lerpDouble(maxCarveOffset, minCarveOffset, offToCenter);
    }
  }

  @override
  bool shouldRepaint(_Wheel oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.shadowOverlay == null && shadowOverlay != null ||
        oldDelegate.color != this.color;
  }

  Size sizeOf(ui.Image img) {
    return Size(img.width.toDouble(), img.height.toDouble());
  }
}
