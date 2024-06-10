import 'dart:isolate';

bool isRunning = false;
bool isExit = false;

riscvIsolate(SendPort sendPort) async {
  print('Entered isolate');
  // Bind ports
  ReceivePort port = ReceivePort();

  sendPort.send(port.sendPort);

  monitorPort(port, sendPort);

  // Begin loop - sleep for N(ms) per loop
  for (; !isExit;) {
    if (isRunning) {
      print('Emulation is running...');
    } else {
      print('Emulation is stopped...');
    }

    await Future.delayed(Duration(milliseconds: 1000));
  }

  print('Exited isolate');
}

// This doesn't really need to be a Future.
void monitorPort(ReceivePort port, SendPort sendPort) {
  port.listen((msg) {
    String data = msg;
    print('Emu Isolate: $data, $isExit');
    switch (data) {
      case 'Stop':
        isRunning = false;
        break;
      case 'Run':
        isRunning = true;
        break;
      case 'Info':
        print('Emu Isolate: sending info.');
        sendPort.send(['Info', 'running=$isRunning']);
        break;
      case 'Exit':
        isExit = true;
        break;
    }
  });
}
