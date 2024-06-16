// 32 bit unsigned register

import 'package:console3_noisolate/definitions.dart';

class Register {
  BigInt value = BigInt.zero;
  final BigInt signBit = BigInt.from(0x0000000080000000);
  final BigInt byteMask = BigInt.from(0xffffffffffffff00);
  final BigInt halfWordMask = BigInt.from(0xffffffffffff0000);
  final BigInt wordMask = BigInt.from(0xffffffff00000000);

  Register(int v) {
    byInt = v;
  }

  set byInt(int v) {
    value = BigInt.from(v);
    signExtend();
  }

  int get byInt {
    return value.toInt();
  }

  void reset(int val) {
    value = BigInt.from(val);
  }

  /// Sign extend to 64 bits for internal computation.
  void signExtend({DataSize size = DataSize.doubleword}) {
    // Test bit 31 for the 32bit sign flag. If set then
    // sign extend to 64bits internally using bit 31.
    BigInt sign = value & signBit;

    if (sign.toInt() > 0) {
      switch (size) {
        case DataSize.byte:
          value = value | byteMask;
          break;
        case DataSize.halfword:
          value = value | halfWordMask;
          break;
        default: // word extended to double word
          value = value | wordMask;
          break;
      }
    }
  }

  void signUnExtend({DataSize size = DataSize.doubleword}) {
    BigInt sign = value & signBit;

    if (sign.toInt() == 0) {
      switch (size) {
        case DataSize.byte:
          value = value & BigInt.from(0x00000000000000ff);
          break;
        case DataSize.halfword:
          value = value & BigInt.from(0x000000000000ffff);
          break;
        default:
          value = value & BigInt.from(0x00000000ffffffff);
          break;
      }
    }
  }
}
