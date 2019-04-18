import 'dart:ui';

/// No clue how the "canvas.drawImageNine()" function works.
/// There is no documentation :(
/// I do not want to spend more time, trying to figure things out,
/// or reading the source code
///
/// So I made my own implementation with blackjack and hookers.
/// Was more fun anyway :)
void drawImage9(
    Canvas canvas, Image img, Rect imgCenter, Rect dstCenter, Size dstSize,
    {Paint paint}) {
  if (paint == null) {
    paint = Paint();
  }
  var dstWidth = dstSize.width;
  var dstHeight = dstSize.height;
  var srcWidth = img.width.toDouble();
  var srcHeight = img.height.toDouble();

  // top left
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(0.0, 0.0, imgCenter.left, imgCenter.top),
      Rect.fromLTRB(0.0, 0.0, dstCenter.left, dstCenter.top),
      paint);
  // top
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(imgCenter.left, 0.0, imgCenter.right, imgCenter.top),
      Rect.fromLTRB(dstCenter.left, 0.0, dstCenter.right, dstCenter.top),
      paint);
  // top right
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(imgCenter.right, 0.0, srcWidth, imgCenter.top),
      Rect.fromLTRB(dstCenter.right, 0.0, dstWidth, dstCenter.top),
      paint);
  // left
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(0.0, imgCenter.top, imgCenter.left, imgCenter.bottom),
      Rect.fromLTRB(0.0, dstCenter.top, dstCenter.left, dstCenter.bottom),
      paint);
  //right
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(
          imgCenter.right, imgCenter.top, srcHeight, imgCenter.bottom),
      Rect.fromLTRB(dstCenter.right, dstCenter.top, dstWidth, dstCenter.bottom),
      paint);
  // bottom left
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(0.0, imgCenter.bottom, imgCenter.left, srcHeight),
      Rect.fromLTRB(0.0, dstCenter.bottom, dstCenter.left, dstHeight),
      paint);
  //bottom
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(
          imgCenter.left, imgCenter.bottom, imgCenter.right, srcHeight),
      Rect.fromLTRB(
          dstCenter.left, dstCenter.bottom, dstCenter.right, dstHeight),
      paint);
  //bottom right
  canvas.drawImageRect(
      img,
      Rect.fromLTRB(imgCenter.right, imgCenter.bottom, srcWidth, srcHeight),
      Rect.fromLTRB(dstCenter.right, dstCenter.bottom, dstWidth, dstHeight),
      paint);
}
