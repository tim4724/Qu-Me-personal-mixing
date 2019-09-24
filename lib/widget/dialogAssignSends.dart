import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/widget/quCheckButton.dart';

import 'quDialog.dart';

class DialogAssignSends extends StatelessWidget {
  final int currentGroupId;
  final MixingModel mixingModel = MixingModel();

  DialogAssignSends(this.currentGroupId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Selector<MixingModel, List<Send>>(
      selector: (context, model) => model.availableSends,
      builder: (context, sends, child) {
        return SingleChildScrollView(
          child: Wrap(
            runSpacing: 4.0,
            spacing: 8.0,
            alignment: WrapAlignment.spaceEvenly,
            children: sends.map((send) => buildSendChild(send)).toList(),
          ),
        );
      },
    );
    final action = PlatformButton(
      child: Text("Done"),
      androidFlat: (context) => MaterialFlatButtonData(),
      onPressed: () => Navigator.of(context).pop(),
    );

    return QuDialog(
      title: 'Assign to ${mixingModel.getGroup(currentGroupId).technicalName}',
      content: content,
      action: action,
    );
  }

  Widget buildSendChild(Send send) {
    return Selector<MixingModel, Group>(
      selector: (context, model) => model.getGroupForSend(send.id),
      builder: (context, group, child) {
        final isInCurrentGroup = group != null && group.id == currentGroupId;
        return Stack(
          overflow: Overflow.visible,
          children: [
            QuCheckButton(
                selected: isInCurrentGroup,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      send.name,
                      minFontSize: 8,
                      maxLines: 1,
                      maxFontSize: 16,
                    ),
                    AutoSizeText(
                      send.sendType != SendType.fxReturn
                          ? send.personName
                          : send.technicalName,
                      minFontSize: 8,
                      maxLines: 1,
                      maxFontSize: 16,
                      textScaleFactor: 0.7,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                onSelect: () {
                  mixingModel.toggleSendAssignement(currentGroupId, send.id);
                },
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(4)),
            Positioned(
              right: 0,
              bottom: 4,
              child: AnimatedOpacity(
                child: CircleAvatar(
                  child: Padding(
                    padding: EdgeInsets.all(3),
                    child: AutoSizeText(
                      group != null ? group.displayId : "",
                      minFontSize: 8,
                      maxFontSize: 20,
                      style: TextStyle(color: Color(0xFFFFFFFF)),
                    ),
                  ),
                  backgroundColor: Colors.grey.withAlpha(220),
                  radius: 12,
                ),
                duration: Duration(milliseconds: 300),
                opacity: group != null ? 1 : 0,
              ),
            ),
          ],
        );
      },
    );
  }
}
