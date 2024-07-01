class Breakpoint {
  bool enabled = false;
  int address = 0;

  Breakpoint();

  factory Breakpoint.nil() {
    Breakpoint bp = Breakpoint()..address = -1;
    return bp;
  }

  bool isNil() => address == -1;
}
