import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/core/personalMixingModel.dart';

class SelectMixDialog extends StatelessWidget {
  final mixingModel = MixingModel();

  @override
  Widget build(BuildContext context) {
    final currentMix = mixingModel.currentMix;
    final mixes = mixingModel.availableMixes;
    final children = List<Widget>();

    for (int i = 0; i < mixes.length; i++) {
      children.add(
        SimpleDialogOption(
          onPressed: () {
            mixingModel.onMixSelected(i);
            Navigator.of(context).pop();
          },
          child: Row(
            children: [
              (mixes[i] == currentMix) ? Icon(Icons.check) : Icon(Icons.remove),
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

    return AlertDialog(
      title: const Text('Select Mix'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
