import 'package:console3_noisolate/arithmetics.dart';
import 'package:console3_noisolate/convertions.dart';
import 'package:console3_noisolate/memory_mapped_devices.dart';
import 'package:console3_noisolate/register.dart';

import 'definitions.dart';

class CPU {
  List<Register> regs = List.filled(32, Register(0));

  Register pc = Register(0);

  final MemoryMappedDevices devices;

  bool ebreakHit = false;

  CPU(this.devices);

  void reset({int resetVector = 0}) {
    // Reset PC
    pc.reset(resetVector);
    regs.map((register) => register.reset(0));
  }

  int _fetch() {
    int inst = devices.read(pc.byInt);
    pc.byInt++;
    return inst;
  }

  void _decode(int instruction) {
    BigInt inst = BigInt.from(instruction);

    Convertions conv = Convertions(inst);
    print(
        '${conv.toHexString(width: 32, withPrefix: true)} : ${conv.toBinString(width: 32)}');

    // Break down the bit fields of the instruction
    // Opcode catagory:
    BigInt opcode = _extractOpcode(inst);

    switch (opcode.toInt()) {
      case loads:
        print('Load instructions');
        BigInt rd = _extractImmDestination(inst); //     dest
        BigInt width = _extractFunct3(inst); //          funct3
        BigInt base = _extractImmBase(inst); //          rs1
        BigInt offset = _extractImmITypeOffset(inst); // imm

        _processLoads(rd, width, base, offset);
        break;
      case immediates:
        // addi, slti[u], andi, ori, xori

        // Note: addi
        // https://stackoverflow.com/questions/50742420/risc-v-build-32-bit-constants-with-lui-and-addi
        // imm is a signed 12bit number and should be extended

        BigInt rd = _extractImmDestination(inst); //  dest
        BigInt type = _extractFunct3(inst); //        funct3
        BigInt src = _extractImmBase(inst); //        rs1/src
        BigInt imm = _extractImmITypeOffset(inst); // imm

        // Sign extend immediate but not for sltiu
        if (type.toInt() != immType_SLTIU) {
          Arithmetics ar = Arithmetics(imm);
          ar.signExtend(0xfffffffffffff000);
          imm = ar.value;
        }

        _processImms(rd, type, src, imm);
        break;
      case lui: // Load upper immediate
        BigInt rd = _extractImmDestination(inst); //   dest

        //          20bits  12bits
        // R[rd] = {imm,    12b0}
        BigInt immv = inst & BigInt.from(0xfffff000);

        Register regD = regs[rd.toInt()];
        regD.value = immv;
        break;
      case auipc:
        BigInt rd = _extractImmDestination(inst); // dest
        BigInt imm = _extractImmSystem(inst); //     imm

        break;
      case system:
        BigInt rd = _extractImmDestination(inst); //  dest
        BigInt funct3 = _extractFunct3(inst); //      funct3
        BigInt rs1 = _extractImmBase(inst); //        rs1/src
        BigInt imm = _extractImmTypeUOffset(inst); // imm

        _processSystems(rd, funct3, rs1, imm);
        break;
      case r_types:
        // add, slt, sltu, and, or, xor, sll, srl, sub, sra
        BigInt rd = _extractImmDestination(inst); // dest
        BigInt funct3 = _extractFunct3(inst); //        funct3
        BigInt rs1 = _extractImmBase(inst); //       rs1/src
        BigInt rs2 = _extractImmRs2(inst); //       rs1/src
        BigInt funct7 = _extractFunct7(inst); //        funct3

        _processRTypes(rd, funct3, rs1, rs2, funct7);
        break;
    }
  }

  void execute(int instructionCount) {
    for (var i = 0; i < instructionCount; i++) {
      int instruction = _fetch();

      _decode(instruction);

      if (ebreakHit) {
        break;
      }
    }
  }

  // -----------------------------------------------
  // ----------- Instruction processing ------------
  // -----------------------------------------------
  void _processLoads(BigInt rd, BigInt width, BigInt baseReg, BigInt offset) {
    // rd = mem[rs1+imm]
    Register regBase = regs[baseReg.toInt()];
    BigInt address = regBase.value + offset;
    int data = devices.read(address.toInt());
    Register reg = regs[rd.toInt()];

    switch (width.toInt()) {
      case Funct3_SizeWord:
        reg.byInt = data;
        // Convertions conv = Convertions(reg.value);
        // print(conv.toHexString());
        break;
    }
  }

  void _processImms(BigInt rd, BigInt type, BigInt src, BigInt imm) {
    // rd = R[src] + imm
    switch (type.toInt()) {
      case immType_ADDI:
        Register regS = regs[src.toInt()];
        BigInt sum = regS.value + imm;
        Register regD = regs[rd.toInt()];
        regD.value = sum;
        break;
    }
  }

