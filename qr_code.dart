import 'bitmap.dart';
import 'helpers.dart';

void main(){
  QrCodeGenerator qrGen = QrCodeGenerator();

  qrGen.createQrCode('www.oye.com', 2, fileName: 'qrCode');
}

class QrCodeGenerator {

  //https://de.m.wikipedia.org/wiki/Datei:QR_Code_V4_structure_example.svg
  void createQrCode(String message, int version, {String fileName = 'qr_code'}){
    if(version > 5 || version < 2) throw FormatException('Expected version between (2, 5)');

    int dimensions = 17 + 4 * version;

    Bitmap bitmap =  Bitmap.createNew(dimensions, dimensions);
    
    //Setup constant Patterns
    drawPositionMarker(bitmap, version);
    //dont draw for v1
    drawAlignmentPattern(bitmap, version);
    drawSynchronisationMarker(bitmap, version);
    bitmap.drawPixel(8, (4*version)+9); //Dark Spot
    drawFormatString(bitmap, version);
    String data = assembleData(version, message);
    print(message.length);
    print(data.length);
    drawData(bitmap, version, data);
    applyMask(bitmap, version);
    

    bitmap.saveBitmap(fileName + '.pbm');

  }

  void drawPositionMarker(Bitmap bitmap, int version){
    
    int dimensions = 17 + 4 * version;
    //Top-Left
    bitmap.drawRectangle(0, 0, 7, 7, filled: false);
    bitmap.drawRectangle(2, 2, 3, 3);

    //Top-Right
    bitmap.drawRectangle(dimensions-7, 0, 7, 7, filled: false);
    bitmap.drawRectangle(dimensions-5, 2, 3, 3);

    //Bottom-Left
    bitmap.drawRectangle(0, dimensions-7, 7, 7, filled: false);
    bitmap.drawRectangle(2, dimensions-5, 3, 3);
  }

  void drawAlignmentPattern(Bitmap bitmap, int version){

    int dimensions = 17 + 4 * version;
    bitmap.drawRectangle(dimensions - 9, dimensions - 9, 5, 5, filled: false);
    bitmap.drawPixel(dimensions-7, dimensions-7);
  }

  void drawSynchronisationMarker(Bitmap bitmap, int version){
    
    int dimensions = 17 + 4 * version;
    int markerSize = 7;

    for(int i = markerSize + 1; i<dimensions - (markerSize+1); i++){
      (i%2 == 0)? bitmap.drawPixel(i, markerSize-1): bitmap.removePixel(i, markerSize-1);
    }

    for(int i = markerSize + 1; i<dimensions - (markerSize+1); i++){
      (i%2 == 0)? bitmap.drawPixel(markerSize-1, i): bitmap.removePixel(markerSize-1, i);
    }
  }
  
  String assembleData(int version, String message){
    String filledMessage = fillMessage(version, message);
    filledMessage += createErrorCorrectionBits(message, version);

    return filledMessage;
  }

