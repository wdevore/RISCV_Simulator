# Description
This is a console frontend for the RISC-V simulator WITHOUT using isolates. This makes it possible to debug easier.

# Tasks

# Running
```sh
/media/iposthuman/Extreme SSD/Development/Flutter/RISCV_Simulator/console3/bin$ dart run console3.dart
```

# Create a new project
```sh
dart create console3_isolate
```

# launch.json entry
```json
        {
            "name": "RISCVEmu",
            "cwd": "RISCV_Simulator/console3_noisolate",
            "request": "launch",
            "type": "dart"
        },
```