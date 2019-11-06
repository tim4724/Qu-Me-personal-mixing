import 'dart:ui';

import 'package:flutter/services.dart';

final Map<String, Image> imageCache = {};

Future<Image> loadImage(String asset) async {
  if (!imageCache.containsKey(asset)) {
    ByteData data = await rootBundle.load(asset);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List());
    FrameInfo fi = await codec.getNextFrame();
    imageCache[asset] = fi.image;
  }
  return imageCache[asset];
}
