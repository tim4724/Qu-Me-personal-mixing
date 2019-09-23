import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/connectionModel.dart';
import 'package:qu_me/core/faderModel.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/widget/dialogSelectMix.dart';
import 'package:qu_me/widget/fader.dart';
import 'package:qu_me/widget/groupWheel.dart';
import 'package:qu_me/widget/pageGroup.dart';
import 'package:qu_me/widget/pageLogin.dart';

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key) {}

  final connectionModel = ConnectionModel();
  final mixingModel = MixingModel();
  final faderModel = FaderModel();

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  var activeWheel = -1;

  @override
  Widget build(BuildContext context) {
    // TODO: fade pagegroup widget
    print("build pageHome");
    // TODO : avoid rebuilding entire widget
    return WillPopScope(
      onWillPop: () => logout(),
      child: Stack(
        children: [
          if (activeWheel != -1) PageGroup(activeWheel, ""),
          AnimatedOpacity(
            child: PlatformScaffold(
              appBar: PlatformAppBar(
                  title: Text(widget.connectionModel.name),
                  ios: (context) => CupertinoNavigationBarData(
                          leading: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text('Logout'),
                        onPressed: () => logout(),
                      )),
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
              body: SafeArea(
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    final land = orientation == Orientation.landscape;
                    return land ? buildBodyLandscape() : buildBodyPortrait();
                  },
                ),
              ),
            ),
            opacity: activeWheel != -1 ? 0.4 : 1,
            duration: Duration(milliseconds: activeWheel != -1 ? 500 : 0),
          ),
        ],
      ),
    );
  }

  void onWheelChanged(int id, double delta) {
    if (activeWheel == -1) {
      setState(() {
        activeWheel = id;
      });
    }
    if (activeWheel == id) {
      final sends = widget.mixingModel.getSendsForGroup(id);
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
    ConnectionModel().reset();
    widget.mixingModel.reset();
    final route =
        platformPageRoute(builder: (context) => PageLogin(), context: context);
    Navigator.pushReplacement(context, route);
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
          Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              children: [
                PlatformButton(
                  child: Text("Mute"),
                  onPressed: () {
                    final platformProvider = PlatformProvider.of(context);
                    if (platformProvider.platform == TargetPlatform.android) {
                      platformProvider.changeToCupertinoPlatform();
                    } else {
                      platformProvider.changeToMaterialPlatform();
                    }
                  },
                  padding: EdgeInsets.all(0),
                  androidFlat: (context) => MaterialFlatButtonData(),
                ),
                Expanded(child: buildFader()),
              ],
            ),
          ),
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
          Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlatformButton(
                  child: Text("Mute"),
                ),
                buildFader(),
              ],
            ),
          ),
        ],
      ),
      padding: EdgeInsets.all(4),
    );
  }

  Widget buildGroup(int index) {
    final group = widget.mixingModel.getGroup(index);
    final name = group.name;
    final color = Color.fromARGB(128, 0, 0, 0);
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4),
        child: GroupWheel(index, name, color, onWheelChanged, onWheelReleased),
      ),
    );
  }

  Widget buildFader() {
    return Selector<MixingModel, Mix>(
      selector: (_, model) {
        return model.currentMix;
      },
      builder: (_, mix, child) {
        return VerticalFader(mix.id, mix.name, mix.technicalName,
            mix.personName, mix.color, mix.stereo);
      },
    );
  }

  void showSelectMixDialog() {
    showPlatformDialog(
      context: context,
      builder: (BuildContext context) => DialogSelectMix(),
    );
  }
}
