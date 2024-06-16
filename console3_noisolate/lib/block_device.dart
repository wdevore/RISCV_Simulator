// Ram is a memory mapped collection of Blocks.
import 'package:console3_noisolate/convertions.dart';

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

  BlockDevice(this.size, this.name);

  factory BlockDevice.create(int size, String name) =>
      BlockDevice(size, name)..mem = List.filled(size, 0);

  void mapTo(int startAddress) {
    start = startAddress;
    end = start + size - 1;
  }

  void write(int address, int value) => mem[address - start] = value;
  int read(int address) => mem[address - start];

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
}
