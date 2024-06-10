import 'dart:isolate';

bool isRunning = false;
bool isExit = false;

riscvIsolate(SendPort sendPort) async {
  print('Entered isolate');
  // Bind ports
  ReceivePort port = ReceivePort();

  // bool paused = true;
  // bool running = false;
  monitorPort(port);

  // port.listen((msg) {
  //   String data = msg[0];
  //   print('Data: $data');
  //   SendPort replyPort = msg[1];
  //   replyPort.send([data, port.sendPort]);
  // });

  sendPort.send(port.sendPort);

  // Begin loop - sleep for N(ms) per loop
  for (; !isExit;) {
    print('Sleep... $isRunning');
    await Future.delayed(Duration(milliseconds: 1000));
    // sleep(Duration(milliseconds: 1000));
  }

  // sendPort.send(["Hello", "there"]);
  // sendPort.send(["Welcome", "to Dart!"]);
  // sendPort.send(["DONE!"]);
  print('Exited isolate');
}

// This doesn't really need to be a Future.
void monitorPort(ReceivePort port) {
  port.listen((msg) {
    String data = msg;
    print('Emu Isolate: $data, $isExit');
    switch (data) {
      case 'Stop':
        isRunning = false;
        break;
      case 'Run':
        isRunning = true;
        print('Emu Isolate: isRunning: $isRunning');
        break;
      case 'Exit':
        isExit = true;
        break;
    }
    // SendPort replyPort = msg[1];
    // replyPort.send([data, port.sendPort]);
  });
  // return Future.delayed(Duration.zero);
}

Future sendReceive(SendPort port, msg) {
  ReceivePort response = ReceivePort();
  port.send([msg, response.sendPort]);
  return response.first;
}
