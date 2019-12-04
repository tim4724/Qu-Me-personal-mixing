import 'package:declarative_animated_list/declarative_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/widget/fader.dart';

import 'dialogAssignSends.dart';

class PageSends extends StatefulWidget {
  final int groupId;

  PageSends(this.groupId, {Key key}) : super(key: key);

  @override
  _PageSendsState createState() => _PageSendsState();
}

class _PageSendsState extends State<PageSends> {
  final groupModel = SendGroupModel();
  final mainSendModel = MainSendMixModel();
  bool panMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = groupModel.getGroup(widget.groupId);

    String groupName = group.name;
    if (groupName == null || groupName.isEmpty) {
      groupName = SendGroupModel.getGroupTechnicalName(group);
    }
    final textController = TextEditingController.fromValue(
      TextEditingValue(
        text: groupName,
        selection: TextSelection.collapsed(offset: groupName.length),
      ),
    );

    Widget titleWidget;
    if (group.sendGroupType == SendGroupType.Custom) {
      titleWidget = Container(
        width: 120.0,
        child: PlatformTextField(
          maxLines: 1,
          maxLength: 12,
          android: (context) => MaterialTextFieldData(
            decoration: InputDecoration(
              hintText: QuLocalizations.get(Strings.SendGroupName),
              counterText: "",
            ),
          ),
          // Needed because on IOS-Platformwidget hardcodes the color black
          style: theme.textTheme.subhead,
          controller: textController,
          onChanged: (name) => groupModel.setGroupName(widget.groupId, name),
        ),
      );
    } else {
      titleWidget = Text(groupName, textAlign: TextAlign.center);
    }

    List<Widget> trailingActions;
    if (group.sendGroupType != SendGroupType.All) {
      trailingActions = [
        PlatformButton(
          padding: EdgeInsets.zero,
          child: Text(QuLocalizations.get(Strings.Assign)),
          androidFlat: (context) => MaterialFlatButtonData(),
          onPressed: () {
            showPlatformDialog(
              context: context,
              androidBarrierDismissible: true,
              builder: (BuildContext context) =>
                  DialogAssignSends(widget.groupId),
            );
          },
        ),
      ];
    }

    return OrientationBuilder(
      builder: (context, orientation) => PlatformScaffold(
        appBar: PlatformAppBar(
          title: titleWidget,
          trailingActions: trailingActions,
          android: (context) => MaterialAppBarData(),
          ios: (context) => CupertinoNavigationBarData(),
        ),
        body: _buildBody(orientation, group),
      ),
    );
  }

  Widget _buildBody(Orientation orientation, SendGroup group) {
    final landscape = orientation == Orientation.landscape;
    final stereoMix = mainSendModel.getCurrentMix()?.mixType == MixType.stereo;
    const levelPanSwitchInputHeight = 32.0;

    EdgeInsets listWidgetPadding;
    if (stereoMix) {
      // We need some padding for the button to switch between panning and level
      if (landscape) {
        listWidgetPadding = EdgeInsets.only(left: levelPanSwitchInputHeight);
      } else {
        listWidgetPadding = EdgeInsets.only(top: levelPanSwitchInputHeight);
      }
    }
    final scrollDirection = landscape ? Axis.horizontal : Axis.vertical;

    Widget Function(List<int>) listBuilder;
    if (group.sendGroupType != SendGroupType.All) {
      // Group assignment can change, therefore use this animated list
      final buildListItem = (context, int sendId, i, Animation<double> anim) {
        return _buildAnimatedFader(anim, sendId, landscape);
      };
      listBuilder = (List<int> sendIds) {
        return DeclarativeList(
          padding: listWidgetPadding,
          items: sendIds,
          scrollDirection: scrollDirection,
          itemBuilder: buildListItem,
          removeBuilder: buildListItem,
        );
      };
    } else {
      // Use the basic simple list. Changes are not animated
      listBuilder = (List<int> sendIds) {
        return ListView.builder(
          padding: listWidgetPadding,
          scrollDirection: scrollDirection,
          itemCount: sendIds.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildFader(sendIds[index], landscape);
          },
        );
      };
    }

    final theme = Theme.of(context);
    return Selector<SendGroupModel, List<int>>(
      selector: (_, model) {
        // TODO: Lists are, by default, only equal to themselves. Even if other is also a list,
        // the equality comparison does not compare the elements of the two lists.
        return List.from(model.getSendIdsForGroup(widget.groupId));
      },
      builder: (BuildContext context, List<int> sendIds, Widget child) {
        if (!stereoMix) {
          return listBuilder(sendIds);
        }
        final sendsEmpty = sendIds == null || sendIds.length == 0;
        return Stack(
          children: [
            listBuilder(sendIds),
            RotatedBox(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 400),
                opacity: sendsEmpty ? 0 : 1,
                child: Container(
                  width: double.maxFinite,
                  height: levelPanSwitchInputHeight,
                  color: Color(0xFF111111),
                  // TODO: make custom segmented control
                  child: CupertinoSegmentedControl<bool>(
                    children: {
                      false: Text(QuLocalizations.get(Strings.Level)),
                      true: Text(QuLocalizations.get(Strings.Panorama)),
                    },
                    groupValue: panMode,
                    unselectedColor: Color(0xFF111111),
                    borderColor: theme.accentColor,
                    selectedColor: theme.accentColor.withAlpha(148),
                    padding: EdgeInsets.all(2),
                    onValueChanged: (bool key) {
                      if (!sendsEmpty) setState(() => panMode = key);
                    },
                  ),
                ),
              ),
              quarterTurns: landscape ? 3 : 0,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedFader(
      Animation<double> anim, int sendId, bool landscape) {
    return FadeTransition(
      opacity: anim,
      child: SizeTransition(
        sizeFactor: anim,
        axis: landscape ? Axis.horizontal : Axis.vertical,
        axisAlignment: 0.0,
        child: _buildFader(sendId, landscape),
      ),
    );
  }

  Widget _buildFader(int sendId, bool landscape) {
    final sendNotifier = mainSendModel.getSendNotifierForId(sendId);
    final showTechnicalName = sendNotifier.value.sendType == SendType.fxReturn;
    return Padding(
      padding: EdgeInsets.all(2.0),
      child: ValueListenableBuilder<FaderInfo>(
        valueListenable: sendNotifier,
        builder: (BuildContext context, FaderInfo faderInfo, _) {
          if (landscape) {
            return VerticalFader(faderInfo, panMode,
                forceDisplayTechnicalName: showTechnicalName);
          } else {
            return HorizontalFader(faderInfo, panMode,
                forceDisplayTechnicalName: showTechnicalName);
          }
        },
      ),
    );
  }
}
