import 'package:console3_noisolate/arithmetics.dart';
import 'package:console3_noisolate/convertions.dart';
import 'package:console3_noisolate/memory_mapped_devices.dart';
import 'package:console3_noisolate/register.dart';

import 'definitions.dart';

class CPU {
  late List<Register> regs;

  Register pc = Register(0);
  Register nextPc = Register(0);

  final MemoryMappedDevices devices;

  bool ebreakHit = false;
  bool branchTaken = false;

  CPU(this.devices) {
    regs = <Register>[];
    for (var i = 0; i < 32; i++) {
      regs.add(Register(0));
    }
    regs[0].isZeroRegister = true;
  }

  void reset({int resetVector = 0}) {
    ebreakHit = false;
    branchTaken = false;

    // Reset PC
    pc.reset(resetVector);

    for (var register in regs) {
      register.reset(0);
    }
  }

  int _fetch() {
    int inst = devices.read(pc.byInt);
    return inst;
  }

  void _decode(int instruction) {
    BigInt inst = BigInt.from(instruction);

    Convertions conv = Convertions(inst);
    Convertions pcc = Convertions(pc.value);
    // print(
    //     'Instruction: ${conv.toHexString(width: 32, withPrefix: true)} : ${conv.toBinString(width: 32)} <- pc: ${pcc.toHexString(width: 32, withPrefix: true)}');

    // Break down the bit fields of the instruction
    // Opcode catagory:
    BigInt opcode = _extractOpcode(inst);
    // conv.byInt = opcode.toInt();
    // print('opcode: ${conv.toHexString(width: 8, withPrefix: true)}');

    switch (opcode.toInt()) {
      case loads:
        BigInt rd = _extractImmDestination(inst); //     dest
        BigInt width = _extractFunct3(inst); //          funct3
        BigInt base = _extractImmBase(inst); //          rs1
        BigInt offset = _extractImmITypeOffset(inst); // imm

        _processLoads(rd, width, base, offset);
        break;
      case stores: // S-Type
        // Offset is a concatination of two immediate fields:
        // imm[11:5] from bits 31-25 OR-ed to imm[4:0] from bits 11-7.
        BigInt imm11_5 = _extractImmSTypeH(inst);
        BigInt imm4_0 = _extractImmSTypeL(inst);
        BigInt imm = imm11_5 | imm4_0; // aka Offset
        Arithmetics immSE = Arithmetics(imm);
        imm = immSE.signExtendDoubleWord();

        BigInt base = _extractImmBase(inst); //          rs1
        BigInt width = _extractFunct3(inst); //          funct3
        BigInt rs2 = _extractSTypeRs1(inst); //          rs1

        _processStores(width, base, rs2, imm);
        break;
      case immediates:
        // addi, slti[u], andi, ori, xori

        // Note: addi
        // https://stackoverflow.com/questions/50742420/risc-v-build-32-bit-constants-with-lui-and-addi
        // imm is a signed 12bit number and should be extended

        // Note: the destination reg and source reg could be the same.
        BigInt rd = _extractImmDestination(inst); //  dest
        BigInt type = _extractFunct3(inst); //        funct3
        BigInt src = _extractImmBase(inst); //        rs1/src
        BigInt imm = _extractImmITypeOffset(inst); // imm

        // Sign extend immediate but not for sltiu
        if (type.toInt() != immType_SLTIU) {
          Arithmetics ar = Arithmetics(imm);
          if (ar.isSigned(signMask: 0x0000000000000800)) {
            ar.signExtend(0xfffffffffffff000);
            imm = ar.value;
          }
        }

        _processImms(rd, type, src, imm);
        break;
      case lui: // Load upper immediate (aka 0-relative addressing)
        BigInt rd = _extractImmDestination(inst); //   dest

        //          20bits  12bits
        // R[rd] = {imm,    12b0}
        BigInt immv = inst & BigInt.from(0xfffff000);

        Register regD = regs[rd.toInt()];
        regD.value = immv;
        break;
      case auipc: // Add Upper Immediate to PC (aka pc-relative addressing)
        // https://stackoverflow.com/questions/52574537/risc-v-pc-absolute-vs-pc-relative
        // https://www.reddit.com/r/RISCV/comments/129qg6t/can_someone_pls_explain/

        // R[rs1] = PC + {imm, 20b0}
        // Assuming pc is at 0x800000ff.
        //   auipc x5, 0x00110   # imm = 0x00110
        //                       # x5 <-- 0x00110000 + 0x800000ff
        //   x5 will have 0x801100ff.
        // --- Or ---
        // # PC          # instruction        # what the instruction does
        // 0x40000000    auipc x5, 0x03000    x5 = PC + (0x3000<<12) => x5 == 0x43000000
        // 0x40000004    jalr x0, 0xc00(x5)   jump to: x5 + sign_extend(0xc00)
        BigInt rd = _extractImmDestination(inst); // dest
        // The immediate is already in the upper 20bits so no shift is required
        BigInt imm = inst & BigInt.from(0xfffff000);

        Register regD = regs[rd.toInt()];
        regD.value = pc.value + imm;
        break;
      case jal:
        // R[rd] = PC+4
        // PC = PC + {imm,1b0}
        // https://app.diagrams.net/#G11NnLLBjYj_xuIsl3dGMEg83GGtynpVWU#%7B%22pageId%22%3A%22C1d5v6QdsQlSAW47ZK7e%22%7D

        BigInt rd = _extractImmDestination(inst); // dest
        // imm is signed and half-word aligned (i.e multiply by 2 or '<< 1') TODO
        BigInt imm = _extractUJTypeImm(inst);

        // Sign extend based on bit 21
        Arithmetics ar = Arithmetics(imm);
        //   31    24 23    16 15     8 7      0
        //   00000000_00010000_00000000_00000000
        //               |sign
        if (ar.isSigned(signMask: 0x0000000000100000)) {
          // 11111111_11110000_00000000_00000000
          ar.signExtend(0xfffffffffff00000);
        }
        // Convertions c = Convertions(BigInt.zero);
        // c.value = ar.value;
        // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');

        Register regD = regs[rd.toInt()];
        regD.value = BigInt.from(pc.byInt + 4);

        // Set jump address
        // c.value = pc.value;
        // print(
        //     '${c.toHexString(width: 32)} : ${c.toBinString(width: 32)} <- pc');
        // pc.byInt = (pc.value + ar.value).toInt();
        BigInt sum = pc.value + ar.value;

        // Remove carry over into upper bits (31-21)
        // 31    24 23    16 15     8 7      0
        // 00000000_00100000_00000100_00000100   <- carry over
        // 00000000_00011111_11111111_11111100   <- sum
        // 00000000_00011111_11111111_11111111   <- removal mask
        nextPc.value = sum & BigInt.from(0x001fffff);
        // c.value = nextPc.value;
        // print(
        //     '${c.toHexString(width: 32)} : ${c.toBinString(width: 32)} <- pc + imm');
        break;
      case jalr:
        // R[rd] = PC + 4
        // PC = R[rs1]+imm
        // The LSb of the branch address is set to 0 (NOT shifted!)

        BigInt rd = _extractImmDestination(inst); // dest
        // imm is signed
        BigInt imm = _extractImmITypeOffset(inst);

        // Sign extend based on bit 11
        Arithmetics ar = Arithmetics(imm);
        //   31    24 23    16 15     8 7      0
        //   00000000_00000000_00001000_00000000
        //                         |sign
        if (ar.isSigned(signMask: 0x0000000000000800)) {
          // 11111111_11111111_11110000_00000000
          ar.signExtend(0xfffffffffffff000);
        }

        BigInt base = _extractImmBase(inst); //        rs1/base
        Register rs1 = regs[base.toInt()];

        // funct3 = 0
        // pc.byInt = (rs1.value + ar.value).toInt();
        BigInt sum = (rs1.value + ar.value);

        Register regD = regs[rd.toInt()];
        regD.value = BigInt.from(pc.byInt + 4);

        // Remove carry over into upper bits above bit11
        // 31    24 23    16 15     8 7      0
        // 00000000_00100000_00000100_00000100   <- carry over
        // 00000000_00000000_00001111_11111111   <- removal mask
        nextPc.value = sum & BigInt.from(0x00000fff);

        break;
      case r_types:
        // add, slt, sltu, and, or, xor, sll, srl, sub, sra
        BigInt rd = _extractImmDestination(inst); // dest
        BigInt funct3 = _extractFunct3(inst); //     funct3
        BigInt rs1 = _extractImmBase(inst); //       rs1/src
        BigInt rs2 = _extractImmRs2(inst); //        rs1/src
        BigInt funct7 = _extractFunct7(inst); //     funct3

        _processRTypes(rd, funct3, rs1, rs2, funct7);
        break;
      case branches:
        // PC-relative addressing. The offset is signed extended
        // multiplied by 2 (aka << 1)
        BigInt imm = _extractSBTypeImm(inst); // dest
        BigInt funct3 = _extractFunct3(inst); //     funct3
        BigInt rs1 = _extractImmBase(inst); //       rs1/src
        BigInt rs2 = _extractImmRs2(inst); //        rs1/src

        _processBranches(imm, funct3, rs1, rs2);
        break;
      case system:
        BigInt rd = _extractImmDestination(inst); //  dest
        BigInt funct3 = _extractFunct3(inst); //      funct3
        BigInt rs1 = _extractImmBase(inst); //        rs1/src
        BigInt imm = _extractImmSystem(inst); // imm

        _processSystems(rd, funct3, rs1, imm);
        break;
      default:
        throw Exception(
            'Unknown opcode ${conv.toHexString(width: 8, withPrefix: true)}');
    }

    switch (opcode.toInt()) {
      case jal:
      case jalr:
        break;
      default:
        if (!branchTaken) {
          nextPc.value = pc.value + BigInt.from(4);
        } else {
          branchTaken = false;
        }
        break;
    }
  }

