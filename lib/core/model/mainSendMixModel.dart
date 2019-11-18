import 'package:flutter/widgets.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:quiver/collection.dart';

import 'faderLevelPanModel.dart';
import 'sendGroupModel.dart';

class MainSendMixModel {
  static final MainSendMixModel _instance = MainSendMixModel._internal();

  factory MainSendMixModel() => _instance;

  // Not so sure if the list of available mix-ids can change,
  // yet we wrap the list in a changeNotifier
  final availableMixIdsNotifier = ValueNotifier(List<int>());

  final _mixNotifiers = List<ValueNotifier<Mix>>();

  // TODO: Move to groupModel?
  final _sendNotifierForId = List<ValueNotifier<Send>>();

  final currentMixIdNotifier = ValueNotifier<int>(null);

  final initializedNotifier = ValueNotifier<bool>(false);

  final _availableControlGroups =
      ListMultimap<ControlGroupType, ControlGroup>();

  final _levelPanModel = FaderLevelPanModel();

  MainSendMixModel._internal();

  void onScene(Scene scene) {
    _availableControlGroups.clear();
    for (final group in scene.controlGroups) {
      _availableControlGroups.add(group.type, group);
    }

    _initMixes(scene.mixes);
    _initSends(scene.sends);

    final currentMix = getCurrentMix();
    // TODO: What if ConnectionModel is not initialized
    final mixerType = ConnectionModel().type;
    // TODO: in which class to parse available sends?
    _initAvailableSends(scene.sends, currentMix, mixerType);

    // TODO: in which class to update fader leves
    _levelPanModel.initLinks(scene.faderLevelLinks, scene.faderPanLinks);
    _initFaderLevelsAndPans(currentMix, scene.mixesLevelInDb);

    initializedNotifier.value = true;
  }

  void _initMixes(List<Mix> mixes) {
    // Init mix list
    _mixNotifiers.length = mixes.length;
    for (int i = 0; i < mixes.length; i++) {
      if (_mixNotifiers[i] == null) {
        _mixNotifiers[i] = ValueNotifier<Mix>(null);
      }
      _mixNotifiers[i].value = mixes[i];
    }

    // Init available mix ids list
    final availableMixIds = _mixNotifiers.map((e) => e.value.id).toList();
    availableMixIdsNotifier.value = availableMixIds;

    // Init current mix id
    if (currentMixIdNotifier.value == null ||
        !availableMixIds.contains(currentMixIdNotifier.value)) {
      // TODO let user select
      currentMixIdNotifier.value = availableMixIds.first;
    }
  }

  void _initSends(List<Send> sends) {
    _sendNotifierForId.length = sends.length;
    for (final send in sends) {
      if (_sendNotifierForId[send.id] == null) {
        _sendNotifierForId[send.id] = ValueNotifier<Send>(null);
      }
      _sendNotifierForId[send.id].value = send;
    }
  }

  void _initAvailableSends(List<Send> sends, Mix currentMix, int mixerType) {
    final availableSends = List<int>();
    if (mixerType == MixerType.QU_16) {
      for (Send send in sends) {
        if (currentMix.sendAssigns[send.id] &&
            (send.sendType != SendType.monoChannel || send.id < 16)) {
          availableSends.add(send.id);
        }
      }
    } else {
      // TODO add selection for QU-24, Qu-32 ...
      availableSends.addAll(sends.map((send) => send.id));
    }
    SendGroupModel().initAvailableSends(availableSends);
  }

  void _initFaderLevelsAndPans(Mix currentMix, List<double> mixesLevelInDb) {
    if (currentMix != null) {
      _levelPanModel.initLevelsAndPans(
        currentMix.sendLevelsInDb,
        currentMix.sendPans,
      );
      for (int i = 0; i < currentMix.sendLevelsInDb.length; i++) {
        _levelPanModel.onLevel(i, currentMix.sendLevelsInDb[i]);
        _levelPanModel.onPan(i, currentMix.sendPans[i] ?? 37);
      }
    } else {
      _levelPanModel.reset();
    }

    // Init master fader levels
    for (int i = 0; i < mixesLevelInDb.length; i++) {
      _levelPanModel.onLevel(i + 39, mixesLevelInDb[i]);
    }
  }

  void selectMix(int id) {
    currentMixIdNotifier.value = id;
    final index = id - _mixNotifiers[0].value.id;
    network.mixSelectChanged(id, index);
  }

