import 'dart:io' as io;

import 'package:path/path.dart' as p;

import 'package:console3_noisolate/block_device.dart';
import 'package:console3_noisolate/memory_mapped_devices.dart';
import 'package:console3_noisolate/soc.dart';

void main(List<String> arguments) {
  print('Running console3_noisolate...');

  MemoryMappedDevices devices = MemoryMappedDevices();
  BlockDevice rom = devices.addDevice('Rom', 0x400, 0x400);
  print(rom);
  BlockDevice ram = devices.addDevice('Ram', rom.end + 1 + 0x100, 0x400);
  print(ram);
  BlockDevice uart = devices.addDevice('UART', ram.end + 1 + 0x1000, 0x04);
  print(uart);

  // -------------------------------------------
  // All address are in byte-form, for example, address 0x401 in word-form
  // is actually 0x404 in byte form.
  // -------------------------------------------
  BigInt baseAddr = BigInt.from(0x400);
  // Load program
  int status = _loadProgram(baseAddr, devices);
  if (status == -1) {
    throw Exception("Can't load program");
  }

  // BigInt incBy = BigInt.from(4);
  // devices.write(baseAddr, 0x00f00313);
  // devices.write(baseAddr += incBy, 0x00200393);
  // devices.write(baseAddr += incBy, 0x007355b3);
  // devices.write(baseAddr += incBy, 0x00100073); // ebreak

  rom.writeProtected = true;

  rom.dump(0x400, 0x42c);

  // Store some data for testing.
  //                      7 6 5 4
  devices.writeByInt(0x0904, 0x12345678);
  //                      b a 9 8
  devices.writeByInt(0x0908, 0xdeadbeaf);
  ram.dump(0x904, 0x908);

  SoC soc = SoC(devices);
  soc.reset();
  soc.run();

  print('Main isolate done.');
  io.exit(0);
}

int _loadProgram(BigInt baseAddr, MemoryMappedDevices devices) {
  var filePath =
      p.join(io.Directory.current.path, '../assembly', 'firmware.out');

  var ioFile = io.File(filePath);
  List<String> lines;

  RegExp lineExpr = RegExp(r'([ 0-9a-f]*):\t([0-9a-f]+)');

  if (ioFile.existsSync()) {
    lines = ioFile.readAsLinesSync();

    BigInt lineAddr = baseAddr;

    for (var line in lines) {
      RegExpMatch? match = lineExpr.firstMatch(line);
      if (match != null) {
        String addr = match[1]!;
        String instr = match[2]!;
        // print('addr: $addr, instr: $instr');

        lineAddr = baseAddr + BigInt.from(int.parse(addr, radix: 16));
        devices.write(lineAddr, int.parse(instr, radix: 16));
      }
    }
  } else {
    return -1;
  }

  return 0;
}
