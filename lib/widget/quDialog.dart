import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class QuDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget action;

  QuDialog({this.title, this.body, this.action});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      android: (context) => buildMaterialDialog(),
      ios: (context) => QuCupertinoDialog(title, body, action),
    );
  }

  Widget buildMaterialDialog() {
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(child: body),
      ),
      contentPadding: EdgeInsets.fromLTRB(24, 12, 24, action == null ? 12 : 0),
      actions: <Widget>[action],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    );
  }
}

class QuCupertinoDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget action;

  const QuCupertinoDialog(this.title, this.body, this.action, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyPaddingBot = action != null ? 0.0 : 24.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 655),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: theme.dialogBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                        child: Text(title, style: (theme.textTheme.title)),
                      ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: body,
                        padding: EdgeInsets.fromLTRB(24, 8, 24, bodyPaddingBot),
                      ),
                    ),
                    if (action != null) action
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
