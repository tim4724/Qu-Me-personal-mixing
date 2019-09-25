import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/group.dart';
import 'package:quiver/collection.dart';

class GroupModel extends ChangeNotifier {
  static final GroupModel _instance = GroupModel._internal();

  factory GroupModel() => _instance;

  final _groups = [
    Group(0, "Group 1", "1"),
    Group(1, "Group 2", "2"),
    Group(2, "Group 3", "3"),
    Group(3, "Me", "me")
  ];
  final _assignement = _Assignement();

  GroupModel._internal();

  List<int> getSendIdsForGroup(int groupId) {
    return UnmodifiableListView(_assignement.getIds(groupId));
  }

  Group getGroupForSend(int sendId) {
    final groupId = _assignement.getGroupId(sendId);
    if (groupId != null) {
      return getGroup(groupId);
    }
    return null;
  }

  void toggleSendAssignement(int groupId, int sendId, bool linked) {
    if (_assignement.getGroupId(sendId) == groupId) {
      unassignSend(sendId, linked);
    } else {
      assignSend(groupId, sendId, linked);
    }
  }

  void assignSend(int groupId, int sendId, bool linked) {
    _assignement.set(groupId, sendId);
    if (linked) {
      _assignement.set(groupId, getLinkedId(sendId));
    }
    notifyListeners();
  }

  void unassignSend(int victimId, bool linked) {
    _assignement.unset(victimId);
    final groupId = _assignement.getGroupId(victimId);
    if (linked && groupId != null) {
      final linkedId = getLinkedId(victimId);
      final lastId = _assignement.getIds(groupId).last;
      if (lastId == victimId || lastId == linkedId) {
        // Delay unset, because of animated list bug
        // Bug occures, when two items are removed at the same time,
        // and one of them is the last item in list
        Future.delayed(Duration(milliseconds: 32), () {
          _assignement.unset(linkedId);
          notifyListeners();
        });
      } else {
        _assignement.unset(linkedId);
      }
    }
    notifyListeners();
  }

  int getLinkedId(int sendId) {
    return sendId % 2 == 0 ? sendId + 1 : sendId - 1;
  }

  // TODO setter for group name

  Group getGroup(int id) {
    return _groups[id];
  }
}

class _Assignement {
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

  List<int> getIds(int groupId) {
    return _sendIdsForGroupId[groupId];
  }

  int getGroupId(int sendId) {
    return _groupIdForSendId[sendId];
  }
}
