import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_console/dart_console.dart';
import 'package:test/test.dart';

void main() {
  test('ConsoleHelloWorld', () {
    final console = Console();
    console.setBackgroundColor(ConsoleColor.blue);
    console.setForegroundColor(ConsoleColor.white);
    console.writeLine('Simple Demo', TextAlignment.center);
    console.resetColorAttributes();

    console.writeLine();

    console.writeLine('This console window has ${console.windowWidth} cols and '
        '${console.windowHeight} rows.');
    console.writeLine();

    console.writeLine('This text is left aligned.', TextAlignment.left);
    console.writeLine('This text is center aligned.', TextAlignment.center);
    console.writeLine('This text is right aligned.', TextAlignment.right);

    for (final color in ConsoleColor.values) {
      console.setForegroundColor(color);
      console.writeLine(color.toString().split('.').last);
    }
    console.resetColorAttributes();
  });

  test('ConsoleKeyboard', () {
    final console = Console();
    console.writeLine(
        'This sample demonstrates keyboard input. Press any key including control keys');
    console.writeLine(
        'such as arrow keys, page up/down, home, end etc. to see it echoed to the');
    console.writeLine('screen. Press Ctrl+Q to end the sample.');
    var key = console.readKey();

    while (true) {
      if (key.isControl && key.controlChar == ControlCharacter.ctrlQ) {
        console.clearScreen();
        console.resetCursorPosition();
        console.rawMode = false;
        exit(0);
      } else {
        print(key);
      }
      key = console.readKey();
    }
  });

  test('ConsolePorts', () async {
    stdout.writeln(
        "isolate running the 'main' method is called: ${Isolate.current.debugName}");

    // creates a port to receive messages on MainIsolate
    final mainControlPort = ReceivePort();

    // Spawns reates a new isolate
    // Once it's start, it will run the "timerTick" function and
    // the param will be the "mainControlPort.sendPort".
    // This away it can send messages back to the "parent" main Isolate when needed
    Isolate timerIsolate = await Isolate.spawn(
      timerTick,
      mainControlPort.sendPort,
      debugName: "TimerIsolate",
    );

    // mainControlPort is a normal stream, transform it in a broadcast one
    // this way we can listen it in more than one place: (1) and (2)
    final streamOfMesssage = mainControlPort.asBroadcastStream();

    // (1)
    // Send a message to TimerIsolate start itself
    stdout.writeln("${Isolate.current.debugName} asking TimerIsolate to start");
    SendPort timer = await streamOfMesssage.first;
    timer.send("start");

    // (2)
    // Keep listening messages from TimerIsolate until we receive 10 messages
    // then kill both "MainIsolate" and "TimerIsolate"
    var counter = 0;
    streamOfMesssage.listen(
      (message) {
        counter++;
        if (counter == 10) {
          stdout.writeln("finishing timer...");
          timerIsolate.kill();
          stdout.writeln("finishing main...");
          Isolate.current.kill();
        } else {
          stdout.writeln(message);
        }
      },
    );
  });
}

void timerTick(SendPort mainPort) async {
  final timerControlPort = ReceivePort();
  stdout.writeln("${Isolate.current.debugName} started");

  mainPort.send(timerControlPort.sendPort);

  await timerControlPort.firstWhere((message) => message == "start");

  stdout.writeln("${Isolate.current.debugName} will start sending messages...");

  Timer.periodic(Duration(seconds: 1), (timer) {
    mainPort.send(DateTime.now().toIso8601String());
  });
}
