import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/widget/quTheme.dart';

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
  final bool disabled;

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
    this.disabled = false,
  });

  QuCheckButton.simpleText(
    String text, {
    this.selected = false,
    this.onSelect,
    this.margin = const EdgeInsets.all(0.0),
    this.padding = const EdgeInsets.all(8.0),
    this.width,
    this.height,
    this.checkColor,
    this.pressedOpacity,
        this.disabled = false,
  })  : child = Text(
          text,
          textAlign: TextAlign.center,
        );

  @override
  _QuCheckButtonState createState() => _QuCheckButtonState();
}

class _QuCheckButtonState extends State<QuCheckButton> {
  var down = false;

  QuThemeData get quTheme => MyApp.quTheme;

  @override
  Widget build(BuildContext context) {
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
      onTap: !widget.disabled ? widget.onSelect : null,
      child: Padding(
        padding: widget.margin,
        child: AnimatedOpacity(
          opacity: getOpacity(),
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

  double getOpacity() {
    if(widget.disabled) {
      return quTheme.buttonDisabledOpacity;
    } else if(down) {
      return widget.pressedOpacity ?? quTheme.buttonDisabledOpacity;
    }
    return 1.0;
  }
}
