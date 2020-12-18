Tests MOV, STR and LDR Variant 1

```
MOV r0 <- 0xCAFE
MOV r1 <- 5
STR [r1+1] <- r0
LDR r2 <- [r1+1]
B 0
```
Assembled
```
2400CAFE
24100005
34010001
14210001
50000000
```

Expected result
```
r0 = 0xCAFE
r1 = 5
r2 = 0xCAFE
```
