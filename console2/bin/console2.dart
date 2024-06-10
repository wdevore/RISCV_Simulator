import 'dart:io';
import 'dart:isolate';

import 'package:console2/emulator/riscv_isolate.dart';
import 'package:dart_console/dart_console.dart';

enum IsolateCommand {
  none,
  run,
  stop,
  exit,
  info,
}

void main(List<String> arguments) async {
  print('Running console2...');

  // ----------- Start emulation Isolate -----------
  // This is the receive port that the emu isolate sends data to.
  ReceivePort port = ReceivePort();

  // mainControlPort is a normal stream, transform it in a broadcast one
  // this way we can listen it in more than one place.
  final streamOfMesssage = port.asBroadcastStream();

  await Isolate.spawn(
    riscvIsolate,
    port.sendPort,
    debugName: 'EmuIsolate',
  );

  // Get send port of emu isolate. The first thing the emu isolate does
  // is send its "input" port (aka send port)
  SendPort emuSendPort = await streamOfMesssage.first;

  monitorPort(streamOfMesssage);

  // -------  Start console -----------

  final console = Console();
  console.rawMode = true; // readKey() becomes none blocking
  console.writeLine('Console is ready');
  Key key = console.readKey();

  bool exitLoop = false;
  IsolateCommand isolateCommand = IsolateCommand.none;

  print('Starting console');
  while (!exitLoop) {
    if (key.char == '`') {
      print('Exiting console loop...');
      console.clearScreen();
      console.resetCursorPosition();
      console.rawMode = false;
      exitLoop = true;
      continue;
    } else {
      print(key);
      switch (key.char) {
        case 'r':
          emuSendPort.send('Run');
          break;
        case 's':
          emuSendPort.send('Stop');
          break;
        case 'e':
          emuSendPort.send('Stop');
          emuSendPort.send('Exit');
          break;
        case 'i':
          isolateCommand = IsolateCommand.info;
          emuSendPort.send('Info');
          break;
      }
    }
    key = console.readKey();
    await Future.delayed(Duration(milliseconds: 10));
  }

  print('Main isolate done.');
  exit(0);
}

void monitorPort(Stream<dynamic> stream) {
  stream.listen(
    (message) {
      print('Main Isolate: $message');
      // List data = message as List;
      // print(data[0]);
      // print(data[1]);
      switch (message[0]) {
        case 'Info':
          print('### ${message[0]}');
          print('### ${message[1]}');
          break;
      }
    },
  );

  // return Future.delayed(Duration.zero);
}

// Future sendReceive(SendPort port, msg) {
//   ReceivePort response = ReceivePort();
//   port.send([msg, response.sendPort]);
//   return response.first;
// }
