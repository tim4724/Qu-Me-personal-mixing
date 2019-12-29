import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/io/quFind.dart' as quFind;
import 'package:qu_me/widget/pageHome.dart';
import 'package:qu_me/widget/quCheckButton.dart';
import 'package:qu_me/widget/quDialog.dart';

class PageLogin extends StatefulWidget {
  PageLogin({Key key}) : super(key: key);

  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin>
    with WidgetsBindingObserver, quFind.MixerFoundListener {
  // TODO: remove old entries from map?
  final mixers = {
    QuLocalizations.get(Strings.Demo): InternetAddress.loopbackIPv4,
    QuLocalizations.get(Strings.Other): null,
  };
  String connectingToMixerName;

  @protected
  void initState() {
    super.initState();
    connectionModel.connectionStateListenable
        .addListener(onConnectionStateChanged);
    WidgetsBinding.instance.addObserver(this);
    quFind.findQuMixers(this);
  }

  @override
  void dispose() {
    connectionModel.connectionStateListenable
        .removeListener(onConnectionStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    quFind.stop();
    super.dispose();
  }

  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        quFind.findQuMixers(this);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        quFind.stop();
        break;
    }
  }

  @override
  void onMixerFound(String name, InternetAddress address, DateTime time) {
    setState(() => mixers[name] = address);
  }

  void onConnectionStateChanged() {
    switch (connectionModel.connectionState) {
      case QuConnectionState.NOT_CONNECTED:
        if (connectingToMixerName != null) {
          final errorMsg = QuLocalizations.get(Strings.ConnectionFailed);
          showErrorDialog(context, errorMsg);
          setState(() {
            final address = mixers[connectingToMixerName];
            if (address != null && !address.isLoopback) {
              mixers.remove(connectingToMixerName);
            }
            connectingToMixerName = null;
          });
        }
        break;
      case QuConnectionState.CONNECTING:
      case QuConnectionState.LOADING_SCENE:
        setState(() => connectingToMixerName = connectionModel.mixer.name);
        break;
      case QuConnectionState.READY:
        Navigator.of(context).pushReplacement(
          platformPageRoute(builder: (_) => PageHome(), context: context),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: Center(
        child: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            final landscape = orientation == Orientation.landscape;
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flex(
                    direction: landscape ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FlutterLogo(size: landscape ? 32 : 64),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          QuLocalizations.get(Strings.AppName),
                          textScaleFactor: 2,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: quTheme.itemBorderRadius,
                        ),
                        child: ListView.builder(
                          itemCount: mixers.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (BuildContext context, int i) {
                            String name = mixers.keys.elementAt(i);
                            return QuCheckButton.simpleText(
                              name,
                              selected: name == connectingToMixerName,
                              onSelect: () => connect(name),
                              margin: EdgeInsets.only(top: 2, bottom: 2),
                            );
                          },
                        ),
                      ),
                      if (connectingToMixerName != null)
                        PlatformCircularProgressIndicator(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void connect(final String mixerName) {
    InternetAddress mixerAddress = mixers[mixerName];
    if (mixerAddress != null) {
      connectionModel.connect(mixerName, mixerAddress);
    } else {
      showPlatformDialog(
        context: context,
        androidBarrierDismissible: true,
        builder: (BuildContext context) {
          return TextInputQuDialog(
            QuLocalizations.get(Strings.HostnameOrIpAddress),
            (String text) async {
              if (text == null || text.isEmpty) {
                return;
              }
              try {
                mixerAddress = InternetAddress(text);
              } catch (e) {
                try {
                  print("lookup for $text");
                  final addresses = await InternetAddress.lookup(text);
                  mixerAddress = addresses.firstWhere(
                    (a) => a.type == InternetAddressType.IPv4,
                    orElse: () => addresses[0],
                  );
                } catch (e) {
                  print("Ip Lookup for hostname $text failed");
                  showErrorDialog(
                    context,
                    QuLocalizations.get(Strings.HostNotFound, [text]),
                  );
                  return;
                }
              }
              connectionModel.connect(mixerName, mixerAddress);
            },
          );
        },
      );
    }
  }
}
