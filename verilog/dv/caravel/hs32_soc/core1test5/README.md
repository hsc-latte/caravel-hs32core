# HS32 Example Instruction 4

**LDR and STR Variant 000**

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
MOV   R1 <-- 0x00F0
MOV   R2 <-- 0x0F00
MOV   R3 <-- 0xF000
MOV   R4 <-- 0x0BAD
MOV   R5 <-- 0x0B09

STR   R0, R4            ; [R4] <-- R0
LDR   R6, R4            ; R6 <-- [R4]

STR   R2, R5, R1        ; [R5 + (R1 << 2)] <- R2
LDR   R7, R5, R1        ; R7 <- [R5 + (R1 << 2)]

BR    0
```

## Hexadecimal

```hex
0x 24 00 00 0F
0x 24 10 00 F0
0x 24 20 0F 00
0x 24 30 F0 00
0x 24 40 0B AD
0x 24 50 0B 09

0x 30 04 00 00
0x 10 64 00 00

0x 31 25 11 00
0x 11 75 11 00

0x 50 00 00 00
```

## Expected result

- [x] `R0   = 0x000F`
- [x] `R1   = 0x00F0`
- [x] `R2   = 0x0F00`
- [x] `R3   = 0xF000`
- [x] `R4   = 0x0BAD`
- [x] `R5   = 0x0B09`
- [x] `R6   = 0x000F`
- [ ] `R7   = 0x0F00`
