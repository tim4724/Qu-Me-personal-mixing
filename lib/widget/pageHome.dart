import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/faderLevelPanModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/QuItemColors.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/widget/dialogSelectMix.dart';
import 'package:qu_me/widget/fader.dart';
import 'package:qu_me/widget/groupWheel.dart';
import 'package:qu_me/widget/pageLogin.dart';
import 'package:qu_me/widget/pageSends.dart';
import 'package:qu_me/widget/quCheckButton.dart';
import 'package:qu_me/widget/quTheme.dart';

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key);

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  final connectionModel = ConnectionModel();
  final mainSendMixModel = MainSendMixModel();
  final groupModel = SendGroupModel();
  final levelPanModel = FaderLevelPanModel();

  var activeWheel = -1;

  // TODO: show loading when scene is loading
  // TODO: show something, when mix is not selected

  @override
  Widget build(BuildContext context) {
    // TODO: fade pagegroup widget
    print("build pageHome");
    // TODO : avoid rebuilding entire widget on wheel scroll
    return WillPopScope(
      onWillPop: () => logout(),
      child: Stack(
        children: [
          if (activeWheel != -1) PageSends(activeWheel),
          AnimatedOpacity(
            child: PlatformScaffold(
              appBar: PlatformAppBar(
                // TODO: make reactive
                title: Text(connectionModel.name ?? ""),
                ios: (context) => CupertinoNavigationBarData(
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(QuLocalizations.get(Strings.Logout)),
                    onPressed: () => logout(),
                  ),
                ),
                android: (context) => MaterialAppBarData(
                  leading: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => logout(),
                  ),
                ),
                trailingActions: <Widget>[
                  PlatformButton(
                    androidFlat: (context) => MaterialFlatButtonData(),
                    padding: EdgeInsets.zero,
                    child: Text(QuLocalizations.get(Strings.MixSelect)),
                    onPressed: () {
                      showSelectMixDialog();
                    },
                  )
                ],
              ),
              body: OrientationBuilder(
                builder: (context, orientation) =>
                    orientation == Orientation.landscape
                        ? buildBodyLandscape()
                        : buildBodyPortrait(),
              ),
            ),
            opacity: activeWheel != -1 ? 0.4 : 1,
            duration: Duration(milliseconds: activeWheel != -1 ? 500 : 0),
          ),
        ],
      ),
    );
  }

  void onWheelChanged(int groupId, double delta) {
    if (activeWheel == -1) {
      setState(() {
        activeWheel = groupId;
      });
    }
    if (activeWheel == groupId) {
      final sends = groupModel.getSendIdsForGroup(groupId);
      levelPanModel.onTrim(sends, delta);
    }
  }

  void onWheelReleased(int id) {
    setState(() {
      if (activeWheel == id) {
        activeWheel = -1;
      }
    });
  }

  logout() {
    network.close();
    connectionModel.reset();
    final route = platformPageRoute(
      builder: (context) => PageLogin(),
      context: context,
    );
    Navigator.pushReplacement(context, route);
    mainSendMixModel.reset();
    levelPanModel.reset();
  }

  Widget buildBodyPortrait() {
    return Padding(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buildGroup(0), buildGroup(2)],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buildGroup(1), buildGroup(3)],
            ),
          ),
          buildFaderWithMuteButton()
        ],
      ),
      padding: EdgeInsets.all(4),
    );
  }

  Widget buildBodyLandscape() {
    return Padding(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildGroup(0),
          buildGroup(1),
          buildGroup(2),
          buildGroup(3),
          buildFaderWithMuteButton(),
        ],
      ),
      padding: EdgeInsets.all(4),
    );
  }

  Widget buildGroup(int groupId) {
    final quTheme = QuThemeData.get();
    final group = groupModel.getGroup(groupId);
    QuItemColors colors;
    if(group.sendGroupType == SendGroupType.Me) {
      colors = quTheme.meColors;
    } else {
      colors = quTheme.defaultGroupColors;
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GroupWheel(groupId, colors, onWheelChanged, onWheelReleased),
      ),
    );
  }

  Widget buildFaderWithMuteButton() {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: ValueListenableBuilder<int>(
        valueListenable: mainSendMixModel.currentMixIdNotifier,
        builder: (BuildContext context, int mixId, _) {
          ValueNotifier<Mix> mixNotifier;
          if (mixId == null) {
            mixNotifier = ValueNotifier(Mix.empty());
          } else {
            mixNotifier = mainSendMixModel.getMixNotifierForId(mixId);
          }
          return AnimatedSwitcher(
            child: Container(
              child: ValueListenableBuilder<FaderInfo>(
                valueListenable: mixNotifier,
                builder: (BuildContext context, FaderInfo info, _) {
                  return Column(
                    children: [
                      buildDebugSwitchPlatformButton(),
                      buildMuteButton(info),
                      Expanded(child: buildMixFader(info)),
                    ],
                  );
                },
              ),
              key: ValueKey(mixId),
            ),
            duration: Duration(milliseconds: 400),
          );
        },
      ),
    );
  }

  Widget buildMuteButton(FaderInfo info) {
    final quTheme = QuThemeData.get();
    return QuCheckButton.simpleText(
      QuLocalizations.get(Strings.Mute),
      selected: info.explicitMuteOn,
      width: 72.0,
      onSelect: () {
        if (info.id != -1) {
          mainSendMixModel.changeMute(info.id, !info.explicitMuteOn);
        }
      },
      margin: EdgeInsets.only(bottom: 8),
      checkColor: quTheme.mutedColor,
      // TODO: add disabled state to QuCheckButton
      pressedOpacity: info.id == -1 ? 1.0 : null,
    );
  }

  Widget buildMixFader(FaderInfo info) {
    return VerticalFader(
      info,
      false,
      forceDisplayTechnicalName: true,
      doubleTap: () => Navigator.of(context).push(
        platformPageRoute<void>(
          builder: (context) => PageSends(4),
          context: context,
        ),
      ),
    );
  }

  void showSelectMixDialog() {
    showPlatformDialog(
      context: context,
      androidBarrierDismissible: true,
      builder: (BuildContext context) => DialogSelectMix(),
    );
  }

  Widget buildDebugSwitchPlatformButton() {
    return QuCheckButton.simpleText(
      "Switch Platform",
      width: 72.0,
      onSelect: () {
        ConnectionModel().reset();
        final platformProvider = PlatformProvider.of(context);
        if (platformProvider.platform != TargetPlatform.iOS) {
          platformProvider.changeToCupertinoPlatform();
        } else {
          platformProvider.changeToMaterialPlatform();
        }
      },
      margin: EdgeInsets.only(bottom: 8.0),
    );
  }
}
