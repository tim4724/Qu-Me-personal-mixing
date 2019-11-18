import 'dart:async';

import 'package:flutter/material.dart';

enum Strings {
  AppName,
  Logout,
  Demo,
  MixSelect,
  Mute,
  SendGroupName,
  Assign,
  Level,
  Panorama,
  SendGroupNothingAssigned,
  Left,
  Center,
  Right,
  Cancel,
  Done,
  AssignSendToGroup,
  Group,
  Me,
  All,
}

class QuLocalizations {
  static const Map<Strings, String> _en = {
    Strings.AppName: "Qu Me",
    Strings.Logout: "Logout",
    Strings.Demo: "Demo",
    Strings.MixSelect: "Mix Select",
    Strings.Mute: "Mute",
    Strings.SendGroupName: "Name",
    Strings.Assign: "Assign",
    Strings.Level: "Level",
    Strings.Panorama: "Panorama",
    Strings.SendGroupNothingAssigned: "Nothing Assigned\nDouble Tap",
    Strings.Left: "Left",
    Strings.Center: "Center",
    Strings.Right: "Right",
    Strings.Cancel: "Cancel",
    Strings.Done: "Done",
    Strings.AssignSendToGroup: r"Assign to group $0",
    Strings.Group: r"Group $0",
    Strings.Me: "Me",
    Strings.All: "All",
  };
  static const Map<Strings, String> _de = {
    Strings.AppName: "Qu Me",
    Strings.Logout: "Abmelden",
    Strings.Demo: "Demo",
    Strings.MixSelect: "Mix wählen",
    Strings.Mute: "Mute",
    Strings.SendGroupName: "Name",
    Strings.Assign: "Zuweisen",
    Strings.Level: "Level",
    Strings.Panorama: "Panorama",
    Strings.SendGroupNothingAssigned: "Nichts Zugewiesen\nDoppelt Tippen",
    Strings.Left: "Links",
    Strings.Center: "Mitte",
    Strings.Right: "Rechts",
    Strings.Cancel: "Abbrechen",
    Strings.Done: "Fertig",
    Strings.AssignSendToGroup: r"Zweisen zur Gruppe $0",
    Strings.Group: r"Gruppe $0",
    Strings.Me: "Ich",
    Strings.All: "Alle",
  };

  QuLocalizations._internal();

  static List<String> data = List(Strings.values.length);

  static Future<void> load(Locale locale) async {
    return Future.sync(() {
      _load(locale.languageCode == "de" ? _de : _en);
    });
  }

  static void _load(Map<Strings, String> dataMap) {
    for (var string in Strings.values) {
      data[string.index] = dataMap[string];
    }
  }

  static String get(Strings key, [List<String> args]) {
    String s = data[key.index];
    if (args != null) {
      for (int i = 0, l = args.length; i < l; i++) {
        s = s.replaceFirst(("\$$i"), args[i]);
      }
    }
    return s;
  }

  static List<String> getList(List<Strings> keys) {
    return keys.map((key) => data[key.index]).toList();
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<void> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<void> load(Locale locale) async {
    return QuLocalizations.load(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<void> old) {
    return false;
  }
}
