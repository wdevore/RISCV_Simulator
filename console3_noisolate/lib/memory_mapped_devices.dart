// Little Endian format.
// lower address holds LSB
//
// Ex:
// Address      Value
// 0x00000000   0x42    // LSB
// 0x00000001   0x32
// 0x00000002   0x31
// 0x00000003   0x30    // MSB
// 0x00000004   0x99
// 0x00000005   0x21
// 0x00000006   0x44
// 0x00000007   0x33
//
// or by Word
//              LSB               MSB
// 0x00000000   0x42, 0x32, 0x31, 0x30
// 0x00000004   0x99, 0x21, 0x44, 0x33

// Unaligned access is not permitted. An exception is thrown.

import 'package:console3_noisolate/block_device.dart';

class MemoryMappedDevices {
  // Memory is thought of as Words (32 bits)
  late List<BlockDevice> mem = [];
  BigInt wordAlignMask = BigInt.from(0xfffffffc);

  BlockDevice addDevice(String name, int startAddress, int size) {
    BlockDevice bd = BlockDevice.create(size, name)..mapTo(startAddress);
    mem.add(bd);
    return bd;
  }

  int read(int address) {
    try {
      BlockDevice block = mem.firstWhere((blk) => blk.contains(address));
      return block.read(address);
    } on StateError {
      throw Exception(
          'Memory read error: no BlockDevices at address 0x${address.toRadixString(16)}');
    }
  }

  void write(BigInt address, int value, {int writeMask = 0xffffffff}) {
    // Determine which Block the address resides in.

    // Word align address by clearing last two bits
    // 11111111_11111111_11111111_11111100 = 0xfffffffc
    BigInt addr = address & wordAlignMask;

    try {
      BlockDevice block =
          mem.firstWhere((blk) => blk.contains(address.toInt()));
      block.write(addr.toInt(), value, writeMask);
    } on StateError {
      throw Exception(
          'Memory write error: no BlockDevices at address 0x${address.toRadixString(16)}');
    }
  }

  void writeByInt(int address, int value) {
    write(BigInt.from(address), value);
  }
}
