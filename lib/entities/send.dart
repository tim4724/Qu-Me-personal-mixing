import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/faderInfo.dart';

class Send extends FaderInfo {
  final SendType sendType;

  Send(
    int id,
    this.sendType,
    int displayId,
    String name,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  ) : super(
          id,
          displayId,
          _technicalName(sendType, displayId),
          name,
          personName,
          explicitMuteOn,
          controlGroups,
        );

  static String _technicalName(SendType type, int displayId) {
    switch (type) {
      case SendType.monoChannel:
        return "Ch $displayId";
      case SendType.stereoChannel:
        return "St $displayId";
      case SendType.fxReturn:
        return "FxRet $displayId";
      case SendType.group:
        return "Grp $displayId";
    }
    return "$displayId";
  }

  @override
  bool get stereo => sendType == SendType.stereoChannel;

  @override
  FaderInfo copyWith({
    String name,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  }) {
    return Send(
        this.id,
        this.sendType,
        this.displayId,
        name ?? this.name,
        personName ?? this.personName,
        explicitMuteOn ?? this.explicitMuteOn,
        controlGroups ?? this.controlGroups);
  }
}

enum SendType { monoChannel, stereoChannel, fxReturn, group }
