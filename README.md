# HSC Latte HS32 Core

The HSC Latte HS32 Core is a 32-bits RISC CPU. The HS32 Core has 32-bits instructions and 16 32-bits registers.

Below is a list of HS32 Core Project Directories:

| Repository                                                        | Description             | License                                                                      | Issues                                                                     | Stars                                                                    | Contributors                                                                           |
| ----------------------------------------------------------------- | ----------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| [caravel-hs32core](https://github.com/hsc-latte/caravel-hs32core) | Core Harness            | ![License](https://img.shields.io/github/license/hsc-latte/caravel-hs32core) | ![Issues](https://img.shields.io/github/issues/hsc-latte/caravel-hs32core) | ![Stars](https://img.shields.io/github/stars/hsc-latte/caravel-hs32core) | ![Contributors](https://img.shields.io/github/contributors/hsc-latte/caravel-hs32core) |
| [hs32core-rtl](https://github.com/hsc-latte/hs32core-rtl)         | RTL Circuit Design      | ![License](https://img.shields.io/github/license/hsc-latte/hs32core-rtl)     | ![Issues](https://img.shields.io/github/issues/hsc-latte/hs32core-rtl)     | ![Stars](https://img.shields.io/github/stars/hsc-latte/hs32core-rtl)     | ![Contributors](https://img.shields.io/github/contributors/hsc-latte/hs32core-rtl)     |
| [hs32core](https://github.com/hsc-latte/hs32core)                 | Main Project Repository | ![License](https://img.shields.io/github/license/hsc-latte/hs32core)         | ![Issues](https://img.shields.io/github/issues/hsc-latte/hs32core)         | ![Stars](https://img.shields.io/github/stars/hsc-latte/hs32core)         | ![Contributors](https://img.shields.io/github/contributors/hsc-latte/hs32core)         |

## Content
1. [Intro](#intro)
2. [Docs](#docs)
3. [Install](#install)
4. [Usage](#usage)
5. [Contributing](#contributing)
6. [Security](#security)
7. [License](#license)

## Intro

### Instructions

- Immediate value is 16-bits
- Rd, Rn and Rm specify the way each register is wired to the ALU. In this case,
  Rd represents the read/write source/destination, Rm and Rn represents the 2 operands fed into the ALU; note that Rn will always have a barrel
  shifter in front of it.
- Naming a register with Rd Rn Rm is always 4 bits
- [xxx] = Dereference pointer, address is stored in xxx
- sh(Rn) shifts contents of Rn left or right by an 5-bits amount

#### Encoding

These are the different encodings that instructions come in.
All instructions are 32 bit.
The first 8 bits is opcode.
Rd, Rm, Rn are always in the same position in the instruciton if present
<X> indicates unused spacer value of X bits

- Field Sizes:
  - Rd : 4 bit register name
  - Rm : 4 bit register name
  - Rn : 4 bit register name
  - Shift: 5 bit shift amount applied to Rn
  - Imm16: 16 bit literal field

<div class="ritz grid-container" dir="ltr"><table class="waffle" cellspacing="0" cellpadding="0"><thead><tr><th class="row-header freezebar-origin-ltr"></th>
  <th id="1092009867C0" style="width:121px" class="column-headers-background">A</th>
  <th id="1092009867C1" style="width:100px" class="column-headers-background">B</th>
  <th id="1092009867C2" style="width:100px" class="column-headers-background">C</th>
  <th id="1092009867C3" style="width:100px" class="column-headers-background">D</th>
  <th id="1092009867C4" style="width:100px" class="column-headers-background">E</th>
  <th id="1092009867C5" style="width:100px" class="column-headers-background">F</th>
  <th id="1092009867C6" style="width:100px" class="column-headers-background">G</th>
  <th id="1092009867C7" style="width:100px" class="column-headers-background">H</th>
  <th id="1092009867C8" style="width:100px" class="column-headers-background">I</th></tr></thead><tbody>

<tr style='height:20px;'>
  <th id="1092009867R0" style="height: 20px;" class="row-headers-background">
    <div class="row-header-wrapper" style="line-height: 20px;">1</div>
  </th>
  <td class="s0" dir="ltr">Name</td>
  <td class="s0" dir="ltr">[0:3]  </td>
  <td class="s0" dir="ltr">[4:7]  </td>
  <td class="s0" dir="ltr">[8:11] </td>
  <td class="s0" dir="ltr">[12:15]</td>
  <td class="s0" dir="ltr">[16:19]</td>
  <td class="s0" dir="ltr">[20:23]</td>
  <td class="s0" dir="ltr">[24:27]</td>
  <td class="s0" dir="ltr">[28:31]</td>
</tr>

<tr style='height:20px;'>
  <th id="1092009867R1" style="height: 20px;" class="row-headers-background">
    <div class="row-header-wrapper" style="line-height: 20px;">2</div>
  </th>
  <td class="s1" dir="ltr">I-Type<br/>(Immediate)</td>
  <td class="s0" dir="ltr" colspan="2">Opcode</td>
  <td class="s0" dir="ltr">Rd</td>
  <td class="s0" dir="ltr">Rm</td>
  <td class="s0" dir="ltr" colspan="4">Imm16</td>
</tr>

<tr style='height:20px;'>
  <th id="1092009867R3" style="height: 20px;" class="row-headers-background">
    <div class="row-header-wrapper" style="line-height: 20px;">5</div>
  </th>
  <td class="s0" dir="ltr">R-Type<br/>(Register)</td>
  <td class="s0" dir="ltr" colspan="2">Opcode</td>
  <td class="s0" dir="ltr" colspan="1">Rd</td>
  <td class="s0" dir="ltr" colspan="1">Rm</td>
  <td class="s0" dir="ltr" colspan="1">Rn</td>
  <td class="s0" dir="ltr" colspan="1">Shift</td>
  <td class="s0" dir="ltr" colspan="1">Shift | Shift Direction | Register Bank</td>
  <td class="s0" dir="ltr" colspan="1">Register Bank | XXX</td>
</tr>

<!--<tr style='height:20px;'>
  <th id="1092009867R3" style="height: 20px;" class="row-headers-background">
    <div class="row-header-wrapper" style="line-height: 20px;">6</div>
  </th>
  <td class="s0" dir="ltr">Jump Type (J-Type)</td>
  <td class="s0" dir="ltr" colspan="2">Opcode</td>
  <td class="s0" dir="ltr" colspan="1">Rd</td>
  <td class="s0" dir="ltr" colspan="1">Unused</td>
  <td class="s0" dir="ltr" colspan="4">16-bit Address or first half of 32-bit Address</td>
</tr>-->
</tbody></table></div>

#### System Details

There are 16 (r0-r15) general-purpose registers plus 4 privileged registers.
In supervisor mode, r12-15 is separate from user-mode r12-15. In all modes, r14 and r15 will be used as the link register and stack pointer respectively.

Legend:

- **IRQs** -- Interrupt Requests
- **SP** -- Stack Pointer
- **LR** -- Link Register
- **MCR** -- Machine Configuration Register
- **IVT** -- Interrupt Vector Table

<table border=0 cellpadding=0 cellspacing=0 width=543>
 <tr height=19>
  <td rowspan=2 height=38 width=64>Register</td>
  <td colspan=3 width=287>Alias/Description</td>
 </tr>
 <tr height=19>
  <td height=19>User</td>
  <td>IRQ</td>
  <td>Supervisor</td>
 </tr>
 <tr height=19>
  <td height=19>r0-r11</td>
  <td colspan=3><center>Shared general purpose registers</center></td>
 </tr>
 <tr height=19>
  <td height=19>r12</td>
  <td>General</td>
  <td colspan=2><center>Interrupt Vector Table</center></td>
 </tr>
 <tr height=19>
  <td height=19>r13</td>
  <td>General</td>
  <td colspan=2><center>Machine Configuration Register</center></td>
 </tr>
 <tr height=19>
  <td height=19>r14</td>
  <td>User LR</td>
  <td>IRQ LR</td>
  <td>Super LR</td>
 </tr>
 <tr height=19>
  <td height=19>r15</td>
  <td>User SP</td>
  <td>IRQ SP</td>
  <td>Super SP</td>
 </tr>
</table>

##### Operation

During a mode switch, the return address will be stored in the appropriate LR and the return stack pointer will be stored in the appropriate SP.

For instance, an interrupt call from User mode will prompt a switch to IRQ mode. The return address and stack pointer of the caller will be stored in IRQ LR (r14) and IRQ SP (r15) respectively.

### CPU

#### Planned Pinout

| Pin # | Name | Description |
|-|-|-|
| 0-15 | IO0-15 | **Address/Data Parallel Bus:** These lines contain the time-multiplexed address (T<sub>1</sub>, T<sub>2</sub>)<br>and data (T<sub>W</sub>, T<sub>4</sub>) buses. During the T<sub>1</sub> cycle, bits A<sub>0</sub>-A<sub>7</sub> of the address bus is outputted.<br>Bit A<sub>0</sub> is the BLE# signal. It is LOW during T<sub>1</sub> if only the low 8-bits is to be transferred<br>during memory or I/O operations. |
| 16 | ALE0 | **Address Latch Enable (LOW):** HIGH during T<sub>1</sub> to signal for the latching of the low 8-bits<br>of the address signal. It is LOW otherwise. |
| 17 | ALE1 | **Address Latch Enable (HIGH):** HIGH during T<sub>2</sub> to signal for the latching of the high 8-bits<br>of the address signal. It is LOW otherwise. |
| 18 | WE# | **Write Enable:** Write strobe is LOW during T<sub>W</sub> to indicate that the processor is performing<br>an I/O or memory write operation. |
| 19 | OE# | **Output Enable:** When LOW, indicates that the processor IO lines are ready<br>to accept/output data. It is held HIGH during T<sub>1</sub> and T<sub>2</sub>. |
| 20 | BHE# | **Bus High Enable:** When LOW, signals for the high 8-bits to be transferred<br>during memory or I/O operations. |
| 22 | PIO | **IO Mode:** When HIGH, indicates that the current operation is an I/O, not memory, operation.<br>This results in the omittance of cycle T<sub>2</sub>. |
| 23, 24 | RX, TX | 9600 Baud UART Interface |
| 25-... | GPIO0-... | General Purpose Input/Output |

#### Overview

![CPU Overview](/images/CPU-Overview.png)

#### Devboard Block Diagram
![](images/cpu-block.svg)

#### Timing Waveforms

Various timing diagrams of the address and data buses

##### Read Cycle

Clock Cycles: 4 minimum

Timing Requirements:
- The duration of the T<sub>W</sub> read clock (no data input) is determined by the `tpd` of whichever memory chip used.
- T<sub>W</sub> can span multiple clock periods to allow for different memory timings. This will allow the CPU to be clocked at a higher speed than the memory chips.

In the implementation, OE# is the AND of 2 signals, one leading edge and one falling edge-driven signals.

<!-- WAVEDROM JSON FILE
{ signal: [
  { name: "CLK",		wave: "hlhlhlhlhlh", node: "..1.2.3.4.5" },
  { name: "ALE0",		wave: "xh.l......x" },
  { name: "ALE1",		wave: "xl.h.l....." },
  { name: "WE#",		wave: "h.........." },
  { name: "OE#",		wave: "h.....l..h." },
  { name: "BHE#",		wave: "x.h.......x" },
  { name: "IO[15:0]",	wave: "x.9.9.x.5.x", data:[ "A[15:0]", "A[31:16]", "D[15:0]" ] },],
  head: { text: "Figure 1. Read Cycle Timing Waveform" },
  edge: [ '1<->2 T1', '2<->3 T2', '3<->4 TW', '4<->5 T3' ]
} -->

![](images/cpu-wave1.svg)

##### Write Cycle

Clock Cycles: 4 minimum

Timing Requirements:
- See the read cycle specifications

<!-- WAVEDROM JSON FILE
{ signal: [
  { name: "CLK",		wave: "hlhlhlhlhlh", node: "..1.2.3.4.5" },
  { name: "ALE0",		wave: "xh.l......x" },
  { name: "ALE1",		wave: "xl.h.l....." },
  { name: "WE#",		wave: "h.....l.h.." },
  { name: "OE#",		wave: "h.....l..h." },
  { name: "BHE#",		wave: "x.h.......x" },
  { name: "IO[15:0]",	wave: "x.9.9.7.x..", data:[ "A[15:0]", "A[31:16]", "D[15:0]" ] },],
  head: { text: "Figure 2. Write Cycle Timing Waveform" },
  edge: [ '1<->2 T1', '2<->3 T2', '3<->4 TW', '4<->5 T3' ]
} -->
![](images/cpu-wave2.svg)

#### Execution Unit

![Execution Unit](/images/Execution-Overview.png)

## Docs

### Directories

**HS32 RTL** -- [`verilog/rtl/hs32cpu`](https://github.com/hsc-latte/hs32core-rtl)

**Documentation** -- [`verilog/rtl/hs32cpu/docs`](https://github.com/hsc-latte/hs32core-rtl/tree/master/docs)

**Testbenches** -- [`verilog/rtl/hs32cpu/bench`](https://github.com/hsc-latte/hs32core-rtl/tree/master/bench)

**CPU Modules** -- [`verilog/rtl/hs32cpu/cpu`](https://github.com/hsc-latte/hs32core-rtl/tree/master/cpu)

**Frontend Modules** -- [`verilog/rtl/hs32cpu/frontend`](https://github.com/hsc-latte/hs32core-rtl/tree/master/frontend)

**SOC Modules** -- [`verilog/rtl/hs32cpu/soc`](https://github.com/hsc-latte/hs32core-rtl/tree/master/soc)

**Third Party Modules** -- [`verilog/rtl/hs32cpu/third_party`](https://github.com/hsc-latte/hs32core-rtl/tree/master/third_party)

**Programmer** -- [`verilog/rtl/hs32cpu/programmer`](https://github.com/hsc-latte/hs32core-rtl/tree/master/programmer)

**Openlane** -- [`verilog/rtl/hs32cpu/openlane`](https://github.com/hsc-latte/hs32core-rtl/tree/master/openlane)

**Skywater** -- [`verilog/rtl/hs32cpu/skywater`](https://github.com/hsc-latte/hs32core-rtl/tree/master/skywater)

### Files

**HS32 ISA** -- [`verilog/rtl/hs32cpu/docs/isa_formal.txt`](https://github.com/hsc-latte/hs32core-rtl/tree/master/docs/isa_formal.txt)

**Top Level Module** -- [`verilog/rtl/hs32cpu/top.v`](https://github.com/hsc-latte/hs32core-rtl/tree/master/top.v)

**HS32 Interrupts** -- [`verilog/rtl/hs32cpu/docs/interrupts.md`](https://github.com/hsc-latte/hs32core-rtl/tree/master/docs/interrupts.md)

**HS32 MMIO** -- [`verilog/rtl/hs32cpu/docs/mmio.md`](https://github.com/hsc-latte/hs32core-rtl/tree/master/docs/mmio.md)

## Install

## Usage

## Contributing

Issues and pull requests are welcome! Please make sure to create them at the right repository :D

## Security

We take any security risks seriously, if you have found or suspected a vulnerability or anything that might compromise our security, we would very much appreciate it if you can report it to us.

## License

Apache 2.0 [LICENSE](https://github.com/hsc-latte/hs32core-rtl/tree/master/LICENSE)

HS32 Core - A 32-bits RISC Processor

```
  Copyright (c) 2020 The HSC Core Authors

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
```
