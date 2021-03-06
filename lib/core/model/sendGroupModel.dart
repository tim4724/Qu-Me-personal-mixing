import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/entities/group.dart';
import 'package:quiver/collection.dart';

final sendGroupModel = SendGroupModel._internal();

class SendGroupModel extends ChangeNotifier {
  final _groups = [
    SendGroup(0, SendGroupType.Custom),
    SendGroup(1, SendGroupType.Custom),
    SendGroup(2, SendGroupType.Custom),
    SendGroup(3, SendGroupType.Me),
    SendGroup(4, SendGroupType.All)
  ];
  final _assignement = _GroupAssignement();
  final availableSendIds = List<int>();

  SendGroupModel._internal();

  void initAvailableSends(List<int> sendIds) {
    availableSendIds.clear();
    availableSendIds.addAll(sendIds);
    // remove send from group if the send is not available anymore
    for (final sendId in _assignement.getAllSendIds()) {
      // TODO: not the best performance probably
      if (!sendIds.contains(sendId)) {
        _assignement.unset(sendId);
      }
    }
    notifyListeners();
  }

  void updateAvailabilitySend(int sendId, bool available) {
    if (!available) {
      availableSendIds.remove(sendId);
      _assignement.unset(sendId);
    } else if (available && !availableSendIds.contains(sendId)) {
      availableSendIds.add(sendId);
      availableSendIds.sort();
    }
    notifyListeners();
  }

  List<int> getSendIdsForGroup(int groupId) {
    if (_groups[groupId].sendGroupType == SendGroupType.All) {
      // This group contains all available sends
      return UnmodifiableListView(availableSendIds);
    }
    return UnmodifiableListView(_assignement.getSendIds(groupId));
  }

  SendGroup getGroupForSendId(int sendId) {
    final groupId = _assignement.getGroupId(sendId);
    return groupId != null ? _groups[groupId] : null;
  }

  void toggleSendAssignement(int groupId, int sendId) {
    if (_assignement.getGroupId(sendId) != groupId) {
      _assignement.set(groupId, sendId);
    } else {
      _assignement.unset(sendId);
    }
    notifyListeners();
  }

  static int getLinkedId(int sendId) {
    return sendId % 2 == 0 ? sendId + 1 : sendId - 1;
  }

  SendGroup getGroup(int id) {
    return _groups[id];
  }

  String getGroupShortNameForId(int groupId) {
    return getGroupShortName(_groups[groupId]);
  }

  static String getGroupTechnicalName(SendGroup group) {
    if (group != null) {
      switch (group.sendGroupType) {
        case SendGroupType.Custom:
          return QuLocalizations.get(Strings.Group, ["${group.id + 1}"]);
        case SendGroupType.Me:
          return QuLocalizations.get(Strings.Me);
        case SendGroupType.All:
          return QuLocalizations.get(Strings.All);
      }
    }
    return "";
  }

  static String getGroupShortName(SendGroup group) {
    if (group != null) {
      switch (group.sendGroupType) {
        case SendGroupType.Custom:
          return "${group.id + 1}";
        case SendGroupType.Me:
          return QuLocalizations.get(Strings.Me);
        case SendGroupType.All:
          return QuLocalizations.get(Strings.All);
      }
    }
    return "";
  }

  void setGroupName(int id, String name) {
    _groups[id] = _groups[id].copyWithNewName(name.trim());
    notifyListeners();
  }
}

class _GroupAssignement {
  final _sendIdsForGroupId = ListMultimap<int, int>();
  final _groupIdForSendId = Map<int, int>();

  void set(int groupId, int sendId) {
    _sendIdsForGroupId.remove(_groupIdForSendId[sendId], sendId);
    _sendIdsForGroupId.add(groupId, sendId);
    _sendIdsForGroupId[groupId].sort();
    _groupIdForSendId[sendId] = groupId;
  }

  void unset(int sendId) {
    final groupId = _groupIdForSendId[sendId];
    if (groupId != null) {
      _groupIdForSendId.remove(sendId);
      _sendIdsForGroupId.remove(groupId, sendId);
    }
  }

  List<int> getSendIds(int groupId) {
    return _sendIdsForGroupId[groupId];
  }

  int getGroupId(int sendId) {
    return _groupIdForSendId[sendId];
  }

  List<int> getAllSendIds() {
    return _sendIdsForGroupId.values.toList();
  }
}
