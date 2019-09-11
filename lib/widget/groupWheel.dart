import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/gestures/dragFader.dart';
import 'package:qu_me/io/asset.dart' as asset;
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/widget/pageGroup.dart';

typedef WheelSelected = Function();
typedef WheelDragUpdate = Function(double delta);
typedef WheelDragRelease = Function();

class GroupWheel extends StatefulWidget {
  final Color _accentColor;
  final String _groupName;
  final WheelDragUpdate dragUpdateCallback;
  final WheelDragRelease dragReleaseCallback;

  const GroupWheel(this._accentColor, this._groupName, this.dragUpdateCallback,
      this.dragReleaseCallback,
      {Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupWheelState();
  }
}

class _GroupWheelState extends State<GroupWheel> {
  final Color backgroundColor = Colors.black45;
  final Color backgroundActiveColor = Colors.black.withAlpha(150);
  final keyWheel = GlobalKey();
  var activePointers = 0;
  var wheelDragDelta = 0.0;
  var lastTapTimestamp = 0;
  ui.Image shadowOverlay;

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
    var wheelHeight = keyWheel.currentContext.size.height;
    widget.dragUpdateCallback(-delta / wheelHeight);
    var newWheelDragDelta = (wheelDragDelta - delta).clamp(0, wheelHeight);
    setState(() => wheelDragDelta = newWheelDragDelta);
  }

  void onTapUp() {
    onPointerStop();
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastTapTimestamp < 300) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PageGroup()),
      );
    }
    lastTapTimestamp = currentTime;
  }

  void onPointerStop() {
    setState(() {
      activePointers--;
      if (activePointers == 0) {
        widget.dragReleaseCallback();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool active = activePointers > 0;
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
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: active ? backgroundActiveColor : backgroundColor,
        borderRadius: BorderRadius.all(Radius.circular(2)),
        border: Border.all(color: widget._accentColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupLabel(widget._groupName, widget._accentColor),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: gestures,
                child: CustomPaint(
                  painter: _Wheel(wheelDragDelta, shadowOverlay),
                  key: keyWheel,
                ),
              ),
            ),
          ),
        ],
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
  static const baseColor = Color.fromARGB(255, 180, 180, 180);
  static const carveColor = Color.fromARGB(255, 21, 21, 21);
  final double offset;
  final ui.Image shadowOverlay;

  const _Wheel(this.offset, this.shadowOverlay);

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
    var paint = Paint()..color = baseColor;

    // clear the canvas area with the base grey color
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = carveColor;
    // carves of the wheel are drawn with a offset
    var drawOffset = (-offset % minCarveOffset) - carveHeight;

    while (drawOffset < size.height) {
      // offset to center on a scale from 0 to 1
      var offToCenter = (1 - 2 * drawOffset / size.height).abs();

      // calculate the top and bottom of the next carve in the wheel
      var t = max(drawOffset, 0.0);
      var h = carveHeight.toDouble();
      h = ui.lerpDouble(h, h * minCarveOffset / maxCarveOffset, offToCenter);
      var b = min(size.height, drawOffset + h);

      // draw the carving
      canvas.drawRect(Rect.fromLTRB(0, t, size.width, b), paint);

      // next carve position:
      drawOffset += ui.lerpDouble(maxCarveOffset, minCarveOffset, offToCenter);
    }
  }

  @override
  bool shouldRepaint(_Wheel oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.shadowOverlay == null && shadowOverlay != null;
  }

  Size sizeOf(ui.Image img) {
    return Size(img.width.toDouble(), img.height.toDouble());
  }
}
