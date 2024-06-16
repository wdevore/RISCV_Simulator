import 'package:console3_noisolate/cpu.dart';
import 'package:console3_noisolate/memory_mapped_devices.dart';

class SoC {
  late CPU cpu;

  final MemoryMappedDevices devices;

  SoC(this.devices) {
    cpu = CPU(devices);
  }

  void run({int instructionCount = 50}) {
    cpu.execute(instructionCount);
  }

  void reset() {
    cpu.reset(resetVector: 0x400);
  }
}
