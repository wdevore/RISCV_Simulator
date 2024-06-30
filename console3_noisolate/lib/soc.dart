import 'dart:io';

import 'package:console3_noisolate/block_device.dart';
import 'package:console3_noisolate/convertions.dart';
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

  void reset({int resetVector = 0}) {
    cpu.reset(resetVector: resetVector);
  }

  void instructionStep() {
    cpu.nextInstruction();
  }

  void renderDisplay() {
    // Prints layout of the CPU

    // Branch Taken: Yes/no
    // ---------------------------------------------------------------
    // x1/ra:    0x00000000    x2/sp:  0x00000000
    // x3/gp:    0x00000000    x4/tp:  0x00000000
    // x5/t0:    0x00000000    x6/t1:  0x00000000   x7/t2:   0x00000000
    // x8/s0/fp  0x00000000    x9/s1:  0x00000000
    // x10/a0:   0x00000000    x11/a1: 0x00000000
    // x12/a2:   0x00000000    x13/a3: 0x00000000   x14/a4:  0x00000000
    // x15/a5:   0x00000000    x16/a6: 0x00000000   x17/a7:  0x00000000
    // x18/s2:   0x00000000    x19/s3: 0x00000000   x20/s4:  0x00000000
    // x21/s5:   0x00000000    x22/s6: 0x00000000   x23/s7:  0x00000000
    // x24/s8:   0x00000000    x25/s9: 0x00000000   x26/s10: 0x00000000
    // x27/s11   0x00000000
    // x28/t3:   0x00000000    x29/t4: 0x00000000   x30/t5: 0x00000000
    // x30/st6   0x00000000
    // ---------------------------------------------------------------
    // PC: 0x00000000      nextPc: 0x00000000
    // Program:
    // <0x0000040c> 0x00b00393
    // <0x00000410> 0x00100073
    // <0x00000414> 0xffc00293 <--PC
    // <0x00000418> 0x00600313
    // <0x0000041c> 0xfe62e4e3
    //
    // ---------------------------------------------------------------
    // Memory
    // <0x00000904> 0x12345678  ..A.DEAD
    // <0x00000908> 0xdeadbeaf  BEAF..01
    // ...

    Convertions c = Convertions(BigInt.zero);
    BigInt x1 = cpu.regs[1].value;
    BigInt x2 = cpu.regs[2].value;
    BigInt x3 = cpu.regs[3].value;
    BigInt x4 = cpu.regs[4].value;
    BigInt x5 = cpu.regs[5].value;
    BigInt x6 = cpu.regs[6].value;
    BigInt x7 = cpu.regs[7].value;
    BigInt x8 = cpu.regs[8].value;
    BigInt x9 = cpu.regs[9].value;
    BigInt x10 = cpu.regs[10].value;
    BigInt x11 = cpu.regs[11].value;
    BigInt x12 = cpu.regs[12].value;
    BigInt x13 = cpu.regs[13].value;
    BigInt x14 = cpu.regs[14].value;
    BigInt x15 = cpu.regs[15].value;
    BigInt x16 = cpu.regs[16].value;
    BigInt x17 = cpu.regs[17].value;
    BigInt x18 = cpu.regs[18].value;
    BigInt x19 = cpu.regs[19].value;
    BigInt x20 = cpu.regs[20].value;
    BigInt x21 = cpu.regs[21].value;
    BigInt x22 = cpu.regs[22].value;
    BigInt x23 = cpu.regs[23].value;
    BigInt x24 = cpu.regs[24].value;
    BigInt x25 = cpu.regs[25].value;
    BigInt x26 = cpu.regs[26].value;
    BigInt x27 = cpu.regs[27].value;
    BigInt x28 = cpu.regs[28].value;
    BigInt x29 = cpu.regs[29].value;
    BigInt x30 = cpu.regs[30].value;
    BigInt x31 = cpu.regs[31].value;

    print("""
----------------------------------------------------------------
Ebreak hit: ${cpu.ebreakHit}

x1/ra:    ${c.toHexStringWV32Pf(x1)}    x2/sp:  ${c.toHexStringWV32Pf(x2)}
x3/gp:    ${c.toHexStringWV32Pf(x3)}    x4/sp:  ${c.toHexStringWV32Pf(x4)}
x5/t0:    ${c.toHexStringWV32Pf(x5)}    x6/t1:  ${c.toHexStringWV32Pf(x6)}   x7/t2:   ${c.toHexStringWV32Pf(x7)}
x8/s0/fp: ${c.toHexStringWV32Pf(x8)}    x9/s1:  ${c.toHexStringWV32Pf(x9)}
x10/a0:   ${c.toHexStringWV32Pf(x10)}    x11/a1: ${c.toHexStringWV32Pf(x11)}
x12/a2:   ${c.toHexStringWV32Pf(x12)}    x13/a3: ${c.toHexStringWV32Pf(x13)}   x14/a4:  ${c.toHexStringWV32Pf(x14)}
x15/a5:   ${c.toHexStringWV32Pf(x15)}    x16/a6: ${c.toHexStringWV32Pf(x16)}   x17/a7:  ${c.toHexStringWV32Pf(x17)}
x18/s2:   ${c.toHexStringWV32Pf(x18)}    x19/s3: ${c.toHexStringWV32Pf(x19)}   x20/s4:  ${c.toHexStringWV32Pf(x20)}
x21/s5:   ${c.toHexStringWV32Pf(x21)}    x22/s6: ${c.toHexStringWV32Pf(x22)}   x23/s7:  ${c.toHexStringWV32Pf(x23)}
x24/s8:   ${c.toHexStringWV32Pf(x24)}    x25/s9: ${c.toHexStringWV32Pf(x25)}   x26/s10: ${c.toHexStringWV32Pf(x26)}
x27/s11:  ${c.toHexStringWV32Pf(x27)}
x28/t3:   ${c.toHexStringWV32Pf(x28)}    x29/t4: ${c.toHexStringWV32Pf(x29)}   x30/t5:  ${c.toHexStringWV32Pf(x30)}
x31/t6:   ${c.toHexStringWV32Pf(x31)}
----------------------------------------------------------------
PC: ${c.toHexStringWV32Pf(cpu.pc.value)}      nextPc: ${c.toHexStringWV32Pf(cpu.nextPc.value)}
""");

    BlockDevice? rom = devices.findDevice('Rom');

    // Print a window of memory around PC
    print('Program:');
    BigInt pc = cpu.pc.value;

    // Print N lines above PC.
    // Attempt to move back 2 words
    BigInt top = pc - BigInt.from(8);
    BigInt start = BigInt.from(rom!.start);

    if (top < start) {
      top = pc - BigInt.from(4);
      if (top < start) {
        top = BigInt.from(rom.start);
      }
    }
    for (var i = top.toInt(); i < top.toInt() + (4 * 5); i += 4) {
      String addr = c.toHexStringWV32Pf(BigInt.from(i));
      int data = rom.read(i);
      String val = c.toHexStringWV32Pf(BigInt.from(data));
      stdout.write('<$addr> $val');
      if (i == pc.toInt()) {
        print(' <-- PC');
      } else {
        print('');
      }
    }
  }
}
