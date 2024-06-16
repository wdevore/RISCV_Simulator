import 'package:console3_noisolate/definitions.dart';

class Arithmetics {
  BigInt value = BigInt.zero;

  Arithmetics(this.value);

  set byInt(int v) {
    value = BigInt.from(v);
  }

  int get byInt {
    return value.toInt();
  }

  set and(int v) {
    value = value & BigInt.from(v);
  }

  set or(int v) {
    value = value | BigInt.from(v);
  }

  // Logical shift right
  // Simulate logical shift right. BinInt only has arithmetic.
  void lsr(int bitShiftAmount, {width = 64}) {
    BigInt bi;
    if (width == 64) {
      bi = BigInt.from(0x7fffffffffffffff);
    } else {
      bi = BigInt.from(0x7fffffff);
    }
    for (var i = 0; i < bitShiftAmount; i++) {
      value = value >> 1;
      // Replace incoming arithmetic 1 with 0
      value = value & bi;
    }
  }

  /// Defaults to bit 31 being checked.
  bool isSigned({
    int signMask = 0x0000000080000000,
  }) {
    BigInt sign = value & BigInt.from(signMask);
    return sign.toInt() > 0;
  }

  // Sign extends based on designated bit.
  // Value should already be shifted right.
  void signExtend(
    // ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_fffff000_00000000
    int extendMask, // Bits to set
  ) {
    value = value | BigInt.from(extendMask);
  }
}
