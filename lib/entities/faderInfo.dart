import 'package:collection/collection.dart';
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/util.dart';

abstract class FaderInfo {
  final int id; // global id
  final int displayId; // id that would be displayed on screen
  final String technicalName; // not user defined name for this entity
  final String name; // user defined name (in mixer console) for this entity
  final FaderInfoCategory category; // category (like drum, git, key, voc, ...)
  final String personName; // name of the musician or null
  final bool explicitMuteOn; // Explicitly muted on the console
  final UnmodifiableSetView<ControlGroup> controlGroups; // DCA or Mute Groups

  FaderInfo(
    this.id,
    this.displayId,
    this.technicalName,
    this.name,
    this.personName,
    this.explicitMuteOn,
    Set<ControlGroup> controlGroups,
  )   : this.controlGroups = unmodifiableSet<ControlGroup>(controlGroups),
        this.category = _categoryForName(name);

  static FaderInfoCategory _categoryForName(String name) {
    final categories = [
      FaderInfoCategory.Drum,
      FaderInfoCategory.String,
      FaderInfoCategory.Key,
      FaderInfoCategory.Voc,
      FaderInfoCategory.Guide,
      FaderInfoCategory.Speaker,
      FaderInfoCategory.Aux,
    ];
    final names = [
      ["drum", "kick", "snar", "tom", "hi-hat", "hihat", "crash", "ride"],
      ["git", "guit", "base", "bass", "cello"],
      ["key", "pad", "piano", "organ", "syn"],
      ["voc", "vox", "v"],
      ["click", "met", "metr", "guide", "tb", "talk"],
      ["mic", "hand", "speak"],
      ["aux", "phone", "pc", "cd", "handy", "cinch"]
    ];
    name = name.toLowerCase();
    for (int i = 0; i < categories.length; i++) {
      if (names[i].any((value) => name.contains(value))) {
        return categories[i];
      }
    }
    return FaderInfoCategory.Unknown;
  }

  bool get stereo;

  // Either explicitly muted or muted through a group
  bool get muted => explicitMuteOn || controlGroups.any((cg) => cg.muteOn);

  FaderInfo copyWith({
    String name,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  });
}

enum FaderInfoCategory { Drum, String, Key, Voc, Guide, Speaker, Aux, Unknown }
