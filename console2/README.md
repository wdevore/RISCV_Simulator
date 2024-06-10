# Description
This is a console frontend for the RISC-V simulator

# Tasks
- Figure out how to have the emu isolate async read the receive port (aka poll it).
  - We can check stream.isEmpty while looping: https://api.dart.dev/stable/3.4.3/dart-isolate/ReceivePort-class.html

# Running
```sh
/media/iposthuman/Extreme SSD/Development/Flutter/RISCV_Simulator/console2/bin$ dart run console2.dart
```

# Dart
- https://dart.dev/get-dart#stable-channel
- https://pub.dev/packages/sdl2/install


# Create a new project
```sh
dart create console1
```
