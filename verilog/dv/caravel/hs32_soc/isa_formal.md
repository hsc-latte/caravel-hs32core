```
                       HS32 CPU and ISA Documentation

                       By: Anthony Kung and Kevin Dai

                               (c) 2020 HSC
```
--------------------------------------------------------------------------------
0. Table of Contents

    1. Instruction Encoding Specification

        1.1 Instruction Type and Bit Layout

        1.2 Table for Shift Direction

        1.3 Table for Register Banks

        1.4 Register Descriptions
        
    2. ALU Instruction Table

    3. Internal Control Signals Specification

    4. Opcode Table and Instruction Decode Specification

    5. Execution Unit Overview

        5.1 Internal Busses (Input 1, 2 and Output Busses)

        5.2 Dual Port (Dual Read, Single Write) Register File

        5.3 Execution unit FSM
--------------------------------------------------------------------------------
## 1. Instruction Encoding Specification

### 1.1 Instruction Type and Bit Layout
```
Legend: o = opcode, d = Rd, m = Rm, n = Rn, i = imm, s = shift, x = don't care

        D = shift direction, b = source register bank*

Type    Wire Format

I-Type  oooo_oooo_dddd_mmmm iiii_iiii_iiii_iiii

R-Type  oooo_oooo_dddd_mmmm nnnn_ssss_sDDb_bxxx

* Bank field is only applicable to Rm variants of the R-Type
  MOV instructions varient 001 and 010, and will specify the
  bank from which Rn/Rm will come from. If nothing defined
  CPU default to Rn variant with code 000 and ignore the field
```
### 1.2 Table for Shift Direction
```
DD      Description
00      Left
01      Right
10      Sign extend right
11      ROR (ROR and ROL are equivalent in practice)
```
### 1.3 Table for Register Banks
```
bb      Bank name
00      User
01      Supervisor
10      IRQ
11      Flags
```
### 1.4 Register Descriptions
```
Code    User    Super   IRQ         Description

0000    r0_u    r0_s    (shared)    General purpose
...     ...     ...     ...         ...
1011    r11_u   r11_s   (shared)    ...
1100    r12_u   mcr_s   ivt_i       Machine Configuration/Interrupt Vector Table
1101    sp_u    sp_s    sp_i        General purpose/Stack pointer (optional)
1110    lr_u    lr_s    lr_i        Link register
1111    pc_u    pc_s    (shared)    Program counter

0000/11 flags   (    shared    )    Program status/flags register

When no suffix is provided, it is assumed the register specified
is of the current mode of execution.

* Note PC can only take on the role of Rm (it cannot be shifted)
```
--------------------------------------------------------------------------------
## 2. ALU Instruction Table
```
ALU     Name    Operation

0000 LATCH   NOP
0001 MOV     obus   <- ibus1, set NZCV
0010 ADD     obus   <- ibus1 + ibus2, store NZCV
0011 SUB     obus   <- ibus1 - ibus2, store NZCV
0100 AND     obus   <- ibus1 & ibus2, set NZCV
0101 OR      obus   <- ibus1 | ibus2, set NZCV
0110 XOR     obus   <- ibus1 ^ ibus2, set NZCV
0111 NOT     obus   <- ibus1 ~ ibus2, set NZCV
...
1010 ADC     obus   <- ibus1 + ibus2 + C, store NZCV
1011 SBC     obus   <- ibus1 - ibus2 - C, store NZCV
...

* ALL ALU Operations will set the NZCV flags but only
  those marked with store will actually store them in
  the Flag register, otherwise, setting will only expose
  the flags internally.
```
--------------------------------------------------------------------------------
## 3. Internal Control Signals Specification
```
dd      Destination (write to)
            00      Don't touch Rd
            01      Write ALU output to Rd
            10      Write DTR to Rd and ALU to MAR
            11      Write ALU output to MAR

r      Reverse Bus
             0      No Reverse          Rd  <- Rm - sh(Rn)
             1      Reverse Operand     Rd  <- sh(Rn) - Rm

* Applicable to SUB variants only, used for indicating
  operand reversal

sss    Input bus values
                    T1  T2   DTW (Clock cycle/Input bus)
            000     Ignored
            001         imm
            010     Rm  imm
            011     Rm  Rn
            100         Rn
            101     Rm  imm  Rd
            110     Rm  Rn   Rd

bbbb    Branch conditionals
                    Alias   Flag        Description
            0000    (none)  (none)      Ignored
            0001    eq       Z          Equal
            0010    ne      !Z          Not equal
            0011    cs       C          Carry set
            0100    nc      !C          No carry
            0101    ss       N          Sign set
            0110    ns      !N          No sign
            0111    ov       V          Overflow
            1000    nv      !V          No overflow
            1001    ab       C & !Z     Unsigned above
            1010    be      !C | Z      Unsigned below or equal
            1011    ge      !(N^V)      Signed greater than or equal
            1100    lt       N^V        Signed less than
            1101    gt      !Z & !(N^V) Signed greater than
            1110    le       Z | (N^V)  Signed less than or equal
            1111    (none)  (none)      Execute regardless

i       Bank Register Indicator
             0      Rm_b
             1      Rd_b

* Applicable to MOV Rm variants only
  Used to indicate bank register

f       Modify ALU Flags
?       Unused
DD      Shift mode
B       0 to ignore supplied register source bank information
```
--------------------------------------------------------------------------------
## 4. Opcode Table and Instruction Decode Specification
```
The "family" is 5 bits, split into a triplet [2:0] and duplet [4:3].
- If bit 3 is set, then bits 123 specifies the ALU operation exactly.
    - If bit 2 is set, then the operation result should NOT be written back
- If bit 3 is unset, then we treat [4:0] as one coherent family.

The "variant" is 3 bits [2:0]
- If 0 is set, the variant specifies an I type instruction

Combined, the family and variant form the 8-bit opcode of the instruction.
The last column specifies the control signals required for internal operation.

* All binary values on the table are specified left to right, MSB to LSB

Name                                  Type    Family  Var     dd_r_sss_bbbb_if?_DDB

- [x] LDR     Rd <- [Rm + imm]        I-Type  000 10  100     10_0_010_0000_000_000
- [x] LDR     Rd <- [Rm]              R-Type  000 10  000     10_0_010_0000_000_000
- [x] LDR     Rd <- [Rm + sh(Rn)]     R-Type  000 10  001     10_0_011_0000_000_DD0
* ctlsig: For LDR, set alu to ADD and imm to 0 (for variant 000 only)

- [x] STR     [Rm + imm] <- Rd        I-Type  001 10  100     11_0_101_0000_000_000
- [x] STR     [Rm] <- Rd              R-Type  001 10  000     11_0_101_0000_000_000
- [x] STR     [Rm + sh(Rn)] <- Rd     R-Type  001 10  001     11_0_110_0000_000_DD0
* ctlsig: For STR, set alu to ADD and imm to 0 (for variant 000 only)

- [x] MOV     Rd <- imm               I-Type  001 00  100     01_0_001_0000_000_000
- [x] MOV     Rd <- sh(Rn)            R-Type  001 00  000     01_0_100_0000_000_DD0
- [x] MOV     Rd <- Rm_b              R-Type  001 00  001     01_0_010_0000_000_001
- [x] MOV     Rd_b <- Rm              R-Type  001 00  010     01_0_010_0000_100_001
* ctlsig: Set imm to 0 for variants 001 and 010

ADD     Rd <- Rm + sh(Rn)       R-Type  010 00  000     01_0_011_0000_010_DD0
ADDC    Rd <- Rm + sh(Rn) + C   R-Type  010 00  001     01_0_011_0000_010_DD0
SUB     Rd <- Rm - sh(Rn)       R-Type  011 00  000     01_0_011_0000_010_DD0
RSUB    Rd <- sh(Rn) - Rm       R-Type  011 00  001     01_1_011_0000_010_DD0
SUBC    Rd <- Rm - sh(Rn) - C   R-Type  011 00  010     01_0_011_0000_010_DD0
RSUBC   Rd <- sh(Rn) - Rm - C   R-Type  011 00  011     01_1_011_0000_010_DD0
MUL     Rd <- Rm + sh(Rn)       R-Type  010 00  010     01_0_011_0000_010_DD0

ADD     Rd <- Rm + imm          I-Type  010 00  100     01_0_010_0000_010_000
ADDC    Rd <- Rm + imm + C      I-Type  010 00  101     01_0_010_0000_010_000
SUB     Rd <- Rm - imm          I-Type  011 00  100     01_0_010_0000_010_000
RSUB    Rd <- imm - Rm          I-Type  011 00  101     01_1_010_0000_010_000
SUBC    Rd <- Rm - imm - C      I-Type  011 00  110     01_0_010_0000_010_000
RSUBC   Rd <- imm - Rm - C      I-Type  011 00  111     01_1_010_0000_010_000

AND     Rd <- Rm & sh(Rn)       R-Type  100 00  000     01_0_011_0000_010_DD0
BIC     Rd <- Rm & ~sh(Rn)      R-Type  100 00  001     01_0_011_0000_010_DD0
OR      Rd <- Rm | sh(Rn)       R-Type  101 00  000     01_0_011_0000_010_DD0
XOR     Rd <- Rm ^ sh(Rn)       R-Type  110 00  000     01_0_011_0000_010_DD0
* assembly: NOT is the same as BIC Rd, ~0, Rn

AND     Rd <- Rm & imm          I-Type  100 00  100     01_0_010_0000_010_000
BIC     Rd <- Rm & ~imm         I-Type  100 00  101     01_0_010_0000_010_000
OR      Rd <- Rm | imm          I-Type  101 00  100     01_0_010_0000_010_000
XOR     Rd <- Rm ^ imm          I-Type  110 00  100     01_0_010_0000_010_000

CMP     Rm - sh(Rn)             R-Type  011 01  000     00_0_011_0000_010_DD0
CMP     Rm - imm                I-Type  011 01  100     00_0_010_0000_010_000
TST     Rm & sh(Rn)             R-Type  100 01  000     00_0_011_0000_010_DD0
TST     Rm & imm                I-Type  100 01  100     00_0_010_0000_010_000

B<c>    PC + Offset             I-Type  010 1c  ccc     00_0_000_cccc_000_000
B<c>L   PC + Offset             I-Type  011 1c  ccc     01_1_010_cccc_000_000
* ctlsig: For branching + link, set Rd = LR, Rm = PC, imm = offset, alu = mov

INT     imm8                    I-Type  100 10  000     00_0_000_0000_000_000
```
--------------------------------------------------------------------------------
## 5. Execution Unit Overview

