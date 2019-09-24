import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuCheckButton extends StatelessWidget {
  final bool selected;
  final Widget child;
  final Function onSelect;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double width;
  final double height;
  final Color checkColor;

  QuCheckButton({
    this.selected,
    this.child,
    this.onSelect,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.all(8),
    this.width,
    this.height,
    this.checkColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Padding(
        padding: margin,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          child: child,
          decoration: BoxDecoration(
            color: selected ? checkColor : Colors.grey,
            borderRadius: const BorderRadius.all(
              Radius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
