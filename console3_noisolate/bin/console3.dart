import 'dart:io' as io;
import 'dart:io';

import 'package:console3_noisolate/breakpoint.dart';
import 'package:console3_noisolate/convertions.dart';
import 'package:path/path.dart' as p;

import 'package:console3_noisolate/block_device.dart';
import 'package:console3_noisolate/memory_mapped_devices.dart';
import 'package:console3_noisolate/soc.dart';

void main(List<String> arguments) {
  print('Running console3_noisolate...');

  // Device "ROM": (0x00000400) <0x00000400, 0x000007ff>
  // Device "BRAM": (0x00000400) <0x00000900, 0x00000cff>
  // Device "DATA": (0x00000040) <0x00001000, 0x0000103f>
  // Device "UART": (0x00000004) <0x00001d00, 0x00001d03>
  MemoryMappedDevices devices = _createDevices('../assembly/programs/counter');
  BlockDevice? rom = devices.findDevice('ROM');
  // BlockDevice? ram = devices.findDevice('BRAM');
  // BlockDevice? data = devices.findDevice('DATA');
  devices.displayDevices();

  // -------------------------------------------
  // All address are in byte-form, for example, address 0x401 in word-form
  // is actually 0x404 in byte form.
  // -------------------------------------------
  BigInt baseAddr = BigInt.from(0);
  // Load program
  int status = _loadProgram(baseAddr, devices);
  if (status == -1) {
    throw Exception("Can't load program");
  }

  rom!.writeProtected = true;

  int pcResetAddr = 0x400;

  // data!.dump(0x1000, 0x100c);

  SoC soc = SoC(devices);
  // soc.addBreakpoint(0x404, enabled: true);
  // soc.addBreakpoint(0x40c, enabled: true);

  soc.reset(resetVector: pcResetAddr);

  soc.renderDisplay();

  // Loop on console input
  bool exitEmu = false;

  // Previous inputs
  String previousCmd = '';
  int pStart = 0;
  int pEnd = 0;

  while (!exitEmu) {
    stdout.write('> ');
    String? command = stdin.readLineSync();
    if (command! == '') {
      command = previousCmd;
    }
    List<String> fs = command.split(' ');
    if (fs.length > 1) {
      command = fs[0];
    }

    switch (command) {
      case 's':
        soc.instructionStep();
        soc.renderDisplay();
        break;
      case 'r':
        // run: r #instructions
        soc.run();
        soc.renderDisplay();
        break;
      case 'b':
        // b addr(int) enabled(bool)
        if (fs.length == 3) {
          int addr = int.parse(fs[1], radix: 16);
          String enabled = fs[2];
          Breakpoint bp = soc.breakPoints.firstWhere(
            (breakpoint) => breakpoint.address == addr,
            orElse: () => Breakpoint.nil(),
          );
          if (bp.isNil()) {
            Convertions c = Convertions(BigInt.from(addr));
            print(
                'No breakpoint at <${c.toHexString(width: 32, withPrefix: true)}>');
          } else {
            bp.enabled = enabled == "on";
          }
        }
        soc.renderBreakpoints();
        break;
      case 'sb': // Set a breakpoint
        // sb addr
        int addr = int.parse(fs[1], radix: 16);

        Breakpoint bp = soc.breakPoints.firstWhere(
          (breakpoint) => breakpoint.address == addr,
          orElse: () => Breakpoint.nil(),
        );

        if (bp.isNil()) {
          // Add new breakpoint
          soc.addBreakpoint(addr, enabled: true);
        } else {
          bp
            ..enabled = true
            ..address = addr;
        }
        soc.renderDisplay();
        break;
      case 'e': // Clears ebreak
        // Overrides flag. However, the code needs to resumable otherwise
        // it may crash. Used for debugging via Ebreaks rather BreakPoints.
        soc.cpu.ebreakHit = false;
        break;
      case 't': // Reset
        soc.reset(resetVector: pcResetAddr);
        soc.renderDisplay();
        break;
      case 'y':
        soc.renderDisplay();
        break;
      case 'x': // Exit
        exitEmu = true;
        break;
      case 'v':
        // v ROM start length (in words)
        String device = fs[1];
        BlockDevice? vice = devices.findDevice(device);
        if (vice == null) {
          print('Device "$device" not found!');
          break;
        }

        if (fs.length == 4) {
          int start = int.parse(fs[2], radix: 16);
          int length = int.parse(fs[3]) - 1;
          pStart = start;
          pEnd = start + (length * 4);
        } else if (fs.length == 3) {
          int start = int.parse(fs[2], radix: 16);
          pStart = start;
          pEnd = start + (10 * 4);
        } else {
          pStart = vice.start;
          pEnd = pStart + (10 * 4);
        }
        vice.dump(pStart, pEnd);
        break;
      default:
        print('UNKNOWN command: $command');
        break;
    }

    previousCmd = command;
  }

  print('Emu exiting...');
  io.exit(0);
}

MemoryMappedDevices _createDevices(String relativePath) {
  var filePath = p.join(io.Directory.current.path, relativePath, 'program.ld');

  var ioFile = io.File(filePath);
  List<String> lines;

  RegExp lineExpr =
      RegExp(r'[ ]+([A-Z]+)[\(wx \)]*:ORIGIN =0x([a-f0-9]+),LENGTH =([0-9]+)');

  MemoryMappedDevices devices = MemoryMappedDevices();

  if (ioFile.existsSync()) {
    lines = ioFile.readAsLinesSync();

    for (var line in lines) {
      RegExpMatch? match = lineExpr.firstMatch(line);
      if (match != null) {
        String name = match[1]!;
        String addr = match[2]!;
        String size = match[3]!;

        int address = int.parse(addr, radix: 16);
        int length = int.parse(size);
        devices.addDevice(name, address, length);
      }
    }
  }

  return devices;
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
