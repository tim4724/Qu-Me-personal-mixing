import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';

void showErrorDialog(BuildContext context, String body) {
  showInfoDialog(context, QuLocalizations.get(Strings.Error), body);
}

void showInfoDialog(BuildContext context, String title, String body) {
  showPlatformDialog(
    context: context,
    androidBarrierDismissible: true,
    builder: (BuildContext context) {
      return InfoDialog(title, body);
    },
  );
}

class InfoDialog extends StatelessWidget {
  final String title;
  final String body;

  InfoDialog(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title:  Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(title),
      ),
      android: (context) => MaterialAlertDialogData(
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      ),
      content: Text(body),
      actions: <Widget>[
        PlatformDialogAction(
          child: Text(QuLocalizations.get(Strings.Ok)),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }
}

class TextInputQuDialog extends StatelessWidget {
  final String title;
  final String okText;
  final Function doneCallback;

  final textController = TextEditingController();

  TextInputQuDialog(this.title, this.doneCallback, {this.okText});

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(title),
      ),
      android: (context) => MaterialAlertDialogData(
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      ),
      content: PlatformTextField(
        controller: textController,
        autofocus: true,
        style: const TextStyle(),

      ),
      actions: [
        PlatformDialogAction(
          child: Text(QuLocalizations.get(Strings.Cancel)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        PlatformDialogAction(
          child: Text(okText ?? QuLocalizations.get(Strings.Ok)),
          onPressed: () {
            Navigator.of(context).pop();
            doneCallback(textController.text);
          },
        ),
      ],
    );
  }
}

class QuDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;

  QuDialog({
    this.title,
    this.body,
    List<Widget> actions,
  }) : this.actions = actions != null && actions.length > 0 ? actions : null;

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      android: (context) => buildMaterialDialog(),
      ios: (context) => _QuCupertinoDialog(title, body, actions),
    );
  }

  Widget buildMaterialDialog() {
    return AlertDialog(
      title: title != null ? Text(title) : null,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(child: body),
      ),
      contentPadding: EdgeInsets.fromLTRB(24, 12, 24, actions == null ? 12 : 0),
      actions: actions,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    );
  }
}

class _QuCupertinoDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;

  const _QuCupertinoDialog(this.title, this.body, this.actions, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyPaddingBot = actions != null ? 0.0 : 24.0;
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
                    if (actions != null)
                      Row(mainAxisSize: MainAxisSize.min, children: actions)
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
