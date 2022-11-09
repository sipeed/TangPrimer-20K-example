# Rocket-chip on Tang Primer 20K

This runs a `rv32ic` rocket core with a UART peripheral attached. This example system outputs `A` via UART infinitely.

## Quick start/Test your UART

You can use the `openrigil-uart-wrapper-reset.fs` in this directory to test your UART functionality. See the `Program` section below.

You need a lite dock (I only have that, you can wire `nreset` to other button) and a core board. You also need a device to see the UART output (e.g. logic analyzer)

It is reported that UART does not work with the RV debugger. I used a FT2232 to get the UART output (baudrate 115200).

## RTL

The repo is at <https://github.com/OpenRigil/openrigil-rtl/tree/for-sipeed>. You should follow the steps in its README to generate the verilog you need (firmware is not needed). You may observe some output of `A` when you run the `emulator` verbosely.

You may be interested in the following files if you want to tweak the RTL.

* Rocket config: <https://github.com/OpenRigil/openrigil-rtl/blob/for-sipeed/sanitytests/rocketchip/src/OpenRigil.scala>
* Boot ROM that infinitely output `A` via UART: <https://github.com/OpenRigil/openrigil-rtl/blob/for-sipeed/sanitytests/rocketchip/resources/bootrom.S>

I have done quite a few tricks to reduce the resources needed and make the toolchain happy

* Remove as many features of the core as possible (e.g. Multiplier, FPU)
* [Remove dtb in BootROM](https://github.com/OpenRigil/rocket-chip/commit/aeb8863e6ee073f29135f4673f260d3d28dc7d2d): This is disastrous
* Remove unused gadgets: DebugModule, TLMonitor, PlusArgReader (GowinSynth does not recognize them)

## Synthesis

Now you should have get `OpenRigilTestHarness.v` in `out/VerilatorTest`. Another file we need is `openrigil-wrapper-reset.v` in the `sipeed/` directory of the RTL repo.

Unfortunately, GowinSynth (V1.9.8.07 Education for Linux) crashes when it tries to synth these RTLs.

So I used `yosys`. You should change the path in the script accordingly.

```
yosys -s yosys.ys
```

Interestingly, yosys for gowin already has a module named `ALU` so the `ALU` from rocket will lead to a confliction. I have to rename the module to `RocketALU`.

## PnR

Now you have generated `openrigil-uart-wrapper-reset.vg`.

NextPnR does not support 20K yet [at the time of writing](https://github.com/YosysHQ/apicula/issues/127), so I have to go back to Gowin tools for PnR.

You can run the following command with the `tcl` in `sipeed/` directory of the RTL repo to PnR. You should change the path in the tcl accordingly.

```bash
./IDE/bin/gw_sh gowin.tcl
```

Fortunately, it does not crash and can generate the bitstream, but unfortunately it will eat MUCH memory.
I have observed that how the many megabytes your `vg` is, how many GIGABYTEs of RAM it will eat.
Once I generated a 93M `vg` and it ate nearly 100G RAM (stuck my laptop of course so I have to use a server). The `openrigil-uart-wrapper-reset.vg` in this writeup is 63M so be careful with your RAM.

## Report

Note the peak memory usage! Be careful!

Also, thanks to the tricks that I used above, logic is not fully occupied. You can add attach periphrals to it (Advertisement: You can try out the [USB FS device that I implement (Both controller and Phy)](https://github.com/OpenRigil/rocket-chip-blocks/tree/usb/src/main/scala/devices/usb) or the montgomery accelerator (for Ed25519) provided by OpenRigil)

```
2. PnR Details

 Total Time and Memory Usage: CPU time = 0h 2m 12s, Elapsed time = 0h 2m 12s, Peak memory usage = 39725MB

3. Resource Usage Summary

  ----------------------------------------------------------
  Resources                   | Usage
  ----------------------------------------------------------
  Logic                       | 13106/20736  63%
    --LUT,ALU,ROM16           | 11654(10200 LUT, 1454 ALU, 0 ROM16)
    --SSRAM(RAM16)            | 242
  Register                    | 2785/16173  17%
    --Logic Register as Latch | 0/15552  0%
    --Logic Register as FF    | 2785/15552  17%
    --I/O Register as Latch   | 0/621  0%
    --I/O Register as FF      | 0/621  0%
  CLS                         | 7620/10368  73%
  I/O Port                    | 3
  ==========================================================

7. Pinout by Port Name

------------------------------------------------------------
Port Name   | Diff Pair | Loc./Bank     | Constraint | Dir.  
------------------------------------------------------------
clock       |           | H11/0         | Y          | in    
nreset      |           | T10/3         | Y          | in    
uart_0_txd  |           | M11/2         | Y          | out   
============================================================
```

## Program and Reset

The following command programs to the SRAM. You should use the git version of `openFPGALoader` if you need to program the flash as the old version programs the flash very slowly.

```
# Program to SRAM
openFPGALoader -b tangprimer20k /path/to/openrigil-uart-wrapper-reset.fs
```

After programming, you need to press the `T10` button to reset the whole system, then you will see many `A` in the UART output.
