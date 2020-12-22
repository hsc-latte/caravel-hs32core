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

MOV   R2, high(COND1)   ; 0x5000
MOV   R2, R2, 16        ; R2 <- (R2 << 16)
STR   R2, R0, 01        ; STR     [Rm + imm] <- Rd

LDR   R3, R0, 0x0010

INT
```

## Hexadecimal

```hex
0x 24 00 FF 00
0x 10 10 00 00

0x 24 20 50 00
0x 20 20 28 00
0x 34 20 00 10

0x 14 30 00 10

0x 90 00 00 10
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
