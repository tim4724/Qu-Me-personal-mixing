import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:quiver/collection.dart';

class MainSendMixModel {
  static final MainSendMixModel _instance = MainSendMixModel._internal();

  factory MainSendMixModel() => _instance;

  // Not so sure if the list of available mix-ids can change??
  final availableMixIdsNotifier = ValueNotifier(List<int>());

  final _mixNotifiers = List<ValueNotifier<Mix>>();
  final _sendNotifiers = List<ValueNotifier<Send>>();
  final currentMixIdNotifier = ValueNotifier<int>(null);

  // TODO: maybe improve control group managent?
  final _allControlGroups = ListMultimap<ControlGroupType, ControlGroup>();

  MainSendMixModel._internal();

  void initControlGroups(List<ControlGroup> controlGroups) {
    _allControlGroups.clear();
    controlGroups.forEach((group) {
      _allControlGroups.add(group.type, group);
    });
  }

  void initMixes(List<Mix> mixes) {
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
    if (currentMixIdNotifier.value != null &&
        !availableMixIds.contains(currentMixIdNotifier.value)) {
      currentMixIdNotifier.value = null;
    }
  }

  void initSends(List<Send> sends) {
    _sendNotifiers.length = sends.length;
    for (final send in sends) {
      if (_sendNotifiers[send.id] == null) {
        _sendNotifiers[send.id] = ValueNotifier<Send>(null);
      }
      _sendNotifiers[send.id].value = send;
    }
  }

  void selectMix(int id) {
    currentMixIdNotifier.value = id;
    final index = id - _mixNotifiers[0].value.id;
    network.changeSelectedMix(id, index);
  }

  void toogleMute(int id) {
    final faderInfo = _getFaderInfoNotifierForId(id);
    if (faderInfo != null) {
      final muteOn = !faderInfo.value.explicitMuteOn;
      faderInfo.value = faderInfo.value.copyWith(explicitMuteOn: muteOn);
      network.changeMute(id, muteOn);
    }
  }

  void updateControlGroup(int groupId, ControlGroupType type, bool muteOn) {
    final oldGroup = _allControlGroups[type][groupId];
    if (oldGroup.muteOn == muteOn) {
      return;
    }

    final newControlGroup = ControlGroup(groupId, type, muteOn);
    _allControlGroups[type][groupId] = newControlGroup;
    for (final sendNotifier in _sendNotifiers) {
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
      controlGroups.add(_allControlGroups[type][groupId]);
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

  Send getSend(int id) {
    return _sendNotifiers[id].value;
  }

  FaderInfo _getFaderInfo(int id) {
    return _getFaderInfoNotifierForId(id).value;
  }

  ValueNotifier<FaderInfo> _getFaderInfoNotifierForId(int id) {
    final isSend = id < _mixNotifiers[0].value.id;
    return isSend ? getSendNotifierForId(id) : getMixListenableForId(id);
  }

  ValueNotifier<Send> getSendNotifierForId(int sendId) {
    return _sendNotifiers[sendId];
  }

  ValueListenable<Mix> getMixListenableForId(int mixId) {
    if (mixId == null) return null;
    return _mixNotifiers[mixId - _mixNotifiers[0].value.id];
  }

  void reset() {
    // TODO: reset ?
  }

  Mix getCurrentMix() {
    if (currentMixIdNotifier.value == null) {
      return null;
    }
    return getMixListenableForId(currentMixIdNotifier.value).value;
  }

  int get currentMixId => currentMixIdNotifier.value;
}
