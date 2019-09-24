import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:quiver/collection.dart';

import 'connectionModel.dart';
import 'faderModel.dart';

class MixingModel extends ChangeNotifier {
  static final MixingModel _instance = MixingModel._internal();

  factory MixingModel() => _instance;

  final _allMixes = List<Mix>();
  final _sendForId = List<Send>();
  final _availableSends = List<Send>();
  final _groups = [
    Group(0, "Group 1", "1"),
    Group(1, "Group 2", "2"),
    Group(2, "Group 3", "3"),
    Group(3, "Me", "me")
  ];
  final _assignement = _Assignement();
  bool _initialized = false;
  Mix currentMix;

  MixingModel._internal();

  void onScene(Scene scene) {
    _allMixes.clear();
    _allMixes.addAll(scene.mixes);

    if (currentMix == null) {
      // TODO let user select
      currentMix = availableMixes[0];
    }

    _sendForId.clear();
    _sendForId.addAll(scene.sends);

    _availableSends.clear();
    // TODO: What if Mixerconnection is not initialized
    // TODO: Parse which sends are assigned anyway
    if (ConnectionModel().type == MixerType.QU_16) {
      final allSends = scene.sends;
      for (Send send in allSends) {
        if (send.sendType != SendType.monoChannel || send.id < 16) {
          _availableSends.add(send);
        }
      }
    } else {
      // TODO improve
      _availableSends.addAll(scene.sends);
    }
    // TODO update sendsByGroup

    FaderModel faderModel = FaderModel();
    if (currentMix != null) {
      for (int i = 0; i < currentMix.sendLevelsInDb.length; i++) {
        faderModel.onNewFaderLevel(i, currentMix.sendLevelsInDb[i]);
      }
    } else {
      faderModel.reset();
    }
    for (int i = 0; i < scene.mixesLevelInDb.length; i++) {
      faderModel.onNewFaderLevel(i + 39, scene.mixesLevelInDb[i]);
    }
    _initialized = true;
    notifyListeners();
  }

  void selectMix(int id) {
    for (int i = 0; i < _allMixes.length; i++) {
      if (_allMixes[i].id == id) {
        currentMix = _allMixes[i];
        network.mixSelectChanged(currentMix.id, i);
        notifyListeners();
        return;
      }
    }
  }

  void toggleSendAssignement(int groupId, int sendId) {
    if (_assignement.getGroupId(sendId) == groupId) {
      unassignSend(groupId, sendId);
    } else {
      assignSend(groupId, sendId);
    }
  }

  void assignSend(int groupId, int sendId) {
    _assignement.set(groupId, sendId);
    if (_sendForId[sendId].faderLinked) {
      int linkedId = sendId % 2 == 0 ? sendId + 1 : sendId - 1;
      _assignement.set(groupId, linkedId);
    }
    notifyListeners();
  }

  void unassignSend(int groupId, int victimId) {
    _assignement.unset(groupId, victimId);
    if (_sendForId[victimId].faderLinked) {
      int linkedId = victimId % 2 == 0 ? victimId + 1 : victimId - 1;
      _assignement.unset(groupId, linkedId);
    }
    notifyListeners();
  }

  List<Send> getSendsForGroup(int groupId) {
    final sends = List<Send>();
    final ids = _assignement.getIds(groupId);
    if (ids != null) {
      for (int id in ids) {
        if (_sendForId.length > id) {
          sends.add(_sendForId[id]);
        }
      }
      sends.sort((a, b) => a.id - b.id);
    }
    return sends;
  }

  Group getGroupForSend(int sendId) {
    final groupId = _assignement.getGroupId(sendId);
    if (groupId != null) {
      return getGroup(groupId);
    }
    return null;
  }

  Group getGroup(int id) {
    return _groups[id];
  }

  List<Group> get groups => UnmodifiableListView(_groups);

  bool get initialized => _initialized;

  List<Send> get availableSends => UnmodifiableListView(_availableSends);

  List<Mix> get availableMixes => UnmodifiableListView(_allMixes);

  void reset() {
    _initialized = false;
    _sendForId.clear();
    _allMixes.clear();
    _availableSends.clear();
    notifyListeners();
  }
}

class _Assignement {
  final _sendIdsForGroupId = SetMultimap<int, int>();
  final _groupIdForSendId = Map<int, int>();

  void set(int groupId, int sendId) {
    _sendIdsForGroupId.remove(_groupIdForSendId[sendId], sendId);
    _sendIdsForGroupId.add(groupId, sendId);
    _groupIdForSendId[sendId] = groupId;
  }

  void unset(int groupId, int sendId) {
    _groupIdForSendId.remove(sendId);
    _sendIdsForGroupId.remove(groupId, sendId);
  }

  Set<int> getIds(int groupId) {
    return _sendIdsForGroupId[groupId];
  }

  int getGroupId(int sendId) {
    return _groupIdForSendId[sendId];
  }
}
