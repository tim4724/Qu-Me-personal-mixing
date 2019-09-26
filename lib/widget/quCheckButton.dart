import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class QuCheckButton extends StatefulWidget {
  final bool selected;
  final Widget child;
  final Function onSelect;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double width;
  final double height;
  final Color checkColor;
  final double pressedOpacity;

  QuCheckButton({
    this.selected,
    this.child,
    this.onSelect,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.all(8),
    this.width,
    this.height,
    this.checkColor = Colors.green,
    this.pressedOpacity = 0.3,
  });

  @override
  _QuCheckButtonState createState() => _QuCheckButtonState();
}

class _QuCheckButtonState extends State<QuCheckButton> {
  var down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => down = true),
      onTapUp: (_) => setState(() => down = false),
      onTapCancel: () => setState(() => down = false),
      onTap: widget.onSelect,
      child: Padding(
        padding: widget.margin,
        child: AnimatedOpacity(
          opacity: down ? widget.pressedOpacity : 1.0,
          duration: down ? Duration.zero : const Duration(milliseconds: 100),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            child: widget.child,
            decoration: BoxDecoration(
              color: widget.selected ? widget.checkColor : Colors.grey,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }
}
