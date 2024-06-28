// ignore_for_file: constant_identifier_names

enum Abi {
  zero,
  ra,
  sp,
  gp,
  tp,
  t0,
  t1,
  t2,
  fp, // s0
  s1,
  a0,
  a1,
  a2,
  a3,
  a4,
  a5,
  a6,
  a7,
  s2,
  s3,
  s4,
  s5,
  s6,
  s7,
  s8,
  s9,
  s10,
  s11,
  t3,
  t4,
  t5,
  t6,
}

enum Form {
  byte,
  word,
}

enum DataSize {
  byte, //       0x00
  halfword, //   0x0000
  word, //       0x00000000
  doubleword, // 0x0000000000000000
}

// Opcode catagories
const system = 0x73; //      0b1110011
const loads = 0x03; //       0b0000011
const stores = 0x23; //      0b0000011
const immediates = 0x13; //  0b0010011
const lui = 0x37; //         0b0110111
const auipc = 0x17; //       0b0010111
const r_types = 0x33; //     0b0110011
const jal = 0x6f; //         0b1101111
const jalr = 0x67; //        0b1100111
const branches = 0x63; //    0b1100011

const Funct3_SizeByte = 0;
const Funct3_SizeHalfWord = 1;
const Funct3_SizeWord = 2;
const Funct3_SizeByteUnsigned = 4;
const Funct3_SizeHWUnsigned = 5;

const immType_ADDI = 0;
const immType_SLLI = 1;
const immType_SLTI = 2;
const immType_SLTIU = 3;
const immType_XORI = 4;
const immType_SRLI = 5;
const immType_SRAI = 5;
const immType_ORI = 6;
const immType_ANDI = 7;

const sbType_BEQ = 0;
const sbType_BNE = 1;
const sbType_BLT = 4;
const sbType_BGE = 5;
const sbType_BLTU = 6;
const sbType_BGEU = 7;

const RType_ADD_SUB = 0; // funct7 = 1 for SUB
const RType_SLL = 1;
const RType_SLT = 2;
const RType_SLTU = 3;
const RType_XOR = 4;
const RType_SRL_SRA = 5; // funct7 = 1 for SRA
const RType_OR = 6;
const RType_AND = 7;

const system_Ecall = 0;
const system_Ebreak = 1;

// LB, LHU/L, LW
const LW_Width = 2;

const Byte0 = 0; // LSB
const Byte1 = 1;
const Byte2 = 2;
const Byte3 = 3;

const HalfwordL = 0;
const HalfwordH = 1;
