# HS32 Example Instruction 6

**Branching Test**

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
MOV   PC, 0x0008
LDR   R0, PC
```

## Hexadecimal

```hex
0x 24 F0 00 00



0x 50 00 00 00
```

## Expected result

- [x] `R0   = 0xB412`
- [x] `R1   = 0xB412`
- [x] `R2   = 0x0ADD`
- [x] `R3   = 0x0BAD`
- [ ] `R4   = 0x0B09`
- [ ] `R5   = 0x21660000`
- [ ] `R6   = 0x0ADD`
- [ ] `R6_u = 0x0ADD`
- [ ] `R7   = 0x0ADD0000`
