import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/widget/quCheckButton.dart';
import 'package:qu_me/widget/quDialog.dart';
import 'package:qu_me/widget/util/consumerUtil.dart';

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
      content: MultiProvider(
        providers: [
          ChangeNotifierProvider<ValueNotifier<List<int>>>.value(
              value: mixModel.availableMixIdsNotifier),
          ChangeNotifierProvider<ValueNotifier<int>>.value(
              value: mixModel.currentMixIdNotifier),
        ],
        child: ValueNotifierConsumer<List<int>>(
          builder: (context, availableMixIds, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: availableMixIds
                  .map(
                    (id) => ChangeNotifierProvider<ValueNotifier<Mix>>.value(
                      value: mixModel.getMixNotifierForId(id),
                      child: MultiValueNotifierConsumer<Mix, int>(
                          builder: buildItem),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
      action: cancelAction,
    );
  }

  Widget buildItem(BuildContext context, Mix mix, int currentMixId, _) {
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