  void toogleMixMasterMute() {
    final currentMix = getCurrentMix();
    getMixNotifierForId(currentMix.id).value =
        currentMix.copyWith(explicitMuteOn: !currentMix.explicitMuteOn);
    network.muteOnChanged(currentMix.id, !currentMix.explicitMuteOn);
  }

  void updateControlGroup(int groupId, ControlGroupType type, bool muteOn) {
    final oldGroup = _availableControlGroups[type][groupId];
    if (oldGroup.muteOn == muteOn) {
      return;
    }

    final newControlGroup = ControlGroup(groupId, type, muteOn);
    _availableControlGroups[type][groupId] = newControlGroup;
    for (final sendNotifier in _sendNotifierForId) {
      _updateControlGroup(sendNotifier.value, newControlGroup);
    }
    for (final mixNotifier in _mixNotifiers) {
      _updateControlGroup(mixNotifier.value, newControlGroup);
    }
  }

  void _updateControlGroup(FaderInfo faderInfo, ControlGroup newGroup) {
    if (faderInfo.controlGroups
        .any((grp) => grp.id == newGroup.id && grp.type == newGroup.type)) {
      final controlGroups = Set<ControlGroup>.from(faderInfo.controlGroups)
        ..removeWhere((grp) {
          return grp.id == newGroup.id && grp.type == newGroup.type;
        })
        ..add(newGroup);
      updateFaderInfo(faderInfo.id, controlGroups: controlGroups);
    }
  }

  void updateControlGroupAssignment(
      int groupId, ControlGroupType type, int faderId, bool assignOn) {
    final faderInfo = _getFaderInfo(faderId);
    final controlGroups = Set<ControlGroup>.from(faderInfo.controlGroups)
      ..removeWhere((group) => group.id == groupId && group.type == type);
    if (assignOn) {
      controlGroups.add(_availableControlGroups[type][groupId]);
    }
    updateFaderInfo(faderId, controlGroups: controlGroups);
  }

  void updateFaderInfo(int id,
      {String name,
      String personName,
      bool explicitMuteOn,
      Set<ControlGroup> controlGroups}) {
    final faderInfoNotifier = _getFaderInfoNotifierForId(id);
    faderInfoNotifier.value = faderInfoNotifier.value.copyWith(
      name: name,
      personName: personName,
      explicitMuteOn: explicitMuteOn,
      controlGroups: controlGroups,
    );
  }

  void updateSend(int id,
      {String name,
      String personName,
      bool explicitMuteOn,
      Set<ControlGroup> controlGroups}) {
    final sendNotifier = getSendNotifierForId(id);
    sendNotifier.value = sendNotifier.value.copyWith(
        name: name,
        personName: personName,
        explicitMuteOn: explicitMuteOn,
        controlGroups: controlGroups);
  }

  void updateMix(int id,
      {String name,
      String personName,
      bool explicitMuteOn,
      Set<ControlGroup> controlGroups,
      List<double> sendLevelsInDb,
      List<bool> sendAssigns}) {
    final mixNotifier = getMixNotifierForId(id);
    mixNotifier.value = mixNotifier.value.copyWith(
      name: name,
      personName: personName,
      explicitMuteOn: explicitMuteOn,
      sendLevelsInDb: sendLevelsInDb,
      sendAssigns: sendAssigns,
      controlGroups: controlGroups,
    );
  }

  Send getSend(int id) {
    return _sendNotifierForId[id].value;
  }

  FaderInfo _getFaderInfo(int id) {
    return _getFaderInfoNotifierForId(id).value;
  }

  ValueNotifier<FaderInfo> _getFaderInfoNotifierForId(int id) {
    final isSend = id < _mixNotifiers[0].value.id;
    return isSend ? getSendNotifierForId(id) : getMixNotifierForId(id);
  }

  ValueNotifier<Send> getSendNotifierForId(int sendId) {
    return _sendNotifierForId[sendId];
  }

  ValueNotifier<Mix> getMixNotifierForId(int mixId) {
    return _mixNotifiers[mixId - _mixNotifiers[0].value.id];
  }

  void reset() {
    initializedNotifier.value = false;
    // TODO: reset all?
  }

  Mix getCurrentMix() {
    return getMixNotifierForId(currentMixIdNotifier.value).value;
  }
}
