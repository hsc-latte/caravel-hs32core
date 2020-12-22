# HS32 Example Instruction 5

**Interrupts and AICT**

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
MOV   R0, 0xFF00
LDR   R1, R0

MOV   R2, 0x0BA0
MOV   R3, high(COND1)   ; 0x5000
MOV   R3, R3, 16        ; R3 <- (R3 << 16)
STR   R3, R2            ; [R2] <-- R3
MOV   R4, 0x0BA1
STR   R4, R0, 0x0010    ; STR     [Rm + imm] <- Rd

LDR   R5, R0, 0x0010

INT   0x0003
```

## Hexadecimal

```hex
0x 24 00 FF 00
0x 10 10 00 00

0x 24 20 0B A0
0x 24 30 50 00
0x 20 30 38 00
0x 30 23 00 00
0x 24 40 0B A1
0x 34 40 00 10

0x 14 50 00 10

0x 90 00 00 03
```

## Expected result

- [ ] `R0   = 0x`
- [ ] `R1   = 0x`
- [ ] `R2   = 0x`
- [ ] `R3   = 0x`
- [ ] `R4   = 0x`
- [ ] `R5   = 0x`
- [ ] `R6   = 0x`
- [ ] `R7   = 0x`
