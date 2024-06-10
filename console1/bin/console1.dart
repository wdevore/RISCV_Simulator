import 'dart:io';
import 'dart:isolate';

import 'package:console1/emulator/riscv_isolate.dart';
import 'package:dart_console/dart_console.dart';

void main(List<String> arguments) async {
  // Start emulation Isolate
  ReceivePort port = ReceivePort();

  await Isolate.spawn(riscvIsolate, port.sendPort);

  SendPort riscvSendPort = await port.first;

  // print('sending...');
  // List msg = await sendReceive(childSendPort, "Hello from Main Isolate");
  // print('msg: $msg');

  sleep(Duration(milliseconds: 2000));
  print('Sending Run');
  riscvSendPort.send('Run');
  sleep(Duration(milliseconds: 5000));
  print('Sending Stop');
  riscvSendPort.send('Stop');
  sleep(Duration(milliseconds: 2000));
  print('Sending Exit');
  riscvSendPort.send('Exit');
  sleep(Duration(milliseconds: 2000));

  // await for (var msg in port) {
  //   print('Main Isolate: $msg');
  //   if (msg[0] == "DONE!") {
  //     port.close();
  //   }
  // }

  print('Done..');
  // Start console
}

Future sendReceive(SendPort port, msg) {
  ReceivePort response = ReceivePort();
  port.send([msg, response.sendPort]);
  return response.first;
}
