import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/faderLevelPanModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/util.dart';
import 'package:qu_me/widget/dialogSelectMix.dart';
import 'package:qu_me/widget/fader.dart';
import 'package:qu_me/widget/groupWheel.dart';
import 'package:qu_me/widget/pageLogin.dart';
import 'package:qu_me/widget/pageSends.dart';
import 'package:qu_me/widget/quCheckButton.dart';

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

  var wheelActive = false;
  var activeWheelGroupId = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () => logout(),
      child: Stack(
        children: [
          ValueListenableBuilder2<int, QuConnectionState>(
            mainSendMixModel.currentMixIdNotifier,
            connectionModel.connectionStateListenable,
            builder: (context, currentMixId, state, appBar) {
              final mixSelected = currentMixId != null;
              final loading = state == QuConnectionState.LOADING_SCENE;
              final disabled = loading || !mixSelected;
              return PlatformScaffold(
                appBar: appBar,
                body: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    AnimatedOpacity(
                      opacity: disabled ? 0.3 : 1,
                      duration: Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: disabled,
                        child: buildBody(currentMixId),
                      ),
                    ),
                    if (loading) PlatformCircularProgressIndicator(),
                    if (!mixSelected)
                      Text(
                        QuLocalizations.get(Strings.MixSelectHint),
                        textScaleFactor: 1.8,
                        style: theme.textTheme.caption,
                      )
                  ],
                ),
              );
            },
            child: buildAppBar(),
          ),
          if (activeWheelGroupId != -1)
            AnimatedOpacity(
              child: IgnorePointer(child: PageSends(activeWheelGroupId)),
              opacity: wheelActive ? 0.4 : 0,
              duration: Duration(milliseconds: 500),
            ),
        ],
      ),
    );
  }

  void onWheelChanged(int groupId, double delta) {
    if (wheelActive == false) {
      setState(() {
        activeWheelGroupId = groupId;
        wheelActive = true;
      });
    }
    if (wheelActive && activeWheelGroupId == groupId) {
      final sends = groupModel.getSendIdsForGroup(groupId);
      levelPanModel.onTrim(sends, delta);
    }
  }

  void onWheelReleased(int id) {
    if (activeWheelGroupId == id && wheelActive) {
      setState(() => wheelActive = false);
    }
  }

  void showSelectMixDialog() {
    showPlatformDialog(
      context: context,
      androidBarrierDismissible: true,
      builder: (BuildContext context) => DialogSelectMix(),
    );
  }

  void showSendsPage() {
    Navigator.of(context).push(
      platformPageRoute<void>(
        builder: (context) => PageSends(4),
        context: context,
      ),
    );
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

  Widget buildAppBar() {
    return PlatformAppBar(
      title: ValueListenableBuilder<Mixer>(
        valueListenable: connectionModel.mixerListenable,
        builder: (BuildContext context, Mixer mixer, _) {
          return Text(mixer?.name ?? "");
        },
      ),
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
          onPressed: () => showSelectMixDialog(),
        ),
      ],
    );
  }

  Widget buildBody(int mixId) {
    final group = buildGroup;
    final mixListenable = mainSendMixModel.getMixListenableForId(mixId);

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        List<Widget> items;
        if (orientation == Orientation.landscape) {
          items = [group(0), group(1), group(2), group(3)];
        } else {
          items = [
            Expanded(child: Column(children: [group(0), group(2)])),
            Expanded(child: Column(children: [group(1), group(3)])),
          ];
        }
        return Padding(
          child: Row(
            children: <Widget>[
              ...items,
              ValueListenableBuilder<FaderInfo>(
                valueListenable: mixListenable ?? ValueNotifier(Mix.empty()),
                builder: (BuildContext context, FaderInfo info, _) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      children: [
                        buildDebugSwitchPlatformButton(),
                        buildMuteButton(info),
                        Expanded(
                          child: VerticalFader(info, false,
                              forceDisplayTechnicalName: true,
                              doubleTap: showSendsPage),
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
          padding: const EdgeInsets.all(4),
        );
      },
    );
  }

  Widget buildGroup(int groupId) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GroupWheel(groupId, onWheelChanged, onWheelReleased),
      ),
    );
  }

  Widget buildMuteButton(FaderInfo info) {
    return QuCheckButton.simpleText(
      QuLocalizations.get(Strings.Mute),
      selected: info.explicitMuteOn,
      width: 72.0,
      onSelect: () => mainSendMixModel.toogleMute(info.id),
      margin: EdgeInsets.only(bottom: 8),
      checkColor: quTheme.mutedButtonColor,
      disabled: info.id == -1,
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
