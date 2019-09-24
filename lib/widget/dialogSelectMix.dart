import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/widget/quCheckButton.dart';
import 'package:qu_me/widget/quDialog.dart';

class DialogSelectMix extends StatelessWidget {
  final mixingModel = MixingModel();

  @override
  Widget build(BuildContext context) {
    final children = mixingModel.availableMixes.map(
      (mix) {
        return Selector<MixingModel, bool>(
          selector: (context, model) => model.currentMix.id == mix.id,
          builder: (context, isCurrentMix, child) => QuCheckButton(
            onSelect: () {
              mixingModel.selectMix(mix.id);
              Navigator.of(context).pop();
            },
            selected: isCurrentMix,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(" ${mix.technicalName}"),
                ),
                Text(mix.name),
                SizedBox(
                  width: 80,
                  child: Text(
                    "Tommy",
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            margin: EdgeInsets.only(bottom: 8),
          ),
        );
      },
    ).toList();
    final action = PlatformButton(
      child: Text("Cancel"),
      androidFlat: (context) => MaterialFlatButtonData(),
      onPressed: () => Navigator.of(context).pop(),
    );

    return QuDialog(
      title: 'Select Mix',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
      action: action,
    );
  }
}
