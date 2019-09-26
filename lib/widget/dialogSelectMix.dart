import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/widget/quCheckButton.dart';
import 'package:qu_me/widget/quDialog.dart';

class DialogSelectMix extends StatelessWidget {
  final mixModel = MainSendMixModel();

  @override
  Widget build(BuildContext context) {
    final cancelAction = PlatformButton(
      child: Text("Cancel"),
      androidFlat: (context) => MaterialFlatButtonData(),
      onPressed: () => Navigator.of(context).pop(),
    );

    return QuDialog(
      title: 'Select Mix',
      content: ValueListenableBuilder<List<int>>(
        valueListenable: mixModel.availableMixIdsNotifier,
        builder: (context, availableMixIds, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: buildChildren(availableMixIds),
        ),
      ),
      action: cancelAction,
    );
  }

  List<Widget> buildChildren(List<int> availableMixIds) {
    return availableMixIds
        .map(
          (id) => AnimatedBuilder(
            animation: Listenable.merge(
              [mixModel.currentMixIdNotifier, mixModel.getMixNotifierForId(id)],
            ),
            builder: (context, _) => buildItem(context, id),
          ),
        )
        .toList();
  }

  Widget buildItem(BuildContext context, int id) {
    final mix = mixModel.getMixNotifierForId(id).value;
    final currentMixId = mixModel.currentMixIdNotifier.value;
    return QuCheckButton(
      onSelect: () {
        mixModel.selectMix(mix.id);
        Navigator.of(context).pop();
      },
      selected: currentMixId == mix.id,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(width: 75, child: Text("${mix.technicalName}", maxLines: 1)),
          Text(mix.name, textAlign: TextAlign.center, maxLines: 1),
          SizedBox(
            width: 75,
            child: Text("Tim", textAlign: TextAlign.end, maxLines: 1),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 8),
    );
  }
}
