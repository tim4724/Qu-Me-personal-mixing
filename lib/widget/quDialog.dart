import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class QuConfirmDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget action;

  QuConfirmDialog({this.title, this.content, this.action});

  @override
  Widget build(BuildContext context) {
    return QuConfirmDialog(

    );
  }
}

class QuDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget action;

  QuDialog({this.title, this.content, this.action});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      android: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: content),
        actions: [action],
        contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 0),
      ),
      ios: (context) => QuCupertinoDialog(
        title: Text(title),
        content: content,
        action: action,
      ),
    );
  }
}

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
      padding: EdgeInsets.fromLTRB(36, 12, 36, 12),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kDialogCornerRadius),
          child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: _kBlurAmount, sigmaY: _kBlurAmount),
            child: SingleChildScrollView(
              child: Container(
                color: isSurfacePainted ? _kDialogColor : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (title != null)
                      Padding(padding: EdgeInsets.all(16), child: title),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                      child: child,
                    ),
                    if (action != null) action
                  ],
                ),
              ),
              physics: ClampingScrollPhysics(),
            ),
          ),
        ),
      ),
    );
  }
}
