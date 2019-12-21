import 'package:flutter/cupertino.dart';
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

  var activeWheelGroupId = -1;

  // TODO: show loading when scene is loading
  // TODO: show something, when mix is not selected
  @override
  Widget build(BuildContext context) {
    // TODO: fade pagegroup widget
    print("build pageHome");

    /*
    final a = AnimatedBuilder(
      animation: Listenable.merge([
        connectionModel.connectionStateListenable,
        mainSendMixModel.currentMixIdNotifier
      ]),
      builder: (BuildContext context, Widget body) {
        final state = connectionModel.connectionState;
        final loading = state == QuConnectionState.LOADING_SCENE;
        final currentMixId = mainSendMixModel.currentMixId;
        final selectedMixIsEmpty = currentMixId != null && currentMixId != -1;
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            body,
            Container(
                constraints: BoxConstraints.expand(),
                decoration: BoxDecoration(
                  color: Color(0xD0000000),
                )),
            if (loading) PlatformCircularProgressIndicator()
          ],
        );
      },
      child: buildBody(),
    );
    */

    // TODO: avoid rebuilding entire widget on wheel scroll
    return WillPopScope(
      onWillPop: () => logout(),
      child: Stack(
        children: [
          if (activeWheelGroupId != -1) PageSends(activeWheelGroupId),
          AnimatedOpacity(
            child: PlatformScaffold(
              appBar: buildAppBar(),
              body: ValueListenableBuilder(
                valueListenable: connectionModel.connectionStateListenable,
                child: buildBody(),
                builder: (context, QuConnectionState state, Widget body) {
                  final loading = state == QuConnectionState.LOADING_SCENE;
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      body,
                      Container(
                        constraints: BoxConstraints.expand(),
                        decoration: BoxDecoration(color: Color(0xD0000000)),
                      ),
                      if (loading) PlatformCircularProgressIndicator()
                    ],
                  );
                },
              ),
            ),
            opacity: activeWheelGroupId != -1 ? 0.4 : 1,
            duration:
                Duration(milliseconds: activeWheelGroupId != -1 ? 500 : 0),
          )
        ],
      ),
    );
  }

  void onWheelChanged(int groupId, double delta) {
    if (activeWheelGroupId == -1) {
      setState(() => activeWheelGroupId = groupId);
    }
    if (activeWheelGroupId == -1 || activeWheelGroupId == groupId) {
      final sends = groupModel.getSendIdsForGroup(groupId);
      levelPanModel.onTrim(sends, delta);
    }
  }

  void onWheelReleased(int id) {
    setState(() {
      if (activeWheelGroupId == id) {
        activeWheelGroupId = -1;
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
        )
      ],
    );
  }

  Widget buildBody() {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return isLandscape ? buildBodyLandscape() : buildBodyPortrait();
      },
    );
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
    final group = groupModel.getGroup(groupId);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GroupWheel(group, onWheelChanged, onWheelReleased),
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
    final quTheme = MyApp.quTheme;
    return QuCheckButton.simpleText(
      QuLocalizations.get(Strings.Mute),
      selected: info.explicitMuteOn,
      width: 72.0,
      onSelect: () {
        mainSendMixModel.changeMute(info.id, !info.explicitMuteOn);
      },
      margin: EdgeInsets.only(bottom: 8),
      checkColor: quTheme.mutedButtonColor,
      disabled: info.id == -1,
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
