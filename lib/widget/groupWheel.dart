import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/gestures/dragFader.dart';
import 'package:qu_me/io/asset.dart' as asset;
import 'package:qu_me/widget/pageSends.dart';

typedef WheelSelected = Function(int id);
typedef WheelDragUpdate = Function(int id, double delta);
typedef WheelDragRelease = Function(int id);

class GroupWheel extends StatefulWidget {
  final int _id;
  final WheelDragUpdate dragUpdateCallback;
  final WheelDragRelease dragReleaseCallback;

  const GroupWheel(this._id, this.dragUpdateCallback, this.dragReleaseCallback,
      {Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupWheelState();
  }
}

class _GroupWheelState extends State<GroupWheel> {
  final keyWheel = GlobalKey();
  var activePointers = 0;
  var wheelDragDelta = 0.0;
  var lastTapTimestamp = 0;
  ui.Image shadowOverlay;

  int get id => widget._id;

  _GroupWheelState() {
    asset.loadImage("assets/shadow.png").then(onImageLoaded);
  }

  void onImageLoaded(ui.Image image) {
    setState(() => shadowOverlay = image);
  }

  void onPointerStart() {
    setState(() => activePointers++);
  }

  void onDragUpdate(double delta) {
    final wheelHeight = keyWheel.currentContext.size.height;
    widget.dragUpdateCallback(widget._id, -delta / wheelHeight / 2);
    final newWheelDragDelta = (wheelDragDelta - delta);
    setState(() => wheelDragDelta = newWheelDragDelta);
  }

  void onTapUp() {
    onPointerStop();
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastTapTimestamp < 300) {
      Navigator.of(context).push(
        platformPageRoute<void>(
          builder: (context) => PageGroup(id),
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
        widget.dragReleaseCallback(widget._id);
      }
    });
  }

  bool get active => activePointers > 0;

  @override
  Widget build(BuildContext context) {
    var gestures = {
      VerticalFaderDragRecognizer:
          GestureRecognizerFactoryWithHandlers<VerticalFaderDragRecognizer>(
              () => VerticalFaderDragRecognizer(slop: 2.0), (recognizer) {
        recognizer
          ..onDragStart = ((offset) => onPointerStart())
          ..onDragUpdate = ((details) => onDragUpdate(details.delta.dy))
          ..onDragStop = onPointerStop;
      }),
      MultiTapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<MultiTapGestureRecognizer>(
              () => MultiTapGestureRecognizer(), (recognizer) {
        recognizer
          ..onTapDown = ((pointer, details) => onPointerStart())
          ..onTapCancel = ((pointer) => onPointerStop())
          ..onTapUp = (pointer, details) => onTapUp();
      }),
    };

    final theme = Theme.of(context);
    return Selector<SendGroupModel, MapEntry<SendGroup, int>>(
      selector: (BuildContext context, SendGroupModel model) {
        return MapEntry(
            model.getGroup(id), model.getSendIdsForGroup(id).length);
      },
      builder: (BuildContext context, MapEntry<SendGroup, int> pair, _) {
        final group = pair.key;
        final sendsCount = pair.value;
        return Container(
          width: 72,
          decoration: BoxDecoration(
            color: active && sendsCount <= 0
                ? theme.primaryColor // TODO: primaryColor is not optimal...
                : theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: Color(0xFF9A9A9A), width: 1),
          ),
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: sendsCount > 0
                ? gestures
                : {
                    MultiTapGestureRecognizer:
                        gestures[MultiTapGestureRecognizer]
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GroupLabel(group.name, group.color.withAlpha(148)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: buildWheelArea(context, sendsCount),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildWheelArea(BuildContext context, int sendsCount) {
    if (sendsCount > 0) {
      return CustomPaint(
        painter: _Wheel(wheelDragDelta, shadowOverlay, active),
        key: keyWheel,
      );
    }
    final theme = Theme.of(context);
    return Container(
      child: Center(
        child: Text(
          "Nothing Assigned\nDouble Tap",
          textAlign: TextAlign.center,
          style: theme.textTheme.caption,
        ),
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
    return Container(
      height: 50,
      color: color,
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
  static const baseColor = Color.fromARGB(196, 180, 180, 180);
  static const baseColorActive = Color.fromARGB(255, 180, 180, 180);
  static const carveColor = Color.fromARGB(255, 21, 21, 21);
  final double offset;
  final ui.Image shadowOverlay;
  final bool active;

  const _Wheel(this.offset, this.shadowOverlay, this.active);

  @override
  void paint(Canvas canvas, Size maxSize) {
    // Enforce a minimum aspect ratio.
    // The wheel must be double the height, than the width.
    var maxWidth = maxSize.height / 2;
    if (maxSize.width > maxWidth) {
      canvas.translate((maxSize.width - maxWidth) / 2, 0);
    }
    Size size = Size(min(maxSize.width, maxWidth), maxSize.height);

    canvas.translate(4, 2);
    drawWheel(canvas, size - Offset(8, 4));
    canvas.translate(-4, -2);

    if (shadowOverlay != null) {
      var srcRect = Offset.zero & sizeOf(shadowOverlay);
      var dstRect = Offset.zero & size;
      canvas.drawImageRect(shadowOverlay, srcRect, dstRect, Paint());
    }
  }

  void drawWheel(Canvas canvas, Size size) {
    const carveHeight = 3.0;
    const minCarveOffset = 7.0;
    const maxCarveOffset = 12.0;
    var paint = Paint()..color = active ? baseColorActive : baseColor;

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
        oldDelegate.active != this.active;
  }

  Size sizeOf(ui.Image img) {
    return Size(img.width.toDouble(), img.height.toDouble());
  }
}
