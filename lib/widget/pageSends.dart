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
  final bool isOverlay;

  PageSends(this.groupId, {this.isOverlay: false, Key key}) : super(key: key);

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
      final hintText = QuLocalizations.get(Strings.SendGroupName);
      titleWidget = Container(
        width: 120.0,
        child: PlatformTextField(
          maxLines: 1,
          maxLength: 12,
          android: (context) => MaterialTextFieldData(
            decoration: InputDecoration(
                hintText: hintText, counterText: "", isDense: true),
          ),
          ios: (context) => CupertinoTextFieldData(placeholder: hintText),
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

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: titleWidget,
        trailingActions: trailingActions,
        ios: (context) => CupertinoNavigationBarData(
          // to avoid flutter exception
          transitionBetweenRoutes: !widget.isOverlay,
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) =>
            buildBody(context, orientation, group),
      ),
    );
  }

  Widget buildBody(
      BuildContext context, Orientation orientation, SendGroup group) {
    final landscape = orientation == Orientation.landscape;
    final stereoMix = mainSendModel.getCurrentMix()?.mixType == MixType.stereo;
    const levelPanSwitchInputHeight = 32.0;

    final mediaQuery = MediaQuery.of(context);

    EdgeInsets listWidgetPadding = mediaQuery.padding;
    if (stereoMix) {
      // We need some padding for the button to switch between panning and level
      if (landscape) {
        listWidgetPadding += EdgeInsets.only(left: levelPanSwitchInputHeight);
      } else {
        listWidgetPadding += EdgeInsets.only(top: levelPanSwitchInputHeight);
      }
    }

    // Group assignment can change, therefore use this animated list
    final buildListItem = (context, int sendId, i, Animation<double> anim) {
      return buildAnimatedFader(anim, sendId, landscape);
    };

    final theme = Theme.of(context);
    return Selector<SendGroupModel, List<int>>(
      selector: (_, model) {
        // TODO: Lists are, by default, only equal to themselves. Even if other is also a list,
        // the equality comparison does not compare the elements of the two lists.
        return List.from(model.getSendIdsForGroup(widget.groupId));
      },
      builder: (BuildContext context, List<int> sendIds, Widget child) {
        final list = DeclarativeList(
          padding: listWidgetPadding,
          items: sendIds,
          scrollDirection: landscape ? Axis.horizontal : Axis.vertical,
          itemBuilder: buildListItem,
          removeBuilder: buildListItem,
        );
        if (!stereoMix) {
          return list;
        }
        final sendsEmpty = sendIds == null || sendIds.isEmpty;
        return Stack(
          children: [
            list,
            AnimatedOpacity(
              duration: Duration(milliseconds: 400),
              opacity: sendsEmpty ? 0 : 1,
              child: Container(
                padding: landscape
                    ? mediaQuery.padding.copyWith(right: 0)
                    : mediaQuery.padding.copyWith(bottom: 0),
                color: Color(0xE8000000),
                child: RotatedBox(
                  child: Container(
                    width: double.maxFinite,
                    height: levelPanSwitchInputHeight,
                    child: CupertinoSegmentedControl<bool>(
                      children: {
                        false: Text(QuLocalizations.get(Strings.Level)),
                        true: Text(QuLocalizations.get(Strings.Panorama)),
                      },
                      groupValue: panMode,
                      unselectedColor: Color(0xFF111111),
                      borderColor: theme.accentColor,
                      selectedColor: theme.accentColor,
                      padding: EdgeInsets.all(2),
                      onValueChanged: (bool key) {
                        if (!sendsEmpty) setState(() => panMode = key);
                      },
                    ),
                  ),
                  quarterTurns: landscape ? 3 : 0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildAnimatedFader(
      Animation<double> anim, int sendId, bool landscape) {
    final sendNotifier = mainSendModel.getSendNotifierForId(sendId);
    final showTechnicalName = sendNotifier.value.sendType == SendType.fxReturn;
    return FadeTransition(
      opacity: anim,
      child: SizeTransition(
        sizeFactor: anim,
        axis: landscape ? Axis.horizontal : Axis.vertical,
        axisAlignment: 0.0,
        child: Padding(
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
        ),
      ),
    );
  }
}
