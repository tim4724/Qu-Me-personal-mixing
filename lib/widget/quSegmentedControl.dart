import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:qu_me/app/myApp.dart';

class QuSegmentedControl<T> extends StatelessWidget {
  final Map<T, Widget> _children;
  final T selectionIndex;
  final ValueChanged<T> onValueChanged;
  final Color unselectedColor;
  final Color selectedColor;
  final Color borderColor;
  final EdgeInsetsGeometry childPadding;

  QuSegmentedControl({
    Key key,
    @required Map<T, Widget> children,
    @required this.onValueChanged,
    this.selectionIndex,
    this.unselectedColor,
    this.selectedColor,
    this.borderColor,
    this.childPadding = EdgeInsets.zero,
  }) : _children = _applyPadding(children, childPadding);

  static Map<T, Widget> _applyPadding<T>(
    Map<T, Widget> children,
    EdgeInsets padding,
  ) {
    Map<T, Widget> paddedChildren = {};
    children.forEach((index, widget) {
      paddedChildren[index] = Padding(padding: padding, child: widget);
    });
    return paddedChildren;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PlatformWidget(
      android: (context) => MaterialSegmentedControl<T>(
        children: _children,
        selectionIndex: selectionIndex,
        horizontalPadding: EdgeInsets.zero,
        verticalOffset: 0,
        unselectedColor: unselectedColor ?? quTheme.itemBackgroundColor,
        borderColor: borderColor ?? theme.accentColor,
        borderRadius: quTheme.itemRadius,
        selectedColor: selectedColor ?? theme.accentColor,
        onSegmentChosen: onValueChanged,
      ),
      ios: (context) => CupertinoSegmentedControl<T>(
        children: _children,
        groupValue: selectionIndex,
        unselectedColor: unselectedColor ?? quTheme.itemBackgroundColor,
        borderColor: borderColor ?? theme.accentColor,
        selectedColor: selectedColor ?? theme.accentColor,
        padding: EdgeInsets.zero,
        onValueChanged: onValueChanged,
      ),
    );
  }
}
