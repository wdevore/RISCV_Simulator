class Convertions {
  BigInt value = BigInt.zero;

  Convertions(this.value);

  set byInt(int v) {
    value = BigInt.from(v);
  }

  String toBinString({width = 64, withPrefix = false}) {
    String v = value.toUnsigned(width).toRadixString(2).padLeft(width, '0');
    if (withPrefix) {
      return '0b$v';
    }
    return v;
  }

  String toHexString({width = 64, withPrefix = false}) {
    String v =
        value.toUnsigned(width).toRadixString(16).padLeft(width ~/ 4, '0');
    if (withPrefix) {
      return '0x$v';
    }
    return v;
  }

  String decorateBinaryUnderscores(String v, {int bits = 64, int width = 8}) {
    String s = '';
    for (var i = 0; i < bits; i += width) {
      s += '${v.substring(i, i + width)}_';
    }
    s = s.substring(0, s.length - 1);
    return s;
  }
}
