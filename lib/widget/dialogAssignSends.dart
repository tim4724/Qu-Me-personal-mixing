import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/entities/send.dart';

class DialogAssignSends extends StatelessWidget {
  final int currentGroupId;
  final MixingModel mixingModel = MixingModel();

  DialogAssignSends(this.currentGroupId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentGroup = mixingModel.getGroup(currentGroupId);
    return AlertDialog(
      title: Text('Assign to ${currentGroup.technicalName}'),
      content: Selector<MixingModel, List<Send>>(
        selector: (context, model) => model.availableSends,
        builder: (context, sends, child) {
          return SingleChildScrollView(
            child: Wrap(
              runSpacing: 0,
              spacing: 8.0,
              alignment: WrapAlignment.spaceEvenly,
              children: sends.map((send) => buildSendChild(send)).toList(),
            ),
          );
        },
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actions: <Widget>[
        FlatButton(
          child: Text('Done'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      backgroundColor: const Color.fromARGB(200, 21, 21, 21),
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
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 6),
              child: ChoiceChip(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                labelPadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                label: SizedBox(
                  width: 50,
                  height: 34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        send.name,
                        minFontSize: 8,
                        maxFontSize: 16,
                        style: const TextStyle(color: Colors.white),
                      ),
                      AutoSizeText(
                        send.sendType != SendType.fxReturn
                            ? send.personName
                            : send.technicalName,
                        minFontSize: 8,
                        maxFontSize: 16,
                        textScaleFactor: 0.8,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                selected: isInCurrentGroup,
                selectedColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                onSelected: (bool selected) {
                  if (selected) {
                    mixingModel.assignSend(currentGroupId, send.id);
                  } else {
                    mixingModel.unassignSend(currentGroupId, send.id);
                  }
                },
              ),
            ),
            if (group != null)
              Positioned(
                right: 0,
                bottom: 2,
                child: CircleAvatar(
                  child: Padding(
                    padding: EdgeInsets.all(3),
                    child: AutoSizeText(
                      group.displayId,
                      minFontSize: 8,
                      maxFontSize: 20,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  backgroundColor: Colors.grey.withAlpha(200),
                  radius: 12,
                ),
              ),
          ],
        );
      },
    );
  }
}
