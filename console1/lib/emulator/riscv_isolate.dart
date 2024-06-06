import 'dart:isolate';

riscvIsolate(SendPort sendPort) {
  sendPort.send(["Hello", "there"]);
  sendPort.send(["Welcome", "to Dart!"]);
  sendPort.send(["DONE!"]);
}