  void execute(int instructionCount) {
    // Convertions c = Convertions(BigInt.zero);

    for (var i = 0; i < instructionCount; i++) {
      // c.byInt = pc.byInt;
      // print('pc: ${c.toHexString(width: 32, withPrefix: true)}');

      nextInstruction();

      if (ebreakHit) {
        // print('System Ebreak reached!');
        break;
      }
    }
  }

  void nextInstruction() {
    if (!ebreakHit) {
      int instruction = _fetch();

      _decode(instruction);

      pc.byInt = nextPc.byInt;
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
        break;
      case Funct3_SizeHalfWord:
        Arithmetics ar = Arithmetics.fromInt(data);
        ar.signExtendHalfWord();
        reg.value = ar.value;
        break;
      case Funct3_SizeByte:
        Arithmetics ar = Arithmetics.fromInt(data);
        ar.signExtendByte();
        reg.value = ar.value;
        break;
      case Funct3_SizeByteUnsigned:
        Arithmetics ar = Arithmetics.fromInt(data);
        reg.value = ar.keepLowerByte();
        break;
      case Funct3_SizeHWUnsigned:
        Arithmetics ar = Arithmetics.fromInt(data);
        reg.value = ar.keepLowerHalfword();
        break;
    }
    Convertions conv = Convertions(reg.value);
    print(conv.toHexString());
  }