### 5.1 Internal Busses (Input 1, 2 and Output Busses)
```
Register        Bus
MAR         <-  obus
DTW         <-  ibus1
DTR         ->  obus
REGOUTA     ->  ibus1
REGOUTB     ->  ibus2
REGINP      <-  obus
IMM         ->  ibus2
PC          ->  ibus1
PC          <-  obus
ALUA        <-  ibus1
ALUB        <-  ibus2
ALUO        ->  obus
```
### 5.2 Dual Port (Dual Read, Single Write) Register File
```
REGRADRA    ->  REGFILE (read select A)
REGOUTA     <-  REGFILE (read port A)
REGRADRB    ->  REGFILE (read address B)
REGOUTB     <-  REGFILE (read select B)
REGWADR     ->  REGFILE (write select)
REGINP      ->  REGFILE (write port)
```
### 5.3 Execution unit FSM
```
== Summary ==
Memory Read:    IDLE -> TR1 -> TM1 -> TW2 -> IDLE
Memory Read PC: IDLE -> TR1 -> TM1 -> TW2 -> TB2 -> IDLE
Memory Write:   IDLE -> TR1 -> TR2 -> TM2 -> IDLE
Register op:    IDLE -> TR1 -> IDLE
Register op PC: IDLE -> TR1 -> TB2 -> IDLE
B+L:            IDLE -> TB1 -> TR1 -> IDLE
B:              IDLE -> TB1 -> TR1 -> IDLE

== State transitions ==

Memory Read (w PC):
    IDLE
    (Read and compute address)
    -> TR1
    (Store address to mar)
    -> TM1
    (Request and wait)
    -> TW2
    (Write address to Rd, if Rd == PC, then TB2)
    (-> TB2)
    -> IDLE

Memory Write:
    IDLE
    (Read address to ibus2, ibus1 Rd)
    -> TR1
    (Store ibus1 to dtw)
    (Read address to ibus1, the address is computed)
    -> TR2
    (Store address to mar)
    -> TM2
    (Request and wait)
    -> IDLE

Register operation (w PC):
    IDLE
    (Read to ibus, compute)
    -> TR1
    (Store result)
    -> IDLE
```
### 5.4 Special Purpose Registers
 
#### 5.4.1 Contents of MCR
```
[31:16] 
[2:1]   CPU Mode bits
        - 00 supervisor
        - 01 interrupt
        - 1x user
[0]     INT Interrupt enable
```