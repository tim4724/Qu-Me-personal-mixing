import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/faderLevelModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/widget/dialogSelectMix.dart';
import 'package:qu_me/widget/fader.dart';
import 'package:qu_me/widget/groupWheel.dart';
import 'package:qu_me/widget/pageGroup.dart';
import 'package:qu_me/widget/pageLogin.dart';
import 'package:qu_me/widget/quCheckButton.dart';

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key);

  final connectionModel = ConnectionModel();
  final mainSendMixModel = MainSendMixModel();
  final faderModel = FaderLevelModel();
  final groupModel = SendGroupModel();

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  var activeWheel = -1;

  @override
  Widget build(BuildContext context) {
    // TODO: fade pagegroup widget
    print("build pageHome");
    // TODO : avoid rebuilding entire widget on wheel scroll
    return WillPopScope(
      onWillPop: () => logout(),
      child: Stack(
        children: [
          if (activeWheel != -1) PageGroup(activeWheel),
          AnimatedOpacity(
            child: PlatformScaffold(
              appBar: PlatformAppBar(
                  title: Text(widget.connectionModel.name),
                  ios: (context) => CupertinoNavigationBarData(
                        leading: CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text('Logout'),
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
                      child: Text('Mix Select'),
                      onPressed: () {
                        showSelectMixDialog();
                      },
                    )
                  ]),
              iosContentPadding: true,
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
      final sends = widget.groupModel.getSendIdsForGroup(groupId);
      widget.faderModel.onTrim(sends, delta);
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
    final route =
        platformPageRoute(builder: (context) => PageLogin(), context: context);
    Navigator.pushReplacement(context, route);
    ConnectionModel().reset();
    widget.mainSendMixModel.reset();
    widget.faderModel.reset();
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
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4),
        child: GroupWheel(groupId, onWheelChanged, onWheelReleased),
      ),
    );
  }

  Widget buildFaderWithMuteButton() {
    final mainSendMixModel = widget.mainSendMixModel;
    return Padding(
      padding: EdgeInsets.all(4),
      // TODO merge listenables?
      child: ValueListenableBuilder(
        valueListenable: mainSendMixModel.currentMixIdNotifier,
        builder: (context, mixId, _) {
          final mixNotifier = mainSendMixModel.getMixNotifierForId(mixId);
          return Column(
            children: [
              ValueListenableBuilder<FaderInfo>(
                valueListenable: mixNotifier,
                builder: (context, info, _) =>
                    buildMuteButton(info.explicitMuteOn),
              ),
              Expanded(
                child: VerticalFader(
                  mixNotifier,
                  false,
                  forceDisplayTechnicalName: true,
                  doubleTap: () => Navigator.of(context).push(
                    platformPageRoute<void>(
                      builder: (context) => PageGroup(4),
                      context: context,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildMuteButton(bool muteOn) {
    return QuCheckButton(
      child: Text("Mute", textAlign: TextAlign.center),
      selected: muteOn,
      width: 72,
      onSelect: () => widget.mainSendMixModel.toogleMixMasterMute(),
      margin: EdgeInsets.only(bottom: 8),
      checkColor: Colors.red,
    );
  }

  void showSelectMixDialog() {
    showPlatformDialog(
      context: context,
      androidBarrierDismissible: true,
      builder: (BuildContext context) => DialogSelectMix(),
    );
  }
}
