import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mixer.dart';

class MixerConnectionModel extends ChangeNotifier {
  static final MixerConnectionModel _instance =
      MixerConnectionModel._internal();

  factory MixerConnectionModel() => _instance;

  Mixer _mixer;

  MixerConnectionModel._internal();

  void onStartConnect(String name, InternetAddress address) {
    _mixer = Mixer(name, address);
    notifyListeners();
  }

  void onMixerVersion(int type, String firmware) {
    _mixer.mixerType = type;
    _mixer.firmwareVersion = firmware;
    notifyListeners();
  }

  InternetAddress get remoteAddress => _mixer?.address;

  get name => _mixer?.name;

  bool get initialized {
    return _mixer?.mixerType != null;
  }

  void reset() {
    _mixer?.mixerType = null;
    notifyListeners();
  }
}
