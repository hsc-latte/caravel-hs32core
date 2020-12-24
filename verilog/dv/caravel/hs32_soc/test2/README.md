# HS32 Example Instruction 2

**MOV Variant 000**

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

## Usage

Use `make` to run test.

Results should match the *Expected result* listed below.

Test will display `Passed all cases.` or `failed` message indicating errors.

## Assembly

```assembly
MOV   R0 <-- 0x03F1
MOV   R1 <-- (R0 << 1)
MOV   R2 <-- (R0 >> 1)
MOV   R3 <-- (R0 # 1)
MOV   R4 <-- (R0 >>> 1)
BR    0
```

## Hexadecimal

```hex
0x 24 00 03 F1
0x 20 10 00 80
0x 20 20 00 A0
0x 20 30 00 C0
0x 20 40 00 E0
0x 50 00 00 00
```

## Expected result

- [x] `R0 = 0x0000 03F1`
- [x] `R1 = 0x0000 07E2`
- [x] `R2 = 0x0000 01F8`
- [x] `R3 = 0x0000 01F8`
- [x] `R4 = 0x8000 01F8`