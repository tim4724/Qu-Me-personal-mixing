import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/io/network.dart' as network;

final connectionModel = ConnectionModel._internal();

class ConnectionModel {
  final _mixerNotifier = ValueNotifier<Mixer>(null);
  final _connectionStateNotifier =
      ValueNotifier<QuConnectionState>(QuConnectionState.NOT_CONNECTED);

  ConnectionModel._internal();

  void connect(String name, InternetAddress address) {
    if (connectionState == QuConnectionState.NOT_CONNECTED) {
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

  void onConnecting() {
    _connectionStateNotifier.value = QuConnectionState.CONNECTING;
  }

  void onLoadingScene() {
    _connectionStateNotifier.value = QuConnectionState.LOADING_SCENE;
  }

  void onReady() {
    _connectionStateNotifier.value = QuConnectionState.READY;
  }

  void onConnectionLost() {
    _connectionStateNotifier.value = QuConnectionState.NOT_CONNECTED;
  }

  int get type => _mixerNotifier.value?.mixerType;

  ValueListenable<Mixer> get mixerListenable => _mixerNotifier;

  ValueListenable<QuConnectionState> get connectionStateListenable {
    return _connectionStateNotifier;
  }

  Mixer get mixer => _mixerNotifier.value;

  QuConnectionState get connectionState => connectionStateListenable.value;

  void reset() {
    _mixerNotifier.value = null;
    _connectionStateNotifier.value = QuConnectionState.NOT_CONNECTED;
  }
}

enum QuConnectionState { NOT_CONNECTED, CONNECTING, LOADING_SCENE, READY }
