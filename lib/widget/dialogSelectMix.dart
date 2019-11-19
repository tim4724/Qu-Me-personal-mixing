import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/widget/quCheckButton.dart';
import 'package:qu_me/widget/quDialog.dart';

class DialogSelectMix extends StatelessWidget {
  final mixModel = MainSendMixModel();

  DialogSelectMix();

  @override
  Widget build(BuildContext context) {
    Widget cancelAction;
    if (mixModel.getCurrentMix() != null) {
      cancelAction = PlatformButton(
        child: Text(QuLocalizations.get(Strings.Cancel)),
        androidFlat: (context) => MaterialFlatButtonData(),
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    return QuDialog(
      title: QuLocalizations.get(Strings.MixSelect),
      body: WillPopScope(
        child: ValueListenableBuilder<List<int>>(
          valueListenable: mixModel.availableMixIdsNotifier,
          builder: (context, availableMixIds, child) {
            return SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: buildChildren(availableMixIds),
              ),
            );
          },
        ),
        onWillPop: () {
          return Future.sync(() => mixModel.getCurrentMix() != null);
        },
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
          SizedBox(
            width: 75,
            child: Text(
              "${mix.technicalName}",
              maxLines: 1,
              textScaleFactor: 1.2,
            ),
          ),
          Text(
            mix.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            textScaleFactor: 1,
          ),
          SizedBox(
            width: 75,
            child: Text(
              "Tim",
              textAlign: TextAlign.end,
              maxLines: 1,
              textScaleFactor: 1,
            ),
          ),
        ],
      ),
      margin: const EdgeInsets.only(top: 4.0, bottom: 4.0),
    );
  }
}