  void _processStores(BigInt width, BigInt rs1, BigInt rs2, BigInt imm) {
    // M[R[rs1] + imm] = R[rs2](7:0)
    Register regRs1 = regs[rs1.toInt()]; // base
    Register regRs2 = regs[rs2.toInt()]; // src

    // Address is in byte-form and must be Word aligned
    BigInt address = regRs1.value + imm; // byte-form

    switch (width.toInt()) {
      case Funct3_SizeByte:
        // Store lower 8bits at address

        // offset (aka imm, in bytes) is 12bits signed +-2048
        // byte select = offset % 4

        // Locate which Byte within Word
        // 0 means Word aligned.
        int byteSelect = address.toInt() % 4;
        int value = (regRs2.value << (byteSelect * 8)).toInt();
        // int value = (regRs2.value >> (byteSelect * 8)).toInt();

        int writeMask = 0;
        switch (byteSelect) {
          case Byte0:
            writeMask = 0xffffff00;
            break;
          case Byte1:
            writeMask = 0xffff00ff;
            break;
          case Byte2:
            writeMask = 0xff00ffff;
            break;
          case Byte3:
            writeMask = 0x00ffffff;
            break;
        }

        devices.write(address, value, writeMask: writeMask);
        break;
      case Funct3_SizeHalfWord:
        // Locate which Halfword within Word
        int halfSelect = address.toInt() % 2;
        int value = (regRs2.value << (halfSelect * 16)).toInt();

        int writeMask = 0;
        switch (halfSelect) {
          case HalfwordL:
            writeMask = 0xffff0000;
            break;
          case HalfwordH:
            writeMask = 0x0000ffff;
            break;
        }

        devices.write(address, value, writeMask: writeMask);
        break;
      case Funct3_SizeWord:
        devices.write(address, regRs2.value.toInt(), writeMask: 0xffffffff);
        break;
    }
  }

