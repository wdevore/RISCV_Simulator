import 'dart:io';

import 'package:console3_noisolate/block_device.dart';
import 'package:console3_noisolate/convertions.dart';
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

  // Manually load to rom
  // regexp for parsing x.out file: '([ 0-9]+):([\t0-9a-f]+)'
  devices.write(0x400, 0x00001337);
  devices.write(0x401, 0x90030313);
  devices.write(0x402, 0x00a32583);
  devices.write(0x403, 0x00100073); // ebreak

  // Load some data
  devices.write(0x0900 + 0x0a, 0xdeadbeaf);

  Convertions conv = Convertions(BigInt.from(devices.read(0x0900 + 0x0a)));

  print('Mem at 0x90a:');
  print(conv.decorateBinaryUnderscores(conv.toBinString()));

  SoC soc = SoC(devices);
  soc.reset();
  soc.run();

  print('Main isolate done.');
  exit(0);
}
