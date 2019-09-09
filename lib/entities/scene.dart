import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/send.dart';

class Scene {
  final List<Send> sends;
  final List<Mix> mixes;

  Scene(this.sends, this.mixes);

  @override
  String toString() {
    return 'Scene{sends: $sends, mixes: $mixes}';
  }
}
