import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuCheckButton extends StatelessWidget {
  final bool selected;
  final Widget child;
  final Function onSelect;
  final EdgeInsets margin;
  final EdgeInsets padding;

  QuCheckButton(
      {this.selected,
      this.child,
      this.onSelect,
      this.margin = const EdgeInsets.all(0),
      this.padding = const EdgeInsets.all(8)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: GestureDetector(
        onTap: onSelect,
        child: Container(
          width: 64,
          height: 42,
          padding: padding,
          child: child,
          decoration: BoxDecoration(
              color: selected ? Colors.green : Colors.grey,
              borderRadius: const BorderRadius.all(Radius.circular(4))),
        ),
      ),
    );
  }
}
