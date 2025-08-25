import 'qr_code.dart';

void main(){
  QrCodeGenerator qrGen = QrCodeGenerator();

  qrGen.createQrCode('example', 2, fileName: 'qr');
}