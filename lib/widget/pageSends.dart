import 'dart:ui';

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
import 'package:qu_me/widget/quSegmentedControl.dart';

import 'dialogAssignSends.dart';

class PageSends extends StatefulWidget {
  final int groupId;
  final bool isOverlay;

  PageSends(this.groupId, {this.isOverlay: false, Key key}) : super(key: key);

  @override
  _PageSendsState createState() => _PageSendsState();
}

class _PageSendsState extends State<PageSends> {
  bool panMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = sendGroupModel.getGroup(widget.groupId);

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
          onChanged: (name) {
            sendGroupModel.setGroupName(widget.groupId, name);
          },
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
              builder: (BuildContext context) {
                return DialogAssignSends(widget.groupId);
              },
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
          // Hide the nearly invisible border because of the pancontrol widget
          border: Border.all(width: 0.0, color: Colors.transparent),
        ),
        android: (context) => MaterialAppBarData(elevation: 0.0),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final landscape = orientation == Orientation.landscape;
          return buildBody(context, landscape, group);
        },
      ),
    );
  }

  Widget buildBody(BuildContext context, bool landscape, SendGroup group) {
    final currentMix = mainSendMixModel.getCurrentMix();
    final stereoMix = currentMix?.mixType == MixType.stereo;

    final panControlHeight = landscape ? 48.0 : 36.0;
    final mediaQuery = MediaQuery.of(context);
    var listWidgetPadding = mediaQuery.padding;
    if (stereoMix) {
      // We need some padding for the button to switch between panning and level
      if (landscape) {
        listWidgetPadding += EdgeInsets.only(left: panControlHeight);
      } else {
        listWidgetPadding += EdgeInsets.only(top: panControlHeight);
      }
    }

    // Group assignment can change, therefore use this animated list
    final buildListItem = (context, int sendId, i, Animation<double> anim) {
      return buildAnimatedFader(anim, sendId, landscape);
    };

    return Selector<SendGroupModel, List<int>>(
      selector: (_, model) {
        // TODO: Lists are, by default, only equal to themselves. Even if other is also a list,
        // the equality comparison does not compare the elements of the two lists.
        return List.from(model.getSendIdsForGroup(widget.groupId));
      },
      builder: (BuildContext context, List<int> sendIds, Widget child) {
        final sendsEmpty = sendIds == null || sendIds.isEmpty;
        return Stack(
          children: [
            if (sendsEmpty)
              Center(
                child: Text(
                  QuLocalizations.get(Strings.SendsEmptyHint),
                  style: Theme.of(context).textTheme.caption,
                  textScaleFactor: 1.6,
                ),
              ),
            DeclarativeList(
                padding: listWidgetPadding,
                items: sendIds,
                scrollDirection: landscape ? Axis.horizontal : Axis.vertical,
                itemBuilder: buildListItem,
                removeBuilder: buildListItem,
                key: ValueKey(widget.groupId)),
            if (stereoMix)
              AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: sendsEmpty ? 0 : 1,
                child: buildPanControl(
                    landscape, panControlHeight, mediaQuery.padding),
              ),
          ],
        );
      },
    );
  }

  Widget buildPanControl(bool landscape, double height, EdgeInsets padding) {
    final controlWidget = RotatedBox(
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(
          top: landscape ? 0.0 : padding.top,
          left: landscape ? padding.bottom : padding.left,
          right: landscape ? padding.top : padding.right,
        ),
        height: height + (landscape ? padding.left : 0.0),
        padding: EdgeInsets.only(top: landscape ? padding.left : 0.0),
        width: double.maxFinite,
        child: QuSegmentedControl<bool>(
          items: {
            false: QuLocalizations.get(Strings.Level),
            true: QuLocalizations.get(Strings.Panorama),
          },
          selectionIndex: panMode,
          onValueChanged: (bool key) => setState(() => panMode = key),
        ),
      ),
      quarterTurns: landscape ? 3 : 0,
    );

    return PlatformWidget(
      ios: (context) {
        final cupertinoTheme = CupertinoTheme.of(context);
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: cupertinoTheme.barBackgroundColor.withAlpha(0xE8),
              child: controlWidget,
            ),
          ),
        );
      },
      android: (context) {
        final theme = Theme.of(context);
        final color = theme.appBarTheme.color ?? theme.primaryColor;
        return Container(
          color: color.withAlpha(0xE8),
          child: controlWidget,
        );
      },
    );
  }

  Widget buildAnimatedFader(Animation<double> anim, int sendId, bool vertical) {
    return FadeTransition(
      opacity: anim,
      child: SizeTransition(
        sizeFactor: anim,
        axis: vertical ? Axis.horizontal : Axis.vertical,
        axisAlignment: 0.0,
        child: buildFader(sendId, vertical),
      ),
    );
  }

  Widget buildFader(int sendId, bool vertical) {
    final sendNotifier = mainSendMixModel.getSendNotifierForId(sendId);
    final showTechnicalName = sendNotifier.value.sendType == SendType.fxReturn;
    return Padding(
      padding: EdgeInsets.all(2.0),
      child: ValueListenableBuilder<FaderInfo>(
        valueListenable: sendNotifier,
        builder: (BuildContext context, FaderInfo faderInfo, _) {
          if (vertical) {
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
