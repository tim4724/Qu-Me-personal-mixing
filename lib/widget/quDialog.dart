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
      android: (context) => QuMaterialDialog(title, body, action),
      ios: (context) => QuCupertinoDialog(title, body, action),
    );
  }
}

/// AlertDialog uses InstrinsicWidth for its content which I do not like.
class QuMaterialDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget action;

  QuMaterialDialog(this.title, this.body, this.action, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  title,
                  style: (theme.textTheme.title),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: body,
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ButtonTheme.bar(
                  child: ButtonBar(
                    children: [action],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QuCupertinoDialog extends StatelessWidget {
  //  static const Color _kDialogColor = Color(0x80000000);
  final String title;
  final Widget body;
  final Widget action;

  const QuCupertinoDialog(this.title, this.body, this.action, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 12, 36, 12),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              color: theme.dialogBackgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(title, style: (theme.textTheme.title)),
                      ),
                    body,
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
