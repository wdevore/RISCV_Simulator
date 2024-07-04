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

  /// [word] is in Little-Endian order so we need to reverse first
  /// build ascii 0x20 -> 0x7e. anything else print '.'
  String wordToString() {
    List<String> ls = [];
    int shift = 0;
    for (var i = 0; i < 4; i++) {
      BigInt sh = value >> shift;
      sh = sh & BigInt.from(0x000000ff);
      if (sh > BigInt.from(19) && sh < BigInt.from(0x7f)) {
        ls.add(String.fromCharCode(sh.toInt()));
      } else {
        ls.add('.');
      }
      shift += 8;
    }
    return ls.reversed.join();
  }
}
