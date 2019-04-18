import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class _KTouchSlop {
  final double x, y;

  const _KTouchSlop(this.x, this.y);

  const _KTouchSlop.horizontal(double x) : this(x, double.infinity);

  const _KTouchSlop.vertical(double y) : this(double.infinity, y);
}

class _FaderPointerState extends MultiDragPointerState {
  _KTouchSlop kTouchSlop;

  _FaderPointerState(Offset initialPosition, _KTouchSlop kTouchSlop)
      : super(initialPosition) {
    this.kTouchSlop = kTouchSlop;
  }

  @override
  void checkForResolutionAfterMove() {
    assert(pendingDelta != null);
    double dxAbs = pendingDelta.dx.abs();
    double dyAbs = pendingDelta.dy.abs();
    if ((dxAbs > kTouchSlop.x && dxAbs > dyAbs) ||
        (dxAbs > kTouchSlop.y && dyAbs > dxAbs)) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    starter(initialPosition);
  }
}

typedef FaderDragStartCallback = Function(Offset offset);

abstract class FaderDragRecognizer
    extends MultiDragGestureRecognizer<_FaderPointerState> implements Drag {
  _KTouchSlop kTouchSlop;
  FaderDragStartCallback onDragStart;
  GestureDragUpdateCallback onDragUpdate;
  Function onDragStop;

  FaderDragRecognizer(_KTouchSlop kTouchSlop, {Object debugOwner})
      : super(debugOwner: debugOwner) {
    this.kTouchSlop = kTouchSlop;
    onStart = (offset) {
      if (onDragStart != null) {
        onDragStart(offset);
      }
      return this;
    };
  }

  @override
  _FaderPointerState createNewPointerState(PointerDownEvent event) {
    return _FaderPointerState(event.position, kTouchSlop);
  }

  @override
  void cancel() {
    if (onDragStop != null) {
      onDragStop();
    }
  }

  @override
  void end(DragEndDetails details) {
    if (onDragStop != null) {
      onDragStop();
    }
  }

  @override
  void update(DragUpdateDetails details) {
    onDragUpdate(details);
  }

  @override
  String get debugDescription => 'fader multidrag';
}

class HorizontalFaderDragRecognizer extends FaderDragRecognizer {
  HorizontalFaderDragRecognizer({slop:2.0}) : super(_KTouchSlop.horizontal(slop));
}

class VerticalFaderDragRecognizer extends FaderDragRecognizer {
  VerticalFaderDragRecognizer({slop:2.0}) : super(_KTouchSlop.vertical(slop));
}
