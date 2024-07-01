// Ram is a memory mapped collection of Blocks.
import 'dart:io';

import 'package:console3_noisolate/convertions.dart';
import 'package:console3_noisolate/definitions.dart';

class BlockDevice {
  String name;
  late List<int> mem;

  int size = 0;

  // If the block is 1024 words mapped to 4096 then:
  // start = 4096 = 0x1000
  // end = 4096 + 1024 - 1 = 5119 = 0x13ff
  int start = 0; // Start of block
  // End = start + size - 1
  int end = 0; // End of block

  bool writeProtected = false;

  BlockDevice(this.size, this.name);

  factory BlockDevice.create(int size, String name) =>
      BlockDevice(size, name)..mem = List.filled(size, 0);

  void mapTo(int startAddress) {
    start = startAddress;
    end = start + size - 1;
  }

  /// [writeMask] is either:
  /// - 0xffffffff = Word
  /// - 0x0000ffff or 0xffff0000 = Halfword
  /// - 0x000000ff etc = Byte
  /// [address] is in byte-form and Word aligned
  void write(int address, int value, int writeMask) {
    if (writeProtected) {
      Convertions conv = Convertions(BigInt.from(address));
      print('ROM is write protected: ${conv.toHexString(
        width: 32,
        withPrefix: true,
      )}');
      return;
    }

    if (writeMask == 0xffffffff) {
      // Break into bytes for storage
      BigInt v = BigInt.from(value);
      _writeWord(address, v);
    } else {
      // Read memory and insert data based on mask.
      // The value should already be shifted and mask set to match.
      // Clear Nth position first, then OR 'value' with 'm'
      BigInt m = BigInt.from(read(address));
      // Clear Nth position
      BigInt or = m & BigInt.from(writeMask);
      // Insert data into Word
      BigInt data = or | BigInt.from(value);

      _writeWord(address, data);
    }
  }

  void _writeWord(int address, BigInt data) {
    mem[address - start] = (data & BigInt.from(0x000000ff)).toInt();
    mem[address + 1 - start] = ((data & BigInt.from(0x0000ff00)) >> 8).toInt();
    mem[address + 2 - start] = ((data & BigInt.from(0x00ff0000)) >> 16).toInt();
    mem[address + 3 - start] = ((data & BigInt.from(0xff000000)) >> 24).toInt();
  }

  int read(int address) {
    // read 4 bytes and mask together into a Word.
    int byte0 = mem[address - start]; // little endian, so byte 0 is first
    int byte1 = mem[address + 1 - start];
    int byte2 = mem[address + 2 - start];
    int byte3 = mem[address + 3 - start];
    BigInt word = BigInt.from(byte0);
    word |= BigInt.from(byte1 << 8);
    word |= BigInt.from(byte2 << 16);
    word |= BigInt.from(byte3 << 24);
    return word.toInt();
  }

  bool contains(int address) {
    return (address >= start && address < end);
  }

  @override
  String toString() {
    Convertions conv = Convertions(BigInt.from(size));
    String ssize = conv.toHexString(width: 32, withPrefix: true);
    conv.byInt = start;
    String sstart = conv.toHexString(width: 32, withPrefix: true);
    conv.byInt = end;
    String send = conv.toHexString(width: 32, withPrefix: true);
    return 'Device "$name": ($ssize) <$sstart, $send>';
  }

  /// [startAddress] and [endAddress] are in byte-form
  void dump(int startAddress, int endAddress,
      {Form form = Form.word, bool withHeader = true}) {
    // <address> value
    Convertions conv = Convertions(BigInt.zero);
    conv.byInt = startAddress;
    String strAddr = conv.toHexString(width: 32, withPrefix: true);
    conv.byInt = endAddress;
    String endAddr = conv.toHexString(width: 32, withPrefix: true);
    if (withHeader) {
      print('Memory from $strAddr to $endAddr:');
    }

    for (int address = startAddress; address <= endAddress; address += 4) {
      int data = read(address);
      conv.byInt = address;
      String addrData = conv.toHexString(width: 32, withPrefix: true);
      conv.byInt = data;
      String hexData = conv.toHexString(width: 32, withPrefix: true);
      stdout.write('<$addrData> $hexData    ');

      conv.byInt = data;
      stdout.write(conv.wordToString());
      print('');
    }
  }
}
