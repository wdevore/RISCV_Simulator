import 'dart:isolate';

import 'package:console1/emulator/riscv_isolate.dart';

void main(List<String> arguments) async {
  // Start emulation Isolate
  ReceivePort port = ReceivePort();

  Isolate.spawn(riscvIsolate, port.sendPort);

  await for (var msg in port) {
    print(msg);
    if (msg[0] == "DONE!") {
      port.close();
    }
  }

  print('Done..');
  // Start console
}