  void _processRTypes(
      BigInt rd, BigInt funct3, BigInt rs1, BigInt rs2, BigInt funct7) {
    Register rs1R = regs[rs1.toInt()];
    Register rs2R = regs[rs2.toInt()];
    Register regD = regs[rd.toInt()];

    switch (funct7.toInt()) {
      case 0:
        switch (funct3.toInt()) {
          case RType_ADD_SUB: // ADD
            regD.value = rs1R.value + rs2R.value;
            break;
          case RType_SLL:
            regD.value = rs1R.value << rs2R.value.toInt();
            break;
          case RType_SLT:
            // rs1 and rs2 need to be treated as signed
            regD.value =
                rs1R.value < rs2R.value ? BigInt.from(1) : BigInt.from(0);
            break;
          case RType_SLTU:
            // rs1 and rs2 need to be treated as 32bit unsigned
            rs1R.signUnExtend();
            rs2R.signUnExtend();
            regD.value =
                rs1R.value < rs2R.value ? BigInt.from(1) : BigInt.from(0);
            // Convert back to internal 64 bit signed
            rs1R.signExtend();
            rs2R.signExtend();
            break;
          case RType_XOR:
            regD.value = rs1R.value ^ rs2R.value;
            break;
          case RType_SRL_SRA: // SRL
            // We need to unsign extend because this is a logical shift
            // which means zeroes appear in the MSb
            // rs1R.signUnExtend();
            // rs2R.signUnExtend();
            regD.value = rs1R.value >> rs2R.value.toInt();
            // Clear upper 32bits and 31st bit of lower
            rs1R.value = rs1R.value & BigInt.from(0x000000007fffffff);
            // rs1R.signExtend();
            // rs2R.signExtend();
            break;
          case RType_OR:
            regD.value = rs1R.value | rs2R.value;
            break;
          case RType_AND:
            regD.value = rs1R.value & rs2R.value;
            break;
        }
        break;
      case 1:
        switch (funct3.toInt()) {
          case RType_ADD_SUB:
            regD.value = rs1R.value - rs2R.value;
            break;
        }
        break;
    }
  }

  void _processSystems(BigInt rd, BigInt funct3, BigInt rs1, BigInt imm) {
    // ECALL or EBREAK
    switch (imm.toInt()) {
      case system_Ecall:
        break;
      case system_Ebreak:
        ebreakHit = true;
        break;
    }
  }
}

// -----------------------------------------------
// ----------- Field Extractions -----------------
// -----------------------------------------------
BigInt _extractOpcode(BigInt instruction) {
  // Bits 6-0
  // 00000000_00000000_00000000_01111111
  BigInt field = instruction & BigInt.from(0x0000007f);
  return field;
}

BigInt _extractImmDestination(BigInt instruction) {
  // Bits 11-7
  // 00000000_00000000_00001111_10000000
  BigInt field = instruction & BigInt.from(0x00000f80);
  field >>= 7;
  return field;
}

BigInt _extractFunct3(BigInt instruction) {
  // Bits 14-12
  // 00000000_00000000_01110000_00000000
  BigInt field = instruction & BigInt.from(0x00007000);
  field >>= 12;
  return field;
}

BigInt _extractImmSystem(BigInt instruction) {
  // Bits 31-12
  // 11111111_11111111_11110000_00000000
  BigInt field = instruction & BigInt.from(0xfffff000);
  field >>= 12;
  return field;
}

BigInt _extractImmBase(BigInt instruction) {
  // Bits 19-15
  // 00000000_00001111_10000000_00000000
  BigInt field = instruction & BigInt.from(0x000f8000);
  field >>= 15;
  return field;
}

BigInt _extractImmTypeUOffset(BigInt instruction) {
  // Bits 31-20
  // 11111111_11111111_11110000_00000000
  BigInt field = instruction & BigInt.from(0xfffff000);
  field >>= 12;
  return field;
}

BigInt _extractImmITypeOffset(BigInt instruction) {
  // 1) Isolate bits
  // Bits 31-20 = 12 bits
  // 11111111_11110000_00000000_00000000
  BigInt field = instruction & BigInt.from(0xfff00000);
  // 2) logical shift right
  field >>= 20;
  return field;
}

BigInt _extractImmRs2(BigInt instruction) {
  // Bits 24-20
  // 00000001_11110000_00000000_00000000
  BigInt field = instruction & BigInt.from(0x01f00000);
  field >>= 20;
  return field;
}

BigInt _extractFunct7(BigInt instruction) {
  // Bits 31-25
  // 11111110_00000000_00000000_00000000
  BigInt field = instruction & BigInt.from(0xfe000000);
  field >>= 25;
  return field;
}