  void drawData(Bitmap bitmap, int version, String data){
    
    int index = data.length - 1;
    int dimensions = 17 + 4 * version;
    int bottomRight = dimensions-1;
    int column = 0;
    int columnPosition = 0;
    int direction = 1;
    int x = bottomRight;
    int y = bottomRight+1;//account for first iteration


    for(int i = 0; i<= index; i++){
      
      bool intersectsTopRight = 
      y - ((columnPosition-1)%2 * direction) < 9 
      && column < 3;

      bool intersectsTopLeft = 
      y - ((columnPosition-1)%2 * direction) < 9 
      && x <= 8;

      bool intersectsBottomLeft = 
      y - ((columnPosition-1)%2 * direction) > bottomRight - 8 
      && x <= 8;

      bool intersectsHorizontalTimingPattern =
      y - ((columnPosition-1)%2 * direction) == 6;

      bool intersectsBottomBorder = 
      y - ((columnPosition-1)%2 * direction) > bottomRight;

      bool intersectsTopBorder = 
      y - ((columnPosition-1)%2 * direction) < 0;

      bool intersectsAlignmentPatternVertically =
      y - ((columnPosition-1)%2 * direction) < dimensions - 4 
      && y - ((columnPosition-1)%2 * direction) > dimensions - 10 
      && column >1 && column <4;

      bool intersectsAlignmentPatternLeftEdge = 
      y - ((columnPosition-1)%2 * direction) < dimensions - 4 
      && y - ((columnPosition-1)%2 * direction) > dimensions - 10 
      && column == 4;

      //switch direction if bordering Position Marker or edge of Code
      if(intersectsTopRight){
        direction = -1;
        y += direction;
        column += 1;
      } else if(intersectsTopLeft){
        direction = -1;
        y += direction;
        column += 1;
      } else if(intersectsBottomLeft){
        direction = 1;
        y += direction;
        column += 1;
      } else if(intersectsBottomBorder){
        direction = 1;
        y += direction;
        column += 1;
      } else if(intersectsTopBorder){
        direction = -1;
        y += direction;
        column += 1;
      }//account for alignmentpattern ignore for V1
      else if(intersectsAlignmentPatternVertically){
        y -= 5 * direction;
      } else if(intersectsHorizontalTimingPattern){
        y -= direction;
      }
      
      
      //Alignment Pattern left is a special case i guess
      if(intersectsAlignmentPatternLeftEdge){
        columnPosition = 1;
        x = bottomRight - columnPosition - column*2;
        y -= (1 * direction);
      } else {
        x = bottomRight - columnPosition - column*2;
        y -= ((columnPosition-1)%2 * direction);
        
      }

      //check after moving the column for simplicity and it works i guess
      bool currentlyIntersectsBottomLeft = y > bottomRight - 8 && x <= 8;
      bool currentlyLeftOfHorizontalTimingPattern = x <= 6;

      //print('X: $x, Y: $y, Column: $column');
      if(currentlyIntersectsBottomLeft){
        y -= 8*direction;
      }//ignore for v1
      if(currentlyLeftOfHorizontalTimingPattern) x-=1;

      columnPosition = (columnPosition==0)? 1 : 0;
      
      if(data[i] == '1') bitmap.drawPixel(x, y);
    }

    //x = bottomRight - (index%2);
    //y = bottomRight - ((index)~/2);
    //print('X: $x, Y: $y');
    //bitmap.drawPixel(x,y);
    //return (x, y);
  }
  
  void drawFormatString(Bitmap bitmap, int version){

    int dimensions = 17 + 4 * version;
     
     bitmap.drawRectangle(0, 8, 3, 1);
     bitmap.drawRectangle(4, 8, 5, 1);
     bitmap.drawPixel(8, 7);
     bitmap.drawPixel(8, 2);

     bitmap.drawLine(8, dimensions -1, 8, dimensions-3);
     bitmap.drawLine(8, dimensions -5, 8, dimensions-7);
     bitmap.drawLine(dimensions -8, 8, dimensions-7, 8);
     bitmap.drawPixel(dimensions - 3, 8);
  }

  void applyMask(Bitmap bitmap, int version){
    int dimensions = 17 + 4 * version;

    

    for(int y= 0; y< dimensions; y++){
      for(int x = 0; x<dimensions; x++){

        bool inTopLeft = y < 9 && x <9;
        bool inTopRight = y < 9 && x > dimensions - 9;
        bool inBottomLeft = y > dimensions - 9 && x < 9;
        bool inAlignmentPattern = y < dimensions - 4 && y > dimensions - 10 && x < dimensions - 4 && x > dimensions - 10;
        bool inTimingpattern = y == 6 || x == 6;
        if((x+y)%2 == 0 && !inTopLeft && !inTopRight && !inBottomLeft && !inAlignmentPattern && !inTimingpattern){
           bitmap.invertPixel(x, y);
        }
      }
    }

  }
}