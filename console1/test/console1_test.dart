import 'dart:io';

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
}
