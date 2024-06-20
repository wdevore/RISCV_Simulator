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
  // regexp for parsing x.out file: '([ 0-9]+):.([\t0-9a-f]+)'
  // All address are in byte-form, for example, address 0x401 in word-form
  // is actually 0x404 in byte form.
  int addr = 0x400;
  devices.write(addr, 0x00001337);
  devices.write(addr += 4, 0x90830313);
  devices.write(addr += 4, 0xaabbd5b7);
  devices.write(addr += 4, 0xcdd58593);
  devices.write(addr += 4, 0x00b32023);
  devices.write(addr += 4, 0x00100073); // ebreak
  rom.writeProtected = true;

  rom.dump(0x400, 0x41a);

  // Store some data for testing.
  //                      7 6 5 4
  devices.write(0x0904, 0x12345678);
  //                      b a 9 8
  devices.write(0x0908, 0xdeadbeaf);
  ram.dump(0x904, 0x908);

  SoC soc = SoC(devices);
  soc.reset();
  soc.run();

  print('Main isolate done.');
  exit(0);
}
