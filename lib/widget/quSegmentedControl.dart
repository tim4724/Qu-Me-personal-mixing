import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class QuSegmentedControl<T> extends StatelessWidget {
  final Map<T, String> items;
  final T selectionIndex;
  final double minWidth;
  final ValueChanged<T> onValueChanged;

  QuSegmentedControl({
    Key key,
    @required this.items,
    @required this.onValueChanged,
    this.minWidth = 96,
    this.selectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Map<T, Widget> children = {};
    return PlatformWidget(
      android: (context) {
        items.forEach((index, item) {
          children[index] = Padding(
            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: Text(
                item,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
          );
        });
        // Also use the cupertino widget on android, because it looks good
        // But change colors, padding and font-weight, so nobody notices
        return CupertinoSlidingSegmentedControl<T>(
          children: children,
          groupValue: selectionIndex,
          thumbColor: theme.accentColor,
          onValueChanged: onValueChanged,
          padding: EdgeInsets.all(0.0),
        );
      },
      ios: (context) {
        items.forEach((index, item) {
          children[index] = ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Text(item, textAlign: TextAlign.center),
          );
        });
        return CupertinoSlidingSegmentedControl<T>(
          children: children,
          groupValue: selectionIndex,
          onValueChanged: onValueChanged,
        );
      },
    );
  }
}
