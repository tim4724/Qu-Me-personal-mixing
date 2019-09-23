import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/core/mixingModel.dart';

class DialogSelectMix extends StatelessWidget {
  final mixingModel = MixingModel();

  @override
  Widget build(BuildContext context) {
    final currentMix = mixingModel.currentMix;
    final mixes = mixingModel.availableMixes;
    final children = List<Widget>();

    for (int i = 0; i < mixes.length; i++) {
      children.add(
        PlatformDialogAction(
          onPressed: () {
            mixingModel.selectMix(i);
            Navigator.of(context).pop();
          },
          child: Row(
            children: [
              (mixes[i].id == currentMix.id)
                  ? Icon(Icons.check)
                  : Icon(Icons.remove),
              Expanded(child: Text(" ${mixes[i].technicalName}")),
              Text(mixes[i].name, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
      if (i < mixes.length - 1) {
        children.add(const Divider(color: Colors.black));
      }
    }

    return PlatformAlertDialog(
      title: Text('Select Mix'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
