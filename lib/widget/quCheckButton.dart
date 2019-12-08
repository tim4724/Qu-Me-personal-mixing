import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qu_me/app/myApp.dart';

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
    this.selected = false,
    this.child,
    this.onSelect,
    this.margin = const EdgeInsets.all(0.0),
    this.padding = const EdgeInsets.all(8.0),
    this.width,
    this.height,
    this.checkColor,
    this.pressedOpacity,
  });

  QuCheckButton.simpleText(
    String text, {
    selected = false,
    onSelect,
    margin = const EdgeInsets.all(0.0),
    padding = const EdgeInsets.all(8.0),
    width,
    height,
    checkColor,
    pressedOpacity,
  })  : child = Text(
          text,
          textAlign: TextAlign.center,
        ),
        selected = selected,
        onSelect = onSelect,
        margin = margin,
        padding = padding,
        width = width,
        height = height,
        checkColor = checkColor,
        pressedOpacity = pressedOpacity;

  @override
  _QuCheckButtonState createState() => _QuCheckButtonState();
}

class _QuCheckButtonState extends State<QuCheckButton> {
  var down = false;

  @override
  Widget build(BuildContext context) {
    final quTheme = MyApp.quTheme;
    Color buttonColor;
    if (widget.selected) {
      buttonColor = widget.checkColor ?? quTheme.buttonCheckColor;
    } else {
      buttonColor = quTheme.buttonColor;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => down = true),
      onTapUp: (_) => setState(() => down = false),
      onTapCancel: () => setState(() => down = false),
      onTap: widget.onSelect,
      child: Padding(
        padding: widget.margin,
        child: AnimatedOpacity(
          opacity: down
              ? widget.pressedOpacity ?? quTheme.buttonPressedOpacity
              : 1.0,
          duration: down ? Duration.zero : const Duration(milliseconds: 100),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            child: DefaultTextStyle(
              style: quTheme.buttonTextStyle,
              child: widget.child,
            ),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: quTheme.borderRadius,
            ),
          ),
        ),
      ),
    );
  }
}
