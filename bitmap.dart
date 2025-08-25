import 'dart:io';
import 'dart:core';

class Bitmap {
  Bitmap({
    required this.data,
    required this.width,
    required this.height,
  }); //3 for header, 2 for space and line break

  int width;
  int height;
  String data;

  /// Gets the given Pixels value 
  int getPixel(int x, int y){
    return int.parse(data[coordinatesToIndex(x, y)]);
  }

  void drawPixel(int x, int y){
    data = data.substring(0, coordinatesToIndex(x, y)) + '1' + data.substring(coordinatesToIndex(x, y)+1);
  }

  void removePixel(int x, int y){
    data = data.substring(0, coordinatesToIndex(x, y)) + '0' + data.substring(coordinatesToIndex(x, y)+1);
  }

  void invertPixel(int x, int y){
    if(data[coordinatesToIndex(x, y)] == '0'){
      drawPixel(x, y);
    } else removePixel(x, y);
  }

  /// Converts Coordinates starting from 0,0 as the top-left Pixel to the corresponding pixels index in the pbm file
  int coordinatesToIndex(int x, int y){
    int index;

    index = x*2 + y*width*2;

    return index;
  }

  void saveBitmap(String path) async {
    String newFile = 'P1\n${width} ${height}\n';

    newFile += data;

    await File(path).writeAsString(newFile);
  }

  static Bitmap createNew(int width, int height){

    String newData = generateEmptyData(width, height);

    return Bitmap(data: newData, width: width, height: height);
  }

  static String generateEmptyData(int width, int height){
    String newData = '';

    for(int i = 1; i<=width*height; i++){
      newData += (i%width == 0)? '0' : '0 ';
      if(i%width == 0) newData += '\n';
    }

    return newData;
  }

  void drawRectangle(int x, int y, int width, int height, {bool filled = true}){
    for(int i = 0; i<width; i++)
      for(int j = 0; j<height; j++)        
      drawPixel(i+x, j+y);
    if(!filled) removeRectangle(x+1, y+1, width-2, height-2);
  }

  void removeRectangle(int x, int y, int width, int height){
    for(int i = 0; i<width; i++)
      for(int j = 0; j<height; j++)        
      removePixel(i+x, j+y);
  }

  void drawLine(int xStart, int yStart, int xEnd, int yEnd) {
    int dx = (xEnd - xStart).abs();
    int dy = (yEnd - yStart).abs();
    int sx = xStart < xEnd ? 1 : -1;
    int sy = yStart < yEnd ? 1 : -1;
    int deviation = dx - dy;

    int x = xStart;
    int y = yStart;

    while (true) {
      drawPixel(x, y);
      if (x == xEnd && y == yEnd) break;
      int e2 = 2 * deviation;
      if (e2 > -dy) {
        deviation -= dy;
        x += sx;
      }
      if (e2 < dx) {
        deviation += dx;
        y += sy;
      }
    }
  }
}
