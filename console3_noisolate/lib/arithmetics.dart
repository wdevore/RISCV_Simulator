class Arithmetics {
  late BigInt value = BigInt.zero;
  final BigInt signBit = BigInt.from(0x0000000080000000);
  final BigInt wordMask = BigInt.from(0xffffffff00000000);

  factory Arithmetics.createZero() => Arithmetics(BigInt.zero);
  factory Arithmetics.fromInt(int v) => Arithmetics(BigInt.from(v));

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

  /// Sign extend to 64 bits for internal computation.
  BigInt signExtendDoubleWord() {
    // Test bit 31 for the 32bit sign flag. If set then
    // sign extend to 64bits internally using bit 31.
    BigInt sign = value & signBit;

    if (sign.toInt() > 0) {
      value = value | wordMask;
    }

    return value;
  }

  // Sign extends based on designated bit.
  // It is expected that the value has already been checked
  // for sign bit.
  // Value should already be shifted right.
  void signExtend(
    int extendMask, // Bits to set
  ) {
    value = value | BigInt.from(extendMask);
  }

  // Sign extends based on designated bit.
  // ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_S0000000_00000000
  void signExtendHalfWord() {
    if (isSigned(signMask: 0x0000000000008000)) {
      int mask = 0xfffffffffff0000;
      value = value | BigInt.from(mask);
    } else {
      keepLowerHalfword();
    }
  }

  // Sign extends based on designated bit.
  // ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffS000
  void signExtendByte() {
    if (isSigned(signMask: 0x0000000000000080)) {
      int mask = 0xfffffffffffff00;
      value = value | BigInt.from(mask);
    } else {
      keepLowerByte();
    }
  }

  BigInt keepLowerByte() {
    int mask = 0x00000000000000ff;
    setData(mask);
    return value;
  }

  BigInt keepLowerHalfword() {
    int mask = 0x000000000000ffff;
    setData(mask);
    return value;
  }

  BigInt keepLowerWord() {
    int mask = 0x00000000ffffffff;
    setData(mask);
    return value;
  }

  void setData(int mask) {
    value = value & BigInt.from(mask);
  }
}
