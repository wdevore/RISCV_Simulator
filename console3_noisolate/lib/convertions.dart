class Convertions {
  BigInt value = BigInt.zero;

  Convertions(this.value);

  set byInt(int v) {
    value = BigInt.from(v);
  }

  String toBinString({int width = 64, bool withPrefix = false}) {
    String v = value.toUnsigned(width).toRadixString(2).padLeft(width, '0');
    if (withPrefix) {
      return '0b$v';
    }
    return v;
  }

  String toHexStringWV32Pf(BigInt val) {
    String v = val.toUnsigned(32).toRadixString(16).padLeft(32 ~/ 4, '0');
    return '0x$v';
  }

  String toHexString({int width = 64, bool withPrefix = false}) {
    String v =
        value.toUnsigned(width).toRadixString(16).padLeft(width ~/ 4, '0');
    if (withPrefix) {
      return '0x$v';
    }
    return v;
  }

  String addUnderscores(String v, {int bits = 64, int width = 8}) {
    String s = '';
    for (var i = 0; i < bits; i += width) {
      s += '${v.substring(i, i + width)}_';
    }
    s = s.substring(0, s.length - 1);
    return s;
  }
}