  void _processImms(BigInt rd, BigInt type, BigInt src, BigInt imm) {
    // rd = R[src] + imm
    switch (type.toInt()) {
      case immType_ADDI:
        Register regS = regs[src.toInt()];
        Register regD = regs[rd.toInt()];
        regD.value = regS.value + imm;
        break;
      case immType_SLTI:
        Register regS = regs[src.toInt()];
        Register regD = regs[rd.toInt()];
        regD.value = regS.value < imm ? BigInt.from(1) : BigInt.from(0);
        break;
      case immType_XORI:
        Register regS = regs[src.toInt()];
        Register regD = regs[rd.toInt()];
        regD.value = regS.value ^ imm;
        break;
      case immType_ORI:
        Register regS = regs[src.toInt()];
        Register regD = regs[rd.toInt()];
        regD.value = regS.value | imm;
        break;
      case immType_ANDI:
        Register regS = regs[src.toInt()];
        Register regD = regs[rd.toInt()];
        regD.value = regS.value & imm;
        break;
      case immType_SRLI:
        Register regS = regs[src.toInt()];
        Register regD = regs[rd.toInt()];
        // Zeroes fill from left.
        regD.value = regS.value >> imm.toInt();
        break;
      case immType_SLLI:
        Register regS = regs[src.toInt()];
        Register regD = regs[rd.toInt()];
        // Zeroes fill from right.
        regD.value = regS.value << imm.toInt();
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
            regD.value = rs1R.value >> rs2R.value.toInt();
            // Clear upper 32bits and 31st bit of lower
            rs1R.value = rs1R.value & BigInt.from(0x000000007fffffff);
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
          case immType_SRAI:
            regD.value = rs1R.value >> rs2R.value.toInt();
            // Replicates sign bit (bit 31), should fill with '1's
            //
            rs1R.value = rs1R.value | BigInt.from(0x0000000080000000);
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

  void _processBranches(BigInt imm, BigInt funct3, BigInt rs1, BigInt rs2) {
    branchTaken = false;
    Register rs1R = regs[rs1.toInt()];
    Register rs2R = regs[rs2.toInt()];

    switch (funct3.toInt()) {
      case sbType_BEQ:
        branchTaken = rs1R.value == rs2R.value;
        break;
      case sbType_BNE:
        branchTaken = rs1R.value != rs2R.value;
        break;
      case sbType_BLT:
        branchTaken = rs1R.value < rs2R.value;
        break;
      case sbType_BGE:
        branchTaken = rs1R.value > rs2R.value;
        break;
      case sbType_BLTU:
        Arithmetics ar1 = Arithmetics.fromInt(rs1R.value.toInt());
        ar1.keepLowerWord();
        Arithmetics ar2 = Arithmetics.fromInt(rs2R.value.toInt());
        ar2.keepLowerWord();
        branchTaken = ar1.value < ar2.value;
        break;
      case sbType_BGEU:
        Arithmetics ar1 = Arithmetics.fromInt(rs1R.value.toInt());
        ar1.keepLowerWord();
        Arithmetics ar2 = Arithmetics.fromInt(rs2R.value.toInt());
        ar2.keepLowerWord();
        branchTaken = ar1.value > ar2.value;
        break;
    }

    // Remove carry over into upper bits above bit11
    // 31    24 23    16 15     8 7      0
    // 00000000_00100000_00000100_00000100   <- carry over
    // 00000000_00000000_00001111_11111111   <- removal mask
    if (branchTaken) {
      nextPc.value = (pc.value + imm) & BigInt.from(0x00000fff);
      Convertions c = Convertions(BigInt.zero);
      c.value = nextPc.value;
      // print(
      //     '${c.toHexString(width: 32)} : ${c.toBinString(width: 32)} <- nextPc');
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
  // 11111111_11110000_00000000_00000000
  BigInt field = instruction & BigInt.from(0xfff00000);
  field >>= 20;
  return field;
}

BigInt _extractImmBase(BigInt instruction) {
  // Bits 19-15
  // 00000000_00001111_10000000_00000000
  BigInt field = instruction & BigInt.from(0x000f8000);
  field >>= 15;
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

BigInt _extractImmSTypeH(BigInt instruction) {
  // Bits 31-25
  // 11111110_00000000_00000000_00000000
  BigInt field = instruction & BigInt.from(0xfe000000);
  // We don't shift by 25 because we want the high immediate
  // in the upper bit positions.
  field >>= 25 - 7;
  return field;
}

BigInt _extractImmSTypeL(BigInt instruction) {
  // Bits 11-7
  // 00000000_00000000_00000111_10000000
  BigInt field = instruction & BigInt.from(0x00000780);
  // Shift all the way to end
  field >>= 7;
  return field;
}

BigInt _extractSTypeRs1(BigInt instruction) {
  // Bits 24-20
  // 00000001_11110000_00000000_00000000
  BigInt field = instruction & BigInt.from(0x01f00000);
  // Shift all the way to end
  field >>= 20;
  return field;
}

// For 'Jal' instruction
BigInt _extractUJTypeImm(BigInt instruction) {
  // imm is formed by swizzling bits and multiplying by 2
  // which is the same as concatinating a zero -> {imm,1b0}
  //        31  30-21 20 19-12
  // imm = [20 | 10:1|11|19:12]
  //         1   10    1   8     <-- bits per section
  BigInt imm = BigInt.zero;
  BigInt isolateMask = BigInt.zero;

  // Convertions c = Convertions(BigInt.zero);

  // 31    24 23    16 15     8 7      0
  // 11111111_11111111_11110000_00000000
  BigInt simm = instruction & BigInt.from(0xfffff000);
  // c.value = simm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');

  // --------- Bit 31 of instruction ----------------
  // Moves bit 31 of instruction to bit 20 of immediate
  // 31    24 23    16 15     8 7      0
  // 10000000_00000000_00000000_00000000
  // 00000000_00010000_00000000_00000000    <- isolate mask
  //             |20
  isolateMask = BigInt.from(0x00100000);
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt shift = instruction >> 11; // Shift bit 31 to bit 11
  // c.value = shift;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f31 = shift & isolateMask; // Isolate
  // c.value = f31;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f31; // Merge
  // c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  // --------- Bits 30-21 of instruction ----------------
  // 31    24 23    16 15     8 7      0
  // 01111111_11100000_00000000_00000000
  // 00000000_00000000_00000111_11111110    <- isolate mask
  //                                  |1
  isolateMask = BigInt.from(0x000007fe);
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // Shift bits of instruction to bits of immediate
  shift = instruction >> 20;
  // c.value = shift;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f30_21 = shift & isolateMask; // Isolate
  // c.value = f30_21;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f30_21; // Merge
  // c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  // --------- Bit 20 of instruction ----------------
  // 31    24 23    16 15     8 7      0
  // 00000000_00010000_00000000_00000000
  // 00000000_00000000_00001000_00000000    <- isolate mask
  //                       |11
  isolateMask = BigInt.from(0x00000800);
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // Shift bit 20 of instruction to bit 11 of immediate
  shift = instruction >> 9;
  // c.value = shift;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f20 = shift & isolateMask; // Isolate
  // c.value = f20;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f20; // Merge
  // c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  // --------- Bits 19-12 of instruction ----------------
  // Bits 19-12 are already in position.
  // 31    24 23    16 15     8 7      0
  // 00000000_00001111_11110000_00000000
  // 00000000_00001111_11110000_00000000    <- isolate mask
  //              |19                  | always zero for halfword alignment.
  isolateMask = BigInt.from(0x000ff000);
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f19_12 = instruction & isolateMask;
  // c.value = f19_12;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f19_12; // Merge
  // c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  return imm;
}

BigInt _extractSBTypeImm(BigInt instruction) {
  Convertions c = Convertions(BigInt.zero);

  BigInt imm = BigInt.zero;
  BigInt isolateMask = BigInt.zero;

  // c.value = instruction;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)} <- instr');

  // imm is formed by swizzling bits: 31-25, 11-7
  //      instruction           imm
  // Bits      11-8      ->     4-1
  // Bit         7       ->      11
  // Bit        31       ->      12
  // Bits      30-25     ->     10-5

  // Bits of instructions carrying imm value
  // 11111110_00000000_00001111_10000000

  // 00000000_01100010_10010110_01100011
  //                       ----

  // --------- Move bits 11-8 of instruction to bits 4-1 of imm
  // 31    24 23    16 15     8 7      0
  // 11111110_00000000_0000----_10000000
  // 00000000_00000000_00001111_00000000
  // to
  // 00000000_00000000_00000000_00011110  <- mask
  //                               |4
  isolateMask = BigInt.from(0x0000001e); // isolate 4 bits
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt shift = instruction >> 7;
  // c.value = shift;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f4_1 = shift & isolateMask; // Isolate
  // c.value = f4_1;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f4_1; // Merge
  c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  // --------- Move bit 7 of instruction to bit 11 of imm
  // 31    24 23    16 15     8 7      0
  // 11111110_00000000_00001111_-0000000
  // 00000000_00000000_00000000_10000000
  // to                         |7
  // 00000000_00000000_00001000_00000000  <- mask
  //                       |11
  isolateMask = BigInt.from(0x00000800); // isolate mask
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  shift = instruction << 4;
  // c.value = shift;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f11 = shift & isolateMask; // Isolate
  // c.value = f11;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f11; // Merge
  // c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  // --------- Move bit 31 of instruction to bit 12 of imm
  // 31    24 23    16 15     8 7      0
  // -1111110_00000000_00001111_10000000
  // 10000000_00000000_00000000_00000000
  // to
  // 00000000_00000000_00010000_00000000  <- mask
  //                      |12
  isolateMask = BigInt.from(0x00001000); // isolate mask
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  shift = instruction >> 19;
  // c.value = shift;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f31 = shift & isolateMask; // Isolate
  // c.value = f31;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f31; // Merge
  // c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  // --------- Move bits 30-25 of instruction to bits 10-5 of imm
  // 31    24 23    16 15     8 7      0
  // 1------0_00000000_00001111_10000000
  // 01111110_00000000_00000000_00000000
  // to
  // 00000000_00000000_00000111_11100000  <- mask
  //                        |10
  isolateMask = BigInt.from(0x000007e0); // isolate mask
  // c.value = isolateMask;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  shift = instruction >> 20;
  // c.value = shift;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  BigInt f30_25 = shift & isolateMask; // Isolate
  // c.value = f30_25;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  imm = imm | f30_25; // Merge
  // c.value = imm;
  // print('${c.toHexString(width: 32)} : ${c.toBinString(width: 32)}');
  // print('------------------------');

  // 31    24 23    16 15     8 7      0
  // 00000000_00000000_00001111_11111111  <- 12bit clear mask
  imm = imm & BigInt.from(0x00000fff);

  return imm;
}
