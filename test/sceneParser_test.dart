import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qu_me/core/sceneParser.dart' as sceneParser;

void main() {
  test("test scene parser", () {
    final file = new File('test_resources/SCENE002.DAT');
    final data = file.readAsBytesSync();
    final scene = sceneParser.parse(data);
    print(scene);
  });

  test("t", () {
      var a = 0x04 | 0x08 << 8;
      print(a);
  });
}
