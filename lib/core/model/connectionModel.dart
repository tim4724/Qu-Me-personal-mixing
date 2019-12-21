import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/io/network.dart' as network;

class ConnectionModel {
  static final ConnectionModel _instance = ConnectionModel._internal();

  factory ConnectionModel() => _instance;

  final _mixerNotifier = ValueNotifier<Mixer>(null);
  final _connectionStateNotifier =
      ValueNotifier<QuConnectionState>(QuConnectionState.NOT_CONNECTED);

  ConnectionModel._internal();

  void connect(String name, InternetAddress address) {
    if(connectionState == QuConnectionState.NOT_CONNECTED) {
      _mixerNotifier.value = Mixer(name, address);
      network.connect(name, address);
    }
  }

  void onMixerVersion(int type, String firmware) {
    final mixer = _mixerNotifier.value;
    mixer.mixerType = type;
    mixer.firmwareVersion = firmware;
    _mixerNotifier.value = mixer;
  }

  void onStartLoadingScene() {
    _connectionStateNotifier.value = QuConnectionState.LOADING_SCENE;
  }

  void onFinishedLoadingScene() {
    _connectionStateNotifier.value = QuConnectionState.READY;
  }

  int get type => _mixerNotifier.value?.mixerType;

  ValueListenable<Mixer> get mixerListenable => _mixerNotifier;

  ValueListenable<QuConnectionState> get connectionStateListenable {
    return _connectionStateNotifier;
  }

  QuConnectionState get connectionState => connectionStateListenable.value;

  void reset() {
    _mixerNotifier.value = null;
    _connectionStateNotifier.value = QuConnectionState.NOT_CONNECTED;
  }
}

enum QuConnectionState { NOT_CONNECTED, LOADING_SCENE, READY }
