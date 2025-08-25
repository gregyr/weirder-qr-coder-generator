
void main() {
  //max bits v1 208
  createErrorCorrectionBits('helloworlfad', 1);
}



String stringToASCII(String string){
  //toRadixString converts a number to its base-x (in this case 2) equivalent
  //padLeft adds 0 to the left side of the string to fill it up to 8
  var binstring = string.codeUnits.map((x) => x.toRadixString(2).padLeft(8, '0')).join();

  return binstring;
}

String characterCountAsBinary(int count){
  //toRadixString converts a number to its base-x (in this case 2) equivalent
  //padLeft adds 0 to the left side of the string to fill it up to 8
  var binaryCount = count.toRadixString(2).padLeft(8, '0');

  return binaryCount;
}

String fillMessage(int version, String message){
  //List<int> maxMessageSizes = [17, 32, 53, 78, 106];
    List<int> maxMessageSizes = [17, 32, 53, 78, 106];
    String byteMessage = '';
    String mode = '0100';
    if(message.length > maxMessageSizes[version-1]) throw FormatException('Message exceeded max length of ${maxMessageSizes[version-1]} with a length of ${message.length}');
    byteMessage += mode;
    byteMessage += characterCountAsBinary(message.length);
    byteMessage += stringToASCII(message);
    byteMessage += '0000'; //Terminator of 0s
    if(message.length < maxMessageSizes[version-1]){
      for(int i = 0; i < maxMessageSizes[version-1] - message.length; i++){
        byteMessage += ((i%2==0)? '11101100': '00010001');
      }
    //byteMessage += generateErrorCorrection();
    }
    print('Message: ${byteMessage.length}');
    //storage of 355bits at v2
    return byteMessage;
  }

List<int> splitDataToInt(String byteMessage){
  List<int> split = [];

  for(int i = 1; i <= byteMessage.length; i++){
    if(i%8 == 0) split.add(int.parse(byteMessage.substring(i-8, i), radix: 2));
  }

  return split;
}



int galoisAdd(int n1, int n2){
  int result = n1 ^ n2;
  return result;
}

List<int> generateAntiLogTable() {
  const int poly = 285; //100011101
  List<int> expTable = List.filled(256, 0);

  int value = 1;
  for (int i = 0; i < 256; i++) {
    expTable[i] = value;

    value <<= 1;

    if (value >= 256) {
      value ^= poly; //^= bit-wise XOR
    }
  }

  return expTable;
}

List<int> generateLogTable() {
  List<int> expTable = generateAntiLogTable();
  List<int> invertedTable = List.filled(256, 0);

  for (int i = 0; i < 256; i++) {
    invertedTable[expTable[i]] = i;
  }

  return invertedTable;
}

int galoisMultiply(List<int> logT, List<int> antiLogT, int n1, int n2){
  if (n1 == 0 || n2 == 0) return 0;
  
  int alpha1 = logT[n1];
  int alpha2 = logT[n2];
  int sum = alpha1 + alpha2;
  if(sum >= 255){
    sum -= 255;
  }
  int result = antiLogT[sum];

  return result;
}

List<int> polyMultiply(List<int> p1, List<int> p2, List<int> logT, List<int> antiLogT) {
  List<int> result = List.filled(p1.length + p2.length - 1, 0);

  for (int i = 0; i < p1.length; i++) {
    for (int j = 0; j < p2.length; j++) {
      if (p1[i] != 0 && p2[j] != 0) {
        int product = galoisMultiply(logT, antiLogT, p1[i], p2[j]);
        result[i + j] ^= product; // XOR for addition in GF(256)
      }
    }
  }
  return result;
}

List<int> createGeneratorPolynomial(int errorCorrectionCodewords, List<int> logT, List<int> antiLogT) {
  List<int> generator = [1]; // start with g(x) = 1

  for (int i = 0; i < errorCorrectionCodewords; i++) {
    // (x - α^i) = [1, α^i]
    List<int> term = [1, antiLogT[i]];
    generator = polyMultiply(generator, term, logT, antiLogT);
  }

  return generator;
}


List<int> generateCodewords(List<int> logT, List<int> antiLogT, List<int> coefficients, List<int> generator){
  
  List<int> message = List.from(coefficients);
  int errorCorrectionCodewords = generator.length;
  //one step
  for(int e = 0; e < coefficients.length; e++){
    
    List<int> result1 = [];
    for(int i in generator){
      int product = galoisMultiply(logT, antiLogT, i, message[0]);
      result1.add(product); 
      } 
    //print('result1: $result1');

    List<int> result = [];
    for(int i = 0; i < message.length; i++){
      if (i < result1.length){
      int sum = galoisAdd(message[i],result1[i]);
      result.add(sum);
      //print('sum $i: $sum');
      } else {
        result.add(message[i]);
        //print('sum$i: ${message[i]}');
      }
    }
    if(e>coefficients.length-generator.length) result.add(result1.last);
    //print('result: $result');
    message = result.sublist(1);

  }
    
  return message;
}

String createErrorCorrectionBits(String message, int version){

  List<int> codewordAmount = [7, 10, 15, 20, 26];

  final logTable = generateLogTable();
  final antiTable = generateAntiLogTable();

  List<int> generator = createGeneratorPolynomial(codewordAmount[version -1], logTable, antiTable);
  print('generator: $generator');
  List<int> coefficients = splitDataToInt(fillMessage(version, message));
  print('coefficients: $coefficients');

  List<int> errorCorrection = generateCodewords(logTable, antiTable, coefficients, generator);
  print('errorCorrection: $errorCorrection');
  String errorCorrectionString = errorCorrection.map((x) => x.toRadixString(2).padLeft(8, '0')).join();
  print('Error: ${errorCorrectionString.length}');
  return errorCorrectionString;
}