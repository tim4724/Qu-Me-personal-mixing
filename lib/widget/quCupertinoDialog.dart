import 'dart:ui';

import 'package:flutter/cupertino.dart';

class QuCupertinoDialog extends CupertinoPopupSurface {
  static const Color _kDialogColor = Color(0xC0000000);
  static const double _kDialogCornerRadius = 12.0;
  static const double _kBlurAmount = 20.0;
  final Widget title;
  final Widget action;

  const QuCupertinoDialog({
    Key key,
    bool isSurfacePainted = true,
    this.title,
    Widget content,
    this.action,
  }) : super(key: key, isSurfacePainted: isSurfacePainted, child: content);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kDialogCornerRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _kBlurAmount, sigmaY: _kBlurAmount),
          child: Container(
            child: Container(
              color: isSurfacePainted ? _kDialogColor : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(padding: EdgeInsets.all(16), child: title),
                  Padding(padding: EdgeInsets.all(16), child: child),
                  action,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
