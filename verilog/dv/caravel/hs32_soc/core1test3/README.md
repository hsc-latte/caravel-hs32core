# HS32 Example Instruction 3

**MOV Variant 010 and 001**

The HS32 instruction format looks like this:

| Type   | Wire Format                               |
| ------ | ----------------------------------------- |
| I-Type | `oooo_oooo_dddd_mmmm iiii_iiii_iiii_iiii` |
| R-Type | `oooo_oooo_dddd_mmmm nnnn_ssss_sDDb_bxxx` |

The hexadecimal format looks like this:

| Type   | bram3.hex   | bram2.hex   | bram1.hex   | bram0.hex   |
| ------ | ----------- | ----------- | ----------- | ----------- |
| I-Type | `oooo_oooo` | `dddd_mmmm` | `iiii_iiii` | `iiii_iiii` |
| R-Type | `oooo_oooo` | `dddd_mmmm` | `nnnn_ssss` | `sDDb_bxxx` |

## Assembly

```assembly
MOV   R0 <-- 0x000F
MOV   R1_u <-- R0
MOV   R1 <-- R1_u

MOV   R0 <-- 0x00F0
MOV   R2_s <-- R0
MOV   R3 <-- R2_s

MOV   R0 <-- 0x0F00
MOV   R3_i <-- R0
MOV   R4 <-- R3_i

MOV   R0 <-- 0xF000
MOV   R5_f <-- R0
MOV   R6 <-- R5_f

BR    0
```

## Hexadecimal

```hex
0x 24 00 00 0F
0x 22 10 00 00
0x 21 11 00 00
0x 24 00 00 F0
0x 22 20 00 08
0x 21 32 00 08
0x 24 00 0F 00
0x 22 30 00 10
0x 21 43 00 10
0x 24 00 F0 00
0x 22 50 00 18
0x 21 65 00 18
0x 50 00 00 00
```

## Expected result

- [x] `R0   = 0xF000`
- [x] `R1   = 0x000F`
- [x] `R2   = 0x00F0`
- [x] `R3   = 0x00F0`
- [x] `R4   = 0x0F00`
- [x] `R5   = 0xF000`
- [x] `R6   = 0xF001`
- [x] `R1_u = 0x000F`
- [x] `R2_s = 0x00F0`
- [x] `R3_i = 0x0F00`
- [x] `R5_f = 0xF000`
