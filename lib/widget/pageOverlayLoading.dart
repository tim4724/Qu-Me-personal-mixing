import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/model/connectionModel.dart';

Widget buildLoadingOverlay(BuildContext context, QuConnectionState state) {
  String text;
  if (state == QuConnectionState.LOADING_SCENE) {
    text = QuLocalizations.get(Strings.LoadingScene);
  } else if (state == QuConnectionState.NOT_CONNECTED) {
    text = QuLocalizations.get(Strings.Connecting);
  }
  final theme = Theme.of(context);
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Padding(
        padding: EdgeInsets.all(8),
        child: PlatformCircularProgressIndicator(),
      ),
      if (text != null) Text(text, style: theme.textTheme.caption),
    ],
  );
}
